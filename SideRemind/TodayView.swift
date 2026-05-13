import SwiftUI
import EventKit

struct TodayView: View {
    @EnvironmentObject var manager: RemindersManager
    @EnvironmentObject var settings: AppSettings

    private var startOfToday: Date { Calendar.current.startOfDay(for: Date()) }

    private var overdueReminders: [EKReminder] {
        manager.todayReminders.filter {
            ($0.dueDateComponents.flatMap { Calendar.current.date(from: $0) } ?? .distantFuture) < startOfToday
        }
    }

    private var dueToday: [EKReminder] {
        manager.todayReminders.filter {
            ($0.dueDateComponents.flatMap { Calendar.current.date(from: $0) } ?? .distantFuture) >= startOfToday
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            reminderList
            QuickAddBar(calendar: settings.effectiveDefaultCalendar(from: manager), defaultDueDate: startOfToday)
                .environmentObject(manager)
        }
        .onChange(of: manager.version) { _, _ in }
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
            Button {
                AddReminderWindowController.shared.open(
                    manager: manager,
                    calendar: settings.effectiveDefaultCalendar(from: manager),
                    defaultDueDate: Date()
                )
            } label: {
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
        if manager.todayReminders.isEmpty {
            emptyState(icon: "star.circle", message: "No reminders today\nType below or tap + to add one")
                .frame(maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: .sectionHeaders) {
                    if !overdueReminders.isEmpty {
                        Section {
                            ForEach(overdueReminders, id: \.calendarItemIdentifier) { r in
                                ReminderRowView(reminder: r, showCalendarName: true)
                                    .environmentObject(manager)
                                Divider().padding(.leading, 42)
                            }
                        } header: {
                            sectionLabel("OVERDUE", color: .red)
                        }
                    }
                    if !dueToday.isEmpty {
                        Section {
                            ForEach(dueToday, id: \.calendarItemIdentifier) { r in
                                ReminderRowView(reminder: r, showCalendarName: true)
                                    .environmentObject(manager)
                                Divider().padding(.leading, 42)
                            }
                        } header: {
                            if !overdueReminders.isEmpty {
                                sectionLabel("TODAY", color: .secondary)
                            }
                        }
                    }
                }
            }
            .frame(maxHeight: .infinity)
        }
    }

    private func sectionLabel(_ title: String, color: Color) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(color)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial)
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
