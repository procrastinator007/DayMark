import AppKit

@MainActor
enum DaymarkStyle {
    static let stickySize = NSSize(width: 320, height: 190)
    static let dailySize = NSSize(width: 320, height: 330)
    static let scoreSize = NSSize(width: 320, height: 165)
    static let yellow = NSColor(calibratedRed: 0.98, green: 0.91, blue: 0.55, alpha: 1)
    static let green = NSColor(calibratedRed: 0.68, green: 0.91, blue: 0.61, alpha: 1)
    static let blue = NSColor(calibratedRed: 0.62, green: 0.88, blue: 0.94, alpha: 1)
    static let coral = NSColor(calibratedRed: 0.96, green: 0.72, blue: 0.59, alpha: 1)
    static let glassBlue = NSColor(calibratedRed: 0.35, green: 0.52, blue: 0.72, alpha: 1)
    static let ink = NSColor(calibratedWhite: 0.09, alpha: 1)
    static let passiveGlass = NSColor(
        calibratedRed: 0.20,
        green: 0.27,
        blue: 0.36,
        alpha: 0.68
    )

    static let titleFont = NSFont(name: "Times New Roman Bold", size: 17.5)
        ?? NSFont.systemFont(ofSize: 17.5, weight: .bold)
    static let bodyFont = NSFont(name: "Times New Roman", size: 15.5)
        ?? NSFont.systemFont(ofSize: 15.5)
    static let smallFont = NSFont(name: "Times New Roman", size: 12.5)
        ?? NSFont.systemFont(ofSize: 12.5)
    static let scoreTitleFont = NSFont(name: "Times New Roman Bold", size: 13)
        ?? NSFont.systemFont(ofSize: 13, weight: .bold)

    static func configure(_ view: NSView, color: NSColor = passiveGlass) {
        view.wantsLayer = true
        view.layer?.backgroundColor = color.withAlphaComponent(0.82).cgColor
        view.layer?.cornerRadius = 18
        view.layer?.shadowColor = NSColor.black.cgColor
        view.layer?.shadowOpacity = 0.22
        view.layer?.shadowRadius = 12
        view.layer?.shadowOffset = NSSize(width: 0, height: -4)
    }

    static func label(_ text: String, font: NSFont = bodyFont) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.textColor = ink
        label.maximumNumberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.attributedStringValue = attributed(text, font: font)
        return label
    }

    static func textView(editable: Bool) -> NSScrollView {
        let textView = NSTextView()
        textView.isEditable = editable
        textView.isRichText = false
        textView.drawsBackground = false
        textView.font = bodyFont
        textView.textColor = ink
        textView.textContainerInset = NSSize(width: 2, height: 6)
        textView.defaultParagraphStyle = paragraphStyle
        textView.typingAttributes = [
            .font: bodyFont,
            .foregroundColor: ink,
            .paragraphStyle: paragraphStyle
        ]
        textView.textContainer?.widthTracksTextView = true
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.autoresizingMask = [.width]

        let scroll = NSScrollView()
        scroll.documentView = textView
        scroll.hasVerticalScroller = true
        scroll.hasHorizontalScroller = false
        scroll.autohidesScrollers = true
        scroll.drawsBackground = false
        scroll.borderType = .noBorder
        return scroll
    }

    static func setText(_ text: String, in textView: NSTextView) {
        textView.textStorage?.setAttributedString(
            attributed(text, font: bodyFont, color: textView.textColor ?? ink)
        )
    }

    static func applyTextColor(_ color: NSColor, to view: NSView) {
        if let dial = view as? ScoreDialView {
            dial.foregroundColor = color
        } else if let field = view as? NSTextField {
            field.textColor = color
            let mutable = NSMutableAttributedString(attributedString: field.attributedStringValue)
            mutable.addAttribute(.foregroundColor, value: color, range: NSRange(location: 0, length: mutable.length))
            field.attributedStringValue = mutable
        } else if let textView = view as? NSTextView {
            textView.textColor = color
            textView.typingAttributes[.foregroundColor] = color
            textView.textStorage?.addAttribute(
                .foregroundColor,
                value: color,
                range: NSRange(location: 0, length: textView.string.utf16.count)
            )
        } else if let button = view as? NSButton, button.image != nil {
            button.contentTintColor = color
        }
        view.subviews.forEach { applyTextColor(color, to: $0) }
    }

    static func button(_ title: String) -> NSButton {
        let button = NSButton(title: title, target: nil, action: nil)
        button.bezelStyle = .rounded
        button.font = smallFont
        button.contentTintColor = .white
        button.attributedTitle = NSAttributedString(
            string: title,
            attributes: [
                .font: smallFont,
                .foregroundColor: NSColor.white
            ]
        )
        return button
    }

    private static var paragraphStyle: NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 0
        style.paragraphSpacing = 0
        style.paragraphSpacingBefore = 0
        style.lineBreakMode = .byWordWrapping
        return style
    }

    private static func attributed(
        _ text: String,
        font: NSFont,
        color: NSColor = ink
    ) -> NSAttributedString {
        NSAttributedString(
            string: text,
            attributes: [
                .font: font,
                .foregroundColor: color,
                .paragraphStyle: paragraphStyle
            ]
        )
    }
}
