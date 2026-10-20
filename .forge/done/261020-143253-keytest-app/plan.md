<!-- forge-slug: keytest-app -->
<!-- task: 2 -->
<!-- priority: medium -->
<!-- part: 2/2 -->
<!-- tdd: off -->
# 키 테스트 앱 — AppKit UI · 이벤트 탭 연결 · 소리 · 앱 번들

## 목표 / 비목표
- 목표: `keytest-core` 위에 맥 앱을 만든다. (1) 이미지와 같은 키보드 화면과 설정 패널 (2) 실제 `CGEventTap`으로 조합키(Cmd+Tab 등)를 가로채 외부로 안 보내고 화면에 켜기 (3) 키를 누를 때 소리, 설정 패널에서 켜기/끄기 (4) `.app` 번들 생성.
- 비목표: 앱 서명 배포·공증, `/Applications` 설치, 로그인 항목 등록, 시스템 권한을 코드나 스크립트로 바꾸는 일(`tccutil` 등). 사용자가 직접 권한을 승인한다. 이미지에 없는 기능(키 기록 저장, 통계 등)도 하지 않는다.

## 근거 문서
- 용어: 없음
- 관련 ADR: 없음
- 선행: `keytest-core` (soft order, part 2/2)
- 참고 이미지 두 장(사용자 제공): (1) 어두운 케이스 + 살구색 베젤 안의 108키 레이아웃, 눌린 키는 연한 살구색 또는 보라색 (2) 키보드 아래 설정 패널 — 행 라벨(한국어) `키보드 초기화`(버튼 `초기화`) / `키 소리`(토글) / `음량`(슬라이더) / `전조`(슬라이더) / `파형`(드롭다운, 기본 `사인파`) / `모드`(드롭다운, 기본 `위키-헤이든`). 파형 선택지는 사인파·사각파·톱니파·삼각파, 모드는 위키-헤이든·단일음.
- 안전 설계: 캡처는 이 앱이 활성일 때만 키를 소비한다(다른 앱 위에서는 통과). 그래도 못 빠져나오는 일이 없도록 창 닫기 버튼(마우스)과 비상 종료 ⌃⌥⌘Q를 항상 쓸 수 있게 한다.
- Definition of Done (사전 상태: `keytest-app` 산출물이 없어 아래 C7·C8은 실패):
  1. `swift build` exit 0, `swift run keytest-checks` exit 0 (core 회귀 없음 — 이미 통과하는 회귀 가드)
  2. `bash scripts/build-app.sh` exit 0, `plutil -lint build/KeyTest.app/Contents/Info.plist` OK, `codesign --verify build/KeyTest.app` exit 0, `build/KeyTest.app/Contents/MacOS/KeyTest` 존재
  3. `T=$(mktemp -t kt).png; .build/debug/KeyTest --snapshot "$T"` exit 0 이고 `sips -g pixelWidth "$T"` ≥ 1000
  4. `.build/debug/KeyTest --describe-ui` 출력에 `키보드 초기화`·`키 소리`·`음량`·`전조`·`파형`·`모드`가 모두 있음
  5. 스냅샷 PNG를 Read로 열어 사용자 이미지와 눈으로 비교한다(색·키 배치·설정 패널). 이것은 기계 체크가 아니라 판단이므로 불일치는 run.md에 적는다.
  6. 권한 없는 상태에서 앱을 실행하면 창에 접근성/입력 모니터링 승인 안내가 보이고 크래시하지 않는다(`--describe-ui` 출력에 안내 문구가 포함됨).
  7. 실제 Cmd+Tab 차단은 사람이 권한을 승인한 뒤 직접 확인해야 한다 → 이 항목은 `pending`(수동 UAT)로 남기고 `unverifiable`로 봉인하지 않는다. 안내 문구: 시스템 설정 → 개인정보 보호 및 보안 → 손쉬운 사용/입력 모니터링에서 `KeyTest.app` 허용 후 앱 재실행.

## 작업 슬라이스
- [ ] S1. AppKit 앱 골격과 키보드 뷰 — `NSApplication` 델리게이트, 어두운 창, 레이아웃 모델을 그대로 그리는 커스텀 뷰(살구색 베젤, 짙은 키캡, 위/아래 두 라벨 키, 키패드 세로 span), 상태 모델에 맞춰 보라(누르는 중)·연한 살구(눌렀던 키)로 칠함 — 완료 기준: `--snapshot` PNG ≥ 1000px, 눈으로 비교 판단
- [ ] S2. 설정 패널 — 이미지처럼 키보드 아래 행 6개(초기화 버튼·키 소리 토글·음량·전조 슬라이더·파형/모드 드롭다운, 한국어 라벨), `SoundSettings`와 양방향 연결(저장·복원), 초기화 버튼은 키 상태와 설정을 모두 기본값으로 — 완료 기준: `--describe-ui`에 6개 라벨(DoD 4)
- [ ] S3. 이벤트 탭 연결 — `CGEvent.tapCreate(.defaultTap, headInsert, 마스크는 코어 상수)`를 메인 런루프에 설치, 콜백은 코어 `decide`에 위임(소비하면 nil 반환), 타임아웃/사용자 입력으로 비활성화되면 재활성화, 권한 없음이면 탭을 만들지 않고 창에 승인 안내 표시(`AXIsProcessTrusted`/`CGPreflightListenEventAccess`), 미디어 키(systemDefined subtype 8) 처리, ⌃⌥⌘Q 종료 — 완료 기준: 권한 없이도 크래시 없이 실행되고 안내가 보임(DoD 6)
- [ ] S4. 소리 — `AVAudioEngine`+소스 노드로 코어 파형 생성기를 재생, 키 누름(keyDown 최초 1회)마다 짧은 엔벨로프 음, 모드별 음 선택(위키-헤이든/단일음), 음량·전조·파형 실시간 반영, `키 소리` 토글이 꺼지면 무음 — 완료 기준: 소리 트리거 경로가 코어 정책(Sound 스위트)을 거침, 빌드 성공
- [ ] S5. `scripts/build-app.sh` — `swift build -c release` 후 `build/KeyTest.app`(Info.plist: 번들 ID·이름·`NSPrincipalClass`·최소 macOS·`NSMicrophone` 같은 불필요 항목 없음), 실행 파일 복사, ad-hoc `codesign -s -`; `KeyTest`에 `--snapshot <path>`와 `--describe-ui` 플래그 — 완료 기준: DoD 2·3·4
