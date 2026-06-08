import AppKit

@MainActor
final class WeeklyWindowController: StickyWindowController, NSTextViewDelegate {
    private let store: DaymarkStore
    private let currentLabel = DaymarkStyle.label("")
    private let sundayLabel = DaymarkStyle.label("Things to do next week", font: DaymarkStyle.titleFont)
    private let nextScroll = DaymarkStyle.textView(editable: true)
    private var rendering = false
    private var observerID: UUID?

    private var nextTextView: NSTextView { nextScroll.documentView as! NSTextView }

    init(store: DaymarkStore, frame: NSRect) {
        self.store = store
        super.init(
            title: "Things to do this week",
            color: DaymarkStyle.coral,
            frame: frame,
            autosaveName: "Daymark.Weekly"
        )
        nextTextView.delegate = self
        stack.addArrangedSubview(currentLabel)
        stack.addArrangedSubview(sundayLabel)
        stack.addArrangedSubview(nextScroll)
        currentLabel.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        sundayLabel.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        nextScroll.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        nextScroll.heightAnchor.constraint(greaterThanOrEqualToConstant: 95).isActive = true
        observerID = store.observe { [weak self] state in self?.render(state) }
    }

    required init?(coder: NSCoder) { fatalError() }

    func textDidChange(_ notification: Notification) {
        guard DateRules.isSunday(Date()), !rendering else { return }
        let lines = nextTextView.string.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        store.update { $0.nextWeekDraft = lines }
    }

    private func render(_ state: AppState) {
        currentLabel.stringValue = state.currentWeekGoals.isEmpty
            ? "No goals were locked for this week."
            : state.currentWeekGoals.map(display).joined(separator: "\n\n")

        let sunday = DateRules.isSunday(Date())
        sundayLabel.isHidden = !sunday
        nextScroll.isHidden = !sunday
        guard sunday else { return }

        let value = state.nextWeekDraft.joined(separator: "\n")
        if nextTextView.string != value {
            rendering = true
            nextTextView.string = value
            rendering = false
        }
    }

    private func display(_ goal: WeeklyGoal) -> String {
        if let target = goal.target {
            return "○  \(goal.text) \(goal.current ?? 0)/\(target)"
        }
        return "\(goal.completed ? "✓" : "○")  \(goal.text)"
    }
}
