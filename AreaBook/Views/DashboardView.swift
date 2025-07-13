import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingCreateKI = false
    @State private var showingCreateGoal = false
    @State private var showingCreateTask = false
    @State private var showingCreateEvent = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(greetingMessage)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                Text(userName)
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            }
                            
                            Spacer()
                            
                            // Profile/Settings Button
                            NavigationLink(destination: SettingsView()) {
                                Image(systemName: "person.circle")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        Text(motivationalQuote)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .italic()
                            .padding(.top, 4)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // Quick Stats Overview
                    if !dataManager.keyIndicators.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("This Week's Progress")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Spacer()
                                NavigationLink("View All", destination: KeyIndicatorsManagementView())
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                                ForEach(dataManager.keyIndicators.prefix(4)) { ki in
                                    KIProgressCard(keyIndicator: ki)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                    
                    // Today's Focus
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Today's Focus")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        HStack(spacing: 16) {
                            // Today's Tasks
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "checkmark.circle")
                                        .foregroundColor(.green)
                                    Text("Tasks")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text("\(todaysTasks.count)")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.green)
                                }
                                
                                if !todaysTasks.isEmpty {
                                    ForEach(todaysTasks.prefix(3)) { task in
                                        TaskRowCompact(task: task)
                                    }
                                    
                                    if todaysTasks.count > 3 {
                                        Text("+ \(todaysTasks.count - 3) more")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                } else {
                                    Text("No tasks for today")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Divider()
                            
                            // Today's Events
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundColor(.blue)
                                    Text("Events")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text("\(todaysEvents.count)")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                }
                                
                                if !todaysEvents.isEmpty {
                                    ForEach(todaysEvents.prefix(3)) { event in
                                        EventRowCompact(event: event)
                                    }
                                    
                                    if todaysEvents.count > 3 {
                                        Text("+ \(todaysEvents.count - 3) more")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                } else {
                                    Text("No events today")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // Goals Overview
                    if !dataManager.goals.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Active Goals")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Spacer()
                                NavigationLink("View All", destination: GoalsView())
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            
                            ForEach(activeGoals.prefix(3)) { goal in
                                GoalRowCompact(goal: goal)
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                    
                    // Weekly Insights
                    WeeklyInsightsCard(
                        completedTasks: completedTasksThisWeek,
                        totalKIProgress: totalKIProgressPercentage,
                        activeGoals: activeGoals.count
                    )
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Add Life Tracker", action: { showingCreateKI = true })
                        Button("Add Goal", action: { showingCreateGoal = true })
                        Button("Add Task", action: { showingCreateTask = true })
                        Button("Add Event", action: { showingCreateEvent = true })
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
            }
            .refreshable {
                // Refresh data
            }
            .sheet(isPresented: $showingCreateKI) {
                CreateKeyIndicatorView()
            }
            .sheet(isPresented: $showingCreateGoal) {
                CreateGoalView()
            }
            .sheet(isPresented: $showingCreateTask) {
                CreateTaskView()
            }
            .sheet(isPresented: $showingCreateEvent) {
                CreateEventView()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var userName: String {
        authViewModel.currentUser?.name ?? "Friend"
    }
    
    private var greetingMessage: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "Good morning,"
        case 12..<17:
            return "Good afternoon,"
        case 17..<22:
            return "Good evening,"
        default:
            return "Good night,"
        }
    }
    
    private var motivationalQuote: String {
        let quotes = [
            "Progress, not perfection.",
            "Small steps lead to big changes.",
            "Consistency builds success.",
            "Focus on what you can control.",
            "Every day is a new opportunity.",
            "Growth happens outside your comfort zone.",
            "Celebrate small wins along the way.",
            "Your future self will thank you.",
            "Success is a series of small efforts.",
            "Believe in your ability to improve."
        ]
        
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return quotes[dayOfYear % quotes.count]
    }
    
    private var todaysTasks: [Task] {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        return dataManager.tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate >= today && dueDate < tomorrow && task.status != .completed
        }
    }
    
    private var todaysEvents: [CalendarEvent] {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        return dataManager.events.filter { event in
            event.startTime >= today && event.startTime < tomorrow
        }
    }
    
    private var activeGoals: [Goal] {
        dataManager.goals.filter { $0.status == .active }
    }
    
    private var completedTasksThisWeek: Int {
        let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        return dataManager.tasks.filter { task in
            guard let completedAt = task.completedAt else { return false }
            return completedAt >= weekStart
        }.count
    }
    
    private var totalKIProgressPercentage: Double {
        guard !dataManager.keyIndicators.isEmpty else { return 0 }
        let totalProgress = dataManager.keyIndicators.reduce(0) { $0 + $1.progressPercentage }
        return totalProgress / Double(dataManager.keyIndicators.count)
    }
}

// MARK: - Supporting Views

struct KIProgressCard: View {
    let keyIndicator: KeyIndicator
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(Color(hex: keyIndicator.color) ?? .blue)
                    .frame(width: 8, height: 8)
                Text(keyIndicator.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(keyIndicator.currentWeekProgress)")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("/ \(keyIndicator.weeklyTarget)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(keyIndicator.progressPercentage * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Color(hex: keyIndicator.color) ?? .blue)
                }
                
                ProgressView(value: keyIndicator.progressPercentage)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: keyIndicator.color) ?? .blue))
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct TaskRowCompact: View {
    let task: Task
    
    var body: some View {
        HStack {
            Circle()
                .fill(task.priority.color)
                .frame(width: 6, height: 6)
            Text(task.title)
                .font(.caption)
                .lineLimit(1)
            Spacer()
        }
    }
}

struct EventRowCompact: View {
    let event: CalendarEvent
    
    var body: some View {
        HStack {
            Text(event.startTime, style: .time)
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .leading)
            Text(event.title)
                .font(.caption)
                .lineLimit(1)
            Spacer()
        }
    }
}

struct GoalRowCompact: View {
    let goal: Goal
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(goal.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                ProgressView(value: goal.progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .scaleEffect(y: 0.7)
            }
            
            Spacer()
            
            Text("\(Int(goal.progress * 100))%")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.blue)
        }
        .padding(.vertical, 4)
    }
}

struct WeeklyInsightsCard: View {
    let completedTasks: Int
    let totalKIProgress: Double
    let activeGoals: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("This Week's Summary")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 20) {
                InsightItem(
                    icon: "checkmark.circle.fill",
                    title: "Tasks Done",
                    value: "\(completedTasks)",
                    color: .green
                )
                
                InsightItem(
                    icon: "target",
                    title: "Avg Progress",
                    value: "\(Int(totalKIProgress * 100))%",
                    color: .blue
                )
                
                InsightItem(
                    icon: "star.circle.fill",
                    title: "Active Goals",
                    value: "\(activeGoals)",
                    color: .orange
                )
            }
            
            if totalKIProgress > 0.8 {
                Text("🎉 Great week! You're crushing your goals!")
                    .font(.caption)
                    .foregroundColor(.green)
                    .fontWeight(.medium)
            } else if totalKIProgress > 0.5 {
                Text("💪 Good progress! Keep pushing forward!")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .fontWeight(.medium)
            } else {
                Text("🚀 Every step counts! You've got this!")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .fontWeight(.medium)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct InsightItem: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    DashboardView()
        .environmentObject(DataManager.shared)
        .environmentObject(AuthViewModel())
}