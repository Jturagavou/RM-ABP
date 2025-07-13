import Foundation
import SwiftUI
import FirebaseFirestore

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
    var description: String
    var type: GroupType
    var parentGroupId: String? // For companionships within districts
    var creatorId: String
    var members: [GroupMember]
    var settings: GroupSettings
    var invitationCode: String
    var createdAt: Date
    var updatedAt: Date
    
    init(name: String, description: String = "", type: GroupType, parentGroupId: String? = nil, creatorId: String) {
        self.id = UUID().uuidString
        self.name = name
        self.description = description
        self.type = type
        self.parentGroupId = parentGroupId
        self.creatorId = creatorId
        self.members = []
        self.settings = GroupSettings()
        self.invitationCode = UUID().uuidString.prefix(8).uppercased()
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    init?(from document: DocumentSnapshot) {
        guard let data = document.data() else { return nil }
        
        self.id = data["id"] as? String ?? ""
        self.name = data["name"] as? String ?? ""
        self.description = data["description"] as? String ?? ""
        self.type = GroupType(rawValue: data["type"] as? String ?? "") ?? .district
        self.parentGroupId = data["parentGroupId"] as? String
        self.creatorId = data["creatorId"] as? String ?? ""
        
        if let membersData = data["members"] as? [[String: Any]] {
            self.members = membersData.compactMap { GroupMember(from: $0) }
        } else {
            self.members = []
        }
        
        if let settingsData = data["settings"] as? [String: Any] {
            self.settings = GroupSettings(from: settingsData)
        } else {
            self.settings = GroupSettings()
        }
        
        self.invitationCode = data["invitationCode"] as? String ?? ""
        self.createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        self.updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
    }
    
    func toFirestoreData() -> [String: Any] {
        return [
            "id": id,
            "name": name,
            "description": description,
            "type": type.rawValue,
            "parentGroupId": parentGroupId ?? "",
            "creatorId": creatorId,
            "members": members.map { $0.toFirestoreData() },
            "settings": settings.toFirestoreData(),
            "invitationCode": invitationCode,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt)
        ]
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
    var lastActive: Date
    var permissions: GroupPermissions
    
    init(userId: String, role: GroupRole) {
        self.id = UUID().uuidString
        self.userId = userId
        self.role = role
        self.joinedAt = Date()
        self.lastActive = Date()
        self.permissions = GroupPermissions(role: role)
    }
    
    init(from document: DocumentSnapshot) {
        let data = document.data() ?? [:]
        self.id = data["id"] as? String ?? UUID().uuidString
        self.userId = data["userId"] as? String ?? ""
        self.role = GroupRole(rawValue: data["role"] as? String ?? "member") ?? .member
        self.joinedAt = (data["joinedAt"] as? Timestamp)?.dateValue() ?? Date()
        self.lastActive = (data["lastActive"] as? Timestamp)?.dateValue() ?? Date()
        
        if let permissionsData = data["permissions"] as? [String: Any] {
            self.permissions = GroupPermissions(from: permissionsData)
        } else {
            self.permissions = GroupPermissions(role: self.role)
        }
    }
    
    init?(from data: [String: Any]) {
        guard let userId = data["userId"] as? String,
              let roleString = data["role"] as? String,
              let role = GroupRole(rawValue: roleString) else { return nil }
        
        self.id = data["id"] as? String ?? UUID().uuidString
        self.userId = userId
        self.role = role
        self.joinedAt = (data["joinedAt"] as? Timestamp)?.dateValue() ?? Date()
        self.lastActive = (data["lastActive"] as? Timestamp)?.dateValue() ?? Date()
        
        if let permissionsData = data["permissions"] as? [String: Any] {
            self.permissions = GroupPermissions(from: permissionsData)
        } else {
            self.permissions = GroupPermissions(role: role)
        }
    }
    
    func toFirestoreData() -> [String: Any] {
        return [
            "id": id,
            "userId": userId,
            "role": role.rawValue,
            "joinedAt": Timestamp(date: joinedAt),
            "lastActive": Timestamp(date: lastActive),
            "permissions": permissions.toFirestoreData()
        ]
    }
}

