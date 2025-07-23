import SwiftUI

struct KeyIndicatorsView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingCreateKeyIndicator = false
    @State private var selectedTimeframe: Timeframe = .week
    @State private var showingStats = false
    
    enum Timeframe: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with stats
                    KeyIndicatorsHeader(
                        keyIndicators: dataManager.keyIndicators,
                        timeframe: selectedTimeframe
                    )
                    
                    // Timeframe selector
                    TimeframeSelector(selectedTimeframe: $selectedTimeframe)
                    
                    // Key Indicators Grid
                    if dataManager.keyIndicators.isEmpty {
                        EmptyKeyIndicatorsView {
                            showingCreateKeyIndicator = true
                        }
                    } else {
                        KeyIndicatorsGrid(
                            keyIndicators: dataManager.keyIndicators,
                            timeframe: selectedTimeframe
                        )
                    }
                    
                    // Weekly Progress Summary
                    if !dataManager.keyIndicators.isEmpty {
                        WeeklyProgressSummary(keyIndicators: dataManager.keyIndicators)
                    }
                    
                    // Quick Actions
                    QuickActionsSection()
                }
                .padding()
            }
            .navigationTitle("Life Trackers")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateKeyIndicator = true }) {
                        Image(systemName: "plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingStats = true }) {
                        Image(systemName: "chart.bar")
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreateKeyIndicator) {
            CreateKeyIndicatorView()
                .environmentObject(dataManager)
                .environmentObject(authViewModel)
        }
        .sheet(isPresented: $showingStats) {
            KeyIndicatorsStatsView(keyIndicators: dataManager.keyIndicators)
        }
    }
}

// MARK: - Header Component
struct KeyIndicatorsHeader: View {
    let keyIndicators: [KeyIndicator]
    let timeframe: KeyIndicatorsView.Timeframe
    
    private var totalProgress: Double {
        guard !keyIndicators.isEmpty else { return 0 }
        let totalProgress = keyIndicators.reduce(0) { $0 + $1.progressPercentage }
        return totalProgress / Double(keyIndicators.count)
    }
    
    private var completedCount: Int {
        keyIndicators.filter { $0.progressPercentage >= 1.0 }.count
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Overall Progress Circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: totalProgress)
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .green],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: totalProgress)
                
                VStack(spacing: 4) {
                    Text("\(Int(totalProgress * 100))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Overall")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Stats Row
            HStack(spacing: 30) {
                StatItem(
                    title: "Active",
                    value: "\(keyIndicators.count)",
                    icon: "chart.bar.fill",
                    color: .blue
                )
                
                StatItem(
                    title: "Completed",
                    value: "\(completedCount)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                StatItem(
                    title: "In Progress",
                    value: "\(keyIndicators.count - completedCount)",
                    icon: "clock.fill",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Timeframe Selector
struct TimeframeSelector: View {
    @Binding var selectedTimeframe: KeyIndicatorsView.Timeframe
    
    var body: some View {
        HStack {
            ForEach(KeyIndicatorsView.Timeframe.allCases, id: \.self) { timeframe in
                Button(action: { selectedTimeframe = timeframe }) {
                    Text(timeframe.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            selectedTimeframe == timeframe ?
                            Color.blue :
                            Color(.systemGray6)
                        )
                        .foregroundColor(
                            selectedTimeframe == timeframe ?
                            .white :
                            .primary
                        )
                        .cornerRadius(20)
                }
            }
        }
    }
}

// MARK: - Key Indicators Grid
struct KeyIndicatorsGrid: View {
    let keyIndicators: [KeyIndicator]
    let timeframe: KeyIndicatorsView.Timeframe
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
            ForEach(keyIndicators) { indicator in
                KeyIndicatorCard(
                    indicator: indicator,
                    timeframe: timeframe
                )
            }
        }
    }
}

// MARK: - Key Indicator Card
struct KeyIndicatorCard: View {
    let indicator: KeyIndicator
    let timeframe: KeyIndicatorsView.Timeframe
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: { showingDetail = true }) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Circle()
                        .fill(Color(hex: indicator.color))
                        .frame(width: 12, height: 12)
                    
                    Text(indicator.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(indicator.currentWeekProgress)/\(indicator.weeklyTarget)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Progress Bar
                ProgressView(value: indicator.progressPercentage)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: indicator.color)))
                
                // Unit and Status
                HStack {
                    Text(indicator.unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(indicator.progressPercentage >= 1.0 ? "Complete" : "In Progress")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(indicator.progressPercentage >= 1.0 ? .green : .orange)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            KeyIndicatorDetailView(indicator: indicator)
        }
    }
}

