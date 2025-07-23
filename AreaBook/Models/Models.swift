import Foundation
import SwiftUI
import FirebaseFirestore // Added for DocumentSnapshot

// MARK: - User Models
struct User: Identifiable, Codable {
    
    let id: String
    var email: String
    var name: String
    var avatar: String?
    var createdAt: Date
    var lastSeen: Date
    var settings: UserSettings
    
    // Memberwise initializer for direct construction
    init(id: String, email: String, name: String, avatar: String?, createdAt: Date, lastSeen: Date, settings: UserSettings) {
        self.id = id
        self.email = email
        self.name = name
        self.avatar = avatar
        self.createdAt = createdAt
        self.lastSeen = lastSeen
        self.settings = settings
    }
    // Add an initializer from [String: Any]
    init?(dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? String,
              let email = dictionary["email"] as? String,
              let name = dictionary["name"] as? String else { 
            return nil 
        }
        
        self.id = id
        self.email = email
        self.name = name
        self.avatar = dictionary["avatar"] as? String
        
        // Safely handle createdAt - could be Timestamp or Date
        if let timestamp = dictionary["createdAt"] as? Timestamp {
            self.createdAt = timestamp.dateValue()
        } else if let date = dictionary["createdAt"] as? Date {
            self.createdAt = date
        } else {
            self.createdAt = Date() // Fallback
        }
        
        // Safely handle lastSeen - could be Timestamp or Date
        if let timestamp = dictionary["lastSeen"] as? Timestamp {
            self.lastSeen = timestamp.dateValue()
        } else if let date = dictionary["lastSeen"] as? Date {
            self.lastSeen = date
        } else {
            self.lastSeen = Date() // Fallback
        }
        
        // Safely handle settings - try different approaches
        if let settingsDict = dictionary["settings"] as? [String: Any] {
            // Try to create UserSettings from dictionary
            do {
                let settingsData = try JSONSerialization.data(withJSONObject: settingsDict)
                self.settings = try JSONDecoder().decode(UserSettings.self, from: settingsData)
            } catch {
                print("⚠️ Failed to decode UserSettings, using defaults: \(error)")
                self.settings = UserSettings() // Use default settings
            }
        } else {
            print("⚠️ No settings found in user data, using defaults")
            self.settings = UserSettings() // Use default settings
        }
    }
    // Add an initializer from DocumentSnapshot
    init?(snapshot: DocumentSnapshot) {
        guard let data = snapshot.data() else { return nil }
        self.init(dictionary: data)
    }
}

struct UserSettings: Codable {
    var defaultCalendarView: CalendarViewType = .monthly
    var defaultTaskView: TaskViewType = .day
    var eventColorScheme: [String: String] = [
        "Church": "#3B82F6",
        "School": "#10B981",
        "Personal": "#8B5CF6",
        "Work": "#F59E0B"
    ]
    var notificationsEnabled: Bool = true
    var pushNotifications: Bool = true
    var dailyKIReviewTime: String?
    // --- Customization fields ---
    var userProfile: UserProfile = .general
    var enabledFeatures: Set<AppFeature> = Set(AppFeature.defaultFeatures)
    var dashboardLayout: DashboardLayout = DashboardLayout.default
    var customWidgets: [DashboardWidget] = []
    var aiPreferences: AIPreferences = AIPreferences()
    
    // Widget Settings
    var widgetSize: WidgetSize? = .medium
    var widgetTheme: WidgetTheme? = .system
    var widgetRefreshInterval: RefreshInterval? = .hourly
    var widgetShowKeyIndicators: Bool? = true
    var widgetShowTasks: Bool? = true
    var widgetShowEvents: Bool? = true
    
    // Siri Settings
    var siriEnabled: Bool = false
    var siriShortcuts: [String] = []
    
    // MARK: - Initializers
    init() {
        // Default initializer with default values
        self.defaultCalendarView = .monthly
        self.defaultTaskView = .day
        self.eventColorScheme = [
            "Church": "#3B82F6",
            "School": "#10B981",
            "Personal": "#8B5CF6",
            "Work": "#F59E0B"
        ]
        self.notificationsEnabled = true
        self.pushNotifications = true
        self.dailyKIReviewTime = nil
        self.userProfile = .general
        self.enabledFeatures = Set(AppFeature.defaultFeatures)
        self.dashboardLayout = DashboardLayout.default
        self.customWidgets = []
        self.aiPreferences = AIPreferences()
        self.widgetSize = .medium
        self.widgetTheme = .system
        self.widgetRefreshInterval = .hourly
        self.widgetShowKeyIndicators = true
        self.widgetShowTasks = true
        self.widgetShowEvents = true
        self.siriEnabled = false
        self.siriShortcuts = []
    }
    
    // MARK: - Codable Implementation
    enum CodingKeys: String, CodingKey {
        case defaultCalendarView, defaultTaskView, eventColorScheme, notificationsEnabled
        case pushNotifications, dailyKIReviewTime, userProfile, enabledFeatures
        case dashboardLayout, customWidgets, aiPreferences, widgetSize, widgetTheme
        case widgetRefreshInterval, widgetShowKeyIndicators, widgetShowTasks, widgetShowEvents
        case siriEnabled, siriShortcuts
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Use safer decoding with fallbacks for all properties
        do {
            defaultCalendarView = try container.decodeIfPresent(CalendarViewType.self, forKey: .defaultCalendarView) ?? .monthly
        } catch {
            print("⚠️ UserSettings: Failed to decode defaultCalendarView, using default")
            defaultCalendarView = .monthly
        }
        
        do {
            defaultTaskView = try container.decodeIfPresent(TaskViewType.self, forKey: .defaultTaskView) ?? .day
        } catch {
            print("⚠️ UserSettings: Failed to decode defaultTaskView, using default")
            defaultTaskView = .day
        }
        
        eventColorScheme = (try? container.decodeIfPresent([String: String].self, forKey: .eventColorScheme)) ?? [
            "Church": "#3B82F6",
            "School": "#10B981",
            "Personal": "#8B5CF6",
            "Work": "#F59E0B"
        ]
        
        notificationsEnabled = (try? container.decodeIfPresent(Bool.self, forKey: .notificationsEnabled)) ?? true
        pushNotifications = (try? container.decodeIfPresent(Bool.self, forKey: .pushNotifications)) ?? true
        dailyKIReviewTime = try? container.decodeIfPresent(String.self, forKey: .dailyKIReviewTime)
        
        do {
            userProfile = try container.decodeIfPresent(UserProfile.self, forKey: .userProfile) ?? .general
        } catch {
            print("⚠️ UserSettings: Failed to decode userProfile, using default")
            userProfile = .general
        }
        
        // Safely decode enabledFeatures as array and convert to Set
        do {
            let featuresArray = try container.decodeIfPresent([AppFeature].self, forKey: .enabledFeatures) ?? AppFeature.defaultFeatures
            enabledFeatures = Set(featuresArray)
        } catch {
            print("⚠️ UserSettings: Failed to decode enabledFeatures, using defaults")
            enabledFeatures = Set(AppFeature.defaultFeatures)
        }
        
        // Safely decode complex objects
        do {
            dashboardLayout = try container.decodeIfPresent(DashboardLayout.self, forKey: .dashboardLayout) ?? DashboardLayout.default
        } catch {
            print("⚠️ UserSettings: Failed to decode dashboardLayout, using default")
            dashboardLayout = DashboardLayout.default
        }
        
        customWidgets = (try? container.decodeIfPresent([DashboardWidget].self, forKey: .customWidgets)) ?? []
        
        do {
            aiPreferences = try container.decodeIfPresent(AIPreferences.self, forKey: .aiPreferences) ?? AIPreferences()
        } catch {
            print("⚠️ UserSettings: Failed to decode aiPreferences, using default")
            aiPreferences = AIPreferences()
        }
        
        // Widget settings with safe fallbacks
        widgetSize = try? container.decodeIfPresent(WidgetSize.self, forKey: .widgetSize)
        widgetTheme = try? container.decodeIfPresent(WidgetTheme.self, forKey: .widgetTheme)
        widgetRefreshInterval = try? container.decodeIfPresent(RefreshInterval.self, forKey: .widgetRefreshInterval)
        widgetShowKeyIndicators = (try? container.decodeIfPresent(Bool.self, forKey: .widgetShowKeyIndicators)) ?? true
        widgetShowTasks = (try? container.decodeIfPresent(Bool.self, forKey: .widgetShowTasks)) ?? true
        widgetShowEvents = (try? container.decodeIfPresent(Bool.self, forKey: .widgetShowEvents)) ?? true
        
        siriEnabled = (try? container.decodeIfPresent(Bool.self, forKey: .siriEnabled)) ?? false
        siriShortcuts = (try? container.decodeIfPresent([String].self, forKey: .siriShortcuts)) ?? []
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(defaultCalendarView, forKey: .defaultCalendarView)
        try container.encode(defaultTaskView, forKey: .defaultTaskView)
        try container.encode(eventColorScheme, forKey: .eventColorScheme)
        try container.encode(notificationsEnabled, forKey: .notificationsEnabled)
        try container.encode(pushNotifications, forKey: .pushNotifications)
        try container.encodeIfPresent(dailyKIReviewTime, forKey: .dailyKIReviewTime)
        try container.encode(userProfile, forKey: .userProfile)
        
        // Encode enabledFeatures as array
        try container.encode(Array(enabledFeatures), forKey: .enabledFeatures)
        
        try container.encode(dashboardLayout, forKey: .dashboardLayout)
        try container.encode(customWidgets, forKey: .customWidgets)
        try container.encode(aiPreferences, forKey: .aiPreferences)
        
        try container.encodeIfPresent(widgetSize, forKey: .widgetSize)
        try container.encodeIfPresent(widgetTheme, forKey: .widgetTheme)
        try container.encodeIfPresent(widgetRefreshInterval, forKey: .widgetRefreshInterval)
        try container.encodeIfPresent(widgetShowKeyIndicators, forKey: .widgetShowKeyIndicators)
        try container.encodeIfPresent(widgetShowTasks, forKey: .widgetShowTasks)
        try container.encodeIfPresent(widgetShowEvents, forKey: .widgetShowEvents)
        
