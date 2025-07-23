import Foundation
import Firebase
import Combine

// MARK: - Collaboration Manager
@MainActor
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
            type: .district
        )
        
        // Set the description in group settings
        if !description.isEmpty {
            group.settings.description = description
        }
        
        // Add creator as admin member
        group.members.append(GroupMember(userId: creatorId, role: .admin))
        
        try await db.collection("accountabilityGroups").document(group.id).setData(group.toFirestoreData())
        
        print("✅ CollaborationManager: Created group '\(group.name)' with ID: \(group.id)")
        print("✅ CollaborationManager: Group invite code: \(group.inviteCode)")
        
        return group
    }
    
    func joinGroup(groupId: String, userId: String, invitationCode: String) async throws {
        // Verify invitation code
        let groupDoc = try await db.collection("accountabilityGroups").document(groupId).getDocument()
        guard AccountabilityGroup(from: groupDoc) != nil else {
            throw CollaborationError.groupNotFound
        }
        
        // TODO: Implement invitation code validation
        // For now, allow joining without code validation
        
        // Add user to group
        let member = GroupMember(userId: userId, role: .member)
        try await db.collection("accountabilityGroups").document(groupId).updateData([
            "members": FieldValue.arrayUnion([member.toFirestoreData()])
        ])
        
        // Add to user's groups
        try await addUserToGroup(userId: userId, groupId: groupId, role: .member)
    }
    
    func joinGroupWithInviteCode(inviteCode: String, userId: String) async throws {
        print("🔗 CollaborationManager: Attempting to join group with invite code: \(inviteCode)")
        
        // Look up group by invite code
        let snapshot = try await db.collection("accountabilityGroups")
            .whereField("inviteCode", isEqualTo: inviteCode.uppercased())
            .getDocuments()
        
        guard let document = snapshot.documents.first else {
            print("❌ CollaborationManager: No group found with invite code: \(inviteCode)")
            throw CollaborationError.invalidInviteCode
        }
        
        guard let group = AccountabilityGroup(from: document) else {
            print("❌ CollaborationManager: Failed to decode group from document")
            throw CollaborationError.groupNotFound
        }
        
        print("✅ CollaborationManager: Found group: \(group.name) with \(group.members.count) members")
        
        // Check if user is already a member
        if group.members.contains(where: { $0.userId == userId }) {
            print("❌ CollaborationManager: User \(userId) is already a member of group \(group.id)")
            throw CollaborationError.alreadyMember
        }
        
        // Add user to group
        let member = GroupMember(userId: userId, role: .member)
        try await db.collection("accountabilityGroups").document(group.id).updateData([
            "members": FieldValue.arrayUnion([member.toFirestoreData()])
        ])
        
        print("✅ CollaborationManager: Successfully added user \(userId) to group \(group.id)")
        
        // Add to user's groups
        try await addUserToGroup(userId: userId, groupId: group.id, role: .member)
    }
    
    func leaveGroup(groupId: String, userId: String) async throws {
        // Remove from group members
        let groupRef = db.collection("accountabilityGroups").document(groupId)
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
    
    func shareProgress(groupId: String, userId: String, type: ProgressShareType, data: [String: String]) async throws {
        let progressShare = ProgressShare(
            id: UUID().uuidString,
            userId: userId,
            groupId: groupId,
            type: type,
            data: data,
            timestamp: Date()
        )
        
        try await db.collection("accountabilityGroups").document(groupId)
            .collection("progress_shares").document(progressShare.id)
            .setData(progressShare.toFirestoreData())
        
        // Send notification to group members
        await notifyGroupMembers(groupId: groupId, notification: GroupNotification(
            type: .progressUpdate,
            fromUserId: userId,
            message: "\(userId) shared progress",
            data: ["progressId": progressShare.id]
        ))
    }
    
    func getGroupProgress(groupId: String) async throws -> [ProgressShare] {
        let snapshot = try await db.collection("accountabilityGroups").document(groupId)
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
        
        try await db.collection("accountabilityGroups").document(groupId)
            .collection("challenges").document(newChallenge.id)
            .setData(newChallenge.toFirestoreData())
        
        // Notify group members
        await notifyGroupMembers(
            groupId: groupId, 
            notification: GroupNotification(
                type: .challengeCreated,
                fromUserId: creatorId,
                message: "New challenge: \(challenge.title)",
                data: ["challengeId": newChallenge.id]
            )
        )
    }
    
    func joinChallenge(groupId: String, challengeId: String, userId: String) async throws {
        let challengeRef = db.collection("accountabilityGroups").document(groupId)
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
            await notifyGroupMembers(
                groupId: groupId, 
                notification: GroupNotification(
                    type: .challengeCompleted,
                    fromUserId: userId,
                    message: "\(userId) completed the challenge!",
                    data: ["challengeId": challengeId]
                )
            )
        }
    }
    
    // MARK: - Real-time Listeners
    
    func startListeningToUserGroups(userId: String) {
        print("🔍 CollaborationManager: Starting listener for user groups with userId: \(userId)")
        
        // Listen to accountabilityGroups collection where user is a member
        let listener = db.collection("accountabilityGroups")
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("❌ CollaborationManager: Error listening to user groups: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else { 
                    print("📊 CollaborationManager: No group documents found")
                    return 
                }
                
                print("📊 CollaborationManager: Found \(documents.count) total groups in database")
                
                let groups = documents.compactMap { doc -> AccountabilityGroup? in
                        // Try to create AccountabilityGroup from document
                        guard let group = AccountabilityGroup(from: doc) else {
                            print("❌ CollaborationManager: Failed to decode group from document \(doc.documentID)")
                            return nil
                        }
                        
                        // Filter groups where user is a member
                        let isMember = group.members.contains { member in
                            member.userId == userId
                        }
                        
                        if isMember {
                            print("✅ CollaborationManager: User is member of group: \(group.name) (ID: \(group.id))")
                            return group
                        } else {
                            print("⏭️ CollaborationManager: User not member of group: \(group.name)")
                        return nil
                    }
                }
                
                print("✅ CollaborationManager: Found \(groups.count) groups where user is a member")
                
                // Check for groups that need invite code updates
                Task {
                    await self?.updateGroupsWithMissingInviteCodes(documents: documents)
                }
                
                DispatchQueue.main.async {
                    self?.currentUserGroups = groups
                    print("🔄 CollaborationManager: Updated currentUserGroups with \(groups.count) groups")
                    
                    // Debug: Print group names
                    for group in groups {
                        print("   - \(group.name) (Members: \(group.members.count))")
                    }
                }
            }
        
        listeners.append(listener)
        print("✅ CollaborationManager: Group listener added successfully")
    }
    
    private func updateGroupsWithMissingInviteCodes(documents: [QueryDocumentSnapshot]) async {
        for doc in documents {
            let data = doc.data()
            // "inviteCode": inviteCode, // Commented out because inviteCode is not in scope
            if (data["inviteCode"] as? String)?.isEmpty == true {
                // Generate new invite code and update the group
                let newInviteCode = String((0..<6).map { _ in "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".randomElement()! })
                try? await db.collection("accountabilityGroups").document(doc.documentID).updateData([
                    "inviteCode": newInviteCode,
                    "updatedAt": Timestamp(date: Date())
                ])
                print("✅ CollaborationManager: Generated invite code for group \(doc.documentID)")
            }
        }
    }
    
    func startListeningToGroupProgress(groupId: String) {
        let listener = db.collection("accountabilityGroups").document(groupId)
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
        let listener = db.collection("accountabilityGroups").document(groupId)
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
        let groupDoc = try await db.collection("accountabilityGroups").document(groupId).getDocument()
        guard let group = AccountabilityGroup(from: groupDoc) else { return nil }
        
        return group.members.first { $0.userId == userId }?.role
    }
    
    func canUserAccessGroupData(groupId: String, userId: String) async throws -> Bool {
        let role = try await getUserRoleInGroup(groupId: groupId, userId: userId)
        return role != nil
    }
    
    func canUserModifyGroupData(groupId: String, userId: String) async throws -> Bool {
        let role = try await getUserRoleInGroup(groupId: groupId, userId: userId)
        return role == .admin || role == .leader
    }
    
    // MARK: - Private Helpers
    
    private func addUserToGroup(userId: String, groupId: String, role: GroupRole) async throws {
        // Add user to the group's members array
        let member = GroupMember(userId: userId, role: role)
        try await db.collection("accountabilityGroups").document(groupId)
            .updateData([
                "members": FieldValue.arrayUnion([member.toFirestoreData()])
            ])
    }
    
    private func removeUserFromGroup(userId: String, groupId: String) async throws {
        // Get current group data
        let groupDoc = try await db.collection("accountabilityGroups").document(groupId).getDocument()
        guard var group = AccountabilityGroup(from: groupDoc) else {
            throw CollaborationError.groupNotFound
        }
        
        // Remove user from members array
        group.members.removeAll { $0.userId == userId }
        
        // Update the group
        try await db.collection("accountabilityGroups").document(groupId)
            .updateData([
                "members": group.members.map { $0.toFirestoreData() }
            ])
    }
    
    private func fetchUserGroups(groupIds: [String]) {
        Task {
            var groups: [AccountabilityGroup] = []
            
            for groupId in groupIds {
                do {
                    let doc = try await db.collection("accountabilityGroups").document(groupId).getDocument()
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
    
    private func notifyGroupMembers(groupId: String, notification: GroupNotification) async {
        // Get group members
        guard let group = await getGroup(groupId: groupId) else {
            print("❌ CollaborationManager: Group not found for notification")
            return
        }
        
        // Send notification to each member (except the sender)
        for member in group.members {
            if member.userId != notification.fromUserId {
                // In a real implementation, this would send push notifications
                print("📧 CollaborationManager: Would notify user \(member.userId) about \(notification.type.rawValue)")
            }
        }
    }
    
    private func getGroup(groupId: String) async -> AccountabilityGroup? {
        do {
            let doc = try await db.collection("accountabilityGroups").document(groupId).getDocument()
            return AccountabilityGroup(from: doc)
        } catch {
            print("❌ CollaborationManager: Error fetching group \(groupId): \(error)")
            return nil
        }
    }
    
    // MARK: - Listener Management
    
    func stopAllListeners() {
        print("🛑 CollaborationManager: Stopping \(listeners.count) listeners")
        for listener in listeners {
            listener.remove()
        }
        listeners.removeAll()
    }
    
    // MARK: - User Search & Invitations
    
    func searchUsers(query: String) async throws -> [UserSuggestion] {
        guard query.count >= 2 else { return [] }
        
        print("🔍 CollaborationManager: Searching users with query: \(query)")
        
        // Search by name (case-insensitive)
        let nameSnapshot = try await db.collection("users")
            .whereField("name", isGreaterThanOrEqualTo: query)
            .whereField("name", isLessThan: query + "\u{f8ff}")
            .limit(to: 10)
            .getDocuments()
        
        // Search by email (exact match)
        let emailSnapshot = try await db.collection("users")
            .whereField("email", isEqualTo: query.lowercased())
            .limit(to: 5)
            .getDocuments()
        
        var users: Set<UserSuggestion> = []
        
        // Process name search results
        for doc in nameSnapshot.documents {
            if let user = UserSuggestion(from: doc) {
                users.insert(user)
            }
        }
        
        // Process email search results
        for doc in emailSnapshot.documents {
            if let user = UserSuggestion(from: doc) {
                users.insert(user)
            }
        }
        
        print("✅ CollaborationManager: Found \(users.count) users")
        return Array(users).sorted { $0.name < $1.name }
    }
    
    // MARK: - Group Invitations
    
    func sendGroupInvitation(groupId: String, fromUserId: String, toUserId: String, message: String? = nil) async throws {
        print("📧 CollaborationManager: Sending group invitation from \(fromUserId) to \(toUserId)")
        
        let invitation = GroupInvitation(
            id: UUID().uuidString,
            groupId: groupId,
            groupName: "Group", // Will be updated with actual group name
            fromUserId: fromUserId,
            toUserId: toUserId,
            message: message ?? "You've been invited to join a group!",
            status: .pending
        )
        
        try await db.collection("group_invitations").document(invitation.id).setData(invitation.toFirestoreData())
        
        // Send notification to invited user
        await notifyGroupMembers(groupId: groupId, notification: GroupNotification(
            type: .memberJoined, // Using existing type
            fromUserId: fromUserId,
            message: "You've been invited to join a group",
            data: ["invitationId": invitation.id, "groupId": groupId]
        ))
        
        print("✅ CollaborationManager: Group invitation sent successfully")
    }
    
    func acceptGroupInvitation(invitationId: String, userId: String) async throws {
        print("✅ CollaborationManager: Accepting group invitation \(invitationId)")
        
        // Get invitation
        let invitationDoc = try await db.collection("group_invitations").document(invitationId).getDocument()
        guard let invitation = GroupInvitation(from: invitationDoc) else {
            throw CollaborationError.invitationNotFound
        }
        
        // Verify invitation is for this user and still pending
        guard invitation.toUserId == userId && invitation.status == .pending else {
            throw CollaborationError.invalidInvitation
        }
        
        // Update invitation status
        try await db.collection("group_invitations").document(invitationId).updateData([
            "status": "accepted",
            "acceptedAt": Timestamp(date: Date())
        ])
        
            // Add user to group
            try await joinGroup(groupId: invitation.groupId, userId: userId, invitationCode: "")
        
        // Notify group members
        await notifyGroupMembers(groupId: invitation.groupId, notification: GroupNotification(
            type: .memberJoined,
            fromUserId: userId,
            message: "A new member joined the group",
            data: ["userId": userId]
        ))
        
        print("✅ CollaborationManager: Group invitation accepted successfully")
    }
    
    func declineGroupInvitation(invitationId: String, userId: String) async throws {
        print("❌ CollaborationManager: Declining group invitation \(invitationId)")
        
        // Get invitation
        let invitationDoc = try await db.collection("group_invitations").document(invitationId).getDocument()
        guard let invitation = GroupInvitation(from: invitationDoc) else {
            throw CollaborationError.invitationNotFound
        }
        
        // Verify invitation is for this user and still pending
        guard invitation.toUserId == userId && invitation.status == .pending else {
            throw CollaborationError.invalidInvitation
        }
        
        // Update invitation status
        try await db.collection("group_invitations").document(invitationId).updateData([
            "status": "declined",
            "declinedAt": Timestamp(date: Date())
        ])
        
        // Notify inviter
        await notifyGroupMembers(groupId: invitation.groupId, notification: GroupNotification(
            type: .memberLeft, // Using existing type
            fromUserId: userId,
            message: "Your group invitation was declined",
            data: ["invitationId": invitationId, "groupId": invitation.groupId]
        ))
        
        print("✅ CollaborationManager: Group invitation declined successfully")
    }
    
    func getUserInvitations(userId: String) async throws -> [GroupInvitation] {
        let snapshot = try await db.collection("group_invitations")
            .whereField("toUserId", isEqualTo: userId)
            .whereField("status", isEqualTo: "pending")
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { GroupInvitation(from: $0) }
    }
    
    // MARK: - Public Invite Links
    
    func generatePublicInviteLink(groupId: String, fromUserId: String, expiresInDays: Int = 7) async throws -> String {
        guard let group = await getGroup(groupId: groupId) else {
            throw CollaborationError.groupNotFound
        }
        
        // Verify user has permission to create invite links
        guard group.members.contains(where: { $0.userId == fromUserId && ($0.role == .admin || $0.role == .leader) }) else {
            throw CollaborationError.unauthorized
        }
        
        // Create invite link data
        let inviteLink = PublicInviteLink(
            groupId: groupId,
            groupName: group.name,
            createdBy: fromUserId,
            expiresAt: Calendar.current.date(byAdding: .day, value: expiresInDays, to: Date()) ?? Date().addingTimeInterval(86400 * 7),
            inviteCode: group.inviteCode
        )
        
        // Save to Firestore
        try await db.collection("public_invite_links").document(inviteLink.id)
            .setData(inviteLink.toFirestoreData())
        
        // Generate deep link URL
        let baseURL = "https://areabook.app/invite"
        let inviteURL = "\(baseURL)?code=\(group.inviteCode)&group=\(groupId)&link=\(inviteLink.id)"
        
        print("✅ CollaborationManager: Generated public invite link for group \(group.name)")
        return inviteURL
    }
    
    func processPublicInviteLink(url: URL, userId: String?) async throws -> PublicInviteLinkInfo {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            throw CollaborationError.invalidInviteLink
        }
        
        guard let inviteCode = queryItems.first(where: { $0.name == "code" })?.value,
              let groupId = queryItems.first(where: { $0.name == "group" })?.value,
              let linkId = queryItems.first(where: { $0.name == "link" })?.value else {
            throw CollaborationError.invalidInviteLink
        }
        
        // Verify invite link exists and is valid
        let linkDoc = try await db.collection("public_invite_links").document(linkId).getDocument()
        guard let data = linkDoc.data() else {
            throw CollaborationError.inviteLinkExpired
        }
        
        let inviteLink = PublicInviteLink(
            id: data["id"] as? String ?? linkId,
            groupId: data["groupId"] as? String ?? "",
            groupName: data["groupName"] as? String ?? "",
            createdBy: data["createdBy"] as? String ?? "",
            expiresAt: (data["expiresAt"] as? Timestamp)?.dateValue() ?? Date(),
            inviteCode: data["inviteCode"] as? String ?? ""
        )
        
        // Check if expired
        if inviteLink.expiresAt < Date() {
            throw CollaborationError.inviteLinkExpired
        }
        
        // Get group info
        guard let group = await getGroup(groupId: groupId) else {
            throw CollaborationError.groupNotFound
        }
        
        // If user is logged in, check if already a member
        var userStatus: PublicInviteLinkInfo.UserStatus = .notLoggedIn
        if let userId = userId {
            if group.members.contains(where: { $0.userId == userId }) {
                userStatus = .alreadyMember
            } else {
                userStatus = .canJoin
            }
        }
        
        return PublicInviteLinkInfo(
            groupId: groupId,
            groupName: group.name,
            memberCount: group.members.count,
            inviteCode: inviteCode,
            userStatus: userStatus,
            needsAppDownload: userId == nil
        )
    }
    
    func joinGroupViaPublicLink(inviteCode: String, userId: String) async throws {
        // Use existing invite code logic
        try await joinGroupWithInviteCode(inviteCode: inviteCode, userId: userId)
    }
    
    // MARK: - Notification Helpers
    
    private func sendInvitationNotification(invitation: GroupInvitation) async throws {
        // Get recipient user data for FCM token
        let userDoc = try await db.collection("users").document(invitation.toUserId).getDocument()
        guard let userData = userDoc.data(),
              let fcmToken = userData["fcmToken"] as? String else {
            print("⚠️ CollaborationManager: No FCM token found for user \(invitation.toUserId)")
            return
        }
        
        // Create notification payload
        let notification: [String: Any] = [
            "to": fcmToken,
            "notification": [
                "title": "Group Invitation",
                "body": invitation.message,
                "sound": "default"
            ],
            "data": [
                "type": "group_invitation",
                "invitationId": invitation.id,
                "groupId": invitation.groupId,
                "groupName": invitation.groupName
            ]
        ]
        
        // Send via Firebase Cloud Messaging
        // Note: In production, this would be handled by a server endpoint
        print("📧 CollaborationManager: Would send notification to \(invitation.toUserId)")
        _ = notification // Suppress unused warning
    }
    
    // MARK: - Real-time Listeners
}