import SwiftUI

struct GoalDetailView: View {
    let goal: Goal
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var showingEditGoal = false
    @State private var selectedTimelineEntry: TimelineEntry?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Goal Header
                    GoalHeaderCard(goal: goal)
                    
                    // Progress Section
                    GoalProgressSection(goal: goal)
                    
                    // Timeline Section
                    if !goal.timeline.isEmpty {
                        GoalTimelineSection(timeline: goal.timeline) { entry in
                            selectedTimelineEntry = entry
                        }
                    } else {
                        EmptyTimelineSection()
                    }
                    
                    // Linked Items Section
                    LinkedItemsSection(goal: goal)
                    
                    // Bottom padding
                    Spacer()
                        .frame(height: 100)
                }
                .padding(.horizontal)
                .padding(.top, 5)
            }
            .navigationTitle("Goal Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        showingEditGoal = true
                    }
                }
            }
            .sheet(isPresented: $showingEditGoal) {
                CreateGoalView(goalToEdit: goal)
            }
            .sheet(item: $selectedTimelineEntry) { entry in
                TimelineEntryDetailView(entry: entry)
            }
        }
    }
}

struct GoalHeaderCard: View {
    let goal: Goal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(goal.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    if !goal.description.isEmpty {
                        Text(goal.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(goal.progress)%")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text(goal.status.rawValue.capitalized)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor(for: goal.status).opacity(0.2))
                        .foregroundColor(statusColor(for: goal.status))
                        .cornerRadius(6)
                }
            }
            
            if let targetDate = goal.targetDate {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.blue)
                    Text("Target: \(targetDate, style: .date)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: targetDate).day ?? 0
                    Text("\(daysRemaining) days remaining")
                        .font(.caption)
                        .foregroundColor(daysRemaining < 7 ? .red : .secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private func statusColor(for status: GoalStatus) -> Color {
        switch status {
        case .active: return .blue
        case .completed: return .green
        case .paused: return .orange
        case .cancelled: return .red
        }
    }
}

struct GoalProgressSection: View {
    let goal: Goal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Progress")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ProgressView(value: Double(goal.progress) / 100.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
                
                HStack {
                    Text("0%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("100%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Milestones
            HStack {
                ForEach([25, 50, 75, 100], id: \.self) { milestone in
                    VStack(spacing: 4) {
                        Circle()
                            .fill(goal.progress >= milestone ? .green : .gray.opacity(0.3))
                            .frame(width: 12, height: 12)
                        
                        Text("\(milestone)%")
                            .font(.caption2)
                            .foregroundColor(goal.progress >= milestone ? .green : .secondary)
                    }
                    
                    if milestone != 100 {
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct GoalTimelineSection: View {
    let timeline: [TimelineEntry]
    let onEntryTap: (TimelineEntry) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Timeline")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(timeline.count) entries")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            LazyVStack(spacing: 12) {
                ForEach(timeline) { entry in
                    TimelineEntryRow(entry: entry) {
                        onEntryTap(entry)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct TimelineEntryRow: View {
    let entry: TimelineEntry
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: entry.type.icon)
                    .font(.title3)
                    .foregroundColor(Color(hex: entry.type.color))
                    .frame(width: 30, height: 30)
                    .background(Color(hex: entry.type.color).opacity(0.2))
                    .clipShape(Circle())
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(entry.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    HStack {
                        Text(entry.timestamp, style: .relative)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        if let progressChange = entry.progressChange {
                            Spacer()
                            Text("\(progressChange > 0 ? "+" : "")\(progressChange)%")
                                .font(.caption2)
                                .foregroundColor(progressChange > 0 ? .green : .red)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(.systemGray6))
                                .cornerRadius(4)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EmptyTimelineSection: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Timeline")
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                Image(systemName: "clock")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
                
                Text("No Timeline Entries Yet")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Complete tasks and events linked to this goal to see progress entries here")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 20)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct LinkedItemsSection: View {
    let goal: Goal
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Linked Items")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Linked Tasks
            let linkedTasks = dataManager.getTasksForGoal(goal.id)
            if !linkedTasks.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tasks (\(linkedTasks.count))")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                    
                    ForEach(linkedTasks) { task in
                        HStack {
                            Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(task.status == .completed ? .green : .gray)
                            
                            Text(task.title)
                                .font(.caption)
                                .strikethrough(task.status == .completed)
                                .foregroundColor(task.status == .completed ? .secondary : .primary)
                            
                            Spacer()
                            
                            Circle()
                                .fill(task.priority.color)
                                .frame(width: 6, height: 6)
                        }
                    }
                }
            }
            
            // Linked Events
            let linkedEvents = dataManager.events.filter { $0.linkedGoalId == goal.id }
            if !linkedEvents.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Events (\(linkedEvents.count))")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                    
                    ForEach(linkedEvents) { event in
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.orange)
                            
                            Text(event.title)
                                .font(.caption)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text(event.startTime, style: .date)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // Linked Notes
            let linkedNotes = dataManager.getNotesForGoal(goal.id)
            if !linkedNotes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes (\(linkedNotes.count))")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.purple)
                    
                    ForEach(linkedNotes) { note in
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.purple)
                            
                            Text(note.title)
                                .font(.caption)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text(note.updatedAt, style: .date)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            if linkedTasks.isEmpty && linkedEvents.isEmpty && linkedNotes.isEmpty {
                Text("No linked items yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct TimelineEntryDetailView: View {
    let entry: TimelineEntry
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack {
                        Image(systemName: entry.type.icon)
                            .font(.title)
                            .foregroundColor(Color(hex: entry.type.color))
                            .frame(width: 50, height: 50)
                            .background(Color(hex: entry.type.color).opacity(0.2))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.title)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(entry.timestamp, style: .complete)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    // Description
                    Text(entry.description)
                        .font(.body)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    
                    // Progress Change
                    if let progressChange = entry.progressChange {
                        HStack {
                            Text("Progress Change:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text("\(progressChange > 0 ? "+" : "")\(progressChange)%")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(progressChange > 0 ? .green : .red)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Timeline Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    GoalDetailView(goal: Goal(title: "Sample Goal", description: "This is a sample goal for preview"))
        .environmentObject(DataManager.shared)
        .environmentObject(AuthViewModel())
}