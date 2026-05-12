import Foundation

class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var panelWidth: CGFloat = 390
    @Published var sidebarWidth: CGFloat = 150

    // Persisted list preferences
    @Published var hiddenCalendarIds: Set<String> {
        didSet { UserDefaults.standard.set(Array(hiddenCalendarIds), forKey: "hiddenCalendarIds") }
    }
    @Published var calendarOrder: [String] {
        didSet { UserDefaults.standard.set(calendarOrder, forKey: "calendarOrder") }
    }

    var onPanelWidthChange: ((CGFloat) -> Void)?

    private init() {
        hiddenCalendarIds = Set(UserDefaults.standard.stringArray(forKey: "hiddenCalendarIds") ?? [])
        calendarOrder = UserDefaults.standard.stringArray(forKey: "calendarOrder") ?? []
    }

    func setPanelWidth(_ w: CGFloat) {
        let clamped = max(300, min(660, w))
        panelWidth = clamped
        onPanelWidthChange?(clamped)
    }

    func toggleHidden(_ calendarId: String) {
        if hiddenCalendarIds.contains(calendarId) {
            hiddenCalendarIds.remove(calendarId)
        } else {
            hiddenCalendarIds.insert(calendarId)
        }
    }

    func applyOrder(from lists: [any Identifiable]) {
        // Called on first load to seed calendarOrder if empty
    }
}
