//
//  AreaBookWidget.swift
//  AreaBookWidget
//
//  Created by Jona Turagavou on 7/17/25.
//

import WidgetKit
import SwiftUI

// MARK: - Widget Data Sync Status
public enum WidgetSyncStatus: Equatable {
    case success
    case appGroupNotConfigured
    case encodingError(Error)
    case decodingError(Error)
    case noData
    case authenticationMismatch
    
    public static func == (lhs: WidgetSyncStatus, rhs: WidgetSyncStatus) -> Bool {
        switch (lhs, rhs) {
        case (.success, .success),
             (.appGroupNotConfigured, .appGroupNotConfigured),
             (.noData, .noData),
             (.authenticationMismatch, .authenticationMismatch):
            return true
        case (.encodingError(_), .encodingError(_)),
             (.decodingError(_), .decodingError(_)):
            return true
        default:
            return false
        }
    }
}

// MARK: - Widget Types (Essential types for widget extension)

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

// MARK: - Widget Data Utilities
public struct WidgetDataUtilities {
    // Use shared UserDefaults for widget data synchronization
    private static let sharedDefaults = UserDefaults(suiteName: "group.com.areabook.ios")
    
    public static func saveData<T: Codable>(_ data: T, forKey key: String) {
        guard let sharedDefaults = sharedDefaults else {
            print("❌ WidgetDataUtilities: Shared UserDefaults not available - app group 'group.com.areabook.ios' might not be configured")
            return
        }
        
        do {
            let encoded = try JSONEncoder().encode(data)
            sharedDefaults.set(encoded, forKey: key)
            sharedDefaults.synchronize()
            print("✅ WidgetDataUtilities: Successfully saved data for key '\(key)' - size: \(encoded.count) bytes")
        } catch {
            print("❌ WidgetDataUtilities: Failed to save data for key \(key): \(error)")
        }
    }
    
    public static func loadData<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let sharedDefaults = sharedDefaults else {
            print("❌ WidgetDataUtilities: Shared UserDefaults not available - app group 'group.com.areabook.ios' might not be configured")
            return nil
        }
        
        guard let data = sharedDefaults.data(forKey: key) else {
            print("⚠️ WidgetDataUtilities: No data found for key '\(key)'")
            return nil
        }
        
        do {
            let decoded = try JSONDecoder().decode(type, from: data)
            print("✅ WidgetDataUtilities: Successfully loaded data for key '\(key)' - size: \(data.count) bytes")
            return decoded
        } catch {
            print("❌ WidgetDataUtilities: Failed to load data for key \(key): \(error)")
            return nil
        }
    }
    
    public static func clearData(forKey key: String) {
        sharedDefaults?.removeObject(forKey: key)
        sharedDefaults?.synchronize()
        print("🗑️ WidgetDataUtilities: Cleared data for key '\(key)'")
    }
    
    public static func clearAllWidgetData() {
        for key in WidgetDataKeys.allKeys {
            clearData(forKey: key)
        }
        print("🗑️ WidgetDataUtilities: Cleared all widget data")
    }
    
    public static func validateAppGroupConfiguration() -> Bool {
        guard let _ = sharedDefaults else {
            print("❌ WidgetDataUtilities: App group 'group.com.areabook.ios' not configured.")
            return false
        }
        print("✅ WidgetDataUtilities: App group 'group.com.areabook.ios' is configured.")
        return true
    }
    
    public static func loadAuthenticationState() -> (String?, Bool, Date?) {
        let userId = sharedDefaults?.string(forKey: "currentUserId")
        let lastSync = sharedDefaults?.object(forKey: "lastSyncTime") as? Date
        
        let isAuthenticated = userId != nil && !userId!.isEmpty
        return (userId, isAuthenticated, lastSync)
    }
    
    // Enhanced load method with status
    public static func loadDataWithStatus<T: Codable>(_ type: T.Type, forKey key: String) -> (data: T?, status: WidgetSyncStatus) {
        guard let sharedDefaults = sharedDefaults else {
            return (nil, .appGroupNotConfigured)
        }
        
        guard let data = sharedDefaults.data(forKey: key) else {
            return (nil, .noData)
        }
        
        do {
            let decoded = try JSONDecoder().decode(type, from: data)
            return (decoded, .success)
        } catch {
            print("❌ WidgetDataUtilities: Failed to decode data for key \(key): \(error)")
            return (nil, .decodingError(error))
        }
    }
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

