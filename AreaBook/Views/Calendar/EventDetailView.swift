import SwiftUI

struct EventDetailView: View {
    let event: CalendarEvent
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Event Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(event.title)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            if event.isRecurring {
                                Image(systemName: "repeat")
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Text(event.category)
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(categoryColor(for: event.category).opacity(0.2))
                            .foregroundColor(categoryColor(for: event.category))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    
                    // Time Information
                    VStack(alignment: .leading, spacing: 12) {
                        Label {
                            VStack(alignment: .leading) {
                                Text("Date")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(event.startTime, style: .date)
                                    .fontWeight(.medium)
                            }
                        } icon: {
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                        }
                        
                        Label {
                            VStack(alignment: .leading) {
                                Text("Time")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(event.startTime, style: .time) - \(event.endTime, style: .time)")
                                    .fontWeight(.medium)
                            }
                        } icon: {
                            Image(systemName: "clock")
                                .foregroundColor(.orange)
                        }
                        
                        if event.isRecurring, let pattern = event.recurrencePattern {
                            Label {
                                VStack(alignment: .leading) {
                                    Text("Recurrence")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(recurrenceDescription(pattern))
                                        .fontWeight(.medium)
                                }
                            } icon: {
                                Image(systemName: "repeat")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Description
                    if !event.description.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.headline)
                            Text(event.description)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Linked Items
                    if event.linkedGoalId != nil || !event.taskIds.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Linked Items")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            if let goalId = event.linkedGoalId,
                               let goal = dataManager.goals.first(where: { $0.id == goalId }) {
                                LinkedGoalCard(goal: goal)
                                    .padding(.horizontal)
                            }
                            
                            if !event.taskIds.isEmpty {
                                let linkedTasks = dataManager.tasks.filter { event.taskIds.contains($0.id) }
                                ForEach(linkedTasks) { task in
                                    LinkedTaskCard(task: task)
                                        .padding(.horizontal)
                                }
                            }
                        }
                    }
                    
                    // Status
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Status")
                            .font(.headline)
                        
                        HStack {
                            Image(systemName: statusIcon(for: event.status))
                                .foregroundColor(statusColor(for: event.status))
                            Text(event.status.rawValue.capitalized)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(statusColor(for: event.status).opacity(0.2))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    
                    // Metadata
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Created: \(event.createdAt, style: .date) at \(event.createdAt, style: .time)")
                        Text("Updated: \(event.updatedAt, style: .date) at \(event.updatedAt, style: .time)")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showingEditSheet = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            CreateEventView(eventToEdit: event)
        }
        .alert("Delete Event", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let userId = authViewModel.currentUser?.id {
                    dataManager.deleteEvent(event, userId: userId)
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to delete this event? This action cannot be undone.")
        }
    }
    
    private func categoryColor(for category: String) -> Color {
        switch category.lowercased() {
        case "work": return .blue
        case "personal": return .purple
        case "health": return .green
        case "social": return .orange
        case "learning": return .indigo
        default: return .gray
        }
    }
    
    private func statusIcon(for status: EventStatus) -> String {
        switch status {
        case .scheduled: return "calendar"
        case .completed: return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle.fill"
        }
    }
    
    private func statusColor(for status: EventStatus) -> Color {
        switch status {
        case .scheduled: return .blue
        case .completed: return .green
        case .cancelled: return .red
        }
    }
    
    private func recurrenceDescription(_ pattern: RecurrencePattern) -> String {
        var description = ""
        
        switch pattern.type {
        case .daily:
            description = pattern.interval == 1 ? "Every day" : "Every \(pattern.interval) days"
        case .weekly:
            description = pattern.interval == 1 ? "Every week" : "Every \(pattern.interval) weeks"
            if let days = pattern.daysOfWeek {
                let dayNames = days.map { dayName(for: $0) }.joined(separator: ", ")
                description += " on \(dayNames)"
            }
        case .monthly:
            description = pattern.interval == 1 ? "Every month" : "Every \(pattern.interval) months"
        case .yearly:
            description = pattern.interval == 1 ? "Every year" : "Every \(pattern.interval) years"
        }
        
        if let endDate = pattern.endDate {
            description += " until \(endDate, style: .date)"
        }
        
        return description
    }
    
    private func dayName(for dayIndex: Int) -> String {
        let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return days[safe: dayIndex] ?? ""
    }
}

// MARK: - Linked Item Cards
struct LinkedGoalCard: View {
    let goal: Goal
    
    var body: some View {
        HStack {
            Image(systemName: "flag.fill")
                .foregroundColor(.orange)
            
            VStack(alignment: .leading) {
                Text("Linked Goal")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(goal.title)
                    .fontWeight(.medium)
            }
            
            Spacer()
            
            Text("\(goal.progress)%")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.orange)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct LinkedTaskCard: View {
    let task: Task
    
    var body: some View {
        HStack {
            Image(systemName: task.status == .completed ? "checkmark.square.fill" : "square")
                .foregroundColor(task.status == .completed ? .green : .gray)
            
            VStack(alignment: .leading) {
                Text(task.title)
                    .fontWeight(.medium)
                    .strikethrough(task.status == .completed)
                
                if let dueDate = task.dueDate {
                    Text("Due: \(dueDate, style: .date)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Circle()
                .fill(task.priority.color)
                .frame(width: 8, height: 8)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Safe Array Extension
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    EventDetailView(event: CalendarEvent(
        title: "Team Meeting",
        description: "Weekly sync with the development team",
        category: "Work",
        startTime: Date(),
        endTime: Date().addingTimeInterval(3600)
    ))
    .environmentObject(DataManager.shared)
    .environmentObject(AuthViewModel())
}