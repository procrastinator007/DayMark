import AppKit

@MainActor
final class ScoreDialView: NSView {
    var score = 0 {
        didSet { needsDisplay = true }
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: 142, height: 142)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let center = NSPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) / 2 - 12

        NSColor.white.withAlphaComponent(0.22).setFill()
        NSBezierPath(ovalIn: NSRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        )).fill()

        drawTicks(center: center, radius: radius)
        drawHand(center: center, radius: radius)
        drawScore(center: center)
    }

    private func drawTicks(center: NSPoint, radius: CGFloat) {
        for value in stride(from: 0, through: 100, by: 10) {
            let angle = angleForScore(value)
            let outer = point(center: center, radius: radius - 5, angle: angle)
            let inner = point(center: center, radius: radius - 11, angle: angle)
            let path = NSBezierPath()
            path.move(to: inner)
            path.line(to: outer)
            path.lineWidth = value % 20 == 0 ? 2 : 1
            NSColor.white.withAlphaComponent(0.85).setStroke()
            path.stroke()
        }
    }

    private func drawHand(center: NSPoint, radius: CGFloat) {
        let angle = angleForScore(score)
        let endpoint = point(center: center, radius: radius * 0.67, angle: angle)
        let path = NSBezierPath()
        path.move(to: center)
        path.line(to: endpoint)
        path.lineWidth = 5
        path.lineCapStyle = .round
        NSColor.white.setStroke()
        path.stroke()

        NSColor.white.setFill()
        NSBezierPath(ovalIn: NSRect(
            x: center.x - 5,
            y: center.y - 5,
            width: 10,
            height: 10
        )).fill()
    }

    private func drawScore(center: NSPoint) {
        let text = "\(score)"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont(name: "Times New Roman Bold", size: 24)
                ?? NSFont.boldSystemFont(ofSize: 24),
            .foregroundColor: NSColor.white
        ]
        let size = text.size(withAttributes: attributes)
        text.draw(
            at: NSPoint(x: center.x - size.width / 2, y: center.y - 43),
            withAttributes: attributes
        )
    }

    private func angleForScore(_ value: Int) -> CGFloat {
        let degrees = 225 - (Double(value) / 100.0 * 270)
        return CGFloat(degrees * .pi / 180)
    }

    private func point(center: NSPoint, radius: CGFloat, angle: CGFloat) -> NSPoint {
        NSPoint(
            x: center.x + cos(angle) * radius,
            y: center.y + sin(angle) * radius
        )
    }
}
