import AppKit
import KeyTestCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let state = KeyState()
    private var settings = SoundSettings.load(from: .standard)
    private let audio = AudioPlayer()
    private var window: NSWindow!
    private var root: RootView!
    private var tap: EventTapController!
    private var monitor: Any?
    private var retryTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        installMenu()

        root = RootView(state: state, settings: settings)
        root.panel.onChange = { [weak self] new in
            self?.settings = new
            new.save(to: .standard)
        }
        root.panel.onReset = { [weak self] in self?.resetAll() }

        window = NSWindow(contentRect: NSRect(origin: .zero, size: RootView.size),
                          styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
        window.title = "KeyTest"
        window.appearance = NSAppearance(named: .darkAqua)
        window.contentView = root
        window.isReleasedWhenClosed = false
        window.center()
        window.makeKeyAndOrderFront(nil)

        tap = EventTapController(state: state,
                                 onPress: { [weak self] id in self?.keyPressed(id) },
                                 onChange: { [weak self] in self?.root.keyboard.needsDisplay = true },
                                 onQuit: { NSApp.terminate(nil) })

        Permission.requestPrompts()
        installLocalMonitor()
        refreshTap()
        retryTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in self?.refreshTap() }
        audio.start()
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    /// 탭이 아직 없으면 설치를 시도하고, 권한 안내 배너를 갱신한다.
    private func refreshTap() {
        if tap.install() {
            root.keyboard.bannerText = nil
        } else {
            let permission = Permission.current()
            root.keyboard.bannerText = UIStrings.permissionBanner(permission)
                ?? "키 이벤트 탭을 만들지 못했습니다. 앱을 다시 실행해 보세요."
        }
    }

    /// 탭이 없을 때(권한 전)의 대체 경로: 이 앱 창 안의 키만 켠다. 시스템 조합키는 막지 못한다.
    private func installLocalMonitor() {
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp, .flagsChanged, .systemDefined]) { [weak self] event in
            guard let self, !self.tap.isInstalled, let cg = event.cgEvent else { return event }
            let decision = EventTapPolicy.decide(type: cg.type, event: cg,
                                                 context: TapContext(captureEnabled: false, appActive: true), state: self.state)
            if decision.verdict == .quit {
                NSApp.terminate(nil)
                return nil
            }
            if let id = decision.pressedKeyID { self.keyPressed(id) }
            self.root.keyboard.needsDisplay = true
            return (event.type == .keyDown || event.type == .keyUp) ? nil : event
        }
    }

    private func keyPressed(_ id: String) {
        guard SoundTrigger.shouldPlay(enabled: settings.enabled, isDown: true, isRepeat: false, isNewPress: true),
              let cell = Layout.cell(id: id) else { return }
        audio.play(samples: NoteRenderer.render(frequency: settings.frequency(for: cell), waveform: settings.waveform,
                                                volume: settings.volume, sampleRate: audio.sampleRate))
    }

    private func resetAll() {
        state.reset()
        settings.reset()
        settings.save(to: .standard)
        root.panel.load(settings)
        root.keyboard.needsDisplay = true
    }

    private func installMenu() {
        let mainMenu = NSMenu()
        let appItem = NSMenuItem()
        mainMenu.addItem(appItem)
        let appMenu = NSMenu()
        appMenu.addItem(NSMenuItem(title: "KeyTest 종료", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        appItem.submenu = appMenu
        NSApp.mainMenu = mainMenu
    }
}
