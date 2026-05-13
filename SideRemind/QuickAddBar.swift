import SwiftUI
import AppKit
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
            HStack(spacing: 10) {
                Button {
                    AddReminderWindowController.shared.open(
                        manager: manager,
                        calendar: calendar,
                        defaultDueDate: defaultDueDate
                    )
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
                .help("Open full form")

                TextField("New Reminder…", text: $title)
                    .font(.system(size: 14))
                    .focused($focused)
                    .onSubmit { save() }
                    .textFieldStyle(.plain)
                    .simultaneousGesture(TapGesture().onEnded {
                        // nonactivatingPanel won't accept keyboard input unless
                        // we explicitly activate the app and make the panel key.
                        NSApp.activate(ignoringOtherApps: true)
                        (NSApp.delegate as? AppDelegate)?.panel?.makeKey()
                        focused = true
                    })
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(.regularMaterial)
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