// MARK: - Widget Entry
struct AreaBookWidgetEntry: TimelineEntry {
    let date: Date
    let keyIndicators: [WidgetKeyIndicator]
    let todaysTasks: [WidgetAppTask]
    let todaysEvents: [WidgetCalendarEvent]
    let goals: [WidgetGoal]
    let notes: [WidgetNote]
    let wellnessData: WidgetWellnessData
    
    static let placeholder = AreaBookWidgetEntry(
        date: Date(),
        keyIndicators: [
            WidgetKeyIndicator(
                id: "1",
                name: "Scripture Study",
                weeklyTarget: 7,
                unit: "sessions",
                color: "#3B82F6",
                progress: 5.0,
                createdAt: Date(),
                updatedAt: Date()
            ),
            WidgetKeyIndicator(
                id: "2",
                name: "Prayer",
                weeklyTarget: 14,
                unit: "times",
                color: "#10B981",
                progress: 6.0,
                createdAt: Date(),
                updatedAt: Date()
            )
        ],
        todaysTasks: [
            WidgetAppTask(
                id: "1",
                title: "Complete morning study",
                description: "Daily scripture reading",
                priority: .high,
                status: .pending,
                dueDate: Date(),
                createdAt: Date(),
                updatedAt: Date()
            ),
            WidgetAppTask(
                id: "2",
                title: "Review goals",
                description: "Weekly goal review",
                priority: .medium,
                status: .completed,
                dueDate: Date(),
                completedAt: Date(),
                createdAt: Date(),
                updatedAt: Date()
            )
        ],
        todaysEvents: [
            WidgetCalendarEvent(
                id: "1",
                title: "Sunday School",
                description: "Weekly class",
                category: "Church",
                startTime: Date(),
                endTime: Calendar.current.date(byAdding: .hour, value: 1, to: Date())!,
                status: .scheduled,
                createdAt: Date(),
                updatedAt: Date()
            )
        ],
        goals: [
            WidgetGoal(
                id: "1",
                title: "Read 12 books this year",
                description: "Personal development",
                targetDate: Calendar.current.date(byAdding: .month, value: 6, to: Date())!,
                targetValue: 12.0,
                currentValue: 9.0,
                unit: "books",
                status: .active,
                keyIndicatorIds: [],
                createdAt: Date(),
                updatedAt: Date()
            )
        ],
        notes: [
            WidgetNote(
                id: "1",
                title: "Project ideas",
                content: "New app concepts...",
                linkedGoalIds: [],
                createdAt: Date(),
                updatedAt: Date()
            )
        ],
        wellnessData: WidgetWellnessData(
            currentMood: .good,
            meditationMinutes: 15,
            waterGlasses: 6,
            sleepHours: 7.5
        )
    )
}

