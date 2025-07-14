import Foundation
import SwiftUI

// MARK: - User Models
struct User: Identifiable, Codable {
    let id: String
    var email: String
    var name: String
    var avatar: String?
    var createdAt: Date
    var lastSeen: Date
    var settings: UserSettings
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
}

enum CalendarViewType: String, Codable, CaseIterable {
    case monthly = "monthly"
    case weekly = "weekly"
}

enum TaskViewType: String, Codable, CaseIterable {
    case day = "day"
    case week = "week"
    case goal = "goal"
}

// MARK: - Key Indicator Models
struct KeyIndicator: Identifiable, Codable {
    let id: String
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
    let id: String
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
    
    init(title: String, description: String, keyIndicatorIds: [String] = [], targetDate: Date? = nil) {
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
    }
}

enum GoalStatus: String, Codable, CaseIterable {
    case active = "active"
    case completed = "completed"
    case paused = "paused"
    case cancelled = "cancelled"
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
    let id: String
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
    
    init(title: String, description: String, category: String, startTime: Date, endTime: Date, linkedGoalId: String? = nil) {
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
struct Task: Identifiable, Codable {
    let id: String
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
    
    init(title: String, description: String? = nil, priority: TaskPriority = .medium, dueDate: Date? = nil, linkedGoalId: String? = nil, linkedEventId: String? = nil) {
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

// MARK: - Accountability Group Models
struct AccountabilityGroup: Identifiable, Codable {
    let id: String
    var name: String
    var type: GroupType
    var parentGroupId: String? // For companionships within districts
    var members: [GroupMember]
    var createdAt: Date
    var updatedAt: Date
    
    init(name: String, type: GroupType, parentGroupId: String? = nil) {
        self.id = UUID().uuidString
        self.name = name
        self.type = type
        self.parentGroupId = parentGroupId
        self.members = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

enum GroupType: String, Codable, CaseIterable {
    case district = "district"
    case companionship = "companionship"
}

struct GroupMember: Identifiable, Codable {
    let id: String
    var userId: String
    var role: GroupRole
    var joinedAt: Date
    var permissions: GroupPermissions
    
    init(userId: String, role: GroupRole) {
        self.id = UUID().uuidString
        self.userId = userId
        self.role = role
        self.joinedAt = Date()
        self.permissions = GroupPermissions(role: role)
    }
}

enum GroupRole: String, Codable, CaseIterable {
    case admin = "admin"
    case leader = "leader"
    case member = "member"
    case viewer = "viewer"
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
        }
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
    var todaysTasks: [Task]
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

// MARK: - Enhanced Data Models

// Template Models
struct GoalTemplate: Identifiable, Codable {
    let id: String
    var name: String
    var description: String
    var category: String
    var defaultKIIds: [String]
    var estimatedDuration: Int // in days
    var difficulty: GoalDifficulty
    var tags: [String]
    var isShared: Bool
    var createdBy: String
    var createdAt: Date
    var usage: Int // how many times used
    
    init(name: String, description: String, category: String, defaultKIIds: [String] = [], estimatedDuration: Int = 30, difficulty: GoalDifficulty = .medium, tags: [String] = [], isShared: Bool = false, createdBy: String) {
        self.id = UUID().uuidString
        self.name = name
        self.description = description
        self.category = category
        self.defaultKIIds = defaultKIIds
        self.estimatedDuration = estimatedDuration
        self.difficulty = difficulty
        self.tags = tags
        self.isShared = isShared
        self.createdBy = createdBy
        self.createdAt = Date()
        self.usage = 0
    }
}

enum GoalDifficulty: String, Codable, CaseIterable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
    
    var color: String {
        switch self {
        case .beginner: return "#10B981"
        case .intermediate: return "#F59E0B"
        case .advanced: return "#EF4444"
        }
    }
}

struct TaskTemplate: Identifiable, Codable {
    let id: String
    var name: String
    var description: String
    var category: String
    var estimatedTime: Int // in minutes
    var defaultPriority: TaskPriority
    var tags: [String]
    var isShared: Bool
    var createdBy: String
    var createdAt: Date
    var usage: Int
    
    init(name: String, description: String, category: String, estimatedTime: Int = 30, defaultPriority: TaskPriority = .medium, tags: [String] = [], isShared: Bool = false, createdBy: String) {
        self.id = UUID().uuidString
        self.name = name
        self.description = description
        self.category = category
        self.estimatedTime = estimatedTime
        self.defaultPriority = defaultPriority
        self.tags = tags
        self.isShared = isShared
        self.createdBy = createdBy
        self.createdAt = Date()
        self.usage = 0
    }
}

struct EventTemplate: Identifiable, Codable {
    let id: String
    var name: String
    var description: String
    var category: String
    var defaultDuration: Int // in minutes
    var tags: [String]
    var isShared: Bool
    var createdBy: String
    var createdAt: Date
    var usage: Int
    
    init(name: String, description: String, category: String, defaultDuration: Int = 60, tags: [String] = [], isShared: Bool = false, createdBy: String) {
        self.id = UUID().uuidString
        self.name = name
        self.description = description
        self.category = category
        self.defaultDuration = defaultDuration
        self.tags = tags
        self.isShared = isShared
        self.createdBy = createdBy
        self.createdAt = Date()
        self.usage = 0
    }
}

// Historical Tracking Models
struct KeyIndicatorHistory: Identifiable, Codable {
    let id: String
    var keyIndicatorId: String
    var date: Date
    var value: Int
    var weeklyTarget: Int
    var notes: String?
    var createdAt: Date
    
    init(keyIndicatorId: String, date: Date, value: Int, weeklyTarget: Int, notes: String? = nil) {
        self.id = UUID().uuidString
        self.keyIndicatorId = keyIndicatorId
        self.date = date
        self.value = value
        self.weeklyTarget = weeklyTarget
        self.notes = notes
        self.createdAt = Date()
    }
}

struct GoalMilestone: Identifiable, Codable {
    let id: String
    var title: String
    var description: String
    var targetDate: Date
    var completed: Bool
    var completedAt: Date?
    var notes: String?
    var createdAt: Date
    
    init(title: String, description: String, targetDate: Date) {
        self.id = UUID().uuidString
        self.title = title
        self.description = description
        self.targetDate = targetDate
        self.completed = false
        self.completedAt = nil
        self.notes = nil
        self.createdAt = Date()
    }
}

// Enhanced Goal Model with additional properties
extension Goal {
    var milestones: [GoalMilestone] {
        get {
            // This would be loaded from Firestore
            return []
        }
        set {
            // This would be saved to Firestore
        }
    }
    
    var dependencies: [String] {
        get {
            // Goal IDs that must be completed first
            return []
        }
        set {
            // Save to Firestore
        }
    }
    
    var collaborators: [String] {
        get {
            // User IDs who can collaborate on this goal
            return []
        }
        set {
            // Save to Firestore
        }
    }
    
    var shareSettings: GoalShareSettings {
        get {
            return GoalShareSettings()
        }
        set {
            // Save to Firestore
        }
    }
}

struct GoalShareSettings: Codable {
    var isShared: Bool = false
    var shareWithGroups: [String] = []
    var shareLevel: ShareLevel = .read
    var allowComments: Bool = true
    var allowSuggestions: Bool = true
    var expirationDate: Date?
}

enum ShareLevel: String, Codable, CaseIterable {
    case read = "read"
    case comment = "comment"
    case edit = "edit"
    case admin = "admin"
}

// Enhanced Task Model with dependencies and time tracking
extension Task {
    var dependencies: [String] {
        get {
            // Task IDs that must be completed first
            return []
        }
        set {
            // Save to Firestore
        }
    }
    
    var timeTracking: TaskTimeTracking {
        get {
            return TaskTimeTracking()
        }
        set {
            // Save to Firestore
        }
    }
    
    var delegatedTo: String? {
        get {
            // User ID if task is delegated
            return nil
        }
        set {
            // Save to Firestore
        }
    }
}

struct TaskTimeTracking: Codable {
    var estimatedTime: Int = 0 // in minutes
    var actualTime: Int = 0 // in minutes
    var startTime: Date?
    var endTime: Date?
    var isPaused: Bool = false
    var pausedAt: Date?
    var totalPausedTime: Int = 0 // in minutes
}

// Enhanced AccountabilityGroup Model
extension AccountabilityGroup {
    var hierarchyLevel: GroupHierarchyLevel {
        get {
            return GroupHierarchyLevel.companionship
        }
        set {
            // Save to Firestore
        }
    }
    
    var parentGroups: [String] {
        get {
            // Parent group IDs
            return []
        }
        set {
            // Save to Firestore
        }
    }
    
    var childGroups: [String] {
        get {
            // Child group IDs
            return []
        }
        set {
            // Save to Firestore
        }
    }
    
    var settings: GroupSettings {
        get {
            return GroupSettings()
        }
        set {
            // Save to Firestore
        }
    }
}

enum GroupHierarchyLevel: String, Codable, CaseIterable {
    case zone = "zone"
    case district = "district"
    case companionship = "companionship"
    
    var displayName: String {
        switch self {
        case .zone: return "Zone"
        case .district: return "District"
        case .companionship: return "Companionship"
        }
    }
}

struct GroupSettings: Codable {
    var allowMemberInvites: Bool = true
    var requireApprovalForJoin: Bool = false
    var allowCrossGroupVisibility: Bool = true
    var enableGroupChallenges: Bool = true
    var enableGroupChat: Bool = true
    var autoArchiveInactive: Bool = false
    var inactivityThreshold: Int = 30 // days
    var defaultShareLevel: ShareLevel = .read
    var allowDataExport: Bool = true
    var enableAnalytics: Bool = true
}

// Data Validation Models
struct ValidationRule: Identifiable, Codable {
    let id: String
    var field: String
    var ruleType: ValidationRuleType
    var parameters: [String: Any]
    var errorMessage: String
    var isActive: Bool
    
    init(field: String, ruleType: ValidationRuleType, parameters: [String: Any], errorMessage: String) {
        self.id = UUID().uuidString
        self.field = field
        self.ruleType = ruleType
        self.parameters = parameters
        self.errorMessage = errorMessage
        self.isActive = true
    }
}

enum ValidationRuleType: String, Codable, CaseIterable {
    case required = "required"
    case minLength = "minLength"
    case maxLength = "maxLength"
    case pattern = "pattern"
    case range = "range"
    case unique = "unique"
    case crossField = "crossField"
    case custom = "custom"
}

struct ValidationResult: Codable {
    var isValid: Bool
    var errors: [ValidationError]
    var warnings: [ValidationWarning]
    
    init(isValid: Bool = true, errors: [ValidationError] = [], warnings: [ValidationWarning] = []) {
        self.isValid = isValid
        self.errors = errors
        self.warnings = warnings
    }
}

struct ValidationError: Identifiable, Codable {
    let id: String
    var field: String
    var message: String
    var ruleType: ValidationRuleType
    var severity: ValidationSeverity
    
    init(field: String, message: String, ruleType: ValidationRuleType, severity: ValidationSeverity = .error) {
        self.id = UUID().uuidString
        self.field = field
        self.message = message
        self.ruleType = ruleType
        self.severity = severity
    }
}

struct ValidationWarning: Identifiable, Codable {
    let id: String
    var field: String
    var message: String
    var suggestion: String?
    
    init(field: String, message: String, suggestion: String? = nil) {
        self.id = UUID().uuidString
        self.field = field
        self.message = message
        self.suggestion = suggestion
    }
}

enum ValidationSeverity: String, Codable, CaseIterable {
    case error = "error"
    case warning = "warning"
    case info = "info"
}

// Conflict Resolution Models
struct DataConflict: Identifiable, Codable {
    let id: String
    var entityType: String
    var entityId: String
    var localVersion: [String: Any]
    var serverVersion: [String: Any]
    var conflictType: ConflictType
    var detectedAt: Date
    var resolvedAt: Date?
    var resolutionStrategy: ConflictResolutionStrategy?
    var resolvedBy: String?
    
    init(entityType: String, entityId: String, localVersion: [String: Any], serverVersion: [String: Any], conflictType: ConflictType) {
        self.id = UUID().uuidString
        self.entityType = entityType
        self.entityId = entityId
        self.localVersion = localVersion
        self.serverVersion = serverVersion
        self.conflictType = conflictType
        self.detectedAt = Date()
        self.resolvedAt = nil
        self.resolutionStrategy = nil
        self.resolvedBy = nil
    }
}

enum ConflictType: String, Codable, CaseIterable {
    case update = "update"
    case delete = "delete"
    case create = "create"
    case permission = "permission"
}

enum ConflictResolutionStrategy: String, Codable, CaseIterable {
    case useLocal = "useLocal"
    case useServer = "useServer"
    case merge = "merge"
    case manual = "manual"
}

// Analytics Models
struct AnalyticsData: Codable {
    var userId: String
    var date: Date
    var metrics: [AnalyticsMetric]
    var trends: [AnalyticsTrend]
    var insights: [AnalyticsInsight]
    
    init(userId: String, date: Date = Date()) {
        self.userId = userId
        self.date = date
        self.metrics = []
        self.trends = []
        self.insights = []
    }
}

struct AnalyticsMetric: Identifiable, Codable {
    let id: String
    var name: String
    var value: Double
    var unit: String
    var category: AnalyticsCategory
    var timestamp: Date
    
    init(name: String, value: Double, unit: String, category: AnalyticsCategory) {
        self.id = UUID().uuidString
        self.name = name
        self.value = value
        self.unit = unit
        self.category = category
        self.timestamp = Date()
    }
}

enum AnalyticsCategory: String, Codable, CaseIterable {
    case keyIndicators = "keyIndicators"
    case goals = "goals"
    case tasks = "tasks"
    case events = "events"
    case groups = "groups"
    case productivity = "productivity"
    case engagement = "engagement"
}

struct AnalyticsTrend: Identifiable, Codable {
    let id: String
    var name: String
    var direction: TrendDirection
    var percentage: Double
    var period: TrendPeriod
    var significance: TrendSignificance
    var description: String
    
    init(name: String, direction: TrendDirection, percentage: Double, period: TrendPeriod, significance: TrendSignificance, description: String) {
        self.id = UUID().uuidString
        self.name = name
        self.direction = direction
        self.percentage = percentage
        self.period = period
        self.significance = significance
        self.description = description
    }
}

enum TrendDirection: String, Codable, CaseIterable {
    case increasing = "increasing"
    case decreasing = "decreasing"
    case stable = "stable"
}

enum TrendPeriod: String, Codable, CaseIterable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case yearly = "yearly"
}

enum TrendSignificance: String, Codable, CaseIterable {
    case high = "high"
    case medium = "medium"
    case low = "low"
}

struct AnalyticsInsight: Identifiable, Codable {
    let id: String
    var title: String
    var description: String
    var category: AnalyticsCategory
    var confidence: Double // 0.0 to 1.0
    var actionable: Bool
    var suggestions: [String]
    var createdAt: Date
    
    init(title: String, description: String, category: AnalyticsCategory, confidence: Double = 0.8, actionable: Bool = true, suggestions: [String] = []) {
        self.id = UUID().uuidString
        self.title = title
        self.description = description
        self.category = category
        self.confidence = confidence
        self.actionable = actionable
        self.suggestions = suggestions
        self.createdAt = Date()
    }
}