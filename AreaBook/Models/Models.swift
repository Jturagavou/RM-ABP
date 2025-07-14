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
    case zone = "zone"
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
    var canViewFullSync: Bool
    var canAssignTasks: Bool
    var canCreateComments: Bool
    
    init(role: GroupRole) {
        switch role {
        case .admin:
            self.canViewGoals = true
            self.canViewEvents = true
            self.canViewTasks = true
            self.canViewKIs = true
            self.canSendEncouragements = true
            self.canManageMembers = true
            self.canViewFullSync = true
            self.canAssignTasks = true
            self.canCreateComments = true
        case .leader:
            self.canViewGoals = true
            self.canViewEvents = true
            self.canViewTasks = true
            self.canViewKIs = true
            self.canSendEncouragements = true
            self.canManageMembers = false
            self.canViewFullSync = true
            self.canAssignTasks = true
            self.canCreateComments = true
        case .member:
            self.canViewGoals = true
            self.canViewEvents = true
            self.canViewTasks = true
            self.canViewKIs = true
            self.canSendEncouragements = true
            self.canManageMembers = false
            self.canViewFullSync = false
            self.canAssignTasks = false
            self.canCreateComments = true
        case .viewer:
            self.canViewGoals = true
            self.canViewEvents = true
            self.canViewTasks = true
            self.canViewKIs = true
            self.canSendEncouragements = false
            self.canManageMembers = false
            self.canViewFullSync = false
            self.canAssignTasks = false
            self.canCreateComments = false
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

// MARK: - Group Comments and Feedback
struct GroupComment: Identifiable, Codable {
    let id: String
    var groupId: String
    var authorId: String
    var targetType: CommentTargetType
    var targetId: String
    var content: String
    var createdAt: Date
    var updatedAt: Date
    var parentCommentId: String? // For threaded comments
    var reactions: [CommentReaction]
    
    init(groupId: String, authorId: String, targetType: CommentTargetType, targetId: String, content: String, parentCommentId: String? = nil) {
        self.id = UUID().uuidString
        self.groupId = groupId
        self.authorId = authorId
        self.targetType = targetType
        self.targetId = targetId
        self.content = content
        self.createdAt = Date()
        self.updatedAt = Date()
        self.parentCommentId = parentCommentId
        self.reactions = []
    }
}

enum CommentTargetType: String, Codable, CaseIterable {
    case goal = "goal"
    case event = "event"
    case task = "task"
    case keyIndicator = "keyIndicator"
}

struct CommentReaction: Identifiable, Codable {
    let id: String
    var userId: String
    var type: ReactionType
    var createdAt: Date
    
    init(userId: String, type: ReactionType) {
        self.id = UUID().uuidString
        self.userId = userId
        self.type = type
        self.createdAt = Date()
    }
}

enum ReactionType: String, Codable, CaseIterable {
    case thumbsUp = "thumbsUp"
    case heart = "heart"
    case celebrate = "celebrate"
    case pray = "pray"
    case support = "support"
}

// MARK: - Full Sync Models
struct FullSyncShare: Identifiable, Codable {
    let id: String
    var ownerId: String
    var groupId: String
    var sharedWithUserId: String
    var permissions: SyncPermissions
    var createdAt: Date
    var expiresAt: Date?
    var isActive: Bool
    
    init(ownerId: String, groupId: String, sharedWithUserId: String, permissions: SyncPermissions, expiresAt: Date? = nil) {
        self.id = UUID().uuidString
        self.ownerId = ownerId
        self.groupId = groupId
        self.sharedWithUserId = sharedWithUserId
        self.permissions = permissions
        self.createdAt = Date()
        self.expiresAt = expiresAt
        self.isActive = true
    }
}

struct SyncPermissions: Codable {
    var canViewGoals: Bool
    var canViewEvents: Bool
    var canViewTasks: Bool
    var canViewNotes: Bool
    var canViewKIs: Bool
    var canViewDashboard: Bool
    
    init(canViewGoals: Bool = true, canViewEvents: Bool = true, canViewTasks: Bool = true, canViewNotes: Bool = true, canViewKIs: Bool = true, canViewDashboard: Bool = true) {
        self.canViewGoals = canViewGoals
        self.canViewEvents = canViewEvents
        self.canViewTasks = canViewTasks
        self.canViewNotes = canViewNotes
        self.canViewKIs = canViewKIs
        self.canViewDashboard = canViewDashboard
    }
}

// MARK: - Group Task Assignment
struct GroupTaskAssignment: Identifiable, Codable {
    let id: String
    var groupId: String
    var assignedById: String
    var assignedToId: String
    var taskId: String
    var goalId: String?
    var dueDate: Date
    var priority: TaskPriority
    var status: AssignmentStatus
    var createdAt: Date
    var completedAt: Date?
    var notes: String?
    
    init(groupId: String, assignedById: String, assignedToId: String, taskId: String, goalId: String? = nil, dueDate: Date, priority: TaskPriority = .medium, notes: String? = nil) {
        self.id = UUID().uuidString
        self.groupId = groupId
        self.assignedById = assignedById
        self.assignedToId = assignedToId
        self.taskId = taskId
        self.goalId = goalId
        self.dueDate = dueDate
        self.priority = priority
        self.status = .pending
        self.createdAt = Date()
        self.completedAt = nil
        self.notes = notes
    }
}

enum AssignmentStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case accepted = "accepted"
    case inProgress = "inProgress"
    case completed = "completed"
    case declined = "declined"
}