import SwiftUI

struct EventDetailView: View {
    let event: CalendarEvent
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingEditEvent = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    EventHeaderView(event: event, onToggleCompletion: toggleEventCompletion)
                    
                    if !event.description.isEmpty {
                        EventDescriptionView(description: event.description)
                    }
                    
                    EventTimeView(event: event)
                    
                    if let linkedGoalId = event.linkedGoalId,
                       let goal = dataManager.goals.first(where: { $0.id == linkedGoalId }) {
                        EventGoalView(event: event, goal: goal)
                    }
                    
                    EventStatusView(event: event)
                }
                .padding()
            }
            .navigationTitle("Event Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        showingEditEvent = true
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showingEditEvent) {
            CreateEventView(eventToEdit: event)
                .environmentObject(dataManager)
                .environmentObject(authViewModel)
        }
    }
    
    private func toggleEventCompletion() {
        var updatedEvent = event
        if updatedEvent.status == .completed {
            updatedEvent.status = .scheduled
        } else {
            updatedEvent.status = .completed
        }
        
        dataManager.updateEvent(updatedEvent, userId: authViewModel.currentUser?.id ?? "")
    }
}

// MARK: - Subviews

struct EventHeaderView: View {
    let event: CalendarEvent
    let onToggleCompletion: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(event.category)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                }
                
                Spacer()
                
                Button(action: onToggleCompletion) {
                    Image(systemName: event.status == .completed ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(event.status == .completed ? .green : .gray)
                        .font(.title2)
                }
            }
        }
        .padding(.bottom, 10)
    }
}

struct EventDescriptionView: View {
    let description: String
    
    var body: some View {
        Text(description)
            .font(.body)
            .foregroundColor(.secondary)
    }
}

struct EventTimeView: View {
    let event: CalendarEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Time")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Start")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(event.startTime, style: .date)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("End")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatDateTime(event.endTime))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
        }
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct EventGoalView: View {
    let event: CalendarEvent
    let goal: Goal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Linked Goal")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(goal.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let progressContribution = event.progressContribution {
                    HStack {
                        Text("Progress Contribution:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1f", progressContribution))
                            .font(.caption)
                            .fontWeight(.medium)
                        Text(goal.unit)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Goal Progress")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(goal.calculatedProgress))%")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    ProgressView(value: Double(goal.calculatedProgress) / 100.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

struct EventStatusView: View {
    let event: CalendarEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Status")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                Text(event.status.rawValue.capitalized)
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(event.status == .completed ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                    .foregroundColor(event.status == .completed ? .green : .orange)
                    .cornerRadius(8)
                
                if event.status == .completed {
                    Text("Completed on \(formatDate(event.updatedAt))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
} 
 
 
 