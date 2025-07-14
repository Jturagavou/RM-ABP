import Foundation
import Firebase
import Combine

// MARK: - Collaboration Manager
class CollaborationManager: ObservableObject {
    static let shared = CollaborationManager()
    
    @Published var currentUserGroups: [AccountabilityGroup] = []
    @Published var groupInvitations: [GroupInvitation] = []
    @Published var sharedProgress: [String: [ProgressShare]] = [:] // groupId: [progress]
    @Published var groupChallenges: [GroupChallenge] = []
    @Published var groupComments: [String: [GroupComment]] = [:] // targetId: [comments]
    @Published var fullSyncShares: [FullSyncShare] = []
    @Published var groupTaskAssignments: [GroupTaskAssignment] = []
    
    private var db = Firestore.firestore()
    private var listeners: [ListenerRegistration] = []
    
    private init() {}
    
    // MARK: - Group Management
    
    func createGroup(name: String, description: String, creatorId: String) async throws -> AccountabilityGroup {
        let group = AccountabilityGroup(
            name: name,
            description: description,
            creatorId: creatorId,
            members: [GroupMember(userId: creatorId, role: .admin, joinedAt: Date())],
            settings: GroupSettings()
        )
        
        try await db.collection("groups").document(group.id).setData(group.firestoreData)
        
        // Add to user's groups
        try await addUserToGroup(userId: creatorId, groupId: group.id, role: .admin)
        
        return group
    }
    
    func joinGroup(groupId: String, userId: String, invitationCode: String) async throws {
        // Verify invitation code
        let groupDoc = try await db.collection("groups").document(groupId).getDocument()
        guard let group = AccountabilityGroup(from: groupDoc) else {
            throw CollaborationError.groupNotFound
        }
        
        guard group.invitationCode == invitationCode else {
            throw CollaborationError.invalidInvitationCode
        }
        
        // Add user to group
        let member = GroupMember(userId: userId, role: .member, joinedAt: Date())
        try await db.collection("groups").document(groupId).updateData([
            "members": FieldValue.arrayUnion([member.firestoreData])
        ])
        
        // Add to user's groups
        try await addUserToGroup(userId: userId, groupId: groupId, role: .member)
    }
    
    func leaveGroup(groupId: String, userId: String) async throws {
        // Remove from group members
        let groupRef = db.collection("groups").document(groupId)
        let groupDoc = try await groupRef.getDocument()
        
        guard var group = AccountabilityGroup(from: groupDoc) else {
            throw CollaborationError.groupNotFound
        }
        
        group.members.removeAll { $0.userId == userId }
        
        try await groupRef.updateData([
            "members": group.members.map { $0.firestoreData }
        ])
        
        // Remove from user's groups
        try await removeUserFromGroup(userId: userId, groupId: groupId)
    }
    
    // MARK: - Progress Sharing
    
    func shareProgress(groupId: String, userId: String, type: ProgressShareType, data: [String: Any]) async throws {
        let progressShare = ProgressShare(
            id: UUID().uuidString,
            userId: userId,
            groupId: groupId,
            type: type,
            data: data,
            timestamp: Date()
        )
        
        try await db.collection("groups").document(groupId)
            .collection("progress_shares").document(progressShare.id)
            .setData(progressShare.firestoreData)
        
        // Send notification to group members
        try await notifyGroupMembers(groupId: groupId, notification: GroupNotification(
            type: .progressUpdate,
            fromUserId: userId,
            message: "\(userId) shared progress",
            data: ["progressId": progressShare.id]
        ))
    }
    
    func getGroupProgress(groupId: String) async throws -> [ProgressShare] {
        let snapshot = try await db.collection("groups").document(groupId)
            .collection("progress_shares")
            .order(by: "timestamp", descending: true)
            .limit(to: 50)
            .getDocuments()
        
        return snapshot.documents.compactMap { ProgressShare(from: $0) }
    }
    
    // MARK: - Group Challenges
    
