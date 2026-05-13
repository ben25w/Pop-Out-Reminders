import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var panel: SidebarPanel?
    var statusItem: NSStatusItem?
    var trackingTimer: Timer?
    var outsideCount = 0
    var isShowing = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Prevent duplicate instances — quit the new copy if one is already running
        let bundleId = Bundle.main.bundleIdentifier ?? ""
        let others = NSRunningApplication.runningApplications(withBundleIdentifier: bundleId)
            .filter { $0 != NSRunningApplication.current }
        if !others.isEmpty {
            NSApp.terminate(nil)
            return
        }

        NSApp.setActivationPolicy(.accessory)
        setupStatusItem()
        setupPanel()
        startTracking()
    }

    // MARK: - Status Bar

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "list.bullet.rectangle.portrait",
                                   accessibilityDescription: "Pop Out Reminders")
        }
        let menu = NSMenu()
        let toggleItem = NSMenuItem(title: "Toggle Panel", action: #selector(togglePanel), keyEquivalent: "")
        menu.addItem(toggleItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Pop Out Reminders", action: #selector(quit), keyEquivalent: "q"))
        statusItem?.menu = menu
    }

    @objc func togglePanel() {
        guard panel != nil else { return }
        if isShowing { hidePanel() } else { showPanel() }
    }

    @objc func quit() {
        NSApp.terminate(nil)
    }

    // MARK: - Panel

    private func setupPanel() {
        panel = SidebarPanel()
    }

    func showPanel() {
        guard let panel, !isShowing else { return }
        isShowing = true
        outsideCount = 0
        panel.show()
    }

    func hidePanel() {
        guard let panel, isShowing else { return }
        isShowing = false
        outsideCount = 0
        panel.hide()
    }

    // MARK: - Mouse Tracking

    private func startTracking() {
        trackingTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.checkMousePosition()
        }
    }

    private func checkMousePosition() {
        guard let screen = NSScreen.main else { return }
        let mouse = NSEvent.mouseLocation
        let screenFrame = screen.frame

        if !isShowing {
            // Trigger when mouse reaches the rightmost 3 pixels
            if mouse.x >= screenFrame.maxX - 3 {
                showPanel()
            }
        } else {
            guard let panel else { return }
            // Keep panel open while settings or add-reminder window is visible
            if anyPopupVisible {
                outsideCount = 0
                return
            }
            // Hide after mouse leaves panel area for ~300ms (6 ticks × 50ms)
            if !panel.frame.contains(mouse) {
                outsideCount += 1
                if outsideCount >= 6 {
                    hidePanel()
                }
            } else {
                outsideCount = 0
            }
        }
    }
}
