import Foundation
import Firebase
import FirebaseFirestore
import Combine
import WidgetKit

class DataManager: ObservableObject {
    static let shared = DataManager()
    
    @Published var keyIndicators: [KeyIndicator] = []
    @Published var goals: [Goal] = []
    @Published var events: [CalendarEvent] = []
    @Published var tasks: [AppTask] = []
    @Published var notes: [Note] = []
    @Published var accountabilityGroups: [AccountabilityGroup] = []
    @Published var encouragements: [Encouragement] = []
    
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showError = false
    
    private var db: Firestore!
    private var listeners: [ListenerRegistration] = []
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Initialize AI service integration
        setupAIIntegration()
    }
    
    private func setupAIIntegration() {
        // Trigger AI analysis when data changes
        $tasks
            .combineLatest($events, $goals, $notes)
            .debounce(for: .seconds(5), scheduler: DispatchQueue.main)
            .sink { [weak self] tasks, events, goals, notes in
                self?.triggerAIAnalysis(tasks: tasks, events: events, goals: goals, notes: notes)
                // Sync to widgets using existing service
                WidgetDataService.shared.syncDataForWidgets()
            }
            .store(in: &cancellables)
    }
    
    private func triggerAIAnalysis(tasks: [AppTask], events: [CalendarEvent], goals: [Goal], notes: [Note]) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Only analyze if we have meaningful data
        if !tasks.isEmpty || !events.isEmpty || !goals.isEmpty || !notes.isEmpty {
            AIService.shared.analyzeUserBehavior(
                userId: userId,
                tasks: tasks,
                events: events,
                goals: goals,
                notes: notes
            )
        }
    }
    
    func configure() {
        self.db = Firestore.firestore()
    }
    
    func setupListeners(for userId: String) {
        print("📊 DataManager: Setting up listeners for user: \(userId)")
        removeListeners()
        
        // Setup real-time listeners for all collections
        setupKeyIndicatorsListener(userId: userId)
        setupGoalsListener(userId: userId)
        setupEventsListener(userId: userId)
        setupTasksListener(userId: userId)
        setupNotesListener(userId: userId)
        setupGroupsListener(userId: userId)
        setupEncouragementListener(userId: userId)
        
        // Start widget data service real-time updates
        WidgetDataService.shared.startRealtimeUpdates()
        
        // Initial sync to widgets
        WidgetDataService.shared.syncDataForWidgets()
    }
    
    func removeListeners() {
        print("📊 DataManager: Removing all listeners")
        listeners.forEach { $0.remove() }
        listeners.removeAll()
        
        // Stop widget data service real-time updates
        WidgetDataService.shared.stopRealtimeUpdates()
        
        // Clear widget data when removing listeners (usually when signing out)
        print("🔄 DataManager: Clearing widget data due to listener removal")
        WidgetDataUtilities.clearAllWidgetData()
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    // MARK: - Key Indicators
    private func setupKeyIndicatorsListener(userId: String) {
        print("📊 DataManager: Setting up key indicators listener for user: \(userId)")
        let path = "users/\(userId)/keyIndicators"
        print("📊 DataManager: Firestore path: \(path)")
        
        let listener = db.collection("users").document(userId).collection("keyIndicators")
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("❌ DataManager: Key indicators listener error: \(error.localizedDescription)")
                    print("❌ DataManager: Error code: \(error._code)")
                    self?.showError(error.localizedDescription)
                    return
                }
                
                guard let documents = snapshot?.documents else { 
                    print("📊 DataManager: No key indicators documents found")
                    return 
                }
                
                print("✅ DataManager: Key indicators listener success, found \(documents.count) documents")
                self?.keyIndicators = documents.compactMap { doc -> KeyIndicator? in
                    try? doc.data(as: KeyIndicator.self)
                }
            }
        listeners.append(listener)
    }
    
    func createKeyIndicator(_ keyIndicator: KeyIndicator, userId: String) {
        print("📊 DataManager: Creating key indicator for user: \(userId)")
        print("📊 DataManager: Key indicator ID: \(keyIndicator.id)")
        let path = "users/\(userId)/keyIndicators/\(keyIndicator.id)"
        print("📊 DataManager: Firestore path: \(path)")
        
        do {
            try db.collection("users").document(userId).collection("keyIndicators")
                .document(keyIndicator.id).setData(from: keyIndicator)
            print("✅ DataManager: Key indicator created successfully")
            
            // Immediately sync to widgets for real-time updates
            WidgetDataService.shared.syncDataForWidgets()
            print("🔄 DataManager: Widget data refreshed for key indicator creation")
            
            // HapticManager.shared.success()
        } catch {
            print("❌ DataManager: Failed to create key indicator: \(error.localizedDescription)")
            print("❌ DataManager: Error: \(error)")
            showError("Failed to create key indicator. \(error.localizedDescription)", suggestion: "Please try again or check your network connection.")
            // HapticManager.shared.error()
        }
    }
    
    func updateKeyIndicator(_ keyIndicator: KeyIndicator, userId: String) {
        var updatedKI = keyIndicator
        updatedKI.updatedAt = Date()
        
        do {
            try db.collection("users").document(userId).collection("keyIndicators")
                .document(keyIndicator.id).setData(from: updatedKI)
            
            // Immediately sync to widgets for real-time updates
            WidgetDataService.shared.syncDataForWidgets()
            print("🔄 DataManager: Widget data refreshed for key indicator update")
        } catch {
            showError("Failed to update key indicator: \(error.localizedDescription)", suggestion: "Please try again or check your network connection.")
        }
    }
    
    func deleteKeyIndicator(_ keyIndicator: KeyIndicator, userId: String) {
        db.collection("users").document(userId).collection("keyIndicators")
            .document(keyIndicator.id).delete { [weak self] error in
                if let error = error {
                    self?.showError("Failed to delete key indicator: \(error.localizedDescription)", suggestion: "Please try again or check your network connection.")
                } else {
                    // Immediately sync to widgets for real-time updates
                    WidgetDataService.shared.syncDataForWidgets()
                    print("🔄 DataManager: Widget data refreshed for key indicator deletion")
                }
            }
    }
    
    // MARK: - Goals
    private func setupGoalsListener(userId: String) {
        let listener = db.collection("users").document(userId).collection("goals")
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    self?.showError(error.localizedDescription)
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                self?.goals = documents.compactMap { doc -> Goal? in
                    try? doc.data(as: Goal.self)
                }
            }
        listeners.append(listener)
    }
    
    func createGoal(_ goal: Goal, userId: String) {
        do {
            try db.collection("users").document(userId).collection("goals")
                .document(goal.id).setData(from: goal)
            // Sync to widgets
            WidgetDataService.shared.syncDataForWidgets()
        } catch {
            showError("Failed to create goal: \(error.localizedDescription)", suggestion: "Please try again or check your network connection.")
        }
    }
    
    func updateGoal(_ goal: Goal, userId: String) {
        var updatedGoal = goal
        updatedGoal.updatedAt = Date()
        
        do {
            try db.collection("users").document(userId).collection("goals")
                .document(goal.id).setData(from: updatedGoal)
            // Sync to widgets
            WidgetDataService.shared.syncDataForWidgets()
        } catch {
            showError("Failed to update goal: \(error.localizedDescription)", suggestion: "Please try again or check your network connection.")
        }
    }
    
    func deleteGoal(_ goal: Goal, userId: String) {
        db.collection("users").document(userId).collection("goals")
            .document(goal.id).delete { [weak self] error in
                if let error = error {
                    self?.showError("Failed to delete goal: \(error.localizedDescription)", suggestion: "Please try again or check your network connection.")
                } else {
                    // Sync to widgets
                    WidgetDataService.shared.syncDataForWidgets()
                }
            }
    }
    
    // MARK: - Calendar Events
    private func setupEventsListener(userId: String) {
        let listener = db.collection("users").document(userId).collection("events")
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    self?.showError(error.localizedDescription)
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                self?.events = documents.compactMap { doc -> CalendarEvent? in
                    try? doc.data(as: CalendarEvent.self)
                }
            }
        listeners.append(listener)
    }
    
    func createEvent(_ event: CalendarEvent, userId: String) {
        do {
            try db.collection("users").document(userId).collection("events")
                .document(event.id).setData(from: event)
            
            // Immediately sync to widgets for real-time updates
            WidgetDataService.shared.syncDataForWidgets()
            print("🔄 DataManager: Widget data refreshed for event creation")
        } catch {
            showError("Failed to create event: \(error.localizedDescription)", suggestion: "Please try again or check your network connection.")
        }
    }
    
    func updateEvent(_ event: CalendarEvent, userId: String) {
        var updatedEvent = event
        updatedEvent.updatedAt = Date()
        
        print("📅 DataManager: Updating event: \(event.title)")
        print("📅 DataManager: Event status: \(event.status.rawValue)")
        print("📅 DataManager: Updated event status: \(updatedEvent.status.rawValue)")
        print("📅 DataManager: Event linkedGoalId: \(event.linkedGoalId ?? "nil")")
        print("📅 DataManager: Event progressContribution: \(event.progressContribution ?? 0)")
        
        // Find the existing event to compare status
        let existingEvent = events.first { $0.id == event.id }
        let wasCompleted = existingEvent?.status == .completed
        let isBeingCompleted = event.status == .completed && !wasCompleted
        
        print("📅 DataManager: Was completed: \(wasCompleted)")
        print("📅 DataManager: Is being completed: \(isBeingCompleted)")
        
        // Update linked goal progress if event is being completed and has progress contribution
        if isBeingCompleted,
           let goalId = event.linkedGoalId,
           let progressContribution = event.progressContribution,
           progressContribution > 0 {
            print("📅 DataManager: Triggering goal progress update for event completion")
            updateGoalProgress(goalId: goalId, contribution: progressContribution, userId: userId)
        }
        
        do {
            try db.collection("users").document(userId).collection("events")
                .document(event.id).setData(from: updatedEvent)
            
            // Immediately sync to widgets for real-time updates
            WidgetDataService.shared.syncDataForWidgets()
            print("🔄 DataManager: Widget data refreshed for event update")
        } catch {
            showError("Failed to update event: \(error.localizedDescription)", suggestion: "Please try again or check your network connection.")
        }
    }
    
    func deleteEvent(_ event: CalendarEvent, userId: String) {
        db.collection("users").document(userId).collection("events")
            .document(event.id).delete { [weak self] error in
                if let error = error {
                    self?.showError("Failed to delete event: \(error.localizedDescription)", suggestion: "Please try again or check your network connection.")
                } else {
                    // Immediately sync to widgets for real-time updates
                    WidgetDataService.shared.syncDataForWidgets()
                    print("🔄 DataManager: Widget data refreshed for event deletion")
                }
            }
    }
    
    // MARK: - Tasks
    private func setupTasksListener(userId: String) {
        let listener = db.collection("users").document(userId).collection("tasks")
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    self?.showError(error.localizedDescription)
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                        self?.tasks = documents.compactMap { doc -> AppTask? in
            try? doc.data(as: AppTask.self)
                }
            }
        listeners.append(listener)
    }
    
    func createTask(_ task: AppTask, userId: String) {
        do {
            try db.collection("users").document(userId).collection("tasks")
                .document(task.id).setData(from: task)
            
            // Immediately sync to widgets for real-time updates
            WidgetDataService.shared.syncDataForWidgets()
            print("🔄 DataManager: Widget data refreshed for task creation")
        } catch {
            showError("Failed to create task: \(error.localizedDescription)", suggestion: "Please try again or check your network connection.")
        }
    }
    
    func updateTask(_ task: AppTask, userId: String) {
        var updatedTask = task
        updatedTask.updatedAt = Date()
        
        print("📋 DataManager: Updating task: \(task.title)")
        print("📋 DataManager: Task status: \(task.status.rawValue)")
        print("📋 DataManager: Task completedAt: \(task.completedAt?.description ?? "nil")")
        print("📋 DataManager: Task linkedGoalId: \(task.linkedGoalId ?? "nil")")
        print("📋 DataManager: Task progressContribution: \(task.progressContribution ?? 0)")
        
        // Find the existing task to compare status
        let existingTask = tasks.first { $0.id == task.id }
        let wasCompleted = existingTask?.status == .completed
        let isBeingCompleted = task.status == .completed && !wasCompleted
        
        print("📋 DataManager: Was completed: \(wasCompleted)")
        print("📋 DataManager: Is being completed: \(isBeingCompleted)")
        
        // Update linked goal progress if task is being completed and has progress contribution
        if isBeingCompleted,
           let goalId = task.linkedGoalId,
           let progressContribution = task.progressContribution,
           progressContribution > 0 {
            print("📋 DataManager: Triggering goal progress update for task completion")
            updateGoalProgress(goalId: goalId, contribution: progressContribution, userId: userId)
        }
        
        do {
            try db.collection("users").document(userId).collection("tasks")
                .document(task.id).setData(from: updatedTask)
            
            // Immediately sync to widgets for real-time updates
            WidgetDataService.shared.syncDataForWidgets()
            print("🔄 DataManager: Widget data refreshed for task update")
        } catch {
            showError("Failed to update task: \(error.localizedDescription)", suggestion: "Please try again or check your network connection.")
        }
    }
    
    func deleteTask(_ task: AppTask, userId: String) {
        db.collection("users").document(userId).collection("tasks")
            .document(task.id).delete { [weak self] error in
                if let error = error {
                    self?.showError("Failed to delete task: \(error.localizedDescription)", suggestion: "Please try again or check your network connection.")
                } else {
                    // Immediately sync to widgets for real-time updates
                    WidgetDataService.shared.syncDataForWidgets()
                    print("🔄 DataManager: Widget data refreshed for task deletion")
                }
            }
    }
    
    // MARK: - Notes
    private func setupNotesListener(userId: String) {
        let listener = db.collection("users").document(userId).collection("notes")
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    self?.showError(error.localizedDescription)
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                self?.notes = documents.compactMap { doc -> Note? in
                    try? doc.data(as: Note.self)
                }
            }
        listeners.append(listener)
    }
    
    func createNote(_ note: Note, userId: String) {
        do {
            try db.collection("users").document(userId).collection("notes")
                .document(note.id).setData(from: note)
            // Sync to widgets
            WidgetDataService.shared.syncDataForWidgets()
        } catch {
            showError("Failed to create note: \(error.localizedDescription)", suggestion: "Please try again or check your network connection.")
        }
    }
    
    func updateNote(_ note: Note, userId: String) {
        var updatedNote = note
        updatedNote.updatedAt = Date()
        
        do {
            try db.collection("users").document(userId).collection("notes")
                .document(note.id).setData(from: updatedNote)
            // Sync to widgets
            WidgetDataService.shared.syncDataForWidgets()
        } catch {
            showError("Failed to update note: \(error.localizedDescription)", suggestion: "Please try again or check your network connection.")
        }
    }
    
    func deleteNote(_ note: Note, userId: String) {
        db.collection("users").document(userId).collection("notes")
            .document(note.id).delete { [weak self] error in
                if let error = error {
                    self?.showError("Failed to delete note: \(error.localizedDescription)", suggestion: "Please try again or check your network connection.")
                } else {
                    // Sync to widgets
                    WidgetDataService.shared.syncDataForWidgets()
                }
            }
    }
    
    // MARK: - Accountability Groups
    private func setupGroupsListener(userId: String) {
        let listener = db.collection("accountabilityGroups")
            .whereField("members", arrayContains: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    self?.showError(error.localizedDescription)
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                self?.accountabilityGroups = documents.compactMap { doc -> AccountabilityGroup? in
                    try? doc.data(as: AccountabilityGroup.self)
                }
            }
        listeners.append(listener)
    }
    
    func createAccountabilityGroup(_ group: AccountabilityGroup) {
        do {
            try db.collection("accountabilityGroups")
                .document(group.id).setData(from: group)
        } catch {
            showError("Failed to create accountability group: \(error.localizedDescription)", suggestion: "Please try again or check your network connection.")
        }
    }
    
    func updateAccountabilityGroup(_ group: AccountabilityGroup) {
        var updatedGroup = group
        updatedGroup.updatedAt = Date()
        
        do {
            try db.collection("accountabilityGroups")
                .document(group.id).setData(from: updatedGroup)
        } catch {
            showError("Failed to update accountability group: \(error.localizedDescription)", suggestion: "Please try again or check your network connection.")
        }
    }
    
    // MARK: - Encouragements
    private func setupEncouragementListener(userId: String) {
        let listener = db.collection("encouragements")
            .whereField("toUserId", isEqualTo: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    self?.showError(error.localizedDescription)
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                self?.encouragements = documents.compactMap { doc -> Encouragement? in
                    try? doc.data(as: Encouragement.self)
                }
            }
        listeners.append(listener)
    }
    
    func sendEncouragement(_ encouragement: Encouragement) {
        do {
            try db.collection("encouragements")
                .document(encouragement.id).setData(from: encouragement)
        } catch {
            showError("Failed to send encouragement: \(error.localizedDescription)", suggestion: "Please try again or check your network connection.")
        }
    }
    
    func markEncouragementAsRead(_ encouragement: Encouragement) {
        var updatedEncouragement = encouragement
        updatedEncouragement.readAt = Date()
        
        do {
            try db.collection("encouragements")
                .document(encouragement.id).setData(from: updatedEncouragement)
        } catch {
            showError("Failed to mark encouragement as read: \(error.localizedDescription)", suggestion: "Please try again or check your network connection.")
        }
    }
    
    // MARK: - Dashboard Data
    func getDashboardData(for userId: String) -> DashboardData {
        let today = Calendar.current.startOfDay(for: Date())
        
        let todaysTasks = tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return Calendar.current.isDate(dueDate, inSameDayAs: today)
        }
        
        let todaysEvents = events.filter { event in
            return Calendar.current.isDate(event.startTime, inSameDayAs: today)
        }
        
        let recentGoals = Array(goals.filter { $0.status == .active }
            .sorted { $0.updatedAt > $1.updatedAt }
            .prefix(5))
        
        let quote = DailyQuote.samples.randomElement() ?? DailyQuote.samples[0]
        
        return DashboardData(
            weeklyKIs: keyIndicators,
            todaysTasks: todaysTasks,
            todaysEvents: todaysEvents,
            quote: quote,
            recentGoals: recentGoals
        )
    }
    
    // MARK: - Utility Methods
    func getGoalsForKeyIndicator(_ keyIndicatorId: String) -> [Goal] {
        return goals.filter { $0.keyIndicatorIds.contains(keyIndicatorId) }
    }
    
    func getTasksForGoal(_ goalId: String) -> [AppTask] {
        return tasks.filter { $0.linkedGoalId == goalId }
    }
    
    func getTasksForEvent(_ eventId: String) -> [AppTask] {
        return tasks.filter { $0.linkedEventId == eventId }
    }
    
    func getNotesForGoal(_ goalId: String) -> [Note] {
        return notes.filter { $0.linkedGoalIds.contains(goalId) }
    }
    
    // MARK: - Widget Sync
    func syncAllDataToWidgets() {
        WidgetDataService.shared.syncDataForWidgets()
    }
    
    // MARK: - Clear All User Data
    func clearAllUserData(userId: String, completion: @escaping () -> Void) {
        let group = DispatchGroup()
        let collections = [
            ("goals", goals.map { $0.id }),
            ("tasks", tasks.map { $0.id }),
            ("events", events.map { $0.id }),
            ("notes", notes.map { $0.id }),
            ("keyIndicators", keyIndicators.map { $0.id })
        ]
        
        for (collection, ids) in collections {
            for id in ids {
                group.enter()
                db.collection("users").document(userId).collection(collection).document(id).delete { _ in
                    group.leave()
                }
            }
        }
        // Accountability groups and encouragements are global collections
        for groupObj in accountabilityGroups where groupObj.members.contains(where: { $0.id == userId }) {
            group.enter()
            db.collection("accountabilityGroups").document(groupObj.id).delete { _ in
                group.leave()
            }
        }
        for encouragement in encouragements where encouragement.toUserId == userId {
            group.enter()
            db.collection("encouragements").document(encouragement.id).delete { _ in
                group.leave()
            }
        }
        group.notify(queue: .main) {
            // Clear local arrays
            self.goals = []
            self.tasks = []
            self.events = []
            self.notes = []
            self.keyIndicators = []
            self.accountabilityGroups = []
            self.encouragements = []
            completion()
        }
    }
    
    // MARK: - Goal Progress Updates
    private func updateGoalProgress(goalId: String, contribution: Double, userId: String) {
        print("🎯 DataManager: Updating goal progress for goal \(goalId)")
        print("🎯 DataManager: Contribution amount: \(contribution)")
        
        guard let goalIndex = goals.firstIndex(where: { $0.id == goalId }) else { 
            print("❌ DataManager: Goal not found with ID: \(goalId)")
            return 
        }
        
        var updatedGoal = goals[goalIndex]
        print("🎯 DataManager: Goal before update - Progress: \(updatedGoal.calculatedProgress)%, Current Value: \(updatedGoal.currentValue), Target Value: \(updatedGoal.targetValue)")
        
        updatedGoal.updateProgress(contribution: contribution)
        
        print("🎯 DataManager: Goal after update - Progress: \(updatedGoal.calculatedProgress)%, Current Value: \(updatedGoal.currentValue), Target Value: \(updatedGoal.targetValue)")
        
        // Update the local goals array
        goals[goalIndex] = updatedGoal
        
        // Update the goal in Firestore
        do {
            try db.collection("users").document(userId).collection("goals")
                .document(goalId).setData(from: updatedGoal)
            print("✅ DataManager: Goal progress updated successfully in Firestore")
        } catch {
            print("❌ DataManager: Failed to update goal progress in Firestore: \(error.localizedDescription)")
            showError("Failed to update goal progress: \(error.localizedDescription)", suggestion: "Please try again or check your network connection.")
        }
    }
    
    func getTimelineForGoal(goalId: String) -> [TimelineItem] {
        var timelineItems: [TimelineItem] = []
        
        // Add goal creation
        if let goal = goals.first(where: { $0.id == goalId }) {
            timelineItems.append(TimelineItem(
                type: .goal,
                date: goal.createdAt,
                title: "Goal Created: \(goal.title)",
                description: goal.description,
                relatedGoalId: goalId
            ))
        }
        
        // Add linked notes
        let linkedNotes = getNotesForGoal(goalId)
        for note in linkedNotes {
            timelineItems.append(TimelineItem(
                type: .note,
                date: note.createdAt,
                title: "Note Added: \(note.title)",
                description: note.content,
                relatedGoalId: goalId
            ))
        }
        
        // Add linked tasks
        let linkedTasks = getTasksForGoal(goalId)
        for task in linkedTasks {
            timelineItems.append(TimelineItem(
                type: .task,
                date: task.createdAt,
                title: "Task Created: \(task.title)",
                description: task.description,
                relatedGoalId: goalId,
                relatedTaskId: task.id
            ))
            
            if task.status == .completed, let completedAt = task.completedAt {
                timelineItems.append(TimelineItem(
                    type: .task,
                    date: completedAt,
                    title: "Task Completed: \(task.title)",
                    description: "Task marked as completed",
                    relatedGoalId: goalId,
                    relatedTaskId: task.id,
                    progressChange: task.progressContribution
                ))
            }
        }
        
        // Add linked events
        let linkedEvents = events.filter { $0.linkedGoalId == goalId }
        for event in linkedEvents {
            timelineItems.append(TimelineItem(
                type: .event,
                date: event.createdAt,
                title: "Event Created: \(event.title)",
                description: event.description,
                relatedGoalId: goalId,
                relatedEventId: event.id
            ))
            
            if event.status == .completed {
                timelineItems.append(TimelineItem(
                    type: .event,
                    date: event.updatedAt,
                    title: "Event Completed: \(event.title)",
                    description: "Event marked as completed",
                    relatedGoalId: goalId,
                    relatedEventId: event.id,
                    progressChange: event.progressContribution
                ))
            }
        }
        
        // Sort by date (newest first)
        return timelineItems.sorted { $0.date > $1.date }
    }
    
    private func showError(_ message: String, suggestion: String? = nil) {
        if let suggestion = suggestion {
            self.errorMessage = "\(message)\nSuggestion: \(suggestion)"
        } else {
            self.errorMessage = message
        }
        self.showError = true
    }
    
    func updateUser(_ user: User, userId: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        do {
            let userData = try JSONEncoder().encode(user)
            let userDict = try JSONSerialization.jsonObject(with: userData) as? [String: Any] ?? [:]
            db.collection("users").document(userId).setData(userDict) { error in
                if let error = error {
                    print("❌ DataManager: Failed to update user: \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("✅ DataManager: User updated successfully")
                    completion(true)
                }
            }
        } catch {
            print("❌ DataManager: Failed to encode user: \(error.localizedDescription)")
            completion(false)
        }
    }
}

