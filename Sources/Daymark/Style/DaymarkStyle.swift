import AppKit

@MainActor
enum DaymarkStyle {
    static let yellow = NSColor(calibratedRed: 0.98, green: 0.91, blue: 0.55, alpha: 1)
    static let green = NSColor(calibratedRed: 0.68, green: 0.91, blue: 0.61, alpha: 1)
    static let blue = NSColor(calibratedRed: 0.62, green: 0.88, blue: 0.94, alpha: 1)
    static let coral = NSColor(calibratedRed: 0.96, green: 0.72, blue: 0.59, alpha: 1)
    static let ink = NSColor(calibratedWhite: 0.09, alpha: 1)

    static let titleFont = NSFont.systemFont(ofSize: 18, weight: .bold)
    static let bodyFont = NSFont.systemFont(ofSize: 15, weight: .medium)
    static let smallFont = NSFont.systemFont(ofSize: 11, weight: .medium)

    static func configure(_ view: NSView, color: NSColor) {
        view.wantsLayer = true
        view.layer?.backgroundColor = color.cgColor
        view.layer?.cornerRadius = 2
        view.layer?.shadowColor = NSColor.black.cgColor
        view.layer?.shadowOpacity = 0.22
        view.layer?.shadowRadius = 12
        view.layer?.shadowOffset = NSSize(width: 0, height: -4)
    }

    static func label(_ text: String, font: NSFont = bodyFont) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = font
        label.textColor = ink
        label.maximumNumberOfLines = 0
        label.lineBreakMode = .byWordWrapping
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

        let scroll = NSScrollView()
        scroll.documentView = textView
        scroll.hasVerticalScroller = true
        scroll.drawsBackground = false
        scroll.borderType = .noBorder
        return scroll
    }

    static func button(_ title: String) -> NSButton {
        let button = NSButton(title: title, target: nil, action: nil)
        button.bezelStyle = .rounded
        button.font = smallFont
        button.contentTintColor = ink
        return button
    }
}
