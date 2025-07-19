import SwiftUI

struct TasksView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedFilter: TaskFilter = .all
    @State private var showingCreateTask = false
    @State private var taskToEdit: Task?
    
    enum TaskFilter: String, CaseIterable {
        case all = "All"
        case pending = "Pending"
        case completed = "Completed"
        case overdue = "Overdue"
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Filter Picker
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(TaskFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Tasks List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        let filteredTasks = getFilteredTasks()
                        
                        if filteredTasks.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "checkmark.square")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray)
                                
                                Text("No Tasks")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                Text("No tasks found for the selected filter")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                
                                Button("Create Task") {
                                    showingCreateTask = true
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .padding(.top, 100)
                        } else {
                            ForEach(filteredTasks) { task in
                                TaskCard(task: task) {
                                    toggleTaskCompletion(task)
                                } onEdit: {
                                    taskToEdit = task
                                } onDelete: {
                                    deleteTask(task)
                                }
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                            }
                        }
                    }
                    .padding()
                    .animation(.easeInOut, value: filteredTasks.map { $0.id })
                }
            }
            .navigationTitle("Tasks")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreateTask = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingCreateTask) {
                CreateTaskView()
            }
            .sheet(item: $taskToEdit) { task in
                CreateTaskView(taskToEdit: task)
            }
        }
    }
    
    private func getFilteredTasks() -> [Task] {
        let tasks = dataManager.tasks
        
        switch selectedFilter {
        case .all:
            return tasks.sorted { $0.createdAt > $1.createdAt }
        case .pending:
            return tasks.filter { $0.status == .pending }.sorted { $0.createdAt > $1.createdAt }
        case .completed:
            return tasks.filter { $0.status == .completed }.sorted { $0.completedAt ?? Date() > $1.completedAt ?? Date() }
        case .overdue:
            return tasks.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return dueDate < Date() && task.status != .completed
            }.sorted { $0.dueDate ?? Date() < $1.dueDate ?? Date() }
        }
    }
    
    private func toggleTaskCompletion(_ task: Task) {
        guard let userId = authViewModel.currentUser?.id else { return }
        
        var updatedTask = task
        updatedTask.status = task.status == .completed ? .pending : .completed
        updatedTask.completedAt = updatedTask.status == .completed ? Date() : nil
        
        dataManager.updateTask(updatedTask, userId: userId)
    }
    
    private func deleteTask(_ task: Task) {
        guard let userId = authViewModel.currentUser?.id else { return }
        dataManager.deleteTask(task, userId: userId)
    }
}

struct TaskCard: View {
    let task: Task
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.status == .completed ? .green : .gray)
                    .font(.title2)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .strikethrough(task.status == .completed)
                    .foregroundColor(task.status == .completed ? .secondary : .primary)
                
                if let description = task.description, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    if let dueDate = task.dueDate {
                        Label(dueDate.formatted(date: .abbreviated, time: .shortened), systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(dueDate < Date() && task.status != .completed ? .red : .secondary)
                    }
                    
                    Spacer()
                    
                    Circle()
                        .fill(task.priority.color)
                        .frame(width: 8, height: 8)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .contextMenu {
            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
                onEdit()
            }
        }
    }
}

#Preview {
    TasksView()
        .environmentObject(DataManager.shared)
        .environmentObject(AuthViewModel())
}