        try container.encode(siriEnabled, forKey: .siriEnabled)
        try container.encode(siriShortcuts, forKey: .siriShortcuts)
    }
}

// MARK: - User Profile Types
enum UserProfile: String, Codable, CaseIterable {
    case general, student, business, workplace, family, relationship, wellbeing, fitness, creative, religious, language, financial, travel, volunteer, rehab
    
    var displayName: String {
        self.rawValue.capitalized
    }
}

// MARK: - Wellness Data
struct WellnessData: Codable {
    var currentMood: MoodType = .good
    var meditationMinutes: Int = 0
    var waterGlasses: Int = 0
    var sleepHours: Double = 0.0
    var lastUpdated: Date = Date()
}

enum MoodType: String, Codable, CaseIterable {
    case excellent = "excellent"
    case good = "good"
    case okay = "okay"
    case bad = "bad"
    case terrible = "terrible"
    
    var displayName: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .okay: return "Okay"
        case .bad: return "Bad"
        case .terrible: return "Terrible"
        }
    }
    
    var emoji: String {
        switch self {
        case .excellent: return "😃"
        case .good: return "🙂"
        case .okay: return "😐"
        case .bad: return "😞"
        case .terrible: return "😫"
        }
    }
}

// MARK: - Event Categories
struct EventCategory: Identifiable, Codable {
    let id: String
    var name: String
    var color: String
    var icon: String
    
    init(name: String, color: String, icon: String) {
        self.id = UUID().uuidString
        self.name = name
        self.color = color
        self.icon = icon
    }
    
    var categoryColor: Color {
        ColorTheme().colorFromHex(color)
    }
}

// MARK: - Color Theme Manager
// Remove the entire ColorThemeManager class definition from this file.

enum AppColorTheme: String, Codable, CaseIterable {
    case blue = "blue"
    case green = "green"
    case purple = "purple"
    case orange = "orange"
    case pink = "pink"
    case red = "red"
    case yellow = "yellow"
    case teal = "teal"
    
    var color: Color {
        switch self {
        case .blue: return .blue
        case .green: return .green
        case .purple: return .purple
        case .orange: return .orange
        case .pink: return .pink
        case .red: return .red
        case .yellow: return .yellow
        case .teal: return .teal
        }
    }
}

// MARK: - Widget and Siri Settings
enum WidgetSize: String, Codable, CaseIterable {
    case small, medium, large
    
    var displayName: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        }
    }
    
    var systemFamily: WidgetFamily {
        switch self {
        case .small: return .systemSmall
        case .medium: return .systemMedium
        case .large: return .systemLarge
        }
    }
}

// WidgetFamily type for compatibility with WidgetKit
#if canImport(WidgetKit)
import WidgetKit
#else
// If WidgetKit is not available, define a stub:
enum WidgetFamily: String, CaseIterable, Codable {
    case systemSmall, systemMedium, systemLarge
}
#endif

enum WidgetTheme: String, Codable, CaseIterable {
    case system, light, dark, colorful
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        case .colorful: return "Colorful"
        }
    }
}

enum RefreshInterval: String, Codable, CaseIterable {
    case fifteenMinutes = "15min"
    case thirtyMinutes = "30min"
    case hourly = "1hour"
    case daily = "daily"
    
    var displayName: String {
        switch self {
        case .fifteenMinutes: return "15 Minutes"
        case .thirtyMinutes: return "30 Minutes"
        case .hourly: return "Hourly"
        case .daily: return "Daily"
        }
    }
}

// MARK: - App Features
enum FeatureCategory: String, Codable, CaseIterable {
    case core, social, productivity, wellness, academic, business, professional, family, relationship, fitness, creative, religious, language, financial, travel, volunteer, recovery
    
    var displayName: String {
        switch self {
        case .core: return "Core Features"
        case .social: return "Social"
        case .productivity: return "Productivity"
        case .wellness: return "Wellness"
        case .academic: return "Academic"
        case .business: return "Business"
        case .professional: return "Professional"
        case .family: return "Family"
        case .relationship: return "Relationship"
        case .fitness: return "Fitness"
        case .creative: return "Creative"
        case .religious: return "Religious"
        case .language: return "Language"
        case .financial: return "Financial"
        case .travel: return "Travel"
        case .volunteer: return "Volunteer"
        case .recovery: return "Recovery"
        }
    }
}

enum AppFeature: String, Codable, CaseIterable, Hashable {
    // Core
    case goals, tasks, calendar, notes, keyIndicators, dashboard
    // Social
    case groups, sharing, accountability
    // Productivity
    case siriShortcuts, widgets, dataExport, aiAssistant
    // Wellness
    case moodTracking, meditationTimer, selfCareRoutines
    // Academic
    case academicTracking, studyTimer, assignmentManager
    // Business
    case businessMetrics, teamManagement, financialTracking
    // Professional
    case professionalDevelopment, workLifeBalance
    // Family
    case familyActivities, parentingGoals, householdManagement
    // Relationship
    case relationshipGoals, communicationTracking, datePlanning
    // Fitness
    case workoutTracking, nutritionTracking, healthMonitoring
    // Creative
    case projectTracking, inspirationLog, portfolioGoals
    // Religious
    case prayerTracking, scriptureStudy, serviceActivities
    // Language
    case studySessions, vocabularyPractice, conversationTracking
    // Financial
    case budgetTracking, savingsGoals, investmentMonitoring
    // Travel
    case tripPlanning, bucketList, travelMemories
    // Volunteer
    case serviceHours, donationTracking, communityInvolvement
    // Recovery
    case recoveryMilestones, triggerTracking, supportNetwork

    static var defaultFeatures: [AppFeature] {
        [.goals, .tasks, .calendar, .notes, .keyIndicators, .dashboard, .groups]
    }

    var displayName: String {
        switch self {
        case .goals: return "Goals"
        case .tasks: return "Tasks"
        case .calendar: return "Calendar"
        case .notes: return "Notes"
        case .keyIndicators: return "Life Trackers"
        case .dashboard: return "Dashboard"
        case .groups: return "Groups"
        case .sharing: return "Sharing"
        case .accountability: return "Accountability"
        case .siriShortcuts: return "Siri Shortcuts"
        case .widgets: return "Widgets"
        case .dataExport: return "Data Export"
        case .aiAssistant: return "AI Assistant"
        case .moodTracking: return "Mood Tracking"
        case .meditationTimer: return "Meditation Timer"
        case .selfCareRoutines: return "Self-Care Routines"
        case .academicTracking: return "Academic Tracking"
        case .studyTimer: return "Study Timer"
        case .assignmentManager: return "Assignment Manager"
        case .businessMetrics: return "Business Metrics"
        case .teamManagement: return "Team Management"
        case .financialTracking: return "Financial Tracking"
        case .professionalDevelopment: return "Professional Development"
        case .workLifeBalance: return "Work-Life Balance"
        case .familyActivities: return "Family Activities"
        case .parentingGoals: return "Parenting Goals"
        case .householdManagement: return "Household Management"
        case .relationshipGoals: return "Relationship Goals"
        case .communicationTracking: return "Communication Tracking"
        case .datePlanning: return "Date Planning"
        case .workoutTracking: return "Workout Tracking"
        case .nutritionTracking: return "Nutrition Tracking"
        case .healthMonitoring: return "Health Monitoring"
        case .projectTracking: return "Project Tracking"
        case .inspirationLog: return "Inspiration Log"
        case .portfolioGoals: return "Portfolio Goals"
        case .prayerTracking: return "Prayer Tracking"
        case .scriptureStudy: return "Scripture Study"
        case .serviceActivities: return "Service Activities"
        case .studySessions: return "Study Sessions"
        case .vocabularyPractice: return "Vocabulary Practice"
        case .conversationTracking: return "Conversation Tracking"
        case .budgetTracking: return "Budget Tracking"
        case .savingsGoals: return "Savings Goals"
        case .investmentMonitoring: return "Investment Monitoring"
        case .tripPlanning: return "Trip Planning"
        case .bucketList: return "Bucket List"
        case .travelMemories: return "Travel Memories"
        case .serviceHours: return "Service Hours"
        case .donationTracking: return "Donation Tracking"
        case .communityInvolvement: return "Community Involvement"
        case .recoveryMilestones: return "Recovery Milestones"
        case .triggerTracking: return "Trigger Tracking"
        case .supportNetwork: return "Support Network"
        }
    }

