import AppKit

final class StickyPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

@MainActor
class StickyWindowController: NSWindowController, NSWindowDelegate {
    let content = NSView()
    let stack = NSStackView()
    private let accentColor: NSColor

    init(
        title: String,
        color: NSColor,
        frame: NSRect,
        autosaveName: String,
        size: NSSize = DaymarkStyle.stickySize,
        showsHeading: Bool = true
    ) {
        self.accentColor = color
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
        window.minSize = size
        window.maxSize = size
        window.contentMinSize = size
        window.contentMaxSize = size
        window.setContentSize(size)
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.alphaValue = 1
        super.init(window: window)
        window.delegate = self

        DaymarkStyle.configure(content)
        window.contentView = content
        content.widthAnchor.constraint(equalToConstant: size.width).isActive = true
        content.heightAnchor.constraint(equalToConstant: size.height).isActive = true

        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 7
        stack.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(stack)

        if showsHeading {
            let heading = DaymarkStyle.label(title, font: DaymarkStyle.titleFont)
            stack.addArrangedSubview(heading)
            heading.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        }

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: content.topAnchor, constant: 15),
            stack.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -15)
        ])
        applySelectedAppearance(false, animated: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show() {
        setEditingAppearance(false)
        window?.orderFront(nil)
    }

    func setEditingAppearance(_ isEditing: Bool) {
        applySelectedAppearance(isEditing, animated: true)
    }

    func apply(settings: AppSettings) {
        window?.level = settings.alwaysOnTop ? .floating : .normal
        DaymarkStyle.applyTypography(to: content)
        DaymarkStyle.applyButtonVisibility(to: content)
        applySelectedAppearance(window?.firstResponder is NSTextView, animated: false)
    }

    func addSettingsButton(target: AnyObject, action: Selector) {
        let button = NSButton(
            image: NSImage(
                systemSymbolName: "gearshape.fill",
                accessibilityDescription: "Settings"
            ) ?? NSImage(),
            target: target,
            action: action
        )
        button.isBordered = false
        button.contentTintColor = DaymarkStyle.ink
        button.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(button)
        NSLayoutConstraint.activate([
            button.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -11),
            button.topAnchor.constraint(equalTo: content.topAnchor, constant: 9),
            button.widthAnchor.constraint(equalToConstant: 24),
            button.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    private func applySelectedAppearance(_ selected: Bool, animated: Bool) {
        let changes = {
            self.content.layer?.backgroundColor = self.accentColor.withAlphaComponent(
                selected
                    ? min(1, DaymarkStyle.settings.opacity + 0.18)
                    : DaymarkStyle.settings.opacity
            ).cgColor
            self.window?.alphaValue = 1
            DaymarkStyle.applyTextColor(DaymarkStyle.ink, to: self.content)
            DaymarkStyle.applyButtonVisibility(to: self.content)
        }
        guard animated else {
            changes()
            return
        }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.18
            changes()
        }
    }

    func windowDidBecomeKey(_ notification: Notification) {
        setEditingAppearance(true)
    }

    func windowDidResignKey(_ notification: Notification) {
        setEditingAppearance(false)
    }
}
