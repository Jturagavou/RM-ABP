import Foundation
import Combine

class DataValidationService: ObservableObject {
    static let shared = DataValidationService()
    
    @Published var validationErrors: [String: [ValidationError]] = [:]
    @Published var validationWarnings: [String: [ValidationWarning]] = [:]
    
    private var validationRules: [String: [ValidationRule]] = [:]
    
    private init() {
        setupDefaultValidationRules()
    }
    
    // MARK: - Public Validation Methods
    
    func validateGoal(_ goal: Goal) -> ValidationResult {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []
        
        // Title validation
        if goal.title.isEmpty {
            errors.append(ValidationError(field: "title", message: "Goal title is required", ruleType: .required))
        }
        
        if goal.title.count < 3 {
            errors.append(ValidationError(field: "title", message: "Goal title must be at least 3 characters", ruleType: .minLength))
        }
        
        if goal.title.count > 100 {
            errors.append(ValidationError(field: "title", message: "Goal title cannot exceed 100 characters", ruleType: .maxLength))
        }
        
        // Description validation
        if goal.description.isEmpty {
            warnings.append(ValidationWarning(field: "description", message: "Consider adding a description for better clarity", suggestion: "Add a brief description of what you want to achieve"))
        }
        
        if goal.description.count > 1000 {
            errors.append(ValidationError(field: "description", message: "Goal description cannot exceed 1000 characters", ruleType: .maxLength))
        }
        
        // Target date validation
        if let targetDate = goal.targetDate {
            if targetDate < Date() {
                errors.append(ValidationError(field: "targetDate", message: "Target date cannot be in the past", ruleType: .range))
            }
            
            if targetDate > Calendar.current.date(byAdding: .year, value: 5, to: Date()) ?? Date() {
                warnings.append(ValidationWarning(field: "targetDate", message: "Target date is more than 5 years in the future", suggestion: "Consider setting shorter-term milestones"))
            }
        }
        
        // Key indicators validation
        if goal.keyIndicatorIds.isEmpty {
            warnings.append(ValidationWarning(field: "keyIndicatorIds", message: "Consider linking this goal to key indicators for better tracking", suggestion: "Add relevant key indicators to measure progress"))
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors, warnings: warnings)
    }
    
    func validateKeyIndicator(_ ki: KeyIndicator) -> ValidationResult {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []
        
        // Name validation
        if ki.name.isEmpty {
            errors.append(ValidationError(field: "name", message: "Key indicator name is required", ruleType: .required))
        }
        
        if ki.name.count < 2 {
            errors.append(ValidationError(field: "name", message: "Key indicator name must be at least 2 characters", ruleType: .minLength))
        }
        
        if ki.name.count > 50 {
            errors.append(ValidationError(field: "name", message: "Key indicator name cannot exceed 50 characters", ruleType: .maxLength))
        }
        
        // Weekly target validation
        if ki.weeklyTarget <= 0 {
            errors.append(ValidationError(field: "weeklyTarget", message: "Weekly target must be greater than 0", ruleType: .range))
        }
        
        if ki.weeklyTarget > 1000 {
            warnings.append(ValidationWarning(field: "weeklyTarget", message: "Weekly target seems very high", suggestion: "Consider setting a more achievable target"))
        }
        
        // Unit validation
        if ki.unit.isEmpty {
            warnings.append(ValidationWarning(field: "unit", message: "Consider adding a unit for better clarity", suggestion: "Add a unit like 'times', 'minutes', 'pages', etc."))
        }
        
        // Current progress validation
        if ki.currentWeekProgress < 0 {
            errors.append(ValidationError(field: "currentWeekProgress", message: "Progress cannot be negative", ruleType: .range))
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors, warnings: warnings)
    }
    
