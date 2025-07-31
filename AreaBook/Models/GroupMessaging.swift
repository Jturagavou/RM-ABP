import Foundation
import FirebaseFirestore

// MARK: - Group Messaging Models

struct GroupChatMessage: Identifiable, Codable {
    let id: String
    let groupId: String
    let senderId: String
    let senderName: String
    let senderAvatar: String?
    var content: String
    var messageType: ChatMessageType
    var mentions: [UserMention]
    var replyToMessageId: String?
    var attachments: [MessageAttachment]
    var reactions: [MessageReaction]
    var isEdited: Bool
    var isDeleted: Bool
    let createdAt: Date
    var editedAt: Date?
    var deletedAt: Date?
    
    init(
        groupId: String,
        senderId: String,
        senderName: String,
        senderAvatar: String? = nil,
        content: String,
        messageType: ChatMessageType = .text,
        mentions: [UserMention] = [],
        replyToMessageId: String? = nil,
        attachments: [MessageAttachment] = []
    ) {
        self.id = UUID().uuidString
        self.groupId = groupId
        self.senderId = senderId
        self.senderName = senderName
        self.senderAvatar = senderAvatar
        self.content = content
        self.messageType = messageType
        self.mentions = mentions
        self.replyToMessageId = replyToMessageId
        self.attachments = attachments
        self.reactions = []
        self.isEdited = false
        self.isDeleted = false
        self.createdAt = Date()
        self.editedAt = nil
        self.deletedAt = nil
    }
    
    // Firebase initialization
    init?(from document: DocumentSnapshot) {
        guard let data = document.data() else { return nil }
        
        self.id = data["id"] as? String ?? document.documentID
        self.groupId = data["groupId"] as? String ?? ""
        self.senderId = data["senderId"] as? String ?? ""
        self.senderName = data["senderName"] as? String ?? ""
        self.senderAvatar = data["senderAvatar"] as? String
        self.content = data["content"] as? String ?? ""
        self.messageType = ChatMessageType(rawValue: data["messageType"] as? String ?? "") ?? .text
        
        // Parse mentions
        if let mentionsData = data["mentions"] as? [[String: Any]] {
            self.mentions = mentionsData.compactMap { UserMention(dictionary: $0) }
        } else {
            self.mentions = []
        }
        
        self.replyToMessageId = data["replyToMessageId"] as? String
        
        // Parse attachments
        if let attachmentsData = data["attachments"] as? [[String: Any]] {
            self.attachments = attachmentsData.compactMap { MessageAttachment(dictionary: $0) }
        } else {
            self.attachments = []
        }
        
        // Parse reactions
        if let reactionsData = data["reactions"] as? [[String: Any]] {
            self.reactions = reactionsData.compactMap { MessageReaction(dictionary: $0) }
        } else {
            self.reactions = []
        }
        
        self.isEdited = data["isEdited"] as? Bool ?? false
        self.isDeleted = data["isDeleted"] as? Bool ?? false
        self.createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        self.editedAt = (data["editedAt"] as? Timestamp)?.dateValue()
        self.deletedAt = (data["deletedAt"] as? Timestamp)?.dateValue()
    }
    
    func toFirestoreData() -> [String: Any] {
        var data: [String: Any] = [
            "id": id,
            "groupId": groupId,
            "senderId": senderId,
            "senderName": senderName,
            "content": content,
            "messageType": messageType.rawValue,
            "mentions": mentions.map { $0.toFirestoreData() },
            "attachments": attachments.map { $0.toFirestoreData() },
            "reactions": reactions.map { $0.toFirestoreData() },
            "isEdited": isEdited,
            "isDeleted": isDeleted,
            "createdAt": Timestamp(date: createdAt)
        ]
        
        if let senderAvatar = senderAvatar {
            data["senderAvatar"] = senderAvatar
        }
        if let replyToMessageId = replyToMessageId {
            data["replyToMessageId"] = replyToMessageId
        }
        if let editedAt = editedAt {
            data["editedAt"] = Timestamp(date: editedAt)
        }
        if let deletedAt = deletedAt {
            data["deletedAt"] = Timestamp(date: deletedAt)
        }
        
        return data
    }
}

