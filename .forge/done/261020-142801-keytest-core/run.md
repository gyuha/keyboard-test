# RUN — 키 테스트 앱 코어 (keytest-core)

실행 방식: 서브에이전트 워크플로우 없이 오케스트레이터 세션이 직접 실행 (규모가 작아 fg-run의 직접 실행 경로). 이 때문에 in-flight 마커(running.md)는 쓰지 않았다.

## 슬라이스별 결과
- S1 Package.swift(KeyTestCore · KeyTest · keytest-checks)와 .gitignore — ✅ as planned (`swift build` exit 0, warning 0)
- S2 레이아웃 모델 108키 — ⚠ 라벨 3개를 플랜 약칭 대신 이미지 표기로 구현 (`Caps Lock`/`Left Shift`/`Right Shift`, 플랜 본문은 `Caps`/`LShift`/`RShift`). 이미지가 근거이고 플랜 표기는 축약이었다. 테스트 기대값도 같은 이미지 표기로 독립 작성함.
- S3 키 상태 모델 — ✅ as planned (held/everPressed 분리, 좌우 수정키는 키코드로 구분, Caps Lock은 켜진 동안 held)
- S4 이벤트 탭 정책 — ✅ as planned. 결정 사항: 앱이 비활성이면 기록도 차단도 안 함, 활성+캡처 OFF면 기록만 하고 통과, 탭 위치는 `.cghidEventTap`(HID 수준 — Cmd+Tab 차단 가능성을 위해 선택, 실제 차단 여부는 권한 승인 후 수동 UAT 대상)
- S5 사운드 설정·합성 로직 — ✅ as planned. 결정 사항: 위키-헤이든 이상적 0.5칸 어긋남으로 알파벳 행 보정, 음역은 MIDI 48–83으로 접음(모듈로 36), 단일음 모드는 A4(440Hz)+전조
- S6 keytest-checks 러너 — ✅ as planned (스위트별 `SUITE <Name>: p/t`, 실패 시 exit 1, 알 수 없는 스위트 exit 1)

## DoD baseline → after
1. `swift build` exit 0 : 1 → 0 (사전 상태는 패키지 없음으로 실패)
2. `swift run keytest-checks` exit 0 : 1 → 0
3. Layout : 없음 → `SUITE Layout: 7/7` (N ≥ 4)
4. EventTap : 없음 → `SUITE EventTap: 11/11` (N ≥ 7)
5. KeyState : 없음 → `SUITE KeyState: 9/9` (N ≥ 6)
6. Sound : 없음 → `SUITE Sound: 12/12` (N ≥ 8)
7. 러너 fail-open 방지 재현 : 스위트마다 소스를 하나씩 일부러 망가뜨려(Tab 키코드 · 우측 Shift 마스크 · 소비 판정 · 전조 분모) 대응 테스트가 실패하고 exit 1이 나는 것을 확인한 뒤 원복(cmp로 4개 파일 원복 확인, 원복 후 exit 0). 알 수 없는 `--suite`도 exit 1.
8. fix-forward eval 규칙: 신규 기능 플랜이라 해당 없음 (기존 스위트가 없어 첫 테스트가 곧 작업).

미해결/주의
- 합성 CGEvent 단위 테스트까지만 증명했다. 실제 `CGEvent.tapCreate` 설치와 Cmd+Tab 시스템 차단은 `keytest-app` 이후 사람이 권한을 승인하고 확인해야 한다.
- 이 머신에는 XCTest/Swift Testing이 없어(Xcode 미설치) `swift test`는 쓰지 않고 자체 러너를 만들었다.