    func createGroupChallenge(groupId: String, creatorId: String, challenge: GroupChallenge) async throws {
        var newChallenge = challenge
        newChallenge.groupId = groupId
        newChallenge.creatorId = creatorId
        
        try await db.collection("groups").document(groupId)
            .collection("challenges").document(newChallenge.id)
            .setData(newChallenge.firestoreData)
        
        // Notify group members
        try await notifyGroupMembers(groupId: groupId, notification: GroupNotification(
            type: .challengeCreated,
            fromUserId: creatorId,
            message: "New challenge: \(challenge.title)",
            data: ["challengeId": newChallenge.id]
        ))
    }
    
    func joinChallenge(groupId: String, challengeId: String, userId: String) async throws {
        let challengeRef = db.collection("groups").document(groupId)
            .collection("challenges").document(challengeId)
        
        try await challengeRef.updateData([
            "participants": FieldValue.arrayUnion([userId])
        ])
        
        // Update user's challenge participation
        try await db.collection("users").document(userId)
            .collection("challenge_participations").document(challengeId)
            .setData([
                "challengeId": challengeId,
                "groupId": groupId,
                "joinedAt": Timestamp(date: Date()),
                "progress": 0
            ])
    }
    
    func updateChallengeProgress(groupId: String, challengeId: String, userId: String, progress: Double) async throws {
        try await db.collection("users").document(userId)
            .collection("challenge_participations").document(challengeId)
            .updateData([
                "progress": progress,
                "lastUpdated": Timestamp(date: Date())
            ])
        
        // Check if challenge is completed
        if progress >= 1.0 {
            try await notifyGroupMembers(groupId: groupId, notification: GroupNotification(
                type: .challengeCompleted,
                fromUserId: userId,
                message: "\(userId) completed the challenge!",
                data: ["challengeId": challengeId]
            ))
        }
    }
    
    // MARK: - Real-time Listeners
    
    func startListeningToUserGroups(userId: String) {
        let listener = db.collection("users").document(userId)
            .collection("groups")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                let groupIds = documents.compactMap { $0.data()["groupId"] as? String }
                self?.fetchUserGroups(groupIds: groupIds)
            }
        
        listeners.append(listener)
    }
    
    func startListeningToGroupProgress(groupId: String) {
        let listener = db.collection("groups").document(groupId)
            .collection("progress_shares")
            .order(by: "timestamp", descending: true)
            .limit(to: 20)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                let progressShares = documents.compactMap { ProgressShare(from: $0) }
                DispatchQueue.main.async {
                    self?.sharedProgress[groupId] = progressShares
                }
            }
        
        listeners.append(listener)
    }
    
    func startListeningToGroupChallenges(groupId: String) {
        let listener = db.collection("groups").document(groupId)
            .collection("challenges")
            .whereField("isActive", isEqualTo: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                let challenges = documents.compactMap { GroupChallenge(from: $0) }
                DispatchQueue.main.async {
                    self?.groupChallenges = challenges
                }
            }
        
        listeners.append(listener)
    }
    
    // MARK: - Data Access Control
    
    func getUserRoleInGroup(groupId: String, userId: String) async throws -> GroupRole? {
        let groupDoc = try await db.collection("groups").document(groupId).getDocument()
        guard let group = AccountabilityGroup(from: groupDoc) else { return nil }
        
        return group.members.first { $0.userId == userId }?.role
    }
    
    func canUserAccessGroupData(groupId: String, userId: String) async throws -> Bool {
        let role = try await getUserRoleInGroup(groupId: groupId, userId: userId)
        return role != nil
    }
    
    func canUserModifyGroupData(groupId: String, userId: String) async throws -> Bool {
        let role = try await getUserRoleInGroup(groupId: groupId, userId: userId)
        return role == .admin || role == .moderator
    }
    
    // MARK: - Private Helpers
    
    private func addUserToGroup(userId: String, groupId: String, role: GroupRole) async throws {
        try await db.collection("users").document(userId)
            .collection("groups").document(groupId)
            .setData([
                "groupId": groupId,
                "role": role.rawValue,
                "joinedAt": Timestamp(date: Date())
            ])
    }
    
    private func removeUserFromGroup(userId: String, groupId: String) async throws {
        try await db.collection("users").document(userId)
            .collection("groups").document(groupId)
            .delete()
    }
    
    private func fetchUserGroups(groupIds: [String]) {
        Task {
            var groups: [AccountabilityGroup] = []
            
            for groupId in groupIds {
                do {
                    let doc = try await db.collection("groups").document(groupId).getDocument()
                    if let group = AccountabilityGroup(from: doc) {
                        groups.append(group)
                    }
                } catch {
                    print("Error fetching group \(groupId): \(error)")
                }
            }
            
            DispatchQueue.main.async {
                self.currentUserGroups = groups
            }
        }
    }
    
    private func notifyGroupMembers(groupId: String, notification: GroupNotification) async throws {
        let groupDoc = try await db.collection("groups").document(groupId).getDocument()
        guard let group = AccountabilityGroup(from: groupDoc) else { return }
        
        for member in group.members {
            try await db.collection("users").document(member.userId)
                .collection("notifications").document(notification.id)
                .setData(notification.firestoreData)
        }
    }
    
    func stopAllListeners() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }
}

