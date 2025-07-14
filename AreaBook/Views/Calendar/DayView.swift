import SwiftUI

struct DayView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedDate: Date = Date()
    @State private var currentTime: Date = Date()
    @State private var scrollOffset: CGFloat = 0
    @State private var showingEventCreation = false
    @State private var selectedTimeSlot: Date?
    @State private var selectedEvent: CalendarEvent?
    @State private var showingEventDetails = false
    
    private let hourHeight: CGFloat = 60
    private let hours = Array(0...23)
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with navigation
            headerView
            
            // All-day events section
            allDayEventsSection
            
            // Time grid with events
            timeGridView
        }
        .navigationTitle(selectedDate.formatted(date: .abbreviated, time: .omitted))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            scrollToCurrentTime()
            startCurrentTimeTimer()
        }
        .sheet(isPresented: $showingEventCreation) {
            CreateEventView(prefilledDate: selectedTimeSlot)
        }
        .sheet(isPresented: $showingEventDetails) {
            if let event = selectedEvent {
                EventDetailsView(event: event)
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            Button(action: { goToPreviousDay() }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Button("Today") {
                selectedDate = Date()
                scrollToCurrentTime()
            }
            .font(.headline)
            .foregroundColor(.blue)
            
            Spacer()
            
            Button(action: { goToNextDay() }) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(.primary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .fill(Color(.systemGray5))
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    private var allDayEventsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !allDayEvents.isEmpty {
                HStack {
                    Text("All Day")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 50, alignment: .leading)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(allDayEvents) { event in
                            AllDayEventCard(event: event)
                                .onTapGesture {
                                    selectedEvent = event
                                    showingEventDetails = true
                                }
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(height: 1)
            }
        }
    }
    
    private var timeGridView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(hours, id: \.self) { hour in
                    HourSlot(
                        hour: hour,
                        selectedDate: selectedDate,
                        events: eventsForHour(hour),
                        currentTime: currentTime,
                        onTimeSlotTapped: { date in
                            selectedTimeSlot = date
                            showingEventCreation = true
                        },
                        onEventTapped: { event in
                            selectedEvent = event
                            showingEventDetails = true
                        }
                    )
                    .frame(height: hourHeight)
                }
            }
        }
        .coordinateSpace(name: "scroll")
    }
    
    private var allDayEvents: [CalendarEvent] {
        eventsForSelectedDate.filter { event in
            Calendar.current.dateInterval(of: .day, for: event.startTime)?.contains(event.endTime) == false ||
            Calendar.current.component(.hour, from: event.startTime) == 0 &&
            Calendar.current.component(.minute, from: event.startTime) == 0 &&
            Calendar.current.component(.hour, from: event.endTime) == 23 &&
            Calendar.current.component(.minute, from: event.endTime) == 59
        }
    }
    
    private var eventsForSelectedDate: [CalendarEvent] {
        dataManager.events.filter { event in
            Calendar.current.isDate(event.startTime, inSameDayAs: selectedDate)
        }
        .sorted { $0.startTime < $1.startTime }
    }
    
    private func eventsForHour(_ hour: Int) -> [CalendarEvent] {
        eventsForSelectedDate.filter { event in
            let eventHour = Calendar.current.component(.hour, from: event.startTime)
            let eventEndHour = Calendar.current.component(.hour, from: event.endTime)
            return eventHour <= hour && eventEndHour >= hour && !isAllDayEvent(event)
        }
    }
    
    private func isAllDayEvent(_ event: CalendarEvent) -> Bool {
        let startComponents = Calendar.current.dateComponents([.hour, .minute], from: event.startTime)
        let endComponents = Calendar.current.dateComponents([.hour, .minute], from: event.endTime)
        
        return startComponents.hour == 0 && startComponents.minute == 0 &&
               endComponents.hour == 23 && endComponents.minute == 59
    }
    
    private func goToPreviousDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
    }
    
    private func goToNextDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
    }
    
    private func scrollToCurrentTime() {
        // Scroll to current time logic would go here
        // This is a simplified version
    }
    
    private func startCurrentTimeTimer() {
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            currentTime = Date()
        }
    }
}

struct HourSlot: View {
    let hour: Int
    let selectedDate: Date
    let events: [CalendarEvent]
    let currentTime: Date
    let onTimeSlotTapped: (Date) -> Void
    let onEventTapped: (CalendarEvent) -> Void
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        return formatter
    }()
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Time label
                VStack {
                    if hour != 0 {
                        Text(timeFormatter.string(from: hourDate))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .frame(width: 50)
                .padding(.top, -8)
                
                // Time slot area
                ZStack(alignment: .topLeading) {
                    // Background and divider
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onTimeSlotTapped(hourDate)
                        }
                    
                    // Hour divider
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 1)
                        .frame(maxWidth: .infinity)
                    
                    // Events in this hour
                    ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                        EventBlock(
                            event: event,
                            geometry: geometry,
                            hourHeight: 60,
                            overlappingEvents: events.count,
                            eventIndex: index
                        )
                        .onTapGesture {
                            onEventTapped(event)
                        }
                    }
                    
                    // Current time indicator
                    if shouldShowCurrentTimeIndicator {
                        CurrentTimeIndicator(currentTime: currentTime, hour: hour)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    private var hourDate: Date {
        Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: selectedDate) ?? selectedDate
    }
    
    private var shouldShowCurrentTimeIndicator: Bool {
        Calendar.current.isDate(currentTime, inSameDayAs: selectedDate) &&
        Calendar.current.component(.hour, from: currentTime) == hour
    }
}

struct EventBlock: View {
    let event: CalendarEvent
    let geometry: GeometryProxy
    let hourHeight: CGFloat
    let overlappingEvents: Int
    let eventIndex: Int
    
    var body: some View {
        let startMinute = Calendar.current.component(.minute, from: event.startTime)
        let duration = event.endTime.timeIntervalSince(event.startTime)
        let height = min(CGFloat(duration / 3600) * hourHeight, hourHeight - CGFloat(startMinute) * hourHeight / 60)
        let yOffset = CGFloat(startMinute) * hourHeight / 60
        let width = overlappingEvents > 1 ? (geometry.size.width - 50) / CGFloat(overlappingEvents) : geometry.size.width - 50
        let xOffset = CGFloat(eventIndex) * width
        
        VStack(alignment: .leading, spacing: 2) {
            Text(event.title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .lineLimit(1)
            
            if height > 30 {
                Text(event.startTime.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.9))
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .frame(width: width, height: height, alignment: .topLeading)
        .background(colorForCategory(event.category))
        .cornerRadius(4)
        .offset(x: xOffset, y: yOffset)
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

struct CurrentTimeIndicator: View {
    let currentTime: Date
    let hour: Int
    
    var body: some View {
        let minute = Calendar.current.component(.minute, from: currentTime)
        let yOffset = CGFloat(minute) * 60 / 60
        
        HStack(spacing: 0) {
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
                .offset(x: -4)
            
            Rectangle()
                .fill(Color.red)
                .frame(height: 1)
                .frame(maxWidth: .infinity)
        }
        .offset(y: yOffset)
    }
}

struct AllDayEventCard: View {
    let event: CalendarEvent
    
    var body: some View {
        HStack {
            Rectangle()
                .fill(colorForCategory(event.category))
                .frame(width: 4)
                .cornerRadius(2)
            
            Text(event.title)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray6))
        .cornerRadius(6)
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
    DayView()
        .environmentObject(DataManager.shared)
        .environmentObject(AuthViewModel())
}