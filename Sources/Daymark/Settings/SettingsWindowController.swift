import AppKit

@MainActor
final class SettingsWindowController: NSWindowController {
    private let settingsStore: SettingsStore
    private let daymarkStore: DaymarkStore
    private let onQuit: () -> Void
    private let alignmentControl = NSSegmentedControl(
        labels: ["Left edge", "Right edge"],
        trackingMode: .selectOne,
        target: nil,
        action: nil
    )
    private let floatingToggle = NSButton(
        checkboxWithTitle: "Keep stickies above other windows",
        target: nil,
        action: nil
    )
    private let opacitySlider = NSSlider(
        value: 0.78,
        minValue: 0.4,
        maxValue: 1,
        target: nil,
        action: nil
    )
    private let opacityLabel = NSTextField(labelWithString: "78%")
    private let fontControl = NSPopUpButton()
    private let fontSizeControl = NSPopUpButton()
    private let weekStack = NSStackView()
    private var settingsObserverID: UUID?
    private var stateObserverID: UUID?

    init(
        settingsStore: SettingsStore,
        daymarkStore: DaymarkStore,
        onQuit: @escaping () -> Void
    ) {
        self.settingsStore = settingsStore
        self.daymarkStore = daymarkStore
        self.onQuit = onQuit

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 620, height: 630),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Daymark Settings"
        window.isReleasedWhenClosed = false
        window.setFrameAutosaveName("Daymark.Settings")
        super.init(window: window)
        configureContent()
        configureActions()

