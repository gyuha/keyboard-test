import AppKit
import KeyTestCore

/// CGEventTap 설치와 콜백. 판단은 전부 코어의 EventTapPolicy.decide가 한다.
final class EventTapController {
    private var tap: CFMachPort?
    private var source: CFRunLoopSource?
    private let state: KeyState
    private let onPress: (String) -> Void
    private let onChange: () -> Void
    private let onQuit: () -> Void

    var captureEnabled = true
    var isInstalled: Bool { tap != nil }

    init(state: KeyState, onPress: @escaping (String) -> Void, onChange: @escaping () -> Void, onQuit: @escaping () -> Void) {
        self.state = state
        self.onPress = onPress
        self.onChange = onChange
        self.onQuit = onQuit
    }

    /// 권한이 없으면 false (탭이 만들어지지 않는다).
    @discardableResult
    func install() -> Bool {
        if tap != nil { return true }
        let callback: CGEventTapCallBack = { _, type, event, info in
            guard let info else { return Unmanaged.passUnretained(event) }
            return Unmanaged<EventTapController>.fromOpaque(info).takeUnretainedValue().handle(type: type, event: event)
        }
        guard let port = CGEvent.tapCreate(tap: TapConfig.location, place: TapConfig.placement,
                                           options: TapConfig.options, eventsOfInterest: TapConfig.mask,
                                           callback: callback, userInfo: Unmanaged.passUnretained(self).toOpaque()) else {
            return false
        }
        tap = port
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, port, 0)
        source = runLoopSource
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: port, enable: true)
        return true
    }

    private func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        let context = TapContext(captureEnabled: captureEnabled, appActive: NSApp.isActive)
        let decision = EventTapPolicy.decide(type: type, event: event, context: context, state: state)
        if let id = decision.pressedKeyID { onPress(id) }
        if type == .keyDown || type == .keyUp || type == .flagsChanged || type == TapConfig.systemDefined { onChange() }
        switch decision.verdict {
        case .pass:
            return Unmanaged.passUnretained(event)
        case .consume:
            return nil
        case .quit:
            DispatchQueue.main.async { [onQuit] in onQuit() }
            return nil
        case .reenable:
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            return Unmanaged.passUnretained(event)
        }
    }
}
