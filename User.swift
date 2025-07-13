import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable {
    let id: String
    let fullname: String
    let email: String
    var keyIndicators: [KeyIndicator]
    var accountabilityGroups: [String] // Group IDs
    var settings: UserSettings
    
    enum CodingKeys: String, CodingKey {
        case id = "uid"
        case fullname
        case email
        case keyIndicators
        case accountabilityGroups
        case settings
    }
}

struct UserSettings: Codable {
    var eventColorScheme: EventColorScheme
    var defaultCalendarView: CalendarViewType
    var defaultTaskView: TaskViewType
    var notificationsEnabled: Bool
    var dailyKIReviewTime: String // "HH:mm" format
    
    init() {
        self.eventColorScheme = .standard
        self.defaultCalendarView = .monthly
        self.defaultTaskView = .byDay
        self.notificationsEnabled = true
        self.dailyKIReviewTime = "21:00"
    }
}

enum EventColorScheme: String, CaseIterable, Codable {
    case standard = "standard"
    case pastel = "pastel"
    case bold = "bold"
    case minimal = "minimal"
}

enum CalendarViewType: String, CaseIterable, Codable {
    case monthly = "monthly"
    case weekly = "weekly"
    case daily = "daily"
}

enum TaskViewType: String, CaseIterable, Codable {
    case byDay = "byDay"
    case byWeek = "byWeek"
    case byGoal = "byGoal"
    case all = "all"
}

struct KeyIndicator: Identifiable, Codable {
    let id: String
    let name: String
    let weeklyTarget: Int
    var currentWeekProgress: Int
    let createdAt: Date
    var isActive: Bool
    
    var progressPercentage: Double {
        guard weeklyTarget > 0 else { return 0.0 }
        return min(Double(currentWeekProgress) / Double(weeklyTarget), 1.0)
    }
    
    init(name: String, weeklyTarget: Int) {
        self.id = UUID().uuidString
        self.name = name
        self.weeklyTarget = weeklyTarget
        self.currentWeekProgress = 0
        self.createdAt = Date()
        self.isActive = true
    }
}