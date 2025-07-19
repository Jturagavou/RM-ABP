import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var dataManager: DataManager
    
    @State private var dashboardData: DashboardData?
    @State private var showingProfile = false
    @State private var isLoading = true
    @State private var isRefreshing = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                if isLoading && dashboardData == nil {
                    // Skeleton loading view
                    SkeletonDashboardView()
                        .padding()
                } else {
                    LazyVStack(spacing: 20) {
                        // Header with user greeting
                        HeaderView()
                        
                        // Daily Quote
                        if let quote = dashboardData?.quote {
                            QuoteCard(quote: quote)
                                .transition(.move(edge: .leading).combined(with: .opacity))
                        }
                        
                        // Weekly Key Indicators
                        if let keyIndicators = dashboardData?.weeklyKIs, !keyIndicators.isEmpty {
                            KeyIndicatorsSection(keyIndicators: keyIndicators)
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                        } else if !isLoading {
                            EmptyKeyIndicatorsCard()
                        }
                        
                        // Today's Tasks
                        if let tasks = dashboardData?.todaysTasks {
                            TodaysTasksSection(tasks: tasks)
                                .transition(.move(edge: .leading).combined(with: .opacity))
                        }
                        
                        // Today's Events
                        if let events = dashboardData?.todaysEvents {
                            TodaysEventsSection(events: events)
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                        }
                        
                        // Recent Goals
                        if let goals = dashboardData?.recentGoals, !goals.isEmpty {
                            RecentGoalsSection(goals: goals)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .padding()
                    .animation(.easeInOut, value: dashboardData)
                }
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
                await refreshDashboardAsync()
            }
            .onAppear {
                if dashboardData == nil {
                    refreshDashboard()
                }
            }
            .sheet(isPresented: $showingProfile) {
                ProfileView()
            }
            .alert("Error", isPresented: $showError) {
                Button("Retry") { refreshDashboard() }
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func refreshDashboard() {
        guard let userId = authViewModel.currentUser?.id else { return }
        
        isLoading = true
        
        Task { @MainActor in
            do {
                try await Task.sleep(nanoseconds: 300_000_000) // Small delay for smoother animation
                dashboardData = dataManager.getDashboardData(for: userId)
                isLoading = false
            } catch {
                errorMessage = "Failed to load dashboard data"
                showError = true
                isLoading = false
            }
        }
    }
    
    @MainActor
    private func refreshDashboardAsync() async {
        guard let userId = authViewModel.currentUser?.id else { return }
        
        isRefreshing = true
        
        do {
            try await Task.sleep(nanoseconds: 500_000_000) // Simulate network delay
            dashboardData = dataManager.getDashboardData(for: userId)
            
            // Show success feedback
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {
            errorMessage = "Failed to refresh dashboard"
            showError = true
        }
        
        isRefreshing = false
    }
}

// MARK: - Skeleton Loading View
struct SkeletonDashboardView: View {
    @State private var isAnimating = false
    
    var body: some View {
        LazyVStack(spacing: 20) {
            // Header skeleton
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 120, height: 20)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 180, height: 32)
                }
                Spacer()
            }
            
            // Quote skeleton
            VStack(alignment: .leading, spacing: 12) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 60)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 16)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            
            // KI skeleton
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(0..<4) { _ in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 100)
                }
            }
            
            // Tasks skeleton
            VStack(spacing: 12) {
                ForEach(0..<3) { _ in
                    HStack {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 24, height: 24)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 200, height: 16)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 100, height: 12)
                        }
                        
                        Spacer()
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .opacity(isAnimating ? 0.6 : 1.0)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Empty States
struct EmptyKeyIndicatorsCard: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text("No Key Indicators")
                .font(.headline)
            
            Text("Create key indicators to track your weekly progress")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            NavigationLink(destination: KeyIndicatorsView()) {
                Text("Create Key Indicator")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(6)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
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
    @State private var completedTasks = Set<String>()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "checkmark.square.fill")
                    .foregroundColor(.green)
                Text("Today's Tasks")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(tasks.filter { $0.status == .completed || completedTasks.contains($0.id) }.count)/\(tasks.count)")
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
                        TaskRowView(
                            task: task,
                            isCompleted: task.status == .completed || completedTasks.contains(task.id)
                        ) {
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
        
        if completedTasks.contains(task.id) {
            completedTasks.remove(task.id)
            updatedTask.status = .pending
            updatedTask.completedAt = nil
        } else {
            completedTasks.insert(task.id)
            updatedTask.status = .completed
            updatedTask.completedAt = Date()
        }
        
        dataManager.updateTask(updatedTask, userId: userId)
    }
}

struct TaskRowView: View {
    let task: Task
    let isCompleted: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isCompleted ? .green : .gray)
                    .font(.title3)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.subheadline)
                    .strikethrough(isCompleted)
                    .foregroundColor(isCompleted ? .secondary : .primary)
                
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
    @State private var showingConfirmation = false
    
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
                    showingConfirmation = true
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
            .alert("Sign Out", isPresented: $showingConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    authViewModel.signOut()
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to sign out?")
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