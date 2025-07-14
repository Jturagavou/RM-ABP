import SwiftUI

struct GroupTaskAssignmentView: View {
    let groupId: String
    
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var collaborationManager = CollaborationManager.shared
    @State private var showingCreateAssignment = false
    @State private var selectedFilter: AssignmentFilter = .all
    
    enum AssignmentFilter: String, CaseIterable {
        case all = "All"
        case assigned = "Assigned to Me"
        case created = "Created by Me"
        case pending = "Pending"
        case completed = "Completed"
    }
    
    var filteredAssignments: [GroupTaskAssignment] {
        guard let currentUserId = authViewModel.currentUser?.id else { return [] }
        
        let assignments = collaborationManager.groupTaskAssignments
        
        switch selectedFilter {
        case .all:
            return assignments
        case .assigned:
            return assignments.filter { $0.assignedToId == currentUserId }
        case .created:
            return assignments.filter { $0.assignedById == currentUserId }
        case .pending:
            return assignments.filter { $0.status == .pending }
        case .completed:
            return assignments.filter { $0.status == .completed }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.blue)
                        Text("Task Assignments")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                        Button("Assign Task") {
                            showingCreateAssignment = true
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    
                    // Filter Picker
                    Picker("Filter", selection: $selectedFilter) {
                        ForEach(AssignmentFilter.allCases, id: \.self) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .padding()
                .background(Color(.systemGray6))
                
                // Assignments List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredAssignments) { assignment in
                            TaskAssignmentRow(assignment: assignment, onStatusUpdate: { status in
                                updateAssignmentStatus(assignment, status: status)
                            })
                        }
                        
                        if filteredAssignments.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "clipboard")
                                    .font(.system(size: 48))
                                    .foregroundColor(.gray)
                                
                                Text("No Assignments")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                Text("Group task assignments help keep everyone accountable and organized")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                
                                Button("Create First Assignment") {
                                    showingCreateAssignment = true
                                }
                                .font(.body)
                                .foregroundColor(.blue)
                            }
                            .padding(.vertical, 40)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Assignments")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadAssignments()
            }
            .sheet(isPresented: $showingCreateAssignment) {
                CreateTaskAssignmentView(groupId: groupId)
            }
        }
    }
    
    private func loadAssignments() {
        Task {
            try await collaborationManager.loadTaskAssignments(for: groupId)
        }
    }
    
    private func updateAssignmentStatus(_ assignment: GroupTaskAssignment, status: AssignmentStatus) {
        Task {
            try await collaborationManager.updateTaskAssignmentStatus(
                assignmentId: assignment.id,
                status: status
            )
        }
    }
}

struct TaskAssignmentRow: View {
    let assignment: GroupTaskAssignment
    let onStatusUpdate: (AssignmentStatus) -> Void
    
    private var isOverdue: Bool {
        assignment.dueDate < Date() && assignment.status != .completed
    }
    
    private var statusColor: Color {
        switch assignment.status {
        case .pending: return .orange
        case .accepted: return .blue
        case .inProgress: return .blue
        case .completed: return .green
        case .declined: return .red
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Task ID: \(assignment.taskId)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    HStack {
                        Text("From: \(assignment.assignedById)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("To: \(assignment.assignedToId)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(assignment.status.rawValue.capitalized)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(statusColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor.opacity(0.1))
                        .cornerRadius(8)
                    
                    if isOverdue {
                        Text("OVERDUE")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    }
                }
            }
            
            // Priority and Due Date
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: priorityIcon(assignment.priority))
                        .foregroundColor(priorityColor(assignment.priority))
                    Text(assignment.priority.rawValue.capitalized)
                        .font(.caption)
                        .foregroundColor(priorityColor(assignment.priority))
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .foregroundColor(.secondary)
                    Text(assignment.dueDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Notes
            if let notes = assignment.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            
            // Action Buttons
            HStack {
                if assignment.status == .pending {
                    Button("Accept") {
                        onStatusUpdate(.accepted)
                    }
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .cornerRadius(8)
                    
                    Button("Decline") {
                        onStatusUpdate(.declined)
                    }
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.red)
                    .cornerRadius(8)
                }
                
                if assignment.status == .accepted {
                    Button("Start") {
                        onStatusUpdate(.inProgress)
                    }
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .cornerRadius(8)
                }
                
                if assignment.status == .inProgress {
                    Button("Complete") {
                        onStatusUpdate(.completed)
                    }
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green)
                    .cornerRadius(8)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isOverdue ? Color.red : Color.clear, lineWidth: 2)
        )
    }
    
    private func priorityIcon(_ priority: TaskPriority) -> String {
        switch priority {
        case .low: return "arrow.down.circle.fill"
        case .medium: return "minus.circle.fill"
        case .high: return "arrow.up.circle.fill"
        case .urgent: return "exclamationmark.triangle.fill"
        }
    }
    
    private func priorityColor(_ priority: TaskPriority) -> Color {
        switch priority {
        case .low: return .green
        case .medium: return .blue
        case .high: return .orange
        case .urgent: return .red
        }
    }
}

