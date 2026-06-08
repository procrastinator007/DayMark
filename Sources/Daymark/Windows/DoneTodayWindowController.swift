import AppKit

@MainActor
final class DoneTodayWindowController: StickyWindowController, NSTextViewDelegate {
    private let store: DaymarkStore
    private let reflectionScroll = DaymarkStyle.textView(editable: true)
    private let planScroll = DaymarkStyle.textView(editable: false)
    private let logButton = DaymarkStyle.button("Update")
    private var rendering = false
    private var observerID: UUID?

    private var textView: NSTextView { reflectionScroll.documentView as! NSTextView }
    private var planTextView: NSTextView { planScroll.documentView as! NSTextView }

    init(store: DaymarkStore, frame: NSRect) {
        self.store = store
        super.init(
            title: "Today",
            color: DaymarkStyle.green,
            frame: frame,
            autosaveName: "Daymark.Daily",
            size: frame.size,
            showsHeading: false
        )
        textView.delegate = self
        logButton.target = self
        logButton.action = #selector(commitProgress)
        let columns = NSStackView()
        columns.orientation = .horizontal
        columns.distribution = .fillEqually
        columns.spacing = 14
        stack.addArrangedSubview(columns)
        columns.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true

        let planColumn = NSStackView()
        planColumn.orientation = .vertical
        planColumn.alignment = .leading
        planColumn.spacing = 5
        planColumn.addArrangedSubview(
            DaymarkStyle.label("Things I need to do today", font: DaymarkStyle.titleFont)
        )
        planColumn.addArrangedSubview(planScroll)

        let reflectionColumn = NSStackView()
        reflectionColumn.orientation = .vertical
        reflectionColumn.alignment = .leading
        reflectionColumn.spacing = 5
        reflectionColumn.addArrangedSubview(
            DaymarkStyle.label("Things I did today", font: DaymarkStyle.titleFont)
        )
        reflectionColumn.addArrangedSubview(reflectionScroll)
        let buttonRow = NSView()
        buttonRow.translatesAutoresizingMaskIntoConstraints = false
        buttonRow.addSubview(logButton)
        logButton.translatesAutoresizingMaskIntoConstraints = false
        reflectionColumn.addArrangedSubview(buttonRow)

        columns.addArrangedSubview(planColumn)
        columns.addArrangedSubview(reflectionColumn)

        let contentHeight = max(150, frame.height - 76)
        planScroll.widthAnchor.constraint(equalTo: planColumn.widthAnchor).isActive = true
        planScroll.heightAnchor.constraint(equalToConstant: contentHeight).isActive = true
        reflectionScroll.widthAnchor.constraint(equalTo: reflectionColumn.widthAnchor).isActive = true
        reflectionScroll.heightAnchor.constraint(equalToConstant: contentHeight - 30).isActive = true
        buttonRow.widthAnchor.constraint(equalTo: reflectionColumn.widthAnchor).isActive = true
        buttonRow.heightAnchor.constraint(equalToConstant: 26).isActive = true
        logButton.centerXAnchor.constraint(equalTo: buttonRow.centerXAnchor).isActive = true
        logButton.centerYAnchor.constraint(equalTo: buttonRow.centerYAnchor).isActive = true
        logButton.widthAnchor.constraint(equalToConstant: 78).isActive = true
        observerID = store.observe { [weak self] state in self?.render(state) }
    }

    required init?(coder: NSCoder) { fatalError() }

    func textDidChange(_ notification: Notification) {
        guard !rendering else { return }
        store.recordReflection(textView.string)
    }

    func textDidBeginEditing(_ notification: Notification) {
        setEditingAppearance(true)
    }

    func textDidEndEditing(_ notification: Notification) {
        setEditingAppearance(false)
    }

    @objc private func commitProgress() {
        let count = store.commitToday()
        logButton.toolTip = count == 0
            ? "Saved. No new matching items."
            : "Updated \(count) matching item\(count == 1 ? "" : "s")."
    }

    private func render(_ state: AppState) {
        let key = DateRules.dateKey(Date())
        guard let day = state.days[key] else { return }
        if textView.string != day.reflection {
            rendering = true
            DaymarkStyle.setText(day.reflection, in: textView)
            rendering = false
        }
        let plan = day.plannedTasks.isEmpty
            ? "Nothing was carried over from yesterday."
            : day.plannedTasks.map {
                "\($0.completed ? "✓" : "○") \($0.text)"
            }.joined(separator: "\n")
        DaymarkStyle.setText(plan, in: planTextView)
    }
}
