import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedDate = Date()
    @State private var showingCreateEvent = false
    @State private var selectedEvent: CalendarEvent?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Calendar Widget
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: [.date])
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding()
                    .background(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                
                // Events for selected date
                ScrollView {
                    LazyVStack(spacing: 12) {
                        let eventsForDate = getEventsForDate(selectedDate)
                        
                        if eventsForDate.isEmpty {
                            EmptyStateView()
                        } else {
                            ForEach(eventsForDate) { event in
                                EventCard(event: event)
                                    .onTapGesture {
                                        selectedEvent = event
                                    }
                            }
                        }
                    }
                    .padding()
                }
                .refreshable {
                    // Refresh events if needed
                    if let userId = authViewModel.currentUser?.id {
                        dataManager.setupListeners(for: userId, userName: authViewModel.currentUser?.name)
                    }
                }
            }
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateEvent = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateEvent) {
                CreateEventView()
            }
            .sheet(item: $selectedEvent) { event in
                EventDetailView(event: event)
            }
        }
    }
    
    // Get events for a specific date including recurring events
    private func getEventsForDate(_ date: Date) -> [CalendarEvent] {
        var eventsForDate: [CalendarEvent] = []
        
        for event in dataManager.events {
            if event.isRecurring, let pattern = event.recurrencePattern {
                // Check if recurring event occurs on this date
                if CalendarHelper.isRecurringEventOccursOnDate(event: event, pattern: pattern, date: date) {
                    // Create a virtual occurrence for this date
                    var occurrence = event
                    occurrence.startTime = CalendarHelper.combineDateWithTime(date: date, time: event.startTime)
                    occurrence.endTime = CalendarHelper.combineDateWithTime(date: date, time: event.endTime)
                    eventsForDate.append(occurrence)
                }
            } else {
                // Regular event - check if it's on this date
                if Calendar.current.isDate(event.startTime, inSameDayAs: date) {
                    eventsForDate.append(event)
                }
            }
        }
        
        return eventsForDate.sorted { $0.startTime < $1.startTime }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Events")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("No events scheduled for this date")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 50)
    }
}

struct EventCard: View {
    let event: CalendarEvent
    
    var body: some View {
        HStack(spacing: 12) {
            // Time Column
            VStack(spacing: 2) {
                Text(event.startTime, style: .time)
                    .font(.caption)
                    .fontWeight(.medium)
                Text("-")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(event.endTime, style: .time)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(width: 60)
            
            // Color Indicator
            Rectangle()
                .fill(categoryColor(for: event.category))
                .frame(width: 4)
                .cornerRadius(2)
            
            // Event Details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(event.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if event.isRecurring {
                        Image(systemName: "repeat")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if !event.description.isEmpty {
                    Text(event.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    Text(event.category)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(categoryColor(for: event.category).opacity(0.2))
                        .foregroundColor(categoryColor(for: event.category))
                        .cornerRadius(6)
                    
                    if event.linkedGoalId != nil {
                        Image(systemName: "flag.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    
                    if !event.taskIds.isEmpty {
                        Image(systemName: "checkmark.square.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            
            Spacer()
            
            // Status indicator
            if event.status == .completed {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private func categoryColor(for category: String) -> Color {
        switch category.lowercased() {
        case "work": return .blue
        case "personal": return .purple
        case "health": return .green
        case "social": return .orange
        case "learning": return .indigo
        default: return .gray
        }
    }
}



#Preview {
    CalendarView()
        .environmentObject(DataManager.shared)
        .environmentObject(AuthViewModel())
}