    var description: String {
        switch self {
        case .goals: return "Set and track personal goals with progress monitoring."
        case .tasks: return "Manage daily tasks and to-do lists."
        case .calendar: return "Schedule events and manage your time."
        case .notes: return "Create and organize notes and ideas."
        case .keyIndicators: return "Track weekly habits and life metrics."
        case .dashboard: return "Personalized overview of your progress."
        case .groups: return "Create accountability groups and teams."
        case .sharing: return "Share progress with friends and family."
        case .accountability: return "Get accountability from your groups."
        case .siriShortcuts: return "Use voice commands with Siri."
        case .widgets: return "Add widgets to your home screen."
        case .dataExport: return "Export and backup your data."
        case .aiAssistant: return "Get AI-powered suggestions and insights."
        case .moodTracking: return "Track your daily mood and emotions."
        case .meditationTimer: return "Set meditation and mindfulness timers."
        case .selfCareRoutines: return "Track self-care activities and routines."
        case .academicTracking: return "Monitor academic progress and grades."
        case .studyTimer: return "Pomodoro-style study timers."
        case .assignmentManager: return "Manage assignments and deadlines."
        case .businessMetrics: return "Track business KPIs and metrics."
        case .teamManagement: return "Manage team goals and progress."
        case .financialTracking: return "Track business finances and revenue."
        case .professionalDevelopment: return "Track career goals and skills."
        case .workLifeBalance: return "Monitor work-life balance metrics."
        case .familyActivities: return "Plan and track family activities."
        case .parentingGoals: return "Set and track parenting objectives."
        case .householdManagement: return "Manage household tasks and chores."
        case .relationshipGoals: return "Set relationship and couple goals."
        case .communicationTracking: return "Track communication with partner."
        case .datePlanning: return "Plan and track date activities."
        case .workoutTracking: return "Track workouts and exercise routines."
        case .nutritionTracking: return "Monitor nutrition and meal planning."
        case .healthMonitoring: return "Track health metrics and appointments."
        case .projectTracking: return "Track creative projects and milestones."
        case .inspirationLog: return "Log creative inspiration and ideas."
        case .portfolioGoals: return "Track portfolio and creative goals."
        case .prayerTracking: return "Track prayer and spiritual activities."
        case .scriptureStudy: return "Monitor scripture study progress."
        case .serviceActivities: return "Track service and volunteer work."
        case .studySessions: return "Track language study sessions."
        case .vocabularyPractice: return "Practice and track vocabulary."
        case .conversationTracking: return "Track conversation practice."
        case .budgetTracking: return "Track personal budget and expenses."
        case .savingsGoals: return "Set and track savings goals."
        case .investmentMonitoring: return "Monitor investments and returns."
        case .tripPlanning: return "Plan trips and travel itineraries."
        case .bucketList: return "Track bucket list items and adventures."
        case .travelMemories: return "Log travel memories and experiences."
        case .serviceHours: return "Track volunteer service hours."
        case .donationTracking: return "Track donations and charitable giving."
        case .communityInvolvement: return "Monitor community participation."
        case .recoveryMilestones: return "Track recovery progress and milestones."
        case .triggerTracking: return "Track triggers and coping strategies."
        case .supportNetwork: return "Manage support network and contacts."
        }
    }

    var icon: String {
        switch self {
        case .goals: return "target"
        case .tasks: return "checkmark.circle"
        case .calendar: return "calendar"
        case .notes: return "note.text"
        case .keyIndicators: return "chart.bar"
        case .dashboard: return "square.grid.2x2"
        case .groups: return "person.3"
        case .sharing: return "square.and.arrow.up"
        case .accountability: return "hand.raised"
        case .siriShortcuts: return "mic"
        case .widgets: return "rectangle.stack"
        case .dataExport: return "arrow.up.doc"
        case .aiAssistant: return "brain.head.profile"
        case .moodTracking: return "heart"
        case .meditationTimer: return "timer"
        case .selfCareRoutines: return "leaf"
        case .academicTracking: return "book"
        case .studyTimer: return "clock"
        case .assignmentManager: return "doc.text"
        case .businessMetrics: return "chart.line.uptrend.xyaxis"
        case .teamManagement: return "person.2"
        case .financialTracking: return "dollarsign.circle"
        case .professionalDevelopment: return "briefcase"
        case .workLifeBalance: return "scalemass"
        case .familyActivities: return "house"
        case .parentingGoals: return "figure.and.child.holdinghands"
        case .householdManagement: return "wrench.and.screwdriver"
        case .relationshipGoals: return "heart.circle"
        case .communicationTracking: return "message"
        case .datePlanning: return "calendar.badge.plus"
        case .workoutTracking: return "dumbbell"
        case .nutritionTracking: return "fork.knife"
        case .healthMonitoring: return "cross.case"
        case .projectTracking: return "paintbrush"
        case .inspirationLog: return "lightbulb"
        case .portfolioGoals: return "folder"
        case .prayerTracking: return "hands.sparkles"
        case .scriptureStudy: return "book.closed"
        case .serviceActivities: return "hand.raised.fill"
        case .studySessions: return "graduationcap"
        case .vocabularyPractice: return "textformat.abc"
        case .conversationTracking: return "bubble.left.and.bubble.right"
        case .budgetTracking: return "creditcard"
        case .savingsGoals: return "banknote"
        case .investmentMonitoring: return "chart.pie"
        case .tripPlanning: return "airplane"
        case .bucketList: return "list.star"
        case .travelMemories: return "camera"
        case .serviceHours: return "clock.badge"
        case .donationTracking: return "gift"
        case .communityInvolvement: return "building.2"
        case .recoveryMilestones: return "flag.checkered"
        case .triggerTracking: return "exclamationmark.triangle"
        case .supportNetwork: return "person.crop.circle.badge.plus"
        }
    }

    var category: FeatureCategory {
        switch self {
        case .goals, .tasks, .calendar, .notes, .keyIndicators, .dashboard:
            return .core
        case .groups, .sharing, .accountability:
            return .social
        case .siriShortcuts, .widgets, .dataExport, .aiAssistant:
            return .productivity
        case .moodTracking, .meditationTimer, .selfCareRoutines:
            return .wellness
        case .academicTracking, .studyTimer, .assignmentManager:
            return .academic
        case .businessMetrics, .teamManagement, .financialTracking:
            return .business
        case .professionalDevelopment, .workLifeBalance:
            return .professional
        case .familyActivities, .parentingGoals, .householdManagement:
            return .family
        case .relationshipGoals, .communicationTracking, .datePlanning:
            return .relationship
        case .workoutTracking, .nutritionTracking, .healthMonitoring:
            return .fitness
        case .projectTracking, .inspirationLog, .portfolioGoals:
            return .creative
        case .prayerTracking, .scriptureStudy, .serviceActivities:
            return .religious
        case .studySessions, .vocabularyPractice, .conversationTracking:
            return .language
        case .budgetTracking, .savingsGoals, .investmentMonitoring:
            return .financial
        case .tripPlanning, .bucketList, .travelMemories:
            return .travel
        case .serviceHours, .donationTracking, .communityInvolvement:
            return .volunteer
        case .recoveryMilestones, .triggerTracking, .supportNetwork:
            return .recovery
        }
    }

    var color: Color {
        switch self {
        case .goals: return .purple
        case .tasks: return .orange
        case .calendar: return .blue
        case .notes: return .yellow
        case .keyIndicators: return .green
        case .dashboard: return .gray
        case .aiAssistant: return .cyan
        // Add more as needed
        default: return .blue
        }
    }
}

struct FeatureCatalog {
    static let all: [AppFeature] = AppFeature.allCases
    static func features(for category: FeatureCategory) -> [AppFeature] {
        all.filter { $0.category == category }
    }
    static func featureInfo(_ feature: AppFeature) -> (name: String, description: String, icon: String, category: FeatureCategory) {
        (feature.displayName, feature.description, feature.icon, feature.category)
    }
}

// MARK: - Dashboard Layout
struct DashboardLayout: Codable {
    var widgets: [DashboardWidget]
    var gridRows: Int
    var gridCols: Int
    static let `default` = DashboardLayout(widgets: [
        DashboardWidget(type: .keyIndicators, size: .standard, position: (0,0)),
        DashboardWidget(type: .tasks, size: .medium, position: (0,1), orientation: .horizontal),
        DashboardWidget(type: .goals, size: .standard, position: (1,0)),
        DashboardWidget(type: .events, size: .standard, position: (1,1))
    ], gridRows: 2, gridCols: 3)
}

// MARK: - Dashboard Widget
struct DashboardWidget: Codable, Identifiable {
    var id: String = UUID().uuidString
    var type: DashboardWidgetType
    var size: DashboardWidgetSize
    var positionRow: Int
    var positionCol: Int
    var orientation: WidgetOrientation = .horizontal // Only applies to medium widgets
    var config: [String: String] = [:] // For customizations
    
    var position: (row: Int, col: Int) {
        get { (positionRow, positionCol) }
        set { 
            positionRow = newValue.row
            positionCol = newValue.col
        }
    }
    
    var gridSize: (rows: Int, cols: Int) {
        orientation.getGridSize(for: size)
    }
    
    init(type: DashboardWidgetType, size: DashboardWidgetSize, position: (row: Int, col: Int), orientation: WidgetOrientation = .horizontal, config: [String: String] = [:]) {
        self.type = type
        self.size = size
        self.positionRow = position.row
        self.positionCol = position.col
        self.orientation = orientation
        self.config = config
    }
}

// MARK: - AI Preferences
struct AIPreferences: Codable {
    var assistantStyle: AssistantStyle = .supportive
    // Add other AI preference properties as needed
    init(assistantStyle: AssistantStyle = .supportive) {
        self.assistantStyle = assistantStyle
    }
}

enum AssistantStyle: String, Codable, CaseIterable {
    case supportive = "supportive"
    case analytical = "analytical"
    case motivational = "motivational"
    case casual = "casual"
    case formal = "formal"
    
    var displayName: String {
        switch self {
        case .supportive: return "Supportive"
        case .analytical: return "Analytical"
        case .motivational: return "Motivational"
        case .casual: return "Casual"
        case .formal: return "Formal"
        }
    }
}


enum CalendarViewType: String, Codable, CaseIterable {
    case day = "day"
    case weekly = "weekly"
    case monthly = "monthly"
}

enum TaskViewType: String, Codable, CaseIterable {
    case day = "day"
    case week = "week"
    case goal = "goal"
}

// MARK: - Key Indicator Models
struct KeyIndicator: Identifiable, Codable {
    var id: String
    var name: String
    var weeklyTarget: Int
    var currentWeekProgress: Int
    var unit: String
    var color: String
    var createdAt: Date
    var updatedAt: Date
    
    var progressPercentage: Double {
        guard weeklyTarget > 0 else { return 0 }
        return min(Double(currentWeekProgress) / Double(weeklyTarget), 1.0)
    }
    
