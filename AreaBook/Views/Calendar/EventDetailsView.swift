import SwiftUI

struct EventDetailsView: View {
    let event: CalendarEvent
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text(event.title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                if !event.description.isEmpty {
                    Text(event.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.secondary)
                    Text("\(event.startTime.formatted(date: .omitted, time: .shortened)) - \(event.endTime.formatted(date: .omitted, time: .shortened))")
                        .font(.subheadline)
                }
                
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.secondary)
                    Text(event.startTime.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                }
                
                HStack {
                    Image(systemName: "tag")
                        .foregroundColor(.secondary)
                    Text(event.category)
                        .font(.subheadline)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(colorForCategory(event.category).opacity(0.2))
                        .foregroundColor(colorForCategory(event.category))
                        .cornerRadius(6)
                }
                
                if event.isRecurring {
                    HStack {
                        Image(systemName: "repeat")
                            .foregroundColor(.secondary)
                        Text("Recurring Event")
                            .font(.subheadline)
                    }
                }
                
                if let goalId = event.linkedGoalId {
                    HStack {
                        Image(systemName: "target")
                            .foregroundColor(.secondary)
                        Text("Linked to Goal")
                            .font(.subheadline)
                    }
                }
                
                if !event.taskIds.isEmpty {
                    HStack {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(.secondary)
                        Text("\(event.taskIds.count) linked task\(event.taskIds.count == 1 ? "" : "s")")
                            .font(.subheadline)
                    }
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 12) {
                    Button(action: {
                        // Edit action - would need to implement navigation to edit view
                    }) {
                        HStack {
                            Image(systemName: "pencil")
                            Text("Edit Event")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        // Delete action - would need to implement deletion
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Event")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
            }
            .padding()
            .navigationTitle("Event Details")
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
    
    private func colorForCategory(_ category: String) -> Color {
        switch category {
        case "Church": return .blue
        case "Work": return .orange
        case "Personal": return .green
        case "Family": return .purple
        case "Health": return .red
        case "School": return .yellow
        default: return .gray
        }
    }
}

#Preview {
    EventDetailsView(event: CalendarEvent(
        title: "Sample Event",
        description: "This is a sample event description",
        category: "Personal",
        startTime: Date(),
        endTime: Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
    ))
}