import Foundation
import Firebase
import Combine

class TemplateManager: ObservableObject {
    static let shared = TemplateManager()
    
    @Published var goalTemplates: [GoalTemplate] = []
    @Published var taskTemplates: [TaskTemplate] = []
    @Published var eventTemplates: [EventTemplate] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showError = false
    
    private let db = Firestore.firestore()
    private var listeners: [ListenerRegistration] = []
    
    private init() {
        setupDefaultTemplates()
    }
    
    // MARK: - Template Loading
    
    func loadUserTemplates(userId: String) {
        isLoading = true
        
        // Load goal templates
        db.collection("users").document(userId).collection("goalTemplates")
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    self?.showError(error.localizedDescription)
                    return
                }
                
                self?.goalTemplates = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: GoalTemplate.self)
                } ?? []
                
                // Load shared templates
                self?.loadSharedGoalTemplates()
            }
        
        // Load task templates
        db.collection("users").document(userId).collection("taskTemplates")
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    self?.showError(error.localizedDescription)
                    return
                }
                
                self?.taskTemplates = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: TaskTemplate.self)
                } ?? []
                
                self?.loadSharedTaskTemplates()
            }
        
        // Load event templates
        db.collection("users").document(userId).collection("eventTemplates")
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    self?.showError(error.localizedDescription)
                    return
                }
                
                self?.eventTemplates = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: EventTemplate.self)
                } ?? []
                
                self?.loadSharedEventTemplates()
            }
        
        isLoading = false
    }
    
    private func loadSharedGoalTemplates() {
        db.collection("sharedTemplates").document("goals").collection("templates")
            .whereField("isShared", isEqualTo: true)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    self?.showError(error.localizedDescription)
                    return
                }
                
                let sharedTemplates = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: GoalTemplate.self)
                } ?? []
                
                // Merge with user templates (avoiding duplicates)
                let userTemplateIds = Set(self?.goalTemplates.map { $0.id } ?? [])
                let newSharedTemplates = sharedTemplates.filter { !userTemplateIds.contains($0.id) }
                
                self?.goalTemplates.append(contentsOf: newSharedTemplates)
            }
    }
    
    private func loadSharedTaskTemplates() {
        db.collection("sharedTemplates").document("tasks").collection("templates")
            .whereField("isShared", isEqualTo: true)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    self?.showError(error.localizedDescription)
                    return
                }
                
                let sharedTemplates = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: TaskTemplate.self)
                } ?? []
                
                let userTemplateIds = Set(self?.taskTemplates.map { $0.id } ?? [])
                let newSharedTemplates = sharedTemplates.filter { !userTemplateIds.contains($0.id) }
                
                self?.taskTemplates.append(contentsOf: newSharedTemplates)
            }
    }
    
    private func loadSharedEventTemplates() {
        db.collection("sharedTemplates").document("events").collection("templates")
            .whereField("isShared", isEqualTo: true)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    self?.showError(error.localizedDescription)
                    return
                }
                
                let sharedTemplates = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: EventTemplate.self)
                } ?? []
                
                let userTemplateIds = Set(self?.eventTemplates.map { $0.id } ?? [])
                let newSharedTemplates = sharedTemplates.filter { !userTemplateIds.contains($0.id) }
                
                self?.eventTemplates.append(contentsOf: newSharedTemplates)
            }
    }
    
    // MARK: - Template Creation
    
    func createGoalTemplate(_ template: GoalTemplate, userId: String) async throws {
        let validationResult = DataValidationService.shared.validateGoalTemplate(template)
        
        guard validationResult.isValid else {
            throw TemplateError.validationFailed(validationResult.errors)
        }
        
        let templateRef = db.collection("users").document(userId).collection("goalTemplates").document(template.id)
        
        try await templateRef.setData(from: template)
        
        // If shared, also add to shared templates
        if template.isShared {
            try await db.collection("sharedTemplates").document("goals").collection("templates").document(template.id).setData(from: template)
        }
    }
    
    func createTaskTemplate(_ template: TaskTemplate, userId: String) async throws {
        let templateRef = db.collection("users").document(userId).collection("taskTemplates").document(template.id)
        
        try await templateRef.setData(from: template)
        
        if template.isShared {
            try await db.collection("sharedTemplates").document("tasks").collection("templates").document(template.id).setData(from: template)
        }
    }
    
    func createEventTemplate(_ template: EventTemplate, userId: String) async throws {
        let templateRef = db.collection("users").document(userId).collection("eventTemplates").document(template.id)
        
        try await templateRef.setData(from: template)
        
        if template.isShared {
            try await db.collection("sharedTemplates").document("events").collection("templates").document(template.id).setData(from: template)
        }
    }
    
    // MARK: - Template Usage
    
    func useGoalTemplate(_ template: GoalTemplate, userId: String) async throws -> Goal {
        // Increment usage count
        try await incrementTemplateUsage(templateId: template.id, type: "goal", userId: userId)
        
        // Create goal from template
        let goal = Goal(
            title: template.name,
            description: template.description,
            keyIndicatorIds: template.defaultKIIds,
            targetDate: Calendar.current.date(byAdding: .day, value: template.estimatedDuration, to: Date())
        )
        
        return goal
    }
    
    func useTaskTemplate(_ template: TaskTemplate, userId: String) async throws -> Task {
        // Increment usage count
        try await incrementTemplateUsage(templateId: template.id, type: "task", userId: userId)
        
        // Create task from template
        let task = Task(
            title: template.name,
            description: template.description,
            priority: template.defaultPriority,
            dueDate: Calendar.current.date(byAdding: .minute, value: template.estimatedTime, to: Date())
        )
        
        return task
    }
    
    func useEventTemplate(_ template: EventTemplate, userId: String) async throws -> CalendarEvent {
        // Increment usage count
        try await incrementTemplateUsage(templateId: template.id, type: "event", userId: userId)
        
        // Create event from template
        let startTime = Date()
        let endTime = Calendar.current.date(byAdding: .minute, value: template.defaultDuration, to: startTime) ?? startTime
        
        let event = CalendarEvent(
            title: template.name,
            description: template.description,
            category: template.category,
            startTime: startTime,
            endTime: endTime
        )
        
        return event
    }
    
    private func incrementTemplateUsage(templateId: String, type: String, userId: String) async throws {
        let templateRef = db.collection("users").document(userId).collection("\(type)Templates").document(templateId)
        
        try await templateRef.updateData([
            "usage": FieldValue.increment(Int64(1))
        ])
        
        // Also update shared template if it exists
        let sharedRef = db.collection("sharedTemplates").document("\(type)s").collection("templates").document(templateId)
        
        try await sharedRef.updateData([
            "usage": FieldValue.increment(Int64(1))
        ])
    }
    
    // MARK: - Template Management
    
    func updateGoalTemplate(_ template: GoalTemplate, userId: String) async throws {
        let validationResult = DataValidationService.shared.validateGoalTemplate(template)
        
        guard validationResult.isValid else {
            throw TemplateError.validationFailed(validationResult.errors)
        }
        
        var updatedTemplate = template
        
        let templateRef = db.collection("users").document(userId).collection("goalTemplates").document(template.id)
        
        try await templateRef.setData(from: updatedTemplate)
        
        if template.isShared {
            try await db.collection("sharedTemplates").document("goals").collection("templates").document(template.id).setData(from: updatedTemplate)
        }
    }
    
    func deleteGoalTemplate(_ template: GoalTemplate, userId: String) async throws {
        let templateRef = db.collection("users").document(userId).collection("goalTemplates").document(template.id)
        
        try await templateRef.delete()
        
        if template.isShared {
            try await db.collection("sharedTemplates").document("goals").collection("templates").document(template.id).delete()
        }
    }
    
    func shareTemplate(_ template: GoalTemplate, userId: String) async throws {
        guard template.createdBy == userId else {
            throw TemplateError.unauthorized
        }
        
        var updatedTemplate = template
        updatedTemplate.isShared = true
        
        try await updateGoalTemplate(updatedTemplate, userId: userId)
    }
    
    func unshareTemplate(_ template: GoalTemplate, userId: String) async throws {
        guard template.createdBy == userId else {
            throw TemplateError.unauthorized
        }
        
        var updatedTemplate = template
        updatedTemplate.isShared = false
        
        // Remove from shared templates
        try await db.collection("sharedTemplates").document("goals").collection("templates").document(template.id).delete()
        
        try await updateGoalTemplate(updatedTemplate, userId: userId)
    }
    
    // MARK: - Template Search and Filtering
    
    func searchGoalTemplates(query: String, category: String? = nil, difficulty: GoalDifficulty? = nil) -> [GoalTemplate] {
        var filteredTemplates = goalTemplates
        
        // Text search
        if !query.isEmpty {
            filteredTemplates = filteredTemplates.filter { template in
                template.name.localizedCaseInsensitiveContains(query) ||
                template.description.localizedCaseInsensitiveContains(query) ||
                template.tags.contains { $0.localizedCaseInsensitiveContains(query) }
            }
        }
        
        // Category filter
        if let category = category {
            filteredTemplates = filteredTemplates.filter { $0.category == category }
        }
        
        // Difficulty filter
        if let difficulty = difficulty {
            filteredTemplates = filteredTemplates.filter { $0.difficulty == difficulty }
        }
        
        return filteredTemplates.sorted { $0.usage > $1.usage }
    }
    
    func searchTaskTemplates(query: String, category: String? = nil, priority: TaskPriority? = nil) -> [TaskTemplate] {
        var filteredTemplates = taskTemplates
        
        if !query.isEmpty {
            filteredTemplates = filteredTemplates.filter { template in
                template.name.localizedCaseInsensitiveContains(query) ||
                template.description.localizedCaseInsensitiveContains(query) ||
                template.tags.contains { $0.localizedCaseInsensitiveContains(query) }
            }
        }
        
        if let category = category {
            filteredTemplates = filteredTemplates.filter { $0.category == category }
        }
        
        if let priority = priority {
            filteredTemplates = filteredTemplates.filter { $0.defaultPriority == priority }
        }
        
        return filteredTemplates.sorted { $0.usage > $1.usage }
    }
    
    func searchEventTemplates(query: String, category: String? = nil) -> [EventTemplate] {
        var filteredTemplates = eventTemplates
        
        if !query.isEmpty {
            filteredTemplates = filteredTemplates.filter { template in
                template.name.localizedCaseInsensitiveContains(query) ||
                template.description.localizedCaseInsensitiveContains(query) ||
                template.tags.contains { $0.localizedCaseInsensitiveContains(query) }
            }
        }
        
        if let category = category {
            filteredTemplates = filteredTemplates.filter { $0.category == category }
        }
        
        return filteredTemplates.sorted { $0.usage > $1.usage }
    }
    
    // MARK: - Template Statistics
    
    func getTemplateStats(userId: String) -> TemplateStats {
        let userGoalTemplates = goalTemplates.filter { $0.createdBy == userId }
        let userTaskTemplates = taskTemplates.filter { $0.createdBy == userId }
        let userEventTemplates = eventTemplates.filter { $0.createdBy == userId }
        
        return TemplateStats(
            totalGoalTemplates: userGoalTemplates.count,
            totalTaskTemplates: userTaskTemplates.count,
            totalEventTemplates: userEventTemplates.count,
            totalSharedTemplates: userGoalTemplates.filter { $0.isShared }.count + userTaskTemplates.filter { $0.isShared }.count + userEventTemplates.filter { $0.isShared }.count,
            totalUsage: userGoalTemplates.reduce(0) { $0 + $1.usage } + userTaskTemplates.reduce(0) { $0 + $1.usage } + userEventTemplates.reduce(0) { $0 + $1.usage },
            mostUsedGoalTemplate: userGoalTemplates.max(by: { $0.usage < $1.usage }),
            mostUsedTaskTemplate: userTaskTemplates.max(by: { $0.usage < $1.usage }),
            mostUsedEventTemplate: userEventTemplates.max(by: { $0.usage < $1.usage })
        )
    }
    
    // MARK: - Default Templates
    
    private func setupDefaultTemplates() {
        // Default goal templates
        let defaultGoalTemplates = [
            GoalTemplate(
                name: "Daily Scripture Study",
                description: "Establish a consistent daily scripture study habit",
                category: "Spiritual",
                defaultKIIds: [],
                estimatedDuration: 30,
                difficulty: .beginner,
                tags: ["spiritual", "daily", "scripture"],
                isShared: true,
                createdBy: "system"
            ),
            GoalTemplate(
                name: "Weekly Service Project",
                description: "Complete a meaningful service project each week",
                category: "Service",
                defaultKIIds: [],
                estimatedDuration: 90,
                difficulty: .intermediate,
                tags: ["service", "weekly", "community"],
                isShared: true,
                createdBy: "system"
            ),
            GoalTemplate(
                name: "Monthly Missionary Work",
                description: "Actively participate in missionary work opportunities",
                category: "Missionary",
                defaultKIIds: [],
                estimatedDuration: 30,
                difficulty: .intermediate,
                tags: ["missionary", "monthly", "sharing"],
                isShared: true,
                createdBy: "system"
            )
        ]
        
        // Default task templates
        let defaultTaskTemplates = [
            TaskTemplate(
                name: "Morning Prayer",
                description: "Start the day with personal prayer",
                category: "Spiritual",
                estimatedTime: 10,
                defaultPriority: .high,
                tags: ["prayer", "morning", "daily"],
                isShared: true,
                createdBy: "system"
            ),
            TaskTemplate(
                name: "Evening Reflection",
                description: "Reflect on the day's experiences and lessons",
                category: "Personal",
                estimatedTime: 15,
                defaultPriority: .medium,
                tags: ["reflection", "evening", "growth"],
                isShared: true,
                createdBy: "system"
            ),
            TaskTemplate(
                name: "Family Home Evening Preparation",
                description: "Prepare materials and activities for family home evening",
                category: "Family",
                estimatedTime: 30,
                defaultPriority: .medium,
                tags: ["family", "preparation", "weekly"],
                isShared: true,
                createdBy: "system"
            )
        ]
        
        // Default event templates
        let defaultEventTemplates = [
            EventTemplate(
                name: "Weekly Planning Session",
                description: "Plan and organize the upcoming week",
                category: "Personal",
                defaultDuration: 60,
                tags: ["planning", "weekly", "organization"],
                isShared: true,
                createdBy: "system"
            ),
            EventTemplate(
                name: "District Meeting",
                description: "Monthly district meeting for missionaries",
                category: "Church",
                defaultDuration: 90,
                tags: ["meeting", "district", "church"],
                isShared: true,
                createdBy: "system"
            ),
            EventTemplate(
                name: "Personal Study Time",
                description: "Dedicated time for personal study and reflection",
                category: "Spiritual",
                defaultDuration: 45,
                tags: ["study", "personal", "spiritual"],
                isShared: true,
                createdBy: "system"
            )
        ]
        
        // In a real app, these would be loaded from Firestore
        // For now, we'll add them to the local arrays
        self.goalTemplates = defaultGoalTemplates
        self.taskTemplates = defaultTaskTemplates
        self.eventTemplates = defaultEventTemplates
    }
    
    // MARK: - Helper Methods
    
    private func showError(_ message: String) {
        DispatchQueue.main.async {
            self.errorMessage = message
            self.showError = true
        }
    }
}

// MARK: - Supporting Types

struct TemplateStats {
    var totalGoalTemplates: Int
    var totalTaskTemplates: Int
    var totalEventTemplates: Int
    var totalSharedTemplates: Int
    var totalUsage: Int
    var mostUsedGoalTemplate: GoalTemplate?
    var mostUsedTaskTemplate: TaskTemplate?
    var mostUsedEventTemplate: EventTemplate?
}

enum TemplateError: Error {
    case validationFailed([ValidationError])
    case unauthorized
    case templateNotFound
    case alreadyShared
    case networkError(String)
}