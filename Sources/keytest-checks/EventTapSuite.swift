import AppKit
import CoreGraphics
import KeyTestCore

private func keyEvent(_ code: CGKeyCode, down: Bool = true, flags: CGEventFlags = [], repeatCount: Int64 = 0) throws -> CGEvent {
    guard let e = CGEvent(keyboardEventSource: nil, virtualKey: code, keyDown: down) else {
        throw CheckFailure(description: "CGEvent 생성 실패")
    }
    e.flags = flags
    e.setIntegerValueField(.keyboardEventAutorepeat, value: repeatCount)
    return e
}

private let capturing = TapContext(captureEnabled: true, appActive: true)

let eventTapSuite = Suite(name: "EventTap", tests: [
    ("cmdTabIsConsumedAndLit", {
        let state = KeyState()
        let e = try keyEvent(48, flags: .maskCommand)
        let d = EventTapPolicy.decide(type: .keyDown, event: e, context: capturing, state: state)
        try expectEqual(d.verdict, .consume, "Cmd+Tab verdict")
        try expectEqual(d.pressedKeyID, "Tab", "pressed key")
        try expect(state.held.contains("Tab"), "Tab lit")
    }),
    ("modifierFlagsChangedIsConsumedAndLit", {
        let state = KeyState()
        let e = try keyEvent(58, flags: .maskAlternate)
        e.type = .flagsChanged
        let d = EventTapPolicy.decide(type: .flagsChanged, event: e, context: capturing, state: state)
        try expectEqual(d.verdict, .consume, "Option verdict")
        try expect(state.held.contains("LAlt"), "LAlt lit")
    }),
    ("passesThroughWhenCaptureOff", {
        let state = KeyState()
        let e = try keyEvent(48, flags: .maskCommand)
        let d = EventTapPolicy.decide(type: .keyDown, event: e,
                                      context: TapContext(captureEnabled: false, appActive: true), state: state)
        try expectEqual(d.verdict, .pass, "capture off")
    }),
    ("passesThroughAndRecordsNothingWhenAppInactive", {
        let state = KeyState()
        let e = try keyEvent(48, flags: .maskCommand)
        let d = EventTapPolicy.decide(type: .keyDown, event: e,
                                      context: TapContext(captureEnabled: true, appActive: false), state: state)
        try expectEqual(d.verdict, .pass, "inactive")
        try expect(state.everPressed.isEmpty, "nothing recorded while inactive")
    }),
    ("tapConfigIsActiveHeadInsertWithAllKeyTypes", {
        try expect(TapConfig.options == .defaultTap, "must be defaultTap (not listenOnly)")
        try expect(TapConfig.placement == .headInsertEventTap, "head insert")
        try expect(TapConfig.location == .cghidEventTap, "HID level")
        for type in [CGEventType.keyDown, .keyUp, .flagsChanged, TapConfig.systemDefined] {
            try expect(TapConfig.mask & (CGEventMask(1) << CGEventMask(type.rawValue)) != 0, "mask has \(type.rawValue)")
        }
    }),
    ("panicChordRequestsQuit", {
        let state = KeyState()
        let e = try keyEvent(12, flags: [.maskControl, .maskAlternate, .maskCommand])
        let d = EventTapPolicy.decide(type: .keyDown, event: e, context: capturing, state: state)
        try expectEqual(d.verdict, .quit, "panic chord")
        let plain = try keyEvent(12, flags: .maskCommand)
        let d2 = EventTapPolicy.decide(type: .keyDown, event: plain, context: capturing, state: state)
        try expectEqual(d2.verdict, .consume, "Cmd+Q alone is only captured, not quit")
    }),
    ("timeoutRequestsReenable", {
        let state = KeyState()
        let e = try keyEvent(0)
        for type in [CGEventType.tapDisabledByTimeout, .tapDisabledByUserInput] {
            let d = EventTapPolicy.decide(type: type, event: e, context: capturing, state: state)
            try expectEqual(d.verdict, .reenable, "disabled tap \(type.rawValue)")
        }
    }),
    ("permissionStatesAreDistinguished", {
        try expectEqual(TapPermission.classify(accessibilityTrusted: true, inputMonitoringAllowed: true), .granted, "ok")
        try expectEqual(TapPermission.classify(accessibilityTrusted: false, inputMonitoringAllowed: true), .missingAccessibility, "ax")
        try expectEqual(TapPermission.classify(accessibilityTrusted: true, inputMonitoringAllowed: false), .missingInputMonitoring, "im")
        try expectEqual(TapPermission.classify(accessibilityTrusted: false, inputMonitoringAllowed: false), .missingBoth, "both")
    }),
    ("autorepeatDoesNotReportANewPress", {
        let state = KeyState()
        let first = EventTapPolicy.decide(type: .keyDown, event: try keyEvent(0), context: capturing, state: state)
        try expectEqual(first.pressedKeyID, "A", "first press")
        let rep = EventTapPolicy.decide(type: .keyDown, event: try keyEvent(0, repeatCount: 1), context: capturing, state: state)
        try expectEqual(rep.pressedKeyID, nil, "autorepeat")
        try expectEqual(rep.verdict, .consume, "autorepeat still consumed")
    }),
    ("mediaKeyDataIsParsed", {
        let down = MediaKeyEvent.parse(data1: (7 << 16) | (0xA << 8), subtype: 8)
        try expect(down?.key == .mute && down?.down == true, "mute down")
        let up = MediaKeyEvent.parse(data1: (0 << 16) | (0xB << 8), subtype: 8)
        try expect(up?.key == .volumeUp && up?.down == false, "vol up release")
        try expect(MediaKeyEvent.parse(data1: 7 << 16, subtype: 7) == nil, "other subtype ignored")
    }),
    ("systemDefinedEventLightsMediaKey", {
        guard let ns = NSEvent.otherEvent(with: .systemDefined, location: .zero, modifierFlags: [], timestamp: 0,
                                          windowNumber: 0, context: nil, subtype: 8,
                                          data1: (1 << 16) | (0xA << 8), data2: -1),
              let cg = ns.cgEvent else {
            throw CheckFailure(description: "systemDefined NSEvent/CGEvent 생성 실패")
        }
        let state = KeyState()
        let d = EventTapPolicy.decide(type: TapConfig.systemDefined, event: cg, context: capturing, state: state)
        try expectEqual(d.verdict, .consume, "media verdict")
        try expect(state.held.contains("Vol-"), "Vol- lit")
    }),
])
