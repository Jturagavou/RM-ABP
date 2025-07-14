import Foundation
import SwiftUI
import Firebase
import FirebaseFirestore

struct DashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var dataManager: DataManager
    
    @State private var dashboardData: DashboardData?
    @State private var showingProfile = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Header with user greeting
                    HeaderView()
                    
                    // Daily Quote
                    if let quote = dashboardData?.quote {
                        QuoteCard(quote: quote)
                    }
                    
                    // Weekly Key Indicators
                    if let keyIndicators = dashboardData?.weeklyKIs, !keyIndicators.isEmpty {
                        KeyIndicatorsSection(keyIndicators: keyIndicators)
                    }
                    
                    // Today's Tasks
                    if let tasks = dashboardData?.todaysTasks {
                        TodaysTasksSection(tasks: tasks)
                    }
                    
                    // Today's Events
                    if let events = dashboardData?.todaysEvents {
                        TodaysEventsSection(events: events)
                    }
                    
                    // Recent Goals
                    if let goals = dashboardData?.recentGoals, !goals.isEmpty {
                        RecentGoalsSection(goals: goals)
                    }
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingProfile = true
                    } label: {
                        AsyncImage(url: URL(string: authViewModel.currentUser?.avatar ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.blue)
                        }
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                    }
                }
            }
            .refreshable {
                refreshDashboard()
            }
            .onAppear {
                refreshDashboard()
            }
            .sheet(isPresented: $showingProfile) {
                ProfileView()
            }
        }
    }
    
    private func refreshDashboard() {
        guard let userId = authViewModel.currentUser?.id else { return }
        dashboardData = dataManager.getDashboardData(for: userId)
    }
}

struct HeaderView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingText)
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Text(authViewModel.currentUser?.name ?? "User")
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }
            
            Spacer()
        }
        .padding(.horizontal)
    }
    
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12:
            return "Good morning,"
        case 12..<17:
            return "Good afternoon,"
        case 17..<22:
            return "Good evening,"
        default:
            return "Good night,"
        }
    }
}

struct QuoteCard: View {
    let quote: DailyQuote
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "quote.opening")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text("Daily Inspiration")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            Text(quote.text)
                .font(.body)
                .italic()
                .lineLimit(nil)
            
            HStack {
                Spacer()
                Text("— \(quote.author)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct KeyIndicatorsSection: View {
    let keyIndicators: [KeyIndicator]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                Text("Weekly Key Indicators")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(keyIndicators) { ki in
                    KeyIndicatorCard(keyIndicator: ki)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct KeyIndicatorCard: View {
    let keyIndicator: KeyIndicator
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(Color(hex: keyIndicator.color) ?? .blue)
                    .frame(width: 12, height: 12)
                Text(keyIndicator.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(keyIndicator.currentWeekProgress)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("/ \(keyIndicator.weeklyTarget)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                
                ProgressView(value: keyIndicator.progressPercentage)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: keyIndicator.color) ?? .blue))
                
                Text("\(Int(keyIndicator.progressPercentage * 100))% complete")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
}

struct TodaysTasksSection: View {
    let tasks: [Task]
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "checkmark.square.fill")
                    .foregroundColor(.green)
                Text("Today's Tasks")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(tasks.filter { $0.status == .completed }.count)/\(tasks.count)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(6)
            }
            
            if tasks.isEmpty {
                Text("No tasks for today")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(tasks.prefix(5)) { task in
                        TaskRowView(task: task) {
                            toggleTaskCompletion(task)
                        }
                    }
                    
                    if tasks.count > 5 {
                        NavigationLink("View All Tasks") {
                            TasksView()
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private func toggleTaskCompletion(_ task: Task) {
        guard let userId = authViewModel.currentUser?.id else { return }
        
        var updatedTask = task
        updatedTask.status = task.status == .completed ? .pending : .completed
        updatedTask.completedAt = updatedTask.status == .completed ? Date() : nil
        
        dataManager.updateTask(updatedTask, userId: userId)
    }
}

struct TaskRowView: View {
    let task: Task
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.status == .completed ? .green : .gray)
                    .font(.title3)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.subheadline)
                    .strikethrough(task.status == .completed)
                    .foregroundColor(task.status == .completed ? .secondary : .primary)
                
                if let dueDate = task.dueDate {
                    Text(dueDate, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Circle()
                .fill(task.priority.color)
                .frame(width: 8, height: 8)
        }
        .padding(.vertical, 4)
    }
}

struct TodaysEventsSection: View {
    let events: [CalendarEvent]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
                Text("Today's Events")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            if events.isEmpty {
                Text("No events for today")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(events.prefix(3)) { event in
                        EventRowView(event: event)
                    }
                    
                    if events.count > 3 {
                        NavigationLink("View All Events") {
                            CalendarView()
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
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

struct EventRowView: View {
    let event: CalendarEvent
    
    var body: some View {
        HStack(spacing: 12) {
            VStack {
                Text(event.startTime, style: .time)
                    .font(.caption)
                    .fontWeight(.medium)
                Text("-")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(event.endTime, style: .time)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(width: 60)
            
            Rectangle()
                .fill(Color.blue)
                .frame(width: 3)
                .cornerRadius(1.5)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(event.category)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(4)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct RecentGoalsSection: View {
    let goals: [Goal]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "flag.fill")
                    .foregroundColor(.orange)
                Text("Recent Goals")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                NavigationLink("View All") {
                    GoalsView()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            LazyVStack(spacing: 8) {
                ForEach(goals) { goal in
                    GoalRowView(goal: goal)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct GoalRowView: View {
    let goal: Goal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(goal.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(goal.progress)%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }
            
            ProgressView(value: Double(goal.progress) / 100.0)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
        }
        .padding(.vertical, 4)
    }
}

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                AsyncImage(url: URL(string: authViewModel.currentUser?.avatar ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 80))
                }
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                
                Text(authViewModel.currentUser?.name ?? "User")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(authViewModel.currentUser?.email ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Sign Out") {
                    authViewModel.signOut()
                    dismiss()
                }
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(10)
            }
            .padding()
            .navigationTitle("Profile")
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

// Helper extension for hex colors
extension Color {
    init?(hex: String) {
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
            return nil
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
    DashboardView()
        .environmentObject(AuthViewModel())
        .environmentObject(DataManager.shared)
}