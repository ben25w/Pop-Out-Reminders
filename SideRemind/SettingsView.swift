import SwiftUI
import EventKit

struct SettingsView: View {
    @EnvironmentObject var manager: RemindersManager
    @StateObject private var settings = AppSettings.shared
    @Environment(\.dismiss) private var dismiss

    // Local copy for drag-to-reorder, seeded from manager.lists in order
    @State private var orderedIds: [String] = []

    private var orderedLists: [EKCalendar] {
        orderedIds.compactMap { id in manager.lists.first { $0.calendarIdentifier == id } }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                Button("Done") { commit(); dismiss() }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            // Section label
            Text("MY LISTS — drag to reorder, click eye to hide")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 4)

            // Reorderable list
            List {
                ForEach(orderedLists, id: \.calendarIdentifier) { cal in
                    HStack(spacing: 10) {
                        // Eye toggle
                        Button {
                            settings.toggleHidden(cal.calendarIdentifier)
                        } label: {
                            Image(systemName: settings.hiddenCalendarIds.contains(cal.calendarIdentifier)
                                  ? "eye.slash" : "eye")
                                .font(.system(size: 14))
                                .foregroundColor(settings.hiddenCalendarIds.contains(cal.calendarIdentifier)
                                                 ? .secondary : .primary)
                                .frame(width: 20)
                        }
                        .buttonStyle(.plain)

                        // Colour dot
                        Circle()
                            .fill(Color(cgColor: cal.cgColor))
                            .frame(width: 10, height: 10)

                        // Name (greyed if hidden)
                        Text(cal.title)
                            .font(.system(size: 13))
                            .foregroundColor(settings.hiddenCalendarIds.contains(cal.calendarIdentifier)
                                             ? .secondary : .primary)

                        Spacer()

                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(.secondary)
                            .font(.system(size: 12))
                    }
                    .padding(.vertical, 2)
                }
                .onMove { from, to in
                    orderedIds.move(fromOffsets: from, toOffset: to)
                }
            }
            .listStyle(.plain)
            .frame(minHeight: 200)
        }
        .frame(width: 320)
        .onAppear { seedOrder() }
    }

    private func seedOrder() {
        // Start from saved order, append any new lists not yet in the order
        let saved = settings.calendarOrder
        let allIds = manager.lists.map { $0.calendarIdentifier }
        let merged = saved.filter { allIds.contains($0) }
            + allIds.filter { !saved.contains($0) }
        orderedIds = merged
    }

    private func commit() {
        settings.calendarOrder = orderedIds
    }
}
