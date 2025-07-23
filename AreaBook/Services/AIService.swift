import Foundation
import FirebaseFirestore
import FirebaseAuth

class AIService: ObservableObject {
    private let db = Firestore.firestore()
    
    // MARK: - Published Properties
    @Published var currentSuggestions: [AISuggestion] = []
    @Published var passiveProfile: PassiveAIProfile?
    @Published var userProfile: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Singleton
    static let shared = AIService()
    
    private init() {
        setupAuthListener()
    }
    
    // MARK: - Authentication Listener
    private func setupAuthListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                self?.loadUserData(userId: user.uid)
            } else {
                self?.clearUserData()
            }
        }
    }
    
    // MARK: - User Data Management
    private func loadUserData(userId: String) {
        loadUserProfile(userId: userId)
        loadPassiveProfile(userId: userId)
        loadSuggestions(userId: userId)
    }
    
    private func clearUserData() {
        DispatchQueue.main.async {
            self.currentSuggestions = []
            self.passiveProfile = nil
            self.userProfile = nil
        }
    }
    
    // MARK: - User Profile Management
    func loadUserProfile(userId: String) {
        db.collection("users").document(userId).getDocument { [weak self] document, error in
            DispatchQueue.main.async {
                if let document = document, document.exists {
                    do {
                        self?.userProfile = try document.data(as: User.self)
                    } catch {
                        print("Error decoding user profile: \(error)")
                        self?.createDefaultUserProfile(userId: userId)
                    }
                } else {
                    self?.createDefaultUserProfile(userId: userId)
                }
            }
        }
    }
    
    private func createDefaultUserProfile(userId: String) {
        let defaultSettings = UserSettings()
        let user = User(id: userId, email: "", name: "New User", avatar: nil, createdAt: Date(), lastSeen: Date(), settings: defaultSettings)
        saveUserProfile(user)
    }
    
    func saveUserProfile(_ user: User) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(user)
            let dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
            
            db.collection("users").document(user.id).setData(dictionary) { error in
                if let error = error {
                    print("Error saving user profile: \(error)")
                    DispatchQueue.main.async {
                        self.errorMessage = "Failed to save profile"
                    }
                } else {
                    DispatchQueue.main.async {
                        self.userProfile = user
                    }
                }
            }
        } catch {
            print("Error encoding user profile: \(error)")
            DispatchQueue.main.async {
                self.errorMessage = "Failed to save profile"
            }
        }
    }
    
    // MARK: - Passive AI Profile Management
    func loadPassiveProfile(userId: String) {
        db.collection("passiveProfiles").document(userId).getDocument { [weak self] document, error in
            DispatchQueue.main.async {
                if let document = document, document.exists {
                    do {
                        self?.passiveProfile = try document.data(as: PassiveAIProfile.self)
                    } catch {
                        print("Error decoding passive profile: \(error)")
                        self?.createDefaultPassiveProfile(userId: userId)
                    }
                } else {
                    self?.createDefaultPassiveProfile(userId: userId)
                }
            }
        }
    }
    
    private func createDefaultPassiveProfile(userId: String) {
        let profile = PassiveAIProfile(userId: userId)
        savePassiveProfile(profile)
    }
    
    func savePassiveProfile(_ profile: PassiveAIProfile) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(profile)
            let dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
            
            db.collection("passiveProfiles").document(profile.userId).setData(dictionary) { error in
                if let error = error {
                    print("Error saving passive profile: \(error)")
                } else {
                    DispatchQueue.main.async {
                        self.passiveProfile = profile
                    }
                }
            }
        } catch {
            print("Error encoding passive profile: \(error)")
        }
    }
    
    // MARK: - Suggestions Management
    func loadSuggestions(userId: String) {
        db.collection("suggestions")
            .whereField("userId", isEqualTo: userId)
            .whereField("status", isEqualTo: SuggestionStatus.pending.rawValue)
            .order(by: "createdAt", descending: true)
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let documents = snapshot?.documents {
                        self?.currentSuggestions = documents.compactMap { document in
                            try? document.data(as: AISuggestion.self)
                        }
                    }
                }
            }
    }
    
    func saveSuggestion(_ suggestion: AISuggestion) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(suggestion)
            let dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
            
            db.collection("suggestions").document(suggestion.id).setData(dictionary) { error in
                if let error = error {
                    print("Error saving suggestion: \(error)")
                } else {
                    self.loadSuggestions(userId: suggestion.userId)
                }
            }
        } catch {
            print("Error encoding suggestion: \(error)")
        }
    }
    
    func acceptSuggestion(_ suggestion: AISuggestion) {
        var updatedSuggestion = suggestion
        updatedSuggestion.status = .accepted
        updatedSuggestion.acceptedAt = Date()
        saveSuggestion(updatedSuggestion)
    }
    
    func dismissSuggestion(_ suggestion: AISuggestion) {
        var updatedSuggestion = suggestion
        updatedSuggestion.status = .dismissed
        updatedSuggestion.dismissedAt = Date()
        saveSuggestion(updatedSuggestion)
    }
    
    // MARK: - Passive AI Analysis
    func analyzeUserBehavior(userId: String, tasks: [AppTask], events: [CalendarEvent], goals: [Goal], notes: [Note]) {
        guard let profile = passiveProfile else { return }
        
        var updatedProfile = profile
        
        // Analyze skipped tasks
        let skippedTasks = tasks.filter { $0.status == .skipped }
        for task in skippedTasks {
            let category = task.category ?? "general"
            updatedProfile.skippedTasks[category, default: 0] += 1
        }
        
        // Analyze common keywords from notes
        let allContent = notes.map { $0.content + " " + $0.title }.joined(separator: " ")
        let keywords = extractKeywords(from: allContent)
        updatedProfile.commonKeywords = Array(Set(updatedProfile.commonKeywords + keywords)).prefix(20).map { $0 }
        
        // Analyze goal engagement
        for goal in goals {
            let engagement = analyzeGoalEngagement(goal: goal, tasks: tasks, events: events)
            updatedProfile.goalEngagement[goal.id] = engagement
        }
        
        // Analyze task completion patterns
        let completionRates = calculateTaskCompletionRates(tasks: tasks)
        updatedProfile.taskCompletionPatterns = completionRates
        
        // Analyze active hours
        let activeHours = analyzeActiveHours(events: events, tasks: tasks)
        updatedProfile.activeHours = activeHours
        
        updatedProfile.lastUpdated = Date()
        savePassiveProfile(updatedProfile)
        
        // Generate suggestions based on analysis
        generateSuggestions(from: updatedProfile, tasks: tasks, goals: goals)
    }
    
    private func extractKeywords(from text: String) -> [String] {
        let words = text.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { $0.count > 3 }
        
        let stopWords = Set(["the", "and", "for", "with", "this", "that", "have", "will", "from", "they", "been", "were", "said", "each", "which", "their", "time", "would", "there", "could", "other", "than", "first", "very", "after", "some", "what", "when", "where", "over", "think", "also", "around", "another", "into", "during", "before", "these", "through", "under", "while", "should", "because", "against", "between", "never", "through", "always", "often", "sometimes", "usually", "rarely", "never", "always", "often", "sometimes", "usually", "rarely"])
        
        let filteredWords = words.filter { !stopWords.contains($0) }
        let wordCounts = Dictionary(grouping: filteredWords, by: { $0 })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
        
        return Array(wordCounts.prefix(10).map { $0.key })
    }
    
    private func analyzeGoalEngagement(goal: Goal, tasks: [AppTask], events: [CalendarEvent]) -> GoalEngagementData {
        let relatedTasks = tasks.filter { $0.linkedGoalId == goal.id }
        let relatedEvents = events.filter { $0.linkedGoalId == goal.id }
        
        let totalInteractions = relatedTasks.count + relatedEvents.count
        let completedInteractions = relatedTasks.filter { $0.status == .completed }.count + 
                                   relatedEvents.filter { $0.status == .completed }.count
        
        let progressRate = totalInteractions > 0 ? Double(completedInteractions) / Double(totalInteractions) : 0.0
        
        var data = GoalEngagementData()
        data.lastUpdated = Date()
        data.interactionCount = totalInteractions
        data.progressRate = progressRate
        data.emotionalState = nil
        return data
    }
    
    private func calculateTaskCompletionRates(tasks: [AppTask]) -> [String: Double] {
        let groupedTasks = Dictionary(grouping: tasks) { task in
            task.category ?? "general"
        }
        
        return groupedTasks.mapValues { tasks in
            let completed = tasks.filter { $0.status == .completed }.count
            return Double(completed) / Double(tasks.count)
        }
    }
    
    private func analyzeActiveHours(events: [CalendarEvent], tasks: [AppTask]) -> [String] {
        let allDates = events.map { $0.startTime } + tasks.compactMap { $0.dueDate }
        let hourCounts = Dictionary(grouping: allDates) { date in
            Calendar.current.component(.hour, from: date)
        }.mapValues { $0.count }
        
        let sortedHours = hourCounts.sorted { $0.value > $1.value }
        return sortedHours.prefix(5).map { "\($0.key):00" }
    }
    
    // MARK: - Suggestion Generation
    private func generateSuggestions(from profile: PassiveAIProfile, tasks: [AppTask], goals: [Goal]) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        var suggestions: [AISuggestion] = []
        
        // Check for skipped tasks
        for (category, count) in profile.skippedTasks {
            if count >= 3 {
                let suggestion = AISuggestion(
                    userId: userId,
                    type: .rescheduleTasks,
                    message: "You've skipped \(count) \(category) tasks recently. Would you like to reschedule them for a different time?",
                    priority: count >= 5 ? .high : .medium
                )
                suggestions.append(suggestion)
            }
        }
        
        // Check for low goal engagement
        let lowEngagementGoals = profile.goalEngagement.filter { $0.value.progressRate < 0.3 }
        for (goalId, _) in lowEngagementGoals {
            if let goal = goals.first(where: { $0.id == goalId }) {
                let suggestion = AISuggestion(
                    userId: userId,
                    type: .emotionalSupport,
                    message: "Your goal '\(goal.title)' hasn't seen much progress lately. Would you like some help breaking it down into smaller steps?",
                    priority: .medium
                )
                suggestions.append(suggestion)
            }
        }
        
        // Check for emotional patterns
        if profile.commonKeywords.contains("overwhelmed") || profile.commonKeywords.contains("stressed") {
            let suggestion = AISuggestion(
                userId: userId,
                type: .emotionalSupport,
                message: "I notice you've been feeling overwhelmed. Would you like to create a plan to reduce stress and find balance?",
                priority: .high
            )
            suggestions.append(suggestion)
        }
        
        // Save suggestions
        for suggestion in suggestions {
            saveSuggestion(suggestion)
        }
    }
    
    // MARK: - Assistant Plan Management
    func saveAssistantPlan(_ plan: AssistantPlan) {
        do {
            try db.collection("assistantPlans").document(plan.id).setData(from: plan)
        } catch {
            print("Error saving assistant plan: \(error)")
        }
    }
    
    func loadAssistantPlans(userId: String) async -> [AssistantPlan] {
        do {
            let snapshot = try await db.collection("assistantPlans")
                .whereField("userId", isEqualTo: userId)
                .order(by: "createdAt", descending: true)
                .getDocuments()
            
            return snapshot.documents.compactMap { document in
                try? document.data(as: AssistantPlan.self)
            }
        } catch {
            print("Error loading assistant plans: \(error)")
            return []
        }
    }
    
    // MARK: - Chat Logging
    func logAssistantInteraction(_ log: AssistantChatLog) {
        do {
            try db.collection("assistantLogs").document(log.id).setData(from: log)
        } catch {
            print("Error logging assistant interaction: \(error)")
        }
    }
    
    // MARK: - Siri/AI Integration Stub
    @MainActor
    func generateResponse(prompt: String) async -> String {
        return "[AI response placeholder]"
    }
    
    // MARK: - Helper Methods
    func getPassiveContext() -> PassiveContext {
        guard let profile = passiveProfile else { return PassiveContext() }
        
        let goalEngagement = profile.goalEngagement.values.map { $0.progressRate }.reduce(0, +) / Double(max(profile.goalEngagement.count, 1))
        let engagementLevel = goalEngagement > 0.7 ? "high" : goalEngagement > 0.4 ? "medium" : "low"
        
        var context = PassiveContext()
        context.goalEngagement = engagementLevel
        context.recentKeywords = Array(profile.commonKeywords.prefix(5))
        context.emotionalState = nil
        context.taskCompletionRate = profile.taskCompletionPatterns.values.reduce(0, +) / Double(max(profile.taskCompletionPatterns.count, 1))
        context.activeGoals = profile.goalEngagement.count
        context.lastGoalUpdate = profile.lastUpdated
        return context
    }
}

// MARK: - Extensions for Task Category
extension AppTask {
    var category: String? {
        // Extract category from title or description
        let text = (title + " " + (description ?? "")).lowercased()
        
        if text.contains("spiritual") || text.contains("prayer") || text.contains("scripture") {
            return "spiritual"
        } else if text.contains("family") || text.contains("relationship") {
            return "family"
        } else if text.contains("work") || text.contains("job") || text.contains("career") {
            return "work"
        } else if text.contains("school") || text.contains("study") || text.contains("homework") {
            return "school"
        } else if text.contains("health") || text.contains("exercise") || text.contains("fitness") {
            return "health"
        } else {
            return "personal"
        }
    }
} 