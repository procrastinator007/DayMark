import AppKit

@MainActor
final class TodayTasksWindowController: StickyWindowController {
    private let store: DaymarkStore
    private let taskLabel = DaymarkStyle.label("")
    private var observerID: UUID?

    init(store: DaymarkStore, frame: NSRect) {
        self.store = store
        super.init(
            title: "Things I need to do today",
            color: DaymarkStyle.yellow,
            frame: frame,
            autosaveName: "Daymark.Today"
        )
        taskLabel.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        stack.addArrangedSubview(taskLabel)
        taskLabel.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        observerID = store.observe { [weak self] state in self?.render(state) }
    }

    required init?(coder: NSCoder) { fatalError() }

    private func render(_ state: AppState) {
        let key = DateRules.dateKey(Date())
        let tasks = state.days[key]?.plannedTasks ?? []
        taskLabel.stringValue = tasks.isEmpty
            ? "Nothing was carried over from yesterday."
            : tasks.map { "\($0.completed ? "✓" : "○")  \($0.text)" }.joined(separator: "\n\n")
    }
}