// MARK: - Widget Timeline Provider
struct AreaBookWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> AreaBookWidgetEntry {
        AreaBookWidgetEntry.placeholder
    }
    
    func getSnapshot(in context: Context, completion: @escaping (AreaBookWidgetEntry) -> ()) {
        if context.isPreview {
            completion(AreaBookWidgetEntry.placeholder)
        } else {
            loadWidgetData { entry in
                completion(entry)
            }
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        loadWidgetData { entry in
            // Update every 5 minutes for more real-time experience
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            print("🔄 WidgetProvider: Timeline created with next update at \(nextUpdate)")
            completion(timeline)
        }
    }
    
    private func loadWidgetData(completion: @escaping (AreaBookWidgetEntry) -> Void) {
        print("🔄 Widget: Starting data load...")
        
        // FIXED: Validate app group access first
        guard WidgetDataUtilities.validateAppGroupConfiguration() else {
            print("❌ Widget: CRITICAL - App group not configured, showing placeholder")
            completion(AreaBookWidgetEntry.placeholder)
            return
        }
        
        // FIXED: Check authentication state
        let (widgetUserId, isAuthenticated, lastUpdate) = WidgetDataUtilities.loadAuthenticationState()
        
        guard isAuthenticated, let userId = widgetUserId, !userId.isEmpty else {
            print("❌ Widget: User not authenticated or no user ID, showing placeholder")
            print("❌ Widget: Auth state - userId: \(widgetUserId ?? "none"), authenticated: \(isAuthenticated)")
            completion(AreaBookWidgetEntry.placeholder)
            return
        }
        
        print("✅ Widget: User authenticated (ID: \(userId)), loading data...")
        
        // Check if auth state is recent (within last 24 hours)
        if let lastUpdate = lastUpdate, Date().timeIntervalSince(lastUpdate) > 24 * 60 * 60 {
            print("⚠️ Widget: Authentication state is stale (last update: \(lastUpdate))")
        }
        
        // Load data using enhanced utilities with error handling
        let keyIndicatorsResult = WidgetDataUtilities.loadDataWithStatus([WidgetKeyIndicator].self, forKey: WidgetDataKeys.keyIndicators)
        let tasksResult = WidgetDataUtilities.loadDataWithStatus([WidgetAppTask].self, forKey: WidgetDataKeys.todaysTasks)
        let eventsResult = WidgetDataUtilities.loadDataWithStatus([WidgetCalendarEvent].self, forKey: WidgetDataKeys.todaysEvents)
        let goalsResult = WidgetDataUtilities.loadDataWithStatus([WidgetGoal].self, forKey: WidgetDataKeys.goals)
        let notesResult = WidgetDataUtilities.loadDataWithStatus([WidgetNote].self, forKey: WidgetDataKeys.recentNotes)
        let wellnessResult = WidgetDataUtilities.loadDataWithStatus(WidgetWellnessData.self, forKey: WidgetDataKeys.wellnessData)
        
        // Extract data and status
        let (keyIndicators, kiStatus) = keyIndicatorsResult
        let (tasks, tasksStatus) = tasksResult
        let (events, eventsStatus) = eventsResult
        let (goals, goalsStatus) = goalsResult
        let (notes, notesStatus) = notesResult
        let (wellnessData, wellnessStatus) = wellnessResult
        
        // Log any data loading issues
        let statuses = [
            ("keyIndicators", kiStatus),
            ("tasks", tasksStatus),
            ("events", eventsStatus),
            ("goals", goalsStatus),
            ("notes", notesStatus),
            ("wellness", wellnessStatus)
        ]
        
        var hasErrors = false
        for (name, status) in statuses {
            switch status {
            case .success:
                continue
            case .appGroupNotConfigured:
                print("❌ Widget: App group not configured for \(name)")
                hasErrors = true
            case .noData:
                print("⚠️ Widget: No data available for \(name)")
            case .decodingError(let error):
                print("❌ Widget: Data corruption in \(name): \(error)")
                hasErrors = true
            case .encodingError(let error):
                print("❌ Widget: Encoding error for \(name): \(error)")
                hasErrors = true
            case .authenticationMismatch:
                print("❌ Widget: Authentication mismatch for \(name)")
                hasErrors = true
            }
        }
        
        // If critical errors, show placeholder
        if hasErrors {
            print("❌ Widget: Critical errors detected, showing placeholder")
            completion(AreaBookWidgetEntry.placeholder)
            return
        }
        
        print("📊 Widget: Loaded data counts:")
        print("   - Key Indicators: \(keyIndicators?.count ?? 0)")
        print("   - Tasks: \(tasks?.count ?? 0)")
        print("   - Events: \(events?.count ?? 0)")
        print("   - Goals: \(goals?.count ?? 0)")
        print("   - Notes: \(notes?.count ?? 0)")
        print("   - Wellness: \(wellnessData != nil ? "Available" : "Not Available")")
        
        let entry = AreaBookWidgetEntry(
            date: Date(),
            keyIndicators: keyIndicators ?? [],
            todaysTasks: tasks ?? [],
            todaysEvents: events ?? [],
            goals: goals ?? [],
            notes: notes ?? [],
            wellnessData: wellnessData ?? WidgetWellnessData()
        )
        
        print("✅ Widget: Data load completed successfully")
        completion(entry)
    }
}

// MARK: - Widget Views
struct AreaBookWidgetEntryView: View {
    var entry: AreaBookWidgetProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        case .systemExtraLarge:
            if #available(iOS 17.0, *) {
                ExtraLargeWidgetView(entry: entry)
            } else {
                LargeWidgetView(entry: entry)
            }
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

struct SmallWidgetView: View {
    let entry: AreaBookWidgetEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Header
            HStack {
                Image(systemName: "book.fill")
                    .foregroundColor(.blue)
                Text("AreaBook")
                    .font(.caption.bold())
                Spacer()
            }
            
            Spacer()
            
            // Key Indicators (Top 2)
            ForEach(Array(entry.keyIndicators.prefix(2)), id: \.id) { indicator in
                HStack {
                    Circle()
                        .fill(progressColor(for: indicator.progressPercentage))
                        .frame(width: 6, height: 6)
                    Text(indicator.name)
                        .font(.caption2)
                        .lineLimit(1)
                    Spacer()
                    Text("\(Int(indicator.progressPercentage * 100))%")
                        .font(.caption2.bold())
                }
            }
            
            Spacer()
            
