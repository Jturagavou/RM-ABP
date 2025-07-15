import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedDate = Date()
    @State private var showingCreateEvent = false
    @State private var dragStartDate: Date?
    @State private var dragEndDate: Date?
    @State private var isDragging = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Calendar Widget with Drag Gesture
                ZStack {
                    DatePicker("Select Date", selection: $selectedDate, displayedComponents: [.date])
                        .datePickerStyle(GraphicalDatePickerStyle())
                        .padding()
                        .overlay(
                            // Invisible overlay for drag detection
                            Rectangle()
                                .fill(Color.clear)
                                .contentShape(Rectangle())
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { value in
                                            if !isDragging {
                                                isDragging = true
                                                dragStartDate = selectedDate
                                                
                                                // Haptic feedback
                                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                                impactFeedback.impactOccurred()
                                            }
                                        }
                                        .onEnded { value in
                                            if isDragging {
                                                isDragging = false
                                                dragEndDate = selectedDate
                                                
                                                // Show event creation with drag dates
                                                if let startDate = dragStartDate {
                                                    selectedDate = startDate
                                                    showingCreateEvent = true
                                                }
                                                
                                                dragStartDate = nil
                                                dragEndDate = nil
                                            }
                                        }
                                )
                        )
                    
                    // Visual feedback during drag
                    if isDragging {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                VStack(spacing: 8) {
                                    Image(systemName: "calendar.badge.plus")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                    Text("Release to create event")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(12)
                                .shadow(radius: 4)
                                Spacer()
                            }
                            Spacer()
                        }
                        .transition(.opacity.combined(with: .scale))
                        .animation(.easeInOut(duration: 0.2), value: isDragging)
                    }
                }
                
                // Events for selected date
                ScrollView {
                    LazyVStack(spacing: 12) {
                        let eventsForDate = eventsForSelectedDate
                        
                        if eventsForDate.isEmpty {
                            EmptyCalendarView(selectedDate: selectedDate) {
                                showingCreateEvent = true
                            }
                        } else {
                            ForEach(eventsForDate) { event in
                                EventCard(event: event)
                            }
                        }
                        
                        // Bottom padding for floating button
                        Spacer()
                            .frame(height: 100)
                    }
                    .padding(.horizontal)
                    .padding(.top, 5)
                }
            }
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingCreateEvent) {
                CreateEventView(prefilledDate: selectedDate)
            }
        }
    }
    
    private var eventsForSelectedDate: [CalendarEvent] {
        dataManager.events.filter { event in
            Calendar.current.isDate(event.startTime, inSameDayAs: selectedDate)
        }
        .sorted { $0.startTime < $1.startTime }
    }
}

struct EmptyCalendarView: View {
    let selectedDate: Date
    let onCreateEvent: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Events")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("No events scheduled for \(selectedDate, style: .date)")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Create Event") {
                onCreateEvent()
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 10)
        }
        .padding(.top, 50)
    }
}

struct EventCard: View {
    let event: CalendarEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if !event.description.isEmpty {
                        Text(event.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(event.category)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(categoryColor(for: event.category).opacity(0.2))
                        .foregroundColor(categoryColor(for: event.category))
                        .cornerRadius(6)
                    
                    Text(event.status.rawValue.capitalized)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.blue)
                    .font(.caption)
                
                Text("\(event.startTime, style: .time) - \(event.endTime, style: .time)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if event.isRecurring {
                    Image(systemName: "repeat")
                        .foregroundColor(.orange)
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private func categoryColor(for category: String) -> Color {
        switch category.lowercased() {
        case "personal": return .blue
        case "work": return .orange
        case "health": return .green
        case "family": return .purple
        case "church": return .indigo
        case "school": return .teal
        default: return .gray
        }
    }
}

#Preview {
    CalendarView()
        .environmentObject(DataManager.shared)
        .environmentObject(AuthViewModel())
}