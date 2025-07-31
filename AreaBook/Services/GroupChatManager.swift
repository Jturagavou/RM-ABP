import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

// MARK: - Group Chat Manager
@MainActor
class GroupChatManager: ObservableObject {
    static let shared = GroupChatManager()
    
    @Published var conversations: [GroupConversation] = []
    @Published var currentGroupMessages: [GroupChatMessage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedGroupId: String?
    
    private var db = Firestore.firestore()
    private var conversationListeners: [ListenerRegistration] = []
    private var messageListeners: [String: ListenerRegistration] = []
    
    private init() {}
    
    // MARK: - Conversation Management
    
    /// Start listening to user's group conversations
    func startListeningToConversations(userId: String) {
        print("🗨️ GroupChatManager: Starting conversation listeners for user: \(userId)")
        
        // Listen to groups where user is a member
        let listener = db.collection("accountabilityGroups")
            .whereField("members", arrayContains: ["userId": userId])
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("❌ GroupChatManager: Error listening to conversations: \(error)")
                    self?.errorMessage = "Failed to load conversations"
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("📭 GroupChatManager: No conversations found")
                    return
                }
                
                Task {
                    await self?.updateConversations(from: documents, userId: userId)
                }
            }
        
        conversationListeners.append(listener)
    }
    
    private func updateConversations(from documents: [QueryDocumentSnapshot], userId: String) async {
        var conversations: [GroupConversation] = []
        
        for doc in documents {
            if let group = AccountabilityGroup(from: doc) {
                let participantIds = group.members.map { $0.userId }
                var conversation = GroupConversation(
                    groupId: group.id,
                    groupName: group.name,
                    participantIds: participantIds
                )
                
                // Get last message and unread count
                do {
                    let (lastMessage, unreadCount) = try await getConversationSummary(groupId: group.id, userId: userId)
                    conversation.lastMessage = lastMessage
                    conversation.unreadCount = unreadCount
                    conversation.lastActivity = lastMessage?.createdAt ?? Date()
                } catch {
                    print("⚠️ GroupChatManager: Failed to get conversation summary for \(group.id): \(error)")
                }
                
                conversations.append(conversation)
            }
        }
        
        // Sort by last activity
        conversations.sort { $0.lastActivity > $1.lastActivity }
        
        self.conversations = conversations
        print("✅ GroupChatManager: Updated conversations: \(conversations.count)")
    }
    
    private func getConversationSummary(groupId: String, userId: String) async throws -> (GroupChatMessage?, Int) {
        // Get last message
        let lastMessageQuery = db.collection("groupMessages")
            .whereField("groupId", isEqualTo: groupId)
            .whereField("isDeleted", isEqualTo: false)
            .order(by: "createdAt", descending: true)
            .limit(to: 1)
        
        let lastMessageSnapshot = try await lastMessageQuery.getDocuments()
        let lastMessage = lastMessageSnapshot.documents.first.flatMap { GroupChatMessage(from: $0) }
        
        // Count unread messages (simplified - in real app, you'd track read status per user)
        let unreadQuery = db.collection("groupMessages")
            .whereField("groupId", isEqualTo: groupId)
            .whereField("senderId", isNotEqualTo: userId)
            .whereField("isDeleted", isEqualTo: false)
            .order(by: "createdAt", descending: true)
            .limit(to: 50) // Check last 50 messages
        
        let unreadSnapshot = try await unreadQuery.getDocuments()
        let unreadCount = unreadSnapshot.documents.count // Simplified count
        
        return (lastMessage, min(unreadCount, 99)) // Cap at 99
    }
    
    // MARK: - Message Management
    
    /// Start listening to messages for a specific group
    func startListeningToMessages(groupId: String) {
        print("💬 GroupChatManager: Starting message listener for group: \(groupId)")
        
        selectedGroupId = groupId
        
        // Stop existing listener for this group
        if let existingListener = messageListeners[groupId] {
            existingListener.remove()
        }
        
        let listener = db.collection("groupMessages")
            .whereField("groupId", isEqualTo: groupId)
            .whereField("isDeleted", isEqualTo: false)
            .order(by: "createdAt", descending: false)
            .limit(to: 100) // Limit to last 100 messages
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("❌ GroupChatManager: Error listening to messages: \(error)")
                    self?.errorMessage = "Failed to load messages"
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("📭 GroupChatManager: No messages found for group \(groupId)")
                    self?.currentGroupMessages = []
                    return
                }
                
                let messages = documents.compactMap { GroupChatMessage(from: $0) }
                self?.currentGroupMessages = messages
                print("✅ GroupChatManager: Loaded \(messages.count) messages for group \(groupId)")
            }
        
        messageListeners[groupId] = listener
    }
    
    /// Send a message to a group
    func sendMessage(
        groupId: String,
        content: String,
        messageType: ChatMessageType = .text,
        replyToMessageId: String? = nil,
        attachments: [MessageAttachment] = []
    ) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw GroupChatError.userNotFound
        }
        
        // Validate message
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw GroupChatError.messageTooLong
        }
        
        // Get group to extract member info for mentions
        let groupDoc = try await db.collection("accountabilityGroups").document(groupId).getDocument()
        guard let group = AccountabilityGroup(from: groupDoc) else {
            throw GroupChatError.groupNotFound
        }
        
        // Get sender info
        let userDoc = try await db.collection("users").document(currentUser.uid).getDocument()
        let userData = userDoc.data()
        let senderName = userData?["name"] as? String ?? "Unknown User"
        let senderAvatar = userData?["avatar"] as? String
        
        // Detect mentions
        let mentions = MentionDetector.detectMentions(in: content, availableUsers: group.members)
        
        // Create message
        let message = GroupChatMessage(
            groupId: groupId,
            senderId: currentUser.uid,
            senderName: senderName,
            senderAvatar: senderAvatar,
            content: content,
            messageType: messageType,
            mentions: mentions,
            replyToMessageId: replyToMessageId,
            attachments: attachments
        )
        
        // Save to Firestore
        try await db.collection("groupMessages").document(message.id).setData(message.toFirestoreData())
        
        // Update conversation last activity
        try await updateConversationLastActivity(groupId: groupId, lastMessage: message)
        
        // Send notifications for mentions
        try await sendMentionNotifications(message: message, group: group)
        
        print("✅ GroupChatManager: Sent message to group \(groupId)")
    }
    
    /// Edit a message
    func editMessage(messageId: String, newContent: String) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw GroupChatError.userNotFound
        }
        
        let messageRef = db.collection("groupMessages").document(messageId)
        let messageDoc = try await messageRef.getDocument()
        
        guard var message = GroupChatMessage(from: messageDoc) else {
            throw GroupChatError.messageNotFound
        }
        
        // Check permissions
        guard message.senderId == currentUser.uid else {
            throw GroupChatError.insufficientPermissions
        }
        
        // Update message
        message.content = newContent
        message.isEdited = true
        message.editedAt = Date()
        
        // Re-detect mentions in edited content
        let groupDoc = try await db.collection("accountabilityGroups").document(message.groupId).getDocument()
        if let group = AccountabilityGroup(from: groupDoc) {
            message.mentions = MentionDetector.detectMentions(in: newContent, availableUsers: group.members)
        }
        
        try await messageRef.updateData(message.toFirestoreData())
        
        print("✅ GroupChatManager: Edited message \(messageId)")
    }
    
    /// Delete a message
    func deleteMessage(messageId: String) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw GroupChatError.userNotFound
        }
        
        let messageRef = db.collection("groupMessages").document(messageId)
        let messageDoc = try await messageRef.getDocument()
        
        guard let message = GroupChatMessage(from: messageDoc) else {
            throw GroupChatError.messageNotFound
        }
        
        // Check permissions
        guard message.senderId == currentUser.uid else {
            throw GroupChatError.insufficientPermissions
        }
        
        try await messageRef.updateData([
            "isDeleted": true,
            "deletedAt": Timestamp(date: Date()),
            "content": "This message was deleted"
        ])
        
        print("✅ GroupChatManager: Deleted message \(messageId)")
    }
    
    /// Add reaction to a message
    func addReaction(messageId: String, emoji: String) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw GroupChatError.userNotFound
        }
        
        // Get user info
        let userDoc = try await db.collection("users").document(currentUser.uid).getDocument()
        let userData = userDoc.data()
        let userName = userData?["name"] as? String ?? "Unknown User"
        
        let reaction = MessageReaction(
            emoji: emoji,
            userId: currentUser.uid,
            userName: userName
        )
        
        try await db.collection("groupMessages").document(messageId).updateData([
            "reactions": FieldValue.arrayUnion([reaction.toFirestoreData()])
        ])
        
        print("✅ GroupChatManager: Added reaction \(emoji) to message \(messageId)")
    }
    
    /// Remove reaction from a message
    func removeReaction(messageId: String, emoji: String) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw GroupChatError.userNotFound
        }
        
        // Get user info
        let userDoc = try await db.collection("users").document(currentUser.uid).getDocument()
        let userData = userDoc.data()
        let userName = userData?["name"] as? String ?? "Unknown User"
        
        let reaction = MessageReaction(
            emoji: emoji,
            userId: currentUser.uid,
            userName: userName
        )
        
        try await db.collection("groupMessages").document(messageId).updateData([
            "reactions": FieldValue.arrayRemove([reaction.toFirestoreData()])
        ])
        
        print("✅ GroupChatManager: Removed reaction \(emoji) from message \(messageId)")
    }
    
    // MARK: - Private Helper Methods
    
    private func updateConversationLastActivity(groupId: String, lastMessage: GroupChatMessage) async throws {
        // Update conversation metadata
        try await db.collection("groupConversations").document(groupId).setData([
            "groupId": groupId,
            "lastActivity": Timestamp(date: lastMessage.createdAt),
            "lastMessage": [
                "id": lastMessage.id,
                "senderId": lastMessage.senderId,
                "senderName": lastMessage.senderName,
                "content": lastMessage.content,
                "messageType": lastMessage.messageType.rawValue,
                "createdAt": Timestamp(date: lastMessage.createdAt)
            ]
        ], merge: true)
    }
    
    private func sendMentionNotifications(message: GroupChatMessage, group: AccountabilityGroup) async throws {
        for mention in message.mentions {
            // Skip notifying the sender
            guard mention.userId != message.senderId else { continue }
            
            // Create notification
            let notification = [
                "userId": mention.userId,
                "type": "mention",
                "title": "You were mentioned in \(group.name)",
                "body": "\(message.senderName): \(message.content)",
                "data": [
                    "groupId": message.groupId,
                    "messageId": message.id,
                    "groupName": group.name
                ],
                "createdAt": Timestamp(date: Date())
            ]
            
            try await db.collection("notifications").addDocument(data: notification)
            
            print("📨 GroupChatManager: Sent mention notification to \(mention.userId)")
        }
    }
    
    // MARK: - Cleanup
    
    func stopAllListeners() {
        print("🛑 GroupChatManager: Stopping all listeners")
        
        for listener in conversationListeners {
            listener.remove()
        }
        conversationListeners.removeAll()
        
        for (_, listener) in messageListeners {
            listener.remove()
        }
        messageListeners.removeAll()
        
        conversations = []
        currentGroupMessages = []
        selectedGroupId = nil
    }
    
    func stopMessageListener(for groupId: String) {
        if let listener = messageListeners[groupId] {
            listener.remove()
            messageListeners.removeValue(forKey: groupId)
        }
        
        if selectedGroupId == groupId {
            currentGroupMessages = []
            selectedGroupId = nil
        }
    }
    
    // MARK: - Utility Methods
    
    /// Get available users for mentions in a group
    func getAvailableUsersForMentions(groupId: String) async throws -> [GroupMember] {
        let groupDoc = try await db.collection("accountabilityGroups").document(groupId).getDocument()
        guard let group = AccountabilityGroup(from: groupDoc) else {
            throw GroupChatError.groupNotFound
        }
        
        return group.members
    }
    
    /// Search messages in a group
    func searchMessages(in groupId: String, query: String) async throws -> [GroupChatMessage] {
        let snapshot = try await db.collection("groupMessages")
            .whereField("groupId", isEqualTo: groupId)
            .whereField("isDeleted", isEqualTo: false)
            .order(by: "createdAt", descending: true)
            .limit(to: 500)
            .getDocuments()
        
        let allMessages = snapshot.documents.compactMap { GroupChatMessage(from: $0) }
        
        // Filter by query
        let searchQuery = query.lowercased()
        return allMessages.filter { message in
            message.content.lowercased().contains(searchQuery) ||
            message.senderName.lowercased().contains(searchQuery)
        }
    }
    
    /// Mark messages as read for current user
    func markMessagesAsRead(groupId: String) async throws {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        // Update read status (simplified implementation)
        try await db.collection("userReadStatus").document("\(currentUser.uid)_\(groupId)").setData([
            "userId": currentUser.uid,
            "groupId": groupId,
            "lastReadAt": Timestamp(date: Date())
        ], merge: true)
        
        print("✅ GroupChatManager: Marked messages as read for group \(groupId)")
    }
}