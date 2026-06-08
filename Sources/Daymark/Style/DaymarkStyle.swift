import AppKit

@MainActor
enum DaymarkStyle {
    static let stickySize = NSSize(width: 320, height: 270)
    static let scoreSize = NSSize(width: 210, height: 270)
    static let yellow = NSColor(calibratedRed: 0.98, green: 0.91, blue: 0.55, alpha: 1)
    static let green = NSColor(calibratedRed: 0.68, green: 0.91, blue: 0.61, alpha: 1)
    static let blue = NSColor(calibratedRed: 0.62, green: 0.88, blue: 0.94, alpha: 1)
    static let coral = NSColor(calibratedRed: 0.96, green: 0.72, blue: 0.59, alpha: 1)
    static let glassBlue = NSColor(calibratedRed: 0.35, green: 0.52, blue: 0.72, alpha: 1)
    static let ink = NSColor(calibratedWhite: 0.09, alpha: 1)

    static let titleFont = NSFont(name: "Times New Roman Bold", size: 19)
        ?? NSFont.systemFont(ofSize: 19, weight: .bold)
    static let bodyFont = NSFont(name: "Times New Roman", size: 16)
        ?? NSFont.systemFont(ofSize: 16)
    static let smallFont = NSFont(name: "Times New Roman", size: 12)
        ?? NSFont.systemFont(ofSize: 12)

    static func configure(_ view: NSView, color: NSColor) {
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
        textView.textStorage?.setAttributedString(attributed(text, font: bodyFont))
    }

    static func button(_ title: String) -> NSButton {
        let button = NSButton(title: title, target: nil, action: nil)
        button.bezelStyle = .rounded
        button.font = smallFont
        button.contentTintColor = ink
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

    private static func attributed(_ text: String, font: NSFont) -> NSAttributedString {
        NSAttributedString(
            string: text,
            attributes: [
                .font: font,
                .foregroundColor: ink,
                .paragraphStyle: paragraphStyle
            ]
        )
    }
}