// MARK: - Supporting Models

struct ProgressShare: Identifiable, Codable {
    let id: String
    let userId: String
    let groupId: String
    let type: ProgressShareType
    let data: [String: Any]
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case id, userId, groupId, type, timestamp
    }
    
    var firestoreData: [String: Any] {
        return [
            "id": id,
            "userId": userId,
            "groupId": groupId,
            "type": type.rawValue,
            "data": data,
            "timestamp": Timestamp(date: timestamp)
        ]
    }
    
    init(from document: DocumentSnapshot) {
        let data = document.data() ?? [:]
        self.id = data["id"] as? String ?? ""
        self.userId = data["userId"] as? String ?? ""
        self.groupId = data["groupId"] as? String ?? ""
        self.type = ProgressShareType(rawValue: data["type"] as? String ?? "") ?? .kiUpdate
        self.data = data["data"] as? [String: Any] ?? [:]
        self.timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
    }
    
    init(id: String, userId: String, groupId: String, type: ProgressShareType, data: [String: Any], timestamp: Date) {
        self.id = id
        self.userId = userId
        self.groupId = groupId
        self.type = type
        self.data = data
        self.timestamp = timestamp
    }
}

enum ProgressShareType: String, CaseIterable {
    case kiUpdate = "ki_update"
    case goalProgress = "goal_progress"
    case taskCompleted = "task_completed"
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
    
    var firestoreData: [String: Any] {
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
    
    init(title: String, description: String, type: ChallengeType, target: Double, unit: String, startDate: Date, endDate: Date) {
        self.id = UUID().uuidString
        self.groupId = ""
        self.creatorId = ""
        self.title = title
        self.description = description
        self.type = type
        self.target = target
        self.unit = unit
        self.startDate = startDate
        self.endDate = endDate
        self.participants = []
        self.isActive = true
        self.createdAt = Date()
    }
}

enum ChallengeType: String, CaseIterable {
    case individual = "individual"
    case team = "team"
    case competition = "competition"
}

struct GroupNotification: Identifiable, Codable {
    let id: String
    let type: NotificationType
    let fromUserId: String
    let message: String
    let data: [String: Any]
    let timestamp: Date
    var isRead: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, type, fromUserId, message, timestamp, isRead
    }
    
    var firestoreData: [String: Any] {
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
    
    init(type: NotificationType, fromUserId: String, message: String, data: [String: Any] = [:]) {
        self.id = UUID().uuidString
        self.type = type
        self.fromUserId = fromUserId
        self.message = message
        self.data = data
        self.timestamp = Date()
        self.isRead = false
    }
}

enum NotificationType: String, CaseIterable {
    case progressUpdate = "progress_update"
    case challengeCreated = "challenge_created"
    case challengeCompleted = "challenge_completed"
    case groupInvitation = "group_invitation"
    case milestone = "milestone"
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
    
