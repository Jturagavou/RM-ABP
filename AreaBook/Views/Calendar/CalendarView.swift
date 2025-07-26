import SwiftUI
import UIKit

// MARK: - Gesture State Management
enum CalendarGestureState {
    case idle
    case longPressing
    case editing
}

class CalendarGestureCoordinator: ObservableObject {
    @Published var currentState: CalendarGestureState = .idle
    @Published var activeGestureId: UUID?
    
    func requestGestureStart(_ gestureType: CalendarGestureState, id: UUID = UUID()) -> Bool {
        switch (currentState, gestureType) {
        case (.idle, _):
            currentState = gestureType
            activeGestureId = id
            return true
        case (.longPressing, .editing):
            currentState = gestureType
            activeGestureId = id
            return true
        default:
            return false
        }
    }
    
    func endGesture(_ id: UUID, returnTo: CalendarGestureState = .idle) {
        guard activeGestureId == id else { return }
        currentState = returnTo
        activeGestureId = nil
    }
}

struct CalendarView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var gestureCoordinator = CalendarGestureCoordinator()
    @State private var selectedDate = Date()
    @State private var showingCreateEvent = false
    @State private var newEventStart = Date()
    @State private var newEventEnd = Date().addingTimeInterval(3600)
    @State private var calendarViewMode: CalendarViewMode = .month
    @State private var editingEvent: CalendarEvent?
    @State private var lastScaleValue: CGFloat = 1.0
    @State private var currentScale: CGFloat = 1.0
    
    enum CalendarViewMode: String, CaseIterable {
        case day = "Day"
        case week = "Week"
        case month = "Month"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // View Mode Picker
                Picker("View Mode", selection: $calendarViewMode) {
                    ForEach(CalendarViewMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Calendar Content with Pinch Zoom
                Group {
                    switch calendarViewMode {
                    case .day:
                        DayView(selectedDate: $selectedDate, events: eventsForSelectedDate, gestureCoordinator: gestureCoordinator)
                    case .week:
                        WeekView(selectedDate: $selectedDate, events: eventsForWeek, gestureCoordinator: gestureCoordinator)
                    case .month:
                        MonthView(selectedDate: $selectedDate, events: eventsForSelectedDate, gestureCoordinator: gestureCoordinator)
                    }
                }
                .background(Color.clear) // Ensure gesture area is defined
                .simultaneousGesture(
                    MagnificationGesture()
                        .onChanged { value in
                            currentScale = value
                        }
                        .onEnded { value in
                            withAnimation(.easeInOut(duration: 0.3)) {
                                handlePinchZoom(scale: value)
                            }
                            currentScale = 1.0
                            lastScaleValue = 1.0
                        }
                )
            }
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingCreateEvent) {
                CreateEventView(
                    eventToEdit: editingEvent,
                    defaultStart: newEventStart,
                    defaultEnd: newEventEnd
                )
                .environmentObject(dataManager)
                .environmentObject(authViewModel)
            }
        }
    }
    
    private func handlePinchZoom(scale: CGFloat) {
        // Pinch out (zoom in) - go to more detailed view
        if scale > 1.5 {
            switch calendarViewMode {
            case .month:
                calendarViewMode = .week
            case .week:
                calendarViewMode = .day
            case .day:
                break // Already at most detailed view
            }
        }
        // Pinch in (zoom out) - go to less detailed view
        else if scale < 0.75 {
            switch calendarViewMode {
            case .day:
                calendarViewMode = .week
            case .week:
                calendarViewMode = .month
            case .month:
                break // Already at least detailed view
            }
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private var eventsForSelectedDate: [CalendarEvent] {
        dataManager.events.filter { event in
            Calendar.current.isDate(event.startTime, inSameDayAs: selectedDate)
        }
        .sorted { $0.startTime < $1.startTime }
    }
    
    private var eventsForWeek: [CalendarEvent] {
        let calendar = Calendar.current
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
        let weekEnd = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.end ?? selectedDate
        
        return dataManager.events.filter { event in
            event.startTime >= weekStart && event.startTime < weekEnd
        }
        .sorted { $0.startTime < $1.startTime }
    }
}

struct EventCard: View {
    let event: CalendarEvent
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    @State private var isExpanded = false
    @State private var showingEditEvent = false
    @State private var isLongPressing = false
    
    var body: some View {
        // Main event card (always visible)
        HStack(spacing: 12) {
            // Completion Toggle
            Button(action: toggleEventCompletion) {
                Image(systemName: event.status == .completed ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(event.status == .completed ? .green : .gray)
                    .font(.title3)
            }
            
            VStack {
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
            
            Rectangle()
                .fill(event.status == .completed ? Color.green : Color.blue)
                .frame(width: 4)
                .cornerRadius(2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .strikethrough(event.status == .completed)
                    .foregroundColor(event.status == .completed ? .secondary : .primary)
                
                if !event.description.isEmpty {
                    Text(event.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(colorThemeManager.getCategoryColor(for: event.category))
                            .frame(width: 8, height: 8)
                        Text(event.category)
                            .font(.caption)
                            .foregroundColor(colorThemeManager.getCategoryColor(for: event.category))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(colorThemeManager.getCategoryColor(for: event.category).opacity(0.2))
                    .cornerRadius(6)
                    
                    if event.status == .completed {
                        Text("Completed")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(6)
                    }
                }
            }
            
            Spacer()
            
            // Tap to expand
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                Image(systemName: "chevron.right")
                    .foregroundColor(.blue)
                    .font(.caption)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .scaleEffect(isLongPressing ? 1.02 : 1.0)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isLongPressing ? Color.orange : Color.clear, lineWidth: 3)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isLongPressing ? Color.orange.opacity(0.1) : Color.clear)
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isLongPressing)
        .onLongPressGesture(minimumDuration: 0.6, maximumDistance: 40) {
            print("🎯 Event long press SUCCESS - entering edit mode")
            
            // Enhanced haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            // Enter editing mode
            showingEditEvent = true
            
        } onPressingChanged: { pressing in
            if pressing {
                // Start visual feedback immediately
                withAnimation(.easeIn(duration: 0.2)) {
                    isLongPressing = true
                }
                
                // Gentle vibration on press start
                let selectionFeedback = UISelectionFeedbackGenerator()
                selectionFeedback.selectionChanged()
                
            } else {
                // End visual feedback immediately
                withAnimation(.easeOut(duration: 0.2)) {
                    isLongPressing = false
                }
            }
        }
        .sheet(isPresented: $isExpanded) {
            EventDetailView(event: event)
                .environmentObject(dataManager)
                .environmentObject(authViewModel)
        }
        .sheet(isPresented: $showingEditEvent) {
            CreateEventView(
                eventToEdit: event,
                defaultStart: event.startTime,
                defaultEnd: event.endTime
            )
        }
    }
    
    private func toggleEventCompletion() {
        guard let userId = authViewModel.currentUser?.id else { return }
        
        var updatedEvent = event
        updatedEvent.status = event.status == .completed ? .scheduled : .completed
        
        dataManager.updateEvent(updatedEvent, userId: userId)
    }
}

struct DetailRow: View {
    let title: String
    var value: String? = nil
    var date: Date? = nil
    
    init(title: String, value: String) {
        self.title = title
        self.value = value
        self.date = nil
    }
    
    init(title: String, date: Date) {
        self.title = title
        self.value = nil
        self.date = date
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)
            
            if let date = date {
                HStack(spacing: 4) {
                    Text(date, style: .date)
                    Text(date, style: .time)
                }
                .font(.subheadline)
                .foregroundColor(.primary)
            } else if let value = value {
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            Spacer()
        }
    }
}

// MARK: - Calendar View Components

// MARK: - Day View with Enhanced Long Press
struct DayView: View {
    @Binding var selectedDate: Date
    let events: [CalendarEvent]
    @ObservedObject var gestureCoordinator: CalendarGestureCoordinator
    @State private var showingCreateEvent = false
    @State private var newEventStart = Date()
    @State private var newEventEnd = Date().addingTimeInterval(3600)
    
    // Drag gesture states
    @State private var isDragging = false
    @State private var dragStartHour: Int?
    @State private var dragEndHour: Int?
    @State private var dragStartY: CGFloat = 0
    @State private var currentDragY: CGFloat = 0
    
    private let hourHeight: CGFloat = 60
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Day Header
                HStack {
                    Text(selectedDate, style: .date)
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                    Button("Today") {
                        selectedDate = Date()
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)
                
                // Time Slots Container
                ZStack(alignment: .topLeading) {
                    // Time slots
                    LazyVStack(spacing: 8) {
                        ForEach(0..<24, id: \.self) { hour in
                            DayTimeSlot(
                                hour: hour,
                                date: selectedDate,
                                events: eventsForHour(hour),
                                isHighlighted: isDragging && isHourInDragRange(hour)
                            )
                            .frame(height: hourHeight)
                        }
                    }
                    .padding(.leading, 62) // Account for time label width
                    
                    // Temporary event block during drag
                    if isDragging, let startHour = dragStartHour, let endHour = dragEndHour {
                        let minHour = min(startHour, endHour)
                        let maxHour = max(startHour, endHour)
                        let yOffset = CGFloat(minHour) * (hourHeight + 8)
                        let height = CGFloat(maxHour - minHour + 1) * (hourHeight + 8) - 8
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.blue, lineWidth: 2)
                                    .overlay(
                                        VStack {
                                            Text("New Event")
                                                .font(.headline)
                                                .fontWeight(.semibold)
                                            Text("\(minHour):00 - \(maxHour + 1):00")
                                                .font(.subheadline)
                                        }
                                        .foregroundColor(.blue)
                                    )
                            )
                            .frame(height: height)
                            .offset(x: 62, y: yOffset)
                            .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
                            .allowsHitTesting(false)
                            .animation(.easeInOut(duration: 0.2), value: height)
                    }
                }
                .padding(.horizontal)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 10)
                        .onChanged { value in
                            handleDragChanged(value)
                        }
                        .onEnded { value in
                            handleDragEnded(value)
                        }
                )
            }
            .padding(.vertical)
        }
        .sheet(isPresented: $showingCreateEvent) {
            CreateEventView(
                eventToEdit: nil,
                defaultStart: newEventStart,
                defaultEnd: newEventEnd
            )
        }
    }
    
    private func handleDragChanged(_ value: DragGesture.Value) {
        let hour = Int(value.location.y / (hourHeight + 8))
        let clampedHour = max(0, min(23, hour))
        
        if !isDragging {
            // Check if drag is long enough to start
            let dragDistance = abs(value.translation.height)
            if dragDistance > 5 {
                // Start drag
                isDragging = true
                dragStartHour = clampedHour
                dragEndHour = clampedHour
                dragStartY = value.startLocation.y
                
                // Haptic feedback
                let selectionFeedback = UISelectionFeedbackGenerator()
                selectionFeedback.selectionChanged()
            }
        } else {
            // Update drag
            let prevEndHour = dragEndHour
            dragEndHour = clampedHour
            currentDragY = value.location.y
            
            // Light haptic when crossing hour boundaries
            if let prevEnd = prevEndHour, prevEnd != clampedHour {
                let selectionFeedback = UISelectionFeedbackGenerator()
                selectionFeedback.selectionChanged()
            }
        }
    }
    
    private func handleDragEnded(_ value: DragGesture.Value) {
        guard isDragging, let startHour = dragStartHour, let endHour = dragEndHour else {
            isDragging = false
            return
        }
        
        let minHour = min(startHour, endHour)
        let maxHour = max(startHour, endHour)
        
        // Create event
        let calendar = Calendar.current
        let baseDate = calendar.startOfDay(for: selectedDate)
        newEventStart = calendar.date(bySettingHour: minHour, minute: 0, second: 0, of: baseDate) ?? selectedDate
        newEventEnd = calendar.date(bySettingHour: maxHour + 1, minute: 0, second: 0, of: baseDate) ?? selectedDate
        
        // Strong haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Reset drag state
        isDragging = false
        dragStartHour = nil
        dragEndHour = nil
        
        // Show create event sheet
        showingCreateEvent = true
    }
    
    private func isHourInDragRange(_ hour: Int) -> Bool {
        guard let startHour = dragStartHour, let endHour = dragEndHour else {
            return false
        }
        let minHour = min(startHour, endHour)
        let maxHour = max(startHour, endHour)
        return hour >= minHour && hour <= maxHour
    }
    
    private func eventsForHour(_ hour: Int) -> [CalendarEvent] {
        let calendar = Calendar.current
        let baseDate = calendar.startOfDay(for: selectedDate)
        let hourStart = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: baseDate) ?? selectedDate
        let hourEnd = calendar.date(bySettingHour: hour + 1, minute: 0, second: 0, of: baseDate) ?? selectedDate.addingTimeInterval(3600)
        
        return events.filter { event in
            event.startTime >= hourStart && event.startTime < hourEnd
        }
    }
}

