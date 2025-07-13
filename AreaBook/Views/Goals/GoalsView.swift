import SwiftUI

struct GoalsView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(dataManager.goals) { goal in
                        GoalCard(goal: goal)
                    }
                    
                    if dataManager.goals.isEmpty {
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
                        .padding(.top, 100)
                    }
                }
                .padding()
            }
            .navigationTitle("Goals")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct GoalCard: View {
    let goal: Goal
    
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
                
                Text("\(goal.progress)%")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            ProgressView(value: Double(goal.progress) / 100.0)
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

#Preview {
    GoalsView()
        .environmentObject(DataManager.shared)
        .environmentObject(AuthViewModel())
}