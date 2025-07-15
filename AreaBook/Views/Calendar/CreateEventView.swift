import SwiftUI

struct CreateEventView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var title = ""
    @State private var description = ""
    @State private var category = "Personal"
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
    @State private var isAllDay = false
    @State private var selectedGoalId: String?
    @State private var selectedKeyIndicatorIds: Set<String> = []
    @State private var isRecurring = false
    @State private var recurrenceType: RecurrenceType = .weekly
    @State private var recurrenceInterval = 1
    @State private var selectedDaysOfWeek: Set<Int> = []
    @State private var recurrenceEndDate: Date?
    @State private var hasRecurrenceEndDate = false
    @State private var linkedTasks: [Task] = []
    @State private var showingTaskCreation = false
    
    let eventToEdit: CalendarEvent?
    let prefilledDate: Date?
    
    private let categories = ["Personal", "Church", "School", "Work", "Family", "Health", "Other"]
    private let weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    
    init(eventToEdit: CalendarEvent? = nil, prefilledDate: Date? = nil) {
        self.eventToEdit = eventToEdit
        self.prefilledDate = prefilledDate
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Basic Information Section
                Section("Event Details") {
                    TextField("Event Title", text: $title)
                    
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3)
                    
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                }
                
                // Date and Time Section
                Section("Date & Time") {
                    Toggle("All Day", isOn: $isAllDay)
                    
                    DatePicker("Start", selection: $startDate, displayedComponents: isAllDay ? [.date] : [.date, .hourAndMinute])
                        .onChange(of: startDate) { newDate in
                            if endDate <= newDate {
                                endDate = Calendar.current.date(byAdding: .hour, value: 1, to: newDate) ?? newDate
                            }
                        }
                    
                    DatePicker("End", selection: $endDate, displayedComponents: isAllDay ? [.date] : [.date, .hourAndMinute])
                        .disabled(isAllDay)
                    
                    if isAllDay {
                        Text("All-day events end at midnight of the selected day")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Goal Linking Section
                if !dataManager.goals.isEmpty {
                    Section("Link to Goal") {
                        Picker("Goal (Optional)", selection: $selectedGoalId) {
                            Text("None").tag(nil as String?)
                            ForEach(dataManager.goals.filter { $0.status == .active }) { goal in
                                Text(goal.title).tag(goal.id as String?)
                            }
                        }
                    }
                }
                
                // Key Indicators Section
                if !dataManager.keyIndicators.isEmpty {
                    Section("Link to Key Indicators") {
                        Text("Select Key Indicators that will be updated when this event is completed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                            ForEach(dataManager.keyIndicators) { ki in
                                KISelectionCard(
                                    keyIndicator: ki,
                                    isSelected: selectedKeyIndicatorIds.contains(ki.id)
                                ) {
                                    if selectedKeyIndicatorIds.contains(ki.id) {
                                        selectedKeyIndicatorIds.remove(ki.id)
                                    } else {
                                        selectedKeyIndicatorIds.insert(ki.id)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Recurrence Section
                Section("Repeat") {
                    Toggle("Recurring Event", isOn: $isRecurring)
                    
                    if isRecurring {
                        Picker("Repeat", selection: $recurrenceType) {
                            ForEach(RecurrenceType.allCases, id: \.self) { type in
                                Text(type.rawValue.capitalized).tag(type)
                            }
                        }
                        
                        Stepper("Every \(recurrenceInterval) \(recurrenceType.rawValue)\(recurrenceInterval > 1 ? "s" : "")", 
                               value: $recurrenceInterval, in: 1...52)
                        
                        if recurrenceType == .weekly {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Repeat On")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                                    ForEach(0..<7, id: \.self) { dayIndex in
                                        Button(action: {
                                            if selectedDaysOfWeek.contains(dayIndex) {
                                                selectedDaysOfWeek.remove(dayIndex)
                                            } else {
                                                selectedDaysOfWeek.insert(dayIndex)
                                            }
                                        }) {
                                            Text(String(weekdays[dayIndex].prefix(3)))
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundColor(selectedDaysOfWeek.contains(dayIndex) ? .white : .primary)
                                                .frame(width: 40, height: 30)
                                                .background(selectedDaysOfWeek.contains(dayIndex) ? Color.blue : Color(.systemGray5))
                                                .cornerRadius(6)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                        }
                        
                        Toggle("End Repeat", isOn: $hasRecurrenceEndDate)
                        
                        if hasRecurrenceEndDate {
                            DatePicker("End Date", selection: Binding(
                                get: { recurrenceEndDate ?? Calendar.current.date(byAdding: .month, value: 1, to: Date())! },
                                set: { recurrenceEndDate = $0 }
                            ), displayedComponents: [.date])
                        }
                    }
                }
                
                // Tasks Section
                Section("Related Tasks") {
                    if linkedTasks.isEmpty {
                        Button("Add Task") {
                            showingTaskCreation = true
                        }
                        .foregroundColor(.blue)
                    } else {
                        ForEach(linkedTasks) { task in
                            HStack {
                                Circle()
                                    .fill(task.priority.color)
                                    .frame(width: 8, height: 8)
                                Text(task.title)
                                    .font(.subheadline)
                                Spacer()
                                Button("Remove") {
                                    linkedTasks.removeAll { $0.id == task.id }
                                }
                                .font(.caption)
                                .foregroundColor(.red)
                            }
                        }
                        
                        Button("Add Another Task") {
                            showingTaskCreation = true
                        }
                        .foregroundColor(.blue)
                    }
                }
                
                // Preview Section
                Section("Preview") {
                    EventPreviewCard(
                        title: title.isEmpty ? "Event Title" : title,
                        description: description,
                        category: category,
                        startDate: startDate,
                        endDate: endDate,
                        isAllDay: isAllDay,
                        isRecurring: isRecurring,
                        recurrenceType: recurrenceType,
                        recurrenceInterval: recurrenceInterval
                    )
                }
            }
            .navigationTitle(eventToEdit == nil ? "New Event" : "Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveEvent()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .onAppear {
                loadEventData()
                setupDefaultRecurrence()
                setupPrefilledDate()
            }
            .sheet(isPresented: $showingTaskCreation) {
                CreateTaskForEventView { task in
                    linkedTasks.append(task)
                }
            }
        }
    }
    
    private func setupDefaultRecurrence() {
        if eventToEdit == nil {
            // Set default days of week based on start date
            let dayOfWeek = Calendar.current.component(.weekday, from: startDate) - 1
            selectedDaysOfWeek = [dayOfWeek]
        }
    }
    
    private func setupPrefilledDate() {
        if let prefilled = prefilledDate, eventToEdit == nil {
            startDate = prefilled
            endDate = Calendar.current.date(byAdding: .hour, value: 1, to: prefilled) ?? prefilled
            
            // Update default recurrence days
            let dayOfWeek = Calendar.current.component(.weekday, from: prefilled) - 1
            selectedDaysOfWeek = [dayOfWeek]
        }
    }
    
    private func loadEventData() {
        guard let event = eventToEdit else { return }
        
        title = event.title
        description = event.description
        category = event.category
        startDate = event.startTime
        endDate = event.endTime
        selectedGoalId = event.linkedGoalId
        selectedKeyIndicatorIds = Set(event.linkedKeyIndicatorIds)
        isRecurring = event.isRecurring
        
        if let pattern = event.recurrencePattern {
            recurrenceType = pattern.type
            recurrenceInterval = pattern.interval
            selectedDaysOfWeek = Set(pattern.daysOfWeek ?? [])
            recurrenceEndDate = pattern.endDate
            hasRecurrenceEndDate = pattern.endDate != nil
        }
        
        // Load linked tasks
        linkedTasks = dataManager.getTasksForEvent(event.id)
    }
    
    private func saveEvent() {
        guard let userId = authViewModel.currentUser?.id else { return }
        
        // Create recurrence pattern if needed
        var recurrencePattern: RecurrencePattern?
        if isRecurring {
            recurrencePattern = RecurrencePattern(
                type: recurrenceType,
                interval: recurrenceInterval,
                daysOfWeek: recurrenceType == .weekly ? Array(selectedDaysOfWeek) : nil,
                endDate: hasRecurrenceEndDate ? recurrenceEndDate : nil
            )
        }
        
        var event: CalendarEvent
        if let existingEvent = eventToEdit {
            event = CalendarEvent(
                title: title,
                description: description,
                category: category,
                startTime: startDate,
                endTime: isAllDay ? Calendar.current.startOfDay(for: endDate.addingTimeInterval(86400)) : endDate,
                linkedGoalId: selectedGoalId,
                linkedKeyIndicatorIds: Array(selectedKeyIndicatorIds)
            )
            event.id = existingEvent.id
            event.taskIds = linkedTasks.map { $0.id }
            event.isRecurring = isRecurring
            event.recurrencePattern = recurrencePattern
            event.status = existingEvent.status
            event.createdAt = existingEvent.createdAt
            event.updatedAt = Date()
        } else {
            event = CalendarEvent(
                title: title,
                description: description,
                category: category,
                startTime: startDate,
                endTime: isAllDay ? Calendar.current.startOfDay(for: endDate.addingTimeInterval(86400)) : endDate,
                linkedGoalId: selectedGoalId,
                linkedKeyIndicatorIds: Array(selectedKeyIndicatorIds)
            )
            event.taskIds = linkedTasks.map { $0.id }
            event.isRecurring = isRecurring
            event.recurrencePattern = recurrencePattern
        }
        
        // Save event
        if eventToEdit != nil {
            dataManager.updateEvent(event, userId: userId)
        } else {
            dataManager.createEvent(event, userId: userId)
        }
        
        // Save linked tasks
        for task in linkedTasks {
            var taskToSave = task
            taskToSave.linkedEventId = event.id
            
            if dataManager.tasks.contains(where: { $0.id == task.id }) {
                dataManager.updateTask(taskToSave, userId: userId)
            } else {
                dataManager.createTask(taskToSave, userId: userId)
            }
        }
        
        dismiss()
    }
}

struct EventPreviewCard: View {
    let title: String
    let description: String
    let category: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let isRecurring: Bool
    let recurrenceType: RecurrenceType
    let recurrenceInterval: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                Spacer()
                
                Text(category)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(6)
            }
            
            if !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    
                    if isAllDay {
                        Text("All day")
                            .font(.caption)
                    } else {
                        Text("\(startDate, style: .time) - \(endDate, style: .time)")
                            .font(.caption)
                    }
                    
                    Spacer()
                }
                
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    
                    Text(startDate, style: .date)
                        .font(.caption)
                    
                    if isRecurring {
                        Text("• Repeats every \(recurrenceInterval) \(recurrenceType.rawValue)\(recurrenceInterval > 1 ? "s" : "")")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
}

struct CreateTaskForEventView: View {
    let onSave: (Task) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var priority: TaskPriority = .medium
    @State private var dueDate: Date?
    @State private var hasDueDate = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Task Details") {
                    TextField("Task Title", text: $title)
                    
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(2)
                    
                    Picker("Priority", selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            HStack {
                                Circle()
                                    .fill(priority.color)
                                    .frame(width: 12, height: 12)
                                Text(priority.rawValue.capitalized)
                            }
                            .tag(priority)
                        }
                    }
                }
                
                Section("Due Date") {
                    Toggle("Set due date", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker("Due Date", selection: Binding(
                            get: { dueDate ?? Date() },
                            set: { dueDate = $0 }
                        ), displayedComponents: [.date, .hourAndMinute])
                    }
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        let task = Task(
                            title: title,
                            description: description.isEmpty ? nil : description,
                            priority: priority,
                            dueDate: hasDueDate ? dueDate : nil
                        )
                        onSave(task)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

// MARK: - Recurring Events Generator
class RecurringEventsGenerator {
    static func generateRecurringEvents(from baseEvent: CalendarEvent, until endDate: Date) -> [CalendarEvent] {
        guard baseEvent.isRecurring,
              let pattern = baseEvent.recurrencePattern else {
            return []
        }
        
        var events: [CalendarEvent] = []
        var currentDate = baseEvent.startTime
        let finalEndDate = pattern.endDate ?? endDate
        
        while currentDate <= finalEndDate {
            let nextDate = calculateNextOccurrence(from: currentDate, pattern: pattern)
            
            if nextDate > finalEndDate {
                break
            }
            
            if nextDate != baseEvent.startTime { // Don't duplicate the original event
                let duration = baseEvent.endTime.timeIntervalSince(baseEvent.startTime)
                let newEvent = CalendarEvent(
                    title: baseEvent.title,
                    description: baseEvent.description,
                    category: baseEvent.category,
                    startTime: nextDate,
                    endTime: nextDate.addingTimeInterval(duration),
                    linkedGoalId: baseEvent.linkedGoalId
                )
                newEvent.taskIds = baseEvent.taskIds
                newEvent.isRecurring = false // Generated events are not themselves recurring
                
                events.append(newEvent)
            }
            
            currentDate = nextDate
        }
        
        return events
    }
    
    private static func calculateNextOccurrence(from date: Date, pattern: RecurrencePattern) -> Date {
        let calendar = Calendar.current
        
        switch pattern.type {
        case .daily:
            return calendar.date(byAdding: .day, value: pattern.interval, to: date) ?? date
            
        case .weekly:
            if let daysOfWeek = pattern.daysOfWeek, !daysOfWeek.isEmpty {
                // Find next occurrence on specified days
                let currentWeekday = calendar.component(.weekday, from: date) - 1 // 0-6
                let sortedDays = daysOfWeek.sorted()
                
                // Find next day in this week
                if let nextDay = sortedDays.first(where: { $0 > currentWeekday }) {
                    let daysToAdd = nextDay - currentWeekday
                    return calendar.date(byAdding: .day, value: daysToAdd, to: date) ?? date
                } else {
                    // Go to first day of next interval week
                    let daysToNextWeek = 7 - currentWeekday + sortedDays[0]
                    let weeksToAdd = (pattern.interval - 1) * 7
                    return calendar.date(byAdding: .day, value: daysToNextWeek + weeksToAdd, to: date) ?? date
                }
            } else {
                return calendar.date(byAdding: .weekOfYear, value: pattern.interval, to: date) ?? date
            }
            
        case .monthly:
            return calendar.date(byAdding: .month, value: pattern.interval, to: date) ?? date
            
        case .yearly:
            return calendar.date(byAdding: .year, value: pattern.interval, to: date) ?? date
        }
    }
}

#Preview {
    CreateEventView()
        .environmentObject(DataManager.shared)
        .environmentObject(AuthViewModel())
}