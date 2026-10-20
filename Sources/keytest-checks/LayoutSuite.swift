import KeyTestCore

// 참고 이미지에서 옮겨 적은 기대 라벨 (구현과 독립). 이미지 표기에 맞춰 Caps Lock / Left Shift / Right Shift를 쓴다.
private let expectedRows: [[String]] = [
    ["Esc", "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12",
     "Print", "Scroll", "Pause", "Sleep", "Mute", "Vol-", "Vol+"],
    ["~", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=", "Backspace",
     "Ins", "Home", "PgUp", "N.Lck", "÷", "×", "−"],
    ["Tab", "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "{", "}", "|",
     "Del", "End", "PgDn", "7", "8", "9", "+"],
    ["Caps Lock", "A", "S", "D", "F", "G", "H", "J", "K", "L", ";", "'", "Enter",
     "4", "5", "6"],
    ["Left Shift", "Z", "X", "C", "V", "B", "N", "M", ",", ".", "/", "Right Shift",
     "↑", "1", "2", "3", "N.Ent"],
    ["LCtl", "LWin", "LAlt", "Space", "RAlt", "RWin", "Menu", "RCtl",
     "←", "↓", "→", "0", "."],
]

let layoutSuite = Suite(name: "Layout", tests: [
    ("totalIs108", {
        try expectEqual(Layout.all.count, 108, "total keys")
    }),
    ("rowCounts", {
        try expectEqual(Layout.rows.map { $0.count }, [20, 21, 21, 16, 17, 13], "row counts")
    }),
    ("labelsMatchImageOrder", {
        for (i, expected) in expectedRows.enumerated() {
            try expectEqual(Layout.rows[i].map { $0.label }, expected, "row \(i) labels")
        }
    }),
    ("idsAreUnique", {
        try expectEqual(Set(Layout.all.map { $0.id }).count, 108, "unique ids")
    }),
    ("macKeyCodeMapping", {
        try expectEqual(Layout.cell(forKeyCode: 48)?.id, "Tab", "Tab=48")
        try expectEqual(Layout.cell(forKeyCode: 55)?.id, "LWin", "Cmd=55 -> LWin")
        try expectEqual(Layout.cell(forKeyCode: 54)?.id, "RWin", "RCmd=54 -> RWin")
        try expectEqual(Layout.cell(forKeyCode: 58)?.id, "LAlt", "Option=58 -> LAlt")
        try expectEqual(Layout.cell(forKeyCode: 61)?.id, "RAlt", "ROption=61 -> RAlt")
        try expectEqual(Layout.cell(forKeyCode: 105)?.id, "Print", "F13=105 -> Print")
        try expectEqual(Layout.cell(forKeyCode: 114)?.id, "Ins", "Help=114 -> Ins")
        try expectEqual(Layout.cell(forKeyCode: 82)?.id, "Num0", "keypad 0=82")
        try expectEqual(Layout.cell(forKeyCode: 18)?.id, "1", "digit 1=18")
    }),
    ("mediaKeys", {
        try expectEqual(Layout.cell(forMedia: .mute)?.id, "Mute", "mute")
        try expectEqual(Layout.cell(forMedia: .volumeUp)?.id, "Vol+", "vol up")
        try expectEqual(Layout.cell(forMedia: .volumeDown)?.id, "Vol-", "vol down")
    }),
    ("keypadTallKeysSpanTwoRows", {
        try expectEqual(Layout.cell(id: "Num+")?.height, 2, "+ height")
        try expectEqual(Layout.cell(id: "N.Ent")?.height, 2, "N.Ent height")
        try expectEqual(Layout.cell(id: "Space")?.width, 6.25, "space width")
    }),
])
