import SwiftUI

struct CreateTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var title = ""
    @State private var description = ""
    @State private var priority: TaskPriority = .medium
    @State private var dueDate: Date?
    @State private var hasDueDate = false
    @State private var selectedGoalId: String?
    @State private var selectedEventId: String?
    @State private var subtasks: [Subtask] = []
    @State private var newSubtaskText = ""
    @State private var showingSubtaskSheet = false
    @State private var reminderDate: Date?
    @State private var hasReminder = false
    @State private var estimatedDuration: TimeInterval?
    @State private var hasEstimatedDuration = false
    @State private var selectedDurationHours = 0
    @State private var selectedDurationMinutes = 30
    @State private var progressAmount: Int = 0
    @State private var connectedKeyIndicatorId: String?
    @State private var hasProgressTracking = false
    
    let taskToEdit: Task?
    
    init(taskToEdit: Task? = nil) {
        self.taskToEdit = taskToEdit
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Basic Information Section
                Section("Task Details") {
                    TextField("Task Title", text: $title)
                    
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3)
                    
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
                
                // Due Date Section
                Section("Due Date & Time") {
                    Toggle("Set due date", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker("Due Date", selection: Binding(
                            get: { dueDate ?? Date() },
                            set: { dueDate = $0 }
                        ), displayedComponents: [.date, .hourAndMinute])
                        
                        Toggle("Set reminder", isOn: $hasReminder)
                        
                        if hasReminder {
                            DatePicker("Reminder", selection: Binding(
                                get: { reminderDate ?? Date() },
                                set: { reminderDate = $0 }
                            ), displayedComponents: [.date, .hourAndMinute])
                            
                            Text("You'll be notified at this time")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Duration Estimation Section
                Section("Time Estimation") {
                    Toggle("Estimate duration", isOn: $hasEstimatedDuration)
                    
                    if hasEstimatedDuration {
                        HStack {
                            Picker("Hours", selection: $selectedDurationHours) {
                                ForEach(0..<24, id: \.self) { hour in
                                    Text("\(hour)h").tag(hour)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: 80)
                            
                            Picker("Minutes", selection: $selectedDurationMinutes) {
                                ForEach([0, 15, 30, 45], id: \.self) { minute in
                                    Text("\(minute)m").tag(minute)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: 80)
                        }
                        .onChange(of: selectedDurationHours) { _ in updateEstimatedDuration() }
                        .onChange(of: selectedDurationMinutes) { _ in updateEstimatedDuration() }
                        
                        if let duration = estimatedDuration {
                            Text("Estimated: \(formatDuration(duration))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
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
                
                // Event Linking Section
                if !dataManager.events.isEmpty {
                    Section("Link to Event") {
                        Picker("Event (Optional)", selection: $selectedEventId) {
                            Text("None").tag(nil as String?)
                            ForEach(dataManager.events.filter { event in
                                Calendar.current.isDate(event.startTime, greaterThan: Date().addingTimeInterval(-86400))
                            }) { event in
                                VStack(alignment: .leading) {
                                    Text(event.title)
                                    Text(event.startTime, style: .date)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .tag(event.id as String?)
                            }
                        }
                    }
                }
                
                // Progress Tracking Section
                if !dataManager.keyIndicators.isEmpty {
                    Section("Progress Tracking") {
                        Toggle("Track Progress", isOn: $hasProgressTracking)
                        
                        if hasProgressTracking {
                            Picker("Key Indicator", selection: $connectedKeyIndicatorId) {
                                Text("None").tag(nil as String?)
                                ForEach(dataManager.keyIndicators) { ki in
                                    Text(ki.name).tag(ki.id as String?)
                                }
                            }
                            
                            HStack {
                                Text("Progress Amount:")
                                
                                Spacer()
                                
                                Stepper(value: $progressAmount, in: 0...1000, step: 1) {
                                    Text("\(progressAmount)")
                                        .fontWeight(.medium)
                                }
                            }
                            
                            if let selectedKIId = connectedKeyIndicatorId,
                               let ki = dataManager.keyIndicators.first(where: { $0.id == selectedKIId }) {
                                Text("Completing this task will add \(progressAmount) to \(ki.name) (\(ki.unit))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // Subtasks Section
                Section {
                    if subtasks.isEmpty {
                        Button("Add Subtask") {
                            showingSubtaskSheet = true
                        }
                        .foregroundColor(.blue)
                    } else {
                        ForEach(subtasks.indices, id: \.self) { index in
                            SubtaskRow(
                                subtask: subtasks[index],
                                onToggle: {
                                    subtasks[index].completed.toggle()
                                },
                                onEdit: { newTitle in
                                    subtasks[index].title = newTitle
                                },
                                onDelete: {
                                    subtasks.remove(at: index)
                                }
                            )
                        }
                        
                        Button("Add Another Subtask") {
                            showingSubtaskSheet = true
                        }
                        .foregroundColor(.blue)
                    }
                } header: {
                    HStack {
                        Text("Subtasks")
                        Spacer()
                        if !subtasks.isEmpty {
                            Text("\(subtasks.filter { $0.completed }.count)/\(subtasks.count) completed")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Preview Section
                Section("Preview") {
                    TaskPreviewCard(
                        title: title.isEmpty ? "Task Title" : title,
                        description: description,
                        priority: priority,
                        dueDate: hasDueDate ? dueDate : nil,
                        subtasksCount: subtasks.count,
                        completedSubtasks: subtasks.filter { $0.completed }.count,
                        estimatedDuration: hasEstimatedDuration ? estimatedDuration : nil
                    )
                }
            }
            .navigationTitle(taskToEdit == nil ? "New Task" : "Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTask()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .onAppear {
                loadTaskData()
                updateEstimatedDuration()
            }
            .sheet(isPresented: $showingSubtaskSheet) {
                CreateSubtaskSheet { subtask in
                    subtasks.append(subtask)
                }
            }
        }
    }
    
    private func updateEstimatedDuration() {
        if hasEstimatedDuration {
            estimatedDuration = TimeInterval(selectedDurationHours * 3600 + selectedDurationMinutes * 60)
        } else {
            estimatedDuration = nil
        }
    }
    
    private func loadTaskData() {
        guard let task = taskToEdit else { return }
        
        title = task.title
        description = task.description ?? ""
        priority = task.priority
        dueDate = task.dueDate
        hasDueDate = task.dueDate != nil
        selectedGoalId = task.linkedGoalId
        selectedEventId = task.linkedEventId
        subtasks = task.subtasks
        
        // Load duration estimation if available
        if let duration = estimatedDuration {
            hasEstimatedDuration = true
            selectedDurationHours = Int(duration) / 3600
            selectedDurationMinutes = (Int(duration) % 3600) / 60
        }
        
        // Load progress tracking data
        progressAmount = task.progressAmount ?? 0
        connectedKeyIndicatorId = task.connectedKeyIndicatorId
        hasProgressTracking = task.connectedKeyIndicatorId != nil
    }
    
    private func saveTask() {
        guard let userId = authViewModel.currentUser?.id else { return }
        
        var task: Task
        if let existingTask = taskToEdit {
            task = existingTask
            task.title = title
            task.description = description.isEmpty ? nil : description
            task.priority = priority
            task.dueDate = hasDueDate ? dueDate : nil
            task.linkedGoalId = selectedGoalId
            task.linkedEventId = selectedEventId
            task.subtasks = subtasks
            task.updatedAt = Date()
            task.progressAmount = hasProgressTracking ? progressAmount : nil
            task.connectedKeyIndicatorId = hasProgressTracking ? connectedKeyIndicatorId : nil
        } else {
            task = Task(
                title: title,
                description: description.isEmpty ? nil : description,
                priority: priority,
                dueDate: hasDueDate ? dueDate : nil,
                linkedGoalId: selectedGoalId,
                linkedEventId: selectedEventId,
                progressAmount: hasProgressTracking ? progressAmount : nil,
                connectedKeyIndicatorId: hasProgressTracking ? connectedKeyIndicatorId : nil
            )
            task.subtasks = subtasks
        }
        
        if taskToEdit != nil {
            dataManager.updateTask(task, userId: userId)
        } else {
            dataManager.createTask(task, userId: userId)
        }
        
        // Schedule reminder if needed
        if hasReminder, let reminderDate = reminderDate {
            NotificationManager.shared.scheduleTaskReminder(for: task, at: reminderDate)
        }
        
        dismiss()
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct SubtaskRow: View {
    let subtask: Subtask
    let onToggle: () -> Void
    let onEdit: (String) -> Void
    let onDelete: () -> Void
    
    @State private var isEditing = false
    @State private var editText = ""
    @State private var showingDeleteAlert = false
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: subtask.completed ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(subtask.completed ? .green : .gray)
                    .font(.title3)
            }
            
            if isEditing {
                TextField("Subtask", text: $editText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        onEdit(editText)
                        isEditing = false
                    }
            } else {
                Text(subtask.title)
                    .font(.subheadline)
                    .strikethrough(subtask.completed)
                    .foregroundColor(subtask.completed ? .secondary : .primary)
                    .onTapGesture {
                        editText = subtask.title
                        isEditing = true
                    }
            }
            
            Spacer()
            
            Menu {
                Button("Edit") {
                    editText = subtask.title
                    isEditing = true
                }
                
                Button("Delete", role: .destructive) {
                    showingDeleteAlert = true
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
        }
        .alert("Delete Subtask", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this subtask?")
        }
    }
}

struct CreateSubtaskSheet: View {
    let onSave: (Subtask) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Subtask title", text: $title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.title3)
                
                Spacer()
            }
            .padding()
            .navigationTitle("New Subtask")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        let subtask = Subtask(title: title)
                        onSave(subtask)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

struct TaskPreviewCard: View {
    let title: String
    let description: String
    let priority: TaskPriority
    let dueDate: Date?
    let subtasksCount: Int
    let completedSubtasks: Int
    let estimatedDuration: TimeInterval?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(priority.color)
                    .frame(width: 12, height: 12)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                Spacer()
                
                Text(priority.rawValue.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(priority.color.opacity(0.2))
                    .foregroundColor(priority.color)
                    .cornerRadius(4)
            }
            
            if !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                if let dueDate = dueDate {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.secondary)
                            .font(.caption)
                        Text("Due: \(dueDate, style: .date) at \(dueDate, style: .time)")
                            .font(.caption)
                        Spacer()
                    }
                }
                
                if subtasksCount > 0 {
                    HStack {
                        Image(systemName: "list.bullet")
                            .foregroundColor(.secondary)
                            .font(.caption)
                        Text("\(completedSubtasks)/\(subtasksCount) subtasks completed")
                            .font(.caption)
                        Spacer()
                    }
                }
                
                if let duration = estimatedDuration {
                    HStack {
                        Image(systemName: "timer")
                            .foregroundColor(.secondary)
                            .font(.caption)
                        Text("Estimated: \(formatDuration(duration))")
                            .font(.caption)
                        Spacer()
                    }
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Task Templates
struct TaskTemplatesView: View {
    let onSelectTemplate: (TaskTemplate) -> Void
    @Environment(\.dismiss) private var dismiss
    
    private let templates = TaskTemplate.defaultTemplates
    
    var body: some View {
        NavigationView {
            List {
                Section("Quick Templates") {
                    ForEach(templates) { template in
                        Button(action: {
                            onSelectTemplate(template)
                            dismiss()
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Circle()
                                        .fill(template.priority.color)
                                        .frame(width: 10, height: 10)
                                    Text(template.title)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                                
                                if !template.description.isEmpty {
                                    Text(template.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                                
                                if !template.subtasks.isEmpty {
                                    Text("\(template.subtasks.count) subtasks included")
                                        .font(.caption2)
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .navigationTitle("Task Templates")
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

struct TaskTemplate: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let priority: TaskPriority
    let subtasks: [String]
    let estimatedDuration: TimeInterval?
    
    static let defaultTemplates = [
        TaskTemplate(
            title: "Morning Workout",
            description: "Daily exercise routine to stay healthy",
            priority: .high,
            subtasks: ["Warm up", "Main workout", "Cool down and stretch"],
            estimatedDuration: 45 * 60
        ),
        TaskTemplate(
            title: "Weekly Planning",
            description: "Review goals and plan the upcoming week",
            priority: .medium,
            subtasks: ["Review last week's progress", "Set goals for new week", "Schedule important events"],
            estimatedDuration: 45 * 60
        ),
        TaskTemplate(
            title: "Meal Prep Sunday",
            description: "Prepare healthy meals for the week",
            priority: .high,
            subtasks: ["Plan weekly menu", "Grocery shopping", "Batch cook meals", "Store in containers"],
            estimatedDuration: 180 * 60
        ),
        TaskTemplate(
            title: "Learning Session",
            description: "Dedicated time for skill development",
            priority: .medium,
            subtasks: ["Choose learning material", "Take notes", "Practice exercises", "Review progress"],
            estimatedDuration: 60 * 60
        ),
        TaskTemplate(
            title: "House Cleaning",
            description: "Weekly deep clean and organization",
            priority: .medium,
            subtasks: ["Declutter living spaces", "Vacuum and mop", "Clean bathrooms", "Organize closets"],
            estimatedDuration: 120 * 60
        )
    ]
}

// MARK: - Notification Manager
class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    func scheduleTaskReminder(for task: Task, at date: Date) {
        // Implementation would use UNUserNotificationCenter
        // This is a placeholder for the notification scheduling logic
        print("Scheduling reminder for task: \(task.title) at \(date)")
    }
}

#Preview {
    CreateTaskView()
        .environmentObject(DataManager.shared)
        .environmentObject(AuthViewModel())
}