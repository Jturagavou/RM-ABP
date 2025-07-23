import SwiftUI
import Charts

struct GoalAnalyticsView: View {
    @EnvironmentObject var dataManager: DataManager
    let goal: Goal
    
    @State private var selectedTimeframe: Timeframe = .week
    @State private var showingProgressHistory = false
    
    enum Timeframe: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case quarter = "Quarter"
        case year = "Year"
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Header with goal info
                GoalAnalyticsHeader(goal: goal)
                
                // Progress Overview Card
                ProgressOverviewCard(goal: goal)
                
                // Progress Chart
                ProgressChartCard(goal: goal, timeframe: selectedTimeframe)
                
                // Progress History
                ProgressHistoryCard(goal: goal)
                
                // Related Activities
                RelatedActivitiesCard(goal: goal)
                
                // Insights
                InsightsCard(goal: goal)
            }
            .padding()
        }
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    ForEach(Timeframe.allCases, id: \.self) { timeframe in
                        Button(timeframe.rawValue) {
                            selectedTimeframe = timeframe
                        }
                    }
                } label: {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                }
            }
        }
    }
}

struct GoalAnalyticsHeader: View {
    let goal: Goal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if !goal.description.isEmpty {
                        Text(goal.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(goal.calculatedProgress)%")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text("Complete")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Progress bar
            ProgressView(value: Double(goal.calculatedProgress) / 100.0)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            
            // Goal details
            HStack {
                if let targetDate = goal.targetDate {
                    Label("Due: \(targetDate, style: .date)", systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Label(goal.progressType.rawValue.capitalized, systemImage: "chart.bar")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct ProgressOverviewCard: View {
    let goal: Goal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Progress Overview")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ProgressStatCard(
                    title: "Current Value",
                    value: String(format: "%.1f", goal.currentValue),
                    unit: goal.unit,
                    color: .blue
                )
                
                ProgressStatCard(
                    title: "Target Value",
                    value: String(format: "%.1f", goal.targetValue),
                    unit: goal.unit,
                    color: .green
                )
                
                ProgressStatCard(
                    title: "Remaining",
                    value: String(format: "%.1f", max(0, goal.targetValue - goal.currentValue)),
                    unit: goal.unit,
                    color: .orange
                )
                
                ProgressStatCard(
                    title: "Completion Rate",
                    value: "\(goal.calculatedProgress)%",
                    unit: "",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct ProgressStatCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(alignment: .bottom, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
}

struct ProgressChartCard: View {
    let goal: Goal
    let timeframe: GoalAnalyticsView.Timeframe
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Progress Trend")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(timeframe.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Mock chart data - in a real app, you'd fetch historical data
            Chart {
                ForEach(sampleProgressData, id: \.date) { dataPoint in
                    LineMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Progress", dataPoint.progress)
                    )
                    .foregroundStyle(.blue)
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Progress", dataPoint.progress)
                    )
                    .foregroundStyle(.blue.opacity(0.1))
                }
            }
            .frame(height: 200)
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks(position: .leading) {
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: FloatingPointFormatStyle<Double>.number.precision(.fractionLength(0)))
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // Sample data for demonstration
    private var sampleProgressData: [ProgressDataPoint] {
        let calendar = Calendar.current
        let today = Date()
        var dataPoints: [ProgressDataPoint] = []
        
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                let progress = Double.random(in: 0...Double(goal.calculatedProgress))
                dataPoints.append(ProgressDataPoint(date: date, progress: progress))
            }
        }
        
        return dataPoints.sorted { $0.date < $1.date }
    }
}

struct ProgressDataPoint {
    let date: Date
    let progress: Double
}

struct ProgressHistoryCard: View {
    let goal: Goal
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.headline)
                .fontWeight(.semibold)
            
            let timeline = dataManager.getTimelineForGoal(goalId: goal.id)
            
            if timeline.isEmpty {
                Text("No recent activity")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(timeline.prefix(5)) { item in
                        TimelineItemRow(item: item)
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

struct TimelineItemRow: View {
    let item: TimelineItem
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(iconColor)
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: iconName)
                        .font(.caption)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let description = item.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(item.date, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
    
    private var iconName: String {
        switch item.type {
        case .goal: return "flag"
        case .task: return "checkmark.circle"
        case .event: return "calendar"
        case .note: return "doc.text"
        case .keyIndicator: return "chart.bar"
        case .progressUpdate: return "arrow.up.circle"
        case .other: return "circle"
        }
    }
    
    private var iconColor: Color {
        switch item.type {
        case .goal: return .blue
        case .task: return .green
        case .event: return .orange
        case .note: return .purple
        case .keyIndicator: return .red
        case .progressUpdate: return .yellow
        case .other: return .gray
        }
    }
}

struct RelatedActivitiesCard: View {
    let goal: Goal
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Related Activities")
                .font(.headline)
                .fontWeight(.semibold)
            
            let linkedTasks = dataManager.tasks.filter { $0.linkedGoalId == goal.id }
            let linkedEvents = dataManager.events.filter { $0.linkedGoalId == goal.id }
            let linkedNotes = dataManager.getNotesForGoal(goal.id)
            
            VStack(spacing: 12) {
                ActivitySummaryRow(
                    icon: "checkmark.circle",
                    title: "Linked Tasks",
                    count: linkedTasks.count,
                    completed: linkedTasks.filter { $0.status == .completed }.count,
                    color: .green
                )
                
                ActivitySummaryRow(
                    icon: "calendar",
                    title: "Linked Events",
                    count: linkedEvents.count,
                    completed: linkedEvents.filter { $0.status == .completed }.count,
                    color: .orange
                )
                
                ActivitySummaryRow(
                    icon: "doc.text",
                    title: "Linked Notes",
                    count: linkedNotes.count,
                    completed: 0,
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct ActivitySummaryRow: View {
    let icon: String
    let title: String
    let count: Int
    let completed: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            if count > 0 {
                Text("\(completed)/\(count)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(color)
            } else {
                Text("0")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct InsightsCard: View {
    let goal: Goal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Insights")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                InsightRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Progress Rate",
                    description: progressRateInsight,
                    color: .blue
                )
                
                InsightRow(
                    icon: "clock",
                    title: "Time Remaining",
                    description: timeRemainingInsight,
                    color: .orange
                )
                
                InsightRow(
                    icon: "target",
                    title: "Goal Status",
                    description: goalStatusInsight,
                    color: .green
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var progressRateInsight: String {
        let progress = goal.calculatedProgress
        if progress >= 100 {
            return "Goal completed! 🎉"
        } else if progress >= 75 {
            return "Great progress! You're in the final stretch."
        } else if progress >= 50 {
            return "Good progress! You're halfway there."
        } else if progress >= 25 {
            return "Making steady progress. Keep it up!"
        } else {
            return "Getting started. Every step counts!"
        }
    }
    
    private var timeRemainingInsight: String {
        guard let targetDate = goal.targetDate else {
            return "No target date set"
        }
        
        let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: targetDate).day ?? 0
        
        if daysRemaining < 0 {
            return "Target date has passed"
        } else if daysRemaining == 0 {
            return "Due today!"
        } else if daysRemaining <= 7 {
            return "Due in \(daysRemaining) day\(daysRemaining == 1 ? "" : "s")"
        } else {
            let weeks = daysRemaining / 7
            return "Due in \(weeks) week\(weeks == 1 ? "" : "s")"
        }
    }
    
    private var goalStatusInsight: String {
        let progress = goal.calculatedProgress
        let daysRemaining = goal.targetDate.map { Calendar.current.dateComponents([.day], from: Date(), to: $0).day ?? 0 } ?? 0
        
        if progress >= 100 {
            return "Completed successfully!"
        } else if daysRemaining < 0 && progress < 100 {
            return "Overdue - consider adjusting your target"
        } else if progress >= 75 {
            return "On track to complete on time"
        } else if progress >= 50 {
            return "Making good progress"
        } else {
            return "May need more focus to meet target"
        }
    }
}

struct InsightRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationView {
        GoalAnalyticsView(goal: Goal(
            title: "Sample Goal",
            description: "This is a sample goal for preview",
            targetValue: 100,
            unit: "points",
            progressType: .numerical
        ))
    }
} 
 
 
 