# RUN — 키 테스트 앱 (keytest-app)

실행 방식: 서브에이전트 워크플로우 없이 오케스트레이터 세션이 직접 실행 (in-flight 마커 없음).

## 슬라이스별 결과
- S1 AppKit 앱 골격과 키보드 뷰 — ✅ as planned. 스냅샷 PNG 1100×700, 눈으로 비교: 키 배치·베젤·보라(누르는 중)/살구색(눌렀던 키)이 참고 이미지와 일치
- S2 설정 패널 — ⚠ 행 6개·한국어 라벨·기본값(사인파/위키-헤이든)은 이미지와 같다. 컨트롤 강조색은 이미지의 살구색이 아니라 시스템 파란색(NSSwitch/NSSlider 기본, 바꾸려면 커스텀 그리기가 필요해 범위 밖으로 둠)
- S3 이벤트 탭 연결 — ✅ as planned. `CGEvent.tapCreate(.defaultTap, headInsert, .cghidEventTap)`, 타임아웃 재활성화, 권한 없으면 탭 없이 1.5초마다 재시도 + 창 안의 키만 켜는 대체 경로, ⌃⌥⌘Q 종료. 덧붙인 것: 권한 전에도 창 안 키는 켜지도록 로컬 모니터(플랜에 없던 보조 경로)
- S4 소리 — ✅ as planned. AVAudioSourceNode 1개로 다중 음 혼합, 트리거는 코어 `SoundTrigger`를 거침, 음량·전조·파형·모드는 새 음마다 반영
- S5 scripts/build-app.sh + --snapshot/--describe-ui — ✅ as planned (스냅샷에는 이미지와 비교하기 쉽도록 예시 키 5개를 켠다 — 코드 주석에 명시)

## DoD baseline → after
1. `swift build` / `swift run keytest-checks` exit 0 : 이미 통과(core 회귀 가드, 기대된 결과) → 0 / 0, Layout 7/7 · EventTap 11/11 · KeyState 9/9 · Sound 12/12
2. build-app.sh · plutil · codesign · 실행 파일 : 모두 없음 → rc=0 · Info.plist OK · codesign rc=0 · 실행 파일 존재
3. `--snapshot` 폭 : 스텁이 인자를 무시(exit 0이지만 파일 없음) → rc=0, pixelWidth 1100 (≥1000)
4. `--describe-ui` 라벨 6개 : 없음 → 6개 모두 있음
5. 스냅샷 눈 비교 : 위 S1·S2 참고 (차이는 컨트롤 강조색 한 가지)
6. 권한 없는 상태 : 셸에서 직접 실행하면 호스트 프로세스의 권한이 상속돼 `granted`로 보임. 번들을 LaunchServices로 띄우면(`open -W --stdout`) `권한: missingBoth` + 한국어 승인 안내가 나옴 → 확인됨
7. 실제 Cmd+Tab 차단 : **수동 UAT 대기(자동 증명 불가)**

## 미확인 사항 (정직하게)
- GUI를 실제로 띄운 실행 테스트는 하지 않았다. 앱이 활성화되며 키를 가로채고 시스템 권한 승인 창을 띄우기 때문에 이 세션의 입력을 가로챌 위험이 있다. 탭 설치·소리 재생 경로는 컴파일과 코어 단위 테스트까지만 검증됨.
- 탭 위치를 `.cghidEventTap`으로 한 것이 macOS 26에서 Cmd+Tab을 실제로 막는지는 확인 못 함 [Medium: 일반적으로 HID 수준 액티브 탭은 앱 전환 단축키를 소비할 수 있다고 알려져 있으나 OS 버전별 차이 가능].
