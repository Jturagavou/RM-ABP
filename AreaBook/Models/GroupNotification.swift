import Foundation

struct GroupNotification: Codable, Identifiable {
    let id: String
    let groupId: String
    let userId: String // recipient
    let type: NotificationType
    let title: String
    let message: String
    let isRead: Bool
    let createdAt: Date
    
    enum NotificationType: String, Codable, CaseIterable {
        case groupInvitation = "group_invitation"
        case goalShared = "goal_shared"
        case challengeStarted = "challenge_started"
        case challengeCompleted = "challenge_completed"
        case memberJoined = "member_joined"
        case memberLeft = "member_left"
        case progressUpdate = "progress_update"
        case groupUpdate = "group_update"
    }
    
    init(id: String = UUID().uuidString,
         groupId: String,
         userId: String,
         type: NotificationType,
         title: String,
         message: String,
         isRead: Bool = false,
         createdAt: Date = Date()) {
        self.id = id
        self.groupId = groupId
        self.userId = userId
        self.type = type
        self.title = title
        self.message = message
        self.isRead = isRead
        self.createdAt = createdAt
    }
}