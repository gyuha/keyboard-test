import CoreGraphics
import KeyTestCore

let keyStateSuite = Suite(name: "KeyState", tests: [
    ("keyDownThenUp", {
        let s = KeyState()
        try expectEqual(s.keyDown(code: 12), "Q", "new press")
        try expect(s.held.contains("Q"), "Q held")
        s.keyUp(code: 12)
        try expect(!s.held.contains("Q"), "Q released")
        try expect(s.everPressed.contains("Q"), "Q stays in everPressed")
    }),
    ("repeatedKeyDownIsNotNewPress", {
        let s = KeyState()
        _ = s.keyDown(code: 0)
        try expectEqual(s.keyDown(code: 0), nil, "second down while held")
    }),
    ("leftAndRightShiftAreDistinct", {
        let s = KeyState()
        try expectEqual(s.flagsChanged(code: 56, flags: .maskShift), "Left Shift", "left")
        try expectEqual(s.flagsChanged(code: 60, flags: .maskShift), "Right Shift", "right")
        try expect(s.held.contains("Left Shift") && s.held.contains("Right Shift"), "both held")
        // 왼쪽을 뗀다: flags에는 오른쪽 때문에 shift 비트가 남아 있다
        _ = s.flagsChanged(code: 56, flags: .maskShift)
        try expect(!s.held.contains("Left Shift"), "left released")
        try expect(s.held.contains("Right Shift"), "right still held")
        _ = s.flagsChanged(code: 60, flags: [])
        try expect(s.held.isEmpty, "all released")
    }),
    ("optionAndCommandMapToAltAndWin", {
        let s = KeyState()
        _ = s.flagsChanged(code: 58, flags: .maskAlternate)
        _ = s.flagsChanged(code: 55, flags: [.maskAlternate, .maskCommand])
        try expectEqual(s.held, Set(["LAlt", "LWin"]), "Option+Cmd held")
    }),
    ("capsLockLatchesUntilToggledOff", {
        let s = KeyState()
        _ = s.flagsChanged(code: 57, flags: .maskAlphaShift)
        try expect(s.held.contains("Caps Lock"), "caps on")
        _ = s.flagsChanged(code: 57, flags: [])
        try expect(!s.held.contains("Caps Lock"), "caps off")
        try expect(s.everPressed.contains("Caps Lock"), "caps remembered")
    }),
    ("heldAndEverPressedAreDifferentSets", {
        let s = KeyState()
        _ = s.keyDown(code: 53)  // Esc
        s.keyUp(code: 53)
        _ = s.keyDown(code: 36)  // Enter 누르는 중
        try expectEqual(s.held, Set(["Enter"]), "held")
        try expectEqual(s.everPressed, Set(["Esc", "Enter"]), "everPressed")
    }),
    ("mediaKeysLightTheirCells", {
        let s = KeyState()
        try expectEqual(s.media(.mute, down: true), "Mute", "mute down")
        try expect(s.held.contains("Mute"), "mute held")
        _ = s.media(.mute, down: false)
        try expect(!s.held.contains("Mute") && s.everPressed.contains("Mute"), "mute released, remembered")
    }),
    ("resetClearsEverything", {
        let s = KeyState()
        _ = s.keyDown(code: 12)
        s.reset()
        try expect(s.held.isEmpty && s.everPressed.isEmpty, "empty after reset")
    }),
    ("unknownKeyCodeIsIgnored", {
        let s = KeyState()
        try expectEqual(s.keyDown(code: 9999), nil, "unknown")
        try expect(s.everPressed.isEmpty, "nothing recorded")
    }),
])
