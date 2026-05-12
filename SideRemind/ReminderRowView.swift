import SwiftUI
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
        return d < Date() && !reminder.isCompleted
    }

    private var dueDateText: String? {
        guard let date = dueDate else { return nil }
        if date < Date() {
            let f = RelativeDateTimeFormatter()
            f.unitsStyle = .full
            f.dateTimeStyle = .named
            return f.localizedString(for: date, relativeTo: Date())
        } else if Calendar.current.isDateInToday(date) {
            if reminder.dueDateComponents?.hour != nil {
                return date.formatted(.dateTime.hour().minute())
            }
            return "Today"
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

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(isHovered ? Color.primary.opacity(0.05) : Color.clear)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .contextMenu {
            Button("Delete") { try? manager.deleteReminder(reminder) }
        }
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
