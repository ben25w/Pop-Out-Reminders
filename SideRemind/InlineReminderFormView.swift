import SwiftUI
import EventKit

struct InlineReminderFormView: View {
    @EnvironmentObject var manager: RemindersManager
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var nav: PanelNavigation

    @State private var title = ""
    @State private var notes = ""
    @State private var hasDate = false
    @State private var hasTime = false
    @State private var dueDate = Date()
    @State private var selectedCalendarId = ""
    @State private var priority = 0

    @FocusState private var titleFocused: Bool

    private let priorityOptions: [(String, Int)] = [
        ("None", 0), ("Low", 9), ("Medium", 5), ("High", 1)
    ]

    private var safeCalendarBinding: Binding<String> {
        Binding(
            get: {
                manager.lists.contains(where: { $0.calendarIdentifier == selectedCalendarId })
                    ? selectedCalendarId
                    : (settings.effectiveDefaultCalendar(from: manager)?.calendarIdentifier
                        ?? manager.lists.first?.calendarIdentifier ?? selectedCalendarId)
            },
            set: { selectedCalendarId = $0 }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    titleNotesSection
                    sectionDivider("DATE & TIME")
                    dateTimeSection
                    sectionDivider("ORGANIZATION")
                    organizationSection
                }
                .padding(.bottom, 24)
            }
        }
        .onAppear { populate() }
        .onChange(of: hasDate) { _, on in if !on { hasTime = false } }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack {
            Button("Cancel") { nav.dismiss() }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
            Spacer()
            Text(nav.editingReminder == nil ? "New Reminder" : "Edit Reminder")
                .font(.system(size: 14, weight: .semibold))
            Spacer()
            Button(nav.editingReminder == nil ? "Add" : "Save") { save() }
                .buttonStyle(.plain)
                .foregroundColor(title.trimmingCharacters(in: .whitespaces).isEmpty ? .secondary : .accentColor)
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Title & Notes

    private var titleNotesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField("Title", text: $title)
                .font(.system(size: 16, weight: .medium))
                .textFieldStyle(.plain)
                .focused($titleFocused)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 10)

            Divider().padding(.horizontal, 16)

            TextField("Notes", text: $notes, axis: .vertical)
                .font(.system(size: 13))
                .textFieldStyle(.plain)
                .lineLimit(3...8)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
        }
        .background(Color(.controlBackgroundColor).opacity(0.5))
    }

    // MARK: - Section header

    private func sectionDivider(_ label: String) -> some View {
        Text(label)
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(.secondary)
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Date & Time

    private var dateTimeSection: some View {
        VStack(spacing: 0) {
            // Date row
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.red)
                    .frame(width: 22)
                Text("Date")
                    .font(.system(size: 13))
                Spacer()
                Toggle("", isOn: $hasDate.animation())
                    .toggleStyle(.switch)
                    .controlSize(.small)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.controlBackgroundColor).opacity(0.5))

            if hasDate {
                Divider().padding(.leading, 54)
                DatePicker("", selection: $dueDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding(.horizontal, 8)
                    .background(Color(.controlBackgroundColor).opacity(0.5))
            }

            Divider().padding(.leading, hasDate ? 0 : 54)

            // Time row
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.blue)
                    .frame(width: 22)
                Text("Time")
                    .font(.system(size: 13))
                    .foregroundColor(hasDate ? .primary : .secondary)
                Spacer()
                Toggle("", isOn: $hasTime.animation())
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .disabled(!hasDate)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.controlBackgroundColor).opacity(0.5))

            if hasDate && hasTime {
                Divider().padding(.leading, 54)
                DatePicker("", selection: $dueDate, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.field)
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(.controlBackgroundColor).opacity(0.5))
            }
        }
        .cornerRadius(10)
        .padding(.horizontal, 12)
    }

    // MARK: - Organization

    private var organizationSection: some View {
        VStack(spacing: 0) {
            // List picker
            if !manager.lists.isEmpty {
                HStack {
                    Image(systemName: "list.bullet")
                        .foregroundColor(.secondary)
                        .frame(width: 22)
                    Text("List")
                        .font(.system(size: 13))
                    Spacer()
                    Picker("", selection: safeCalendarBinding) {
                        ForEach(manager.lists, id: \.calendarIdentifier) { cal in
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color(cgColor: cal.cgColor))
                                    .frame(width: 8, height: 8)
                                Text(cal.title)
                            }
                            .tag(cal.calendarIdentifier)
                        }
                    }
                    .labelsHidden()
                    .frame(maxWidth: 160)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.controlBackgroundColor).opacity(0.5))

                Divider().padding(.leading, 54)
            }

            // Priority picker
            HStack {
                Image(systemName: "exclamationmark.3")
                    .foregroundColor(.secondary)
                    .frame(width: 22)
                Text("Priority")
                    .font(.system(size: 13))
                Spacer()
                Picker("", selection: $priority) {
                    ForEach(priorityOptions, id: \.1) { label, value in
                        Text(label).tag(value)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: 120)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.controlBackgroundColor).opacity(0.5))
        }
        .cornerRadius(10)
        .padding(.horizontal, 12)
    }

    // MARK: - Logic

    private func populate() {
        // Seed calendar from nav/settings
        let defaultCal = nav.preselectedCalendar ?? settings.effectiveDefaultCalendar(from: manager)
        selectedCalendarId = defaultCal?.calendarIdentifier
            ?? manager.lists.first?.calendarIdentifier ?? ""

        if let r = nav.editingReminder {
            // Editing existing reminder
            title    = r.title ?? ""
            notes    = r.notes ?? ""
            priority = r.priority
            selectedCalendarId = r.calendar?.calendarIdentifier ?? selectedCalendarId

            if let dc = r.dueDateComponents, let d = Calendar.current.date(from: dc) {
                hasDate  = true
                hasTime  = dc.hour != nil
                dueDate  = d
            }
        } else {
            // New reminder — seed date from defaultDueDate if provided
            if let d = nav.defaultDueDate {
                hasDate  = true
                hasTime  = Calendar.current.component(.hour, from: d) != 0
                           || Calendar.current.component(.minute, from: d) != 0
                dueDate  = d
            }
            // Auto-focus title field for new reminders
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { titleFocused = true }
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let cal = manager.lists.first { $0.calendarIdentifier == selectedCalendarId }
        var components: Set<Calendar.Component> = [.year, .month, .day]
        if hasTime { components.insert(.hour); components.insert(.minute) }
        let finalDate: Date? = hasDate ? dueDate : nil

        if let existing = nav.editingReminder {
            // Update existing
            existing.title    = trimmed
            existing.notes    = notes.isEmpty ? nil : notes
            existing.priority = priority
            existing.calendar = cal ?? manager.store.defaultCalendarForNewReminders()
            if let d = finalDate {
                existing.dueDateComponents = Calendar.current.dateComponents(components, from: d)
            } else {
                existing.dueDateComponents = nil
            }
            try? manager.store.save(existing, commit: true)
            Task { await manager.fetchAll() }
        } else {
            // Create new
            try? manager.addReminder(
                title: trimmed,
                notes: notes.isEmpty ? nil : notes,
                dueDate: finalDate,
                calendar: cal,
                priority: priority
            )
        }
        nav.dismiss()
    }
}
