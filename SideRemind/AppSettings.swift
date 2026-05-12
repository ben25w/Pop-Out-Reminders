import Foundation

class AppSettings: ObservableObject {
    static let shared = AppSettings()

    // Panel geometry — observed by SidebarPanel via Combine
    @Published var panelWidth: CGFloat = 390 {
        didSet { panelWidth = max(300, min(660, panelWidth)) }
    }
    @Published var panelHeightFraction: Double = 0.70 {
        didSet { panelHeightFraction = max(0.40, min(0.95, panelHeightFraction)) }
    }

    // Sidebar list column width (internal split)
    @Published var sidebarWidth: CGFloat = 150 {
        didSet { sidebarWidth = max(120, min(240, sidebarWidth)) }
    }

    // Persisted list preferences
    @Published var hiddenCalendarIds: Set<String> {
        didSet { UserDefaults.standard.set(Array(hiddenCalendarIds), forKey: "hiddenCalendarIds") }
    }
    @Published var calendarOrder: [String] {
        didSet { UserDefaults.standard.set(calendarOrder, forKey: "calendarOrder") }
    }

    private init() {
        hiddenCalendarIds = Set(UserDefaults.standard.stringArray(forKey: "hiddenCalendarIds") ?? [])
        calendarOrder = UserDefaults.standard.stringArray(forKey: "calendarOrder") ?? []
    }

    func toggleHidden(_ calendarId: String) {
        if hiddenCalendarIds.contains(calendarId) {
            hiddenCalendarIds.remove(calendarId)
        } else {
            hiddenCalendarIds.insert(calendarId)
        }
    }
}