// MARK: - Day Time Slot (Simplified)
struct DayTimeSlot: View {
    let hour: Int
    let date: Date
    let events: [CalendarEvent]
    let isHighlighted: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Time Label
            Text("\(hour):00")
                .font(.caption)
                .fontWeight(.medium)
                .frame(width: 50, alignment: .trailing)
            
            // Time Slot Content
            VStack(spacing: 4) {
                if events.isEmpty {
                    // Empty slot
                    Rectangle()
                        .fill(Color.clear)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .overlay(
                            Rectangle()
                                .fill(isHighlighted ? Color.blue.opacity(0.1) : Color.clear)
                        )
                } else {
                    // Events in this time slot
                    ForEach(events) { event in
                        EventCard(event: event)
                    }
                }
            }
        }
    }
}

struct WeekView: View {
    @Binding var selectedDate: Date
    let events: [CalendarEvent]
    @ObservedObject var gestureCoordinator: CalendarGestureCoordinator
    @State private var showingCreateEvent = false
    @State private var newEventStart = Date()
    @State private var newEventEnd = Date().addingTimeInterval(3600)
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Week Header
                HStack {
                    Text("Week of \(weekStartDate, style: .date)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                    Button("This Week") {
                        selectedDate = Date()
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)
                
                // Week Grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                    ForEach(weekDays, id: \.self) { date in
                        WeekDayCell(
                            date: date,
                            events: eventsForDate(date),
                            onLongPress: {
                                let calendar = Calendar.current
                                let baseDate = calendar.startOfDay(for: date)
                                newEventStart = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: baseDate) ?? date
                                newEventEnd = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: baseDate) ?? date.addingTimeInterval(3600)
                                showingCreateEvent = true
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .sheet(isPresented: $showingCreateEvent) {
            CreateEventView(
                eventToEdit: nil,
                defaultStart: newEventStart,
                defaultEnd: newEventEnd
            )
        }
    }
    
