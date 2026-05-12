import Foundation
import EventKit

@MainActor
class RemindersManager: ObservableObject {
    @Published var lists: [EKCalendar] = []
    @Published var todayReminders: [EKReminder] = []
    @Published var isAuthorized = false
    @Published var version = 0

    let store = EKEventStore()

    func requestAccess() async {
        do {
            let granted: Bool
            if #available(macOS 14.0, *) {
                granted = try await store.requestFullAccessToReminders()
            } else {
                granted = try await store.requestAccess(to: .reminder)
            }
            isAuthorized = granted
            if granted { await fetchAll() }
        } catch {
            print("EventKit access error: \(error)")
        }
    }

    func fetchAll() async {
        fetchLists()
        await fetchTodayReminders()
        version += 1
    }

    func fetchLists() {
        lists = store.calendars(for: .reminder).sorted { $0.title < $1.title }
    }

    func fetchTodayReminders() async {
        let cal = Calendar.current
        let endOfToday = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: Date()))!
        // nil start = include all overdue reminders (EventKit documented behaviour)
        let pred = store.predicateForIncompleteReminders(withDueDateStarting: nil, ending: endOfToday, calendars: nil)
        let results = await fetchWith(predicate: pred)
        todayReminders = results.sorted {
            let d1 = $0.dueDateComponents.flatMap { cal.date(from: $0) } ?? .distantFuture
            let d2 = $1.dueDateComponents.flatMap { cal.date(from: $0) } ?? .distantFuture
            return d1 < d2
        }
    }

    func fetchReminders(for calendar: EKCalendar) async -> [EKReminder] {
        let pred = store.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: [calendar])
        return await fetchWith(predicate: pred)
    }

    func fetchAllIncomplete() async -> [EKReminder] {
        var results: [EKReminder] = []
        for cal in lists {
            let items = await fetchReminders(for: cal)
            results.append(contentsOf: items)
        }
        return results
    }

    private func fetchWith(predicate: NSPredicate) async -> [EKReminder] {
        await withCheckedContinuation { continuation in
            store.fetchReminders(matching: predicate) { reminders in
                continuation.resume(returning: reminders ?? [])
            }
        }
    }

    // MARK: - Convenience

    var defaultCalendar: EKCalendar? {
        store.defaultCalendarForNewReminders()
    }

    // MARK: - Mutations

    func addReminder(title: String, notes: String?, dueDate: Date?, calendar: EKCalendar?) throws {
        let reminder = EKReminder(eventStore: store)
        reminder.title = title
        reminder.notes = notes
        reminder.calendar = calendar ?? store.defaultCalendarForNewReminders()
        if let dueDate {
            reminder.dueDateComponents = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute], from: dueDate)
        }
        try store.save(reminder, commit: true)
        Task { await fetchAll() }
    }

    func toggleComplete(_ reminder: EKReminder) throws {
        reminder.isCompleted = !reminder.isCompleted
        try store.save(reminder, commit: true)
        Task { await fetchAll() }
    }

    func deleteReminder(_ reminder: EKReminder) throws {
        try store.remove(reminder, commit: true)
        Task { await fetchAll() }
    }
}
