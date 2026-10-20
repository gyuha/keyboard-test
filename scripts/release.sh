#!/usr/bin/env bash
# 새 버전을 배포한다: DMG 빌드 → GitHub 릴리스 공개(태그 생성) → homebrew-tap 갱신.
# 사용: scripts/release.sh <버전> [릴리스 노트 파일]   예) scripts/release.sh 0.2.0
# 노트 파일을 주지 않으면 GitHub가 커밋 기록으로 노트를 만든다.
#
# 공개는 되돌릴 수 없으니 먼저 점검한다: main 브랜치 · 추적 파일 변경 없음 · origin/main과 같은 커밋 · 아직 없는 태그.
# 릴리스는 공개됐는데 tap 갱신만 실패하면 `scripts/update-tap.sh <버전>`으로 다시 실행한다.
set -euo pipefail
cd "$(dirname "$0")/.."

REPO="gyuha/keyboard-test"

die() { echo "오류: $*" >&2; exit 1; }

version="${1:-}"
notes_file="${2:-}"
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "사용법: scripts/release.sh <버전> [노트 파일]  (예: 0.2.0)"
tag="v$version"
[[ -z "$notes_file" || -f "$notes_file" ]] || die "노트 파일이 없습니다: $notes_file"

[[ "$(git branch --show-current)" == "main" ]] || die "main 브랜치에서만 배포합니다"
[[ -z "$(git status --porcelain --untracked-files=no)" ]] || die "커밋하지 않은 변경이 있습니다. 먼저 커밋하세요"
git fetch --quiet origin main
[[ "$(git rev-parse HEAD)" == "$(git rev-parse origin/main)" ]] || die "HEAD가 origin/main과 다릅니다. 먼저 push(또는 pull)하세요"
gh auth status >/dev/null 2>&1 || die "gh 로그인이 필요합니다 (gh auth login)"
if gh release view "$tag" -R "$REPO" >/dev/null 2>&1; then die "$tag 릴리스가 이미 있습니다"; fi
if git ls-remote --exit-code --tags origin "refs/tags/$tag" >/dev/null 2>&1; then die "$tag 태그가 이미 있습니다"; fi

echo "==> $tag 빌드"
VERSION="$version" bash scripts/build-dmg.sh

echo "==> $tag 릴리스 공개"
notes_args=(--generate-notes)
[[ -n "$notes_file" ]] && notes_args=(--notes-file "$notes_file")
gh release create "$tag" build/KeyTest.dmg -R "$REPO" --title "KeyTest $tag" --target "$(git rev-parse HEAD)" "${notes_args[@]}"

echo "==> homebrew-tap 갱신"
if ! bash scripts/update-tap.sh "$version"; then
  echo "릴리스는 공개됐지만 tap 갱신에 실패했습니다. 원인을 해결한 뒤 'scripts/update-tap.sh $version'을 다시 실행하세요." >&2
  exit 1
fi

echo "배포 완료: https://github.com/$REPO/releases/tag/$tag"
echo "설치 확인: brew update && brew upgrade --cask keytest   (처음이면 brew install --cask gyuha/tap/keytest)"
