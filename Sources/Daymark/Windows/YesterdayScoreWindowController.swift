import AppKit

@MainActor
final class YesterdayScoreWindowController: StickyWindowController {
    private let store: DaymarkStore
    private let calendar: Calendar
    private let onOpenSettings: () -> Void
    private let dial = ScoreDialView()
    private let summaryLabel = DaymarkStyle.label("", font: DaymarkStyle.smallFont)
    private let lateLogButton = DaymarkStyle.button("Add missing detail")
    private var observerID: UUID?

    init(
        store: DaymarkStore,
        frame: NSRect,
        calendar: Calendar = .current,
        onOpenSettings: @escaping () -> Void
    ) {
        self.store = store
        self.calendar = calendar
        self.onOpenSettings = onOpenSettings
        super.init(
            title: "Yesterday’s score",
            color: DaymarkStyle.glassBlue,
            frame: frame,
            autosaveName: "Daymark.YesterdayScore",
            size: frame.size,
            showsHeading: false
        )
        addSettingsButton(target: self, action: #selector(openSettings))
        lateLogButton.target = self
        lateLogButton.action = #selector(addLateLog)

        let titleLabel = DaymarkStyle.label(
            "Yesterday’s score",
            font: DaymarkStyle.scoreTitleFont
        )
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(dial)
        titleLabel.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        dial.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        dial.heightAnchor.constraint(
            equalToConstant: max(110, frame.height - 70)
        ).isActive = true

        summaryLabel.translatesAutoresizingMaskIntoConstraints = false
        lateLogButton.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(summaryLabel)
        content.addSubview(lateLogButton)
        NSLayoutConstraint.activate([
            summaryLabel.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 16),
            summaryLabel.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -10),
            lateLogButton.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -12),
            lateLogButton.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -7),
            lateLogButton.widthAnchor.constraint(equalToConstant: 112)
        ])

        observerID = store.observe { [weak self] state in self?.render(state) }
    }

    required init?(coder: NSCoder) { fatalError() }

    @objc private func addLateLog() {
        let alert = NSAlert()
        alert.messageText = "Add a late log for yesterday"
        alert.informativeText = "This is stored as a late entry and will update yesterday’s score."
        alert.addButton(withTitle: "Add late log")
        alert.addButton(withTitle: "Cancel")

        let scroll = DaymarkStyle.textView(editable: true)
        scroll.frame = NSRect(x: 0, y: 0, width: 340, height: 110)
        alert.accessoryView = scroll

        guard alert.runModal() == .alertFirstButtonReturn,
              let textView = scroll.documentView as? NSTextView
        else { return }
        store.addLateLog(textView.string, for: yesterdayKey())
    }

    @objc private func openSettings() {
        onOpenSettings()
    }

    private func render(_ state: AppState) {
        let score = DailyScoring.score(state.days[yesterdayKey()])
        dial.score = score.total
        let lateCount = state.days[yesterdayKey()]?.lateLogs?.count ?? 0
        summaryLabel.stringValue = lateCount == 0
            ? score.summary
            : "\(score.summary) · \(lateCount) late log\(lateCount == 1 ? "" : "s")"
    }

    private func yesterdayKey() -> String {
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        return DateRules.dateKey(yesterday, calendar: calendar)
    }
}
