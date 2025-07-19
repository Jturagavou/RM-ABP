import SwiftUI

struct GoalsView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingCreateGoal = false
    @State private var selectedGoal: Goal?
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(dataManager.goals) { goal in
                        NavigationLink(destination: GoalDetailView(goal: goal)) {
                            GoalCard(goal: goal)
                        }
                        .buttonStyle(PlainButtonStyle())
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
                            
                            Button("Create Goal") {
                                showingCreateGoal = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(.top, 100)
                    }
                }
                .padding()
            }
            .navigationTitle("Goals")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreateGoal = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingCreateGoal) {
                CreateGoalView()
            }
        }
    }
}

struct GoalCard: View {
    let goal: Goal
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
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
                .progressViewStyle(LinearProgressViewStyle(tint: progressColor(for: goal)))
            
            HStack {
                if let targetDate = goal.targetDate {
                    Label("\(targetDate, style: .date)", systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    if !goal.keyIndicatorIds.isEmpty {
                        Image(systemName: "target")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text("\(goal.keyIndicatorIds.count)")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
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
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
        }
    }
    
    private func progressColor(for goal: Goal) -> Color {
        if goal.status == .completed {
            return .green
        } else if goal.progress >= 75 {
            return .blue
        } else if goal.progress >= 50 {
            return .orange
        } else {
            return .red
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

#Preview {
    GoalsView()
        .environmentObject(DataManager.shared)
        .environmentObject(AuthViewModel())
}