    private var weekStartDate: Date {
        let calendar = Calendar.current
        return calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
    }
    
    private var weekDays: [Date] {
        let calendar = Calendar.current
        let weekStart = weekStartDate
        return (0..<7).compactMap { day in
            calendar.date(byAdding: .day, value: day, to: weekStart)
        }
    }
    
    private func eventsForDate(_ date: Date) -> [CalendarEvent] {
        events.filter { event in
            Calendar.current.isDate(event.startTime, inSameDayAs: date)
        }
    }
}



struct WeekDayCell: View {
    let date: Date
    let events: [CalendarEvent]
    let onLongPress: () -> Void
    @State private var isLongPressing = false
    
    var body: some View {
        VStack(spacing: 4) {
            Text(date, style: .date)
                .font(.caption)
                .fontWeight(.medium)
            
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.title3)
                .fontWeight(.bold)
            
            if !events.isEmpty {
                Text("\(events.count) events")
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
        }
        .frame(height: 80)
        .frame(maxWidth: .infinity)
        .background(Calendar.current.isDateInToday(date) ? Color.blue.opacity(0.1) : Color(.systemGray6))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .fill(isLongPressing ? Color.blue.opacity(0.3) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            isLongPressing ? Color.blue : Color.clear,
                            lineWidth: isLongPressing ? 2 : 0
                        )
                        .scaleEffect(isLongPressing ? 1.05 : 1.0)
                )
                .animation(.easeInOut(duration: 0.2), value: isLongPressing)
        )
        .scaleEffect(isLongPressing ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: 0.6, maximumDistance: 40) {
            print("🎯 Long press SUCCESS at \(Calendar.current.component(.day, from: date))")
            
            // Enhanced haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            onLongPress()
        } onPressingChanged: { pressing in
            if pressing {
                // Start visual feedback immediately
                withAnimation(.easeIn(duration: 0.2)) {
                    isLongPressing = true
                }
                
                // Gentle vibration on press start
                let selectionFeedback = UISelectionFeedbackGenerator()
                selectionFeedback.selectionChanged()
                
            } else {
                // End visual feedback immediately
                withAnimation(.easeOut(duration: 0.2)) {
                    isLongPressing = false
                }
            }
        }
    }
}

