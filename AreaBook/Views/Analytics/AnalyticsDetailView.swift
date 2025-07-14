import SwiftUI
import Charts

struct AnalyticsDetailView: View {
    let analytics: AnalyticsData?
    @Environment(\.dismiss) private var dismiss
    @StateObject private var analyticsService = AnalyticsService.shared
    @State private var selectedTimeRange: TimeRange = .thisWeek
    @State private var selectedCategory: AnalyticsCategory = .productivity
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    if let analytics = analytics {
                        // Time Range Selector
                        TimeRangeSelector(selectedRange: $selectedTimeRange)
                        
                        // Key Metrics Grid
                        MetricsGrid(metrics: analytics.metrics)
                        
                        // Productivity Score Card
                        if let productivityScore = analytics.metrics.first(where: { $0.name == "Productivity Score" }) {
                            ProductivityScoreCard(score: productivityScore.value)
                        }
                        
                        // Trends Section
                        if !analytics.trends.isEmpty {
                            TrendsSection(trends: analytics.trends)
                        }
                        
                        // Category Breakdown
                        CategoryBreakdownSection(
                            metrics: analytics.metrics,
                            selectedCategory: $selectedCategory
                        )
                        
                        // Insights Section
                        if !analytics.insights.isEmpty {
                            DetailedInsightsSection(insights: analytics.insights)
                        }
                        
                        // Goal Progress Chart
                        GoalProgressChart()
                        
                        // Weekly Activity Chart
                        WeeklyActivityChart()
                        
                    } else {
                        // Loading State
                        AnalyticsLoadingView()
                    }
                }
                .padding()
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
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

struct TimeRangeSelector: View {
    @Binding var selectedRange: TimeRange
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Time Period")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Button(action: { selectedRange = range }) {
                        Text(range.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedRange == range ? Color.blue : Color(.systemGray5))
                            .foregroundColor(selectedRange == range ? .white : .primary)
                            .cornerRadius(8)
                    }
                }
                Spacer()
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct MetricsGrid: View {
    let metrics: [AnalyticsMetric]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Key Metrics")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(metrics) { metric in
                    MetricCard(metric: metric)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct MetricCard: View {
    let metric: AnalyticsMetric
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconForCategory(metric.category))
                    .font(.title3)
                    .foregroundColor(colorForCategory(metric.category))
                Spacer()
            }
            
            Text("\(metric.value, specifier: metric.unit == "%" ? "%.1f" : "%.0f")")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(metric.name)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            Text(metric.unit)
                .font(.caption2)
                .foregroundColor(colorForCategory(metric.category))
                .fontWeight(.medium)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    private func iconForCategory(_ category: AnalyticsCategory) -> String {
        switch category {
        case .goals: return "target"
        case .tasks: return "checkmark.circle"
        case .keyIndicators: return "chart.bar"
        case .events: return "calendar"
        case .productivity: return "bolt.fill"
        case .engagement: return "heart.fill"
        case .groups: return "person.3.fill"
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

struct ProductivityScoreCard: View {
    let score: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Productivity Score")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 20) {
                // Circular Progress
                ZStack {
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 8)
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .trim(from: 0, to: score / 100)
                        .stroke(scoreColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1), value: score)
                    
                    VStack {
                        Text("\(Int(score))")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(scoreColor)
                        Text("Score")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(scoreDescription)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(scoreAdvice)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Score Breakdown
                    ScoreBreakdown(score: score)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var scoreColor: Color {
        if score >= 80 { return .green }
        else if score >= 60 { return .blue }
        else if score >= 40 { return .orange }
        else { return .red }
    }
    
    private var scoreDescription: String {
        if score >= 80 { return "Excellent Performance" }
        else if score >= 60 { return "Good Performance" }
        else if score >= 40 { return "Room for Improvement" }
        else { return "Needs Attention" }
    }
    
    private var scoreAdvice: String {
        if score >= 80 { return "Keep up the excellent work!" }
        else if score >= 60 { return "You're doing well, stay consistent!" }
        else if score >= 40 { return "Focus on completing more tasks." }
        else { return "Start with small, achievable goals." }
    }
}

struct ScoreBreakdown: View {
    let score: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            BreakdownItem(title: "Goals", value: 40, color: .blue)
            BreakdownItem(title: "Tasks", value: 30, color: .green)
            BreakdownItem(title: "KIs", value: 30, color: .purple)
        }
    }
}