    init(name: String, weeklyTarget: Int, unit: String, color: String) {
        self.id = UUID().uuidString
        self.name = name
        self.weeklyTarget = weeklyTarget
        self.currentWeekProgress = 0
        self.unit = unit
        self.color = color
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Goal Models
struct Goal: Identifiable, Codable {
    var id: String
    var title: String
    var description: String
    var keyIndicatorIds: [String]
    var progress: Int // 0-100
    var status: GoalStatus
    var targetDate: Date?
    var createdAt: Date
    var updatedAt: Date
    var linkedNoteIds: [String]
    var stickyNotes: [StickyNote]
    
    // New fields for numerical tracking
    var targetValue: Double // Now required
    var currentValue: Double
    var unit: String
    var progressType: GoalProgressType
    
    // --- New fields for progress tracking ---
    var connectedKeyIndicatorId: String? // The key indicator this goal is connected to
    var progressAmount: Double? // The amount of progress this goal contributes
    // --- End new fields ---
    
    // --- Key Indicator Classification ---
    var isKeyIndicator: Bool = false // Whether this goal is classified as a Key Indicator
    var resetTimeline: ResetTimeline = .weekly // How often this KI resets (only applies if isKeyIndicator = true)
    var lastResetDate: Date? // When this KI was last reset
    // --- End Key Indicator fields ---
    
    init(title: String, description: String, keyIndicatorIds: [String] = [], targetDate: Date? = nil, targetValue: Double, unit: String = "", progressType: GoalProgressType = .percentage) {
        self.id = UUID().uuidString
        self.title = title
        self.description = description
        self.keyIndicatorIds = keyIndicatorIds
        self.progress = 0
        self.status = .active
        self.targetDate = targetDate
        self.createdAt = Date()
        self.updatedAt = Date()
        self.linkedNoteIds = []
        self.stickyNotes = []
        self.targetValue = targetValue
        self.currentValue = 0
        self.unit = unit
        self.progressType = progressType
    }
    
    // Computed property to calculate progress based on type
    var calculatedProgress: Int {
        switch progressType {
        case .percentage:
            return progress
        case .numerical:
            guard targetValue > 0 else { return 0 }
            let percentage = (currentValue / targetValue) * 100
            return min(Int(percentage), 100)
        case .keyIndicators:
            // Calculate based on linked key indicators progress
            return progress
        }
    }
    
    // Method to update progress when tasks/events are completed
    mutating func updateProgress(from task: AppTask) {
        if let contribution = task.progressContribution, contribution > 0 {
            updateProgress(contribution: contribution)
        }
    }
    
    mutating func updateProgress(from event: CalendarEvent) {
        if let contribution = event.progressContribution, contribution > 0 {
            updateProgress(contribution: contribution)
        }
    }
    
    // Unified method to update progress with contribution
    mutating func updateProgress(contribution: Double) {
        print("🎯 Goal: Updating progress with contribution: \(contribution)")
        print("🎯 Goal: Current progress type: \(progressType.rawValue)")
        print("🎯 Goal: Before update - Progress: \(progress)%, Current Value: \(currentValue), Target Value: \(targetValue)")
        
        switch progressType {
        case .numerical:
            currentValue += contribution
            print("🎯 Goal: Numerical update - New current value: \(currentValue)")
        case .percentage:
            // For percentage goals, convert contribution to percentage
            if targetValue > 0 {
                let percentageContribution = (contribution / targetValue) * 100
                progress = min(progress + Int(percentageContribution), 100)
                print("🎯 Goal: Percentage update - Percentage contribution: \(percentageContribution), New progress: \(progress)%")
            } else {
                print("🎯 Goal: Percentage update - Target value is 0, cannot calculate percentage")
            }
        case .keyIndicators:
            // Handle key indicator progress updates
            print("🎯 Goal: Key indicators update - Not implemented yet")
            break
        }
        self.updatedAt = Date()
        print("🎯 Goal: After update - Progress: \(progress)%, Current Value: \(currentValue), Target Value: \(targetValue)")
    }
    
    // MARK: - Key Indicator Methods
    
    /// Check if this Key Indicator goal needs to be reset based on its timeline
    func needsReset() -> Bool {
        guard isKeyIndicator else { return false }
        guard let lastReset = lastResetDate else { return true } // Never been reset
        
        let timeSinceReset = Date().timeIntervalSince(lastReset)
        return timeSinceReset >= resetTimeline.resetInterval
    }
    
    /// Reset the Key Indicator progress and update the reset date
    mutating func resetKeyIndicator() {
        guard isKeyIndicator else { return }
        
        // Reset progress values
        self.progress = 0
        self.currentValue = 0
        self.lastResetDate = Date()
        self.updatedAt = Date()
        
        print("🔄 Key Indicator '\(title)' reset for \(resetTimeline.displayName) cycle")
    }
    
    /// Get the progress percentage for Key Indicator display
    var keyIndicatorProgressPercentage: Double {
        guard isKeyIndicator else { return Double(calculatedProgress) }
        
        switch progressType {
        case .percentage:
            return Double(progress)
        case .numerical:
            guard targetValue > 0 else { return 0 }
            return min((currentValue / targetValue) * 100, 100)
        case .keyIndicators:
            return Double(progress)
        }
    }
}

enum GoalStatus: String, Codable, CaseIterable {
    case active = "active"
    case completed = "completed"
    case paused = "paused"
    case cancelled = "cancelled"
}

enum GoalProgressType: String, Codable, CaseIterable {
    case percentage = "percentage"
    case numerical = "numerical"
    case keyIndicators = "keyIndicators"
    
    var displayName: String {
        switch self {
        case .percentage: return "Percentage"
        case .numerical: return "Numerical Target"
        case .keyIndicators: return "Key Indicators"
        }
    }
}

// MARK: - Reset Timeline for Key Indicators
enum ResetTimeline: String, Codable, CaseIterable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case quarterly = "quarterly"
    case yearly = "yearly"
    
    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .quarterly: return "Quarterly"
        case .yearly: return "Yearly"
        }
    }
    
    var resetInterval: TimeInterval {
        switch self {
        case .daily: return 24 * 60 * 60 // 1 day
        case .weekly: return 7 * 24 * 60 * 60 // 7 days
        case .monthly: return 30 * 24 * 60 * 60 // 30 days (approximate)
        case .quarterly: return 90 * 24 * 60 * 60 // 90 days
        case .yearly: return 365 * 24 * 60 * 60 // 365 days
        }
    }
}

struct StickyNote: Identifiable, Codable {
    let id: String
    var content: String
    var color: String
    var position: CGPoint
    var createdAt: Date
    
    init(content: String, color: String = "#FBBF24", position: CGPoint = .zero) {
        self.id = UUID().uuidString
        self.content = content
        self.color = color
        self.position = position
        self.createdAt = Date()
    }
}

// MARK: - Calendar Event Models
struct CalendarEvent: Identifiable, Codable {
    var id: String
    var title: String
    var description: String
    var category: String
    var startTime: Date
    var endTime: Date
    var linkedGoalId: String?
    var taskIds: [String]
    var isRecurring: Bool
    var recurrencePattern: RecurrencePattern?
    var status: EventStatus
    var createdAt: Date
    var updatedAt: Date
    var progressContribution: Double?
    
    // --- New fields for progress tracking ---
    var connectedKeyIndicatorId: String? // The key indicator this event is connected to
    var progressAmount: Double? // The amount of progress this event contributes
    // --- End new fields ---
    
    init(title: String, description: String, category: String, startTime: Date, endTime: Date, linkedGoalId: String? = nil, progressContribution: Double? = nil) {
        self.id = UUID().uuidString
        self.title = title
        self.description = description
        self.category = category
        self.startTime = startTime
        self.endTime = endTime
        self.linkedGoalId = linkedGoalId
        self.taskIds = []
        self.isRecurring = false
        self.recurrencePattern = nil
        self.status = .scheduled
        self.createdAt = Date()
        self.updatedAt = Date()
        self.progressContribution = progressContribution
    }
}

enum EventStatus: String, Codable, CaseIterable {
    case scheduled = "scheduled"
    case completed = "completed"
    case cancelled = "cancelled"
}

struct RecurrencePattern: Codable {
    var type: RecurrenceType
    var interval: Int
    var daysOfWeek: [Int]? // 0-6, Sunday = 0
    var endDate: Date?
}

enum RecurrenceType: String, Codable, CaseIterable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case yearly = "yearly"
}

// MARK: - Task Models
struct AppTask: Identifiable, Codable {
    var id: String
    var title: String
    var description: String?
    var status: TaskStatus
    var priority: TaskPriority
    var dueDate: Date?
    var linkedGoalId: String?
    var linkedEventId: String?
    var subtasks: [Subtask]
    var createdAt: Date
    var updatedAt: Date
    var completedAt: Date?
    
    // New field for goal progress contribution
    var progressContribution: Double?
    
    // --- New fields for progress tracking ---
    var connectedKeyIndicatorId: String? // The key indicator this task is connected to
    var progressAmount: Double? // The amount of progress this task contributes
    // --- End new fields ---
    
    init(title: String, description: String? = nil, priority: TaskPriority = .medium, dueDate: Date? = nil, linkedGoalId: String? = nil, linkedEventId: String? = nil, progressContribution: Double? = nil) {
        self.id = UUID().uuidString
        self.title = title
        self.description = description
        self.status = .pending
        self.priority = priority
        self.dueDate = dueDate
        self.linkedGoalId = linkedGoalId
        self.linkedEventId = linkedEventId
        self.subtasks = []
        self.createdAt = Date()
        self.updatedAt = Date()
        self.completedAt = nil
        self.progressContribution = progressContribution
    }
}

enum TaskStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case completed = "completed"
    case failed = "failed"
    case skipped = "skipped"
}

enum TaskPriority: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}

struct Subtask: Identifiable, Codable {
    let id: String
    var title: String
    var completed: Bool
    var createdAt: Date
    
    init(title: String) {
        self.id = UUID().uuidString
        self.title = title
        self.completed = false
        self.createdAt = Date()
    }
}

// MARK: - Note Models
struct Note: Identifiable, Codable {
    let id: String
    var title: String
    var content: String // Markdown content
    var tags: [String]
    var linkedNoteIds: [String]
    var linkedGoalIds: [String]
    var linkedTaskIds: [String]
    var linkedEventIds: [String]
    var folder: String?
    var createdAt: Date
    var updatedAt: Date
    
