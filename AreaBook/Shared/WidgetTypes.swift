import Foundation
import SwiftUI

// MARK: - Widget-Specific Types (Shared between main app and widget extension)

// MARK: - Key Indicator
public struct WidgetKeyIndicator: Identifiable, Codable {
    public let id: String
    public var name: String
    public var weeklyTarget: Int
    public var unit: String
    public var color: String
    public var progress: Double
    public var createdAt: Date
    public var updatedAt: Date
    
    public var progressPercentage: Double {
        guard weeklyTarget > 0 else { return 0 }
        return min(progress / Double(weeklyTarget), 1.0)
    }
    
    public init(id: String = UUID().uuidString, name: String, weeklyTarget: Int, unit: String, color: String, progress: Double = 0, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.weeklyTarget = weeklyTarget
        self.unit = unit
        self.color = color
        self.progress = progress
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - App Task
public struct WidgetAppTask: Identifiable, Codable {
    public let id: String
    public var title: String
    public var description: String?
    public var priority: WidgetTaskPriority
    public var status: WidgetTaskStatus
    public var dueDate: Date?
    public var completedAt: Date?
    public var linkedGoalId: String?
    public var linkedEventId: String?
    public var progressContribution: Double?
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(id: String = UUID().uuidString, title: String, description: String? = nil, priority: WidgetTaskPriority = .medium, status: WidgetTaskStatus = .pending, dueDate: Date? = nil, completedAt: Date? = nil, linkedGoalId: String? = nil, linkedEventId: String? = nil, progressContribution: Double? = nil, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.description = description
        self.priority = priority
        self.status = status
        self.dueDate = dueDate
        self.completedAt = completedAt
        self.linkedGoalId = linkedGoalId
        self.linkedEventId = linkedEventId
        self.progressContribution = progressContribution
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public enum WidgetTaskPriority: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    public var displayName: String {
        rawValue.capitalized
    }
    
    public var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}

public enum WidgetTaskStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case inProgress = "inProgress"
    case completed = "completed"
    case cancelled = "cancelled"
    
    public var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }
}

// MARK: - Calendar Event
public struct WidgetCalendarEvent: Identifiable, Codable {
    public let id: String
    public var title: String
    public var description: String?
    public var category: String
    public var startTime: Date
    public var endTime: Date
    public var status: WidgetEventStatus
    public var linkedGoalId: String?
    public var progressContribution: Double?
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(id: String = UUID().uuidString, title: String, description: String? = nil, category: String = "Personal", startTime: Date, endTime: Date, status: WidgetEventStatus = .scheduled, linkedGoalId: String? = nil, progressContribution: Double? = nil, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.startTime = startTime
        self.endTime = endTime
        self.status = status
        self.linkedGoalId = linkedGoalId
        self.progressContribution = progressContribution
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public enum WidgetEventStatus: String, Codable, CaseIterable {
    case scheduled = "scheduled"
    case inProgress = "inProgress"
    case completed = "completed"
    case cancelled = "cancelled"
    
    public var displayName: String {
        switch self {
        case .scheduled: return "Scheduled"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }
}

// MARK: - Goal
public struct WidgetGoal: Identifiable, Codable {
    public let id: String
    public var title: String
    public var description: String?
    public var targetDate: Date
    public var targetValue: Double
    public var currentValue: Double
    public var unit: String
    public var status: WidgetGoalStatus
    public var keyIndicatorIds: [String]
    public var createdAt: Date
    public var updatedAt: Date
    
    public var progressPercentage: Double {
        guard targetValue > 0 else { return 0 }
        return min(currentValue / targetValue, 1.0)
    }
    
    public init(id: String = UUID().uuidString, title: String, description: String? = nil, targetDate: Date, targetValue: Double, currentValue: Double = 0, unit: String, status: WidgetGoalStatus = .active, keyIndicatorIds: [String] = [], createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.description = description
        self.targetDate = targetDate
        self.targetValue = targetValue
        self.currentValue = currentValue
        self.unit = unit
        self.status = status
        self.keyIndicatorIds = keyIndicatorIds
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public enum WidgetGoalStatus: String, Codable, CaseIterable {
    case active = "active"
    case completed = "completed"
    case paused = "paused"
    case cancelled = "cancelled"
    
    public var displayName: String {
        rawValue.capitalized
    }
}

// MARK: - Note
public struct WidgetNote: Identifiable, Codable {
    public let id: String
    public var title: String
    public var content: String
    public var linkedGoalIds: [String]
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(id: String = UUID().uuidString, title: String, content: String, linkedGoalIds: [String] = [], createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.content = content
        self.linkedGoalIds = linkedGoalIds
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Wellness Data
public struct WidgetWellnessData: Codable {
    public var currentMood: WidgetMoodType = .good
    public var meditationMinutes: Int = 0
    public var waterGlasses: Int = 0
    public var sleepHours: Double = 0.0
    
    public init(currentMood: WidgetMoodType = .good, meditationMinutes: Int = 0, waterGlasses: Int = 0, sleepHours: Double = 0.0) {
        self.currentMood = currentMood
        self.meditationMinutes = meditationMinutes
        self.waterGlasses = waterGlasses
        self.sleepHours = sleepHours
    }
}

public enum WidgetMoodType: String, Codable, CaseIterable {
    case excellent = "excellent"
    case good = "good"
    case okay = "okay"
    case bad = "bad"
    case terrible = "terrible"
    
    public var displayName: String {
        rawValue.capitalized
    }
    
    public var emoji: String {
        switch self {
        case .excellent: return "😄"
        case .good: return "🙂"
        case .okay: return "😐"
        case .bad: return "😔"
        case .terrible: return "😢"
        }
    }
}

// MARK: - App Feature
public enum WidgetAppFeature: String, Codable, CaseIterable {
    case keyIndicators = "keyIndicators"
    case goals = "goals"
    case tasks = "tasks"
    case calendar = "calendar"
    case notes = "notes"
    case wellness = "wellness"
    case groups = "groups"
    case ai = "ai"
    case financial = "financial"
    case fitness = "fitness"
    case academic = "academic"
    
    public var displayName: String {
        switch self {
        case .keyIndicators: return "Key Indicators"
        case .goals: return "Goals"
        case .tasks: return "Tasks"
        case .calendar: return "Calendar"
        case .notes: return "Notes"
        case .wellness: return "Wellness"
        case .groups: return "Groups"
        case .ai: return "AI Assistant"
        case .financial: return "Financial"
        case .fitness: return "Fitness"
        case .academic: return "Academic"
        }
    }
    
    public var icon: String {
        switch self {
        case .keyIndicators: return "chart.bar.fill"
        case .goals: return "target"
        case .tasks: return "checklist"
        case .calendar: return "calendar"
        case .notes: return "note.text"
        case .wellness: return "heart.fill"
        case .groups: return "person.3.fill"
        case .ai: return "brain.head.profile"
        case .financial: return "dollarsign.circle.fill"
        case .fitness: return "figure.run"
        case .academic: return "book.fill"
        }
    }
    
    public static let defaultFeatures: [WidgetAppFeature] = [
        .keyIndicators, .goals, .tasks, .calendar, .notes, .wellness
    ]
}

// MARK: - Widget Data Keys
public struct WidgetDataKeys {
    public static let keyIndicators = "keyIndicators"
    public static let todaysTasks = "todaysTasks"
    public static let todaysEvents = "todaysEvents"
    public static let goals = "goals"
    public static let recentNotes = "recentNotes"
    public static let wellnessData = "wellnessData"
    public static let enabledFeatures = "enabledFeatures"
    public static let widgetPreferences = "widgetPreferences"
    
    public static let allKeys = [
        keyIndicators,
        todaysTasks,
        todaysEvents,
        goals,
        recentNotes,
        wellnessData,
        enabledFeatures,
        widgetPreferences
    ]
}

// MARK: - Widget Data Utilities
public struct WidgetDataUtilities {
    // Use shared UserDefaults for widget data synchronization
    private static let sharedDefaults = UserDefaults(suiteName: "group.com.areabook.ios.widget")
    
    public static func saveData<T: Codable>(_ data: T, forKey key: String) {
        do {
            let encoded = try JSONEncoder().encode(data)
            sharedDefaults?.set(encoded, forKey: key)
            sharedDefaults?.synchronize()
        } catch {
            print("❌ WidgetDataUtilities: Failed to save data for key \(key): \(error)")
        }
    }
    
    public static func loadData<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = sharedDefaults?.data(forKey: key) else {
            return nil
        }
        
        do {
            let decoded = try JSONDecoder().decode(type, from: data)
            return decoded
        } catch {
            print("❌ WidgetDataUtilities: Failed to load data for key \(key): \(error)")
            return nil
        }
    }
    
    public static func clearData(forKey key: String) {
        sharedDefaults?.removeObject(forKey: key)
        sharedDefaults?.synchronize()
    }
    
    public static func clearAllWidgetData() {
        for key in WidgetDataKeys.allKeys {
            clearData(forKey: key)
        }
    }
}

// MARK: - Color Extension
public extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
} 