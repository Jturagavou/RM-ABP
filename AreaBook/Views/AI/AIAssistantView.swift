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
    @StateObject private var aiCalendarParser = AICalendarParser.shared
    @StateObject private var ocrService = OCRService.shared
    @EnvironmentObject var dataManager: DataManager
    @FocusState private var isInputFocused: Bool
    
    // Image processing states
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var processingImage = false
    @State private var showingEventConfirmation = false
    @State private var extractedEvents: [CalendarEvent] = []
    @State private var processingResult: CalendarProcessingResult?
    
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
                        // Camera/Image button
                        Button(action: { showingImagePicker = true }) {
                            Image(systemName: "camera.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        .disabled(isTyping || processingImage)
                        
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
                        .disabled(currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isTyping || processingImage)
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
        .sheet(isPresented: $showingImagePicker) {
            ImageSelectionSheet(
                isPresented: $showingImagePicker,
                selectedImage: $selectedImage,
                onImageSelected: processCalendarImage
            )
        }
        .sheet(isPresented: $showingEventConfirmation) {
            if let result = processingResult {
                CalendarEventConfirmationView(
                    result: result,
                    onConfirm: confirmEvents,
                    onCancel: { showingEventConfirmation = false }
                )
            }
        }
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
            content: "Hi! I'm your AI assistant. I can help you with goals, tasks, events, and even understand your relationships with people in your accountability groups. You can also share calendar images with me and I'll extract events for you! What would you like to work on today?",
            isUser: false,
            timestamp: Date()
        ))
    }
    
    // MARK: - Image Processing Functions
    
    private func processCalendarImage(_ image: UIImage) {
        processingImage = true
        
        // Add processing message
        messages.append(ChatMessage(
            id: UUID().uuidString,
            content: "📸 Processing your calendar image... I'm extracting text and identifying events.",
            isUser: false,
            timestamp: Date()
        ))
        
        Task {
            do {
                let result = try await aiCalendarParser.processCalendarImage(image)
                
                await MainActor.run {
                    processingImage = false
                    processingResult = result
                    
                    if result.hasEvents {
                        extractedEvents = result.calendarEvents
                        
                        // Add success message
                        messages.append(ChatMessage(
                            id: UUID().uuidString,
                            content: "✅ Great! I found \(result.calendarEvents.count) event\(result.calendarEvents.count == 1 ? "" : "s") in your image:\n\n\(formatEventsForMessage(result.calendarEvents))\n\nWould you like me to add these to your calendar?",
                            isUser: false,
                            timestamp: Date()
                        ))
                        
                        showingEventConfirmation = true
                    } else {
                        // Add no events found message
                        messages.append(ChatMessage(
                            id: UUID().uuidString,
                            content: "I processed your image but couldn't identify any clear calendar events. The extracted text was:\n\n\(result.extractedText.isEmpty ? "No text found" : result.extractedText)\n\nCould you try a clearer image or tell me manually about the events you'd like to add?",
                            isUser: false,
                            timestamp: Date()
                        ))
                    }
                }
            } catch {
                await MainActor.run {
                    processingImage = false
                    
                    // Add error message
                    messages.append(ChatMessage(
                        id: UUID().uuidString,
                        content: "❌ Sorry, I had trouble processing your image: \(error.localizedDescription). Please try again with a clearer image or tell me about the events manually.",
                        isUser: false,
                        timestamp: Date()
                    ))
                }
            }
        }
    }
    
    private func formatEventsForMessage(_ events: [CalendarEvent]) -> String {
        return events.enumerated().map { index, event in
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = event.isAllDay ? .none : .short
            
            let dateString = dateFormatter.string(from: event.startTime)
            let endString = event.isAllDay ? "" : " - \(DateFormatter().string(from: event.endTime))"
            
            return "\(index + 1). **\(event.title)**\n   📅 \(dateString)\(endString)\n   📍 \(event.location ?? "No location")"
        }.joined(separator: "\n\n")
    }
    
    private func confirmEvents() {
        showingEventConfirmation = false
        
        Task {
            var successCount = 0
            
            for event in extractedEvents {
                do {
                    try await dataManager.createEvent(event)
                    successCount += 1
                } catch {
                    print("Failed to create event: \(error)")
                }
            }
            
            await MainActor.run {
                if successCount > 0 {
                    messages.append(ChatMessage(
                        id: UUID().uuidString,
                        content: "🎉 Perfect! I've added \(successCount) event\(successCount == 1 ? "" : "s") to your calendar. You can view and edit them in the Calendar tab.",
                        isUser: false,
                        timestamp: Date()
                    ))
                } else {
                    messages.append(ChatMessage(
                        id: UUID().uuidString,
                        content: "❌ Sorry, I couldn't add the events to your calendar. Please try creating them manually or contact support if the issue persists.",
                        isUser: false,
                        timestamp: Date()
                    ))
                }
                
                // Clear processed events
                extractedEvents = []
                processingResult = nil
            }
        }
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
