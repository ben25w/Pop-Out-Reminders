import AppKit
import SwiftUI
import EventKit

class SettingsWindowController: NSObject, NSWindowDelegate {
    static let shared = SettingsWindowController()

    private var window: NSWindow?

    func open(manager: RemindersManager) {
        if let existing = window, existing.isVisible {
            existing.orderFront(nil)
            return
        }

        let hosting = NSHostingView(rootView:
            SettingsView()
                .environmentObject(manager)
                .environmentObject(AppSettings.shared)
        )
        hosting.sizingOptions = []

        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 520),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        win.title = "Settings"
        win.isReleasedWhenClosed = false
        win.delegate = self
        win.contentView = hosting
        win.setFrameOrigin(originNearPanel(windowSize: win.frame.size))
        NSApp.activate(ignoringOtherApps: true)
        win.makeKeyAndOrderFront(nil)
        window = win
    }

    func close() {
        window?.close()
    }

    func windowWillClose(_ notification: Notification) {
        window = nil
    }
}

class AddReminderWindowController: NSObject, NSWindowDelegate {
    static let shared = AddReminderWindowController()

    private var window: NSWindow?

    func open(manager: RemindersManager, calendar: EKCalendar? = nil, defaultDueDate: Date? = nil) {
        window?.close()

        let hosting = NSHostingView(rootView:
            AddReminderView(preselectedCalendar: calendar, defaultDueDate: defaultDueDate)
                .environmentObject(manager)
        )
        hosting.sizingOptions = []

        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 340),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        win.title = "New Reminder"
        win.isReleasedWhenClosed = false
        win.delegate = self
        win.contentView = hosting
        win.setFrameOrigin(originNearPanel(windowSize: win.frame.size))
        NSApp.activate(ignoringOtherApps: true)
        win.makeKeyAndOrderFront(nil)
        window = win
    }

    func close() {
        window?.close()
    }

    func windowWillClose(_ notification: Notification) {
        window = nil
    }
}

// Place a popup window just to the left of the sidebar panel, near the top.
// Falls back to top-right of screen if the panel can't be found.
private func originNearPanel(windowSize: CGSize) -> NSPoint {
    let screen = NSScreen.main ?? NSScreen.screens[0]
    let sf = screen.visibleFrame

    let panelFrame = (NSApp.delegate as? AppDelegate)?.panel?.frame
    let panelLeft = panelFrame?.minX ?? sf.maxX
    let panelTop = panelFrame?.maxY ?? sf.maxY

    let x = panelLeft - windowSize.width - 8
    let y = panelTop - windowSize.height

    return NSPoint(
        x: max(sf.minX, x),
        y: max(sf.minY, y)
    )
}
