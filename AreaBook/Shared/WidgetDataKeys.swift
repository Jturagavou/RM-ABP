import Foundation

// MARK: - App Group Configuration
struct WidgetConfiguration {
    static let appGroupIdentifier = "group.com.areabook.app"
    
    // UserDefaults Keys
    struct Keys {
        static let keyIndicators = "keyIndicators"
        static let todaysTasks = "todaysTasks"
        static let todaysEvents = "todaysEvents"
        static let lastUpdated = "widgetLastUpdated"
        static let userName = "userName"
        static let dailyQuote = "dailyQuote"
    }
    
    // Widget Update Intervals
    static let updateInterval: TimeInterval = 15 * 60 // 15 minutes
    static let immediateUpdateDelay: TimeInterval = 0.5 // Debounce delay
}

// MARK: - Widget Data Manager
class WidgetDataManager {
    static let shared = WidgetDataManager()
    private let sharedDefaults = UserDefaults(suiteName: WidgetConfiguration.appGroupIdentifier)
    private var updateTimer: Timer?
    
    private init() {}
    
    // Update all widget data
    func updateAllWidgetData(keyIndicators: [KeyIndicator], tasks: [Task], events: [CalendarEvent], userName: String? = nil) {
        guard let sharedDefaults = sharedDefaults else { return }
        
        // Encode and save key indicators
        if let kiData = try? JSONEncoder().encode(keyIndicators) {
            sharedDefaults.set(kiData, forKey: WidgetConfiguration.Keys.keyIndicators)
        }
        
        // Filter and save today's tasks
        let todaysTasks = tasks.filter { task in
            if let dueDate = task.dueDate {
                return Calendar.current.isDateInToday(dueDate)
            }
            return false
        }.sorted { ($0.priority.rawValue, $0.dueDate ?? Date()) < ($1.priority.rawValue, $1.dueDate ?? Date()) }
        
        if let tasksData = try? JSONEncoder().encode(todaysTasks) {
            sharedDefaults.set(tasksData, forKey: WidgetConfiguration.Keys.todaysTasks)
        }
        
        // Filter and save today's events (including recurring)
        let todaysEvents = filterTodaysEvents(from: events)
        if let eventsData = try? JSONEncoder().encode(todaysEvents) {
            sharedDefaults.set(eventsData, forKey: WidgetConfiguration.Keys.todaysEvents)
        }
        
        // Update metadata
        if let userName = userName {
            sharedDefaults.set(userName, forKey: WidgetConfiguration.Keys.userName)
        }
        
        sharedDefaults.set(Date(), forKey: WidgetConfiguration.Keys.lastUpdated)
        
        // Request widget reload
        requestWidgetReload()
    }
    
    // Filter today's events including recurring ones
    private func filterTodaysEvents(from events: [CalendarEvent]) -> [CalendarEvent] {
        let today = Date()
        var todaysEvents: [CalendarEvent] = []
        
        for event in events {
            if event.isRecurring, let pattern = event.recurrencePattern {
                // Check if recurring event occurs today
                if isRecurringEventOccursOnDate(event: event, pattern: pattern, date: today) {
                    // Create a virtual occurrence for today
                    var todayOccurrence = event
                    todayOccurrence.startTime = combineDateWithTime(date: today, time: event.startTime)
                    todayOccurrence.endTime = combineDateWithTime(date: today, time: event.endTime)
                    todaysEvents.append(todayOccurrence)
                }
            } else {
                // Regular event - check if it's today
                if Calendar.current.isDate(event.startTime, inSameDayAs: today) {
                    todaysEvents.append(event)
                }
            }
        }
        
        return todaysEvents.sorted { $0.startTime < $1.startTime }
    }
    
    // Check if recurring event occurs on specific date
    private func isRecurringEventOccursOnDate(event: CalendarEvent, pattern: RecurrencePattern, date: Date) -> Bool {
        let calendar = Calendar.current
        
        // Check if date is within event range
        if date < event.startTime { return false }
        if let endDate = pattern.endDate, date > endDate { return false }
        
        switch pattern.type {
        case .daily:
            let daysDiff = calendar.dateComponents([.day], from: event.startTime, to: date).day ?? 0
            return daysDiff >= 0 && daysDiff % pattern.interval == 0
            
        case .weekly:
            let weeksDiff = calendar.dateComponents([.weekOfYear], from: event.startTime, to: date).weekOfYear ?? 0
            if weeksDiff % pattern.interval != 0 { return false }
            
            // Check day of week
            if let daysOfWeek = pattern.daysOfWeek {
                let weekday = calendar.component(.weekday, from: date) - 1 // 0-6
                return daysOfWeek.contains(weekday)
            }
            return calendar.component(.weekday, from: date) == calendar.component(.weekday, from: event.startTime)
            
        case .monthly:
            let monthsDiff = calendar.dateComponents([.month], from: event.startTime, to: date).month ?? 0
            if monthsDiff % pattern.interval != 0 { return false }
            return calendar.component(.day, from: date) == calendar.component(.day, from: event.startTime)
            
        case .yearly:
            let yearsDiff = calendar.dateComponents([.year], from: event.startTime, to: date).year ?? 0
            if yearsDiff % pattern.interval != 0 { return false }
            let eventComponents = calendar.dateComponents([.month, .day], from: event.startTime)
            let dateComponents = calendar.dateComponents([.month, .day], from: date)
            return eventComponents.month == dateComponents.month && eventComponents.day == dateComponents.day
        }
    }
    
    // Combine date with time from another date
    private func combineDateWithTime(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: time)
        
        var combined = DateComponents()
        combined.year = dateComponents.year
        combined.month = dateComponents.month
        combined.day = dateComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute
        combined.second = timeComponents.second
        
        return calendar.date(from: combined) ?? date
    }
    
    // Request widget timeline reload
    private func requestWidgetReload() {
        #if !targetEnvironment(simulator)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
    
    // Debounced update
    func scheduleWidgetUpdate(keyIndicators: [KeyIndicator], tasks: [Task], events: [CalendarEvent], userName: String? = nil) {
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: WidgetConfiguration.immediateUpdateDelay, repeats: false) { _ in
            self.updateAllWidgetData(keyIndicators: keyIndicators, tasks: tasks, events: events, userName: userName)
        }
    }
}