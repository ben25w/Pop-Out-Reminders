import SwiftUI
import EventKit

struct ListDetailView: View {
    let calendarIdentifier: String
    @EnvironmentObject var manager: RemindersManager
    @State private var reminders: [EKReminder] = []
    @State private var isLoading = true

    private var calendar: EKCalendar? {
        manager.lists.first { $0.calendarIdentifier == calendarIdentifier }
    }

    private var accentColor: Color {
        guard let cal = calendar else { return .accentColor }
        return Color(cgColor: cal.cgColor)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
            QuickAddBar(calendar: calendar)
                .environmentObject(manager)
        }
        .task(id: calendarIdentifier) { await load() }
        .onChange(of: manager.version) { _, _ in Task { await load() } }
    }

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                if let cal = calendar {
                    Circle().fill(accentColor).frame(width: 10, height: 10)
                    Text(cal.title)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(accentColor)
                } else {
                    Text("List")
                        .font(.system(size: 22, weight: .bold))
                }
            }
            Spacer()
            Button {
                AddReminderWindowController.shared.open(manager: manager, calendar: calendar)
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(accentColor)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if reminders.isEmpty {
            emptyState(icon: "checkmark.circle", message: "No reminders\nType below or tap + to add one")
                .frame(maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(reminders, id: \.calendarItemIdentifier) { r in
                        ReminderRowView(reminder: r)
                            .environmentObject(manager)
                        Divider().padding(.leading, 42)
                    }
                    Color.clear.frame(maxWidth: .infinity, minHeight: 8)
                }
            }
            .frame(maxHeight: .infinity)
        }
    }

    private func load() async {
        isLoading = true
        if let cal = calendar {
            reminders = await manager.fetchReminders(for: cal)
        }
        isLoading = false
    }
}
