#!/usr/bin/env bash
# 공개된 릴리스를 homebrew-tap(gyuha/homebrew-tap)의 Cask에 반영한다. scripts/release.sh가 공개한 직후 부르고,
# 실패했을 때는 직접 `scripts/update-tap.sh <버전>`으로 다시 실행해도 된다(이미 반영돼 있으면 아무것도 바꾸지 않는다).
#
# 순서: 릴리스가 공개 상태인지 확인 → 공개 URL에서 DMG를 내려받아 GitHub가 준 sha256과 대조 →
#       tap 저장소를 새로 받아 Cask의 version·sha256 갱신 → 바뀐 게 있으면 커밋·push.
# 환경 변수: DRY_RUN=1 이면 커밋만 하고 push는 건너뛴다. SOURCE_REPO(기본 gyuha/keyboard-test), TAP_URL(기본 gyuha/homebrew-tap의 https 주소).
set -euo pipefail

SOURCE_REPO="${SOURCE_REPO:-gyuha/keyboard-test}"
TAP_URL="${TAP_URL:-https://github.com/gyuha/homebrew-tap.git}"
ASSET="KeyTest.dmg"
CASK="Casks/keytest.rb"

die() { echo "오류: $*" >&2; exit 1; }

# Cask의 version과 sha256 줄을 바꾸고, 실제로 반영됐는지 확인한다. 인자: 파일 버전 sha256
rewrite_cask() {
  local file="$1" version="$2" sha="$3"
  sed -i '' -e "s/^  version \".*\"$/  version \"$version\"/" -e "s/^  sha256 \".*\"$/  sha256 \"$sha\"/" "$file"
  grep -qF "  version \"$version\"" "$file" && grep -qF "  sha256 \"$sha\"" "$file"
}

main() {
  local version="${1:-}"
  [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "사용법: scripts/update-tap.sh <버전>  (예: 0.2.0)"
  local tag="v$version"

  local work
  work="$(mktemp -d "${TMPDIR:-/tmp}/keytest-tap.XXXXXX")"
  # 종료 시점에는 지역 변수가 사라져 있으므로 경로를 지금 확장해 둔다
  trap "rm -rf '$work'" EXIT

  local draft digest
  draft="$(gh api "repos/$SOURCE_REPO/releases/tags/$tag" --jq '.draft')" || die "$tag 릴리스를 찾을 수 없습니다"
  [[ "$draft" == "false" ]] || die "$tag 은 아직 공개되지 않은 초안입니다"
  digest="$(gh api "repos/$SOURCE_REPO/releases/tags/$tag" --jq ".assets[] | select(.name==\"$ASSET\") | .digest")"
  [[ "$digest" =~ ^sha256:[0-9a-f]{64}$ ]] || die "$ASSET 에 GitHub sha256 digest가 없어 검증할 수 없습니다"

  gh release download "$tag" -R "$SOURCE_REPO" -p "$ASSET" -D "$work" >/dev/null
  local sha
  sha="$(shasum -a 256 "$work/$ASSET" | awk '{print $1}')"
  [[ "sha256:$sha" == "$digest" ]] || die "내려받은 $ASSET 의 sha256($sha)이 GitHub 값($digest)과 다릅니다"

  git clone --quiet --depth 1 "$TAP_URL" "$work/tap"
  rewrite_cask "$work/tap/$CASK" "$version" "$sha" || die "$CASK 의 version/sha256 줄을 찾지 못했습니다"

  git -C "$work/tap" add "$CASK"
  if [[ -z "$(git -C "$work/tap" status --porcelain)" ]]; then
    echo "tap은 이미 $version 입니다. 바꿀 것이 없습니다."
    return 0
  fi

  git -C "$work/tap" diff --cached -- "$CASK"
  git -C "$work/tap" commit --quiet -m "KeyTest $version Homebrew Cask 갱신"
  if [[ "${DRY_RUN:-}" == "1" ]]; then
    echo "DRY_RUN=1: push는 건너뜁니다."
    return 0
  fi
  git -C "$work/tap" push --quiet origin HEAD
  echo "tap 갱신 완료: KeyTest $version (sha256 $sha)"
}

# 다른 스크립트나 점검에서 source 해서 rewrite_cask만 쓸 수 있게, 직접 실행했을 때만 main을 돈다.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