    init(title: String, content: String = "", tags: [String] = [], folder: String? = nil) {
        self.id = UUID().uuidString
        self.title = title
        self.content = content
        self.tags = tags
        self.linkedNoteIds = []
        self.linkedGoalIds = []
        self.linkedTaskIds = []
        self.linkedEventIds = []
        self.folder = folder
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - AI Assistant Models

// MARK: - Passive AI Profile
struct PassiveAIProfile: Identifiable, Codable {
    let id: String
    var userId: String
    var skippedTasks: [String: Int] // Category -> count
    var commonKeywords: [String] // From notes and reflections
    var goalEngagement: [String: GoalEngagementData] // Goal ID -> engagement data
    var moodStreaks: [String: Int] // Mood -> consecutive days
    var activeHours: [String] // Most active hours
    var taskCompletionPatterns: [String: Double] // Category -> completion rate
    var emotionalPatterns: [String: Int] // Emotion -> frequency
    var lastUpdated: Date
    
    init(userId: String) {
        self.id = UUID().uuidString
        self.userId = userId
        self.skippedTasks = [:]
        self.commonKeywords = []
        self.goalEngagement = [:]
        self.moodStreaks = [:]
        self.activeHours = []
        self.taskCompletionPatterns = [:]
        self.emotionalPatterns = [:]
        self.lastUpdated = Date()
    }
}

struct GoalEngagementData: Codable {
    var lastUpdated: Date
    var interactionCount: Int
    var progressRate: Double
    var emotionalState: String? // "motivated", "frustrated", "overwhelmed"
    
    init() {
        self.lastUpdated = Date()
        self.interactionCount = 0
        self.progressRate = 0.0
        self.emotionalState = nil
    }
}

// MARK: - AI Suggestions
struct AISuggestion: Identifiable, Codable {
    let id: String
    var userId: String
    var type: SuggestionType
    var message: String
    var status: SuggestionStatus
    var priority: SuggestionPriority
    var relatedGoalId: String?
    var relatedTaskId: String?
    var relatedEventId: String?
    var createdAt: Date
    var expiresAt: Date?
    var acceptedAt: Date?
    var dismissedAt: Date?
    
    init(userId: String, type: SuggestionType, message: String, priority: SuggestionPriority = .medium) {
        self.id = UUID().uuidString
        self.userId = userId
        self.type = type
        self.message = message
        self.status = .pending
        self.priority = priority
        self.createdAt = Date()
        self.expiresAt = Calendar.current.date(byAdding: .day, value: 7, to: Date())
    }
}

enum SuggestionType: String, Codable, CaseIterable {
    case rescheduleTasks = "reschedule_tasks"
    case createGoal = "create_goal"
    case addReflection = "add_reflection"
    case adjustSchedule = "adjust_schedule"
    case emotionalSupport = "emotional_support"
    case habitFormation = "habit_formation"
    case relationshipFocus = "relationship_focus"
    case spiritualGrowth = "spiritual_growth"
    
    var displayName: String {
        switch self {
        case .rescheduleTasks: return "Schedule Adjustment"
        case .createGoal: return "Goal Creation"
        case .addReflection: return "Reflection Prompt"
        case .adjustSchedule: return "Schedule Optimization"
        case .emotionalSupport: return "Emotional Support"
        case .habitFormation: return "Habit Building"
        case .relationshipFocus: return "Relationship Focus"
        case .spiritualGrowth: return "Spiritual Growth"
        }
    }
    
    var icon: String {
        switch self {
        case .rescheduleTasks: return "clock.arrow.circlepath"
        case .createGoal: return "target"
        case .addReflection: return "brain.head.profile"
        case .adjustSchedule: return "calendar.badge.plus"
        case .emotionalSupport: return "heart.fill"
        case .habitFormation: return "repeat.circle"
        case .relationshipFocus: return "person.2.fill"
        case .spiritualGrowth: return "sparkles"
        }
    }
}

enum SuggestionStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case accepted = "accepted"
    case dismissed = "dismissed"
    case expired = "expired"
}

enum SuggestionPriority: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case urgent = "urgent"
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        case .urgent: return .purple
        }
    }
}

// MARK: - Assistant Plans
struct AssistantPlan: Identifiable, Codable {
    let id: String
    var userId: String
    var intent: String // User's stated intent
    var emotionalContext: String? // Detected emotional state
    var goals: [AssistantGoal]
    var tasks: [AssistantTask]
    var events: [AssistantEvent]
    var notes: [AssistantNote]
    var linkedFrom: String // "assistant", "passive_ai", "manual"
    var createdAt: Date
    var status: PlanStatus
    var feedbackScore: Int? // 1-5 rating
    
    init(userId: String, intent: String, linkedFrom: String = "assistant") {
        self.id = UUID().uuidString
        self.userId = userId
        self.intent = intent
        self.goals = []
        self.tasks = []
        self.events = []
        self.notes = []
        self.linkedFrom = linkedFrom
        self.createdAt = Date()
        self.status = .draft
    }
}

struct AssistantGoal: Identifiable, Codable {
    let id: String
    var title: String
    var description: String
    var targetValue: Double
    var unit: String
    var progressType: GoalProgressType
    var category: String // "spiritual", "family", "personal", "missionary"
    
    init(title: String, description: String, targetValue: Double, unit: String = "", progressType: GoalProgressType = .percentage, category: String = "personal") {
        self.id = UUID().uuidString
        self.title = title
        self.description = description
        self.targetValue = targetValue
        self.unit = unit
        self.progressType = progressType
        self.category = category
    }
}

struct AssistantTask: Identifiable, Codable {
    let id: String
    var title: String
    var description: String?
    var priority: TaskPriority
    var dueDate: Date?
    var progressContribution: Double?
    var category: String
    
    init(title: String, description: String? = nil, priority: TaskPriority = .medium, dueDate: Date? = nil, progressContribution: Double? = nil, category: String = "personal") {
        self.id = UUID().uuidString
        self.title = title
        self.description = description
        self.priority = priority
        self.dueDate = dueDate
        self.progressContribution = progressContribution
        self.category = category
    }
}

struct AssistantEvent: Identifiable, Codable {
    let id: String
    var title: String
    var description: String
    var category: String
    var startTime: Date
    var endTime: Date
    var progressContribution: Double?
    
    init(title: String, description: String, category: String, startTime: Date, endTime: Date, progressContribution: Double? = nil) {
        self.id = UUID().uuidString
        self.title = title
        self.description = description
        self.category = category
        self.startTime = startTime
        self.endTime = endTime
        self.progressContribution = progressContribution
    }
}

struct AssistantNote: Identifiable, Codable {
    let id: String
    var title: String
    var content: String
    var prompt: String? // AI-generated reflection prompt
    var tags: [String]
    
    init(title: String, content: String = "", prompt: String? = nil, tags: [String] = []) {
        self.id = UUID().uuidString
        self.title = title
        self.content = content
        self.prompt = prompt
        self.tags = tags
    }
}

enum PlanStatus: String, Codable, CaseIterable {
    case draft = "draft"
    case active = "active"
    case completed = "completed"
    case cancelled = "cancelled"
}

// MARK: - Assistant Chat Logs
struct AssistantChatLog: Identifiable, Codable {
    let id: String
    var userId: String
    var userInput: String
    var detectedIntent: String
    var passiveContext: PassiveContext
    var planGenerated: Bool
    var tasksAssigned: Int
    var eventsCreated: Int
    var goalsCreated: Int
    var notesCreated: Int
    var feedbackScore: Int? // 1-5 rating
    var timestamp: Date
    
    init(userId: String, userInput: String, detectedIntent: String, passiveContext: PassiveContext) {
        self.id = UUID().uuidString
        self.userId = userId
        self.userInput = userInput
        self.detectedIntent = detectedIntent
        self.passiveContext = passiveContext
        self.planGenerated = false
        self.tasksAssigned = 0
        self.eventsCreated = 0
        self.goalsCreated = 0
        self.notesCreated = 0
        self.timestamp = Date()
    }
}

struct PassiveContext: Codable {
    var goalEngagement: String // "high", "medium", "low"
    var recentKeywords: [String]
    var emotionalState: String?
    var taskCompletionRate: Double
    var activeGoals: Int
    var lastGoalUpdate: Date?
    
    init() {
        self.goalEngagement = "medium"
        self.recentKeywords = []
        self.emotionalState = nil
        self.taskCompletionRate = 0.0
        self.activeGoals = 0
        self.lastGoalUpdate = nil
    }
}

// MARK: - User Profile & Onboarding
// Note: UserProfile is defined as an enum above, this struct definition is removed to avoid conflicts

enum UserRole: String, Codable, CaseIterable {
    case student = "student"
    case recovery = "recovery"
    case relationship = "relationship"
    case family = "family"
    case missionary = "missionary"
    case personal = "personal"
    
    var displayName: String {
        switch self {
        case .student: return "Student"
        case .recovery: return "Recovery"
        case .relationship: return "Relationship"
        case .family: return "Family"
        case .missionary: return "Missionary"
        case .personal: return "Personal"
        }
    }
    
    var description: String {
        switch self {
        case .student: return "Focus on academic and personal development"
        case .recovery: return "Support for recovery and healing journey"
        case .relationship: return "Strengthening relationships and connections"
        case .family: return "Family planning and management"
        case .missionary: return "Missionary work and spiritual growth"
        case .personal: return "General personal development"
        }
    }
}

// Note: AIPreferences is defined above, this duplicate definition is removed

enum SuggestionFrequency: String, Codable, CaseIterable {
    case minimal = "minimal"
    case moderate = "moderate"
    case frequent = "frequent"
    case adaptive = "adaptive"
}

enum EmotionalTrackingLevel: String, Codable, CaseIterable {
    case none = "none"
    case basic = "basic"
    case detailed = "detailed"
    case comprehensive = "comprehensive"
}


enum PrivacyLevel: String, Codable, CaseIterable {
    case standard = "standard"
    case enhanced = "enhanced"
    case local = "local"
}