    func validateTask(_ task: Task) -> ValidationResult {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []
        
        // Title validation
        if task.title.isEmpty {
            errors.append(ValidationError(field: "title", message: "Task title is required", ruleType: .required))
        }
        
        if task.title.count < 3 {
            errors.append(ValidationError(field: "title", message: "Task title must be at least 3 characters", ruleType: .minLength))
        }
        
        if task.title.count > 200 {
            errors.append(ValidationError(field: "title", message: "Task title cannot exceed 200 characters", ruleType: .maxLength))
        }
        
        // Due date validation
        if let dueDate = task.dueDate {
            if dueDate < Date() {
                warnings.append(ValidationWarning(field: "dueDate", message: "Due date is in the past", suggestion: "Consider updating the due date or marking as overdue"))
            }
        }
        
        // Description validation
        if let description = task.description, description.count > 1000 {
            errors.append(ValidationError(field: "description", message: "Task description cannot exceed 1000 characters", ruleType: .maxLength))
        }
        
        // Subtasks validation
        if task.subtasks.isEmpty && task.priority == .high {
            warnings.append(ValidationWarning(field: "subtasks", message: "High priority tasks benefit from subtasks", suggestion: "Consider breaking this task into smaller subtasks"))
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors, warnings: warnings)
    }
    
    func validateEvent(_ event: CalendarEvent) -> ValidationResult {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []
        
        // Title validation
        if event.title.isEmpty {
            errors.append(ValidationError(field: "title", message: "Event title is required", ruleType: .required))
        }
        
        if event.title.count > 100 {
            errors.append(ValidationError(field: "title", message: "Event title cannot exceed 100 characters", ruleType: .maxLength))
        }
        
        // Date validation
        if event.startTime >= event.endTime {
            errors.append(ValidationError(field: "endTime", message: "End time must be after start time", ruleType: .crossField))
        }
        
        let duration = event.endTime.timeIntervalSince(event.startTime)
        if duration > 24 * 60 * 60 { // 24 hours
            warnings.append(ValidationWarning(field: "duration", message: "Event duration exceeds 24 hours", suggestion: "Consider splitting into multiple events"))
        }
        
        if duration < 5 * 60 { // 5 minutes
            warnings.append(ValidationWarning(field: "duration", message: "Very short event duration", suggestion: "Ensure the time is correct"))
        }
        
        // Category validation
        if event.category.isEmpty {
            warnings.append(ValidationWarning(field: "category", message: "Consider adding a category for better organization"))
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors, warnings: warnings)
    }
    
    func validateAccountabilityGroup(_ group: AccountabilityGroup) -> ValidationResult {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []
        
        // Name validation
        if group.name.isEmpty {
            errors.append(ValidationError(field: "name", message: "Group name is required", ruleType: .required))
        }
        
        if group.name.count < 3 {
            errors.append(ValidationError(field: "name", message: "Group name must be at least 3 characters", ruleType: .minLength))
        }
        
        if group.name.count > 50 {
            errors.append(ValidationError(field: "name", message: "Group name cannot exceed 50 characters", ruleType: .maxLength))
        }
        
        // Members validation
        if group.members.isEmpty {
            warnings.append(ValidationWarning(field: "members", message: "Group has no members", suggestion: "Consider inviting members to the group"))
        }
        
        if group.members.count > 50 {
            warnings.append(ValidationWarning(field: "members", message: "Large group size may reduce effectiveness", suggestion: "Consider splitting into smaller groups"))
        }
        
        // Admin validation
        let adminCount = group.members.filter { $0.role == .admin }.count
        if adminCount == 0 {
            errors.append(ValidationError(field: "members", message: "Group must have at least one admin", ruleType: .required))
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors, warnings: warnings)
    }
    
    // MARK: - Template Validation
    
    func validateGoalTemplate(_ template: GoalTemplate) -> ValidationResult {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []
        
        // Name validation
        if template.name.isEmpty {
            errors.append(ValidationError(field: "name", message: "Template name is required", ruleType: .required))
        }
        
        if template.name.count > 100 {
            errors.append(ValidationError(field: "name", message: "Template name cannot exceed 100 characters", ruleType: .maxLength))
        }
        
        // Description validation
        if template.description.isEmpty {
            warnings.append(ValidationWarning(field: "description", message: "Consider adding a description for better usability"))
        }
        
        // Duration validation
        if template.estimatedDuration <= 0 {
            errors.append(ValidationError(field: "estimatedDuration", message: "Estimated duration must be greater than 0", ruleType: .range))
        }
        
        if template.estimatedDuration > 365 * 2 { // 2 years
            warnings.append(ValidationWarning(field: "estimatedDuration", message: "Very long duration for a template", suggestion: "Consider shorter timeframes"))
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors, warnings: warnings)
    }
    