            // Quick Stats
            HStack {
                VStack {
                    Text("\(entry.todaysTasks.filter { $0.status != .completed }.count)")
                        .font(.caption.bold())
                    Text("Tasks")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack {
                    Text("\(entry.todaysEvents.count)")
                        .font(.caption.bold())
                    Text("Events")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
    
    private func progressColor(for percentage: Double) -> Color {
        switch percentage {
        case 0.8...:
            return .green
        case 0.5...:
            return .orange
        default:
            return .red
        }
    }
}

struct MediumWidgetView: View {
    let entry: AreaBookWidgetEntry
    
    var body: some View {
        HStack(spacing: 0) {
            // Left side - Key Indicators (takes 60% of width)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "target")
                        .foregroundColor(.blue)
                        .font(.caption)
                    Text("Progress")
                        .font(.caption.bold())
                        .foregroundColor(.primary)
                    Spacer()
                }
                
                ForEach(Array(entry.keyIndicators.prefix(2)), id: \.id) { indicator in
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text(indicator.name)
                                .font(.caption2)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            Spacer()
                            Text("\(Int(indicator.progressPercentage * 100))%")
                                .font(.caption2.bold())
                                .foregroundColor(progressColor(for: indicator.progressPercentage))
                        }
                        
                        ProgressView(value: indicator.progressPercentage)
                            .progressViewStyle(LinearProgressViewStyle(tint: progressColor(for: indicator.progressPercentage)))
                            .scaleEffect(y: 0.7)
                    }
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.leading, 12)
            .padding(.trailing, 8)
            
            // Divider
            Rectangle()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 1)
                .padding(.vertical, 8)
            
            // Right side - Today's Summary (takes 40% of width)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text("Today")
                        .font(.caption.bold())
                        .foregroundColor(.primary)
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    // Tasks summary
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                            .font(.caption2)
                        Text("\(entry.todaysTasks.filter { $0.status != .completed }.count)")
                            .font(.caption.bold())
                        Text("tasks left")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    // Events summary
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .foregroundColor(.green)
                            .font(.caption2)
                        Text("\(entry.todaysEvents.count)")
                            .font(.caption.bold())
                        Text("events")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    // Wellness indicator
                    HStack(spacing: 4) {
                        Image(systemName: "drop.fill")
                            .foregroundColor(.cyan)
                            .font(.caption2)
                        Text("\(entry.wellnessData.waterGlasses)")
                            .font(.caption.bold())
                        Text("glasses")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.leading, 8)
            .padding(.trailing, 12)
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    
    private func progressColor(for percentage: Double) -> Color {
        switch percentage {
        case 0.8...:
            return .green
        case 0.5...:
            return .orange
        default:
            return .red
        }
    }
}

struct LargeWidgetView: View {
    let entry: AreaBookWidgetEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "book.fill")
                    .foregroundColor(.blue)
                Text("AreaBook Dashboard")
                    .font(.headline.bold())
                Spacer()
                Text(entry.date, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Key Indicators Section
            VStack(alignment: .leading, spacing: 6) {
                Text("Key Indicators")
                    .font(.subheadline.bold())
                
                ForEach(Array(entry.keyIndicators.prefix(4)), id: \.id) { indicator in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(indicator.name)
                                .font(.caption)
                            ProgressView(value: indicator.progressPercentage)
                                .progressViewStyle(LinearProgressViewStyle(tint: progressColor(for: indicator.progressPercentage)))
                        }
                        
                        Spacer()
                        
                        Text("\(Int(indicator.progress))/\(indicator.weeklyTarget)")
                            .font(.caption.bold())
                    }
                }
            }
            
            Divider()
            
            // Today's Summary
            HStack(spacing: 20) {
                // Tasks
                VStack(alignment: .leading) {
                    Text("Tasks")
                        .font(.caption.bold())
                    Text("\(entry.todaysTasks.filter { $0.status != .completed }.count) pending")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // Events
                VStack(alignment: .leading) {
                    Text("Events")
                        .font(.caption.bold())
                    Text("\(entry.todaysEvents.count) today")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // Goals
                VStack(alignment: .leading) {
                    Text("Goals")
                        .font(.caption.bold())
                    Text("\(entry.goals.count) active")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Wellness Summary
            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("Mood")
                        .font(.caption.bold())
                    Text(entry.wellnessData.currentMood.emoji)
                        .font(.title2)
                }
                
                VStack(alignment: .leading) {
                    Text("Water")
                        .font(.caption.bold())
                    Text("\(entry.wellnessData.waterGlasses) glasses")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading) {
                    Text("Sleep")
                        .font(.caption.bold())
                    Text("\(String(format: "%.1f", entry.wellnessData.sleepHours))h")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
    
    private func progressColor(for percentage: Double) -> Color {
        switch percentage {
        case 0.8...:
            return .green
        case 0.5...:
            return .orange
        default:
            return .red
        }
    }
}

@available(iOS 17.0, *)
struct ExtraLargeWidgetView: View {
    let entry: AreaBookWidgetEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with app branding
            HStack {
                Image(systemName: "book.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
                Text("AreaBook Dashboard")
                    .font(.title2.bold())
                Spacer()
                VStack(alignment: .trailing) {
                    Text(entry.date, style: .date)
                        .font(.caption)
                    Text(entry.date, style: .time)
                        .font(.caption.bold())
                }
                .foregroundColor(.secondary)
            }
            
            // Two-column layout for maximum space utilization
            HStack(alignment: .top, spacing: 20) {
                // Left column
                VStack(alignment: .leading, spacing: 12) {
                    // Key Indicators Section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "target")
                                .foregroundColor(.blue)
                            Text("Key Indicators")
                                .font(.subheadline.bold())
                        }
                        
                        ForEach(Array(entry.keyIndicators.prefix(4)), id: \.id) { indicator in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(indicator.name)
                                        .font(.caption)
                                        .lineLimit(1)
                                    Spacer()
                                    Text("\(Int(indicator.progressPercentage * 100))%")
                                        .font(.caption.bold())
                                        .foregroundColor(progressColor(for: indicator.progressPercentage))
                                }
                                
                                ProgressView(value: indicator.progressPercentage)
                                    .progressViewStyle(LinearProgressViewStyle(tint: progressColor(for: indicator.progressPercentage)))
                            }
                        }
                    }
                    
                    // Tasks Summary
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "checkmark.circle")
                                .foregroundColor(.blue)
                            Text("Today's Tasks")
                                .font(.subheadline.bold())
                        }
                        
                        ForEach(Array(entry.todaysTasks.prefix(3)), id: \.id) { task in
                            HStack {
                                Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(task.status == .completed ? .green : .gray)
                                Text(task.title)
                                    .font(.caption)
                                    .strikethrough(task.status == .completed)
                                    .lineLimit(1)
                                Spacer()
                            }
                        }
                    }
                }
                
                // Right column
                VStack(alignment: .leading, spacing: 12) {
                    // Events Section
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.green)
                            Text("Today's Events")
                                .font(.subheadline.bold())
                        }
                        
                        ForEach(Array(entry.todaysEvents.prefix(3)), id: \.id) { event in
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(.orange)
                                    .font(.caption2)
                                VStack(alignment: .leading) {
                                    Text(event.title)
                                        .font(.caption)
                                        .lineLimit(1)
                                    Text(event.startTime, style: .time)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                        }
                    }
                    
                    // Wellness Dashboard
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                            Text("Wellness")
                                .font(.subheadline.bold())
                        }
                        
                        HStack(spacing: 16) {
                            VStack {
                                Text(entry.wellnessData.currentMood.emoji)
                                    .font(.title2)
                                Text("Mood")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack {
                                Text("\(entry.wellnessData.waterGlasses)")
                                    .font(.title3.bold())
                                    .foregroundColor(.cyan)
                                Text("Glasses")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack {
                                Text("\(String(format: "%.1f", entry.wellnessData.sleepHours))")
                                    .font(.title3.bold())
                                    .foregroundColor(.purple)
                                Text("Sleep hrs")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack {
                                Text("\(entry.wellnessData.meditationMinutes)")
                                    .font(.title3.bold())
                                    .foregroundColor(.green)
                                Text("Meditation")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Goals Summary
                    if !entry.goals.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "target")
                                    .foregroundColor(.purple)
                                Text("Active Goals")
                                    .font(.subheadline.bold())
                            }
                            
                            Text("\(entry.goals.count) goals in progress")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    
    private func progressColor(for percentage: Double) -> Color {
        switch percentage {
        case 0.8...:
            return .green
        case 0.5...:
            return .orange
        default:
            return .red
        }
    }
}

// MARK: - Widget Family Support
func supportedWidgetFamilies() -> [WidgetFamily] {
    var families: [WidgetFamily] = [.systemSmall, .systemMedium, .systemLarge]
    
    // Add iOS 17+ families if available
    if #available(iOS 17.0, *) {
        families.append(.systemExtraLarge)
    }
    
    return families
}

// MARK: - Main Widget
struct AreaBookWidget: Widget {
    let kind: String = "AreaBookWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AreaBookWidgetProvider()) { entry in
            AreaBookWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("AreaBook Dashboard")
        .description("Keep track of your key indicators, tasks, and daily progress.")
        .supportedFamilies(supportedWidgetFamilies())
        .contentMarginsDisabled()
    }
}