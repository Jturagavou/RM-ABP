import Foundation
import Firebase
import Combine

class AnalyticsService: ObservableObject {
    static let shared = AnalyticsService()
    
    @Published var personalAnalytics: AnalyticsData?
    @Published var groupAnalytics: [String: AnalyticsData] = [:]
    @Published var insights: [AnalyticsInsight] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showError = false
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - Personal Analytics
    
    func generatePersonalAnalytics(userId: String) async throws -> AnalyticsData {
        isLoading = true
        
        // Fetch user data
        let goals = try await fetchUserGoals(userId: userId)
        let tasks = try await fetchUserTasks(userId: userId)
        let events = try await fetchUserEvents(userId: userId)
        let keyIndicators = try await fetchUserKeyIndicators(userId: userId)
        
        // Generate metrics
        let metrics = generateMetrics(goals: goals, tasks: tasks, events: events, keyIndicators: keyIndicators)
        
        // Generate trends
        let trends = try await generateTrends(userId: userId, goals: goals, tasks: tasks, events: events, keyIndicators: keyIndicators)
        
        // Generate insights
        let insights = try await generateInsights(userId: userId, metrics: metrics, trends: trends)
        
        let analytics = AnalyticsData(userId: userId)
        analytics.metrics = metrics
        analytics.trends = trends
        analytics.insights = insights
        
        // Store analytics
        try await storeAnalytics(analytics, userId: userId)
        
        personalAnalytics = analytics
        isLoading = false
        
        return analytics
    }
    
    // MARK: - Group Analytics
    
    func generateGroupAnalytics(groupId: String, userId: String) async throws -> AnalyticsData {
        isLoading = true
        
        // Fetch group data
        let groupMembers = try await fetchGroupMembers(groupId: groupId)
        let groupGoals = try await fetchGroupGoals(groupId: groupId)
        let groupTasks = try await fetchGroupTasks(groupId: groupId)
        let groupEvents = try await fetchGroupEvents(groupId: groupId)
        
        // Generate group metrics
        let metrics = generateGroupMetrics(members: groupMembers, goals: groupGoals, tasks: groupTasks, events: groupEvents)
        
        // Generate group trends
        let trends = try await generateGroupTrends(groupId: groupId, members: groupMembers)
        
        // Generate group insights
        let insights = try await generateGroupInsights(groupId: groupId, metrics: metrics, trends: trends)
        
        let analytics = AnalyticsData(userId: groupId)
        analytics.metrics = metrics
        analytics.trends = trends
        analytics.insights = insights
        
        groupAnalytics[groupId] = analytics
        isLoading = false
        
        return analytics
    }
    
    // MARK: - Metrics Generation
    
    private func generateMetrics(goals: [Goal], tasks: [Task], events: [CalendarEvent], keyIndicators: [KeyIndicator]) -> [AnalyticsMetric] {
        var metrics: [AnalyticsMetric] = []
        
        // Goal metrics
        let activeGoals = goals.filter { $0.status == .active }
        let completedGoals = goals.filter { $0.status == .completed }
        let goalCompletionRate = goals.isEmpty ? 0 : Double(completedGoals.count) / Double(goals.count)
        
        metrics.append(AnalyticsMetric(name: "Active Goals", value: Double(activeGoals.count), unit: "goals", category: .goals))
        metrics.append(AnalyticsMetric(name: "Completed Goals", value: Double(completedGoals.count), unit: "goals", category: .goals))
        metrics.append(AnalyticsMetric(name: "Goal Completion Rate", value: goalCompletionRate * 100, unit: "%", category: .goals))
        
        // Task metrics
        let completedTasks = tasks.filter { $0.status == .completed }
        let overdueTasks = tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate < Date() && task.status == .pending
        }
        
        metrics.append(AnalyticsMetric(name: "Total Tasks", value: Double(tasks.count), unit: "tasks", category: .tasks))
        metrics.append(AnalyticsMetric(name: "Completed Tasks", value: Double(completedTasks.count), unit: "tasks", category: .tasks))
        metrics.append(AnalyticsMetric(name: "Overdue Tasks", value: Double(overdueTasks.count), unit: "tasks", category: .tasks))
        
