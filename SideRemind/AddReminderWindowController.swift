import AppKit
import SwiftUI
import EventKit

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
        win.center()
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
