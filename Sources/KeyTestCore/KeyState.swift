import CoreGraphics

/// 어떤 키가 눌리는 중인지(held), 한 번이라도 눌렸는지(everPressed)를 기록한다.
public final class KeyState {
    public private(set) var held = Set<String>()
    public private(set) var everPressed = Set<String>()

    public init() {}

    private static let modifierMasks: [Int: CGEventFlags] = [
        56: .maskShift, 60: .maskShift,
        59: .maskControl, 62: .maskControl,
        58: .maskAlternate, 61: .maskAlternate,
        55: .maskCommand, 54: .maskCommand,
        57: .maskAlphaShift,
        63: .maskSecondaryFn,
    ]

    /// 새로 눌린 키의 id를 돌려준다. 이미 눌려 있으면(키 반복) nil.
    @discardableResult
    public func keyDown(code: Int) -> String? {
        guard let cell = Layout.cell(forKeyCode: code) else { return nil }
        return press(cell.id)
    }

    public func keyUp(code: Int) {
        guard let cell = Layout.cell(forKeyCode: code) else { return }
        held.remove(cell.id)
    }

    /// 수정키는 flagsChanged로만 온다. 키코드로 좌/우를 구분하고 flags의 해당 비트로 눌림/뗌을 판단한다.
    @discardableResult
    public func flagsChanged(code: Int, flags: CGEventFlags) -> String? {
        guard let mask = Self.modifierMasks[code], let cell = Layout.cell(forKeyCode: code) else { return nil }
        if flags.contains(mask), !held.contains(cell.id) {
            return press(cell.id)
        }
        held.remove(cell.id)
        return nil
    }

    @discardableResult
    public func media(_ key: MediaKey, down: Bool) -> String? {
        guard let cell = Layout.cell(forMedia: key) else { return nil }
        if down { return press(cell.id) }
        held.remove(cell.id)
        return nil
    }

    public func reset() {
        held.removeAll()
        everPressed.removeAll()
    }

    private func press(_ id: String) -> String? {
        everPressed.insert(id)
        return held.insert(id).inserted ? id : nil
    }
}
