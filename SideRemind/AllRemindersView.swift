import SwiftUI
import EventKit

struct AllRemindersView: View {
    @EnvironmentObject var manager: RemindersManager
    @EnvironmentObject var settings: AppSettings
    @State private var reminders: [EKReminder] = []
    @State private var isLoading = true
    @State private var collapsed: Set<String> = []

    private var groupedByList: [(EKCalendar, [EKReminder])] {
        let order = settings.calendarOrder
        let hidden = settings.hiddenCalendarIds
        let sorted = manager.lists
            .filter { !hidden.contains($0.calendarIdentifier) }
            .sorted {
                let ai = order.firstIndex(of: $0.calendarIdentifier) ?? Int.max
                let bi = order.firstIndex(of: $1.calendarIdentifier) ?? Int.max
                return ai == bi ? $0.title < $1.title : ai < bi
            }
        return sorted.compactMap { cal in
            let items = reminders
                .filter { $0.calendar?.calendarIdentifier == cal.calendarIdentifier }
                .sorted { ($0.title ?? "") < ($1.title ?? "") }
            return items.isEmpty ? nil : (cal, items)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom) {
                Text("All")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.secondary)
                Spacer()
                Button {
                    AddReminderWindowController.shared.open(manager: manager, calendar: settings.effectiveDefaultCalendar(from: manager))
                } label: {
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
            } else if groupedByList.isEmpty {
                emptyState(icon: "tray", message: "No reminders\nType below or tap + to add one")
                    .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                        ForEach(groupedByList, id: \.0.calendarIdentifier) { (cal, items) in
                            Section {
                                if !collapsed.contains(cal.calendarIdentifier) {
                                    ForEach(items, id: \.calendarItemIdentifier) { r in
                                        ReminderRowView(reminder: r)
                                            .environmentObject(manager)
                                        Divider().padding(.leading, 42)
                                    }
                                }
                            } header: {
                                listSectionHeader(cal, count: items.count)
                            }
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

    private func listSectionHeader(_ cal: EKCalendar, count: Int) -> some View {
        let calId = cal.calendarIdentifier
        let isCollapsed = collapsed.contains(calId)
        return Button {
            if isCollapsed { collapsed.remove(calId) } else { collapsed.insert(calId) }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 14)
                Circle()
                    .fill(Color(cgColor: cal.cgColor))
                    .frame(width: 10, height: 10)
                Text(cal.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                Text("\(count)")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)
        }
        .buttonStyle(.plain)
    }

    private func load() async {
        isLoading = true
        reminders = await manager.fetchAllIncomplete()
        isLoading = false
    }
}