enum ChatMessageType: String, Codable, CaseIterable {
    case text = "text"
    case image = "image"
    case file = "file"
    case system = "system"
    case progressShare = "progressShare"
    case challengeUpdate = "challengeUpdate"
    case goalMilestone = "goalMilestone"
}

// MARK: - User Mention

struct UserMention: Codable {
    let userId: String
    let userName: String
    let startIndex: Int
    let length: Int
    
    init(userId: String, userName: String, startIndex: Int, length: Int) {
        self.userId = userId
        self.userName = userName
        self.startIndex = startIndex
        self.length = length
    }
    
    init?(dictionary: [String: Any]) {
        guard
            let userId = dictionary["userId"] as? String,
            let userName = dictionary["userName"] as? String,
            let startIndex = dictionary["startIndex"] as? Int,
            let length = dictionary["length"] as? Int
        else { return nil }
        
        self.userId = userId
        self.userName = userName
        self.startIndex = startIndex
        self.length = length
    }
    
    func toFirestoreData() -> [String: Any] {
        return [
            "userId": userId,
            "userName": userName,
            "startIndex": startIndex,
            "length": length
        ]
    }
}

// MARK: - Message Attachment

struct MessageAttachment: Identifiable, Codable {
    let id: String
    let fileName: String
    let fileSize: Int64
    let mimeType: String
    let url: String
    let thumbnailUrl: String?
    let uploadedAt: Date
    
    init(fileName: String, fileSize: Int64, mimeType: String, url: String, thumbnailUrl: String? = nil) {
        self.id = UUID().uuidString
        self.fileName = fileName
        self.fileSize = fileSize
        self.mimeType = mimeType
        self.url = url
        self.thumbnailUrl = thumbnailUrl
        self.uploadedAt = Date()
    }
    
    init?(dictionary: [String: Any]) {
        guard
            let id = dictionary["id"] as? String,
            let fileName = dictionary["fileName"] as? String,
            let fileSize = dictionary["fileSize"] as? Int64,
            let mimeType = dictionary["mimeType"] as? String,
            let url = dictionary["url"] as? String,
            let uploadedAt = (dictionary["uploadedAt"] as? Timestamp)?.dateValue()
        else { return nil }
        
        self.id = id
        self.fileName = fileName
        self.fileSize = fileSize
        self.mimeType = mimeType
        self.url = url
        self.thumbnailUrl = dictionary["thumbnailUrl"] as? String
        self.uploadedAt = uploadedAt
    }
    
    func toFirestoreData() -> [String: Any] {
        var data: [String: Any] = [
            "id": id,
            "fileName": fileName,
            "fileSize": fileSize,
            "mimeType": mimeType,
            "url": url,
            "uploadedAt": Timestamp(date: uploadedAt)
        ]
        
        if let thumbnailUrl = thumbnailUrl {
            data["thumbnailUrl"] = thumbnailUrl
        }
        
        return data
    }
}

// MARK: - Message Reaction

struct MessageReaction: Codable {
    let emoji: String
    let userId: String
    let userName: String
    let createdAt: Date
    
    init(emoji: String, userId: String, userName: String) {
        self.emoji = emoji
        self.userId = userId
        self.userName = userName
        self.createdAt = Date()
    }
    
    init?(dictionary: [String: Any]) {
        guard
            let emoji = dictionary["emoji"] as? String,
            let userId = dictionary["userId"] as? String,
            let userName = dictionary["userName"] as? String,
            let createdAt = (dictionary["createdAt"] as? Timestamp)?.dateValue()
        else { return nil }
        
        self.emoji = emoji
        self.userId = userId
        self.userName = userName
        self.createdAt = createdAt
    }
    
    func toFirestoreData() -> [String: Any] {
        return [
            "emoji": emoji,
            "userId": userId,
            "userName": userName,
            "createdAt": Timestamp(date: createdAt)
        ]
    }
}

// MARK: - Group Conversation Info

struct GroupConversation: Identifiable, Codable {
    let id: String // Same as groupId
    let groupId: String
    let groupName: String
    var lastMessage: GroupChatMessage?
    var lastActivity: Date
    var unreadCount: Int
    var participantIds: [String]
    var isActive: Bool
    
