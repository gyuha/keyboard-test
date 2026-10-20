#!/usr/bin/env bash
# build/KeyTest.dmg 를 만든다 (앱 번들 빌드 포함, Applications 바로가기 포함).
set -euo pipefail
cd "$(dirname "$0")/.."

bash scripts/build-app.sh

DMG="build/KeyTest.dmg"
STAGE="$(mktemp -d "${TMPDIR:-/tmp}/keytest-dmg.XXXXXX")"
trap 'rm -rf "$STAGE"' EXIT

cp -R build/KeyTest.app "$STAGE/KeyTest.app"
ln -s /Applications "$STAGE/Applications"

rm -f "$DMG"
hdiutil create -volname "KeyTest" -srcfolder "$STAGE" -ov -format UDZO "$DMG"
hdiutil verify "$DMG"
echo "built $DMG"
