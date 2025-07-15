import SwiftUI

struct GoalsView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingCreateGoal = false
    @State private var showingCreateDivider = false
    @State private var selectedGoalForDetail: Goal?
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Dividers and Goals
                    if dataManager.goalDividers.isEmpty && dataManager.goals.isEmpty {
                        EmptyGoalsView()
                    } else {
                        // Goals with dividers
                        ForEach(dataManager.goalDividers.sorted(by: { $0.sortOrder < $1.sortOrder })) { divider in
                            GoalDividerSection(
                                divider: divider,
                                goals: goalsForDivider(divider.id)
                            ) { goal in
                                selectedGoalForDetail = goal
                            }
                        }
                        
                        // Uncategorized goals
                        let uncategorizedGoals = dataManager.goals.filter { $0.dividerCategory == nil }
                        if !uncategorizedGoals.isEmpty {
                            GoalDividerSection(
                                divider: nil,
                                goals: uncategorizedGoals
                            ) { goal in
                                selectedGoalForDetail = goal
                            }
                        }
                    }
                    
                    // Bottom padding for floating button
                    Spacer()
                        .frame(height: 100)
                }
                .padding(.horizontal)
                .padding(.top, 5)
            }
            .navigationTitle("Goals")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("New Goal") {
                            showingCreateGoal = true
                        }
                        Button("New Category") {
                            showingCreateDivider = true
                        }
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
            .sheet(isPresented: $showingCreateDivider) {
                CreateGoalDividerView()
            }
            .sheet(item: $selectedGoalForDetail) { goal in
                GoalDetailView(goal: goal)
            }
        }
    }
    
    private func goalsForDivider(_ dividerId: String) -> [Goal] {
        return dataManager.goals.filter { $0.dividerCategory == dividerId }
    }
}

struct EmptyGoalsView: View {
    var body: some View {
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

struct GoalDividerSection: View {
    let divider: GoalDivider?
    let goals: [Goal]
    let onGoalTap: (Goal) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Divider Header
            HStack {
                if let divider = divider {
                    Image(systemName: divider.icon)
                        .foregroundColor(Color(hex: divider.color))
                        .font(.title2)
                    
                    Text(divider.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: divider.color))
                } else {
                    Image(systemName: "tray")
                        .foregroundColor(.gray)
                        .font(.title2)
                    
                    Text("Uncategorized")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Text("\(goals.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
            }
            
            // Goals in this divider
            if goals.isEmpty {
                Text("No goals in this category yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.leading, 40)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(goals) { goal in
                        GoalCard(goal: goal) {
                            onGoalTap(goal)
                        }
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

struct GoalCard: View {
    let goal: Goal
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
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
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(goal.progress)%")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        
                        if !goal.timeline.isEmpty {
                            Text("\(goal.timeline.count) entries")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
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
            .background(Color(.secondarySystemBackground))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
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

// Color extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    GoalsView()
        .environmentObject(DataManager.shared)
        .environmentObject(AuthViewModel())
}