import SwiftUI
import EventKit
import ServiceManagement

struct SettingsView: View {
    @EnvironmentObject var manager: RemindersManager
    @EnvironmentObject var settings: AppSettings

    @State private var orderedIds: [String] = []
    @State private var launchAtLogin = (SMAppService.mainApp.status == .enabled)

    private var orderedLists: [EKCalendar] {
        orderedIds.compactMap { id in manager.lists.first { $0.calendarIdentifier == id } }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    sizeSection
                    Divider().padding(.horizontal, 16)
                    remindersSection
                    Divider().padding(.horizontal, 16)
                    listsSection
                }
            }
        }
        .frame(width: 340)
        .onAppear { seedOrder() }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("Settings")
                .font(.system(size: 15, weight: .semibold))
            Spacer()
            Button("Done") { commit(); SettingsWindowController.shared.close() }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Size section

    private var sizeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("GENERAL")

            HStack {
                Text("Launch at Login")
                    .font(.system(size: 12, weight: .medium))
                Spacer()
                Toggle("", isOn: $launchAtLogin)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .onChange(of: launchAtLogin) { _, newValue in
                        do {
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            launchAtLogin = !newValue
                        }
                    }
            }

            Divider()
            sectionLabel("PANEL SIZE")

            // Panel width
            sliderRow(
                label: "Panel width",
                value: $settings.panelWidth,
                range: 300...660,
                step: 10,
                display: "\(Int(settings.panelWidth)) px"
            )

            // Panel height
            sliderRow(
                label: "Panel height",
                value: Binding(
                    get: { settings.panelHeightFraction },
                    set: { settings.panelHeightFraction = $0 }
                ),
                range: 0.40...0.95,
                step: 0.05,
                display: "\(Int(settings.panelHeightFraction * 100))%"
            )

            // Sidebar list column
            sliderRow(
                label: "Lists column width",
                value: $settings.sidebarWidth,
                range: 120...240,
                step: 5,
                display: "\(Int(settings.sidebarWidth)) px"
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func sliderRow<V: BinaryFloatingPoint>(
        label: String,
        value: Binding<V>,
        range: ClosedRange<V>,
        step: V.Stride,
        display: String
    ) -> some View where V.Stride: BinaryFloatingPoint {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                Spacer()
                Text(display)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .monospacedDigit()
                    .frame(minWidth: 48, alignment: .trailing)
            }
            Slider(value: value, in: range, step: step)
                .controlSize(.small)
        }
    }

    // MARK: - Reminders section

    private var remindersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("REMINDERS")

            HStack {
                Text("Default List")
                    .font(.system(size: 12, weight: .medium))
                Spacer()
                Picker("", selection: Binding(
                    get: { settings.defaultCalendarId ?? "" },
                    set: { settings.defaultCalendarId = $0.isEmpty ? nil : $0 }
                )) {
                    Text("System Default").tag("")
                    ForEach(manager.lists, id: \.calendarIdentifier) { cal in
                        HStack {
                            Circle()
                                .fill(Color(cgColor: cal.cgColor))
                                .frame(width: 8, height: 8)
                            Text(cal.title)
                        }
                        .tag(cal.calendarIdentifier)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: 160)
            }

            HStack {
                Text("Show Completed Items")
                    .font(.system(size: 12, weight: .medium))
                Spacer()
                Toggle("", isOn: $settings.showCompleted)
                    .toggleStyle(.switch)
                    .controlSize(.small)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Lists section

    private var listsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("MY LISTS")
            Text("Drag to reorder · tap eye to hide")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.bottom, 4)

            List {
                ForEach(orderedLists, id: \.calendarIdentifier) { cal in
                    listRow(cal)
                }
                .onMove { from, to in
                    orderedIds.move(fromOffsets: from, toOffset: to)
                }
            }
            .listStyle(.plain)
            .frame(minHeight: CGFloat(max(3, orderedLists.count)) * 40)
        }
        .padding(.top, 14)
        .padding(.bottom, 16)
    }

    private func listRow(_ cal: EKCalendar) -> some View {
        let hidden = settings.hiddenCalendarIds.contains(cal.calendarIdentifier)
        return HStack(spacing: 10) {
            Button {
                settings.toggleHidden(cal.calendarIdentifier)
            } label: {
                Image(systemName: hidden ? "eye.slash" : "eye")
                    .font(.system(size: 14))
                    .foregroundColor(hidden ? .secondary : .primary)
                    .frame(width: 22)
            }
            .buttonStyle(.plain)

            Circle()
                .fill(Color(cgColor: cal.cgColor))
                .frame(width: 10, height: 10)

            Text(cal.title)
                .font(.system(size: 13))
                .foregroundColor(hidden ? .secondary : .primary)

            Spacer()

            Image(systemName: "line.3.horizontal")
                .foregroundColor(Color(.tertiaryLabelColor))
                .font(.system(size: 12))
        }
        .padding(.vertical, 2)
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(.secondary)
            .padding(.horizontal, 16)
    }

    private func seedOrder() {
        let saved = settings.calendarOrder
        let allIds = manager.lists.map { $0.calendarIdentifier }
        orderedIds = saved.filter { allIds.contains($0) }
            + allIds.filter { !saved.contains($0) }
    }

    private func commit() {
        settings.calendarOrder = orderedIds
    }
}
