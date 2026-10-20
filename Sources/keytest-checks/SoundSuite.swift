import Foundation
import KeyTestCore

private func cell(_ id: String) throws -> KeyCell {
    guard let c = Layout.cell(id: id) else { throw CheckFailure(description: "no cell \(id)") }
    return c
}

let soundSuite = Suite(name: "Sound", tests: [
    ("defaultsMatchReferenceImage", {
        let s = SoundSettings()
        try expect(s.enabled, "sound on by default")
        try expectEqual(s.volume, 1.0, "volume")
        try expectEqual(s.transpose, 0, "transpose")
        try expectEqual(s.waveform, .sine, "waveform 사인파")
        try expectEqual(s.mode, .wickiHayden, "mode 위키-헤이든")
    }),
    ("soundOffNeverTriggers", {
        try expect(!SoundTrigger.shouldPlay(enabled: false, isDown: true, isRepeat: false, isNewPress: true), "off")
    }),
    ("onlyFirstKeyDownTriggers", {
        try expect(SoundTrigger.shouldPlay(enabled: true, isDown: true, isRepeat: false, isNewPress: true), "first down")
        try expect(!SoundTrigger.shouldPlay(enabled: true, isDown: true, isRepeat: true, isNewPress: false), "repeat")
        try expect(!SoundTrigger.shouldPlay(enabled: true, isDown: false, isRepeat: false, isNewPress: false), "key up")
    }),
    ("volumeAndTransposeAreClamped", {
        var s = SoundSettings()
        s.volume = 5
        try expectEqual(s.volume, 1.0, "volume max")
        s.volume = -1
        try expectEqual(s.volume, 0.0, "volume min")
        s.transpose = 99
        try expectEqual(s.transpose, 12, "transpose max")
        s.transpose = -99
        try expectEqual(s.transpose, -12, "transpose min")
    }),
    ("transposeScalesFrequencyBy2PowNOver12", {
        let q = try cell("Q")
        var s = SoundSettings()
        let base = s.frequency(for: q)
        for n in [-12, -5, 7, 12] {
            s.transpose = n
            let ratio = s.frequency(for: q) / base
            try expect(abs(ratio - pow(2.0, Double(n) / 12.0)) < 1e-9, "transpose \(n) ratio \(ratio)")
        }
    }),
    ("fourWaveformsAreAudibleBoundedAndDistinct", {
        var renders: [[Float]] = []
        for w in Waveform.allCases {
            let samples = NoteRenderer.render(frequency: 440, waveform: w, volume: 1)
            let peak = samples.map { abs($0) }.max() ?? 0
            try expect(peak > 0.05, "\(w) silent (peak \(peak))")
            try expect(peak <= 1, "\(w) out of range (peak \(peak))")
            renders.append(samples)
        }
        try expectEqual(Waveform.allCases.count, 4, "waveform count")
        for i in 0..<renders.count {
            for j in (i + 1)..<renders.count {
                try expect(renders[i] != renders[j], "waveform \(i) and \(j) identical")
            }
        }
    }),
    ("volumeZeroIsSilent", {
        let samples = NoteRenderer.render(frequency: 440, waveform: .sine, volume: 0)
        try expect(samples.allSatisfy { $0 == 0 }, "volume 0 must be silent")
    }),
    ("wickiHaydenIntervals", {
        let q = WickiHayden.semitone(for: try cell("Q"))
        try expectEqual(WickiHayden.semitone(for: try cell("W")) - q, 2, "right neighbor")
        try expectEqual(WickiHayden.semitone(for: try cell("2")) - q, 7, "up-right = fifth")
        try expectEqual(WickiHayden.semitone(for: try cell("1")) - q, 5, "up-left = fourth")
        let a = WickiHayden.semitone(for: try cell("A"))
        try expectEqual(WickiHayden.semitone(for: try cell("S")) - a, 2, "right neighbor (home row)")
        try expectEqual(WickiHayden.semitone(for: try cell("W")) - a, 7, "up-right of A is W")
        try expectEqual(WickiHayden.semitone(for: try cell("Q")) - a, 5, "up-left of A is Q")
    }),
    ("fixedModeUsesOneNoteForEveryKey", {
        var s = SoundSettings()
        s.mode = .fixed
        let freqs = Set(try ["Q", "Space", "Esc", "Num5"].map { s.frequency(for: try cell($0)) })
        try expectEqual(freqs.count, 1, "single tone")
        try expect(abs(freqs.first! - 440) < 1e-9, "A4")
    }),
    ("wickiHaydenGivesDifferentNotesToNeighbours", {
        let s = SoundSettings()
        let q = s.frequency(for: try cell("Q"))
        let w = s.frequency(for: try cell("W"))
        try expect(q != w, "Q vs W")
    }),
    ("settingsSurviveSaveAndLoad", {
        let suite = "keytest.checks.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else { throw CheckFailure(description: "no defaults") }
        defer { defaults.removePersistentDomain(forName: suite) }
        var s = SoundSettings()
        s.enabled = false
        s.volume = 0.4
        s.transpose = -3
        s.waveform = .triangle
        s.mode = .fixed
        s.save(to: defaults)
        try expectEqual(SoundSettings.load(from: defaults), s, "round trip")
        try expectEqual(SoundSettings.load(from: UserDefaults(suiteName: suite + ".empty")!), SoundSettings(), "empty -> defaults")
    }),
    ("resetRestoresDefaults", {
        var s = SoundSettings()
        s.enabled = false
        s.volume = 0.1
        s.transpose = 5
        s.waveform = .square
        s.mode = .fixed
        s.reset()
        try expectEqual(s, SoundSettings(), "reset")
    }),
])