enum GroupRole: String, Codable, CaseIterable {
    case admin = "admin"
    case leader = "leader"
    case member = "member"
    case viewer = "viewer"
}

struct GroupSettings: Codable {
    var isPublic: Bool
    var allowInvitations: Bool
    var shareProgress: Bool
    var allowChallenges: Bool
    var notificationSettings: [String: Bool]
    
    init() {
        self.isPublic = false
        self.allowInvitations = true
        self.shareProgress = true
        self.allowChallenges = true
        self.notificationSettings = [:]
    }
    
    init(from data: [String: Any]) {
        self.isPublic = data["isPublic"] as? Bool ?? false
        self.allowInvitations = data["allowInvitations"] as? Bool ?? true
        self.shareProgress = data["shareProgress"] as? Bool ?? true
        self.allowChallenges = data["allowChallenges"] as? Bool ?? true
        self.notificationSettings = data["notificationSettings"] as? [String: Bool] ?? [:]
    }
    
    func toFirestoreData() -> [String: Any] {
        return [
            "isPublic": isPublic,
            "allowInvitations": allowInvitations,
            "shareProgress": shareProgress,
            "allowChallenges": allowChallenges,
            "notificationSettings": notificationSettings
        ]
    }
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
    
    init(from data: [String: Any]) {
        self.canViewGoals = data["canViewGoals"] as? Bool ?? true
        self.canViewEvents = data["canViewEvents"] as? Bool ?? true
        self.canViewTasks = data["canViewTasks"] as? Bool ?? true
        self.canViewKIs = data["canViewKIs"] as? Bool ?? true
        self.canSendEncouragements = data["canSendEncouragements"] as? Bool ?? false
        self.canManageMembers = data["canManageMembers"] as? Bool ?? false
    }
    
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

// MARK: - Collaboration Models
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
        self.type = ProgressShareType(rawValue: data["type"] as? String ?? "") ?? .goal
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
    case goal = "goal"
    case task = "task"
    case keyIndicator = "ki"
    case event = "event"
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
        self.type = ChallengeType(rawValue: data["type"] as? String ?? "") ?? .goal
        self.target = data["target"] as? Double ?? 0.0
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
    case goal = "goal"
    case task = "task"
    case keyIndicator = "ki"
    case event = "event"
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
        self.type = NotificationType(rawValue: data["type"] as? String ?? "") ?? .encouragement
        self.fromUserId = data["fromUserId"] as? String ?? ""
        self.message = data["message"] as? String ?? ""
        self.data = data["data"] as? [String: String] ?? [:]
        self.timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
        self.isRead = data["isRead"] as? Bool ?? false
    }
}

enum NotificationType: String, Codable, CaseIterable {
    case encouragement = "encouragement"
    case challenge = "challenge"
    case invitation = "invitation"
    case progressShare = "progress_share"
    case kiUpdate = "ki_update"
    case goalProgress = "goal_progress"
    case taskCompleted = "task_completed"
    case milestone = "milestone"
    case achievement = "achievement"
}

struct GroupInvitation: Identifiable, Codable {
    let id: String
    let groupId: String
    let groupName: String
    let fromUserId: String
    let toUserId: String
    let message: String
    let createdAt: Date
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
    
    init(from document: DocumentSnapshot) {
        let data = document.data() ?? [:]
        self.id = data["id"] as? String ?? ""
        self.groupId = data["groupId"] as? String ?? ""
        self.groupName = data["groupName"] as? String ?? ""
        self.fromUserId = data["fromUserId"] as? String ?? ""
        self.toUserId = data["toUserId"] as? String ?? ""
        self.message = data["message"] as? String ?? ""
        self.createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        self.status = InvitationStatus(rawValue: data["status"] as? String ?? "") ?? .pending
    }
    
    func toFirestoreData() -> [String: Any] {
        return [
            "id": id,
            "groupId": groupId,
            "groupName": groupName,
            "fromUserId": fromUserId,
            "toUserId": toUserId,
            "message": message,
            "createdAt": Timestamp(date: createdAt),
            "status": status.rawValue
        ]
    }
}

enum InvitationStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case accepted = "accepted"
    case declined = "declined"
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