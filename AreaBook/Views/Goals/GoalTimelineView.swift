import SwiftUI

struct GoalTimelineView: View {
    @EnvironmentObject var dataManager: DataManager
    let goalId: String
    @State private var selectedType: TimelineItemType? = nil

    var filteredTimeline: [TimelineItem] {
        let timeline = dataManager.getTimelineForGoal(goalId: goalId)
        if let type = selectedType {
            return timeline.filter { $0.type == type }
        }
        return timeline
    }

    var body: some View {
        VStack {
            Picker("Filter", selection: $selectedType) {
                Text("All").tag(TimelineItemType?.none)
                ForEach(TimelineItemType.allCases, id: \ .self) { type in
                    Text(type.rawValue.capitalized).tag(Optional(type))
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            List(filteredTimeline) { item in
                TimelineItemCard(item: item)
            }
        }
        .navigationTitle("Goal Timeline")
    }
}

struct TimelineItemCard: View {
    let item: TimelineItem
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.title)
                .font(.headline)
            if let desc = item.description {
                Text(desc)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            HStack {
                Text(item.type.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(.blue)
                Spacer()
                Text(item.date, style: .date)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            if let progress = item.progressChange {
                ProgressView(value: progress)
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
} 