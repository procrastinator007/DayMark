import AppKit

@MainActor
final class DoneTodayWindowController: StickyWindowController, NSTextViewDelegate {
    private let store: DaymarkStore
    private let scroll = DaymarkStyle.textView(editable: true)
    private let recognitionLabel = DaymarkStyle.label(
        "Write naturally. Matching tasks and habits update when logged.",
        font: DaymarkStyle.smallFont
    )
    private let logButton = DaymarkStyle.button("Log today’s progress")
    private var rendering = false
    private var observerID: UUID?

    private var textView: NSTextView { scroll.documentView as! NSTextView }

    init(store: DaymarkStore, frame: NSRect) {
        self.store = store
        super.init(
            title: "Things I did today",
            color: DaymarkStyle.green,
            frame: frame,
            autosaveName: "Daymark.DoneToday"
        )
        textView.delegate = self
        logButton.target = self
        logButton.action = #selector(commitProgress)
        stack.addArrangedSubview(scroll)
        stack.addArrangedSubview(recognitionLabel)
        stack.addArrangedSubview(logButton)
        scroll.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        scroll.heightAnchor.constraint(greaterThanOrEqualToConstant: 125).isActive = true
        recognitionLabel.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        logButton.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        observerID = store.observe { [weak self] state in self?.render(state) }
    }

    required init?(coder: NSCoder) { fatalError() }

    func textDidChange(_ notification: Notification) {
        guard !rendering else { return }
        store.recordReflection(textView.string)
    }

    @objc private func commitProgress() {
        let count = store.commitToday()
        recognitionLabel.stringValue = count == 0
            ? "Reflection saved. No new matching items."
            : "Updated \(count) matching item\(count == 1 ? "" : "s")."
    }

    private func render(_ state: AppState) {
        let key = DateRules.dateKey(Date())
        guard let day = state.days[key] else { return }
        if textView.string != day.reflection {
            rendering = true
            textView.string = day.reflection
            rendering = false
        }
        let matches = ProgressMatcher.detect(
            reflection: day.reflection,
            tasks: day.plannedTasks,
            goals: state.currentWeekGoals,
            alreadyCredited: day.creditedGoalIDs
        )
        let names = matches.taskIDs.compactMap { id in day.plannedTasks.first { $0.id == id }?.text }
            + matches.goalIDs.compactMap { id in state.currentWeekGoals.first { $0.id == id }?.text }
        recognitionLabel.stringValue = names.isEmpty
            ? "Write naturally. Matching tasks and habits update when logged."
            : "Recognized: \(names.joined(separator: ", "))"
    }
}
