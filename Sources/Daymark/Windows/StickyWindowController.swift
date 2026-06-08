import AppKit

final class StickyPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

@MainActor
class StickyWindowController: NSWindowController {
    let content = NSView()
    let stack = NSStackView()

    init(title: String, color: NSColor, frame: NSRect, autosaveName: String) {
        let window = StickyPanel(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        window.title = title
        window.level = .floating
        window.isMovableByWindowBackground = true
        window.hidesOnDeactivate = false
        // Floating on the desktop, but excluded from other apps' full-screen spaces.
        window.collectionBehavior = [.managed, .ignoresCycle]
        window.isReleasedWhenClosed = false
        window.becomesKeyOnlyIfNeeded = true
        window.setFrameAutosaveName(autosaveName)
        window.minSize = DaymarkStyle.stickySize
        window.maxSize = DaymarkStyle.stickySize
        window.setContentSize(DaymarkStyle.stickySize)
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        super.init(window: window)

        DaymarkStyle.configure(content, color: color)
        window.contentView = content

        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 7
        stack.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(stack)

        let heading = DaymarkStyle.label(title, font: DaymarkStyle.titleFont)
        stack.addArrangedSubview(heading)
        heading.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: content.topAnchor, constant: 15),
            stack.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -15)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show() {
        window?.orderFrontRegardless()
    }
}
