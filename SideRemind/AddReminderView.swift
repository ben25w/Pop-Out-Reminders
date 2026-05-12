import SwiftUI
import EventKit

struct AddReminderView: View {
    let preselectedCalendar: EKCalendar?
    let defaultDueDate: Date?

    @EnvironmentObject var manager: RemindersManager

    @State private var title = ""
    @State private var notes = ""
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    @State private var selectedCalendarId: String

    // Always resolves to a valid tag so SwiftUI's Picker never sees ""
    private var safeCalendarBinding: Binding<String> {
        Binding(
            get: {
                if manager.lists.contains(where: { $0.calendarIdentifier == selectedCalendarId }) {
                    return selectedCalendarId
                }
                return manager.defaultCalendar?.calendarIdentifier
                    ?? manager.lists.first?.calendarIdentifier
                    ?? selectedCalendarId
            },
            set: { selectedCalendarId = $0 }
        )
    }

    init(preselectedCalendar: EKCalendar? = nil, defaultDueDate: Date? = nil) {
        self.preselectedCalendar = preselectedCalendar
        self.defaultDueDate = defaultDueDate
        // Seed from preselectedCalendar so first render already has a value;
        // task {} below fills in the default if this is still empty.
        _selectedCalendarId = State(initialValue: preselectedCalendar?.calendarIdentifier ?? "")
    }

    var body: some View {
        VStack(spacing: 0) {
            toolbar
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
                        Picker("List", selection: safeCalendarBinding) {
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
        .task {
            if let date = defaultDueDate {
                hasDueDate = true
                dueDate = date
            }
            // Fill in calendar if init couldn't (no preselectedCalendar provided)
            if selectedCalendarId.isEmpty ||
               !manager.lists.contains(where: { $0.calendarIdentifier == selectedCalendarId }) {
                selectedCalendarId = manager.defaultCalendar?.calendarIdentifier
                    ?? manager.lists.first?.calendarIdentifier
                    ?? ""
            }
        }
    }

    private var toolbar: some View {
        HStack {
            Button("Cancel") { AddReminderWindowController.shared.close() }
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
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let calendar = manager.lists.first { $0.calendarIdentifier == selectedCalendarId }
        try? manager.addReminder(
            title: trimmed,
            notes: notes.isEmpty ? nil : notes,
            dueDate: hasDueDate ? dueDate : nil,
            calendar: calendar
        )
        AddReminderWindowController.shared.close()
    }
}
