import SwiftUI
import FirebaseAuth

// MARK: - Group Chat View
struct GroupChatView: View {
    let group: AccountabilityGroup
    @StateObject private var chatManager = GroupChatManager.shared
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var messageText = ""
    @State private var isLoading = false
    @State private var showingMentionPicker = false
    @State private var availableUsers: [GroupMember] = []
    @State private var replyingToMessage: GroupChatMessage?
    @State private var editingMessage: GroupChatMessage?
    @State private var showingMessageActions = false
    @State private var selectedMessage: GroupChatMessage?
    
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages List
            messagesScrollView
            
            // Reply Preview
            if let replyMessage = replyingToMessage {
                replyPreviewSection(replyMessage)
            }
            
            // Message Input
            messageInputSection
        }
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Info") {
                    // Could show group info
                }
            }
        }
        .onAppear {
            setupChat()
        }
        .onDisappear {
            chatManager.stopMessageListener(for: group.id)
        }
        .sheet(isPresented: $showingMentionPicker) {
            MentionPickerView(
                availableUsers: availableUsers,
                onUserSelected: { user in
                    insertMention(user)
                }
            )
        }
        .sheet(isPresented: $showingMessageActions) {
            if let message = selectedMessage {
                MessageActionsSheet(
                    message: message,
                    currentUserId: authViewModel.currentUser?.id ?? "",
                    onReply: { replyingToMessage = $0 },
                    onEdit: { editingMessage = $0 },
                    onDelete: { deleteMessage($0) }
                )
            }
        }
        .alert("Edit Message", isPresented: .constant(editingMessage != nil)) {
            TextField("Message", text: $messageText)
            Button("Save") {
                if let message = editingMessage {
                    editMessage(message)
                }
            }
            Button("Cancel", role: .cancel) {
                editingMessage = nil
                messageText = ""
            }
        }
    }
    
    // MARK: - Messages Scroll View
    
    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(chatManager.currentGroupMessages) { message in
                        MessageBubbleView(
                            message: message,
                            isCurrentUser: message.senderId == authViewModel.currentUser?.id,
                            onLongPress: {
                                selectedMessage = message
                                showingMessageActions = true
                            },
                            onReaction: { emoji in
                                addReaction(to: message, emoji: emoji)
                            }
                        )
                        .id(message.id)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .onChange(of: chatManager.currentGroupMessages.count) { _ in
                // Scroll to bottom when new messages arrive
                if let lastMessage = chatManager.currentGroupMessages.last {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    // MARK: - Reply Preview Section
    
    private func replyPreviewSection(_ replyMessage: GroupChatMessage) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Replying to \(replyMessage.senderName)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                
                Text(replyMessage.content)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Button("Cancel") {
                replyingToMessage = nil
            }
            .font(.caption)
            .foregroundColor(.red)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .animation(.easeInOut, value: replyingToMessage)
    }
    
    // MARK: - Message Input Section
    
    private var messageInputSection: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                // Mention button
                Button(action: { showingMentionPicker = true }) {
                    Image(systemName: "at")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                
                // Text input
                HStack {
                    TextField("Type a message...", text: $messageText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .focused($isTextFieldFocused)
                        .lineLimit(1...5)
                        .onChange(of: messageText) { newValue in
                            // Auto-trigger mention picker if typing @
                            if newValue.hasSuffix("@") {
                                showingMentionPicker = true
                            }
                        }
                    
                    // Quick emoji reactions
                    HStack(spacing: 8) {
                        ForEach(["👍", "❤️", "😊", "🎉"], id: \.self) { emoji in
                            Button(emoji) {
                                messageText += emoji
                            }
                            .font(.caption)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                
                // Send button
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Chat Functions
    
    private func setupChat() {
        chatManager.startListeningToMessages(groupId: group.id)
        loadAvailableUsers()
        markMessagesAsRead()
    }
    
    private func loadAvailableUsers() {
        Task {
            do {
                availableUsers = try await chatManager.getAvailableUsersForMentions(groupId: group.id)
            } catch {
                print("Failed to load available users: \(error)")
            }
        }
    }
    
    private func sendMessage() {
        let content = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }
        
        isLoading = true
        messageText = ""
        
        Task {
            do {
                try await chatManager.sendMessage(
                    groupId: group.id,
                    content: content,
                    replyToMessageId: replyingToMessage?.id
                )
                
                replyingToMessage = nil
                isTextFieldFocused = true
            } catch {
                // Show error
                print("Failed to send message: \(error)")
            }
            
            isLoading = false
        }
    }
    
    private func editMessage(_ message: GroupChatMessage) {
        guard !messageText.isEmpty else { return }
        
        Task {
            do {
                try await chatManager.editMessage(messageId: message.id, newContent: messageText)
                editingMessage = nil
                messageText = ""
            } catch {
                print("Failed to edit message: \(error)")
            }
        }
    }
    
    private func deleteMessage(_ message: GroupChatMessage) {
        Task {
            do {
                try await chatManager.deleteMessage(messageId: message.id)
            } catch {
                print("Failed to delete message: \(error)")
            }
        }
    }
    
    private func addReaction(to message: GroupChatMessage, emoji: String) {
        Task {
            do {
                // Check if user already reacted with this emoji
                let currentUserId = authViewModel.currentUser?.id ?? ""
                let existingReaction = message.reactions.first { $0.emoji == emoji && $0.userId == currentUserId }
                
                if existingReaction != nil {
                    try await chatManager.removeReaction(messageId: message.id, emoji: emoji)
                } else {
                    try await chatManager.addReaction(messageId: message.id, emoji: emoji)
                }
            } catch {
                print("Failed to add reaction: \(error)")
            }
        }
    }
    
    private func insertMention(_ user: GroupMember) {
        let mention = "@\(user.displayName) "
        messageText += mention
        showingMentionPicker = false
        isTextFieldFocused = true
    }
    
    private func markMessagesAsRead() {
        Task {
            do {
                try await chatManager.markMessagesAsRead(groupId: group.id)
            } catch {
                print("Failed to mark messages as read: \(error)")
            }
        }
    }
}

// MARK: - Message Bubble View

struct MessageBubbleView: View {
    let message: GroupChatMessage
    let isCurrentUser: Bool
    let onLongPress: () -> Void
    let onReaction: (String) -> Void
    
    var body: some View {
        HStack {
            if isCurrentUser {
                Spacer()
                messageContent
            } else {
                HStack(alignment: .top, spacing: 8) {
                    // Avatar
                    AsyncImage(url: URL(string: message.senderAvatar ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Color.blue.opacity(0.3))
                            .overlay(
                                Text(String(message.senderName.prefix(1)))
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                            )
                    }
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                    
                    messageContent
                    
                    Spacer()
                }
            }
        }
    }
    
    private var messageContent: some View {
        VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
            // Sender name (only for other users)
            if !isCurrentUser {
                Text(message.senderName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }
            
            // Message bubble
            VStack(alignment: .leading, spacing: 8) {
                // Message content with mentions
                Text(message.content)
                    .font(.body)
                    .foregroundColor(isCurrentUser ? .white : .primary)
                    .multilineTextAlignment(.leading)
                
                // Reactions
                if !message.reactions.isEmpty {
                    reactionView
                }
                
                // Message info
                HStack(spacing: 4) {
                    Text(formatTime(message.createdAt))
                        .font(.caption2)
                        .foregroundColor(isCurrentUser ? .white.opacity(0.7) : .secondary)
                    
                    if message.isEdited {
                        Text("edited")
                            .font(.caption2)
                            .foregroundColor(isCurrentUser ? .white.opacity(0.7) : .secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isCurrentUser ? Color.blue : Color(.systemGray5))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .onLongPressGesture {
                onLongPress()
            }
        }
        .frame(maxWidth: 280, alignment: isCurrentUser ? .trailing : .leading)
    }
    
    private var reactionView: some View {
        HStack(spacing: 4) {
            ForEach(Array(groupedReactions.keys.sorted()), id: \.self) { emoji in
                let users = groupedReactions[emoji] ?? []
                Button(action: { onReaction(emoji) }) {
                    HStack(spacing: 2) {
                        Text(emoji)
                            .font(.caption)
                        Text("\(users.count)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var groupedReactions: [String: [MessageReaction]] {
        Dictionary(grouping: message.reactions) { $0.emoji }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Mention Picker View

struct MentionPickerView: View {
    let availableUsers: [GroupMember]
    let onUserSelected: (GroupMember) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(availableUsers, id: \.id) { user in
                Button(action: { 
                    onUserSelected(user)
                    dismiss()
                }) {
                    HStack {
                        // User avatar placeholder
                        Circle()
                            .fill(Color.blue.opacity(0.3))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Text(String(user.displayName.prefix(1)))
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                            )
                        
                        VStack(alignment: .leading) {
                            Text(user.displayName)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("@\(user.userName)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .navigationTitle("Mention Someone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Message Actions Sheet

struct MessageActionsSheet: View {
    let message: GroupChatMessage
    let currentUserId: String
    let onReply: (GroupChatMessage) -> Void
    let onEdit: (GroupChatMessage) -> Void
    let onDelete: (GroupChatMessage) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // Message preview
            VStack(alignment: .leading, spacing: 8) {
                Text(message.senderName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Text(message.content)
                    .font(.body)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Actions
            VStack(spacing: 16) {
                Button(action: {
                    onReply(message)
                    dismiss()
                }) {
                    Label("Reply", systemImage: "arrowshape.turn.up.left")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                if message.senderId == currentUserId {
                    Button(action: {
                        onEdit(message)
                        dismiss()
                    }) {
                        Label("Edit", systemImage: "pencil")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: {
                        onDelete(message)
                        dismiss()
                    }) {
                        Label("Delete", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                }
            }
            
            Button("Cancel") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}