    enum InvitationStatus: String, CaseIterable {
        case pending = "pending"
        case accepted = "accepted"
        case declined = "declined"
        case expired = "expired"
    }
}

enum CollaborationError: Error {
    case groupNotFound
    case invalidInvitationCode
    case insufficientPermissions
    case userNotInGroup
    case challengeNotFound
}

// MARK: - Extensions for AccountabilityGroup

extension AccountabilityGroup {
    var firestoreData: [String: Any] {
        return [
            "id": id,
            "name": name,
            "description": description,
            "creatorId": creatorId,
            "members": members.map { $0.firestoreData },
            "settings": settings.firestoreData,
            "invitationCode": invitationCode,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt)
        ]
    }
    
    init?(from document: DocumentSnapshot) {
        guard let data = document.data() else { return nil }
        
        self.id = data["id"] as? String ?? ""
        self.name = data["name"] as? String ?? ""
        self.description = data["description"] as? String ?? ""
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
}

extension GroupMember {
    var firestoreData: [String: Any] {
        return [
            "userId": userId,
            "role": role.rawValue,
            "joinedAt": Timestamp(date: joinedAt),
            "lastActive": Timestamp(date: lastActive)
        ]
    }
    
    init?(from data: [String: Any]) {
        guard let userId = data["userId"] as? String,
              let roleString = data["role"] as? String,
              let role = GroupRole(rawValue: roleString) else { return nil }
        
        self.userId = userId
        self.role = role
        self.joinedAt = (data["joinedAt"] as? Timestamp)?.dateValue() ?? Date()
        self.lastActive = (data["lastActive"] as? Timestamp)?.dateValue() ?? Date()
    }
}

extension GroupSettings {
    var firestoreData: [String: Any] {
        return [
            "isPublic": isPublic,
            "allowInvitations": allowInvitations,
            "shareProgress": shareProgress,
            "allowChallenges": allowChallenges,
            "notificationSettings": notificationSettings
        ]
    }
    
    init(from data: [String: Any]) {
        self.isPublic = data["isPublic"] as? Bool ?? false
        self.allowInvitations = data["allowInvitations"] as? Bool ?? true
        self.shareProgress = data["shareProgress"] as? Bool ?? true
        self.allowChallenges = data["allowChallenges"] as? Bool ?? true
        self.notificationSettings = data["notificationSettings"] as? [String: Bool] ?? [:]
    }
    
    // MARK: - Group Comments and Feedback
    func addComment(to targetType: CommentTargetType, targetId: String, content: String, groupId: String, authorId: String, parentCommentId: String? = nil) async throws {
        let comment = GroupComment(groupId: groupId, authorId: authorId, targetType: targetType, targetId: targetId, content: content, parentCommentId: parentCommentId)
        
        try await db.collection("groups").document(groupId).collection("comments").document(comment.id).setData([
            "id": comment.id,
            "groupId": comment.groupId,
            "authorId": comment.authorId,
            "targetType": comment.targetType.rawValue,
            "targetId": comment.targetId,
            "content": comment.content,
            "createdAt": Timestamp(date: comment.createdAt),
            "updatedAt": Timestamp(date: comment.updatedAt),
            "parentCommentId": comment.parentCommentId ?? "",
            "reactions": comment.reactions.map { reaction in
                [
                    "id": reaction.id,
                    "userId": reaction.userId,
                    "type": reaction.type.rawValue,
                    "createdAt": Timestamp(date: reaction.createdAt)
                ]
            }
        ])
        
        // Update local state
        if groupComments[targetId] == nil {
            groupComments[targetId] = []
        }
        groupComments[targetId]?.append(comment)
    }
    
