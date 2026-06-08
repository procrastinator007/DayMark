import AppKit

@MainActor
final class ScoreDialView: NSView {
    var foregroundColor = DaymarkStyle.ink {
        didSet { needsDisplay = true }
    }

    var score = 0 {
        didSet { needsDisplay = true }
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: 150, height: 150)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let center = NSPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) / 2 - 4

        let outerRect = NSRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        )
        foregroundColor.withAlphaComponent(0.13).setFill()
        NSBezierPath(ovalIn: outerRect).fill()

        foregroundColor.withAlphaComponent(0.82).setStroke()
        let outerRing = NSBezierPath(ovalIn: outerRect.insetBy(dx: 1, dy: 1))
        outerRing.lineWidth = 2.5
        outerRing.stroke()

        foregroundColor.withAlphaComponent(0.28).setStroke()
        let innerRing = NSBezierPath(ovalIn: outerRect.insetBy(dx: 7, dy: 7))
        innerRing.lineWidth = 1
        innerRing.stroke()

        drawTicks(center: center, radius: radius)
        drawLabels(center: center, radius: radius)
        drawHand(center: center, radius: radius)
        drawScore(center: center)
    }

    private func drawTicks(center: NSPoint, radius: CGFloat) {
        for value in stride(from: 0, through: 100, by: 5) {
            let angle = angleForScore(value)
            let outer = point(center: center, radius: radius - 8, angle: angle)
            let tickLength: CGFloat = value % 20 == 0 ? 10 : 5
            let inner = point(
                center: center,
                radius: radius - 8 - tickLength,
                angle: angle
            )
            let path = NSBezierPath()
            path.move(to: inner)
            path.line(to: outer)
            path.lineWidth = value % 20 == 0 ? 1.8 : 0.8
            foregroundColor.withAlphaComponent(0.85).setStroke()
            path.stroke()
        }
    }

    private func drawLabels(center: NSPoint, radius: CGFloat) {
        let font = NSFontManager.shared.convert(
            NSFont.systemFont(ofSize: 8.5, weight: .medium),
            toHaveTrait: .italicFontMask
        )
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: foregroundColor.withAlphaComponent(0.92)
        ]

        for value in stride(from: 0, through: 100, by: 20) {
            let label = "\(value)"
            let size = label.size(withAttributes: attributes)
            let location = point(
                center: center,
                radius: radius - 24,
                angle: angleForScore(value)
            )
            label.draw(
                at: NSPoint(
                    x: location.x - size.width / 2,
                    y: location.y - size.height / 2
                ),
                withAttributes: attributes
            )
        }
    }

    private func drawHand(center: NSPoint, radius: CGFloat) {
        let angle = angleForScore(score)
        let endpoint = point(center: center, radius: radius * 0.62, angle: angle)
        let tail = point(center: center, radius: radius * 0.13, angle: angle + .pi)
        let path = NSBezierPath()
        path.move(to: tail)
        path.line(to: endpoint)
        path.lineWidth = 2.6
        path.lineCapStyle = .round
        foregroundColor.setStroke()
        path.stroke()

        foregroundColor.setFill()
        NSBezierPath(ovalIn: NSRect(
            x: center.x - 4,
            y: center.y - 4,
            width: 8,
            height: 8
        )).fill()
    }

    private func drawScore(center: NSPoint) {
        let text = "\(score)"
        let baseFont = NSFont.systemFont(ofSize: 24, weight: .semibold)
        let font = NSFontManager.shared.convert(baseFont, toHaveTrait: .italicFontMask)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: foregroundColor
        ]
        let size = text.size(withAttributes: attributes)
        text.draw(
            at: NSPoint(x: center.x - size.width / 2, y: center.y - radiusOffset),
            withAttributes: attributes
        )
    }

    private var radiusOffset: CGFloat {
        min(bounds.width, bounds.height) * 0.28
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
