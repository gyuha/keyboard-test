import AppKit
import KeyTestCore

/// 키보드 아래 설정 패널 (참고 이미지: 키보드 초기화 · 키 소리 · 음량 · 전조 · 파형 · 모드).
final class SettingsPanel: NSView {
    var onChange: ((SoundSettings) -> Void)?
    var onReset: (() -> Void)?

    private var settings = SoundSettings()
    private let rowHeight: CGFloat = 51
    private let labelX: CGFloat = 200
    private let rightEdge: CGFloat = 900

    private let resetButton = NSButton(title: UIStrings.resetButton, target: nil, action: nil)
    private let soundSwitch = NSSwitch()
    private let volumeSlider = NSSlider(value: 1, minValue: 0, maxValue: 1, target: nil, action: nil)
    private let transposeSlider = NSSlider(value: 0, minValue: -12, maxValue: 12, target: nil, action: nil)
    private let waveformPopup = NSPopUpButton(frame: .zero, pullsDown: false)
    private let modePopup = NSPopUpButton(frame: .zero, pullsDown: false)

    override var isFlipped: Bool { true }

    override init(frame: NSRect) {
        super.init(frame: frame)
        appearance = NSAppearance(named: .darkAqua)

        let rows: [(String, NSControl, CGFloat)] = [
            (UIStrings.resetRow, resetButton, 100),
            (UIStrings.soundRow, soundSwitch, 52),
            (UIStrings.volumeRow, volumeSlider, 200),
            (UIStrings.transposeRow, transposeSlider, 200),
            (UIStrings.waveformRow, waveformPopup, 250),
            (UIStrings.modeRow, modePopup, 250),
        ]
        for (index, row) in rows.enumerated() {
            let y = 12 + CGFloat(index) * rowHeight
            let label = NSTextField(labelWithString: row.0)
            label.font = NSFont.systemFont(ofSize: 17)
            label.textColor = NSColor(hex: 0x9A9A9A)
            label.frame = NSRect(x: labelX, y: y + 12, width: 260, height: 26)
            addSubview(label)
            let control = row.1
            let height: CGFloat = control === soundSwitch ? 28 : 26
            control.frame = NSRect(x: rightEdge - row.2, y: y + (rowHeight - height) / 2, width: row.2, height: height)
            addSubview(control)
        }

        for waveform in Waveform.allCases { waveformPopup.addItem(withTitle: waveform.title) }
        for mode in SoundMode.allCases { modePopup.addItem(withTitle: mode.title) }

        resetButton.target = self
        resetButton.action = #selector(resetTapped)
        soundSwitch.target = self
        soundSwitch.action = #selector(controlChanged)
        for control in [volumeSlider, transposeSlider] as [NSSlider] {
            control.target = self
            control.action = #selector(controlChanged)
        }
        for popup in [waveformPopup, modePopup] {
            popup.target = self
            popup.action = #selector(controlChanged)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    override func draw(_ dirtyRect: NSRect) {
        NSColor(hex: 0x272727).setFill()
        bounds.fill()
        NSColor(hex: 0x3A3A3A).setFill()
        for index in 0..<6 {
            let y = 12 + CGFloat(index + 1) * rowHeight - 1
            NSRect(x: labelX, y: y, width: rightEdge - labelX + 18, height: 1).fill()
        }
    }

    /// 컨트롤을 설정값에 맞춘다 (콜백은 부르지 않음).
    func load(_ newSettings: SoundSettings) {
        settings = newSettings
        soundSwitch.state = settings.enabled ? .on : .off
        volumeSlider.doubleValue = settings.volume
        transposeSlider.integerValue = settings.transpose
        waveformPopup.selectItem(at: Waveform.allCases.firstIndex(of: settings.waveform) ?? 0)
        modePopup.selectItem(at: SoundMode.allCases.firstIndex(of: settings.mode) ?? 0)
    }

    @objc private func controlChanged() {
        settings.enabled = soundSwitch.state == .on
        settings.volume = volumeSlider.doubleValue
        settings.transpose = Int(transposeSlider.doubleValue.rounded())
        transposeSlider.integerValue = settings.transpose
        settings.waveform = Waveform.allCases[max(0, waveformPopup.indexOfSelectedItem)]
        settings.mode = SoundMode.allCases[max(0, modePopup.indexOfSelectedItem)]
        onChange?(settings)
    }

    @objc private func resetTapped() {
        onReset?()
    }
}
