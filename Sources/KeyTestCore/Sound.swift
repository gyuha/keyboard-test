import Foundation

public enum Waveform: String, CaseIterable {
    case sine, square, sawtooth, triangle

    public var title: String {
        switch self {
        case .sine: return "사인파"
        case .square: return "사각파"
        case .sawtooth: return "톱니파"
        case .triangle: return "삼각파"
        }
    }

    /// phase는 0..<1 한 주기
    public func sample(phase: Double) -> Double {
        switch self {
        case .sine: return sin(2 * Double.pi * phase)
        case .square: return phase < 0.5 ? 1 : -1
        case .sawtooth: return 2 * phase - 1
        case .triangle: return 4 * abs(phase - 0.5) - 1
        }
    }
}

public enum SoundMode: String, CaseIterable {
    case wickiHayden, fixed

    public var title: String {
        switch self {
        case .wickiHayden: return "위키-헤이든"
        case .fixed: return "단일음"
        }
    }
}

public struct SoundSettings: Equatable {
    public var enabled = true
    public var volume = 1.0 { didSet { volume = min(max(volume, 0), 1) } }
    /// 전조: 반음 단위, -12...12
    public var transpose = 0 { didSet { transpose = min(max(transpose, -12), 12) } }
    public var waveform = Waveform.sine
    public var mode = SoundMode.wickiHayden

    public init() {}

    private enum Key {
        static let enabled = "keytest.sound.enabled"
        static let volume = "keytest.sound.volume"
        static let transpose = "keytest.sound.transpose"
        static let waveform = "keytest.sound.waveform"
        static let mode = "keytest.sound.mode"
    }

    public static func load(from defaults: UserDefaults) -> SoundSettings {
        var s = SoundSettings()
        if defaults.object(forKey: Key.enabled) != nil { s.enabled = defaults.bool(forKey: Key.enabled) }
        if defaults.object(forKey: Key.volume) != nil { s.volume = defaults.double(forKey: Key.volume) }
        if defaults.object(forKey: Key.transpose) != nil { s.transpose = defaults.integer(forKey: Key.transpose) }
        if let raw = defaults.string(forKey: Key.waveform), let w = Waveform(rawValue: raw) { s.waveform = w }
        if let raw = defaults.string(forKey: Key.mode), let m = SoundMode(rawValue: raw) { s.mode = m }
        return s
    }

    public func save(to defaults: UserDefaults) {
        defaults.set(enabled, forKey: Key.enabled)
        defaults.set(volume, forKey: Key.volume)
        defaults.set(transpose, forKey: Key.transpose)
        defaults.set(waveform.rawValue, forKey: Key.waveform)
        defaults.set(mode.rawValue, forKey: Key.mode)
    }

    public mutating func reset() {
        self = SoundSettings()
    }

    /// 이 키가 내는 소리의 주파수(Hz). 기준은 A4 = 440Hz.
    public func frequency(for cell: KeyCell) -> Double {
        let midi = mode == .fixed ? 69 : WickiHayden.midiNote(for: cell)
        return 440.0 * pow(2.0, Double(midi - 69 + transpose) / 12.0)
    }
}

public enum WickiHayden {
    /// 가로 이웃 +2반음, 위 행의 오른쪽 이웃 +7, 왼쪽 이웃 +5가 되도록 키 중심 위치에서 음높이를 정한다.
    /// 알파벳 행은 실제 키보드의 어긋남이 0.5/0.25/0.5라서 이상적인 0.5칸 어긋남으로 보정한다.
    public static func semitone(for cell: KeyCell) -> Int {
        let shift: Double = (cell.row == 3 || cell.row == 4) ? 0.25 : 0
        let center = cell.x + cell.width / 2 + shift
        return Int((center * 2).rounded()) + 6 * (5 - cell.row)
    }

    /// 들을 만한 음역(MIDI 48...83)으로 접는다.
    public static func midiNote(for cell: KeyCell) -> Int {
        48 + semitone(for: cell) % 36
    }
}

public enum SoundTrigger {
    /// keyDown 최초 1회만 울린다. 키 반복·keyUp·이미 눌린 키는 울리지 않는다.
    public static func shouldPlay(enabled: Bool, isDown: Bool, isRepeat: Bool, isNewPress: Bool) -> Bool {
        enabled && isDown && !isRepeat && isNewPress
    }
}

public enum NoteRenderer {
    /// 짧은 엔벨로프(5ms 어택, 지수 감쇠)가 붙은 한 음의 샘플. 모두 -1...1.
    public static func render(frequency: Double, waveform: Waveform, volume: Double,
                              sampleRate: Double = 44100, duration: Double = 0.18) -> [Float] {
        let frames = Int(sampleRate * duration)
        let gain = 0.3 * min(max(volume, 0), 1)
        var phase = 0.0
        var out = [Float](repeating: 0, count: frames)
        for i in 0..<frames {
            let t = Double(i) / sampleRate
            let envelope = min(t / 0.005, 1) * exp(-t * 18)
            out[i] = Float(waveform.sample(phase: phase) * envelope * gain)
            phase += frequency / sampleRate
            phase -= phase.rounded(.down)
        }
        return out
    }
}