    // MARK: - Cross-Entity Validation
    
    func validateDataConsistency(goals: [Goal], tasks: [Task], events: [CalendarEvent], keyIndicators: [KeyIndicator]) -> ValidationResult {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []
        
        // Check for orphaned references
        let taskGoalIds = Set(tasks.compactMap { $0.linkedGoalId })
        let existingGoalIds = Set(goals.map { $0.id })
        let orphanedTaskGoals = taskGoalIds.subtracting(existingGoalIds)
        
        if !orphanedTaskGoals.isEmpty {
            errors.append(ValidationError(field: "tasks", message: "Some tasks reference non-existent goals", ruleType: .crossField))
        }
        
        // Check for unreferenced key indicators
        let usedKIIds = Set(goals.flatMap { $0.keyIndicatorIds })
        let existingKIIds = Set(keyIndicators.map { $0.id })
        let unusedKIs = existingKIIds.subtracting(usedKIIds)
        
        if !unusedKIs.isEmpty {
            warnings.append(ValidationWarning(field: "keyIndicators", message: "Some key indicators are not linked to any goals", suggestion: "Consider linking them to goals or removing unused ones"))
        }
        
        // Check for goals without tasks
        let goalsWithoutTasks = goals.filter { goal in
            !tasks.contains { $0.linkedGoalId == goal.id }
        }
        
        if !goalsWithoutTasks.isEmpty {
            warnings.append(ValidationWarning(field: "goals", message: "Some goals have no associated tasks", suggestion: "Consider creating tasks to work toward these goals"))
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors, warnings: warnings)
    }
    
    // MARK: - Business Rule Validation
    
    func validateBusinessRules(for userId: String, goals: [Goal], tasks: [Task], events: [CalendarEvent]) -> ValidationResult {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []
        
        // Check for too many active goals
        let activeGoals = goals.filter { $0.status == .active }
        if activeGoals.count > 10 {
            warnings.append(ValidationWarning(field: "goals", message: "You have many active goals", suggestion: "Consider focusing on fewer goals for better success"))
        }
        
        // Check for overdue tasks
        let overdueTasks = tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate < Date() && task.status == .pending
        }
        
        if overdueTasks.count > 5 {
            warnings.append(ValidationWarning(field: "tasks", message: "You have many overdue tasks", suggestion: "Consider updating or completing overdue tasks"))
        }
        
