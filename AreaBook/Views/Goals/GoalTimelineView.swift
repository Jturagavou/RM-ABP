import SwiftUI

struct GoalTimelineView: View {
    @EnvironmentObject var dataManager: DataManager
    let goalId: String
    @State private var selectedType: TimelineItemType? = nil
    @State private var showingCreateNote = false

    var goal: Goal? {
        dataManager.goals.first { $0.id == goalId }
    }
    
    var linkedNotes: [Note] {
        dataManager.getNotesForGoal(goalId)
    }
    
    var filteredTimeline: [TimelineItem] {
        let timeline = dataManager.getTimelineForGoal(goalId: goalId)
        if let type = selectedType {
            return timeline.filter { $0.type == type }
        }
        return timeline
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Goal Info Section
                if let goal = goal {
                    GoalInfoCard(goal: goal)
                }
                
                // Linked Notes Section
                if !linkedNotes.isEmpty {
                    LinkedNotesSection(notes: linkedNotes)
                }
                
                // Add Note Button
                Button(action: {
                    showingCreateNote = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Note to Goal")
                    }
                    .foregroundColor(.blue)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // Timeline Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Timeline")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Picker("Filter", selection: $selectedType) {
                        Text("All").tag(TimelineItemType?.none)
                        ForEach(TimelineItemType.allCases, id: \.self) { type in
                            Text(type.rawValue.capitalized).tag(Optional(type))
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    LazyVStack(spacing: 0) {
                        ForEach(Array(filteredTimeline.enumerated()), id: \.element.id) { index, item in
                            TimelineItemCard(item: item, isExpanded: false)
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                            
                            // Add connecting line if not the last item
                            if index < filteredTimeline.count - 1 {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 2, height: 20)
                                    .padding(.leading, 25) // Align with the timeline item
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Goal Timeline")
        .sheet(isPresented: $showingCreateNote) {
            CreateNoteView(defaultGoalId: goalId)
                .environmentObject(dataManager)
        }
    }
}

struct TimelineItemCard: View {
    let item: TimelineItem
    @State private var isExpanded: Bool
    
    init(item: TimelineItem, isExpanded: Bool = false) {
        self.item = item
        self._isExpanded = State(initialValue: isExpanded)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with expand/collapse
            HStack {
                // Timeline dot
                Circle()
                    .fill(timelineItemColor)
                    .frame(width: 12, height: 12)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack {
                        Text(item.type.rawValue.capitalized)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(timelineItemColor.opacity(0.2))
                            .foregroundColor(timelineItemColor)
                            .cornerRadius(4)
                        
                        Spacer()
                        
                        Text(item.date, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.blue)
                        .font(.caption)
                }
            }
            
            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    if let desc = item.description, !desc.isEmpty {
                        Text(desc)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.leading, 16)
                    }
                    
                    if let progress = item.progressChange {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Progress Contribution: \(String(format: "%.1f", progress))")
                                .font(.caption)
                                .foregroundColor(.blue)
                            
                            ProgressView(value: min(max(progress, 0), 1.0))
                                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        }
                        .padding(.leading, 16)
                    }
                    
                    // Additional details based on type
                    switch item.type {
                    case .task:
                        if let taskId = item.relatedTaskId {
                            Text("Task ID: \(taskId)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .padding(.leading, 16)
                        }
                    case .event:
                        if let eventId = item.relatedEventId {
                            Text("Event ID: \(eventId)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .padding(.leading, 16)
                        }
                    case .goal, .note, .progressUpdate, .keyIndicator, .other:
                        EmptyView()
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.3)) {
                isExpanded.toggle()
            }
        }
    }
    
    private var timelineItemColor: Color {
        switch item.type {
        case .goal: return .blue
        case .task: return .green
        case .event: return .orange
        case .note: return .purple
        case .progressUpdate: return .cyan
        case .keyIndicator: return .indigo
        case .other: return .gray
        }
    }
}

struct GoalInfoCard: View {
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
            
            ProgressView(value: Double(goal.calculatedProgress) / 100.0)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            
            HStack {
                if let targetDate = goal.targetDate {
                    Label("Due: \(targetDate, style: .date)", systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(goal.status.rawValue.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor(for: goal.status).opacity(0.2))
                    .foregroundColor(statusColor(for: goal.status))
                    .cornerRadius(6)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
        .contextMenu {
            NavigationLink("View Analytics") {
                GoalAnalyticsView(goal: goal)
            }
        }
    }
    
    private func statusColor(for status: GoalStatus) -> Color {
        switch status {
        case .active: return .blue
        case .completed: return .green
        case .paused: return .orange
        case .cancelled: return .red
        }
    }
}

struct LinkedNotesSection: View {
    let notes: [Note]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Linked Notes (\(notes.count))", systemImage: "doc.text")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)
            
            LazyVStack(spacing: 8) {
                ForEach(notes) { note in
                    LinkedNoteCard(note: note)
                        .padding(.horizontal)
                }
            }
        }
    }
}

struct LinkedNoteCard: View {
    let note: Note
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(note.title.isEmpty ? "Untitled Note" : note.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                Spacer()
                
                Text(note.updatedAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if !note.content.isEmpty {
                Text(note.content)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            
            if !note.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(note.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(6)
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
} 