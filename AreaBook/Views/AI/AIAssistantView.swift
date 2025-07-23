import SwiftUI
import FirebaseAuth

struct AIAssistantView: View {
    @StateObject private var aiService = AIService.shared
    @EnvironmentObject var dataManager: DataManager
    @State private var isShowingChat = false
    @State private var messages: [ChatMessage] = []
    @State private var currentInput = ""
    @State private var isTyping = false
    
    var body: some View {
        // AI Assistant Trigger - Top-left corner
        VStack {
            Button(action: { isShowingChat = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                    
                    Text("AI")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.accentColor.opacity(0.9))
                        .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
                )
            }
            .scaleEffect(isShowingChat ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isShowingChat)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 16)
        .padding(.top, 8)
        .sheet(isPresented: $isShowingChat) {
            ConversationalChatView(
                messages: $messages,
                currentInput: $currentInput,
                isTyping: $isTyping,
                onDismiss: { isShowingChat = false }
            )
        }
        .onAppear {
            initializeChat()
        }
    }
    
    private func initializeChat() {
        if messages.isEmpty {
            messages.append(ChatMessage(
                id: UUID().uuidString,
                content: "Hi! I'm your AI assistant. I can help you with goals, tasks, events, and even understand your relationships with people in your accountability groups. What would you like to work on today?",
                isUser: false,
                timestamp: Date()
            ))
        }
    }
}

struct ConversationalChatView: View {
    @Binding var messages: [ChatMessage]
    @Binding var currentInput: String
    @Binding var isTyping: Bool
    let onDismiss: () -> Void
    
    @StateObject private var aiService = AIService.shared
    @EnvironmentObject var dataManager: DataManager
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Chat messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { message in
                                ChatMessageView(message: message)
                                    .id(message.id)
                            }
                            
                            if isTyping {
                                TypingIndicator()
                                    .id("typing")
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .onChange(of: messages.count) { _ in
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(messages.last?.id ?? "typing", anchor: .bottom)
                        }
                    }
                }
                
                // Input area
                VStack(spacing: 0) {
                    Divider()
                    
                    HStack(spacing: 12) {
                        TextField("Type your message...", text: $currentInput, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .focused($isInputFocused)
                            .lineLimit(1...4)
                            .onSubmit {
                                sendMessage()
                            }
                        
                        Button(action: sendMessage) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.title2)
                                .foregroundColor(currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .accentColor)
                        }
                        .disabled(currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isTyping)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .background(Color(.systemBackground))
            }
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        onDismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: clearChat) {
                        Image(systemName: "trash")
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear {
            isInputFocused = true
        }
    }
    
    private func sendMessage() {
        let trimmedInput = currentInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty && !isTyping else { return }
        
        // Add user message
        let userMessage = ChatMessage(
            id: UUID().uuidString,
            content: trimmedInput,
            isUser: true,
            timestamp: Date()
        )
        messages.append(userMessage)
        currentInput = ""
        
        // Show typing indicator
        isTyping = true
        
        // Generate AI response
        Task {
            do {
                let response = try await generateAIResponse(to: trimmedInput)
                
                await MainActor.run {
                    isTyping = false
                    messages.append(response)
                }
            } catch {
                await MainActor.run {
                    isTyping = false
                    messages.append(ChatMessage(
                        id: UUID().uuidString,
                        content: "I'm sorry, I encountered an error. Please try again.",
                        isUser: false,
                        timestamp: Date()
                    ))
                }
                print("Error generating AI response: \(error)")
            }
        }
    }
    
    private func generateAIResponse(to userInput: String) async throws -> ChatMessage {
        guard let _ = Auth.auth().currentUser?.uid else {
            throw AIError.userNotAuthenticated
        }
        
        // Get context including groups and people
        let context = getConversationalContext()
        let userProfile = aiService.userProfile?.settings.userProfile ?? .general
        let userRole = mapUserProfileToUserRole(userProfile)
        let assistantStyle = aiService.userProfile?.settings.aiPreferences.assistantStyle ?? AssistantStyle.supportive
        
        // Generate response using GPT
        let response = try await GPTService.shared.generateConversationalResponse(
            userInput: userInput,
            context: context,
            userRole: userRole,
            assistantStyle: assistantStyle,
            chatHistory: messages.map { $0.content }
        )
        
        return ChatMessage(
            id: UUID().uuidString,
            content: response,
            isUser: false,
            timestamp: Date()
        )
    }
    
    // Helper to map UserProfile to UserRole
    private func mapUserProfileToUserRole(_ profile: UserProfile) -> UserRole {
        switch profile {
        case .student:
            return .student
        case .rehab, .wellbeing:
            return .recovery
        case .family, .relationship:
            return .relationship
        default:
            return .personal
        }
    }
    
    private func getConversationalContext() -> String {
        var context = "User's current data:\n"
        
        // Goals context
        if !dataManager.goals.isEmpty {
            context += "\nGoals (\(dataManager.goals.count)):\n"
            for goal in dataManager.goals.prefix(5) {
                context += "- \(goal.title): \(goal.calculatedProgress)% complete\n"
            }
        }
        
        // Tasks context
        if !dataManager.tasks.isEmpty {
            let pendingTasks = dataManager.tasks.filter { $0.status == .pending }
            context += "\nPending Tasks (\(pendingTasks.count)):\n"
            for task in pendingTasks.prefix(3) {
                context += "- \(task.title)\n"
            }
        }
        
        // Events context
        if !dataManager.events.isEmpty {
            let today = Date()
            let todayEvents = dataManager.events.filter { 
                Calendar.current.isDate($0.startTime, inSameDayAs: today)
            }
            context += "\nToday's Events (\(todayEvents.count)):\n"
            for event in todayEvents.prefix(3) {
                context += "- \(event.title) at \(formatTime(event.startTime))\n"
            }
        }
        
        // Groups and people context
        if !dataManager.accountabilityGroups.isEmpty {
            context += "\nAccountability Groups:\n"
            for group in dataManager.accountabilityGroups {
                context += "- \(group.name) (\(group.members.count) members):\n"
                for member in group.members {
                    context += "  * User \(member.userId) (\(member.role.rawValue))\n"
                }
            }
        }
        
        return context
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func clearChat() {
        messages.removeAll()
        initializeChat()
    }
    
    private func initializeChat() {
        messages.append(ChatMessage(
            id: UUID().uuidString,
            content: "Hi! I'm your AI assistant. I can help you with goals, tasks, events, and even understand your relationships with people in your accountability groups. What would you like to work on today?",
            isUser: false,
            timestamp: Date()
        ))
    }
}

struct ChatMessage: Identifiable {
    let id: String
    let content: String
    let isUser: Bool
    let timestamp: Date
}

struct ChatMessageView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    
                    Text(formatTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.content)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    
                    Text(formatTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct TypingIndicator: View {
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 8, height: 8)
                        .scaleEffect(1.0)
                        .animation(
                            Animation.easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                            value: animationOffset
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray5))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            
            Spacer()
        }
        .onAppear {
            animationOffset = 1
        }
    }
}

enum AIError: Error {
    case userNotAuthenticated
    case invalidResponse
    case networkError
}