        // Check for scheduling conflicts
        let sortedEvents = events.sorted { $0.startTime < $1.startTime }
        for i in 0..<sortedEvents.count-1 {
            let current = sortedEvents[i]
            let next = sortedEvents[i+1]
            
            if current.endTime > next.startTime {
                warnings.append(ValidationWarning(field: "events", message: "Scheduling conflict detected", suggestion: "Check event times for overlaps"))
                break
            }
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors, warnings: warnings)
    }
    
    // MARK: - Private Helper Methods
    
    private func setupDefaultValidationRules() {
        // Goal validation rules
        validationRules["goal"] = [
            ValidationRule(field: "title", ruleType: .required, parameters: [:], errorMessage: "Goal title is required"),
            ValidationRule(field: "title", ruleType: .minLength, parameters: ["min": 3], errorMessage: "Goal title must be at least 3 characters"),
            ValidationRule(field: "title", ruleType: .maxLength, parameters: ["max": 100], errorMessage: "Goal title cannot exceed 100 characters"),
            ValidationRule(field: "description", ruleType: .maxLength, parameters: ["max": 1000], errorMessage: "Goal description cannot exceed 1000 characters")
        ]
        
        // Task validation rules
        validationRules["task"] = [
            ValidationRule(field: "title", ruleType: .required, parameters: [:], errorMessage: "Task title is required"),
            ValidationRule(field: "title", ruleType: .minLength, parameters: ["min": 3], errorMessage: "Task title must be at least 3 characters"),
            ValidationRule(field: "title", ruleType: .maxLength, parameters: ["max": 200], errorMessage: "Task title cannot exceed 200 characters")
        ]
        
        // Event validation rules
        validationRules["event"] = [
            ValidationRule(field: "title", ruleType: .required, parameters: [:], errorMessage: "Event title is required"),
            ValidationRule(field: "title", ruleType: .maxLength, parameters: ["max": 100], errorMessage: "Event title cannot exceed 100 characters")
        ]
        
        // Key indicator validation rules
        validationRules["keyIndicator"] = [
            ValidationRule(field: "name", ruleType: .required, parameters: [:], errorMessage: "Key indicator name is required"),
            ValidationRule(field: "name", ruleType: .minLength, parameters: ["min": 2], errorMessage: "Key indicator name must be at least 2 characters"),
            ValidationRule(field: "weeklyTarget", ruleType: .range, parameters: ["min": 1, "max": 1000], errorMessage: "Weekly target must be between 1 and 1000")
        ]
        
        // Group validation rules
        validationRules["group"] = [
            ValidationRule(field: "name", ruleType: .required, parameters: [:], errorMessage: "Group name is required"),
            ValidationRule(field: "name", ruleType: .minLength, parameters: ["min": 3], errorMessage: "Group name must be at least 3 characters"),
            ValidationRule(field: "name", ruleType: .maxLength, parameters: ["max": 50], errorMessage: "Group name cannot exceed 50 characters")
        ]
    }
    
    // MARK: - Real-time Validation
    
    func validateFieldInRealTime<T>(_ value: T, field: String, entityType: String) -> ValidationResult {
        guard let rules = validationRules[entityType] else {
            return ValidationResult()
        }
        
        let fieldRules = rules.filter { $0.field == field && $0.isActive }
        var errors: [ValidationError] = []
        
        for rule in fieldRules {
            let result = validateField(value, rule: rule)
            if let error = result {
                errors.append(error)
            }
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }
    
    private func validateField<T>(_ value: T, rule: ValidationRule) -> ValidationError? {
        switch rule.ruleType {
        case .required:
            if let stringValue = value as? String, stringValue.isEmpty {
                return ValidationError(field: rule.field, message: rule.errorMessage, ruleType: rule.ruleType)
            }
            
        case .minLength:
            if let stringValue = value as? String,
               let min = rule.parameters["min"] as? Int,
               stringValue.count < min {
                return ValidationError(field: rule.field, message: rule.errorMessage, ruleType: rule.ruleType)
            }
            
        case .maxLength:
            if let stringValue = value as? String,
               let max = rule.parameters["max"] as? Int,
               stringValue.count > max {
                return ValidationError(field: rule.field, message: rule.errorMessage, ruleType: rule.ruleType)
            }
            
        case .range:
            if let intValue = value as? Int,
               let min = rule.parameters["min"] as? Int,
               let max = rule.parameters["max"] as? Int,
               intValue < min || intValue > max {
                return ValidationError(field: rule.field, message: rule.errorMessage, ruleType: rule.ruleType)
            }
            
        case .pattern:
            if let stringValue = value as? String,
               let pattern = rule.parameters["pattern"] as? String {
                do {
                    let regex = try NSRegularExpression(pattern: pattern)
                    let range = NSRange(location: 0, length: stringValue.utf16.count)
                    if regex.firstMatch(in: stringValue, options: [], range: range) == nil {
                        return ValidationError(field: rule.field, message: rule.errorMessage, ruleType: rule.ruleType)
                    }
                } catch {
                    return ValidationError(field: rule.field, message: "Invalid pattern", ruleType: rule.ruleType)
                }
            }
            
        case .unique, .crossField, .custom:
            // These require more complex validation that would be handled elsewhere
            break
        }
        
        return nil
    }
}