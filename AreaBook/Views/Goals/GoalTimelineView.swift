import SwiftUI

struct GoalTimelineView: View {
    let goal: Goal
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var timelineItems: [TimelineItem] = []
    @State private var showingFilterOptions = false
    @State private var filterType: TimelineFilterType = .all
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Goal Header
                    GoalHeaderCard(goal: goal)
                    
                    // Filter Options
                    TimelineFilterView(selectedFilter: $filterType)
                    
                    // Timeline
                    VStack(spacing: 16) {
                        ForEach(filteredTimelineItems) { item in
                            TimelineItemRow(item: item)
                        }
                        
                        if filteredTimelineItems.isEmpty {
                            EmptyTimelineView()
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Goal Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadTimelineItems()
            }
        }
    }
    
    private var filteredTimelineItems: [TimelineItem] {
        switch filterType {
        case .all:
            return timelineItems
        case .completed:
            return timelineItems.filter { $0.isCompleted }
        case .pending:
            return timelineItems.filter { !$0.isCompleted }
        case .events:
            return timelineItems.filter { $0.type == .event }
        case .tasks:
            return timelineItems.filter { $0.type == .task }
        case .notes:
            return timelineItems.filter { $0.type == .note }
        }
    }
    
    private func loadTimelineItems() {
        timelineItems = dataManager.getTimelineForGoal(goal.id)
    }
}

struct GoalHeaderCard: View {
    let goal: Goal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(goal.title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                if !goal.description.isEmpty {
                    Text(goal.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Progress")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("\(goal.progress)%")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        
                        Spacer()
                        
                        Text(goal.status.rawValue.capitalized)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(statusColor(for: goal.status).opacity(0.2))
                            .foregroundColor(statusColor(for: goal.status))
                            .cornerRadius(6)
                    }
                }
            }
            
            ProgressView(value: Double(goal.progress) / 100.0)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            
            if let targetDate = goal.targetDate {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.secondary)
                    Text("Target: \(targetDate, style: .date)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
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

struct TimelineFilterView: View {
    @Binding var selectedFilter: TimelineFilterType
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TimelineFilterType.allCases, id: \.self) { filter in
                    Button(action: {
                        selectedFilter = filter
                    }) {
                        Text(filter.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedFilter == filter ? Color.blue : Color(.systemGray5))
                            .foregroundColor(selectedFilter == filter ? .white : .primary)
                            .cornerRadius(16)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
        }
    }
}

struct TimelineItemRow: View {
    let item: TimelineItem
    
    var body: some View {
        HStack(spacing: 12) {
            // Timeline indicator
            VStack {
                Circle()
                    .fill(item.isCompleted ? Color.green : Color(hex: item.type.color) ?? .blue)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                
                Rectangle()
                    .fill(Color(.systemGray4))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }
            .frame(width: 12)
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: item.type.icon)
                        .foregroundColor(Color(hex: item.type.color) ?? .blue)
                        .font(.caption)
                    
                    Text(item.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .strikethrough(item.isCompleted)
                    
                    Spacer()
                    
                    if item.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
                
                if let description = item.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    Text(item.createdAt, style: .date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if let completedAt = item.completedAt {
                        Text("• Completed \(completedAt, style: .date)")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                    
                    Spacer()
                    
                    if let progressAmount = item.progressAmount {
                        HStack(spacing: 4) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.caption2)
                                .foregroundColor(.orange)
                            Text("+\(progressAmount)")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(4)
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
    }
}

struct EmptyTimelineView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "timeline.selection")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("No Timeline Items")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Events, tasks, and notes linked to this goal will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 40)
    }
}

enum TimelineFilterType: String, CaseIterable {
    case all = "all"
    case completed = "completed"
    case pending = "pending"
    case events = "events"
    case tasks = "tasks"
    case notes = "notes"
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .completed: return "Completed"
        case .pending: return "Pending"
        case .events: return "Events"
        case .tasks: return "Tasks"
        case .notes: return "Notes"
        }
    }
}

#Preview {
    GoalTimelineView(goal: Goal(title: "Sample Goal", description: "This is a sample goal for preview"))
        .environmentObject(DataManager.shared)
        .environmentObject(AuthViewModel())
}