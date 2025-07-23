import WidgetKit
import SwiftUI
import Firebase

// MARK: - Widget Timeline Provider
struct AreaBookWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> AreaBookWidgetEntry {
        AreaBookWidgetEntry.placeholder
    }
    
    func getSnapshot(in context: Context, completion: @escaping (AreaBookWidgetEntry) -> ()) {
        if context.isPreview {
            completion(AreaBookWidgetEntry.placeholder)
        } else {
            loadWidgetData { entry in
                completion(entry)
            }
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        loadWidgetData { entry in
            // Update every 5 minutes for more responsive widgets
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            print("🔄 WidgetProvider: Timeline created with next update at \(nextUpdate)")
            completion(timeline)
        }
    }
    
    private func loadWidgetData(completion: @escaping (AreaBookWidgetEntry) -> Void) {
        // Load data from shared UserDefaults using utilities
        let keyIndicators = WidgetDataUtilities.loadData([KeyIndicator].self, forKey: WidgetDataKeys.keyIndicators) ?? []
        let tasks = WidgetDataUtilities.loadData([AppTask].self, forKey: WidgetDataKeys.todaysTasks) ?? []
        let events = WidgetDataUtilities.loadData([CalendarEvent].self, forKey: WidgetDataKeys.todaysEvents) ?? []
        let goals = WidgetDataUtilities.loadData([Goal].self, forKey: WidgetDataKeys.goals) ?? []
        let notes = WidgetDataUtilities.loadData([Note].self, forKey: WidgetDataKeys.recentNotes) ?? []
        let wellnessData = WidgetDataUtilities.loadData(WellnessData.self, forKey: WidgetDataKeys.wellnessData) ?? WellnessData()
        
        let entry = AreaBookWidgetEntry(
            date: Date(),
            keyIndicators: keyIndicators,
            todaysTasks: tasks,
            todaysEvents: events,
            goals: goals,
            notes: notes,
            wellnessData: wellnessData
        )
        
        completion(entry)
    }
}

// MARK: - Widget Entry
struct AreaBookWidgetEntry: TimelineEntry {
    let date: Date
    let keyIndicators: [KeyIndicator]
    let todaysTasks: [AppTask]
    let todaysEvents: [CalendarEvent]
    let goals: [Goal]
    let notes: [Note]
    let wellnessData: WellnessData
    
    static let placeholder = AreaBookWidgetEntry(
        date: Date(),
        keyIndicators: [
            KeyIndicator(name: "Scripture Study", weeklyTarget: 7, unit: "sessions", color: "#3B82F6"),
            KeyIndicator(name: "Prayer", weeklyTarget: 14, unit: "times", color: "#10B981"),
            KeyIndicator(name: "Exercise", weeklyTarget: 5, unit: "sessions", color: "#F59E0B")
        ],
        todaysTasks: [
            AppTask(title: "Complete morning study", priority: .high),
            AppTask(title: "Review goals", priority: .medium),
            AppTask(title: "Exercise routine", priority: .low)
        ],
        todaysEvents: [
            CalendarEvent(
                title: "Sunday School",
                description: "Weekly class",
                category: "Church",
                startTime: Date(),
                endTime: Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
            ),
            CalendarEvent(
                title: "Team Meeting",
                description: "Weekly sync",
                category: "Work",
                startTime: Calendar.current.date(byAdding: .hour, value: 2, to: Date())!,
                endTime: Calendar.current.date(byAdding: .hour, value: 3, to: Date())!
            )
        ],
        goals: [
            Goal(title: "Read 12 books this year", description: "Personal development", targetDate: Calendar.current.date(byAdding: .month, value: 6, to: Date())!, targetValue: 12.0, unit: "books"),
            Goal(title: "Run a marathon", description: "Fitness goal", targetDate: Calendar.current.date(byAdding: .month, value: 3, to: Date())!, targetValue: 26.2, unit: "miles")
        ],
        notes: [
            Note(title: "Project ideas", content: "New app concepts..."),
            Note(title: "Meeting notes", content: "Key points from today...")
        ],
        wellnessData: WellnessData(
            currentMood: MoodType.good,
            meditationMinutes: 15,
            waterGlasses: 6,
            sleepHours: 7.5
        )
    )
}



