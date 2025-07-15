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

// MARK: - User Suggestion Models
struct UserSuggestion: Identifiable, Codable {
    let id: String
    let email: String
    let name: String
    let avatar: String?
    let mutualConnections: Int
    let lastSeen: Date?
    
    init(from user: User, mutualConnections: Int = 0) {
        self.id = user.id
        self.email = user.email
        self.name = user.name
        self.avatar = user.avatar
        self.mutualConnections = mutualConnections
        self.lastSeen = user.lastSeen
    }
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
    var connectedKeyIndicatorId: String? // New: Connected key indicator for progress tracking
    var targetProgressAmount: Int? // New: Target progress amount for this goal
    
    init(title: String, description: String, keyIndicatorIds: [String] = [], targetDate: Date? = nil, connectedKeyIndicatorId: String? = nil, targetProgressAmount: Int? = nil) {
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
        self.connectedKeyIndicatorId = connectedKeyIndicatorId
        self.targetProgressAmount = targetProgressAmount
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

// MARK: - Timeline Models
struct TimelineItem: Identifiable, Codable {
    let id: String
    let type: TimelineItemType
    let title: String
    let description: String?
    let createdAt: Date
    let completedAt: Date?
    let isCompleted: Bool
    let linkedGoalId: String?
    let progressAmount: Int?
    let connectedKeyIndicatorId: String?
    
    init(from event: CalendarEvent) {
        self.id = event.id
        self.type = .event
        self.title = event.title
        self.description = event.description
        self.createdAt = event.createdAt
        self.completedAt = event.status == .completed ? event.updatedAt : nil
        self.isCompleted = event.status == .completed
        self.linkedGoalId = event.linkedGoalId
        self.progressAmount = event.progressAmount
        self.connectedKeyIndicatorId = event.connectedKeyIndicatorId
    }
    
    init(from task: Task) {
        self.id = task.id
        self.type = .task
        self.title = task.title
        self.description = task.description
        self.createdAt = task.createdAt
        self.completedAt = task.completedAt
        self.isCompleted = task.status == .completed
        self.linkedGoalId = task.linkedGoalId
        self.progressAmount = task.progressAmount
        self.connectedKeyIndicatorId = task.connectedKeyIndicatorId
    }
    
    init(from note: Note) {
        self.id = note.id
        self.type = .note
        self.title = note.title
        self.description = note.content
        self.createdAt = note.createdAt
        self.completedAt = nil
        self.isCompleted = false
        self.linkedGoalId = note.linkedGoalIds.first
        self.progressAmount = nil
        self.connectedKeyIndicatorId = nil
    }
}

enum TimelineItemType: String, Codable, CaseIterable {
    case event = "event"
    case task = "task"
    case note = "note"
    
    var icon: String {
        switch self {
        case .event: return "calendar"
        case .task: return "checkmark.circle"
        case .note: return "note.text"
        }
    }
    
    var color: String {
        switch self {
        case .event: return "#3B82F6"
        case .task: return "#10B981"
        case .note: return "#8B5CF6"
        }
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
    var progressAmount: Int? // New: Progress amount for this event
    var connectedKeyIndicatorId: String? // New: Connected key indicator for progress tracking
    
    init(title: String, description: String, category: String, startTime: Date, endTime: Date, linkedGoalId: String? = nil, progressAmount: Int? = nil, connectedKeyIndicatorId: String? = nil) {
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
        self.progressAmount = progressAmount
        self.connectedKeyIndicatorId = connectedKeyIndicatorId
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
    var progressAmount: Int? // New: Progress amount for this task
    var connectedKeyIndicatorId: String? // New: Connected key indicator for progress tracking
    
    init(title: String, description: String? = nil, priority: TaskPriority = .medium, dueDate: Date? = nil, linkedGoalId: String? = nil, linkedEventId: String? = nil, progressAmount: Int? = nil, connectedKeyIndicatorId: String? = nil) {
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
        self.progressAmount = progressAmount
        self.connectedKeyIndicatorId = connectedKeyIndicatorId
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
    var settings: GroupSettings
    var description: String // New: Description field for groups
    
    init(name: String, type: GroupType, parentGroupId: String? = nil, description: String = "") {
        self.id = UUID().uuidString
        self.name = name
        self.type = type
        self.parentGroupId = parentGroupId
        self.members = []
        self.createdAt = Date()
        self.updatedAt = Date()
        self.settings = GroupSettings()
        self.description = description
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

struct GroupSettings: Codable {
    var isPublic: Bool = false
    var allowInvitations: Bool = true
    var shareProgress: Bool = true
    var allowChallenges: Bool = true
    var requireApproval: Bool = false
    var maxMembers: Int = 50
    
    init() {}
    
    init(from data: [String: Any]) {
        self.isPublic = data["isPublic"] as? Bool ?? false
        self.allowInvitations = data["allowInvitations"] as? Bool ?? true
        self.shareProgress = data["shareProgress"] as? Bool ?? true
        self.allowChallenges = data["allowChallenges"] as? Bool ?? true
        self.requireApproval = data["requireApproval"] as? Bool ?? false
        self.maxMembers = data["maxMembers"] as? Int ?? 50
    }
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