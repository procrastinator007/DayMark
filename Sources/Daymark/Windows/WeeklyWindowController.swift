import AppKit

@MainActor
final class WeeklyWindowController: StickyWindowController, NSTextViewDelegate {
    private let store: DaymarkStore
    private let currentScroll = DaymarkStyle.textView(editable: false)
    private let sundayLabel = DaymarkStyle.label("Things to do next week", font: DaymarkStyle.titleFont)
    private let nextScroll = DaymarkStyle.textView(editable: true)
    private var rendering = false
    private var observerID: UUID?
    private var currentHeightConstraint: NSLayoutConstraint?
    private var nextHeightConstraint: NSLayoutConstraint?

    private var currentTextView: NSTextView { currentScroll.documentView as! NSTextView }
    private var nextTextView: NSTextView { nextScroll.documentView as! NSTextView }

    init(store: DaymarkStore, frame: NSRect) {
        self.store = store
        super.init(
            title: "Things to do this week",
            color: DaymarkStyle.coral,
            frame: frame,
            autosaveName: "Daymark.Weekly",
            size: frame.size
        )
        nextTextView.delegate = self
        stack.addArrangedSubview(currentScroll)
        stack.addArrangedSubview(sundayLabel)
        stack.addArrangedSubview(nextScroll)
        currentScroll.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        sundayLabel.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        nextScroll.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        let availableHeight = max(70, frame.height - 58)
        currentHeightConstraint = currentScroll.heightAnchor.constraint(
            equalToConstant: availableHeight
        )
        nextHeightConstraint = nextScroll.heightAnchor.constraint(
            equalToConstant: max(42, availableHeight * 0.42)
        )
        currentHeightConstraint?.isActive = true
        nextHeightConstraint?.isActive = true
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

    func textDidBeginEditing(_ notification: Notification) {
        setEditingAppearance(true)
    }

    func textDidEndEditing(_ notification: Notification) {
        setEditingAppearance(false)
        render(store.state)
    }

    private func render(_ state: AppState) {
        let currentValue = state.currentWeekGoals.isEmpty
            ? "No goals were locked for this week."
            : state.currentWeekGoals.map(display).joined(separator: "\n")
        DaymarkStyle.setText(currentValue, in: currentTextView)

        let sunday = DateRules.isSunday(Date())
        sundayLabel.isHidden = !sunday
        nextScroll.isHidden = !sunday
        currentHeightConstraint?.constant = sunday
            ? max(42, (window?.contentView?.bounds.height ?? 155) * 0.28)
            : max(70, (window?.contentView?.bounds.height ?? 155) - 58)
        guard sunday else { return }
        guard nextTextView.window?.firstResponder !== nextTextView else { return }

        let value = state.nextWeekDraft.joined(separator: "\n")
        if nextTextView.string != value {
            rendering = true
            DaymarkStyle.setText(value, in: nextTextView)
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