// MARK: - Accountability Group Models
struct AccountabilityGroup: Identifiable, Codable {
    let id: String
    var name: String
    var type: GroupType
    var parentGroupId: String? // For companionships within districts
    var members: [GroupMember]
    var settings: GroupSettings
    var createdAt: Date
    var updatedAt: Date
    var inviteCode: String // Add missing invite code property
    
    init(name: String, type: GroupType, parentGroupId: String? = nil) {
        self.id = UUID().uuidString
        self.name = name
        self.type = type
        self.parentGroupId = parentGroupId
        self.members = []
        self.settings = GroupSettings()
        self.createdAt = Date()
        self.updatedAt = Date()
        self.inviteCode = String((0..<6).map { _ in "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".randomElement()! }) // Generate random invite code
    }
    
    init?(from document: DocumentSnapshot) {
        guard let data = document.data() else { return nil }
        self.id = data["id"] as? String ?? ""
        self.name = data["name"] as? String ?? ""
        self.type = GroupType(rawValue: data["type"] as? String ?? "") ?? .district
        self.parentGroupId = data["parentGroupId"] as? String
        if let membersData = data["members"] as? [[String: Any]] {
            self.members = membersData.compactMap { GroupMember(dictionary: $0) }
        } else {
            self.members = []
        }
        if let settingsData = data["settings"] {
            print("DEBUG: settingsData type is \(Swift.type(of: settingsData)), value: \(settingsData)")
            if let dict = settingsData as? [String: Any] {
                self.settings = GroupSettings(from: dict)
            } else {
                self.settings = GroupSettings()
            }
        } else {
            self.settings = GroupSettings()
        }
        self.createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        self.updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
        self.inviteCode = data["inviteCode"] as? String ?? String((0..<6).map { _ in "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".randomElement()! })  // Add missing inviteCode initialization
    }
    
    func toFirestoreData() -> [String: Any] {
        return [
            "id": id,
            "name": name,
            "type": type.rawValue,
            "parentGroupId": parentGroupId as Any,
            "members": members.map { $0.toFirestoreData() },
            "settings": [
                "isPublic": settings.isPublic,
                "allowInvitations": settings.allowInvitations,
                "shareProgress": settings.shareProgress,
                "allowChallenges": settings.allowChallenges,
                "autoAcceptInvites": settings.autoAcceptInvites,
                "requireApproval": settings.requireApproval
            ],
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt),
            "inviteCode": inviteCode
        ]
    }
}

enum GroupType: String, Codable, CaseIterable {
    case district = "district"
    case companionship = "companionship"
}

struct GroupSettings: Codable {
    var isPublic: Bool = false
    var allowInvitations: Bool = true
    var shareProgress: Bool = true
    var allowChallenges: Bool = true
    var autoAcceptInvites: Bool = false
    var requireApproval: Bool = true
    var description: String = ""
    
    init() {}
    
    init(from data: [String: Any]) {
        self.isPublic = data["isPublic"] as? Bool ?? false
        self.allowInvitations = data["allowInvitations"] as? Bool ?? true
        self.shareProgress = data["shareProgress"] as? Bool ?? true
        self.allowChallenges = data["allowChallenges"] as? Bool ?? true
        self.autoAcceptInvites = data["autoAcceptInvites"] as? Bool ?? false
        self.requireApproval = data["requireApproval"] as? Bool ?? true
        self.description = data["description"] as? String ?? ""
    }
}

struct GroupMember: Identifiable, Codable {
    let id: String
    var userId: String
    var role: GroupRole
    var joinedAt: Date
    var lastActivity: Date
    var permissions: GroupPermissions
    
    init(userId: String, role: GroupRole) {
        self.id = UUID().uuidString
        self.userId = userId
        self.role = role
        self.joinedAt = Date()
        self.lastActivity = Date()
        self.permissions = GroupPermissions(role: role)
    }
    
    init(from document: DocumentSnapshot) {
        let data = document.data() ?? [:]
        self.id = data["id"] as? String ?? UUID().uuidString
        self.userId = data["userId"] as? String ?? ""
        self.role = GroupRole(rawValue: data["role"] as? String ?? "member") ?? .member
        self.joinedAt = (data["joinedAt"] as? Timestamp)?.dateValue() ?? Date()
        self.lastActivity = (data["lastActivity"] as? Timestamp)?.dateValue() ?? Date()
        self.permissions = GroupPermissions(role: self.role)
    }
    // Add dictionary initializer for Firestore decoding
    init(dictionary: [String: Any]) {
        self.id = dictionary["id"] as? String ?? UUID().uuidString
        self.userId = dictionary["userId"] as? String ?? ""
        self.role = GroupRole(rawValue: dictionary["role"] as? String ?? "member") ?? .member
        if let timestamp = dictionary["joinedAt"] as? Timestamp {
            self.joinedAt = timestamp.dateValue()
        } else if let date = dictionary["joinedAt"] as? Date {
            self.joinedAt = date
        } else {
            self.joinedAt = Date()
        }
        if let timestamp = dictionary["lastActivity"] as? Timestamp {
            self.lastActivity = timestamp.dateValue()
        } else if let date = dictionary["lastActivity"] as? Date {
            self.lastActivity = date
        } else {
            self.lastActivity = Date()
        }
        self.permissions = GroupPermissions(role: self.role)
    }
    
    func isAdmin() -> Bool {
        return role == .admin
    }
    
    func toFirestoreData() -> [String: Any] {
        return [
            "userId": userId,
            "role": role.rawValue,
            "joinedAt": Timestamp(date: joinedAt),
            "lastActivity": Timestamp(date: lastActivity)
        ]
    }
}

enum GroupRole: String, Codable, CaseIterable {
    case admin = "admin"
    case leader = "leader"
    case member = "member"
    case viewer = "viewer"
    case moderator = "moderator"
}

struct GroupPermissions: Codable {
    var canViewGoals: Bool
    var canViewEvents: Bool
    var canViewTasks: Bool
    var canViewKIs: Bool
    var canSendEncouragements: Bool
    var canManageMembers: Bool
    
    init(role: GroupRole) {
        switch role {
        case .admin:
            self.canViewGoals = true
            self.canViewEvents = true
            self.canViewTasks = true
            self.canViewKIs = true
            self.canSendEncouragements = true
            self.canManageMembers = true
        case .leader:
            self.canViewGoals = true
            self.canViewEvents = true
            self.canViewTasks = true
            self.canViewKIs = true
            self.canSendEncouragements = true
            self.canManageMembers = false
        case .member:
            self.canViewGoals = true
            self.canViewEvents = true
            self.canViewTasks = true
            self.canViewKIs = true
            self.canSendEncouragements = true
            self.canManageMembers = false
        case .viewer:
            self.canViewGoals = true
            self.canViewEvents = true
            self.canViewTasks = true
            self.canViewKIs = true
            self.canSendEncouragements = false
            self.canManageMembers = false
        case .moderator:
            self.canViewGoals = true
            self.canViewEvents = true
            self.canViewTasks = true
            self.canViewKIs = true
            self.canSendEncouragements = true
            self.canManageMembers = false
        }
    }
    
    var firestoreData: [String: Any] {
        return [
            "canViewGoals": canViewGoals,
            "canViewEvents": canViewEvents,
            "canViewTasks": canViewTasks,
            "canViewKIs": canViewKIs,
            "canSendEncouragements": canSendEncouragements,
            "canManageMembers": canManageMembers
        ]
    }
}

extension GroupPermissions {
    func toFirestoreData() -> [String: Any] {
        return [
            "canViewGoals": canViewGoals,
            "canViewEvents": canViewEvents,
            "canViewTasks": canViewTasks,
            "canViewKIs": canViewKIs,
            "canSendEncouragements": canSendEncouragements,
            "canManageMembers": canManageMembers
        ]
    }
}

struct Encouragement: Identifiable, Codable {
    let id: String
    var fromUserId: String
    var toUserId: String
    var message: String
    var type: EncouragementType
    var sentAt: Date
    var readAt: Date?
    
    init(fromUserId: String, toUserId: String, message: String, type: EncouragementType) {
        self.id = UUID().uuidString
        self.fromUserId = fromUserId
        self.toUserId = toUserId
        self.message = message
        self.type = type
        self.sentAt = Date()
        self.readAt = nil
    }
}

enum EncouragementType: String, Codable, CaseIterable {
    case encouragement = "encouragement"
    case nudge = "nudge"
    case congratulations = "congratulations"
}

// MARK: - Dashboard Models
struct DashboardData {
    var weeklyKIs: [KeyIndicator]
    var todaysTasks: [AppTask]
    var todaysEvents: [CalendarEvent]
    var quote: DailyQuote
    var recentGoals: [Goal]
}

struct DailyQuote: Codable {
    var text: String
    var author: String
    var source: String?
    
    static let samples = [
        DailyQuote(text: "Faith is a living, daring confidence in God's grace.", author: "Martin Luther", source: nil),
        DailyQuote(text: "The best time to plant a tree was 20 years ago. The second best time is now.", author: "Chinese Proverb", source: nil),
        DailyQuote(text: "Success is not final, failure is not fatal: it is the courage to continue that counts.", author: "Winston Churchill", source: nil),
        DailyQuote(text: "Be patient with yourself. Self-growth is tender; it's holy ground.", author: "Stephen Covey", source: nil)
    ]
}

struct ProgressShare: Identifiable, Codable {
    let id: String
    let userId: String
    let groupId: String
    let type: ProgressShareType
    let data: [String: String]
    let timestamp: Date
    
    init(id: String, userId: String, groupId: String, type: ProgressShareType, data: [String: String], timestamp: Date) {
        self.id = id
        self.userId = userId
        self.groupId = groupId
        self.type = type
        self.data = data
        self.timestamp = timestamp
    }
    
    init(from document: DocumentSnapshot) {
        let data = document.data() ?? [:]
        self.id = data["id"] as? String ?? ""
        self.userId = data["userId"] as? String ?? ""
        self.groupId = data["groupId"] as? String ?? ""
        self.type = ProgressShareType(rawValue: data["type"] as? String ?? "") ?? .goals
        self.data = data["data"] as? [String: String] ?? [:]
        self.timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
    }
    
