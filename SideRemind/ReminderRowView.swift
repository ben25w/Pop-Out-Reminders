import SwiftUI
import AppKit
import EventKit

struct ReminderRowView: View {
    let reminder: EKReminder
    let showCalendarName: Bool
    @EnvironmentObject var manager: RemindersManager
    @State private var isHovered = false

    init(reminder: EKReminder, showCalendarName: Bool = false) {
        self.reminder = reminder
        self.showCalendarName = showCalendarName
    }

    private var accentColor: Color {
        guard let cgc = reminder.calendar?.cgColor else { return .accentColor }
        return Color(cgColor: cgc)
    }

    private var dueDate: Date? {
        reminder.dueDateComponents.flatMap { Calendar.current.date(from: $0) }
    }

    private var isOverdue: Bool {
        guard let d = dueDate else { return false }
        // Only flag as overdue if the due DATE (not time) is before today
        return d < Calendar.current.startOfDay(for: Date()) && !reminder.isCompleted
    }

    private var dueDateText: String? {
        guard let date = dueDate else { return nil }
        let cal = Calendar.current
        if cal.isDateInToday(date) {
            // Always show "Today" for today's reminders regardless of time-of-day,
            // so midnight-added reminders don't display "17 hours ago"
            if reminder.dueDateComponents?.hour != nil {
                return date.formatted(.dateTime.hour().minute())
            }
            return "Today"
        } else if date < cal.startOfDay(for: Date()) {
            // Past day — show relative (e.g. "3 days ago")
            let f = RelativeDateTimeFormatter()
            f.unitsStyle = .full
            f.dateTimeStyle = .named
            return f.localizedString(for: date, relativeTo: Date())
        } else {
            return date.formatted(.dateTime.day().month())
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Button {
                try? manager.toggleComplete(reminder)
            } label: {
                Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(reminder.isCompleted ? .secondary : accentColor)
            }
            .buttonStyle(.plain)
            .padding(.top, 1)

            VStack(alignment: .leading, spacing: 3) {
                Text(reminder.title ?? "")
                    .font(.system(size: 13))
                    .foregroundColor(reminder.isCompleted ? .secondary : .primary)
                    .strikethrough(reminder.isCompleted, color: .secondary)

                if let notes = reminder.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                let hasCalName = showCalendarName && reminder.calendar != nil
                let hasDate = dueDateText != nil

                if hasCalName || hasDate {
                    HStack(spacing: 5) {
                        if hasCalName, let cal = reminder.calendar {
                            Circle()
                                .fill(Color(cgColor: cal.cgColor))
                                .frame(width: 6, height: 6)
                            Text(cal.title)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        if hasCalName && hasDate {
                            Text("·")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        if let dateStr = dueDateText {
                            Image(systemName: "calendar")
                                .font(.system(size: 10))
                                .foregroundColor(isOverdue ? .red : .secondary)
                            Text(dateStr)
                                .font(.system(size: 11))
                                .foregroundColor(isOverdue ? .red : .secondary)
                        }
                    }
                }

                if reminder.priority > 0 {
                    HStack(spacing: 3) {
                        ForEach(0..<priorityExclamations, id: \.self) { _ in
                            Image(systemName: "exclamationmark")
                                .font(.system(size: 9, weight: .bold))
                        }
                    }
                    .foregroundColor(.orange)
                }
            }

            // Mail / URL deep link button
            if let url = reminder.url {
                Button {
                    NSWorkspace.shared.open(url)
                } label: {
                    Image(systemName: url.scheme == "message" ? "envelope.fill" : "link")
                        .font(.system(size: 13))
                        .foregroundColor(url.scheme == "message" ? Color(.systemBlue) : .accentColor)
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
                .help(url.scheme == "message" ? "Open in Mail" : url.absoluteString)
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(isHovered ? Color.primary.opacity(0.05) : Color.clear)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .onTapGesture {
            PanelNavigation.shared.openEdit(reminder)
        }
        .contextMenu {
            Button {
                PanelNavigation.shared.openEdit(reminder)
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            Divider()
            // Quick date shortcuts
            Button {
                let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))!
                try? manager.updateDueDate(reminder, to: tomorrow)
            } label: {
                Label("Tomorrow", systemImage: "sunrise")
            }

            Button {
                try? manager.updateDueDate(reminder, to: nextWeekend)
            } label: {
                Label("This Weekend", systemImage: "sun.max")
            }

            Button {
                try? manager.updateDueDate(reminder, to: nextMonday)
            } label: {
                Label("Next Week", systemImage: "forward")
            }

            if reminder.dueDateComponents != nil {
                Button {
                    try? manager.updateDueDate(reminder, to: nil)
                } label: {
                    Label("No Date", systemImage: "xmark.circle")
                }
            }

            Divider()

            Button(role: .destructive) {
                try? manager.deleteReminder(reminder)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // Next Saturday
    private var nextWeekend: Date {
        let cal = Calendar.current
        var comps = DateComponents()
        comps.weekday = 7 // Saturday
        return cal.nextDate(after: cal.startOfDay(for: Date()), matching: comps, matchingPolicy: .nextTime)!
    }

    // Next Monday
    private var nextMonday: Date {
        let cal = Calendar.current
        var comps = DateComponents()
        comps.weekday = 2 // Monday
        return cal.nextDate(after: cal.startOfDay(for: Date()), matching: comps, matchingPolicy: .nextTime)!
    }

    private var priorityExclamations: Int {
        switch reminder.priority {
        case 1: return 3
        case 5: return 2
        case 9: return 1
        default: return 0
        }
    }
}
