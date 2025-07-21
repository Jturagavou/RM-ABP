import Foundation

// MARK: - Calendar Helper
public struct CalendarHelper {
    public static func isRecurringEventOccursOnDate(event: CalendarEvent, pattern: RecurrencePattern, date: Date) -> Bool {
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
    
    public static func combineDateWithTime(date: Date, time: Date) -> Date {
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
    
    public static func generateRecurrenceDescription(_ pattern: RecurrencePattern) -> String {
        var description = ""
        
        switch pattern.type {
        case .daily:
            description = pattern.interval == 1 ? "Every day" : "Every \(pattern.interval) days"
        case .weekly:
            description = pattern.interval == 1 ? "Every week" : "Every \(pattern.interval) weeks"
            if let days = pattern.daysOfWeek {
                let dayNames = days.compactMap { dayName(for: $0) }.joined(separator: ", ")
                description += " on \(dayNames)"
            }
        case .monthly:
            description = pattern.interval == 1 ? "Every month" : "Every \(pattern.interval) months"
        case .yearly:
            description = pattern.interval == 1 ? "Every year" : "Every \(pattern.interval) years"
        }
        
        if let endDate = pattern.endDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            description += " until \(formatter.string(from: endDate))"
        }
        
        return description
    }
    
    private static func dayName(for dayIndex: Int) -> String? {
        let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        guard dayIndex >= 0 && dayIndex < days.count else { return nil }
        return days[dayIndex]
    }
}