    func toFirestoreData() -> [String: Any] {
        return [
            "id": id,
            "userId": userId,
            "groupId": groupId,
            "type": type.rawValue,
            "data": data,
            "timestamp": Timestamp(date: timestamp)
        ]
    }
}

enum ProgressShareType: String, Codable, CaseIterable {
    case goals = "goals"
    case events = "events"
    case tasks = "tasks"
    case kis = "kis"
    case kiUpdate = "kiUpdate"
    case goalProgress = "goalProgress"
    case taskCompleted = "taskCompleted"
    case milestone = "milestone"
    case achievement = "achievement"
}

struct GroupChallenge: Identifiable, Codable {
    let id: String
    var groupId: String
    var creatorId: String
    let title: String
    let description: String
    let type: ChallengeType
    let target: Double
    let unit: String
    let startDate: Date
    let endDate: Date
    var participants: [String]
    var isActive: Bool
    let createdAt: Date
    
    init(id: String, groupId: String, creatorId: String, title: String, description: String, type: ChallengeType, target: Double, unit: String, startDate: Date, endDate: Date, participants: [String], isActive: Bool, createdAt: Date) {
        self.id = id
        self.groupId = groupId
        self.creatorId = creatorId
        self.title = title
        self.description = description
        self.type = type
        self.target = target
        self.unit = unit
        self.startDate = startDate
        self.endDate = endDate
        self.participants = participants
        self.isActive = isActive
        self.createdAt = createdAt
    }
    
    init(from document: DocumentSnapshot) {
        let data = document.data() ?? [:]
        self.id = data["id"] as? String ?? ""
        self.groupId = data["groupId"] as? String ?? ""
        self.creatorId = data["creatorId"] as? String ?? ""
        self.title = data["title"] as? String ?? ""
        self.description = data["description"] as? String ?? ""
        self.type = ChallengeType(rawValue: data["type"] as? String ?? "") ?? .individual
        self.target = data["target"] as? Double ?? 0
        self.unit = data["unit"] as? String ?? ""
        self.startDate = (data["startDate"] as? Timestamp)?.dateValue() ?? Date()
        self.endDate = (data["endDate"] as? Timestamp)?.dateValue() ?? Date()
        self.participants = data["participants"] as? [String] ?? []
        self.isActive = data["isActive"] as? Bool ?? true
        self.createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
    }
    
    func toFirestoreData() -> [String: Any] {
        return [
            "id": id,
            "groupId": groupId,
            "creatorId": creatorId,
            "title": title,
            "description": description,
            "type": type.rawValue,
            "target": target,
            "unit": unit,
            "startDate": Timestamp(date: startDate),
            "endDate": Timestamp(date: endDate),
            "participants": participants,
            "isActive": isActive,
            "createdAt": Timestamp(date: createdAt)
        ]
    }
}

enum ChallengeType: String, Codable, CaseIterable {
    case individual = "individual"
    case group = "group"
}

// MARK: - Group Invitations
enum InvitationStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case accepted = "accepted"
    case declined = "declined"
    case expired = "expired"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .accepted: return "Accepted"
        case .declined: return "Declined"
        case .expired: return "Expired"
        }
    }
}

struct GroupInvitation: Identifiable, Codable {
    var id: String
    var groupId: String
    var groupName: String
    var fromUserId: String
    var toUserId: String
    var message: String
    var createdAt: Date
    var status: InvitationStatus
    
    init(id: String = UUID().uuidString, groupId: String, groupName: String, fromUserId: String, toUserId: String, message: String, createdAt: Date = Date(), status: InvitationStatus = .pending) {
        self.id = id
        self.groupId = groupId
        self.groupName = groupName
        self.fromUserId = fromUserId
        self.toUserId = toUserId
        self.message = message
        self.createdAt = createdAt
        self.status = status
    }
    
    init?(from document: DocumentSnapshot) {
        let data = document.data() ?? [:]
        guard let id = data["id"] as? String,
              let groupId = data["groupId"] as? String,
              let groupName = data["groupName"] as? String,
              let fromUserId = data["fromUserId"] as? String,
              let toUserId = data["toUserId"] as? String,
              let message = data["message"] as? String,
              let statusRaw = data["status"] as? String,
              let status = InvitationStatus(rawValue: statusRaw),
              let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() else { return nil }
        
        self.id = id
        self.groupId = groupId
        self.groupName = groupName
        self.fromUserId = fromUserId
        self.toUserId = toUserId
        self.message = message
        self.createdAt = createdAt
        self.status = status
    }
    
    init?(from document: QueryDocumentSnapshot) {
        let data = document.data()
        guard let id = data["id"] as? String,
              let groupId = data["groupId"] as? String,
              let groupName = data["groupName"] as? String,
              let fromUserId = data["fromUserId"] as? String,
              let toUserId = data["toUserId"] as? String,
              let message = data["message"] as? String,
              let statusRaw = data["status"] as? String,
              let status = InvitationStatus(rawValue: statusRaw),
              let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() else { return nil }
        
        self.id = id
        self.groupId = groupId
        self.groupName = groupName
        self.fromUserId = fromUserId
        self.toUserId = toUserId
        self.message = message
        self.createdAt = createdAt
        self.status = status
    }
    
    func toFirestoreData() -> [String: Any] {
        return [
            "id": id,
            "groupId": groupId,
            "groupName": groupName,
            "fromUserId": fromUserId,
            "toUserId": toUserId,
            "message": message,
            "status": status.rawValue,
            "createdAt": Timestamp(date: createdAt)
        ]
    }
}

enum NotificationType: String, Codable, CaseIterable {
    case progressUpdate = "progress_update"
    case challengeCreated = "challenge_created"
    case challengeCompleted = "challenge_completed"
    case memberJoined = "member_joined"
    case memberLeft = "member_left"
    case goalAchieved = "goal_achieved"
}

struct GroupNotification: Identifiable, Codable {
    let id: String
    let type: NotificationType
    let fromUserId: String
    let message: String
    let data: [String: String]
    let timestamp: Date
    var isRead: Bool
    
    func toFirestoreData() -> [String: Any] {
        return [
            "id": id,
            "type": type.rawValue,
            "fromUserId": fromUserId,
            "message": message,
            "data": data,
            "timestamp": Timestamp(date: timestamp),
            "isRead": isRead
        ]
    }
    
    init(type: NotificationType, fromUserId: String, message: String, data: [String: String] = [:]) {
        self.id = UUID().uuidString
        self.type = type
        self.fromUserId = fromUserId
        self.message = message
        self.data = data
        self.timestamp = Date()
        self.isRead = false
    }
    
    init(from document: DocumentSnapshot) {
        let data = document.data() ?? [:]
        self.id = data["id"] as? String ?? ""
        self.type = NotificationType(rawValue: data["type"] as? String ?? "") ?? .progressUpdate
        self.fromUserId = data["fromUserId"] as? String ?? ""
        self.message = data["message"] as? String ?? ""
        self.data = data["data"] as? [String: String] ?? [:]
        self.timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
        self.isRead = data["isRead"] as? Bool ?? false
    }
}
// MARK: - User Suggestion Models
struct UserSuggestion: Identifiable, Codable {
    let id: String
    var name: String
    var email: String
    var avatar: String?
    var lastSeen: Date
    var suggestionReason: String
    var groupContext: String?
    
    init(id: String, name: String, email: String, avatar: String? = nil, lastSeen: Date = Date(), suggestionReason: String = "Recently Active", groupContext: String? = nil) {
        self.id = id
        self.name = name
        self.email = email
        self.avatar = avatar
        self.lastSeen = lastSeen
        self.suggestionReason = suggestionReason
        self.groupContext = groupContext
    }
    
    init?(from document: QueryDocumentSnapshot) {
        let data = document.data()
        guard let id = data["id"] as? String,
              let name = data["name"] as? String,
              let email = data["email"] as? String else { return nil }
        
        self.id = id
        self.name = name
        self.email = email
        self.avatar = data["avatar"] as? String
        self.lastSeen = (data["lastSeen"] as? Timestamp)?.dateValue() ?? Date()
        self.suggestionReason = data["suggestionReason"] as? String ?? "Recently Active"
        self.groupContext = data["groupContext"] as? String
    }
    
    // Computed property for userId (used in CreateGroupView)
    var userId: String {
        return id
    }
}

// Make UserSuggestion hashable for Set operations
extension UserSuggestion: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: UserSuggestion, rhs: UserSuggestion) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Timeline Item Model
struct TimelineItem: Identifiable, Codable {
    let id: String
    let type: TimelineItemType
    let date: Date
    let title: String
    let description: String?
    let relatedGoalId: String?
    let relatedTaskId: String?
    let relatedEventId: String?
    let progressChange: Double?
    let keyIndicatorId: String?
    let userId: String?
    let createdAt: Date
    // Add more fields as needed for filtering and display
    init(id: String = UUID().uuidString, type: TimelineItemType, date: Date, title: String, description: String? = nil, relatedGoalId: String? = nil, relatedTaskId: String? = nil, relatedEventId: String? = nil, progressChange: Double? = nil, keyIndicatorId: String? = nil, userId: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.type = type
        self.date = date
        self.title = title
        self.description = description
        self.relatedGoalId = relatedGoalId
        self.relatedTaskId = relatedTaskId
        self.relatedEventId = relatedEventId
        self.progressChange = progressChange
        self.keyIndicatorId = keyIndicatorId
        self.userId = userId
        self.createdAt = createdAt
    }
}

enum TimelineItemType: String, Codable, CaseIterable {
    case goal = "goal"
    case task = "task"
    case event = "event"
    case note = "note"
    case progressUpdate = "progressUpdate"
    case keyIndicator = "keyIndicator"
    case other = "other"
}