// MARK: - Small Widget View
struct SmallWidgetView: View {
    let entry: AreaBookWidgetEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image("AppLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 16, height: 16)
                Text("AreaBook")
                    .font(.caption)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            if !entry.keyIndicators.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(entry.keyIndicators.prefix(2)) { ki in
                        HStack {
                            Circle()
                                .fill(Color(hex: ki.color) ?? .blue)
                                .frame(width: 6, height: 6)
                            Text(ki.name)
                                .font(.caption2)
                                .lineLimit(1)
                            Spacer()
                            Text("\(Int(ki.progressPercentage * 100))%")
                                .font(.caption2)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
            
            Spacer()
            
            HStack {
                VStack(alignment: .leading) {
                    Text("\(entry.todaysTasks.count)")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("Tasks")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(entry.todaysEvents.count)")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("Events")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

// MARK: - Medium Widget View
struct MediumWidgetView: View {
    let entry: AreaBookWidgetEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image("AppLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 16, height: 16)
                Text("AreaBook")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text(entry.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 16) {
                // Key Indicators
                VStack(alignment: .leading, spacing: 8) {
                    Text("Key Indicators")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    ForEach(entry.keyIndicators.prefix(3)) { ki in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Circle()
                                    .fill(Color(hex: ki.color) ?? .blue)
                                    .frame(width: 8, height: 8)
                                Text(ki.name)
                                    .font(.caption)
                                    .lineLimit(1)
                                Spacer()
                                Text("\(Int(ki.progressPercentage * 100))%")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            ProgressView(value: ki.progressPercentage)
                                .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: ki.color) ?? .blue))
                                .scaleEffect(y: 0.5)
                        }
                    }
                }
                
                Divider()
                
                // Today's Summary
                VStack(alignment: .leading, spacing: 8) {
                    Text("Today")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "checkmark.square")
                                .foregroundColor(.green)
                                .font(.caption)
                            Text("\(entry.todaysTasks.count) Tasks")
                                .font(.caption)
                            Spacer()
                        }
                        
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                                .font(.caption)
                            Text("\(entry.todaysEvents.count) Events")
                                .font(.caption)
                            Spacer()
                        }
                        
                        if let nextEvent = entry.todaysEvents.first {
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                                Text("Next: \(nextEvent.startTime, style: .time)")
                                    .font(.caption)
                                Spacer()
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

// MARK: - Large Widget View
struct LargeWidgetView: View {
    let entry: AreaBookWidgetEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image("AppLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 16, height: 16)
                VStack(alignment: .leading) {
                    Text("AreaBook")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Dashboard")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(entry.date, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Key Indicators Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Weekly Key Indicators")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(entry.keyIndicators.prefix(4)) { ki in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Circle()
                                    .fill(Color(hex: ki.color) ?? .blue)
                                    .frame(width: 10, height: 10)
                                Text(ki.name)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                                Spacer()
                            }
                            
                            HStack {
                                Text("\(ki.currentWeekProgress)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                Text("/ \(ki.weeklyTarget)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(Int(ki.progressPercentage * 100))%")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(Color(hex: ki.color) ?? .blue)
                            }
                            
                            ProgressView(value: ki.progressPercentage)
                                .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: ki.color) ?? .blue))
                        }
                        .padding(8)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                    }
                }
            }
            
            // Today's Schedule
            HStack(spacing: 16) {
                // Tasks
                VStack(alignment: .leading, spacing: 6) {
                    Text("Today's Tasks")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    ForEach(entry.todaysTasks.prefix(3)) { task in
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
                    
                    if entry.todaysTasks.count > 3 {
                        Text("+ \(entry.todaysTasks.count - 3) more")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Events
                VStack(alignment: .leading, spacing: 6) {
                    Text("Today's Events")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    ForEach(entry.todaysEvents.prefix(3)) { event in
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
                    
                    if entry.todaysEvents.count > 3 {
                        Text("+ \(entry.todaysEvents.count - 3) more")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

// MARK: - Wellness Widget
struct WellnessWidget: Widget {
    let kind: String = "WellnessWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AreaBookWidgetProvider()) { entry in
            WellnessWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Wellness Tracker")
        .description("Track your mood, meditation, and wellness activities.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct WellnessWidgetEntryView: View {
    var entry: AreaBookWidgetProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.pink)
                Text("Wellness")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            if family == .systemSmall {
                // Compact wellness view
                VStack(spacing: 8) {
                    HStack {
                        Text(entry.wellnessData.currentMood.emoji)
                            .font(.title2)
                        Text(entry.wellnessData.currentMood.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    HStack {
                        VStack {
                            Text("\(entry.wellnessData.meditationMinutes)")
                                .font(.headline)
                                .fontWeight(.bold)
                            Text("min")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack {
                            Text("\(entry.wellnessData.waterGlasses)")
                                .font(.headline)
                                .fontWeight(.bold)
                            Text("glasses")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } else {
                // Medium wellness view
                VStack(spacing: 8) {
                    HStack {
                        Text("Mood: \(entry.wellnessData.currentMood.emoji) \(entry.wellnessData.currentMood.displayName)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    
                    HStack(spacing: 16) {
                        WellnessMetric(
                            icon: "timer",
                            value: "\(entry.wellnessData.meditationMinutes)",
                            label: "Meditation",
                            color: .blue
                        )
                        
                        WellnessMetric(
                            icon: "drop.fill",
                            value: "\(entry.wellnessData.waterGlasses)",
                            label: "Water",
                            color: .cyan
                        )
                        
                        WellnessMetric(
                            icon: "bed.double.fill",
                            value: String(format: "%.1f", entry.wellnessData.sleepHours),
                            label: "Sleep",
                            color: .purple
                        )
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

struct WellnessMetric: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.caption)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Goals Widget
struct GoalsWidget: Widget {
    let kind: String = "GoalsWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AreaBookWidgetProvider()) { entry in
            GoalsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Goal Progress")
        .description("Track your goal progress and achievements.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct GoalsWidgetEntryView: View {
    var entry: AreaBookWidgetProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "target")
                    .foregroundColor(.purple)
                Text("Goals")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            if entry.goals.isEmpty {
                Text("No active goals")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                VStack(spacing: 8) {
                    ForEach(entry.goals.prefix(family == .systemSmall ? 2 : 3)) { goal in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(goal.title)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                                Spacer()
                                Text("\(Int(goal.calculatedProgress))%")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            }
                            
                            ProgressView(value: Double(goal.calculatedProgress) / 100.0)
                                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                                .scaleEffect(y: 0.5)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

// MARK: - Widget Configuration
struct AreaBookWidget: Widget {
    let kind: String = "AreaBookWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AreaBookWidgetProvider()) { entry in
            AreaBookWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("AreaBook Dashboard")
        .description("Keep track of your key indicators, tasks, and events.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Widget Entry View
struct AreaBookWidgetEntryView: View {
    var entry: AreaBookWidgetProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - KI Progress Widget
struct KIProgressWidget: Widget {
    let kind: String = "KIProgressWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AreaBookWidgetProvider()) { entry in
            KIProgressWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Key Indicators")
        .description("Track your weekly key indicator progress.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct KIProgressWidgetEntryView: View {
    var entry: AreaBookWidgetProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                Text("Key Indicators")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            if family == .systemSmall {
                // Show top 2 KIs for small widget
                ForEach(entry.keyIndicators.prefix(2)) { ki in
                    KIProgressRow(keyIndicator: ki, compact: true)
                }
            } else {
                // Show all KIs for medium widget
                ForEach(entry.keyIndicators.prefix(4)) { ki in
                    KIProgressRow(keyIndicator: ki, compact: false)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

struct KIProgressRow: View {
    let keyIndicator: KeyIndicator
    let compact: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 2 : 4) {
            HStack {
                Circle()
                    .fill(Color(hex: keyIndicator.color) ?? .blue)
                    .frame(width: compact ? 8 : 10, height: compact ? 8 : 10)
                Text(keyIndicator.name)
                    .font(compact ? .caption : .subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Spacer()
                Text("\(Int(keyIndicator.progressPercentage * 100))%")
                    .font(compact ? .caption2 : .caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: keyIndicator.color) ?? .blue)
            }
            
            ProgressView(value: keyIndicator.progressPercentage)
                .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: keyIndicator.color) ?? .blue))
                .scaleEffect(y: compact ? 0.7 : 1.0)
            
            if !compact {
                Text("\(keyIndicator.currentWeekProgress) / \(keyIndicator.weeklyTarget) \(keyIndicator.unit)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Widget Bundle
struct AreaBookWidgetBundle: WidgetBundle {
    var body: some Widget {
        AreaBookWidget()
        KIProgressWidget()
        WellnessWidget()
        // TasksWidget() // Removed as per edit hint
        GoalsWidget()
    }
}

// MARK: - Preview
struct AreaBookWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AreaBookWidgetEntryView(entry: AreaBookWidgetEntry.placeholder)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Small")
            
            AreaBookWidgetEntryView(entry: AreaBookWidgetEntry.placeholder)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Medium")
            
            AreaBookWidgetEntryView(entry: AreaBookWidgetEntry.placeholder)
                .previewContext(WidgetPreviewContext(family: .systemLarge))
                .previewDisplayName("Large")
            
            KIProgressWidgetEntryView(entry: AreaBookWidgetEntry.placeholder)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("KI Small")
            
            KIProgressWidgetEntryView(entry: AreaBookWidgetEntry.placeholder)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("KI Medium")
            
            WellnessWidgetEntryView(entry: AreaBookWidgetEntry.placeholder)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Wellness Small")
            
            WellnessWidgetEntryView(entry: AreaBookWidgetEntry.placeholder)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Wellness Medium")
            
            // TasksWidgetEntryView(entry: AreaBookWidgetEntry.placeholder) // Removed as per edit hint
            //     .previewContext(WidgetPreviewContext(family: .systemSmall))
            //     .previewDisplayName("Tasks Small")
            
            // TasksWidgetEntryView(entry: AreaBookWidgetEntry.placeholder) // Removed as per edit hint
            //     .previewContext(WidgetPreviewContext(family: .systemMedium))
            //     .previewDisplayName("Tasks Medium")
            
            GoalsWidgetEntryView(entry: AreaBookWidgetEntry.placeholder)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Goals Small")
            
            GoalsWidgetEntryView(entry: AreaBookWidgetEntry.placeholder)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Goals Medium")
        }
    }
}