struct MonthView: View {
    @Binding var selectedDate: Date
    let events: [CalendarEvent]
    @ObservedObject var gestureCoordinator: CalendarGestureCoordinator
    @State private var showingCreateEvent = false
    @State private var newEventStart = Date()
    @State private var newEventEnd = Date().addingTimeInterval(3600)
    
    var body: some View {
        VStack {
            // Calendar Widget
            DatePicker("Select Date", selection: $selectedDate, displayedComponents: [.date])
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding()
            
            // Events for selected date
            ScrollView {
                LazyVStack(spacing: 12) {
                    if events.isEmpty {
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
                        }
                        .padding(.top, 50)
                    } else {
                        ForEach(events) { event in
                            EventCard(event: event)
                        }
                    }
                }
                .padding()
                .onLongPressGesture {
                    let calendar = Calendar.current
                    let baseDate = calendar.startOfDay(for: selectedDate)
                    newEventStart = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: baseDate) ?? selectedDate
                    newEventEnd = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: baseDate) ?? selectedDate.addingTimeInterval(3600)
                    showingCreateEvent = true
                }
            }
        }
        .sheet(isPresented: $showingCreateEvent) {
            CreateEventView(
                eventToEdit: nil,
                defaultStart: newEventStart,
                defaultEnd: newEventEnd
            )
        }
    }
}

#Preview {
    CalendarView()
        .environmentObject(DataManager.shared)
        .environmentObject(AuthViewModel.shared)
}