import Foundation
import EventKit

/// Manages what the panel is showing — the main list, or the inline reminder form.
class PanelNavigation: ObservableObject {
    static let shared = PanelNavigation()
    private init() {}

    @Published var isShowingForm = false
    @Published var editingReminder: EKReminder? = nil
    @Published var preselectedCalendar: EKCalendar? = nil
    @Published var defaultDueDate: Date? = nil

    func openNew(calendar: EKCalendar? = nil, dueDate: Date? = nil) {
        editingReminder     = nil
        preselectedCalendar = calendar
        defaultDueDate      = dueDate
        isShowingForm       = true
    }

    func openEdit(_ reminder: EKReminder) {
        editingReminder     = reminder
        preselectedCalendar = reminder.calendar
        defaultDueDate      = reminder.dueDateComponents.flatMap { Calendar.current.date(from: $0) }
        isShowingForm       = true
    }

    func dismiss() {
        isShowingForm       = false
        editingReminder     = nil
        preselectedCalendar = nil
        defaultDueDate      = nil
    }
}
