import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let coordinator = AppCoordinator()
    private var statusItem: NSStatusItem?
    private var loginItem: NSMenuItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureMenuBar()
        coordinator.start()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    private func configureMenuBar() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.title = "D"
        item.button?.toolTip = "Daymark"

        let menu = NSMenu()
        let showItem = menu.addItem(
            withTitle: "Show all stickies",
            action: #selector(showAll),
            keyEquivalent: ""
        )
        showItem.target = self
        let loginItem = menu.addItem(
            withTitle: "Launch at login",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        loginItem.target = self
        loginItem.state = LaunchAtLoginController.isEnabled ? .on : .off
        self.loginItem = loginItem
        menu.addItem(.separator())
        let dataItem = menu.addItem(
            withTitle: "Export private data…",
            action: #selector(exportData),
            keyEquivalent: ""
        )
        dataItem.target = self
        let weeklyItem = menu.addItem(
            withTitle: "Export weekly report…",
            action: #selector(exportWeekly),
            keyEquivalent: ""
        )
        weeklyItem.target = self
        let monthlyItem = menu.addItem(
            withTitle: "Export monthly report…",
            action: #selector(exportMonthly),
            keyEquivalent: ""
        )
        monthlyItem.target = self
        menu.addItem(.separator())
        let quitItem = menu.addItem(
            withTitle: "Quit Daymark",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        quitItem.target = NSApp
        item.menu = menu
        statusItem = item
    }

    @objc private func showAll() { coordinator.showAll() }
    @objc private func exportData() { coordinator.exportData() }
    @objc private func exportWeekly() { coordinator.exportWeeklyReport() }
    @objc private func exportMonthly() { coordinator.exportMonthlyReport() }

    @objc private func toggleLaunchAtLogin() {
        do {
            try LaunchAtLoginController.toggle()
            loginItem?.state = LaunchAtLoginController.isEnabled ? .on : .off
        } catch {
            let alert = NSAlert()
            alert.messageText = "Could not update Launch at Login"
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
    }
}
