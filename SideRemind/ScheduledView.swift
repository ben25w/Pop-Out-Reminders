import SwiftUI
import EventKit
import UniformTypeIdentifiers

struct ScheduledView: View {
    @EnvironmentObject var manager: RemindersManager
    @EnvironmentObject var settings: AppSettings
    @State private var reminders: [EKReminder] = []
    @State private var isLoading = true
    @State private var collapsed: Set<String> = []
    @State private var dropTargetId: String? = nil

    private struct DateGroup: Identifiable {
        let id: String
        let label: String
        let color: Color
        let targetDate: Date?   // nil = overdue (no drag-drop target)
        let items: [EKReminder]
    }

    private var groups: [DateGroup] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let tomorrow = cal.date(byAdding: .day, value: 1, to: today)!

        var overdue: [EKReminder] = []
        var todayItems: [EKReminder] = []
        var tomorrowItems: [EKReminder] = []
        var future: [Date: [EKReminder]] = [:]

        for r in reminders {
            guard let dc = r.dueDateComponents, let date = cal.date(from: dc) else { continue }
            let day = cal.startOfDay(for: date)
            if day < today { overdue.append(r) }
            else if day == today { todayItems.append(r) }
            else if day == tomorrow { tomorrowItems.append(r) }
            else { future[day, default: []].append(r) }
        }

        var result: [DateGroup] = []
        if !overdue.isEmpty    { result.append(DateGroup(id: "overdue",   label: "Overdue",   color: .red,      targetDate: nil,      items: overdue)) }
        if !todayItems.isEmpty { result.append(DateGroup(id: "today",     label: "Today",     color: .primary,  targetDate: today,    items: todayItems)) }
        if !tomorrowItems.isEmpty { result.append(DateGroup(id: "tomorrow", label: "Tomorrow", color: .secondary, targetDate: tomorrow, items: tomorrowItems)) }
        for day in future.keys.sorted() {
            let label = day.formatted(.dateTime.weekday(.abbreviated).day().month())
            result.append(DateGroup(id: "\(day.timeIntervalSince1970)", label: label, color: .secondary, targetDate: day, items: future[day]!))
        }
        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom) {
                Text("Scheduled")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.red)
                Spacer()
                Button {
                    AddReminderWindowController.shared.open(manager: manager, calendar: settings.effectiveDefaultCalendar(from: manager))
                } label: {
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
            } else if groups.isEmpty {
                emptyState(icon: "calendar", message: "No scheduled reminders\nType below or tap + to add one")
                    .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                        ForEach(groups) { group in
                            Section {
                                groupContent(group)
                            } header: {
                                sectionHeader(group)
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

    @ViewBuilder
    private func groupContent(_ group: DateGroup) -> some View {
        let isDropTarget = dropTargetId == group.id && group.targetDate != nil
        VStack(spacing: 0) {
            if !collapsed.contains(group.id) {
                ForEach(group.items, id: \.calendarItemIdentifier) { r in
                    ReminderRowView(reminder: r, showCalendarName: true)
                        .environmentObject(manager)
                        .onDrag {
                            NSItemProvider(object: r.calendarItemIdentifier as NSString)
                        } preview: {
                            Text(r.title ?? "Reminder")
                                .font(.system(size: 13))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.regularMaterial)
                                .cornerRadius(8)
                        }
                    Divider().padding(.leading, 42)
                }
            }
            if group.targetDate != nil {
                Color.clear.frame(maxWidth: .infinity, minHeight: 8)
            }
        }
        .background(isDropTarget ? Color.accentColor.opacity(0.08) : Color.clear)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(isDropTarget ? Color.accentColor.opacity(0.4) : Color.clear, lineWidth: 1.5)
        )
        .onDrop(of: [UTType.plainText], isTargeted: Binding(
            get: { dropTargetId == group.id },
            set: { dropTargetId = $0 ? group.id : nil }
        )) { providers in
            guard let targetDate = group.targetDate else { return false }
            _ = providers.first?.loadObject(ofClass: NSString.self) { obj, _ in
                guard let id = obj as? String else { return }
                DispatchQueue.main.async {
                    if let r = reminders.first(where: { $0.calendarItemIdentifier == id }) {
                        try? manager.updateDueDate(r, to: targetDate)
                    }
                }
            }
            return true
        }
    }

    private func sectionHeader(_ group: DateGroup) -> some View {
        let isCollapsed = collapsed.contains(group.id)
        return Button {
            if isCollapsed { collapsed.remove(group.id) } else { collapsed.insert(group.id) }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(group.color)
                    .frame(width: 14)
                Text(group.label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(group.color)
                Spacer()
                Text("\(group.items.count)")
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
        reminders = await manager.fetchScheduledReminders()
        isLoading = false
    }
}
