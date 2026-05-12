import SwiftUI

struct TodayView: View {
    @EnvironmentObject var manager: RemindersManager

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            reminderList
        }
        .simultaneousGesture(TapGesture(count: 2).onEnded { showAdd() })
        .onChange(of: manager.version) { _, _ in }
    }

    private func showAdd() {
        AddReminderWindowController.shared.open(
            manager: manager,
            calendar: manager.defaultCalendar,
            defaultDueDate: Date()
        )
    }

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Today")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.yellow)
                Text(Date(), format: .dateTime.weekday(.wide).day().month(.wide))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button { showAdd() } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.yellow)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var reminderList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if manager.todayReminders.isEmpty {
                    emptyState(icon: "star.circle", message: "No reminders today\nDouble-click anywhere to add one")
                        .frame(minHeight: 200)
                } else {
                    ForEach(manager.todayReminders, id: \.calendarItemIdentifier) { r in
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

func emptyState(icon: String, message: String) -> some View {
    VStack(spacing: 10) {
        Image(systemName: icon)
            .font(.system(size: 32))
            .foregroundColor(.secondary)
        Text(message)
            .font(.system(size: 13))
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding()
}
