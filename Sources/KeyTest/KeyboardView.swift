import AppKit
import KeyTestCore

/// 참고 이미지의 키보드: 살구색 베젤 + 짙은 키캡. 누르는 중=보라, 눌렀던 키=연한 살구색.
final class KeyboardView: NSView {
    let state: KeyState
    var bannerText: String? { didSet { needsDisplay = true } }

    init(frame: NSRect, state: KeyState) {
        self.state = state
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        NSGradient(starting: NSColor(hex: 0xB8A49E), ending: NSColor(hex: 0x8A7772))?
            .draw(in: bounds, angle: 90)

        if let banner = bannerText {
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 13, weight: .medium),
                .foregroundColor: NSColor(hex: 0x3A1F1B),
            ]
            banner.draw(in: NSRect(x: 32, y: 9, width: bounds.width - 64, height: 20), withAttributes: attrs)
        }

        let caseRect = NSRect(x: 30, y: 36, width: bounds.width - 60, height: bounds.height - 60)
        NSColor(hex: 0xDEC7BA).setFill()
        NSBezierPath(roundedRect: caseRect, xRadius: 10, yRadius: 10).fill()
        let inner = caseRect.insetBy(dx: 8, dy: 8)
        NSColor(hex: 0x1F1F20).setFill()
        NSBezierPath(roundedRect: inner, xRadius: 7, yRadius: 7).fill()

        let area = inner.insetBy(dx: 10, dy: 10)
        let unit = min(area.width / CGFloat(Layout.width), area.height / CGFloat(Layout.height))
        let originX = area.minX + (area.width - unit * CGFloat(Layout.width)) / 2
        let originY = area.minY + (area.height - unit * CGFloat(Layout.height)) / 2

        for cell in Layout.all {
            let rect = NSRect(x: originX + CGFloat(cell.x) * unit + 1.5,
                              y: originY + CGFloat(cell.y) * unit + 1.5,
                              width: CGFloat(cell.width) * unit - 3,
                              height: CGFloat(cell.height) * unit - 3)
            drawKey(cell, in: rect, unit: unit)
        }
    }

    private func drawKey(_ cell: KeyCell, in rect: NSRect, unit: CGFloat) {
        let held = state.held.contains(cell.id)
        let pressed = state.everPressed.contains(cell.id)
        let fill: NSColor
        let stroke: NSColor
        let text: NSColor
        if held {
            fill = NSColor(hex: 0x8B1E7D); stroke = NSColor(hex: 0xA2339A); text = NSColor(hex: 0xE3A6DB)
        } else if pressed {
            fill = NSColor(hex: 0xE4CCBF); stroke = NSColor(hex: 0xF0DDD2); text = NSColor(hex: 0x2A2220)
        } else {
            fill = NSColor(hex: 0x333335); stroke = NSColor(hex: 0x454547); text = NSColor(hex: 0xDADADA)
        }
        let path = NSBezierPath(roundedRect: rect, xRadius: 4, yRadius: 4)
        fill.setFill()
        path.fill()
        stroke.setStroke()
        path.lineWidth = 1
        path.stroke()

        if cell.caption.count == 1 {
            let isBig = cell.label.count == 1 && cell.label.unicodeScalars.allSatisfy { $0.properties.isAlphabetic }
            let size = isBig ? unit * 0.40 : unit * 0.24
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: size, weight: isBig ? .semibold : .regular),
                .foregroundColor: text,
            ]
            let textSize = cell.caption[0].size(withAttributes: attrs)
            let y = isBig ? rect.minY + 3 : rect.midY - textSize.height / 2
            cell.caption[0].draw(at: NSPoint(x: rect.minX + 6, y: y), withAttributes: attrs)
        } else {
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: unit * 0.26, weight: .regular),
                .foregroundColor: text,
            ]
            let lineHeight = cell.caption[0].size(withAttributes: attrs).height
            cell.caption[0].draw(at: NSPoint(x: rect.minX + 6, y: rect.minY + 3), withAttributes: attrs)
            cell.caption[1].draw(at: NSPoint(x: rect.minX + 6, y: rect.minY + 3 + lineHeight), withAttributes: attrs)
        }
    }
}
