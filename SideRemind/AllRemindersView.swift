import SwiftUI
import EventKit

struct AllRemindersView: View {
    @EnvironmentObject var manager: RemindersManager
    @State private var reminders: [EKReminder] = []
    @State private var isLoading = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .bottom) {
                Text("All")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.secondary)
                Spacer()
                Button { showAdd() } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            Divider()

            if isLoading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        if reminders.isEmpty {
                            emptyState(icon: "tray", message: "No reminders\nDouble-click anywhere to add one")
                                .frame(minHeight: 200)
                        } else {
                            ForEach(reminders, id: \.calendarItemIdentifier) { r in
                                ReminderRowView(reminder: r)
                                    .environmentObject(manager)
                                Divider().padding(.leading, 42)
                            }
                        }
                        Color.clear
                            .frame(maxWidth: .infinity, minHeight: 80)
                            .contentShape(Rectangle())
                    }
                }
            }
        }
        .simultaneousGesture(TapGesture(count: 2).onEnded { showAdd() })
        .task { await load() }
        .onChange(of: manager.version) { _, _ in Task { await load() } }
    }

    private func showAdd() {
        AddReminderWindowController.shared.open(manager: manager, calendar: manager.defaultCalendar)
    }

    private func load() async {
        isLoading = true
        reminders = await manager.fetchAllIncomplete()
            .sorted { ($0.title ?? "") < ($1.title ?? "") }
        isLoading = false
    }
}
