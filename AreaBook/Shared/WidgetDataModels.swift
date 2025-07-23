import Foundation
import SwiftUI

// MARK: - Shared Data Models for Widgets

// Wellness Data Structure
// struct WellnessData: Codable {
//     var currentMood: MoodType = .good
//     var meditationMinutes: Int = 0
//     var waterGlasses: Int = 0
//     var sleepHours: Double = 0.0
//     var lastUpdated: Date = Date()
// }

// Widget Configuration
// struct WidgetConfiguration: Codable {
//     let enabledFeatures: [String]
//     let lastSync: Date
//     let widgetPreferences: WidgetPreferences
// }

// Widget Preferences
// struct WidgetPreferences: Codable {
//     var favoriteWidgets: [String] = []
//     var refreshInterval: Int = 15 // minutes
//     var showNotifications: Bool = true
//     var widgetTheme: WidgetTheme = .system
//     enum WidgetTheme: String, CaseIterable, Codable {
//         case system = "system"
//         case light = "light"
//         case dark = "dark"
//     }
// }

// MARK: - Widget Helper Extensions

// extension KeyIndicator {
//     var progressPercentage: Double {
//         guard weeklyTarget > 0 else { return 0 }
//         return min(Double(currentWeekProgress) / Double(weeklyTarget), 1.0)
//     }
// }

// extension AppTask {
//     var status: TaskStatus {
//         return isCompleted ? .completed : .pending
//     }
//     
//     enum TaskStatus {
//         case completed
//         case pending
//     }
// }

// extension Goal {
//     var calculatedProgress: Double {
//         guard let targetDate = targetDate else { return 0 }
//         
//         let totalDays = Calendar.current.dateComponents([.day], from: Date(), to: targetDate).day ?? 0
//         let elapsedDays = Calendar.current.dateComponents([.day], from: Date(), to: targetDate).day ?? 0
//         
//         guard totalDays > 0 else { return 0 }
//         
//         let progress = max(0, min(100, (Double(elapsedDays) / Double(totalDays)) * 100))
//         return progress
//     }
// }

// MARK: - Widget Data Keys
// enum WidgetDataKeys {
//     static let keyIndicators = "keyIndicators"
//     static let todaysTasks = "todaysTasks"
//     static let todaysEvents = "todaysEvents"
//     static let goals = "goals"
//     static let recentNotes = "recentNotes"
//     static let wellnessData = "wellnessData"
//     static let enabledFeatures = "enabledFeatures"
//     static let widgetPreferences = "widgetPreferences"
// }

// MARK: - Widget Types
enum WidgetType: String, CaseIterable {
    case dashboard = "AreaBookWidget"
    case keyIndicators = "KIProgressWidget"
    case wellness = "WellnessWidget"
    case tasks = "TasksWidget"
    case goals = "GoalsWidget"
    
    var displayName: String {
        switch self {
        case .dashboard: return "AreaBook Dashboard"
        case .keyIndicators: return "Key Indicators"
        case .wellness: return "Wellness Tracker"
        case .tasks: return "Today's Tasks"
        case .goals: return "Goal Progress"
        }
    }
    
    var description: String {
        switch self {
        case .dashboard: return "Overview of key indicators, tasks, and events"
        case .keyIndicators: return "Track your weekly progress on key metrics"
        case .wellness: return "Monitor mood, meditation, and wellness activities"
        case .tasks: return "Quick view of your daily tasks and priorities"
        case .goals: return "Track progress on your personal goals"
        }
    }
    
    var icon: String {
        switch self {
        case .dashboard: return "book.pages"
        case .keyIndicators: return "chart.bar.fill"
        case .wellness: return "heart.fill"
        case .tasks: return "checkmark.square.fill"
        case .goals: return "target"
        }
    }
    
    var color: Color {
        switch self {
        case .dashboard: return .blue
        case .keyIndicators: return .green
        case .wellness: return .pink
        case .tasks: return .orange
        case .goals: return .purple
        }
    }
    
    var supportedSizes: [WidgetSize] {
        switch self {
        case .dashboard: return [.small, .medium, .large]
        case .keyIndicators, .wellness, .tasks, .goals: return [.small, .medium]
        }
    }
}

// MARK: - Widget Data Utilities
// struct WidgetDataUtilities {
//     static let sharedDefaults = UserDefaults(suiteName: "group.com.areabook.app")
//     static func saveData<T: Codable>(_ data: T, forKey key: String) {
//         if let encoded = try? JSONEncoder().encode(data) {
//             sharedDefaults?.set(encoded, forKey: key)
//         }
//     }
//     static func loadData<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
//         guard let data = sharedDefaults?.data(forKey: key) else { return nil }
//         return try? JSONDecoder().decode(type, from: data)
//     }
//     static func clearData(forKey key: String) {
//         sharedDefaults?.removeObject(forKey: key)
//     }
//     static func clearAllWidgetData() {
//         WidgetDataKeys.allCases.forEach { key in
//             sharedDefaults?.removeObject(forKey: key.rawValue)
//         }
//     }
// }

// WidgetFamily type for compatibility with WidgetKit
#if canImport(WidgetKit)
import WidgetKit
#else
// If WidgetKit is not available, define a stub:
enum WidgetFamily: String, CaseIterable, Codable {
    case systemSmall, systemMedium, systemLarge
}
#endif 