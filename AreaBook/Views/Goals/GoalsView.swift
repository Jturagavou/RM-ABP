import SwiftUI

struct GoalsView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // Computed properties to filter goals
    var keyIndicatorGoals: [Goal] {
        dataManager.goals.filter { $0.isKeyIndicator }
    }
    
    var regularGoals: [Goal] {
        dataManager.goals.filter { !$0.isKeyIndicator }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    
                    // Key Indicators Section
                    if !keyIndicatorGoals.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "chart.bar.fill")
                                    .foregroundColor(.blue)
                                Text("Key Indicators")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Spacer()
                                Text("\(keyIndicatorGoals.count)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.secondary.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                            .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: 12) {
                                    ForEach(keyIndicatorGoals) { goal in
                                        NavigationLink(destination: GoalTimelineView(goalId: goal.id)
                                            .environmentObject(dataManager)
                                            .environmentObject(authViewModel)) {
                                            KeyIndicatorCard(goal: goal)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // Regular Goals Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "target")
                                .foregroundColor(.purple)
                            Text("Goals")
                                .font(.title2)
                                .fontWeight(.bold)
                            Spacer()
                            if !regularGoals.isEmpty {
                                Text("\(regularGoals.count)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.secondary.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal)
                        
                        if !regularGoals.isEmpty {
                            LazyVStack(spacing: 16) {
                                ForEach(regularGoals) { goal in
                                    NavigationLink(destination: GoalTimelineView(goalId: goal.id)
                                        .environmentObject(dataManager)
                                        .environmentObject(authViewModel)) {
                                        GoalCard(goal: goal)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                        } else if keyIndicatorGoals.isEmpty {
                            // Show empty state only if no goals at all
                            VStack(spacing: 20) {
                                Image(systemName: "flag")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray)
                                
                                Text("No Goals Yet")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                Text("Create your first goal to get started on your journey")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, 50)
                        } else {
                            // Show message for no regular goals when KIs exist
                            VStack(spacing: 12) {
                                Text("No regular goals yet")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("Create a goal to track long-term objectives")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Goals")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct GoalCard: View {
    @EnvironmentObject var dataManager: DataManager
    let goal: Goal
    
    var linkedNotesCount: Int {
        dataManager.getNotesForGoal(goal.id).count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if !goal.description.isEmpty {
                        Text(goal.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(goal.calculatedProgress)%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    if linkedNotesCount > 0 {
                        Label("\(linkedNotesCount)", systemImage: "doc.text")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            ProgressView(value: Double(goal.calculatedProgress) / 100.0)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            
            HStack {
                if let targetDate = goal.targetDate {
                    Text("Due: \(targetDate, style: .date)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
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
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .contextMenu {
            NavigationLink("View Timeline") {
                GoalTimelineView(goalId: goal.id)
            }
            
            NavigationLink("View Analytics") {
                GoalAnalyticsView(goal: goal)
            }
            
            Button("Edit Goal") {
                // TODO: Add edit functionality
            }
            
            Button("Delete Goal", role: .destructive) {
                // TODO: Add delete functionality
            }
        }
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

// MARK: - Key Indicator Card Component
struct KeyIndicatorCard: View {
    let goal: Goal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with title and progress percentage
            VStack(alignment: .leading, spacing: 4) {
                Text(goal.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text("\(Int(goal.keyIndicatorProgressPercentage))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(progressColor(for: goal.keyIndicatorProgressPercentage))
            }
            
            // Progress bar
            ProgressView(value: goal.keyIndicatorProgressPercentage / 100)
                .progressViewStyle(LinearProgressViewStyle(tint: progressColor(for: goal.keyIndicatorProgressPercentage)))
                .scaleEffect(y: 0.8)
            
            // Timeline indicator
            HStack {
                Image(systemName: "clock")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(goal.resetTimeline.displayName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                if goal.needsReset() {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .frame(width: 160, height: 120)
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(progressColor(for: goal.keyIndicatorProgressPercentage).opacity(0.3), lineWidth: 1)
        )
    }
    
    private func progressColor(for percentage: Double) -> Color {
        switch percentage {
        case 80...:
            return .green
        case 50...:
            return .orange
        default:
            return .red
        }
    }
}

#Preview {
    GoalsView()
        .environmentObject(DataManager.shared)
        .environmentObject(AuthViewModel.shared)
}