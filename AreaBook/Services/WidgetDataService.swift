import Foundation
import Firebase
import FirebaseFirestore
import SwiftUI
import WidgetKit

// MARK: - Widget Types (Essential types for widget data service)

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
    public var isAllDay: Bool
    public var status: WidgetEventStatus
    public var linkedGoalId: String?
    public var progressContribution: Double?
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(id: String = UUID().uuidString, title: String, description: String? = nil, category: String = "Personal", startTime: Date, endTime: Date, isAllDay: Bool = false, status: WidgetEventStatus = .scheduled, linkedGoalId: String? = nil, progressContribution: Double? = nil, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.startTime = startTime
        self.endTime = endTime
        self.isAllDay = isAllDay
        self.status = status
        self.linkedGoalId = linkedGoalId
        self.progressContribution = progressContribution
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public enum WidgetEventStatus: String, Codable, CaseIterable {
    case scheduled = "scheduled"
    case completed = "completed"
    case cancelled = "cancelled"
    
    public var displayName: String {
        rawValue.capitalized
    }
}

// MARK: - Goal
public struct WidgetGoal: Identifiable, Codable {
    public let id: String
    public var title: String
    public var description: String?
    public var targetDate: Date?
    public var targetValue: Double
    public var currentValue: Double
    public var unit: String
    public var status: WidgetGoalStatus
    public var linkedKeyIndicatorIds: [String]
    public var createdAt: Date
    public var updatedAt: Date
    
    public var progressPercentage: Double {
        guard targetValue > 0 else { return 0 }
        return min(currentValue / targetValue, 1.0)
    }
    
    public init(id: String = UUID().uuidString, title: String, description: String? = nil, targetDate: Date? = nil, targetValue: Double, currentValue: Double = 0, unit: String = "", status: WidgetGoalStatus = .active, linkedKeyIndicatorIds: [String] = [], createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.description = description
        self.targetDate = targetDate
        self.targetValue = targetValue
        self.currentValue = currentValue
        self.unit = unit
        self.status = status
        self.linkedKeyIndicatorIds = linkedKeyIndicatorIds
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
    public var tags: [String]
    public var linkedGoalId: String?
    public var linkedTaskId: String?
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(id: String = UUID().uuidString, title: String, content: String, tags: [String] = [], linkedGoalId: String? = nil, linkedTaskId: String? = nil, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.content = content
        self.tags = tags
        self.linkedGoalId = linkedGoalId
        self.linkedTaskId = linkedTaskId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Wellness Data
public struct WidgetWellnessData: Codable {
    public var currentMood: WidgetMood
    public var meditationMinutes: Int
    public var waterGlasses: Int
    public var sleepHours: Double
    public var exerciseMinutes: Int
    public var lastUpdated: Date
    
    public init(currentMood: WidgetMood = .neutral, meditationMinutes: Int = 0, waterGlasses: Int = 0, sleepHours: Double = 0, exerciseMinutes: Int = 0, lastUpdated: Date = Date()) {
        self.currentMood = currentMood
        self.meditationMinutes = meditationMinutes
        self.waterGlasses = waterGlasses
        self.sleepHours = sleepHours
        self.exerciseMinutes = exerciseMinutes
        self.lastUpdated = lastUpdated
    }
}

public enum WidgetMood: String, Codable, CaseIterable {
    case excellent = "excellent"
    case good = "good"
    case neutral = "neutral"
    case bad = "bad"
    case terrible = "terrible"
    
    public var displayName: String {
        rawValue.capitalized
    }
    
    public var emoji: String {
        switch self {
        case .excellent: return "😄"
        case .good: return "🙂"
        case .neutral: return "😐"
        case .bad: return "😕"
        case .terrible: return "😢"
        }
    }
}





// Dependencies:
// - WidgetDataUtilities: AreaBook/Shared/WidgetDataUtilities.swift  
// - AppWidgetConfiguration: AreaBook/Shared/WidgetConfiguration.swift
// - WidgetPreferences: AreaBook/Shared/WidgetPreferences.swift

// MARK: - Widget Data Service
class WidgetDataService: ObservableObject {
    static let shared = WidgetDataService()
    
    private let db = Firestore.firestore()
    
    // MARK: - Sync Coordination and Performance
    private let syncQueue = DispatchQueue(label: "widget.sync", qos: .utility)
    private var syncTimer: Timer?
    private let syncDebounceInterval: TimeInterval = 2.0 // Debounce for 2 seconds
    private var isCurrentlySyncing = false
    
    private enum WidgetDataType: CaseIterable {
        case keyIndicators, tasks, events, goals, notes, wellness, authentication
    }
    
    private init() {}
    
    // MARK: - App Group Validation
    private func validateAppGroupSetup() -> Bool {
        let isValid = WidgetDataUtilities.validateAppGroupConfiguration()
        
        if !isValid {
            print("🚨 WidgetDataService: CRITICAL ERROR - App Group not configured!")
            print("🚨 WidgetDataService: Widgets will not work until 'group.com.areabook.ios' is properly set up")
            
            // Show alert to user about app group issue
            DispatchQueue.main.async {
                // TODO: Show user-facing error about widget configuration
                NotificationCenter.default.post(
                    name: NSNotification.Name("WidgetAppGroupConfigurationError"),
                    object: nil,
                    userInfo: ["error": "App Group not configured for widgets"]
                )
            }
        }
        
        return isValid
    }
    
    // MARK: - Authentication Validation
    private func validateAuthentication() -> (isValid: Bool, userId: String?) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("❌ WidgetDataService: No authenticated user - clearing widget data")
            WidgetDataUtilities.clearAllWidgetData()
            WidgetCenter.shared.reloadAllTimelines()
            return (false, nil)
        }
        
        // Check widget auth state
        let (widgetUserId, isWidgetAuthenticated, _) = WidgetDataUtilities.loadAuthenticationState()
        
        if widgetUserId != currentUserId || !isWidgetAuthenticated {
            print("⚠️ WidgetDataService: Auth state mismatch - Main: \(currentUserId), Widget: \(widgetUserId ?? "none"), Valid: \(isWidgetAuthenticated)")
            
            // Update widget auth state
            let _ = WidgetDataUtilities.saveAuthenticationState(userId: currentUserId, isAuthenticated: true)
            
            // Clear old data if user changed
            if widgetUserId != nil && widgetUserId != currentUserId {
                print("🔄 WidgetDataService: User changed, clearing old widget data")
                WidgetDataUtilities.clearAllWidgetData()
            }
        }
        
        return (true, currentUserId)
    }
    
    // MARK: - Smart Sync Coordinator
    private func requestSync(_ type: WidgetDataType) {
        // This method is now deprecated, use syncDataForWidgets()
        print("⚠️ WidgetDataService: requestSync(_:) is deprecated. Use syncDataForWidgets() instead.")
        syncDataForWidgets()
    }
    
    // MARK: - Main sync method with proper debouncing and background processing
    func syncDataForWidgets() {
        // Cancel any existing sync timer
        syncTimer?.invalidate()
        
        // Debounce the sync to prevent excessive calls
        syncTimer = Timer.scheduledTimer(withTimeInterval: syncDebounceInterval, repeats: false) { [weak self] _ in
            self?.performActualSync()
        }
    }
    
    private func performActualSync() {
        guard !isCurrentlySyncing else {
            print("🔄 WidgetDataService: Sync already in progress, skipping")
            return
        }
        
        isCurrentlySyncing = true
        
        // Perform sync on background queue
        syncQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Validate setup and authentication
            guard self.validateAppGroupSetup() else {
                print("❌ WidgetDataService: App group validation failed")
                self.isCurrentlySyncing = false
                return
            }
            
            let (isValid, userId) = self.validateAuthentication()
            guard isValid, let userId = userId else {
                print("❌ WidgetDataService: Authentication validation failed")
                self.isCurrentlySyncing = false
                return
            }
            
            print("🔄 WidgetDataService: Starting comprehensive widget data sync for user: \(userId)")
            
            // Perform all sync operations
            self.syncKeyIndicators(userId: userId)
            self.syncTodaysTasks(userId: userId)
            self.syncTodaysEvents(userId: userId)
            self.syncGoals(userId: userId)
            self.syncRecentNotes(userId: userId)
            self.syncWellnessData(userId: userId)
            
            // Reload widget timelines
            DispatchQueue.main.async {
                WidgetCenter.shared.reloadAllTimelines()
                print("✅ WidgetDataService: Widget timelines reloaded")
            }
            
            self.isCurrentlySyncing = false
            print("✅ WidgetDataService: Comprehensive sync completed")
        }
    }
    
    // MARK: - Individual Data Sync Methods
    
    private func syncKeyIndicators(userId: String) {
        print("🔄 WidgetDataService: Syncing key indicators...")
        
        db.collection("users").document(userId).collection("keyIndicators")
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    print("❌ WidgetDataService: Failed to fetch key indicators: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("⚠️ WidgetDataService: No key indicators found")
                    return
                }
                
                let keyIndicators = documents.compactMap { document -> WidgetKeyIndicator? in
                    do {
                        let data = document.data()
                        let jsonData = try JSONSerialization.data(withJSONObject: data)
                        return try JSONDecoder().decode(WidgetKeyIndicator.self, from: jsonData)
                    } catch {
                        print("❌ WidgetDataService: Failed to decode key indicator \(document.documentID): \(error)")
                        return nil
                    }
                }
                
                let saveResult = WidgetDataUtilities.saveData(keyIndicators, forKey: WidgetDataKeys.keyIndicators)
                print("📊 WidgetDataService: Key indicators sync result: \(saveResult)")
            }
    }
    
    private func syncTodaysTasks(userId: String) {
        print("🔄 WidgetDataService: Syncing today's tasks...")
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()
        
        db.collection("users").document(userId).collection("tasks")
            .whereField("dueDate", isGreaterThanOrEqualTo: startOfDay)
            .whereField("dueDate", isLessThan: endOfDay)
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    print("❌ WidgetDataService: Failed to fetch tasks: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("⚠️ WidgetDataService: No tasks found for today")
                    return
                }
                
                let tasks = documents.compactMap { document -> WidgetAppTask? in
                    do {
                        let data = document.data()
                        let jsonData = try JSONSerialization.data(withJSONObject: data)
                        return try JSONDecoder().decode(WidgetAppTask.self, from: jsonData)
                    } catch {
                        print("❌ WidgetDataService: Failed to decode task \(document.documentID): \(error)")
                        return nil
                    }
                }
                
                let saveResult = WidgetDataUtilities.saveData(tasks, forKey: WidgetDataKeys.todaysTasks)
                print("📊 WidgetDataService: Tasks sync result: \(saveResult)")
            }
    }
    
    private func syncTodaysEvents(userId: String) {
        print("🔄 WidgetDataService: Syncing today's events...")
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()
        
        db.collection("users").document(userId).collection("events")
            .whereField("startTime", isGreaterThanOrEqualTo: startOfDay)
            .whereField("startTime", isLessThan: endOfDay)
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    print("❌ WidgetDataService: Failed to fetch events: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("⚠️ WidgetDataService: No events found for today")
                    return
                }
                
                let events = documents.compactMap { document -> WidgetCalendarEvent? in
                    do {
                        let data = document.data()
                        let jsonData = try JSONSerialization.data(withJSONObject: data)
                        return try JSONDecoder().decode(WidgetCalendarEvent.self, from: jsonData)
                    } catch {
                        print("❌ WidgetDataService: Failed to decode event \(document.documentID): \(error)")
                        return nil
                    }
                }
                
                let saveResult = WidgetDataUtilities.saveData(events, forKey: WidgetDataKeys.todaysEvents)
                print("📊 WidgetDataService: Events sync result: \(saveResult)")
            }
    }
    
    private func syncGoals(userId: String) {
        print("🔄 WidgetDataService: Syncing goals...")
        
        db.collection("users").document(userId).collection("goals")
            .whereField("status", isEqualTo: "active")
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    print("❌ WidgetDataService: Failed to fetch goals: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("⚠️ WidgetDataService: No active goals found")
                    return
                }
                
                let goals = documents.compactMap { document -> WidgetGoal? in
                    do {
                        let data = document.data()
                        let jsonData = try JSONSerialization.data(withJSONObject: data)
                        return try JSONDecoder().decode(WidgetGoal.self, from: jsonData)
                    } catch {
                        print("❌ WidgetDataService: Failed to decode goal \(document.documentID): \(error)")
                        return nil
                    }
                }
                
                let saveResult = WidgetDataUtilities.saveData(goals, forKey: WidgetDataKeys.goals)
                print("📊 WidgetDataService: Goals sync result: \(saveResult)")
            }
    }
    
    private func syncRecentNotes(userId: String) {
        print("🔄 WidgetDataService: Syncing recent notes...")
        
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        db.collection("users").document(userId).collection("notes")
            .whereField("createdAt", isGreaterThan: oneWeekAgo)
            .order(by: "createdAt", descending: true)
            .limit(to: 10)
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    print("❌ WidgetDataService: Failed to fetch notes: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("⚠️ WidgetDataService: No recent notes found")
                    return
                }
                
                let notes = documents.compactMap { document -> WidgetNote? in
                    do {
                        let data = document.data()
                        let jsonData = try JSONSerialization.data(withJSONObject: data)
                        return try JSONDecoder().decode(WidgetNote.self, from: jsonData)
                    } catch {
                        print("❌ WidgetDataService: Failed to decode note \(document.documentID): \(error)")
                        return nil
                    }
                }
                
                let saveResult = WidgetDataUtilities.saveData(notes, forKey: WidgetDataKeys.recentNotes)
                print("📊 WidgetDataService: Notes sync result: \(saveResult)")
            }
    }
    
    private func syncWellnessData(userId: String) {
        print("🔄 WidgetDataService: Syncing wellness data...")
        
        db.collection("users").document(userId).collection("wellness")
            .order(by: "lastUpdated", descending: true)
            .limit(to: 1)
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    print("❌ WidgetDataService: Failed to fetch wellness data: \(error)")
                    return
                }
                
                guard let document = snapshot?.documents.first else {
                    print("⚠️ WidgetDataService: No wellness data found")
                    return
                }
                
                do {
                    let data = document.data()
                    let jsonData = try JSONSerialization.data(withJSONObject: data)
                    let wellnessData = try JSONDecoder().decode(WidgetWellnessData.self, from: jsonData)
                    
                    let saveResult = WidgetDataUtilities.saveData(wellnessData, forKey: WidgetDataKeys.wellnessData)
                    print("📊 WidgetDataService: Wellness data sync result: \(saveResult)")
                } catch {
                    print("❌ WidgetDataService: Failed to decode wellness data: \(error)")
                }
            }
    }
    
    // MARK: - Real-time Updates
    
    func startRealtimeUpdates() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ WidgetDataService: Cannot start real-time updates - no authenticated user")
            return
        }
        
        print("🔄 WidgetDataService: Starting real-time updates for user: \(userId)")
        
        // Listen for key indicator changes
        db.collection("users").document(userId).collection("keyIndicators")
            .addSnapshotListener { [weak self] _, _ in
                self?.syncKeyIndicators(userId: userId)
            }
        
        // Listen for task changes
        db.collection("users").document(userId).collection("tasks")
            .addSnapshotListener { [weak self] _, _ in
                self?.syncTodaysTasks(userId: userId)
            }
        
        // Listen for event changes
        db.collection("users").document(userId).collection("events")
            .addSnapshotListener { [weak self] _, _ in
                self?.syncTodaysEvents(userId: userId)
            }
        
        // Listen for goal changes
        db.collection("users").document(userId).collection("goals")
            .addSnapshotListener { [weak self] _, _ in
                self?.syncGoals(userId: userId)
            }
        
        // Listen for note changes
        db.collection("users").document(userId).collection("notes")
            .addSnapshotListener { [weak self] _, _ in
                self?.syncRecentNotes(userId: userId)
            }
        
        // Listen for wellness changes
        db.collection("users").document(userId).collection("wellness")
            .addSnapshotListener { [weak self] _, _ in
                self?.syncWellnessData(userId: userId)
            }
    }
    
    /// Stop real-time updates
    func stopRealtimeUpdates() {
        // Remove all listeners
        db.clearPersistence { error in
            if let error = error {
                print("Error clearing persistence: \(error)")
            }
        }
    }
    
    // MARK: - Manual Refresh
    
    /// Manually refresh all widget data
    func refreshWidgetData() {
        syncDataForWidgets()
    }
    
    // MARK: - Widget Configuration
    
    /// Get widget configuration for the current user
    func getWidgetConfiguration() -> AppWidgetConfiguration {
        let enabledFeatures = WidgetDataUtilities.loadData([String].self, forKey: WidgetDataKeys.enabledFeatures) ?? []
        
        return AppWidgetConfiguration(
            enabledFeatures: enabledFeatures,
            lastSync: Date(),
            widgetPreferences: getWidgetPreferences()
        )
    }
    
    /// Get user's widget preferences
    private func getWidgetPreferences() -> WidgetPreferences {
        return WidgetDataUtilities.loadData(WidgetPreferences.self, forKey: WidgetDataKeys.widgetPreferences) ?? WidgetPreferences()
    }
    
    /// Save widget preferences
    func saveWidgetPreferences(_ preferences: WidgetPreferences) {
        WidgetDataUtilities.saveData(preferences, forKey: WidgetDataKeys.widgetPreferences)
    }
    
    // MARK: - Testing and Development
    
    func createSampleDataForTesting() {
        print("🧪 WidgetDataService: Creating sample data for testing...")
        
        // Sample Key Indicators
        let sampleKeyIndicators = [
            WidgetKeyIndicator(
                id: "test-ki-1",
                name: "Exercise",
                weeklyTarget: 5,
                unit: "workouts",
                color: "#3B82F6",
                progress: 3,
                createdAt: Date(),
                updatedAt: Date()
            ),
            WidgetKeyIndicator(
                id: "test-ki-2",
                name: "Reading",
                weeklyTarget: 7,
                unit: "chapters",
                color: "#10B981",
                progress: 4,
                createdAt: Date(),
                updatedAt: Date()
            )
        ]
        
        // Sample Tasks
        let sampleTasks = [
            WidgetAppTask(
                id: "test-task-1",
                title: "Review project proposal",
                status: .pending,
                dueDate: Date(),
                createdAt: Date(),
                updatedAt: Date()
            ),
            WidgetAppTask(
                id: "test-task-2",
                title: "Call dentist",
                status: .completed,
                completedAt: Date(),
                createdAt: Date().addingTimeInterval(-3600),
                updatedAt: Date()
            )
        ]
        
        // Sample Events
        let sampleEvents = [
            WidgetCalendarEvent(
                id: "test-event-1",
                title: "Team Meeting",
                startTime: Date().addingTimeInterval(3600),
                endTime: Date().addingTimeInterval(5400),
                status: WidgetEventStatus.scheduled,
                createdAt: Date(),
                updatedAt: Date()
            )
        ]
        
        // Sample Goals
        let sampleGoals = [
            WidgetGoal(
                id: "test-goal-1",
                title: "Learn SwiftUI",
                targetDate: Date().addingTimeInterval(30 * 24 * 60 * 60),
                targetValue: 100,
                currentValue: 65,
                unit: "percent",
                status: .active,
                createdAt: Date(),
                updatedAt: Date()
            )
        ]
        
        // Sample Notes
        let sampleNotes = [
            WidgetNote(
                id: "test-note-1",
                title: "Meeting Notes",
                content: "Important discussion about project timeline",
                createdAt: Date(),
                updatedAt: Date()
            )
        ]
        
        // Sample Wellness Data
        let sampleWellness = WidgetWellnessData(
            currentMood: .good,
            meditationMinutes: 15,
            waterGlasses: 6,
            sleepHours: 7.5
        )
        
        // Save all sample data
        WidgetDataUtilities.saveData(sampleKeyIndicators, forKey: WidgetDataKeys.keyIndicators)
        WidgetDataUtilities.saveData(sampleTasks, forKey: WidgetDataKeys.todaysTasks)
        WidgetDataUtilities.saveData(sampleEvents, forKey: WidgetDataKeys.todaysEvents)
        WidgetDataUtilities.saveData(sampleGoals, forKey: WidgetDataKeys.goals)
        WidgetDataUtilities.saveData(sampleNotes, forKey: WidgetDataKeys.recentNotes)
        WidgetDataUtilities.saveData(sampleWellness, forKey: WidgetDataKeys.wellnessData)
        
        // Reload widget timelines
        WidgetCenter.shared.reloadAllTimelines()
        
        print("✅ WidgetDataService: Sample data created and widget timelines reloaded")
    }
}

 