// MARK: - Event Models
struct Event: Identifiable, Codable {
    let id: String
    var title: String
    var description: String
    var startDate: Date
    var endDate: Date
    var isAllDay: Bool
    var category: String
    var location: String?
    var isRecurring: Bool
    var recurrenceType: RecurrenceType
    var recurrenceInterval: Int
    var selectedDaysOfWeek: [Int]
    var endDateRecurrence: Date?
    var createdAt: Date
    var updatedAt: Date
    var linkedNoteIds: [String]
    var stickyNotes: [StickyNote]
    
    // New field for goal progress contribution
    var linkedGoalId: String?
    var progressContribution: Double?
    
    init(title: String, description: String, startDate: Date, endDate: Date, isAllDay: Bool = false, category: String = "Personal", location: String? = nil, linkedGoalId: String? = nil, progressContribution: Double? = nil) {
        self.id = UUID().uuidString
        self.title = title
        self.description = description
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = isAllDay
        self.category = category
        self.location = location
        self.isRecurring = false
        self.recurrenceType = .daily
        self.recurrenceInterval = 1
        self.selectedDaysOfWeek = []
        self.endDateRecurrence = nil
        self.createdAt = Date()
        self.updatedAt = Date()
        self.linkedNoteIds = []
        self.stickyNotes = []
        self.linkedGoalId = linkedGoalId
        self.progressContribution = progressContribution
    }
}

enum DashboardWidgetType: String, Codable, CaseIterable {
    case keyIndicators, tasks, events, goals, quote, aiSuggestions, notes, groupActivity, quickActions, weather, custom, aiAssistant

    var displayName: String {
        switch self {
        case .keyIndicators: return "Life Trackers"
        case .tasks: return "Today's Tasks"
        case .events: return "Upcoming Events"
        case .goals: return "Goal Progress"
        case .quote: return "Motivational Quote"
        case .aiSuggestions: return "AI Suggestions"
        case .notes: return "Recent Notes"
        case .groupActivity: return "Group Activity"
        case .quickActions: return "Quick Actions"
        case .weather: return "Weather/Time"
        case .custom: return "Custom Widget"
        case .aiAssistant: return "AI Assistant"
        }
    }
    var icon: String {
        switch self {
        case .keyIndicators: return "chart.bar"
        case .tasks: return "checkmark.circle"
        case .events: return "calendar"
        case .goals: return "target"
        case .quote: return "quote.bubble"
        case .aiSuggestions: return "brain.head.profile"
        case .notes: return "note.text"
        case .groupActivity: return "person.3"
        case .quickActions: return "bolt"
        case .weather: return "cloud.sun"
        case .custom: return "star"
        case .aiAssistant: return "brain.head.profile"
        }
    }
}

enum DashboardWidgetSize: String, Codable, CaseIterable {
    case standard, medium, large
    
    var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .medium: return "Medium"
        case .large: return "Large"
        }
    }
    
    var gridSize: (rows: Int, cols: Int) {
        switch self {
        case .standard: return (1, 1) // 1 widget wide, 1 widget tall
        case .medium: return (1, 2) // 2 widgets wide, 1 widget tall
        case .large: return (2, 2) // 2 widgets wide, 2 widgets tall
        }
    }
    
    var gridArea: Int {
        let size = gridSize
        return size.rows * size.cols
    }
}

enum WidgetOrientation: String, Codable, CaseIterable {
    case horizontal, vertical
    
    var displayName: String {
        switch self {
        case .horizontal: return "Horizontal"
        case .vertical: return "Vertical"
        }
    }
    
    func getGridSize(for widgetSize: DashboardWidgetSize) -> (rows: Int, cols: Int) {
        switch widgetSize {
        case .standard:
            return (1, 1)
        case .medium:
            switch self {
            case .horizontal: return (1, 2)
            case .vertical: return (2, 1)
            }
        case .large:
            return (2, 2)
        }
    }
}

// Note: DashboardWidget is defined above, this duplicate definition is removed

// MARK: - Color Extensions
extension Color {
    init?(hex: String) {
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
            return nil
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

// MARK: - Public Invite Links
struct PublicInviteLink: Identifiable, Codable {
    let id: String
    var groupId: String
    var groupName: String
    var createdBy: String
    var createdAt: Date
    var expiresAt: Date
    var inviteCode: String
    var usageCount: Int
    var isActive: Bool
    
    init(id: String = UUID().uuidString, groupId: String, groupName: String, createdBy: String, expiresAt: Date, inviteCode: String) {
        self.id = id
        self.groupId = groupId
        self.groupName = groupName
        self.createdBy = createdBy
        self.createdAt = Date()
        self.expiresAt = expiresAt
        self.inviteCode = inviteCode
        self.usageCount = 0
        self.isActive = true
    }
    
    init?(from document: QueryDocumentSnapshot) {
        let data = document.data()
        guard let id = data["id"] as? String,
              let groupId = data["groupId"] as? String,
              let groupName = data["groupName"] as? String,
              let createdBy = data["createdBy"] as? String,
              let inviteCode = data["inviteCode"] as? String else { return nil }
        
        self.id = id
        self.groupId = groupId
        self.groupName = groupName
        self.createdBy = createdBy
        self.createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        self.expiresAt = (data["expiresAt"] as? Timestamp)?.dateValue() ?? Date()
        self.inviteCode = inviteCode
        self.usageCount = data["usageCount"] as? Int ?? 0
        self.isActive = data["isActive"] as? Bool ?? true
    }
    
    func toFirestoreData() -> [String: Any] {
        return [
            "id": id,
            "groupId": groupId,
            "groupName": groupName,
            "createdBy": createdBy,
            "createdAt": Timestamp(date: createdAt),
            "expiresAt": Timestamp(date: expiresAt),
            "inviteCode": inviteCode,
            "usageCount": usageCount,
            "isActive": isActive
        ]
    }
}

struct PublicInviteLinkInfo {
    let groupId: String
    let groupName: String
    let memberCount: Int
    let inviteCode: String
    let userStatus: UserStatus
    let needsAppDownload: Bool
    
    enum UserStatus {
        case notLoggedIn
        case canJoin
        case alreadyMember
    }
}


// MARK: - Collaboration Errors
enum CollaborationError: LocalizedError {
    case groupNotFound
    case invalidInviteCode
    case alreadyMember
    case invitationAlreadySent
    case invitationNotFound
    case invalidInvitation
    case unauthorized
    case invalidInviteLink
    case inviteLinkExpired
    case userNotFound
    
    var errorDescription: String? {
        switch self {
        case .groupNotFound:
            return "Group not found"
        case .invalidInviteCode:
            return "Invalid invite code"
        case .alreadyMember:
            return "User is already a member of this group"
        case .invitationAlreadySent:
            return "Invitation has already been sent to this user"
        case .invitationNotFound:
            return "Invitation not found"
        case .invalidInvitation:
            return "Invalid invitation"
        case .unauthorized:
            return "You don't have permission to perform this action"
        case .invalidInviteLink:
            return "Invalid invite link"
        case .inviteLinkExpired:
            return "Invite link has expired"
        case .userNotFound:
            return "User not found"
        }
    }
}

// MARK: - Collaboration Errors

// Make UserSuggestion hashable for Set operations

// MARK: - Group Widget Models
struct GroupWidget: Identifiable, Codable {
    let id: String
    var type: GroupWidgetType
    var title: String
    var position: GridPosition
    var size: GroupWidgetSize
    var isVisible: Bool
    var order: Int
    
    init(id: String = UUID().uuidString, type: GroupWidgetType, title: String, position: GridPosition, size: GroupWidgetSize = .medium, isVisible: Bool = true, order: Int = 0) {
        self.id = id
        self.type = type
        self.title = title
        self.position = position
        self.size = size
        self.isVisible = isVisible
        self.order = order
    }
    
    static let defaultWidgets: [GroupWidget] = [
        GroupWidget(type: .myGroups, title: "My Groups", position: GridPosition(row: 0, col: 0), size: .large, order: 0),
        GroupWidget(type: .recentActivity, title: "Recent Activity", position: GridPosition(row: 1, col: 0), size: .medium, order: 1),
        GroupWidget(type: .invitations, title: "Invitations", position: GridPosition(row: 1, col: 1), size: .small, order: 2),
        GroupWidget(type: .groupStats, title: "Group Stats", position: GridPosition(row: 2, col: 0), size: .medium, order: 3),
        GroupWidget(type: .leaderboard, title: "Leaderboard", position: GridPosition(row: 2, col: 1), size: .medium, order: 4),
        GroupWidget(type: .challenges, title: "Active Challenges", position: GridPosition(row: 3, col: 0), size: .large, order: 5)
    ]
}

enum GroupWidgetType: String, Codable, CaseIterable {
    case myGroups = "my_groups"
    case recentActivity = "recent_activity"
    case invitations = "invitations"
    case groupStats = "group_stats"
    case leaderboard = "leaderboard"
    case challenges = "challenges"
    case analytics = "analytics"
    case recommendations = "recommendations"
    
    var icon: String {
        switch self {
        case .myGroups: return "person.3.fill"
        case .recentActivity: return "clock.fill"
        case .invitations: return "envelope.fill"
        case .groupStats: return "chart.bar.fill"
        case .leaderboard: return "trophy.fill"
        case .challenges: return "target"
        case .analytics: return "chart.line.uptrend.xyaxis"
        case .recommendations: return "lightbulb.fill"
        }
    }
    
    var color: String {
        switch self {
        case .myGroups: return "blue"
        case .recentActivity: return "green"
        case .invitations: return "orange"
        case .groupStats: return "purple"
        case .leaderboard: return "yellow"
        case .challenges: return "red"
        case .analytics: return "indigo"
        case .recommendations: return "pink"
        }
    }
}

enum GroupWidgetSize: String, Codable, CaseIterable {
    case small = "small"
    case medium = "medium"
    case large = "large"
    
    var gridSize: (width: Int, height: Int) {
        switch self {
        case .small: return (1, 1)
        case .medium: return (1, 2)
        case .large: return (2, 2)
        }
    }
}

struct GridPosition: Codable {
    var row: Int
    var col: Int
}