// MARK: - Weekly Progress Summary
struct WeeklyProgressSummary: View {
    let keyIndicators: [KeyIndicator]
    
    private var weeklyStats: (completed: Int, total: Int, percentage: Double) {
        let completed = keyIndicators.filter { $0.progressPercentage >= 1.0 }.count
        let total = keyIndicators.count
        let percentage = total > 0 ? Double(completed) / Double(total) : 0
        return (completed, total, percentage)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week's Progress")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(weeklyStats.completed) of \(weeklyStats.total) completed")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Text("\(Int(weeklyStats.percentage * 100))% weekly goal achieved")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                CircularProgressView(
                    progress: weeklyStats.percentage,
                    size: 60,
                    lineWidth: 6
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Quick Actions Section
struct QuickActionsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 12) {
                QuickActionButton(
                    icon: "plus.circle.fill",
                    title: "Add Tracker",
                    color: .blue
                ) {
                    // Action handled by parent
                }
                
                QuickActionButton(
                    icon: "chart.bar.fill",
                    title: "View Stats",
                    color: .green
                ) {
                    // Action handled by parent
                }
                
                QuickActionButton(
                    icon: "arrow.clockwise",
                    title: "Reset Week",
                    color: .orange
                ) {
                    // Action handled by parent
                }
            }
        }
    }
}

// MARK: - Empty State
struct EmptyKeyIndicatorsView: View {
    let onCreateNew: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Life Trackers Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create your first life tracker to start monitoring your habits and goals")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: onCreateNew) {
                HStack {
                    Image(systemName: "plus")
                    Text("Create First Tracker")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
        }
        .padding(.top, 60)
    }
}

// MARK: - Supporting Views
struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CircularProgressView: View {
    let progress: Double
    let size: CGFloat
    let lineWidth: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: lineWidth)
                .frame(width: size, height: size)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [.blue, .green],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
            
            Text("\(Int(progress * 100))%")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Key Indicator Detail View
struct KeyIndicatorDetailView: View {
    let indicator: KeyIndicator
    @Environment(\.dismiss) private var dismiss
    @State private var showingEdit = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Progress Overview
                    VStack(spacing: 16) {
                        CircularProgressView(
                            progress: indicator.progressPercentage,
                            size: 120,
                            lineWidth: 8
                        )
                        
                        VStack(spacing: 8) {
                            Text(indicator.name)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("\(indicator.currentWeekProgress) of \(indicator.weeklyTarget) \(indicator.unit)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    
                    // Weekly Progress Chart
                    WeeklyProgressChart(indicator: indicator)
                    
                    // Quick Actions
                    QuickUpdateSection(indicator: indicator)
                }
                .padding()
            }
            .navigationTitle("Tracker Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        showingEdit = true
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            CreateKeyIndicatorView(editingIndicator: indicator)
        }
    }
}

// MARK: - Weekly Progress Chart
struct WeeklyProgressChart: View {
    let indicator: KeyIndicator
    
    // Mock weekly data - in real app, this would come from data manager
    private var weeklyData: [Double] {
        [0.2, 0.4, 0.6, 0.8, 0.9, 0.95, indicator.progressPercentage]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week's Progress")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(weeklyData.enumerated()), id: \.offset) { index, progress in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: indicator.color))
                            .frame(height: max(20, progress * 100))
                            .animation(.easeInOut(duration: 0.5), value: progress)
                        
                        Text(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][index])
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(height: 120)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Quick Update Section
struct QuickUpdateSection: View {
    let indicator: KeyIndicator
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Update")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 12) {
                QuickUpdateButton(
                    title: "+1",
                    action: { updateProgress(by: 1) }
                )
                
