import AppKit
import CoreGraphics

public enum TapVerdict: Equatable {
    case pass
    case consume
    case quit
    case reenable
}

public struct TapContext: Equatable {
    public var captureEnabled: Bool
    public var appActive: Bool

    public init(captureEnabled: Bool, appActive: Bool) {
        self.captureEnabled = captureEnabled
        self.appActive = appActive
    }
}

public struct TapDecision: Equatable {
    public let verdict: TapVerdict
    /// 이번 이벤트로 새로 눌린 키 (소리를 낼 대상). 키 반복·keyUp·이미 눌린 키는 nil.
    public let pressedKeyID: String?
}

public enum TapPermission: Equatable {
    case granted
    case missingAccessibility
    case missingInputMonitoring
    case missingBoth

    public static func classify(accessibilityTrusted: Bool, inputMonitoringAllowed: Bool) -> TapPermission {
        switch (accessibilityTrusted, inputMonitoringAllowed) {
        case (true, true): return .granted
        case (false, true): return .missingAccessibility
        case (true, false): return .missingInputMonitoring
        case (false, false): return .missingBoth
        }
    }
}

public enum TapConfig {
    /// listenOnly가 아니어야 이벤트를 소비(차단)할 수 있다.
    public static let options: CGEventTapOptions = .defaultTap
    public static let placement: CGEventTapPlacement = .headInsertEventTap
    public static let location: CGEventTapLocation = .cghidEventTap
    public static let systemDefined = CGEventType(rawValue: 14)!
    public static let eventTypes: [CGEventType] = [.keyDown, .keyUp, .flagsChanged, systemDefined]

    public static var mask: CGEventMask {
        eventTypes.reduce(0) { $0 | (CGEventMask(1) << CGEventMask($1.rawValue)) }
    }
}

public enum MediaKeyEvent {
    /// NX_SYSDEFINED 보조 키 이벤트(subtype 8)의 data1을 해석한다.
    public static func parse(data1: Int, subtype: Int) -> (key: MediaKey, down: Bool)? {
        guard subtype == 8 else { return nil }
        let keyCode = (data1 & 0xFFFF_0000) >> 16
        let keyFlags = data1 & 0x0000_FFFF
        guard let key = MediaKey(rawValue: keyCode) else { return nil }
        return (key, ((keyFlags & 0xFF00) >> 8) == 0xA)
    }
}

public enum EventTapPolicy {
    /// 비상 종료: ⌃⌥⌘Q (Q 키코드 12)
    static func isPanicChord(code: Int, flags: CGEventFlags) -> Bool {
        code == 12 && flags.contains([.maskControl, .maskAlternate, .maskCommand])
    }

    /// 탭 콜백이 위임하는 순수 판단. 앱이 비활성이면 아무것도 기록·차단하지 않는다.
    public static func decide(type: CGEventType, event: CGEvent, context: TapContext, state: KeyState) -> TapDecision {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            return TapDecision(verdict: .reenable, pressedKeyID: nil)
        }
        guard TapConfig.eventTypes.contains(type), context.appActive else {
            return TapDecision(verdict: .pass, pressedKeyID: nil)
        }

        var pressed: String?
        switch type {
        case .keyDown:
            let code = Int(event.getIntegerValueField(.keyboardEventKeycode))
            if isPanicChord(code: code, flags: event.flags) {
                return TapDecision(verdict: .quit, pressedKeyID: nil)
            }
            let isRepeat = event.getIntegerValueField(.keyboardEventAutorepeat) != 0
            let id = state.keyDown(code: code)
            pressed = isRepeat ? nil : id
        case .keyUp:
            state.keyUp(code: Int(event.getIntegerValueField(.keyboardEventKeycode)))
        case .flagsChanged:
            pressed = state.flagsChanged(code: Int(event.getIntegerValueField(.keyboardEventKeycode)), flags: event.flags)
        default:
            if let ns = NSEvent(cgEvent: event), ns.type == .systemDefined,
               let media = MediaKeyEvent.parse(data1: ns.data1, subtype: Int(ns.subtype.rawValue)) {
                pressed = state.media(media.key, down: media.down)
            }
        }
        return TapDecision(verdict: context.captureEnabled ? .consume : .pass, pressedKeyID: pressed)
    }
}