    func loadComments(for targetId: String, groupId: String) async throws {
        let snapshot = try await db.collection("groups").document(groupId).collection("comments")
            .whereField("targetId", isEqualTo: targetId)
            .order(by: "createdAt", descending: false)
            .getDocuments()
        
        let comments = snapshot.documents.compactMap { doc -> GroupComment? in
            let data = doc.data()
            return GroupComment(
                id: data["id"] as? String ?? "",
                groupId: data["groupId"] as? String ?? "",
                authorId: data["authorId"] as? String ?? "",
                targetType: CommentTargetType(rawValue: data["targetType"] as? String ?? "") ?? .goal,
                targetId: data["targetId"] as? String ?? "",
                content: data["content"] as? String ?? "",
                createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date(),
                parentCommentId: data["parentCommentId"] as? String,
                reactions: (data["reactions"] as? [[String: Any]] ?? []).compactMap { reactionData in
                    guard let id = reactionData["id"] as? String,
                          let userId = reactionData["userId"] as? String,
                          let typeString = reactionData["type"] as? String,
                          let type = ReactionType(rawValue: typeString),
                          let createdAt = (reactionData["createdAt"] as? Timestamp)?.dateValue() else {
                        return nil
                    }
                    return CommentReaction(id: id, userId: userId, type: type, createdAt: createdAt)
                }
            )
        }
        
        groupComments[targetId] = comments
    }
    
    func addReactionToComment(commentId: String, groupId: String, userId: String, reactionType: ReactionType) async throws {
        let reaction = CommentReaction(userId: userId, type: reactionType)
        
        try await db.collection("groups").document(groupId).collection("comments").document(commentId).updateData([
            "reactions": FieldValue.arrayUnion([[
                "id": reaction.id,
                "userId": reaction.userId,
                "type": reaction.type.rawValue,
                "createdAt": Timestamp(date: reaction.createdAt)
            ]])
        ])
    }
    
    // MARK: - Full Sync Management
    func createFullSyncShare(ownerId: String, groupId: String, sharedWithUserId: String, permissions: SyncPermissions, expiresAt: Date? = nil) async throws -> FullSyncShare {
        let syncShare = FullSyncShare(ownerId: ownerId, groupId: groupId, sharedWithUserId: sharedWithUserId, permissions: permissions, expiresAt: expiresAt)
        
        try await db.collection("fullSyncShares").document(syncShare.id).setData([
            "id": syncShare.id,
            "ownerId": syncShare.ownerId,
            "groupId": syncShare.groupId,
            "sharedWithUserId": syncShare.sharedWithUserId,
            "permissions": [
                "canViewGoals": permissions.canViewGoals,
                "canViewEvents": permissions.canViewEvents,
                "canViewTasks": permissions.canViewTasks,
                "canViewNotes": permissions.canViewNotes,
                "canViewKIs": permissions.canViewKIs,
                "canViewDashboard": permissions.canViewDashboard
            ],
            "createdAt": Timestamp(date: syncShare.createdAt),
            "expiresAt": syncShare.expiresAt != nil ? Timestamp(date: syncShare.expiresAt!) : nil,
            "isActive": syncShare.isActive
        ])
        
        fullSyncShares.append(syncShare)
        return syncShare
    }
    