struct CreateTaskAssignmentView: View {
    let groupId: String
    
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var collaborationManager = CollaborationManager.shared
    @StateObject private var dataManager = DataManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedMember: GroupMember?
    @State private var selectedTask: Task?
    @State private var selectedGoal: Goal?
    @State private var dueDate = Date().addingTimeInterval(7 * 24 * 3600) // 7 days from now
    @State private var priority: TaskPriority = .medium
    @State private var notes = ""
    @State private var isLoading = false
    
    var availableMembers: [GroupMember] {
        guard let currentUserId = authViewModel.currentUser?.id else { return [] }
        return collaborationManager.currentUserGroups
            .first { $0.id == groupId }?
            .members
            .filter { $0.userId != currentUserId } ?? []
    }
    
    var availableTasks: [Task] {
        dataManager.tasks.filter { !$0.isCompleted }
    }
    
    var availableGoals: [Goal] {
        dataManager.goals
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Member Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Assign To")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(availableMembers) { member in
                                    Button(action: { selectedMember = member }) {
                                        HStack {
                                            Circle()
                                                .fill(selectedMember?.id == member.id ? Color.blue : Color.gray.opacity(0.3))
                                                .frame(width: 20, height: 20)
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.blue, lineWidth: 2)
                                                )
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(member.userId)
                                                    .font(.body)
                                                    .fontWeight(.medium)
                                                Text(member.role.rawValue.capitalized)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            
                                            Spacer()
                                        }
                                        .padding(.vertical, 8)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        .frame(maxHeight: 120)
                    }
                    
                    // Task Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Select Task")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(availableTasks) { task in
                                    Button(action: { selectedTask = task }) {
                                        HStack {
                                            Circle()
                                                .fill(selectedTask?.id == task.id ? Color.blue : Color.gray.opacity(0.3))
                                                .frame(width: 20, height: 20)
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.blue, lineWidth: 2)
                                                )
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(task.title)
                                                    .font(.body)
                                                    .fontWeight(.medium)
                                                    .lineLimit(1)
                                                if let description = task.description {
                                                    Text(description)
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                        .lineLimit(2)
                                                }
                                            }
                                            
                                            Spacer()
                                        }
                                        .padding(.vertical, 8)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        .frame(maxHeight: 120)
                    }
                    
                    // Goal Selection (Optional)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Link to Goal (Optional)")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(availableGoals) { goal in
                                    Button(action: { selectedGoal = goal }) {
                                        HStack {
                                            Circle()
                                                .fill(selectedGoal?.id == goal.id ? Color.blue : Color.gray.opacity(0.3))
                                                .frame(width: 20, height: 20)
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.blue, lineWidth: 2)
                                                )
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(goal.title)
                                                    .font(.body)
                                                    .fontWeight(.medium)
                                                    .lineLimit(1)
                                                if let description = goal.description {
                                                    Text(description)
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                        .lineLimit(2)
                                                }
                                            }
                                            
                                            Spacer()
                                        }
                                        .padding(.vertical, 8)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        .frame(maxHeight: 120)
                    }
                    
                    // Due Date and Priority
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Assignment Details")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 16) {
                            DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                                .datePickerStyle(CompactDatePickerStyle())
                            
                            HStack {
                                Text("Priority")
                                    .font(.body)
                                Spacer()
                                Picker("Priority", selection: $priority) {
                                    ForEach(TaskPriority.allCases, id: \.self) { priority in
                                        Text(priority.rawValue.capitalized).tag(priority)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                        }
                    }
                    
                    // Notes
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Notes (Optional)")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        TextField("Add notes about this assignment...", text: $notes, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(3...6)
                    }
                    
                    // Create Button
                    Button(action: createAssignment) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Create Assignment")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canCreateAssignment ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .disabled(!canCreateAssignment || isLoading)
                }
                .padding()
            }
            .navigationTitle("Create Assignment")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() }
            )
        }
    }
    
    private var canCreateAssignment: Bool {
        selectedMember != nil && selectedTask != nil
    }
    
    private func createAssignment() {
        guard let selectedMember = selectedMember,
              let selectedTask = selectedTask,
              let currentUserId = authViewModel.currentUser?.id else { return }
        
        isLoading = true
        
        Task {
            do {
                try await collaborationManager.assignTask(
                    groupId: groupId,
                    assignedById: currentUserId,
                    assignedToId: selectedMember.userId,
                    taskId: selectedTask.id,
                    goalId: selectedGoal?.id,
                    dueDate: dueDate,
                    priority: priority,
                    notes: notes.isEmpty ? nil : notes
                )
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    GroupTaskAssignmentView(groupId: "test-group-id")
        .environmentObject(AuthViewModel())
}