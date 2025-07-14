import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var analyticsService = AnalyticsService.shared
    @StateObject private var validationService = DataValidationService.shared
    @StateObject private var templateManager = TemplateManager.shared
    @StateObject private var conflictService = ConflictResolutionService.shared
    
    @State private var showingCreateKI = false
    @State private var showingCreateGoal = false
    @State private var showingCreateTask = false
    @State private var showingCreateEvent = false
    @State private var showingAnalytics = false
    @State private var showingTemplates = false
    @State private var showingConflicts = false
    @State private var showingValidationDetails = false
    @State private var analyticsData: AnalyticsData?
    
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
                        
                        // System Status Bar
                        SystemStatusBar(
                            hasConflicts: !conflictService.activeConflicts.isEmpty,
                            validationIssues: validationService.validationErrors.count + validationService.validationWarnings.count,
                            analyticsReady: analyticsData != nil
                        )
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // Analytics Overview Card
                    if let analytics = analyticsData {
                        AnalyticsOverviewCard(analytics: analytics) {
                            showingAnalytics = true
                        }
                    }
                    
                    // Data Management Quick Actions
                    DataManagementQuickActions(
                        onTemplatesPressed: { showingTemplates = true },
                        onConflictsPressed: { showingConflicts = true },
                        onValidationPressed: { showingValidationDetails = true },
                        conflictCount: conflictService.activeConflicts.count,
                        templateCount: templateManager.goalTemplates.count + templateManager.taskTemplates.count
                    )
                    
                    // Insights and Recommendations
                    if let analytics = analyticsData, !analytics.insights.isEmpty {
                        InsightsCard(insights: analytics.insights)
                    }
                    
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
                    
                    // Enhanced Weekly Insights
                    EnhancedWeeklyInsightsCard(
                        completedTasks: completedTasksThisWeek,
                        totalKIProgress: totalKIProgressPercentage,
                        activeGoals: activeGoals.count,
                        analytics: analyticsData
                    )
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // Analytics Button
                    Button(action: { showingAnalytics = true }) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                    
                    // Add Menu
                    Menu {
                        Button("Add Life Tracker", action: { showingCreateKI = true })
                        Button("Add Goal", action: { showingCreateGoal = true })
                        Button("Add Task", action: { showingCreateTask = true })
                        Button("Add Event", action: { showingCreateEvent = true })
                        Divider()
                        Button("Browse Templates", action: { showingTemplates = true })
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
            }
            .refreshable {
                await loadAnalytics()
            }
            .task {
                await loadAnalytics()
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
            .sheet(isPresented: $showingAnalytics) {
                AnalyticsDetailView(analytics: analyticsData)
            }
            .sheet(isPresented: $showingTemplates) {
                TemplateSelectionView()
            }
            .sheet(isPresented: $showingConflicts) {
                ConflictResolutionView()
            }
            .sheet(isPresented: $showingValidationDetails) {
                ValidationDetailsView()
            }
        }
    }
    
    // MARK: - Data Loading
    
    private func loadAnalytics() async {
        guard let userId = authViewModel.currentUser?.id else { return }
        
        do {
            let analytics = try await analyticsService.generatePersonalAnalytics(userId: userId)
            await MainActor.run {
                self.analyticsData = analytics
            }
        } catch {
            print("Failed to load analytics: \(error)")
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

// MARK: - New Analytics UI Components

struct SystemStatusBar: View {
    let hasConflicts: Bool
    let validationIssues: Int
    let analyticsReady: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Sync Status
            HStack(spacing: 4) {
                Image(systemName: hasConflicts ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                    .foregroundColor(hasConflicts ? .orange : .green)
                    .font(.caption)
                Text(hasConflicts ? "Sync Issues" : "All Synced")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Data Quality
            HStack(spacing: 4) {
                Image(systemName: validationIssues > 0 ? "exclamationmark.diamond.fill" : "shield.checkered")
                    .foregroundColor(validationIssues > 0 ? .yellow : .green)
                    .font(.caption)
                Text(validationIssues > 0 ? "\(validationIssues) Issues" : "Data Valid")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Analytics Status
            HStack(spacing: 4) {
                Image(systemName: analyticsReady ? "chart.bar.fill" : "chart.bar")
                    .foregroundColor(analyticsReady ? .blue : .gray)
                    .font(.caption)
                Text(analyticsReady ? "Analytics Ready" : "Loading...")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.top, 8)
    }
}

struct AnalyticsOverviewCard: View {
    let analytics: AnalyticsData
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Analytics Overview")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                    ForEach(analytics.metrics.prefix(6)) { metric in
                        AnalyticsMetricCompact(metric: metric)
                    }
                }
                
                if !analytics.trends.isEmpty {
                    HStack {
                        Text("Trending")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        Spacer()
                        
                        ForEach(analytics.trends.prefix(2)) { trend in
                            TrendIndicator(trend: trend)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AnalyticsMetricCompact: View {
    let metric: AnalyticsMetric
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(metric.value, specifier: "%.0f")")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(colorForCategory(metric.category))
            
            Text(metric.name)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func colorForCategory(_ category: AnalyticsCategory) -> Color {
        switch category {
        case .goals: return .blue
        case .tasks: return .green
        case .keyIndicators: return .purple
        case .events: return .orange
        case .productivity: return .indigo
        case .engagement: return .pink
        case .groups: return .teal
        }
    }
}

struct TrendIndicator: View {
    let trend: AnalyticsTrend
    
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: trendIcon)
                .font(.caption2)
                .foregroundColor(trendColor)
            Text("\(trend.percentage, specifier: "%.0f")%")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(trendColor)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(trendColor.opacity(0.1))
        .cornerRadius(4)
    }
    
    private var trendIcon: String {
        switch trend.direction {
        case .increasing: return "arrow.up"
        case .decreasing: return "arrow.down"
        case .stable: return "minus"
        }
    }
    
    private var trendColor: Color {
        switch trend.direction {
        case .increasing: return .green
        case .decreasing: return .red
        case .stable: return .blue
        }
    }
}

struct DataManagementQuickActions: View {
    let onTemplatesPressed: () -> Void
    let onConflictsPressed: () -> Void
    let onValidationPressed: () -> Void
    let conflictCount: Int
    let templateCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Data Management")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 12) {
                // Templates Button
                Button(action: onTemplatesPressed) {
                    QuickActionButton(
                        icon: "doc.text.fill",
                        title: "Templates",
                        subtitle: "\(templateCount) available",
                        color: .blue
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Conflicts Button (if any)
                if conflictCount > 0 {
                    Button(action: onConflictsPressed) {
                        QuickActionButton(
                            icon: "exclamationmark.triangle.fill",
                            title: "Conflicts",
                            subtitle: "\(conflictCount) pending",
                            color: .orange
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Validation Button
                Button(action: onValidationPressed) {
                    QuickActionButton(
                        icon: "checkmark.shield.fill",
                        title: "Validation",
                        subtitle: "View status",
                        color: .green
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct InsightsCard: View {
    let insights: [AnalyticsInsight]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Insights & Recommendations")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(insights.prefix(3)) { insight in
                InsightRow(insight: insight)
            }
            
            if insights.count > 3 {
                Text("+ \(insights.count - 3) more insights")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct InsightRow: View {
    let insight: AnalyticsInsight
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconForCategory(insight.category))
                .font(.title3)
                .foregroundColor(colorForCategory(insight.category))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(insight.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                if insight.actionable && !insight.suggestions.isEmpty {
                    Text("💡 \(insight.suggestions.first!)")
                        .font(.caption2)
                        .foregroundColor(.blue)
                        .padding(.top, 2)
                }
            }
            
            Spacer()
            
            // Confidence indicator
            ConfidenceIndicator(confidence: insight.confidence)
        }
        .padding(.vertical, 4)
    }
    
    private func iconForCategory(_ category: AnalyticsCategory) -> String {
        switch category {
        case .goals: return "target"
        case .tasks: return "checkmark.circle"
        case .keyIndicators: return "chart.bar"
        case .events: return "calendar"
        case .productivity: return "bolt"
        case .engagement: return "heart"
        case .groups: return "person.3"
        }
    }
    
    private func colorForCategory(_ category: AnalyticsCategory) -> Color {
        switch category {
        case .goals: return .blue
        case .tasks: return .green
        case .keyIndicators: return .purple
        case .events: return .orange
        case .productivity: return .indigo
        case .engagement: return .pink
        case .groups: return .teal
        }
    }
}

struct ConfidenceIndicator: View {
    let confidence: Double
    
    var body: some View {
        Circle()
            .fill(confidenceColor)
            .frame(width: 8, height: 8)
    }
    
    private var confidenceColor: Color {
        if confidence >= 0.8 {
            return .green
        } else if confidence >= 0.6 {
            return .yellow
        } else {
            return .orange
        }
    }
}

struct EnhancedWeeklyInsightsCard: View {
    let completedTasks: Int
    let totalKIProgress: Double
    let activeGoals: Int
    let analytics: AnalyticsData?
    
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
            
            // Enhanced feedback with analytics
            VStack(alignment: .leading, spacing: 8) {
                if let productivity = analytics?.metrics.first(where: { $0.name == "Productivity Score" }) {
                    ProductivityFeedback(score: productivity.value)
                } else {
                    // Fallback to original feedback
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
                
                // Weekly trends
                if let analytics = analytics, !analytics.trends.isEmpty {
                    HStack {
                        Text("Trends:")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        ForEach(analytics.trends.prefix(3)) { trend in
                            if trend.period == .weekly {
                                TrendIndicator(trend: trend)
                            }
                        }
                        
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct ProductivityFeedback: View {
    let score: Double
    
    var body: some View {
        HStack {
            Text(feedbackEmoji)
                .font(.title3)
            
            Text(feedbackMessage)
                .font(.caption)
                .foregroundColor(feedbackColor)
                .fontWeight(.medium)
        }
    }
    
    private var feedbackEmoji: String {
        if score >= 80 { return "🎉" }
        else if score >= 60 { return "💪" }
        else if score >= 40 { return "🚀" }
        else { return "💡" }
    }
    
    private var feedbackMessage: String {
        if score >= 80 { return "Excellent productivity! You're on fire!" }
        else if score >= 60 { return "Good productivity! Keep up the momentum!" }
        else if score >= 40 { return "Steady progress! Every step counts!" }
        else { return "Focus on small wins to build momentum!" }
    }
    
    private var feedbackColor: Color {
        if score >= 80 { return .green }
        else if score >= 60 { return .blue }
        else if score >= 40 { return .orange }
        else { return .purple }
    }
}

// MARK: - Supporting Views (keeping existing ones)

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
                
                ProgressView(value: Double(goal.progress) / 100.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .scaleEffect(y: 0.7)
            }
            
            Spacer()
            
            Text("\(goal.progress)%")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.blue)
        }
        .padding(.vertical, 4)
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