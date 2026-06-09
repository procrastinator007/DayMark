import AppKit

@MainActor
enum DaymarkStyle {
    private static let titleRole = NSUserInterfaceItemIdentifier("Daymark.title")
    private static let bodyRole = NSUserInterfaceItemIdentifier("Daymark.body")
    private static let smallRole = NSUserInterfaceItemIdentifier("Daymark.small")
    private static let scoreTitleRole = NSUserInterfaceItemIdentifier("Daymark.scoreTitle")
    private(set) static var settings = AppSettings.defaults

    static let stickySize = NSSize(width: 320, height: 190)
    static let dailySize = NSSize(width: 320, height: 330)
    static let scoreSize = NSSize(width: 320, height: 165)
    static let yellow = NSColor(calibratedRed: 0.94, green: 0.84, blue: 0.49, alpha: 1)
    // Muted semantic palette: green for action, blue for planning,
    // warm apricot for weekly scope, and slate for reflection.
    static let green = NSColor(calibratedRed: 0.66, green: 0.84, blue: 0.71, alpha: 1)
    static let blue = NSColor(calibratedRed: 0.63, green: 0.82, blue: 0.89, alpha: 1)
    static let coral = NSColor(calibratedRed: 0.91, green: 0.72, blue: 0.62, alpha: 1)
    static let glassBlue = NSColor(calibratedRed: 0.45, green: 0.55, blue: 0.65, alpha: 1)
    static let ink = NSColor(calibratedRed: 0.10, green: 0.13, blue: 0.16, alpha: 1)
    static let passiveGlass = NSColor(
        calibratedRed: 0.20,
        green: 0.27,
        blue: 0.36,
        alpha: 0.68
    )

    static var titleFont: NSFont { font(size: bodyFont.pointSize + 2, bold: true) }
    static var bodyFont: NSFont {
        font(size: CGFloat(settings.fontSize.bodyPointSize), bold: false)
    }
    static var smallFont: NSFont { font(size: max(10, bodyFont.pointSize - 3), bold: false) }
    static var scoreTitleFont: NSFont {
        font(size: max(11, bodyFont.pointSize - 2.5), bold: true)
    }

    static func apply(_ newSettings: AppSettings) {
        settings = newSettings
    }

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
        label.identifier = role(for: font)
        label.attributedStringValue = attributed(text, font: font)
        return label
    }

    static func textView(editable: Bool) -> NSScrollView {
        let textView = NSTextView()
        textView.isEditable = editable
        textView.isRichText = false
        textView.drawsBackground = false
        textView.identifier = bodyRole
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
        } else if let button = view as? NSButton {
            button.contentTintColor = color
            if button.identifier == smallRole {
                button.attributedTitle = buttonTitle(button.title)
            }
        }
        view.subviews.forEach { applyTextColor(color, to: $0) }
    }

    static func applyTypography(to view: NSView) {
        if let field = view as? NSTextField, let font = font(for: field.identifier) {
            field.font = font
            let mutable = NSMutableAttributedString(attributedString: field.attributedStringValue)
            mutable.addAttribute(
                .font,
                value: font,
                range: NSRange(location: 0, length: mutable.length)
            )
            field.attributedStringValue = mutable
        } else if let textView = view as? NSTextView {
            let selectedRange = textView.selectedRange()
            textView.font = bodyFont
            textView.typingAttributes[.font] = bodyFont
            textView.textStorage?.addAttribute(
                .font,
                value: bodyFont,
                range: NSRange(location: 0, length: textView.string.utf16.count)
            )
            textView.setSelectedRange(selectedRange)
        } else if let button = view as? NSButton, button.identifier == smallRole {
            button.font = smallFont
            button.attributedTitle = buttonTitle(button.title)
        }
        view.subviews.forEach { applyTypography(to: $0) }
    }

    static func applyButtonVisibility(to view: NSView) {
        if let button = view as? NSButton, button.identifier == smallRole {
            button.alphaValue = min(1, settings.opacity + 0.10)
            button.contentTintColor = ink
            button.attributedTitle = buttonTitle(button.title)
        }
        view.subviews.forEach { applyButtonVisibility(to: $0) }
    }

    static func button(_ title: String) -> NSButton {
        let button = NSButton(title: title, target: nil, action: nil)
        button.bezelStyle = .rounded
        button.identifier = smallRole
        button.font = smallFont
        button.contentTintColor = ink
        button.attributedTitle = buttonTitle(title)
        button.alphaValue = min(1, settings.opacity + 0.10)
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

    private static func role(for font: NSFont) -> NSUserInterfaceItemIdentifier {
        if abs(font.pointSize - titleFont.pointSize) < 0.2 { return titleRole }
        if abs(font.pointSize - scoreTitleFont.pointSize) < 0.2 { return scoreTitleRole }
        if abs(font.pointSize - smallFont.pointSize) < 0.2 { return smallRole }
        return bodyRole
    }

    private static func font(for identifier: NSUserInterfaceItemIdentifier?) -> NSFont? {
        switch identifier {
        case titleRole: titleFont
        case scoreTitleRole: scoreTitleFont
        case smallRole: smallFont
        case bodyRole: bodyFont
        default: nil
        }
    }

    private static func font(size: CGFloat, bold: Bool) -> NSFont {
        let base: NSFont
        switch settings.fontName {
        case .systemDefault:
            return NSFont.systemFont(
                ofSize: size,
                weight: bold ? .bold : .regular
            )
        default:
            base = NSFont(name: settings.fontName.rawValue, size: size)
                ?? NSFont.systemFont(ofSize: size)
        }
        guard bold else { return base }
        return NSFontManager.shared.convert(base, toHaveTrait: .boldFontMask)
    }

    private static func buttonTitle(_ title: String) -> NSAttributedString {
        NSAttributedString(
            string: title,
            attributes: [
                .font: smallFont,
                .foregroundColor: ink
            ]
        )
    }
}
