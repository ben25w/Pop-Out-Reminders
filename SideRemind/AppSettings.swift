import Foundation

class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var panelWidth: CGFloat {
        didSet { UserDefaults.standard.set(Double(panelWidth), forKey: "panelWidth") }
    }
    @Published var panelHeightFraction: Double {
        didSet { UserDefaults.standard.set(panelHeightFraction, forKey: "panelHeightFraction") }
    }
    @Published var sidebarWidth: CGFloat {
        didSet { UserDefaults.standard.set(Double(sidebarWidth), forKey: "sidebarWidth") }
    }

    @Published var hiddenCalendarIds: Set<String> {
        didSet { UserDefaults.standard.set(Array(hiddenCalendarIds), forKey: "hiddenCalendarIds") }
    }
    @Published var calendarOrder: [String] {
        didSet { UserDefaults.standard.set(calendarOrder, forKey: "calendarOrder") }
    }

    private init() {
        let ud = UserDefaults.standard
        let w  = ud.double(forKey: "panelWidth")
        let hf = ud.double(forKey: "panelHeightFraction")
        let sw = ud.double(forKey: "sidebarWidth")
        panelWidth          = w  > 0 ? CGFloat(w)  : 390
        panelHeightFraction = hf > 0 ? hf           : 0.70
        sidebarWidth        = sw > 0 ? CGFloat(sw)  : 150
        hiddenCalendarIds   = Set(ud.stringArray(forKey: "hiddenCalendarIds") ?? [])
        calendarOrder       = ud.stringArray(forKey: "calendarOrder") ?? []
    }

    func toggleHidden(_ calendarId: String) {
        if hiddenCalendarIds.contains(calendarId) {
            hiddenCalendarIds.remove(calendarId)
        } else {
            hiddenCalendarIds.insert(calendarId)
        }
    }
}
