import Foundation
import Firebase
import FirebaseFirestore
import Combine

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
    
    private init() {}
    
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
    }
    
    func removeListeners() {
        print("📊 DataManager: Removing all listeners")
        listeners.forEach { $0.remove() }
        listeners.removeAll()
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
        } catch {
            print("❌ DataManager: Failed to create key indicator: \(error.localizedDescription)")
            print("❌ DataManager: Error: \(error)")
            showError("Failed to create key indicator: \(error.localizedDescription)")
        }
    }
    
    func updateKeyIndicator(_ keyIndicator: KeyIndicator, userId: String) {
        var updatedKI = keyIndicator
        updatedKI.updatedAt = Date()
        
        do {
            try db.collection("users").document(userId).collection("keyIndicators")
                .document(keyIndicator.id).setData(from: updatedKI)
        } catch {
            showError("Failed to update key indicator: \(error.localizedDescription)")
        }
    }
    
    func deleteKeyIndicator(_ keyIndicator: KeyIndicator, userId: String) {
        db.collection("users").document(userId).collection("keyIndicators")
            .document(keyIndicator.id).delete { [weak self] error in
                if let error = error {
                    self?.showError("Failed to delete key indicator: \(error.localizedDescription)")
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
        } catch {
            showError("Failed to create goal: \(error.localizedDescription)")
        }
    }
    
    func updateGoal(_ goal: Goal, userId: String) {
        var updatedGoal = goal
        updatedGoal.updatedAt = Date()
        
        do {
            try db.collection("users").document(userId).collection("goals")
                .document(goal.id).setData(from: updatedGoal)
        } catch {
            showError("Failed to update goal: \(error.localizedDescription)")
        }
    }
    
    func deleteGoal(_ goal: Goal, userId: String) {
        db.collection("users").document(userId).collection("goals")
            .document(goal.id).delete { [weak self] error in
                if let error = error {
                    self?.showError("Failed to delete goal: \(error.localizedDescription)")
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
        } catch {
            showError("Failed to create event: \(error.localizedDescription)")
        }
    }
    
    func updateEvent(_ event: CalendarEvent, userId: String) {
        var updatedEvent = event
        updatedEvent.updatedAt = Date()
        
        do {
            try db.collection("users").document(userId).collection("events")
                .document(event.id).setData(from: updatedEvent)
        } catch {
            showError("Failed to update event: \(error.localizedDescription)")
        }
    }
    
    func deleteEvent(_ event: CalendarEvent, userId: String) {
        db.collection("users").document(userId).collection("events")
            .document(event.id).delete { [weak self] error in
                if let error = error {
                    self?.showError("Failed to delete event: \(error.localizedDescription)")
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
        } catch {
            showError("Failed to create task: \(error.localizedDescription)")
        }
    }
    
    func updateTask(_ task: AppTask, userId: String) {
        var updatedTask = task
        updatedTask.updatedAt = Date()
        if task.status == .completed && task.completedAt == nil {
            updatedTask.completedAt = Date()
        }
        
        do {
            try db.collection("users").document(userId).collection("tasks")
                .document(task.id).setData(from: updatedTask)
        } catch {
            showError("Failed to update task: \(error.localizedDescription)")
        }
    }
    
    func deleteTask(_ task: AppTask, userId: String) {
        db.collection("users").document(userId).collection("tasks")
            .document(task.id).delete { [weak self] error in
                if let error = error {
                    self?.showError("Failed to delete task: \(error.localizedDescription)")
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
        } catch {
            showError("Failed to create note: \(error.localizedDescription)")
        }
    }
    
    func updateNote(_ note: Note, userId: String) {
        var updatedNote = note
        updatedNote.updatedAt = Date()
        
        do {
            try db.collection("users").document(userId).collection("notes")
                .document(note.id).setData(from: updatedNote)
        } catch {
            showError("Failed to update note: \(error.localizedDescription)")
        }
    }
    
    func deleteNote(_ note: Note, userId: String) {
        db.collection("users").document(userId).collection("notes")
            .document(note.id).delete { [weak self] error in
                if let error = error {
                    self?.showError("Failed to delete note: \(error.localizedDescription)")
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
            showError("Failed to create accountability group: \(error.localizedDescription)")
        }
    }
    
    func updateAccountabilityGroup(_ group: AccountabilityGroup) {
        var updatedGroup = group
        updatedGroup.updatedAt = Date()
        
        do {
            try db.collection("accountabilityGroups")
                .document(group.id).setData(from: updatedGroup)
        } catch {
            showError("Failed to update accountability group: \(error.localizedDescription)")
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
            showError("Failed to send encouragement: \(error.localizedDescription)")
        }
    }
    
    func markEncouragementAsRead(_ encouragement: Encouragement) {
        var updatedEncouragement = encouragement
        updatedEncouragement.readAt = Date()
        
        do {
            try db.collection("encouragements")
                .document(encouragement.id).setData(from: updatedEncouragement)
        } catch {
            showError("Failed to mark encouragement as read: \(error.localizedDescription)")
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
    
    private func showError(_ message: String) {
        DispatchQueue.main.async {
            self.errorMessage = message
            self.showError = true
            
            // Auto-hide after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.showError = false
            }
        }
    }
}