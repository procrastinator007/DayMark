import AppKit
import UniformTypeIdentifiers

@MainActor
final class AppCoordinator {
    private let store = DaymarkStore()
    private let settingsStore = SettingsStore()
    private var controllers: [StickyWindowController] = []
    private var settingsWindowController: SettingsWindowController?
    private var settingsObserverID: UUID?
    private var dayChangeObserver: NSObjectProtocol?
    private var visibilityTimer: Timer?
    private var hiddenForFullScreen = false
    private var primaryScreen: NSScreen?

    func start() {
        DaymarkStyle.apply(settingsStore.settings)
        let screen = Self.primaryDisplay()
        primaryScreen = screen
        let visible = screen.visibleFrame
        let width: CGFloat = 340
        let gap: CGFloat = 10
        let verticalMargin: CGFloat = 24
        let usableHeight = visible.height - verticalMargin * 2 - gap * 3
        let dailyHeight = max(275, usableHeight * 0.36)
        let tomorrowHeight = max(125, usableHeight * 0.17)
        let weeklyHeight = max(155, usableHeight * 0.22)
        let scoreHeight = max(
            145,
            usableHeight - dailyHeight - tomorrowHeight - weeklyHeight
        )
        let horizontalInset: CGFloat = 32
        let left = Self.xPosition(
            for: settingsStore.settings.stickyAlignment,
            visibleFrame: visible,
            width: width,
            inset: horizontalInset
        )
        let top = visible.maxY - dailyHeight - verticalMargin
        let tomorrowY = top - tomorrowHeight - gap
        let weeklyY = tomorrowY - weeklyHeight - gap
        let scoreY = max(visible.minY + verticalMargin, weeklyY - scoreHeight - gap)

        controllers = [
            DoneTodayWindowController(
                store: store,
                frame: NSRect(
                    x: left,
                    y: top,
                    width: width,
                    height: dailyHeight
                )
            ),
            TomorrowWindowController(
                store: store,
                frame: NSRect(x: left, y: tomorrowY, width: width, height: tomorrowHeight)
            ),
            WeeklyWindowController(
                store: store,
                frame: NSRect(x: left, y: weeklyY, width: width, height: weeklyHeight)
            ),
            YesterdayScoreWindowController(
                store: store,
                frame: NSRect(
                    x: left,
                    y: scoreY,
                    width: width,
                    height: scoreHeight
                ),
                onOpenSettings: { [weak self] in self?.showSettings() }
            )
        ]
        settingsWindowController = SettingsWindowController(
            settingsStore: settingsStore,
            daymarkStore: store,
            onQuit: { [weak self] in self?.quit() }
        )
        settingsObserverID = settingsStore.observe { [weak self] settings in
            self?.apply(settings: settings)
        }
        controllers.forEach { $0.show() }
        startFullScreenMonitoring()
        dayChangeObserver = NotificationCenter.default.addObserver(
            forName: .NSCalendarDayChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.store.refreshForCurrentDate() }
        }
    }

    func showAll() {
        hiddenForFullScreen = false
        controllers.forEach { $0.show() }
    }

    func showSettings() {
        settingsWindowController?.show()
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

    private func apply(settings: AppSettings) {
        DaymarkStyle.apply(settings)
        if let screen = controllers.first?.window?.screen ?? primaryScreen {
            primaryScreen = screen
            let x = Self.xPosition(
                for: settings.stickyAlignment,
                visibleFrame: screen.visibleFrame,
                width: controllers.first?.window?.frame.width ?? 340,
                inset: 32
            )
            controllers.forEach { controller in
                guard let window = controller.window else { return }
                window.setFrameOrigin(NSPoint(x: x, y: window.frame.minY))
            }
        }
        controllers.forEach { $0.apply(settings: settings) }
    }

    static func xPosition(
        for alignment: StickyAlignment,
        visibleFrame: NSRect,
        width: CGFloat,
        inset: CGFloat
    ) -> CGFloat {
        switch alignment {
        case .right: visibleFrame.maxX - width - inset
        case .left: visibleFrame.minX + inset
        }
    }

    private func quit() {
        store.saveNow()
        settingsStore.saveNow()
        NSApp.terminate(nil)
    }

    private static func primaryDisplay() -> NSScreen {
        NSScreen.screens.first(where: {
            abs($0.frame.minX) < 1 && abs($0.frame.minY) < 1
        }) ?? NSScreen.main ?? NSScreen.screens.first!
    }

    private func startFullScreenMonitoring() {
        visibilityTimer?.invalidate()
        visibilityTimer = Timer.scheduledTimer(
            withTimeInterval: 0.8,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in self?.updateFullScreenVisibility() }
        }
        updateFullScreenVisibility()
    }

    private func updateFullScreenVisibility() {
        guard let screen = primaryScreen else { return }
        let shouldHide = frontmostAppFills(screen)
        guard shouldHide != hiddenForFullScreen else { return }
        hiddenForFullScreen = shouldHide
        if shouldHide {
            controllers.forEach { $0.window?.orderOut(nil) }
        } else {
            controllers.forEach { $0.show() }
        }
    }

    private func frontmostAppFills(_ screen: NSScreen) -> Bool {
        guard let app = NSWorkspace.shared.frontmostApplication,
              app.bundleIdentifier != Bundle.main.bundleIdentifier,
              let windows = CGWindowListCopyWindowInfo(
                [.optionOnScreenOnly, .excludeDesktopElements],
                kCGNullWindowID
              ) as? [[String: Any]]
        else { return false }

        return windows.contains { info in
            guard let ownerPID = info[kCGWindowOwnerPID as String] as? pid_t,
                  ownerPID == app.processIdentifier,
                  let layer = info[kCGWindowLayer as String] as? Int,
                  layer == 0,
                  let bounds = info[kCGWindowBounds as String] as? [String: NSNumber],
                  let x = bounds["X"]?.doubleValue,
                  let y = bounds["Y"]?.doubleValue,
                  let width = bounds["Width"]?.doubleValue,
                  let height = bounds["Height"]?.doubleValue
            else { return false }

            let rect = CGRect(x: x, y: y, width: width, height: height)
            let tolerance: CGFloat = 4
            return abs(rect.minX - screen.frame.minX) <= tolerance
                && rect.width >= screen.frame.width - tolerance
                && rect.height >= screen.frame.height - tolerance
        }
    }
}