// MARK: - Siri/AI Integration Stubs
extension DataManager {
    @MainActor
    func addTask(_ task: AppTask) async {}
    @MainActor
    func completeTaskByTitle(_ title: String) async {}
    @MainActor
    func getTasksForTimeFrame(_ timeFrame: String) async -> [AppTask] { return [] }
    @MainActor
    func addGoal(_ goal: Goal) async {}
    @MainActor
    func getGoals() async -> [Goal] { return [] }
    @MainActor
    func logKeyIndicator(name: String, value: Int) async {}
    @MainActor
    func getKeyIndicators() async -> [KeyIndicator] { return [] }
    @MainActor
    func getWeeklySummary() async -> String { return "" }
    @MainActor
    func addEvent(_ event: CalendarEvent) async {}
    @MainActor
    func getEventsForTimeFrame(_ timeFrame: String) async -> [CalendarEvent] { return [] }
    @MainActor
    func getNextEvent() async -> CalendarEvent? { return nil }
    @MainActor
    func logMood(mood: MoodType) async {}
    @MainActor
    func logMeditation(minutes: Int) async {}
    @MainActor
    func logWater(glasses: Int) async {}
    @MainActor
    func getWellnessSummary() async -> String { return "" }
    @MainActor
    func getSummaryForTimeFrame(_ timeFrame: String) async -> String { return "" }
    @MainActor
    func getOverallProgress() async -> Double { return 0.0 }
    @MainActor
    func updateGoalProgress(title: String, progress: Double) async {}
}