    func loadFullSyncShares(for userId: String) async throws {
        let snapshot = try await db.collection("fullSyncShares")
            .whereField("sharedWithUserId", isEqualTo: userId)
            .whereField("isActive", isEqualTo: true)
            .getDocuments()
        
        let shares = snapshot.documents.compactMap { doc -> FullSyncShare? in
            let data = doc.data()
            let permissionsData = data["permissions"] as? [String: Bool] ?? [:]
            let permissions = SyncPermissions(
                canViewGoals: permissionsData["canViewGoals"] ?? true,
                canViewEvents: permissionsData["canViewEvents"] ?? true,
                canViewTasks: permissionsData["canViewTasks"] ?? true,
                canViewNotes: permissionsData["canViewNotes"] ?? true,
                canViewKIs: permissionsData["canViewKIs"] ?? true,
                canViewDashboard: permissionsData["canViewDashboard"] ?? true
            )
            
            return FullSyncShare(
                id: data["id"] as? String ?? "",
                ownerId: data["ownerId"] as? String ?? "",
                groupId: data["groupId"] as? String ?? "",
                sharedWithUserId: data["sharedWithUserId"] as? String ?? "",
                permissions: permissions,
                createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                expiresAt: (data["expiresAt"] as? Timestamp)?.dateValue(),
                isActive: data["isActive"] as? Bool ?? true
            )
        }
        
        fullSyncShares = shares
    }
    
    func revokeFullSyncShare(shareId: String) async throws {
        try await db.collection("fullSyncShares").document(shareId).updateData([
            "isActive": false
        ])
        
        fullSyncShares.removeAll { $0.id == shareId }
    }
    
    // MARK: - Group Task Assignment
    func assignTask(groupId: String, assignedById: String, assignedToId: String, taskId: String, goalId: String? = nil, dueDate: Date, priority: TaskPriority = .medium, notes: String? = nil) async throws -> GroupTaskAssignment {
        let assignment = GroupTaskAssignment(groupId: groupId, assignedById: assignedById, assignedToId: assignedToId, taskId: taskId, goalId: goalId, dueDate: dueDate, priority: priority, notes: notes)
        
        try await db.collection("groups").document(groupId).collection("taskAssignments").document(assignment.id).setData([
            "id": assignment.id,
            "groupId": assignment.groupId,
            "assignedById": assignment.assignedById,
            "assignedToId": assignment.assignedToId,
            "taskId": assignment.taskId,
            "goalId": assignment.goalId ?? "",
            "dueDate": Timestamp(date: assignment.dueDate),
            "priority": assignment.priority.rawValue,
            "status": assignment.status.rawValue,
            "createdAt": Timestamp(date: assignment.createdAt),
            "completedAt": assignment.completedAt != nil ? Timestamp(date: assignment.completedAt!) : nil,
            "notes": assignment.notes ?? ""
        ])
        
        groupTaskAssignments.append(assignment)
        return assignment
    }
    
    func updateTaskAssignmentStatus(assignmentId: String, status: AssignmentStatus) async throws {
        let completedAt = status == .completed ? Date() : nil
        
        try await db.collection("taskAssignments").document(assignmentId).updateData([
            "status": status.rawValue,
            "completedAt": completedAt != nil ? Timestamp(date: completedAt!) : nil
        ])
        
        if let index = groupTaskAssignments.firstIndex(where: { $0.id == assignmentId }) {
            groupTaskAssignments[index].status = status
            groupTaskAssignments[index].completedAt = completedAt
        }
    }
    
    func loadTaskAssignments(for groupId: String) async throws {
        let snapshot = try await db.collection("groups").document(groupId).collection("taskAssignments")
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        let assignments = snapshot.documents.compactMap { doc -> GroupTaskAssignment? in
            let data = doc.data()
            return GroupTaskAssignment(
                id: data["id"] as? String ?? "",
                groupId: data["groupId"] as? String ?? "",
                assignedById: data["assignedById"] as? String ?? "",
                assignedToId: data["assignedToId"] as? String ?? "",
                taskId: data["taskId"] as? String ?? "",
                goalId: data["goalId"] as? String,
                dueDate: (data["dueDate"] as? Timestamp)?.dateValue() ?? Date(),
                priority: TaskPriority(rawValue: data["priority"] as? String ?? "") ?? .medium,
                status: AssignmentStatus(rawValue: data["status"] as? String ?? "") ?? .pending,
                createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                completedAt: (data["completedAt"] as? Timestamp)?.dateValue(),
                notes: data["notes"] as? String
            )
        }
        
        groupTaskAssignments = assignments
    }
}