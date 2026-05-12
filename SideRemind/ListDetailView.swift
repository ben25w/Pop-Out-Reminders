import SwiftUI
import EventKit

struct ListDetailView: View {
    let calendarIdentifier: String
    @EnvironmentObject var manager: RemindersManager
    @State private var reminders: [EKReminder] = []
    @State private var isLoading = true
    @State private var showingAdd = false

    private var calendar: EKCalendar? {
        manager.lists.first { $0.calendarIdentifier == calendarIdentifier }
    }

    private var accentColor: Color {
        guard let cal = calendar else { return .accentColor }
        return Color(cgColor: cal.cgColor)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            content
        }
        .task(id: calendarIdentifier) { await load() }
        .onChange(of: manager.version) { _, _ in Task { await load() } }
        .sheet(isPresented: $showingAdd) {
            AddReminderView(preselectedCalendar: calendar)
                .environmentObject(manager)
        }
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
            Button { showingAdd = true } label: {
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
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    if reminders.isEmpty {
                        emptyState(icon: "checkmark.circle", message: "No reminders\nDouble-click to add one")
                            .frame(minHeight: 200)
                            .onTapGesture(count: 2) { showingAdd = true }
                    } else {
                        ForEach(reminders, id: \.calendarItemIdentifier) { r in
                            ReminderRowView(reminder: r)
                                .environmentObject(manager)
                            Divider().padding(.leading, 42)
                        }
                    }

                    // Empty space below list — double-click to add
                    Color.clear
                        .frame(maxWidth: .infinity, minHeight: 80)
                        .contentShape(Rectangle())
                        .onTapGesture(count: 2) { showingAdd = true }
                }
            }
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
