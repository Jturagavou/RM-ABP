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
                if CalendarHelper.isRecurringEventOccursOnDate(event: event, pattern: pattern, date: today) {
                    // Create a virtual occurrence for today
                    var todayOccurrence = event
                    todayOccurrence.startTime = CalendarHelper.combineDateWithTime(date: today, time: event.startTime)
                    todayOccurrence.endTime = CalendarHelper.combineDateWithTime(date: today, time: event.endTime)
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