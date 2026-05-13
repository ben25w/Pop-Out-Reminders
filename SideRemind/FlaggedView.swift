import SwiftUI
import EventKit

struct FlaggedView: View {
    @EnvironmentObject var manager: RemindersManager
    @EnvironmentObject var settings: AppSettings
    @State private var reminders: [EKReminder] = []
    @State private var isLoading = true

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom) {
                Text("Flagged")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.orange)
                Spacer()
                Button {
                    PanelNavigation.shared.openNew(calendar: settings.effectiveDefaultCalendar(from: manager))
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.orange)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            Divider()

            if isLoading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if reminders.isEmpty {
                emptyState(icon: "flag", message: "No flagged reminders\nType below or tap + to add one")
                    .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(reminders, id: \.calendarItemIdentifier) { r in
                            ReminderRowView(reminder: r, showCalendarName: true)
                                .environmentObject(manager)
                            Divider().padding(.leading, 42)
                        }
                        Color.clear.frame(maxWidth: .infinity, minHeight: 8)
                    }
                }
                .frame(maxHeight: .infinity)
            }

        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            QuickAddBar(calendar: settings.effectiveDefaultCalendar(from: manager))
                .environmentObject(manager)
        }
        .task { await load() }
        .onChange(of: manager.version) { _, _ in Task { await load() } }
    }

    private func load() async {
        isLoading = true
        let all = await manager.fetchAllIncomplete()
        reminders = all.filter { $0.priority != 0 }
        isLoading = false
    }
}
