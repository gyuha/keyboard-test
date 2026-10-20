<!-- forge-slug: keytest-core -->
<!-- task: 1 -->
<!-- priority: high -->
<!-- part: 1/2 -->
<!-- tdd: off -->
# 키 테스트 앱 코어 — 패키지 · 레이아웃 · 키 상태 · 이벤트 탭 정책 · 사운드 설정 · 체크 러너

## 목표 / 비목표
- 목표: 화면과 무관한 순수 로직(`KeyTestCore`)과 자체 체크 러너(`keytest-checks`)를 만든다. 이 머신에는 XCTest/Swift Testing이 없어서(Xcode 미설치) 러너는 실행 타깃으로 만든다. 이후 UI 플랜(`keytest-app`)이 이 코어 위에 올라간다.
- 비목표: AppKit 창, 실제 `CGEvent.tapCreate` 설치, 오디오 출력, 앱 번들 스크립트(전부 `keytest-app`). Xcode 설치나 시스템 권한 변경도 하지 않는다.

## 근거 문서
- 용어: 없음 (.forge/CONTEXT.md 없음)
- 관련 ADR: 없음
- 참고 이미지: 사용자가 준 레이아웃 이미지(108키)와 설정 패널 이미지(키보드 초기화 · 키 소리 토글 · 음량 · 전조 · 파형=사인파 · 모드=위키-헤이든)
- 가정(사용자 확인 없이 정함): Alt=Option, Win=Command (그래서 "Alt+Tab" = 맥의 Cmd+Tab). Print/Scroll/Pause=F13/F14/F15, Ins=Help, Del=Forward Delete, N.Lck=키패드 Clear, Menu=Fn(맥에는 Menu 키가 없어서 Fn을 이 칸에 대응), Mute/Vol-/Vol+=미디어 키(systemDefined), Sleep=맥 일반 키보드에 없어 켜지지 않음. 색은 "누르는 중=보라, 눌렀던 키=연한 살구색, 초기화가 모두 지움"으로 해석했다.
- Definition of Done: 아래 명령이 전부 성립 (사전 상태: 아무것도 없어서 전부 실패 — 모두 forward 체크)
  1. `swift build` exit 0
  2. `swift run keytest-checks` exit 0
  3. `swift run keytest-checks --suite Layout` → `SUITE Layout: N/N`, N ≥ 4
  4. `swift run keytest-checks --suite EventTap` → `SUITE EventTap: N/N`, N ≥ 7
  5. `swift run keytest-checks --suite KeyState` → `SUITE KeyState: N/N`, N ≥ 6
  6. `swift run keytest-checks --suite Sound` → `SUITE Sound: N/N`, N ≥ 8
  7. 각 스위트에 의도적 실패를 넣었을 때 러너가 exit 1을 내는지 한 번 재현한다 (러너가 항상 0을 내는 fail-open이 아님을 증명, 재현 후 원복).
  8. 이 플랜에는 기존 테스트 스위트가 없어서 첫 테스트 자체가 작업이다 (fix-forward eval 규칙 해당 없음: 신규 기능 플랜).

## 작업 슬라이스
- [ ] S1. `Package.swift`(swift-tools 5.9, macOS 13+, 타깃: `KeyTestCore` 라이브러리, `KeyTest` 실행 타깃(지금은 `--version`만 출력하는 최소 main), `keytest-checks` 실행 타깃)와 `.gitignore`(`.build/`, `build/`) — 완료 기준: `swift build` exit 0
- [ ] S2. 레이아웃 모델 — 108키를 6행으로(행별 20/21/21/16/17/13), 각 키는 id·표시 라벨(기호 키는 위/아래 두 라벨)·열 위치·너비/높이 span·맥 키코드 매핑을 가진다. N.Ent와 +는 키패드에서 세로 2칸 span이다. 이미지 순서: 행0 `Esc F1–F12 Print Scroll Pause Sleep Mute Vol- Vol+`, 행1 `~ 1 2 3 4 5 6 7 8 9 0 - = Backspace Ins Home PgUp N.Lck ÷ × −`, 행2 `Tab Q W E R T Y U I O P { } | Del End PgDn 7 8 9 +`, 행3 `Caps A S D F G H J K L ; ' Enter 4 5 6`, 행4 `LShift Z X C V B N M , . / RShift ↑ 1 2 3 N.Ent`, 행5 `LCtl LWin LAlt Space RAlt RWin Menu RCtl ← ↓ → 0 .` — 완료 기준: 위 순서와 수를 그대로 단언하는 Layout 스위트 통과(N ≥ 4: 총 108·행별 개수·id 유일·대표 키코드 매핑)
- [ ] S3. 키 상태 모델 — keyDown/keyUp/flagsChanged(키코드로 좌/우 Shift·Ctrl·Option·Cmd 구분, Caps Lock 토글)와 미디어 키(systemDefined)를 받아 "누르는 중" 집합과 "눌렀던 키" 집합을 갱신하고 `reset()`이 둘 다 비운다 — 완료 기준: KeyState 스위트 통과(N ≥ 6)
- [ ] S4. 이벤트 탭 정책 — 순수 함수 `decide(event, context)` (context: 캡처 ON/OFF, 앱 활성 여부). 캡처 ON이고 앱이 활성이면 모든 키 이벤트를 소비하고 상태에 반영한다(Cmd+Tab 포함). 아니면 통과. ⌃⌥⌘Q는 종료 요청(스스로 못 빠져나오는 일을 막는 비상구). `tapDisabledByTimeout/UserInput`은 재활성화 요청. 탭 설정 값(`.defaultTap`, headInsert, 이벤트 마스크)을 상수로 노출. 권한 상태(`granted/denied`) 구분 타입 — 완료 기준: EventTap 스위트 통과(N ≥ 7, 합성 CGEvent 사용)
- [ ] S5. 사운드 설정·합성 로직 — `SoundSettings`(켜짐·음량 0…1·전조 반음 정수·파형 4종 사인/사각/톱니/삼각·모드 위키-헤이든/단일음, 기본값은 켜짐·음량 최대·전조 0·사인파·위키-헤이든), UserDefaults 저장/복원/`reset()`, 트리거 정책(keyDown 최초 1회만, 반복·keyUp 제외), 전조 주파수 = 기준×2^(n/12), 파형 샘플 생성기(−1…1), 위키-헤이든 음 매핑(가로 이웃 +2반음, 위 행 오른쪽 +7, 위 행 왼쪽 +5), 단일음 모드는 모든 키가 같은 음 — 완료 기준: Sound 스위트 통과(N ≥ 8)
- [ ] S6. `keytest-checks` 러너 — 스위트 등록, `--suite <Name>` 선택, 스위트별 `SUITE <Name>: p/t` 출력, 실패 상세 출력, 하나라도 실패하면 exit 1 — 완료 기준: DoD 2·7