        // KI metrics
        let totalKIProgress = keyIndicators.reduce(0) { $0 + $1.currentWeekProgress }
        let totalKITarget = keyIndicators.reduce(0) { $0 + $1.weeklyTarget }
        let avgKIProgress = keyIndicators.isEmpty ? 0 : Double(totalKIProgress) / Double(keyIndicators.count)
        let kiAchievementRate = totalKITarget == 0 ? 0 : Double(totalKIProgress) / Double(totalKITarget)
        
        metrics.append(AnalyticsMetric(name: "Key Indicators", value: Double(keyIndicators.count), unit: "indicators", category: .keyIndicators))
        metrics.append(AnalyticsMetric(name: "Average KI Progress", value: avgKIProgress, unit: "units", category: .keyIndicators))
        metrics.append(AnalyticsMetric(name: "KI Achievement Rate", value: kiAchievementRate * 100, unit: "%", category: .keyIndicators))
        
        // Event metrics
        let thisWeekEvents = events.filter { event in
            Calendar.current.isDate(event.startTime, equalTo: Date(), toGranularity: .weekOfYear)
        }
        
        metrics.append(AnalyticsMetric(name: "This Week Events", value: Double(thisWeekEvents.count), unit: "events", category: .events))
        metrics.append(AnalyticsMetric(name: "Total Events", value: Double(events.count), unit: "events", category: .events))
        
        // Productivity metrics
        let productivity = calculateProductivityScore(goals: goals, tasks: tasks, keyIndicators: keyIndicators)
        let engagement = calculateEngagementScore(goals: goals, tasks: tasks, events: events)
        
        metrics.append(AnalyticsMetric(name: "Productivity Score", value: productivity, unit: "score", category: .productivity))
        metrics.append(AnalyticsMetric(name: "Engagement Score", value: engagement, unit: "score", category: .engagement))
        
