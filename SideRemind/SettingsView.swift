import SwiftUI
import EventKit
import ServiceManagement

struct SettingsView: View {
    @EnvironmentObject var manager: RemindersManager
    @EnvironmentObject var settings: AppSettings

    @State private var orderedIds: [String] = []
    @State private var launchAtLogin = Self.launchAtLoginIsEnabled
    @State private var launchAtLoginMessage: String?

    private static let registeredBundlePathKey = "launchAtLoginRegisteredBundlePath"
    private static let repairAttemptedBundlePathKey = "launchAtLoginRepairAttemptedBundlePath"

    private static var launchAtLoginIsEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

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
        .onAppear {
            seedOrder()
            refreshLaunchAtLoginStatus()
            repairLaunchAtLoginRegistrationIfNeeded()
        }
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

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Launch at Login")
                        .font(.system(size: 12, weight: .medium))
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { launchAtLogin },
                        set: { updateLaunchAtLogin(to: $0) }
                    ))
                    .toggleStyle(.switch)
                    .controlSize(.small)
                }

                if let launchAtLoginMessage {
                    Text(launchAtLoginMessage)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
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

    private func refreshLaunchAtLoginStatus() {
        launchAtLogin = Self.launchAtLoginIsEnabled

        switch SMAppService.mainApp.status {
        case .requiresApproval:
            launchAtLoginMessage = "Allow Pop Out Reminders in System Settings > General > Login Items."
        case .notFound:
            launchAtLoginMessage = "Move Pop Out Reminders to Applications, then turn this on again."
        default:
            launchAtLoginMessage = nil
        }
    }

    private func updateLaunchAtLogin(to enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
                UserDefaults.standard.set(Bundle.main.bundlePath, forKey: Self.registeredBundlePathKey)
                UserDefaults.standard.removeObject(forKey: Self.repairAttemptedBundlePathKey)
            } else {
                try SMAppService.mainApp.unregister()
                UserDefaults.standard.removeObject(forKey: Self.registeredBundlePathKey)
                UserDefaults.standard.removeObject(forKey: Self.repairAttemptedBundlePathKey)
            }
            refreshLaunchAtLoginStatus()
        } catch {
            NSLog("Launch at Login update failed: %@", error.localizedDescription)
            launchAtLogin = Self.launchAtLoginIsEnabled
            launchAtLoginMessage = "Could not update Launch at Login: \(error.localizedDescription)"
        }
    }

    private func repairLaunchAtLoginRegistrationIfNeeded() {
        let currentPath = Bundle.main.bundlePath
        let defaults = UserDefaults.standard

        guard Self.launchAtLoginIsEnabled,
              currentPath.hasPrefix("/Applications/"),
              defaults.string(forKey: Self.registeredBundlePathKey) != currentPath,
              defaults.string(forKey: Self.repairAttemptedBundlePathKey) != currentPath
        else { return }

        do {
            try SMAppService.mainApp.unregister()
            try SMAppService.mainApp.register()
            defaults.set(currentPath, forKey: Self.registeredBundlePathKey)
            defaults.removeObject(forKey: Self.repairAttemptedBundlePathKey)
            refreshLaunchAtLoginStatus()
        } catch {
            defaults.set(currentPath, forKey: Self.repairAttemptedBundlePathKey)
            NSLog("Launch at Login repair failed: %@", error.localizedDescription)
            launchAtLogin = Self.launchAtLoginIsEnabled
            launchAtLoginMessage = "Launch at Login needs resetting. Turn it off and on again, then allow it in System Settings if asked."
        }
    }
}
