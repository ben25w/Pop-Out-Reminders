import SwiftUI
import EventKit

struct SidebarListView: View {
    @Binding var selection: SidebarSelection
    @EnvironmentObject var manager: RemindersManager
    @EnvironmentObject var settings: AppSettings

    // Lists filtered and sorted according to user preferences
    private var visibleLists: [EKCalendar] {
        let all = manager.lists
        let order = settings.calendarOrder
        let hidden = settings.hiddenCalendarIds

        let sorted: [EKCalendar]
        if order.isEmpty {
            sorted = all
        } else {
            sorted = all.sorted {
                let ai = order.firstIndex(of: $0.calendarIdentifier) ?? Int.max
                let bi = order.firstIndex(of: $1.calendarIdentifier) ?? Int.max
                return ai == bi ? $0.title < $1.title : ai < bi
            }
        }
        return sorted.filter { !hidden.contains($0.calendarIdentifier) }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 2) {

                    // Smart lists
                    Group {
                        SmartListRow(icon: "star.circle.fill", color: .yellow,
                                     title: "Today", badge: manager.todayReminders.count,
                                     isSelected: selection == .today) { selection = .today }

                        SmartListRow(icon: "calendar.circle.fill", color: .red,
                                     title: "Scheduled", badge: nil,
                                     isSelected: selection == .scheduled) { selection = .scheduled }

                        SmartListRow(icon: "tray.circle.fill", color: Color(.systemGray),
                                     title: "All", badge: nil,
                                     isSelected: selection == .all) { selection = .all }

                        SmartListRow(icon: "flag.circle.fill", color: .orange,
                                     title: "Flagged", badge: nil,
                                     isSelected: selection == .flagged) { selection = .flagged }
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 10)

                    // My Lists header
                    if !visibleLists.isEmpty {
                        Text("MY LISTS")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 18)
                            .padding(.top, 14)
                            .padding(.bottom, 2)

                        ForEach(visibleLists, id: \.calendarIdentifier) { cal in
                            CalendarRow(
                                calendar: cal,
                                isSelected: selection == .list(cal.calendarIdentifier)
                            ) {
                                selection = .list(cal.calendarIdentifier)
                            }
                            .padding(.horizontal, 8)
                        }
                    }

                    Spacer(minLength: 8)
                }
            }

            // Settings footer
            Divider()
            HStack {
                Button {
                    SettingsWindowController.shared.open(manager: manager)
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 13))
                        Text("Lists")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                Spacer()
            }
        }
    }
}

// MARK: - Smart List Row

struct SmartListRow: View {
    let icon: String
    let color: Color
    let title: String
    let badge: Int?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                    .frame(width: 30, alignment: .center)

                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)

                Spacer()

                if let badge, badge > 0 {
                    Text("\(badge)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.trailing, 4)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .padding(.horizontal, 8)
            .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
            .cornerRadius(8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Calendar Row

struct CalendarRow: View {
    let calendar: EKCalendar
    let isSelected: Bool
    let action: () -> Void

    private var calColor: Color { Color(cgColor: calendar.cgColor) }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Circle()
                    .fill(calColor)
                    .frame(width: 11, height: 11)
                    .padding(.leading, 6)

                Text(calendar.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .padding(.horizontal, 8)
            .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
            .cornerRadius(8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
