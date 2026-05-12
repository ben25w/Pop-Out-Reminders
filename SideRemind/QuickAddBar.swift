import SwiftUI
import EventKit

struct QuickAddBar: View {
    @EnvironmentObject var manager: RemindersManager
    let calendar: EKCalendar?
    var defaultDueDate: Date? = nil

    @State private var title = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 12) {
                Button {
                    AddReminderWindowController.shared.open(
                        manager: manager,
                        calendar: calendar,
                        defaultDueDate: defaultDueDate
                    )
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)

                TextField("New reminder", text: $title)
                    .font(.system(size: 14))
                    .focused($focused)
                    .onSubmit { save() }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(.ultraThinMaterial)
        }
    }

    private func save() {
        let t = title.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        try? manager.addReminder(title: t, notes: nil, dueDate: defaultDueDate, calendar: calendar)
        title = ""
        focused = false
    }
}