                QuickUpdateButton(
                    title: "+5",
                    action: { updateProgress(by: 5) }
                )
                
                QuickUpdateButton(
                    title: "+10",
                    action: { updateProgress(by: 10) }
                )
                
                QuickUpdateButton(
                    title: "Reset",
                    action: { resetProgress() },
                    isDestructive: true
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private func updateProgress(by amount: Int) {
        guard let userId = authViewModel.currentUser?.id else { return }
        
        var updatedIndicator = indicator
        updatedIndicator.currentWeekProgress = min(
            updatedIndicator.currentWeekProgress + amount,
            updatedIndicator.weeklyTarget
        )
        updatedIndicator.updatedAt = Date()
        
        dataManager.updateKeyIndicator(updatedIndicator, userId: userId)
    }
    
    private func resetProgress() {
        guard let userId = authViewModel.currentUser?.id else { return }
        
        var updatedIndicator = indicator
        updatedIndicator.currentWeekProgress = 0
        updatedIndicator.updatedAt = Date()
        
        dataManager.updateKeyIndicator(updatedIndicator, userId: userId)
    }
}

struct QuickUpdateButton: View {
    let title: String
    let action: () -> Void
    var isDestructive: Bool = false
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isDestructive ? Color.red : Color.blue)
                .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Stats View
struct KeyIndicatorsStatsView: View {
    let keyIndicators: [KeyIndicator]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Overall Stats
                    OverallStatsCard(keyIndicators: keyIndicators)
                    
                    // Top Performers
                    TopPerformersCard(keyIndicators: keyIndicators)
                    
                    // Weekly Trends
                    WeeklyTrendsCard(keyIndicators: keyIndicators)
                }
                .padding()
            }
            .navigationTitle("Statistics")
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

struct OverallStatsCard: View {
    let keyIndicators: [KeyIndicator]
    
    private var averageProgress: Double {
        guard !keyIndicators.isEmpty else { return 0 }
        return keyIndicators.reduce(0) { $0 + $1.progressPercentage } / Double(keyIndicators.count)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Overall Performance")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(Int(averageProgress * 100))%")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text("Average Progress")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(keyIndicators.count)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("Active Trackers")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct TopPerformersCard: View {
    let keyIndicators: [KeyIndicator]
    
    private var topPerformers: [KeyIndicator] {
        keyIndicators.sorted { $0.progressPercentage > $1.progressPercentage }.prefix(3).map { $0 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Performers")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(topPerformers, id: \.id) { indicator in
                HStack {
                    Circle()
                        .fill(Color(hex: indicator.color))
                        .frame(width: 8, height: 8)
                    
                    Text(indicator.name)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(Int(indicator.progressPercentage * 100))%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct WeeklyTrendsCard: View {
    let keyIndicators: [KeyIndicator]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Trends")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Mock trend data - in real app, this would show actual trends
            VStack(spacing: 8) {
                TrendRow(title: "Most Consistent", value: "Exercise", trend: .up)
                TrendRow(title: "Biggest Improvement", value: "Reading", trend: .up)
                TrendRow(title: "Needs Attention", value: "Meditation", trend: .down)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct TrendRow: View {
    let title: String
    let value: String
    let trend: TrendDirection
    
    enum TrendDirection {
        case up, down, neutral
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Image(systemName: trend == .up ? "arrow.up" : trend == .down ? "arrow.down" : "minus")
                .font(.caption)
                .foregroundColor(trend == .up ? .green : trend == .down ? .red : .gray)
        }
    }
}

#Preview {
    KeyIndicatorsView()
        .environmentObject(DataManager.shared)
        .environmentObject(AuthViewModel.shared)
} 