        return metrics
    }
    
    private func generateGroupMetrics(members: [GroupMember], goals: [Goal], tasks: [Task], events: [CalendarEvent]) -> [AnalyticsMetric] {
        var metrics: [AnalyticsMetric] = []
        
        // Group size metrics
        metrics.append(AnalyticsMetric(name: "Group Members", value: Double(members.count), unit: "members", category: .groups))
        
        // Collaboration metrics
        let sharedGoals = goals.filter { !$0.collaborators.isEmpty }
        let collaborationRate = goals.isEmpty ? 0 : Double(sharedGoals.count) / Double(goals.count)
        
        metrics.append(AnalyticsMetric(name: "Shared Goals", value: Double(sharedGoals.count), unit: "goals", category: .groups))
        metrics.append(AnalyticsMetric(name: "Collaboration Rate", value: collaborationRate * 100, unit: "%", category: .groups))
        
        // Group activity metrics
        let activeMembers = members.filter { member in
            // Check if member has been active recently
            // This would require additional data about member activity
            return true
        }
        
        metrics.append(AnalyticsMetric(name: "Active Members", value: Double(activeMembers.count), unit: "members", category: .groups))
        
        return metrics
    }
    
    // MARK: - Trend Analysis
    
    private func generateTrends(userId: String, goals: [Goal], tasks: [Task], events: [CalendarEvent], keyIndicators: [KeyIndicator]) async throws -> [AnalyticsTrend] {
        var trends: [AnalyticsTrend] = []
        
        // Goal completion trend
        let goalCompletionTrend = try await calculateGoalCompletionTrend(userId: userId)
        trends.append(contentsOf: goalCompletionTrend)
        
        // Task completion trend
        let taskCompletionTrend = try await calculateTaskCompletionTrend(userId: userId)
        trends.append(contentsOf: taskCompletionTrend)
        
        // KI progress trend
        let kiProgressTrend = try await calculateKIProgressTrend(userId: userId)
        trends.append(contentsOf: kiProgressTrend)
        
        // Productivity trend
        let productivityTrend = try await calculateProductivityTrend(userId: userId)
        trends.append(contentsOf: productivityTrend)
        
        return trends
    }
    
    private func generateGroupTrends(groupId: String, members: [GroupMember]) async throws -> [AnalyticsTrend] {
        var trends: [AnalyticsTrend] = []
        
        // Group growth trend
        let growthTrend = try await calculateGroupGrowthTrend(groupId: groupId)
        trends.append(contentsOf: growthTrend)
        
        // Group engagement trend
        let engagementTrend = try await calculateGroupEngagementTrend(groupId: groupId)
        trends.append(contentsOf: engagementTrend)
        
        return trends
    }
    
    // MARK: - Insight Generation
    
    private func generateInsights(userId: String, metrics: [AnalyticsMetric], trends: [AnalyticsTrend]) async throws -> [AnalyticsInsight] {
        var insights: [AnalyticsInsight] = []
        
        // Goal insights
        if let goalCompletionRate = metrics.first(where: { $0.name == "Goal Completion Rate" }) {
            if goalCompletionRate.value < 50 {
                insights.append(AnalyticsInsight(
                    title: "Low Goal Completion Rate",
                    description: "Your goal completion rate is below 50%. Consider breaking down goals into smaller, more manageable tasks.",
                    category: .goals,
                    confidence: 0.8,
                    suggestions: [
                        "Break large goals into smaller milestones",
                        "Set more realistic timelines",
                        "Review and adjust goals regularly"
                    ]
                ))
            }
        }
        
        // Task insights
        if let overdueTasks = metrics.first(where: { $0.name == "Overdue Tasks" }) {
            if overdueTasks.value > 5 {
                insights.append(AnalyticsInsight(
                    title: "High Number of Overdue Tasks",
                    description: "You have many overdue tasks. Consider prioritizing and reorganizing your task list.",
                    category: .tasks,
                    confidence: 0.9,
                    suggestions: [
                        "Prioritize high-importance tasks",
                        "Extend deadlines for non-urgent tasks",
                        "Consider delegating some tasks"
                    ]
                ))
            }
        }
        
        // KI insights
        if let kiAchievementRate = metrics.first(where: { $0.name == "KI Achievement Rate" }) {
            if kiAchievementRate.value > 80 {
                insights.append(AnalyticsInsight(
                    title: "Excellent KI Performance",
                    description: "You're consistently achieving your key indicator targets. Consider setting more challenging goals.",
                    category: .keyIndicators,
                    confidence: 0.85,
                    suggestions: [
                        "Increase weekly targets for key indicators",
                        "Add new key indicators to track",
                        "Share your success strategies with others"
                    ]
                ))
            }
        }
        
        // Productivity insights
        if let productivityScore = metrics.first(where: { $0.name == "Productivity Score" }) {
            if productivityScore.value < 60 {
                insights.append(AnalyticsInsight(
                    title: "Productivity Opportunity",
                    description: "Your productivity score suggests room for improvement. Focus on completing high-priority tasks first.",
                    category: .productivity,
                    confidence: 0.7,
                    suggestions: [
                        "Use time-blocking for important tasks",
                        "Eliminate distractions during work time",
                        "Review and optimize your daily routine"
                    ]
                ))
            }
        }
        
        // Trend-based insights
        for trend in trends {
            if trend.significance == .high {
                switch trend.direction {
                case .increasing:
                    if trend.name.contains("Completion") {
                        insights.append(AnalyticsInsight(
                            title: "Improving Performance",
                            description: "Great job! Your \(trend.name.lowercased()) is trending upward.",
                            category: .productivity,
                            confidence: 0.8,
                            suggestions: ["Keep up the good work!", "Consider what's working well and apply it to other areas"]
                        ))
                    }
                case .decreasing:
                    if trend.name.contains("Completion") {
                        insights.append(AnalyticsInsight(
                            title: "Performance Decline",
                            description: "Your \(trend.name.lowercased()) has been declining. Consider reviewing your approach.",
                            category: .productivity,
                            confidence: 0.75,
                            suggestions: ["Review recent changes in your routine", "Consider if you're taking on too much"]
                        ))
                    }
                case .stable:
                    // Stable trends might indicate consistency, which could be good or bad depending on the metric
                    break
                }
            }
        }
        
        return insights
    }
    
    private func generateGroupInsights(groupId: String, metrics: [AnalyticsMetric], trends: [AnalyticsTrend]) async throws -> [AnalyticsInsight] {
        var insights: [AnalyticsInsight] = []
        
        // Group collaboration insights
        if let collaborationRate = metrics.first(where: { $0.name == "Collaboration Rate" }) {
            if collaborationRate.value < 30 {
                insights.append(AnalyticsInsight(
                    title: "Low Collaboration",
                    description: "Group members aren't collaborating much on shared goals. Consider encouraging more teamwork.",
                    category: .groups,
                    confidence: 0.8,
                    suggestions: [
                        "Create shared group goals",
                        "Organize regular check-ins",
                        "Encourage peer support and feedback"
                    ]
                ))
            }
        }
        
        // Group size insights
        if let memberCount = metrics.first(where: { $0.name == "Group Members" }) {
            if memberCount.value > 20 {
                insights.append(AnalyticsInsight(
                    title: "Large Group Size",
                    description: "Large groups can be less effective. Consider splitting into smaller subgroups.",
                    category: .groups,
                    confidence: 0.7,
                    suggestions: [
                        "Create smaller working groups",
                        "Assign specific roles to members",
                        "Use structured communication methods"
                    ]
                ))
            }
        }
        
        return insights
    }
    
    // MARK: - Helper Methods
    
    private func calculateProductivityScore(goals: [Goal], tasks: [Task], keyIndicators: [KeyIndicator]) -> Double {
        var score = 0.0
        
        // Goal completion contribution (40%)
        let completedGoals = goals.filter { $0.status == .completed }
        let goalScore = goals.isEmpty ? 0 : Double(completedGoals.count) / Double(goals.count)
        score += goalScore * 0.4
        
        // Task completion contribution (30%)
        let completedTasks = tasks.filter { $0.status == .completed }
        let taskScore = tasks.isEmpty ? 0 : Double(completedTasks.count) / Double(tasks.count)
        score += taskScore * 0.3
        
        // KI achievement contribution (30%)
        let totalProgress = keyIndicators.reduce(0) { $0 + $1.currentWeekProgress }
        let totalTarget = keyIndicators.reduce(0) { $0 + $1.weeklyTarget }
        let kiScore = totalTarget == 0 ? 0 : Double(totalProgress) / Double(totalTarget)
        score += min(kiScore, 1.0) * 0.3
        
        return score * 100
    }
    
    private func calculateEngagementScore(goals: [Goal], tasks: [Task], events: [CalendarEvent]) -> Double {
        var score = 0.0
        
        // Recent activity (50%)
        let recentGoals = goals.filter { $0.updatedAt > Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date() }
        let recentTasks = tasks.filter { $0.updatedAt > Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date() }
        let recentEvents = events.filter { $0.updatedAt > Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date() }
        
        let recentActivityScore = Double(recentGoals.count + recentTasks.count + recentEvents.count) / 10.0
        score += min(recentActivityScore, 1.0) * 0.5
        
        // Variety of activities (30%)
        let hasGoals = !goals.isEmpty
        let hasTasks = !tasks.isEmpty
        let hasEvents = !events.isEmpty
        let varietyScore = [hasGoals, hasTasks, hasEvents].filter { $0 }.count
        score += (Double(varietyScore) / 3.0) * 0.3
        
        // Consistency (20%)
        let consistentActivity = recentGoals.count > 0 && recentTasks.count > 0
        score += (consistentActivity ? 1.0 : 0.0) * 0.2
        
        return score * 100
    }
    
    // MARK: - Trend Calculations
    
    private func calculateGoalCompletionTrend(userId: String) async throws -> [AnalyticsTrend] {
        // This would fetch historical data and calculate trends
        // For now, returning a sample trend
        return [
            AnalyticsTrend(
                name: "Goal Completion Rate",
                direction: .increasing,
                percentage: 15.0,
                period: .monthly,
                significance: .medium,
                description: "Your goal completion rate has improved by 15% this month"
            )
        ]
    }
    
    private func calculateTaskCompletionTrend(userId: String) async throws -> [AnalyticsTrend] {
        return [
            AnalyticsTrend(
                name: "Task Completion Rate",
                direction: .stable,
                percentage: 2.0,
                period: .weekly,
                significance: .low,
                description: "Your task completion rate has remained stable this week"
            )
        ]
    }
    
    private func calculateKIProgressTrend(userId: String) async throws -> [AnalyticsTrend] {
        return [
            AnalyticsTrend(
                name: "KI Progress",
                direction: .increasing,
                percentage: 25.0,
                period: .weekly,
                significance: .high,
                description: "Your key indicator progress has increased significantly this week"
            )
        ]
    }
    
    private func calculateProductivityTrend(userId: String) async throws -> [AnalyticsTrend] {
        return [
            AnalyticsTrend(
                name: "Productivity Score",
                direction: .increasing,
                percentage: 10.0,
                period: .monthly,
                significance: .medium,
                description: "Your overall productivity has improved by 10% this month"
            )
        ]
    }
    
    private func calculateGroupGrowthTrend(groupId: String) async throws -> [AnalyticsTrend] {
        return [
            AnalyticsTrend(
                name: "Group Growth",
                direction: .increasing,
                percentage: 20.0,
                period: .monthly,
                significance: .high,
                description: "Group membership has grown by 20% this month"
            )
        ]
    }
    
    private func calculateGroupEngagementTrend(groupId: String) async throws -> [AnalyticsTrend] {
        return [
            AnalyticsTrend(
                name: "Group Engagement",
                direction: .stable,
                percentage: 5.0,
                period: .weekly,
                significance: .low,
                description: "Group engagement remains steady with slight growth"
            )
        ]
    }
    
    // MARK: - Data Fetching
    
    private func fetchUserGoals(userId: String) async throws -> [Goal] {
        let snapshot = try await db.collection("users").document(userId).collection("goals").getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Goal.self) }
    }
    
    private func fetchUserTasks(userId: String) async throws -> [Task] {
        let snapshot = try await db.collection("users").document(userId).collection("tasks").getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Task.self) }
    }
    
    private func fetchUserEvents(userId: String) async throws -> [CalendarEvent] {
        let snapshot = try await db.collection("users").document(userId).collection("events").getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: CalendarEvent.self) }
    }
    
    private func fetchUserKeyIndicators(userId: String) async throws -> [KeyIndicator] {
        let snapshot = try await db.collection("users").document(userId).collection("keyIndicators").getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: KeyIndicator.self) }
    }
    
    private func fetchGroupMembers(groupId: String) async throws -> [GroupMember] {
        let snapshot = try await db.collection("groups").document(groupId).getDocument()
        let data = snapshot.data() ?? [:]
        let membersData = data["members"] as? [[String: Any]] ?? []
        return membersData.compactMap { try? GroupMember(from: $0) }
    }
    
    private func fetchGroupGoals(groupId: String) async throws -> [Goal] {
        // This would fetch goals shared with the group
        // Implementation would depend on your data structure
        return []
    }
    
    private func fetchGroupTasks(groupId: String) async throws -> [Task] {
        // This would fetch tasks shared with the group
        return []
    }
    
    private func fetchGroupEvents(groupId: String) async throws -> [CalendarEvent] {
        // This would fetch events shared with the group
        return []
    }
    
    private func storeAnalytics(_ analytics: AnalyticsData, userId: String) async throws {
        let analyticsRef = db.collection("users").document(userId).collection("analytics").document()
        try await analyticsRef.setData(from: analytics)
    }
    
    private func showError(_ message: String) {
        DispatchQueue.main.async {
            self.errorMessage = message
            self.showError = true
        }
    }
}

// MARK: - Extensions

extension GroupMember {
    init(from data: [String: Any]) throws {
        guard let id = data["id"] as? String,
              let userId = data["userId"] as? String,
              let roleString = data["role"] as? String,
              let role = GroupRole(rawValue: roleString),
              let joinedAtTimestamp = data["joinedAt"] as? Timestamp else {
            throw AnalyticsError.invalidData
        }
        
        self.id = id
        self.userId = userId
        self.role = role
        self.joinedAt = joinedAtTimestamp.dateValue()
        self.permissions = GroupPermissions(role: role)
    }
}

// MARK: - Supporting Types

enum AnalyticsError: Error {
    case invalidData
    case calculationError
    case networkError(String)
}