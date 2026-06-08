import AppKit

@MainActor
final class TodayTasksWindowController: StickyWindowController {
    private let store: DaymarkStore
    private let scroll = DaymarkStyle.textView(editable: false)
    private var observerID: UUID?
    private var textView: NSTextView { scroll.documentView as! NSTextView }

    init(store: DaymarkStore, frame: NSRect) {
        self.store = store
        super.init(
            title: "Things I need to do today",
            color: DaymarkStyle.yellow,
            frame: frame,
            autosaveName: "Daymark.Today"
        )
        stack.addArrangedSubview(scroll)
        scroll.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        scroll.heightAnchor.constraint(equalToConstant: 195).isActive = true
        observerID = store.observe { [weak self] state in self?.render(state) }
    }

    required init?(coder: NSCoder) { fatalError() }

    private func render(_ state: AppState) {
        let key = DateRules.dateKey(Date())
        let tasks = state.days[key]?.plannedTasks ?? []
        let value = tasks.isEmpty
            ? "Nothing was carried over from yesterday."
            : tasks.map { "\($0.completed ? "✓" : "○") \($0.text)" }.joined(separator: "\n")
        DaymarkStyle.setText(value, in: textView)
    }
}