struct BreakdownItem: View {
    let title: String
    let value: Int
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            Spacer()
            Text("\(value)%")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

struct TrendsSection: View {
    let trends: [AnalyticsTrend]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Trends")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(trends) { trend in
                TrendRow(trend: trend)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct TrendRow: View {
    let trend: AnalyticsTrend
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(trend.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(trend.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: trendIcon)
                        .font(.caption)
                        .foregroundColor(trendColor)
                    Text("\(trend.percentage, specifier: "%.1f")%")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(trendColor)
                }
                
                Text(trend.period.rawValue.capitalized)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    private var trendIcon: String {
        switch trend.direction {
        case .increasing: return "arrow.up.right"
        case .decreasing: return "arrow.down.right"
        case .stable: return "arrow.right"
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

struct CategoryBreakdownSection: View {
    let metrics: [AnalyticsMetric]
    @Binding var selectedCategory: AnalyticsCategory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Category Breakdown")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Category Selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(AnalyticsCategory.allCases, id: \.self) { category in
                        Button(action: { selectedCategory = category }) {
                            Text(category.displayName)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedCategory == category ? Color.blue : Color(.systemGray5))
                                .foregroundColor(selectedCategory == category ? .white : .primary)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Category Metrics
            let categoryMetrics = metrics.filter { $0.category == selectedCategory }
            if !categoryMetrics.isEmpty {
                ForEach(categoryMetrics) { metric in
                    CategoryMetricRow(metric: metric)
                }
            } else {
                Text("No data available for this category")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct CategoryMetricRow: View {
    let metric: AnalyticsMetric
    
    var body: some View {
        HStack {
            Text(metric.name)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            Text("\(metric.value, specifier: "%.1f") \(metric.unit)")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.blue)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct DetailedInsightsSection: View {
    let insights: [AnalyticsInsight]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Detailed Insights")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(insights) { insight in
                DetailedInsightCard(insight: insight)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct DetailedInsightCard: View {
    let insight: AnalyticsInsight
    @State private var showingSuggestions = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: iconForCategory(insight.category))
                    .font(.title3)
                    .foregroundColor(colorForCategory(insight.category))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(insight.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(insight.category.displayName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                ConfidenceIndicator(confidence: insight.confidence)
            }
            
            Text(insight.description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if insight.actionable && !insight.suggestions.isEmpty {
                Button(action: { showingSuggestions.toggle() }) {
                    HStack {
                        Text("View Suggestions")
                            .font(.caption)
                            .fontWeight(.medium)
                        Image(systemName: showingSuggestions ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                    }
                    .foregroundColor(.blue)
                }
                
                if showingSuggestions {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(insight.suggestions, id: \.self) { suggestion in
                            HStack(alignment: .top) {
                                Text("•")
                                    .foregroundColor(.blue)
                                Text(suggestion)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    private func iconForCategory(_ category: AnalyticsCategory) -> String {
        switch category {
        case .goals: return "target"
        case .tasks: return "checkmark.circle"
        case .keyIndicators: return "chart.bar"
        case .events: return "calendar"
        case .productivity: return "bolt.fill"
        case .engagement: return "heart.fill"
        case .groups: return "person.3.fill"
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

struct GoalProgressChart: View {
    @State private var chartData: [ChartDataPoint] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Goal Progress Over Time")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Placeholder for chart - would use Swift Charts in real implementation
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemBackground))
                    .frame(height: 200)
                
                VStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.largeTitle)
                        .foregroundColor(.blue)
                    Text("Goal Progress Chart")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("(Chart implementation needed)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct WeeklyActivityChart: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly Activity")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Placeholder for activity chart
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemBackground))
                    .frame(height: 150)
                
                VStack {
                    Image(systemName: "calendar.badge.clock")
                        .font(.largeTitle)
                        .foregroundColor(.green)
                    Text("Weekly Activity Chart")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("(Chart implementation needed)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct AnalyticsLoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Generating Analytics...")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("This may take a moment")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Supporting Types

enum TimeRange: String, CaseIterable {
    case thisWeek = "thisWeek"
    case thisMonth = "thisMonth"
    case last3Months = "last3Months"
    case thisYear = "thisYear"
    
    var displayName: String {
        switch self {
        case .thisWeek: return "This Week"
        case .thisMonth: return "This Month"
        case .last3Months: return "3 Months"
        case .thisYear: return "This Year"
        }
    }
}

extension AnalyticsCategory {
    var displayName: String {
        switch self {
        case .goals: return "Goals"
        case .tasks: return "Tasks"
        case .keyIndicators: return "Key Indicators"
        case .events: return "Events"
        case .productivity: return "Productivity"
        case .engagement: return "Engagement"
        case .groups: return "Groups"
        }
    }
}

struct ChartDataPoint {
    let date: Date
    let value: Double
}

#Preview {
    AnalyticsDetailView(analytics: nil)
}