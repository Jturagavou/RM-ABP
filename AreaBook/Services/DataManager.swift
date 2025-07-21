import Foundation
import Firebase
import FirebaseFirestore
import Combine
import WidgetKit

class DataManager: ObservableObject {
    static let shared = DataManager()
    
    @Published var keyIndicators: [KeyIndicator] = [] {
        didSet { updateWidgetData() }
    }
    @Published var goals: [Goal] = []
    @Published var events: [CalendarEvent] = [] {
        didSet { updateWidgetData() }
    }
    @Published var tasks: [Task] = [] {
        didSet { updateWidgetData() }
    }
    @Published var notes: [Note] = []
    @Published var accountabilityGroups: [AccountabilityGroup] = []
    @Published var encouragements: [Encouragement] = []
    
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showError = false
    
    private let db = Firestore.firestore()
    private var listeners: [ListenerRegistration] = []
    private var cancellables = Set<AnyCancellable>()
    private var currentUserId: String?
    private var currentUserName: String?
    
    private init() {}
    
    func setupListeners(for userId: String, userName: String? = nil) {
        removeListeners()
        currentUserId = userId
        currentUserName = userName
        
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
        listeners.forEach { $0.remove() }
        listeners.removeAll()
        currentUserId = nil
        currentUserName = nil
    }
    
    // MARK: - Widget Data Sync
    private func updateWidgetData() {
        WidgetDataManager.shared.scheduleWidgetUpdate(
            keyIndicators: keyIndicators,
            tasks: tasks,
            events: events,
            userName: currentUserName
        )
    }
    
    // MARK: - Key Indicators
    private func setupKeyIndicatorsListener(userId: String) {
        let listener = db.collection("users").document(userId).collection("keyIndicators")
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    self?.showError(error.localizedDescription)
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                self?.keyIndicators = documents.compactMap { doc -> KeyIndicator? in
                    try? doc.data(as: KeyIndicator.self)
                }
            }
        listeners.append(listener)
    }
    
    func createKeyIndicator(_ keyIndicator: KeyIndicator, userId: String) {
        do {
            try db.collection("users").document(userId).collection("keyIndicators")
                .document(keyIndicator.id).setData(from: keyIndicator)
        } catch {
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
                
                self?.tasks = documents.compactMap { doc -> Task? in
                    try? doc.data(as: Task.self)
                }
            }
        listeners.append(listener)
    }
    
    func createTask(_ task: Task, userId: String) {
        do {
            try db.collection("users").document(userId).collection("tasks")
                .document(task.id).setData(from: task)
        } catch {
            showError("Failed to create task: \(error.localizedDescription)")
        }
    }
    
    func updateTask(_ task: Task, userId: String) {
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
    
    func deleteTask(_ task: Task, userId: String) {
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
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        let todaysTasks = tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return Calendar.current.isDate(dueDate, inSameDayAs: today)
        }
        
        // More efficient: filter non-recurring events first, then check recurring ones
        let regularTodayEvents = events.filter { event in
            !event.isRecurring && Calendar.current.isDate(event.startTime, inSameDayAs: today)
        }
        
        let recurringTodayEvents = events.compactMap { event -> CalendarEvent? in
            guard event.isRecurring, let pattern = event.recurrencePattern else { return nil }
            
            // Skip if event hasn't started yet or has ended
            if today < Calendar.current.startOfDay(for: event.startTime) { return nil }
            if let endDate = pattern.endDate, today > endDate { return nil }
            
            if CalendarHelper.isRecurringEventOccursOnDate(event: event, pattern: pattern, date: today) {
                var todayOccurrence = event
                todayOccurrence.startTime = CalendarHelper.combineDateWithTime(date: today, time: event.startTime)
                todayOccurrence.endTime = CalendarHelper.combineDateWithTime(date: today, time: event.endTime)
                return todayOccurrence
            }
            return nil
        }
        
        let todaysEvents = (regularTodayEvents + recurringTodayEvents).sorted { $0.startTime < $1.startTime }
        
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
    
    func getTasksForGoal(_ goalId: String) -> [Task] {
        return tasks.filter { $0.linkedGoalId == goalId }
    }
    
    func getTasksForEvent(_ eventId: String) -> [Task] {
        return tasks.filter { $0.linkedEventId == eventId }
    }
    
    func getNotesForGoal(_ goalId: String) -> [Note] {
        return notes.filter { $0.linkedGoalIds.contains(goalId) }
    }
    
    private func showError(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            self?.errorMessage = message
            self?.showError = true
            
            // Log error for debugging
            print("[DataManager Error] \(Date()): \(message)")
            
            // Auto-hide after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                self?.showError = false
            }
        }
    }
}