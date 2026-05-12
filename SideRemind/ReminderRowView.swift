import SwiftUI
import EventKit

struct ReminderRowView: View {
    let reminder: EKReminder
    @EnvironmentObject var manager: RemindersManager
    @State private var isHovered = false

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

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Completion circle
            Button {
                try? manager.toggleComplete(reminder)
            } label: {
                Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(reminder.isCompleted ? .secondary : accentColor)
            }
            .buttonStyle(.plain)
            .padding(.top, 1)

            // Content
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

                if let due = dueDate {
                    HStack(spacing: 3) {
                        Image(systemName: "calendar")
                            .font(.system(size: 10))
                        Text(due, format: .dateTime.day().month().year())
                            .font(.system(size: 11))
                    }
                    .foregroundColor(isOverdue ? .red : .secondary)
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
        case 1: return 3  // High
        case 5: return 2  // Medium
        case 9: return 1  // Low
        default: return 0
        }
    }
}