        settingsObserverID = settingsStore.observe { [weak self] settings in
            self?.render(settings)
        }
        stateObserverID = daymarkStore.observe { [weak self] state in
            self?.renderWeek(state)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func show() {
        guard let window else { return }
        NSApp.activate(ignoringOtherApps: true)
        window.center()
        window.makeKeyAndOrderFront(nil)
    }

    private func configureContent() {
        guard let contentView = window?.contentView else { return }
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        let root = NSStackView()
        root.orientation = .vertical
        root.alignment = .leading
        root.spacing = 16
        root.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(root)

        let brand = NSTextField(labelWithString: "Daymark")
        brand.font = .systemFont(ofSize: 26, weight: .semibold)
        let subtitle = NSTextField(labelWithString: "Local-first productivity stickies")
        subtitle.font = .systemFont(ofSize: 13)
        subtitle.textColor = .secondaryLabelColor
        let brandStack = NSStackView(views: [brand, subtitle])
        brandStack.orientation = .vertical
        brandStack.alignment = .leading
        brandStack.spacing = 4
        root.addArrangedSubview(brandStack)

        alignmentControl.segmentStyle = .rounded
        alignmentControl.setWidth(108, forSegment: 0)
        alignmentControl.setWidth(108, forSegment: 1)
        opacitySlider.isContinuous = true
        opacityLabel.alignment = .right
        opacityLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)

        let opacityRow = NSStackView(views: [opacitySlider, opacityLabel])
        opacityRow.orientation = .horizontal
        opacityRow.spacing = 10
        opacitySlider.widthAnchor.constraint(equalToConstant: 230).isActive = true
        opacityLabel.widthAnchor.constraint(equalToConstant: 42).isActive = true

        fontControl.addItems(withTitles: StickyFont.allCases.map(\.rawValue))
        fontSizeControl.addItems(withTitles: StickyFontSize.allCases.map(\.title))

        let grid = NSGridView(views: [
            [rowLabel("Alignment"), alignmentControl],
            [rowLabel("Window mode"), floatingToggle],
            [rowLabel("Opacity"), opacityRow],
            [rowLabel("Font"), fontControl],
            [rowLabel("Font size"), fontSizeControl]
        ])
        grid.rowSpacing = 12
        grid.columnSpacing = 20
        grid.column(at: 0).xPlacement = .trailing
        grid.column(at: 1).xPlacement = .leading
        let preferencesCard = sectionCard(
            title: "Sticky Preferences",
            subtitle: "Changes apply immediately to every Daymark sticky.",
            content: grid
        )
        root.addArrangedSubview(preferencesCard)
        preferencesCard.widthAnchor.constraint(equalTo: root.widthAnchor).isActive = true

        weekStack.orientation = .horizontal
        weekStack.distribution = .fillEqually
        weekStack.spacing = 7
        let progressCard = sectionCard(
            title: "This Week’s Progress",
            subtitle: "A quick local view of activity and available daily scores.",
            content: weekStack
        )
        root.addArrangedSubview(progressCard)
        progressCard.widthAnchor.constraint(equalTo: root.widthAnchor).isActive = true
        weekStack.widthAnchor.constraint(equalTo: progressCard.widthAnchor, constant: -32).isActive = true
        weekStack.heightAnchor.constraint(equalToConstant: 86).isActive = true

        let reportButton = NSButton(
            title: "Open Analytical Report",
            target: self,
            action: #selector(openReport)
        )
        reportButton.bezelStyle = .rounded

        let spacer = NSView()
        spacer.translatesAutoresizingMaskIntoConstraints = false

        let quitButton = NSButton(
            title: "Quit Daymark",
            target: self,
            action: #selector(quitDaymark)
        )
        quitButton.bezelStyle = .rounded
        quitButton.contentTintColor = .systemRed

        let actionRow = NSStackView(views: [reportButton, spacer, quitButton])
        actionRow.orientation = .horizontal
        actionRow.alignment = .centerY
        actionRow.spacing = 12
        root.addArrangedSubview(actionRow)
        actionRow.widthAnchor.constraint(equalTo: root.widthAnchor).isActive = true

        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 28),
            root.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -28),
            root.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            root.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),
            spacer.widthAnchor.constraint(greaterThanOrEqualToConstant: 1)
        ])
    }

    private func configureActions() {
        alignmentControl.target = self
        alignmentControl.action = #selector(changeAlignment)
        floatingToggle.target = self
        floatingToggle.action = #selector(toggleFloating)
        opacitySlider.target = self
        opacitySlider.action = #selector(changeOpacity)
        fontControl.target = self
        fontControl.action = #selector(changeFont)
        fontSizeControl.target = self
        fontSizeControl.action = #selector(changeFontSize)
    }

    private func render(_ settings: AppSettings) {
        alignmentControl.selectedSegment = settings.stickyAlignment == .left ? 0 : 1
        floatingToggle.state = settings.alwaysOnTop ? .on : .off
        opacitySlider.doubleValue = settings.opacity
        opacityLabel.stringValue = "\(Int((settings.opacity * 100).rounded()))%"
        fontControl.selectItem(withTitle: settings.fontName.rawValue)
        fontSizeControl.selectItem(withTitle: settings.fontSize.title)
    }

    private func renderWeek(_ state: AppState) {
        weekStack.arrangedSubviews.forEach {
            weekStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let start = DateRules.weekStart(today, calendar: calendar)
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEE"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d"

        for offset in 0..<7 {
            let date = calendar.date(byAdding: .day, value: offset, to: start)!
            let key = DateRules.dateKey(date, calendar: calendar)
            let record = state.days[key]
            let status: String
            if let record {
                status = "Score \(DailyScoring.score(record).total)"
            } else if calendar.isDate(date, inSameDayAs: today) {
                status = "Active"
            } else if date > today {
                status = "Upcoming"
            } else {
                status = "No record"
            }
            weekStack.addArrangedSubview(
                dayCard(
                    day: dayFormatter.string(from: date),
                    date: dateFormatter.string(from: date),
                    status: status,
                    isToday: calendar.isDate(date, inSameDayAs: today)
                )
            )
        }
    }

    private func dayCard(
        day: String,
        date: String,
        status: String,
        isToday: Bool
    ) -> NSView {
        let card = NSView()
        card.wantsLayer = true
        card.layer?.cornerRadius = 9
        card.layer?.backgroundColor = (
            isToday
                ? DaymarkStyle.blue.withAlphaComponent(0.42)
                : NSColor.controlBackgroundColor
        ).cgColor

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 3
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        let dayLabel = NSTextField(labelWithString: day)
        dayLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        let dateLabel = NSTextField(labelWithString: date)
        dateLabel.font = .systemFont(ofSize: 18, weight: .medium)
        let statusLabel = NSTextField(labelWithString: status)
        statusLabel.font = .systemFont(ofSize: 9)
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.alignment = .center
        statusLabel.lineBreakMode = .byTruncatingTail

        stack.addArrangedSubview(dayLabel)
        stack.addArrangedSubview(dateLabel)
        stack.addArrangedSubview(statusLabel)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 4),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -4),
            stack.centerYAnchor.constraint(equalTo: card.centerYAnchor)
        ])
        return card
    }

    private func sectionTitle(_ title: String) -> NSTextField {
        let label = NSTextField(labelWithString: title)
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        return label
    }

    private func sectionCard(
        title: String,
        subtitle: String,
        content: NSView
    ) -> NSView {
        let card = NSView()
        card.wantsLayer = true
        card.layer?.cornerRadius = 12
        card.layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.72).cgColor
        card.layer?.borderWidth = 1
        card.layer?.borderColor = NSColor.separatorColor.withAlphaComponent(0.35).cgColor

        let titleLabel = sectionTitle(title)
        let subtitleLabel = NSTextField(labelWithString: subtitle)
        subtitleLabel.font = .systemFont(ofSize: 11.5)
        subtitleLabel.textColor = .secondaryLabelColor

        let stack = NSStackView(views: [titleLabel, subtitleLabel, content])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 7
        stack.setCustomSpacing(13, after: subtitleLabel)
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14)
        ])
        return card
    }

    private func rowLabel(_ title: String) -> NSTextField {
        let label = NSTextField(labelWithString: title)
        label.textColor = .secondaryLabelColor
        return label
    }

    @objc private func changeAlignment() {
        let alignment: StickyAlignment = alignmentControl.selectedSegment == 0 ? .left : .right
        settingsStore.update { $0.stickyAlignment = alignment }
    }

    @objc private func toggleFloating() {
        settingsStore.update { $0.alwaysOnTop = floatingToggle.state == .on }
    }

    @objc private func changeOpacity() {
        settingsStore.update { $0.opacity = opacitySlider.doubleValue }
    }

    @objc private func changeFont() {
        guard let title = fontControl.selectedItem?.title,
              let font = StickyFont(rawValue: title)
        else { return }
        settingsStore.update { $0.fontName = font }
    }

    @objc private func changeFontSize() {
        guard fontSizeControl.indexOfSelectedItem >= 0 else { return }
        let size = StickyFontSize.allCases[fontSizeControl.indexOfSelectedItem]
        settingsStore.update { $0.fontSize = size }
    }

    @objc private func openReport() {
        let alert = NSAlert()
        alert.messageText = "Analytical report view coming soon."
        alert.addButton(withTitle: "OK")
        if let window {
            alert.beginSheetModal(for: window)
        } else {
            alert.runModal()
        }
    }

    @objc private func quitDaymark() {
        onQuit()
    }
}
