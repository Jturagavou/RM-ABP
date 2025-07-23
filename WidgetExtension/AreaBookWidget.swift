import WidgetKit
import SwiftUI

// MARK: - Main Widget Bundle
@main
struct AreaBookWidgetBundle: WidgetBundle {
    var body: some Widget {
        AreaBookMainWidget()
        KIProgressWidget()
        WellnessWidget()
        GoalsWidget()
    }
}

// MARK: - Main Dashboard Widget
struct AreaBookMainWidget: Widget {
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

// MARK: - Widget Provider
struct AreaBookWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> AreaBookWidgetEntry {
        AreaBookWidgetEntry.placeholder
    }
    
    func getSnapshot(in context: Context, completion: @escaping (AreaBookWidgetEntry) -> ()) {
        completion(AreaBookWidgetEntry.placeholder)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = AreaBookWidgetEntry.placeholder
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(15 * 60)))
        completion(timeline)
    }
}

// MARK: - Widget Entry
struct AreaBookWidgetEntry: TimelineEntry {
    let date: Date
    let keyIndicators: [WidgetKeyIndicator]
    let taskCount: Int
    let eventCount: Int
    
    static let placeholder = AreaBookWidgetEntry(
        date: Date(),
        keyIndicators: [
            WidgetKeyIndicator(name: "Scripture Study", progress: 85, color: "#3B82F6"),
            WidgetKeyIndicator(name: "Prayer", progress: 92, color: "#10B981"),
            WidgetKeyIndicator(name: "Exercise", progress: 60, color: "#F59E0B")
        ],
        taskCount: 3,
        eventCount: 2
    )
}

// MARK: - Widget Data Models
struct WidgetKeyIndicator {
    let name: String
    let progress: Int
    let color: String
}

// MARK: - Widget Views
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
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(entry.keyIndicators.prefix(2), id: \.name) { ki in
                    HStack {
                        Circle()
                            .fill(Color(hex: ki.color) ?? .blue)
                            .frame(width: 6, height: 6)
                        Text(ki.name)
                            .font(.caption2)
                            .lineLimit(1)
                        Spacer()
                        Text("\(ki.progress)%")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                }
            }
            
            Spacer()
            
            HStack {
                VStack(alignment: .leading) {
                    Text("\(entry.taskCount)")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("Tasks")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("\(entry.eventCount)")
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

struct MediumWidgetView: View {
    let entry: AreaBookWidgetEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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
                VStack(alignment: .leading, spacing: 8) {
                    Text("Key Indicators")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    ForEach(entry.keyIndicators.prefix(3), id: \.name) { ki in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Circle()
                                    .fill(Color(hex: ki.color) ?? .blue)
                                    .frame(width: 8, height: 8)
                                Text(ki.name)
                                    .font(.caption)
                                    .lineLimit(1)
                                Spacer()
                                Text("\(ki.progress)%")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            ProgressView(value: Double(ki.progress) / 100.0)
                                .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: ki.color) ?? .blue))
                                .scaleEffect(y: 0.5)
                        }
                    }
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Today")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "checkmark.square")
                                .foregroundColor(.green)
                                .font(.caption)
                            Text("\(entry.taskCount) Tasks")
                                .font(.caption)
                        }
                        
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                                .font(.caption)
                            Text("\(entry.eventCount) Events")
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

struct LargeWidgetView: View {
    let entry: AreaBookWidgetEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
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
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Weekly Key Indicators")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(entry.keyIndicators.prefix(4), id: \.name) { ki in
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
                                Text("\(ki.progress)%")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                Spacer()
                            }
                            
                            ProgressView(value: Double(ki.progress) / 100.0)
                                .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: ki.color) ?? .blue))
                        }
                        .padding(8)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                    }
                }
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Text("Tasks: \(entry.taskCount)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                VStack(alignment: .leading) {
                    Text("Events: \(entry.eventCount)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

// MARK: - Additional Widgets
struct KIProgressWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "KIProgressWidget", provider: AreaBookWidgetProvider()) { entry in
            Text("KI Progress")
                .padding()
        }
        .configurationDisplayName("Key Indicators")
        .description("Track your weekly progress.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct WellnessWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "WellnessWidget", provider: AreaBookWidgetProvider()) { entry in
            Text("Wellness")
                .padding()
        }
        .configurationDisplayName("Wellness Tracker")
        .description("Track your wellness activities.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct GoalsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "GoalsWidget", provider: AreaBookWidgetProvider()) { entry in
            Text("Goals")
                .padding()
        }
        .configurationDisplayName("Goal Progress")
        .description("Track your goal achievements.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Color Extension
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
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
} 