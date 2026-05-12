import SwiftUI
import EventKit

struct ScheduledView: View {
    @EnvironmentObject var manager: RemindersManager
    @State private var reminders: [EKReminder] = []
    @State private var isLoading = true
    @State private var showingAdd = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .bottom) {
                Text("Scheduled")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.red)
                Spacer()
                Button { showingAdd = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.red)
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
                            emptyState(icon: "calendar", message: "No scheduled reminders")
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
                            .onTapGesture(count: 2) { showingAdd = true }
                    }
                }
            }
        }
        .task { await load() }
        .onChange(of: manager.version) { _, _ in Task { await load() } }
        .sheet(isPresented: $showingAdd) {
            AddReminderView(preselectedCalendar: manager.defaultCalendar)
                .environmentObject(manager)
        }
    }

    private func load() async {
        isLoading = true
        let all = await manager.fetchAllIncomplete()
        reminders = all
            .filter { $0.dueDateComponents != nil }
            .sorted {
                let d1 = $0.dueDateComponents.flatMap { Calendar.current.date(from: $0) } ?? .distantFuture
                let d2 = $1.dueDateComponents.flatMap { Calendar.current.date(from: $0) } ?? .distantFuture
                return d1 < d2
            }
        isLoading = false
    }
}
