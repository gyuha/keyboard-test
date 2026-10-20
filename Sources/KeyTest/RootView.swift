import AppKit
import KeyTestCore

/// 창 내용: 위는 키보드, 아래는 설정 패널.
final class RootView: NSView {
    static let size = NSSize(width: 1100, height: 700)
    private static let keyboardHeight: CGFloat = 380

    let keyboard: KeyboardView
    let panel: SettingsPanel

    init(state: KeyState, settings: SoundSettings) {
        keyboard = KeyboardView(frame: NSRect(x: 0, y: 0, width: Self.size.width, height: Self.keyboardHeight), state: state)
        panel = SettingsPanel(frame: NSRect(x: 0, y: Self.keyboardHeight, width: Self.size.width,
                                            height: Self.size.height - Self.keyboardHeight))
        super.init(frame: NSRect(origin: .zero, size: Self.size))
        addSubview(keyboard)
        addSubview(panel)
        panel.load(settings)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    override var isFlipped: Bool { true }
}

enum UIDescription {
    /// `--describe-ui`: 화면에 나오는 문자열과 권한 상태를 텍스트로 낸다.
    static func text() -> String {
        let permission = Permission.current()
        var lines = [
            UIStrings.resetRow, UIStrings.resetButton, UIStrings.soundRow, UIStrings.volumeRow,
            UIStrings.transposeRow, UIStrings.waveformRow, UIStrings.modeRow,
            "파형 선택지: " + Waveform.allCases.map { $0.title }.joined(separator: ", "),
            "모드 선택지: " + SoundMode.allCases.map { $0.title }.joined(separator: ", "),
            "키 수: \(Layout.all.count)",
            "권한: \(permission)",
        ]
        if let banner = UIStrings.permissionBanner(permission) { lines.append("안내: " + banner) }
        return lines.joined(separator: "\n")
    }
}

enum Snapshot {
    /// 헤드리스 렌더링 → PNG. 이미지와 비교하기 쉽도록 예시 키(Esc·Enter·N.Ent는 눌렀던 키, Left Shift·LWin은 누르는 중)를 켠다.
    static func write(to path: String) -> Bool {
        let state = KeyState()
        for code in [53, 36, 76] {
            state.keyDown(code: code)
            state.keyUp(code: code)
        }
        state.flagsChanged(code: 56, flags: .maskShift)
        state.flagsChanged(code: 55, flags: [.maskShift, .maskCommand])

        let root = RootView(state: state, settings: SoundSettings())
        root.appearance = NSAppearance(named: .darkAqua)
        if let banner = UIStrings.permissionBanner(Permission.current()) { root.keyboard.bannerText = banner }
        root.layoutSubtreeIfNeeded()
        guard let rep = root.bitmapImageRepForCachingDisplay(in: root.bounds) else { return false }
        root.cacheDisplay(in: root.bounds, to: rep)
        guard let png = rep.representation(using: .png, properties: [:]) else { return false }
        do {
            try png.write(to: URL(fileURLWithPath: path))
            return true
        } catch {
            FileHandle.standardError.write(Data("snapshot write failed: \(error)\n".utf8))
            return false
        }
    }
}
