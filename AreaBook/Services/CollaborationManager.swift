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
    
    private var db = Firestore.firestore()
    private var listeners: [ListenerRegistration] = []
    
    private init() {}
    
    // MARK: - Group Management
    
    func createGroup(name: String, description: String, creatorId: String) async throws -> AccountabilityGroup {
        var group = AccountabilityGroup(
            name: name,
            description: description,
            type: .district,
            creatorId: creatorId
        )
        group.members = [GroupMember(userId: creatorId, role: .admin)]
        
        try await db.collection("groups").document(group.id).setData(group.toFirestoreData())
        
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
        let member = GroupMember(userId: userId, role: .member)
        try await db.collection("groups").document(groupId).updateData([
            "members": FieldValue.arrayUnion([member.toFirestoreData()])
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
            "members": group.members.map { $0.toFirestoreData() }
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
            .setData(progressShare.toFirestoreData())
        
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
            .setData(newChallenge.toFirestoreData())
        
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
                .setData(notification.toFirestoreData())
        }
    }
    
    func stopAllListeners() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }
}

// MARK: - Supporting Types

enum CollaborationError: Error {
    case groupNotFound
    case invalidInvitationCode
    case insufficientPermissions
    case userNotInGroup
    case challengeNotFound
}

