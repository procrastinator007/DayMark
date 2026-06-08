import AppKit
import UniformTypeIdentifiers

@MainActor
final class AppCoordinator {
    private let store = DaymarkStore()
    private var controllers: [StickyWindowController] = []
    private var dayChangeObserver: NSObjectProtocol?

    func start() {
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let width = DaymarkStyle.stickySize.width
        let height = DaymarkStyle.stickySize.height
        let gap: CGFloat = 14
        let right = screen.maxX - width - 22
        let top = screen.maxY - height - 22

        controllers = [
            WeeklyWindowController(
                store: store,
                frame: NSRect(x: right, y: top, width: width, height: height)
            ),
            TodayTasksWindowController(
                store: store,
                frame: NSRect(x: right, y: top - height - gap, width: width, height: height)
            ),
            DoneTodayWindowController(
                store: store,
                frame: NSRect(x: right - width - gap, y: top, width: width, height: height)
            ),
            TomorrowWindowController(
                store: store,
                frame: NSRect(x: right - width - gap, y: top - height - gap, width: width, height: height)
            )
        ]
        controllers.forEach { $0.show() }
        dayChangeObserver = NotificationCenter.default.addObserver(
            forName: .NSCalendarDayChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.store.refreshForCurrentDate() }
        }
    }

    func showAll() {
        controllers.forEach { $0.show() }
    }

    func exportData() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "daymark-\(DateRules.dateKey(Date())).json"
        panel.allowedContentTypes = [.json]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        try? store.exportSnapshot(to: url)
    }

    func exportWeeklyReport() {
        saveReport(
            name: "daymark-weekly-\(DateRules.dateKey(Date())).txt",
            content: WeeklyAnalytics.report(state: store.state)
        )
    }

    func exportMonthlyReport() {
        saveReport(
            name: "daymark-monthly-\(DateRules.dateKey(Date())).txt",
            content: MonthlyAnalytics.report(state: store.state)
        )
    }

    private func saveReport(name: String, content: String) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = name
        guard panel.runModal() == .OK, let url = panel.url else { return }
        try? content.write(to: url, atomically: true, encoding: .utf8)
    }
}
