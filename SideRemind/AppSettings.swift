import Foundation

class AppSettings: ObservableObject {
    static let shared = AppSettings()

    // Panel geometry — Slider in: ranges already clamp these, no didSet needed
    @Published var panelWidth: CGFloat = 390
    @Published var panelHeightFraction: Double = 0.70
    @Published var sidebarWidth: CGFloat = 150

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
