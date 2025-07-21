import WidgetKit
import SwiftUI

// Widget configuration constants
struct WidgetConfiguration {
    static let appGroupIdentifier = "group.com.areabook.app"
    
    struct Keys {
        static let keyIndicators = "keyIndicators"
        static let todaysTasks = "todaysTasks" 
        static let todaysEvents = "todaysEvents"
        static let lastUpdated = "widgetLastUpdated"
        static let userName = "userName"
        static let dailyQuote = "dailyQuote"
    }
}

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
            // Update every 15 minutes for better UX
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
    
    private func loadWidgetData(completion: @escaping (AreaBookWidgetEntry) -> Void) {
        // Load data from UserDefaults (shared with main app)
        let sharedDefaults = UserDefaults(suiteName: WidgetConfiguration.appGroupIdentifier)
        
        let keyIndicatorsData = sharedDefaults?.data(forKey: WidgetConfiguration.Keys.keyIndicators) ?? Data()
        let tasksData = sharedDefaults?.data(forKey: WidgetConfiguration.Keys.todaysTasks) ?? Data()
        let eventsData = sharedDefaults?.data(forKey: WidgetConfiguration.Keys.todaysEvents) ?? Data()
        
        var keyIndicators: [KeyIndicator] = []
        var tasks: [Task] = []
        var events: [CalendarEvent] = []
        
        do {
            if !keyIndicatorsData.isEmpty {
                keyIndicators = try JSONDecoder().decode([KeyIndicator].self, from: keyIndicatorsData)
            }
            if !tasksData.isEmpty {
                tasks = try JSONDecoder().decode([Task].self, from: tasksData)
            }
            if !eventsData.isEmpty {
                events = try JSONDecoder().decode([CalendarEvent].self, from: eventsData)
            }
        } catch {
            print("Error decoding widget data: \(error)")
        }
        
        let entry = AreaBookWidgetEntry(
            date: Date(),
            keyIndicators: keyIndicators,
            todaysTasks: tasks,
            todaysEvents: events
        )
        
        completion(entry)
    }
}

// MARK: - Widget Entry
struct AreaBookWidgetEntry: TimelineEntry {
    let date: Date
    let keyIndicators: [KeyIndicator]
    let todaysTasks: [Task]
    let todaysEvents: [CalendarEvent]
    
    static let placeholder = AreaBookWidgetEntry(
        date: Date(),
        keyIndicators: [
            KeyIndicator(name: "Scripture Study", weeklyTarget: 7, unit: "sessions", color: "#3B82F6"),
            KeyIndicator(name: "Prayer", weeklyTarget: 14, unit: "times", color: "#10B981")
        ],
        todaysTasks: [
            Task(title: "Complete morning study", priority: .high),
            Task(title: "Review goals", priority: .medium)
        ],
        todaysEvents: [
            CalendarEvent(
                title: "Sunday School",
                description: "Weekly class",
                category: "Church",
                startTime: Date(),
                endTime: Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
            )
        ]
    )
}

// MARK: - Small Widget View
struct SmallWidgetView: View {
    let entry: AreaBookWidgetEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "book.pages")
                    .foregroundColor(.blue)
                    .font(.caption)
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
                Image(systemName: "book.pages")
                    .foregroundColor(.blue)
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
                Image(systemName: "book.pages")
                    .foregroundColor(.blue)
                    .font(.title3)
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
@main
struct AreaBookWidgetBundle: WidgetBundle {
    var body: some Widget {
        AreaBookWidget()
        KIProgressWidget()
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
        }
    }
}