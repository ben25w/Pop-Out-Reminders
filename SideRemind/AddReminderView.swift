import SwiftUI
import EventKit

struct AddReminderView: View {
    @EnvironmentObject var manager: RemindersManager
    var preselectedCalendar: EKCalendar?
    var defaultDueDate: Date? = nil  // pass Date() from Today view to pre-fill today

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var notes = ""
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    @State private var selectedCalendarId = ""

    private var selectedCalendar: EKCalendar? {
        manager.lists.first { $0.calendarIdentifier == selectedCalendarId }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Button("Cancel") { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)

                Spacer()
                Text("New Reminder")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()

                Button("Add") { save() }
                    .buttonStyle(.plain)
                    .foregroundColor(title.trimmingCharacters(in: .whitespaces).isEmpty ? .secondary : .accentColor)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            Form {
                Section {
                    TextField("Title", text: $title)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                }

                Section {
                    Toggle("Due Date", isOn: $hasDueDate.animation())
                    if hasDueDate {
                        DatePicker("Date & Time", selection: $dueDate,
                                   displayedComponents: [.date, .hourAndMinute])
                            .labelsHidden()
                    }
                }

                if !manager.lists.isEmpty {
                    Section {
                        Picker("List", selection: $selectedCalendarId) {
                            ForEach(manager.lists, id: \.calendarIdentifier) { cal in
                                HStack {
                                    Circle()
                                        .fill(Color(cgColor: cal.cgColor))
                                        .frame(width: 8, height: 8)
                                    Text(cal.title)
                                }
                                .tag(cal.calendarIdentifier)
                            }
                        }
                    }
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 360)
        .onAppear {
            // Pre-fill due date if provided (e.g. Today view passes Date())
            if let date = defaultDueDate {
                hasDueDate = true
                dueDate = date
            }
            selectedCalendarId = preselectedCalendar?.calendarIdentifier
                ?? manager.defaultCalendar?.calendarIdentifier
                ?? manager.lists.first?.calendarIdentifier
                ?? ""
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        try? manager.addReminder(
            title: trimmed,
            notes: notes.isEmpty ? nil : notes,
            dueDate: hasDueDate ? dueDate : nil,
            calendar: selectedCalendar
        )
        dismiss()
    }
}