    init(groupId: String, groupName: String, participantIds: [String]) {
        self.id = groupId
        self.groupId = groupId
        self.groupName = groupName
        self.lastMessage = nil
        self.lastActivity = Date()
        self.unreadCount = 0
        self.participantIds = participantIds
        self.isActive = true
    }
    
    init?(from document: DocumentSnapshot) {
        guard let data = document.data() else { return nil }
        
        self.id = document.documentID
        self.groupId = data["groupId"] as? String ?? document.documentID
        self.groupName = data["groupName"] as? String ?? ""
        
        // Parse last message if exists
        if let lastMessageData = data["lastMessage"] as? [String: Any] {
            // Create a temporary document snapshot for the message
            let messageDoc = QueryDocumentSnapshot()
            // Note: This is a simplified approach - in real implementation,
            // you might store just the essential last message data
            self.lastMessage = nil // Will be populated separately
        } else {
            self.lastMessage = nil
        }
        
        self.lastActivity = (data["lastActivity"] as? Timestamp)?.dateValue() ?? Date()
        self.unreadCount = data["unreadCount"] as? Int ?? 0
        self.participantIds = data["participantIds"] as? [String] ?? []
        self.isActive = data["isActive"] as? Bool ?? true
    }
    
    func toFirestoreData() -> [String: Any] {
        var data: [String: Any] = [
            "groupId": groupId,
            "groupName": groupName,
            "lastActivity": Timestamp(date: lastActivity),
            "unreadCount": unreadCount,
            "participantIds": participantIds,
            "isActive": isActive
        ]
        
        // Store essential last message info only
        if let lastMessage = lastMessage {
            data["lastMessage"] = [
                "id": lastMessage.id,
                "senderId": lastMessage.senderId,
                "senderName": lastMessage.senderName,
                "content": lastMessage.content,
                "messageType": lastMessage.messageType.rawValue,
                "createdAt": Timestamp(date: lastMessage.createdAt)
            ]
        }
        
        return data
    }
}

// MARK: - Mention Detection Helper

struct MentionDetector {
    static func detectMentions(in text: String, availableUsers: [GroupMember]) -> [UserMention] {
        var mentions: [UserMention] = []
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        var currentIndex = 0
        
        for word in words {
            if word.hasPrefix("@") && word.count > 1 {
                let mentionText = String(word.dropFirst()) // Remove @
                
                // Find matching user
                if let user = availableUsers.first(where: { member in
                    member.userName.lowercased().contains(mentionText.lowercased()) ||
                    member.displayName.lowercased().contains(mentionText.lowercased())
                }) {
                    let mention = UserMention(
                        userId: user.userId,
                        userName: user.displayName,
                        startIndex: currentIndex,
                        length: word.count
                    )
                    mentions.append(mention)
                }
            }
            currentIndex += word.count + 1 // +1 for space
        }
        
        return mentions
    }
    
    static func formatMessageWithMentions(_ message: GroupChatMessage) -> AttributedString {
        var attributedString = AttributedString(message.content)
        
        // Apply mention formatting
        for mention in message.mentions.sorted(by: { $0.startIndex > $1.startIndex }) {
            let range = Range(
                NSRange(location: mention.startIndex, length: mention.length),
                in: message.content
            )
            
            if let range = range {
                attributedString[range].foregroundColor = .blue
                attributedString[range].font = .boldSystemFont(ofSize: 16)
            }
        }
        
        return attributedString
    }
}

// MARK: - Extensions

extension GroupMember {
    var displayName: String {
        return userName // Assuming userName is the display name
    }
}

// MARK: - Chat Errors

enum GroupChatError: LocalizedError {
    case userNotFound
    case groupNotFound
    case messageNotFound
    case insufficientPermissions
    case messageTooLong
    case attachmentTooLarge
    case invalidMessageType
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not found"
        case .groupNotFound:
            return "Group not found"
        case .messageNotFound:
            return "Message not found"
        case .insufficientPermissions:
            return "Insufficient permissions"
        case .messageTooLong:
            return "Message is too long"
        case .attachmentTooLarge:
            return "Attachment is too large"
        case .invalidMessageType:
            return "Invalid message type"
        }
    }
}