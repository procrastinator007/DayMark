import AppKit

@MainActor
final class TomorrowWindowController: StickyWindowController, NSTextViewDelegate {
    private let store: DaymarkStore
    private let scroll = DaymarkStyle.textView(editable: true)
    private var rendering = false
    private var observerID: UUID?

    private var textView: NSTextView { scroll.documentView as! NSTextView }

    init(store: DaymarkStore, frame: NSRect) {
        self.store = store
        super.init(
            title: "Things I need to do tomorrow",
            color: DaymarkStyle.blue,
            frame: frame,
            autosaveName: "Daymark.Tomorrow"
        )
        textView.delegate = self
        stack.addArrangedSubview(scroll)
        scroll.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        scroll.heightAnchor.constraint(greaterThanOrEqualToConstant: 170).isActive = true
        observerID = store.observe { [weak self] state in self?.render(state) }
    }

    required init?(coder: NSCoder) { fatalError() }

    func textDidChange(_ notification: Notification) {
        guard !rendering else { return }
        let lines = textView.string.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        store.update { $0.tomorrowDraft = lines }
    }

    private func render(_ state: AppState) {
        let value = state.tomorrowDraft.joined(separator: "\n")
        guard textView.string != value else { return }
        rendering = true
        textView.string = value
        rendering = false
    }
}
