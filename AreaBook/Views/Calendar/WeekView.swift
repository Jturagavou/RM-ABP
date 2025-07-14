import SwiftUI

struct WeekView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var currentWeek: Date = Date()
    @State private var weekOffset: Int = 0
    @State private var currentTime: Date = Date()
    @State private var showingEventCreation = false
    @State private var selectedTimeSlot: Date?
    @State private var selectedEvent: CalendarEvent?
    @State private var showingEventDetails = false
    
    private let hourHeight: CGFloat = 40
    private let dayWidth: CGFloat = 100
    private let hours = Array(0...23)
    
    private var weekDays: [Date] {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: currentWeek)?.start ?? currentWeek
        return (0...6).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)
        }
    }
    
    private var weekDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with navigation
            headerView
            
            // Week days header
            weekDaysHeader
            
            // Week grid with events
            weekGridView
        }
        .navigationTitle(weekDateFormatter.string(from: currentWeek))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
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
            Button(action: { goToPreviousWeek() }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Button("Today") {
                currentWeek = Date()
                weekOffset = 0
            }
            .font(.headline)
            .foregroundColor(.blue)
            
            Spacer()
            
            Button(action: { goToNextWeek() }) {
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
    
    private var weekDaysHeader: some View {
        HStack(spacing: 0) {
            // Time column spacer
            Spacer()
                .frame(width: 50)
            
            // Day headers
            ForEach(weekDays, id: \.self) { day in
                VStack(spacing: 4) {
                    Text(day.formatted(.dateTime.weekday(.abbreviated)))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(day.formatted(.dateTime.day()))
                        .font(.title3)
                        .fontWeight(Calendar.current.isDateInToday(day) ? .bold : .medium)
                        .foregroundColor(Calendar.current.isDateInToday(day) ? .white : .primary)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(Calendar.current.isDateInToday(day) ? Color.blue : Color.clear)
                        )
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .fill(Color(.systemGray5))
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    private var weekGridView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(hours, id: \.self) { hour in
                    WeekHourSlot(
                        hour: hour,
                        weekDays: weekDays,
                        events: eventsForWeek,
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
        .coordinateSpace(name: "weekScroll")
    }
    
    private var eventsForWeek: [CalendarEvent] {
        dataManager.events.filter { event in
            weekDays.contains { day in
                Calendar.current.isDate(event.startTime, inSameDayAs: day)
            }
        }
        .sorted { $0.startTime < $1.startTime }
    }
    
    private func goToPreviousWeek() {
        currentWeek = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: currentWeek) ?? currentWeek
        weekOffset -= 1
    }
    
    private func goToNextWeek() {
        currentWeek = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: currentWeek) ?? currentWeek
        weekOffset += 1
    }
    
    private func startCurrentTimeTimer() {
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            currentTime = Date()
        }
    }
}

struct WeekHourSlot: View {
    let hour: Int
    let weekDays: [Date]
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
        HStack(spacing: 0) {
            // Time label
            VStack {
                if hour != 0 {
                    Text(timeFormatter.string(from: hourDate(for: weekDays[0])))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .frame(width: 50)
            .padding(.top, -8)
            
            // Day columns
            ForEach(weekDays, id: \.self) { day in
                WeekDayColumn(
                    day: day,
                    hour: hour,
                    events: eventsForDay(day),
                    currentTime: currentTime,
                    onTimeSlotTapped: onTimeSlotTapped,
                    onEventTapped: onEventTapped
                )
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    private func hourDate(for day: Date) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: day) ?? day
    }
    
    private func eventsForDay(_ day: Date) -> [CalendarEvent] {
        events.filter { event in
            Calendar.current.isDate(event.startTime, inSameDayAs: day)
        }
    }
}

struct WeekDayColumn: View {
    let day: Date
    let hour: Int
    let events: [CalendarEvent]
    let currentTime: Date
    let onTimeSlotTapped: (Date) -> Void
    let onEventTapped: (CalendarEvent) -> Void
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                // Background
                Rectangle()
                    .fill(isWeekend ? Color(.systemGray6) : Color.clear)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onTimeSlotTapped(hourDate)
                    }
                
                // Hour divider
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(height: 0.5)
                    .frame(maxWidth: .infinity)
                
                // Vertical day divider
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(width: 0.5)
                    .frame(maxHeight: .infinity)
                    .offset(x: geometry.size.width - 0.5)
                
                // Events for this hour
                ForEach(eventsForHour) { event in
                    WeekEventBlock(
                        event: event,
                        geometry: geometry,
                        hourHeight: 40
                    )
                    .onTapGesture {
                        onEventTapped(event)
                    }
                }
                
                // Current time indicator
                if shouldShowCurrentTimeIndicator {
                    WeekCurrentTimeIndicator(currentTime: currentTime)
                }
            }
        }
    }
    
    private var hourDate: Date {
        Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: day) ?? day
    }
    
    private var isWeekend: Bool {
        let weekday = Calendar.current.component(.weekday, from: day)
        return weekday == 1 || weekday == 7 // Sunday or Saturday
    }
    
    private var eventsForHour: [CalendarEvent] {
        events.filter { event in
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
    
    private var shouldShowCurrentTimeIndicator: Bool {
        Calendar.current.isDate(currentTime, inSameDayAs: day) &&
        Calendar.current.component(.hour, from: currentTime) == hour
    }
}

struct WeekEventBlock: View {
    let event: CalendarEvent
    let geometry: GeometryProxy
    let hourHeight: CGFloat
    
    var body: some View {
        let startMinute = Calendar.current.component(.minute, from: event.startTime)
        let duration = event.endTime.timeIntervalSince(event.startTime)
        let height = min(CGFloat(duration / 3600) * hourHeight, hourHeight - CGFloat(startMinute) * hourHeight / 60)
        let yOffset = CGFloat(startMinute) * hourHeight / 60
        
        HStack(spacing: 2) {
            Rectangle()
                .fill(colorForCategory(event.category))
                .frame(width: 3)
                .cornerRadius(1.5)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(event.title)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                if height > 20 {
                    Text(event.startTime.formatted(date: .omitted, time: .shortened))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 1)
        .frame(width: geometry.size.width - 4, height: height, alignment: .topLeading)
        .background(colorForCategory(event.category).opacity(0.1))
        .cornerRadius(3)
        .offset(x: 2, y: yOffset)
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

struct WeekCurrentTimeIndicator: View {
    let currentTime: Date
    
    var body: some View {
        let minute = Calendar.current.component(.minute, from: currentTime)
        let yOffset = CGFloat(minute) * 40 / 60
        
        Rectangle()
            .fill(Color.red)
            .frame(height: 1)
            .frame(maxWidth: .infinity)
            .offset(y: yOffset)
    }
}

#Preview {
    WeekView()
        .environmentObject(DataManager.shared)
        .environmentObject(AuthViewModel())
}