import Foundation
import NaturalLanguage
import os.log

// MARK: - Siri AI Agent
class SiriAIAgent: ObservableObject {
    static let shared = SiriAIAgent()
    
    private let dataManager = DataManager.shared
    private let aiService = AIService.shared
    private let siriService = SiriService.shared
    
    // Context tracking for conversation
    private var conversationContext: ConversationContext = ConversationContext()
    private let contextManager = ContextManager()
    
    private init() {}
    
    // MARK: - Main Processing Method
    
    func processSiriCommand(_ command: String, userID: String) async -> SiriResponse {
        os_log("🤖 SiriAIAgent: Processing command: %{public}@", log: .default, type: .info, command)
        
        // Update conversation context
        conversationContext.addMessage(.user, content: command)
        
        // Analyze intent and extract entities
        let intentAnalysis = await analyzeIntent(command)
        
        // Generate response based on intent
        let response = await generateResponse(intentAnalysis, userID: userID)
        
        // Update context with response
        conversationContext.addMessage(.assistant, content: response.message)
        
        // Execute actions if needed
        if let action = response.action {
            await executeAction(action, userID: userID)
        }
        
        return response
    }
    
    // MARK: - Intent Analysis
    
    private func analyzeIntent(_ command: String) async -> IntentAnalysis {
        let lowercased = command.lowercased()
        
        // Task-related intents
        if containsTaskKeywords(lowercased) {
            return await analyzeTaskIntent(command)
        }
        
        // Goal-related intents
        if containsGoalKeywords(lowercased) {
            return await analyzeGoalIntent(command)
        }
        
        // Key Indicator intents
        if containsKeyIndicatorKeywords(lowercased) {
            return await analyzeKeyIndicatorIntent(command)
        }
        
        // Event/Calendar intents
        if containsEventKeywords(lowercased) {
            return await analyzeEventIntent(command)
        }
        
        // Wellness intents
        if containsWellnessKeywords(lowercased) {
            return await analyzeWellnessIntent(command)
        }
        
        // Query intents
        if containsQueryKeywords(lowercased) {
            return await analyzeQueryIntent(command)
        }
        
        // Default to general intent
        return IntentAnalysis(
            intent: .general,
            confidence: 0.5,
            entities: extractEntities(command),
            context: conversationContext.getRecentContext()
        )
    }
    
    // MARK: - Intent Type Analysis
    
    private func analyzeTaskIntent(_ command: String) async -> IntentAnalysis {
        let lowercased = command.lowercased()
        var intent: TaskIntent = .list
        var entities: [Entity] = []
        
        // Determine specific task action
        if lowercased.contains("add") || lowercased.contains("create") || lowercased.contains("new") {
            intent = .add
            entities.append(Entity(type: .taskTitle, value: extractTaskTitle(command)))
            entities.append(Entity(type: .priority, value: extractPriority(command)))
            entities.append(Entity(type: .dueDate, value: extractDate(command)))
        } else if lowercased.contains("complete") || lowercased.contains("done") || lowercased.contains("finish") {
            intent = .complete
            entities.append(Entity(type: .taskTitle, value: extractTaskTitle(command)))
        } else if lowercased.contains("list") || lowercased.contains("show") || lowercased.contains("what") {
            intent = .list
            entities.append(Entity(type: .timeFrame, value: extractTimeFrame(command)))
        }
        
        return IntentAnalysis(
            intent: .task(intent),
            confidence: 0.9,
            entities: entities,
            context: conversationContext.getRecentContext()
        )
    }
    
    private func analyzeGoalIntent(_ command: String) async -> IntentAnalysis {
        let lowercased = command.lowercased()
        var intent: GoalIntent = .list
        var entities: [Entity] = []
        
        if lowercased.contains("add") || lowercased.contains("create") || lowercased.contains("new") {
            intent = .add
            entities.append(Entity(type: .goalTitle, value: extractGoalTitle(command)))
            entities.append(Entity(type: .targetDate, value: extractDate(command)))
        } else if lowercased.contains("update") || lowercased.contains("progress") {
            intent = .update
            entities.append(Entity(type: .goalTitle, value: extractGoalTitle(command)))
            entities.append(Entity(type: .progress, value: extractProgress(command)))
        } else if lowercased.contains("list") || lowercased.contains("show") {
            intent = .list
        }
        
        return IntentAnalysis(
            intent: .goal(intent),
            confidence: 0.9,
            entities: entities,
            context: conversationContext.getRecentContext()
        )
    }
    
    private func analyzeKeyIndicatorIntent(_ command: String) async -> IntentAnalysis {
        let lowercased = command.lowercased()
        var intent: KeyIndicatorIntent = .log
        var entities: [Entity] = []
        
        if lowercased.contains("log") || lowercased.contains("record") || lowercased.contains("add") {
            intent = .log
            entities.append(Entity(type: .indicatorName, value: extractIndicatorName(command)))
            entities.append(Entity(type: .value, value: extractValue(command)))
        } else if lowercased.contains("check") || lowercased.contains("progress") || lowercased.contains("how") {
            intent = .check
            entities.append(Entity(type: .indicatorName, value: extractIndicatorName(command)))
        } else if lowercased.contains("summary") || lowercased.contains("weekly") {
            intent = .summary
        }
        
        return IntentAnalysis(
            intent: .keyIndicator(intent),
            confidence: 0.9,
            entities: entities,
            context: conversationContext.getRecentContext()
        )
    }
    
    private func analyzeEventIntent(_ command: String) async -> IntentAnalysis {
        let lowercased = command.lowercased()
        var intent: EventIntent = .list
        var entities: [Entity] = []
        
        if lowercased.contains("add") || lowercased.contains("create") || lowercased.contains("schedule") {
            intent = .add
            entities.append(Entity(type: .eventTitle, value: extractEventTitle(command)))
            entities.append(Entity(type: .startTime, value: extractDateTime(command)))
            entities.append(Entity(type: .endTime, value: extractEndTime(command)))
        } else if lowercased.contains("schedule") || lowercased.contains("today") || lowercased.contains("what") {
            intent = .list
            entities.append(Entity(type: .timeFrame, value: extractTimeFrame(command)))
        } else if lowercased.contains("next") || lowercased.contains("upcoming") {
            intent = .next
        }
        
        return IntentAnalysis(
            intent: .event(intent),
            confidence: 0.9,
            entities: entities,
            context: conversationContext.getRecentContext()
        )
    }
    
    private func analyzeWellnessIntent(_ command: String) async -> IntentAnalysis {
        let lowercased = command.lowercased()
        var intent: WellnessIntent = .check
        var entities: [Entity] = []
        
        if lowercased.contains("mood") || lowercased.contains("feeling") {
            intent = .logMood
            entities.append(Entity(type: .mood, value: extractMood(command)))
        } else if lowercased.contains("meditation") || lowercased.contains("meditate") {
            intent = .logMeditation
            entities.append(Entity(type: .minutes, value: extractMinutes(command)))
        } else if lowercased.contains("water") || lowercased.contains("drink") {
            intent = .logWater
            entities.append(Entity(type: .glasses, value: extractGlasses(command)))
        } else if lowercased.contains("how") && lowercased.contains("doing") {
            intent = .check
        }
        
        return IntentAnalysis(
            intent: .wellness(intent),
            confidence: 0.9,
            entities: entities,
            context: conversationContext.getRecentContext()
        )
    }
    
    private func analyzeQueryIntent(_ command: String) async -> IntentAnalysis {
        let lowercased = command.lowercased()
        var intent: AppQueryIntent = .general
        var entities: [Entity] = []
        
        if lowercased.contains("summary") || lowercased.contains("overview") {
            intent = .summary
            entities.append(Entity(type: .timeFrame, value: extractTimeFrame(command)))
        } else if lowercased.contains("progress") || lowercased.contains("how") {
            intent = .progress
        } else if lowercased.contains("help") || lowercased.contains("what can you do") {
            intent = .help
        }
        
        return IntentAnalysis(
            intent: .query(intent),
            confidence: 0.8,
            entities: entities,
            context: conversationContext.getRecentContext()
        )
    }
    
    // MARK: - Response Generation
    
    private func generateResponse(_ analysis: IntentAnalysis, userID: String) async -> SiriResponse {
        switch analysis.intent {
        case .task(let taskIntent):
            return await generateTaskResponse(taskIntent, entities: analysis.entities, userID: userID)
        case .goal(let goalIntent):
            return await generateGoalResponse(goalIntent, entities: analysis.entities, userID: userID)
        case .keyIndicator(let kiIntent):
            return await generateKeyIndicatorResponse(kiIntent, entities: analysis.entities, userID: userID)
        case .event(let eventIntent):
            return await generateEventResponse(eventIntent, entities: analysis.entities, userID: userID)
        case .wellness(let wellnessIntent):
            return await generateWellnessResponse(wellnessIntent, entities: analysis.entities, userID: userID)
        case .query(let queryIntent):
            return await generateQueryResponse(queryIntent, entities: analysis.entities, userID: userID)
        case .general:
            return await generateGeneralResponse(analysis, userID: userID)
        }
    }
    
    // MARK: - Response Generators
    
    private func generateTaskResponse(_ intent: TaskIntent, entities: [Entity], userID: String) async -> SiriResponse {
        switch intent {
        case .add:
            let title = entities.first(where: { $0.type == .taskTitle })?.value ?? "New Task"
            let priority = entities.first(where: { $0.type == .priority })?.value ?? "medium"
            let dueDate = entities.first(where: { $0.type == .dueDate })?.value ?? "today"
            
            let task = AppTask(
                title: title,
                priority: TaskPriority(rawValue: priority) ?? .medium,
                dueDate: parseDate(dueDate)
            )
            
            await dataManager.addTask(task)
            
            return SiriResponse(
                message: "I've added '\(title)' to your tasks for \(dueDate).",
                action: .addTask(task),
                confidence: 0.9
            )
            
        case .complete:
            let title = entities.first(where: { $0.type == .taskTitle })?.value ?? ""
            
            if !title.isEmpty {
                await dataManager.completeTaskByTitle(title)
                return SiriResponse(
                    message: "Great job! I've marked '\(title)' as completed.",
                    action: .completeTask(title),
                    confidence: 0.9
                )
            } else {
                return SiriResponse(
                    message: "Which task would you like me to mark as completed?",
                    action: nil,
                    confidence: 0.5
                )
            }
            
        case .list:
            let timeFrame = entities.first(where: { $0.type == .timeFrame })?.value ?? "today"
            let tasks = await dataManager.getTasksForTimeFrame(timeFrame)
            
            if tasks.isEmpty {
                return SiriResponse(
                    message: "You have no tasks for \(timeFrame).",
                    action: .listTasks(tasks),
                    confidence: 0.9
                )
            } else {
                let taskList = tasks.prefix(5).map { "• \($0.title)" }.joined(separator: "\n")
                return SiriResponse(
                    message: "Here are your tasks for \(timeFrame):\n\(taskList)",
                    action: .listTasks(tasks),
                    confidence: 0.9
                )
            }
        }
    }
    
    private func generateGoalResponse(_ intent: GoalIntent, entities: [Entity], userID: String) async -> SiriResponse {
        switch intent {
        case .add:
            let title = entities.first(where: { $0.type == .goalTitle })?.value ?? "New Goal"
            let targetDate = entities.first(where: { $0.type == .targetDate })?.value ?? "next month"
            
            let goal = Goal(
                title: title,
                description: "", // default
                keyIndicatorIds: [],
                targetDate: parseDate(targetDate),
                targetValue: 0.0, // default
                unit: "",
                progressType: .percentage
            )
            
            await dataManager.addGoal(goal)
            
            return SiriResponse(
                message: "I've added '\(title)' as a new goal with target date \(targetDate).",
                action: .addGoal(goal),
                confidence: 0.9
            )
            
        case .update:
            let title = entities.first(where: { $0.type == .goalTitle })?.value ?? ""
            let progress = entities.first(where: { $0.type == .progress })?.value ?? "0"
            
            if !title.isEmpty {
                await dataManager.updateGoalProgress(title: title, progress: Double(progress) ?? 0)
                return SiriResponse(
                    message: "I've updated the progress for '\(title)' to \(progress)%.",
                    action: .updateGoal(title, Double(progress) ?? 0),
                    confidence: 0.9
                )
            } else {
                return SiriResponse(
                    message: "Which goal would you like me to update?",
                    action: nil,
                    confidence: 0.5
                )
            }
            
        case .list:
            let goals = await dataManager.getGoals()
            
            if goals.isEmpty {
                return SiriResponse(
                    message: "You don't have any active goals yet.",
                    action: .listGoals(goals),
                    confidence: 0.9
                )
            } else {
                let goalList = goals.prefix(3).map { "• \($0.title) (\(Int($0.calculatedProgress))%)" }.joined(separator: "\n")
                return SiriResponse(
                    message: "Here are your active goals:\n\(goalList)",
                    action: .listGoals(goals),
                    confidence: 0.9
                )
            }
        }
    }
    
    private func generateKeyIndicatorResponse(_ intent: KeyIndicatorIntent, entities: [Entity], userID: String) async -> SiriResponse {
        switch intent {
        case .log:
            let name = entities.first(where: { $0.type == .indicatorName })?.value ?? ""
            let value = entities.first(where: { $0.type == .value })?.value ?? "1"
            
            if !name.isEmpty {
                await dataManager.logKeyIndicator(name: name, value: Int(value) ?? 1)
                return SiriResponse(
                    message: "I've logged \(value) for \(name).",
                    action: .logKeyIndicator(name, Int(value) ?? 1),
                    confidence: 0.9
                )
            } else {
                return SiriResponse(
                    message: "Which key indicator would you like me to log?",
                    action: nil,
                    confidence: 0.5
                )
            }
            
        case .check:
            let name = entities.first(where: { $0.type == .indicatorName })?.value ?? ""
            let indicators = await dataManager.getKeyIndicators()
            
            if !name.isEmpty {
                if let indicator = indicators.first(where: { $0.name.lowercased().contains(name.lowercased()) }) {
                    return SiriResponse(
                        message: "Your \(indicator.name) progress is \(indicator.currentWeekProgress) out of \(indicator.weeklyTarget) (\(Int(indicator.progressPercentage * 100))%).",
                        action: .checkProgress(indicator),
                        confidence: 0.9
                    )
                }
            } else {
                let progressList = indicators.prefix(3).map { "• \($0.name): \($0.currentWeekProgress)/\($0.weeklyTarget)" }.joined(separator: "\n")
                return SiriResponse(
                    message: "Here's your current progress:\n\(progressList)",
                    action: .checkProgress(nil),
                    confidence: 0.9
                )
            }
            
        case .summary:
            let summary = await dataManager.getWeeklySummary()
            return SiriResponse(
                message: "Here's your weekly summary: \(summary)",
                action: .weeklySummary(summary),
                confidence: 0.9
            )
        }
        
        return SiriResponse(
            message: "I'm not sure what you'd like me to do with your key indicators.",
            action: nil,
            confidence: 0.3
        )
    }
    
    private func generateEventResponse(_ intent: EventIntent, entities: [Entity], userID: String) async -> SiriResponse {
        switch intent {
        case .add:
            let title = entities.first(where: { $0.type == .eventTitle })?.value ?? "New Event"
            let startTime = entities.first(where: { $0.type == .startTime })?.value ?? "now"
            let endTime = entities.first(where: { $0.type == .endTime })?.value ?? "in 1 hour"
            
            let event = CalendarEvent(
                title: title,
                description: "", // default
                category: "", // default
                startTime: parseDateTime(startTime),
                endTime: parseDateTime(endTime)
            )
            
            await dataManager.addEvent(event)
            
            return SiriResponse(
                message: "I've added '\(title)' to your calendar from \(startTime) to \(endTime).",
                action: .addEvent(event),
                confidence: 0.9
            )
            
        case .list:
            let timeFrame = entities.first(where: { $0.type == .timeFrame })?.value ?? "today"
            let events = await dataManager.getEventsForTimeFrame(timeFrame)
            
            if events.isEmpty {
                return SiriResponse(
                    message: "You have no events scheduled for \(timeFrame).",
                    action: .listEvents(events),
                    confidence: 0.9
                )
            } else {
                let eventList = events.prefix(5).map { "• \(formatTime($0.startTime)) - \($0.title)" }.joined(separator: "\n")
                return SiriResponse(
                    message: "Here's your schedule for \(timeFrame):\n\(eventList)",
                    action: .listEvents(events),
                    confidence: 0.9
                )
            }
            
        case .next:
            let nextEvent = await dataManager.getNextEvent()
            
            if let event = nextEvent {
                return SiriResponse(
                    message: "Your next event is '\(event.title)' at \(formatTime(event.startTime)).",
                    action: .nextEvent(event),
                    confidence: 0.9
                )
            } else {
                return SiriResponse(
                    message: "You have no upcoming events.",
                    action: .nextEvent(nil),
                    confidence: 0.9
                )
            }
        }
    }
    
    private func generateWellnessResponse(_ intent: WellnessIntent, entities: [Entity], userID: String) async -> SiriResponse {
        switch intent {
        case .logMood:
            let mood = entities.first(where: { $0.type == .mood })?.value ?? "good"
            await dataManager.logMood(mood: MoodType(rawValue: mood) ?? .good)
            
            return SiriResponse(
                message: "I've logged your mood as \(mood). How are you feeling?",
                action: .logMood(mood),
                confidence: 0.9
            )
            
        case .logMeditation:
            let minutes = entities.first(where: { $0.type == .minutes })?.value ?? "10"
            await dataManager.logMeditation(minutes: Int(minutes) ?? 10)
            
            return SiriResponse(
                message: "Great! I've logged \(minutes) minutes of meditation. Keep up the mindfulness practice!",
                action: .logMeditation(Int(minutes) ?? 10),
                confidence: 0.9
            )
            
        case .logWater:
            let glasses = entities.first(where: { $0.type == .glasses })?.value ?? "1"
            await dataManager.logWater(glasses: Int(glasses) ?? 1)
            
            return SiriResponse(
                message: "I've logged \(glasses) glass of water. Stay hydrated!",
                action: .logWater(Int(glasses) ?? 1),
                confidence: 0.9
            )
            
        case .check:
            let wellness = await dataManager.getWellnessSummary()
            return SiriResponse(
                message: "Here's your wellness check: \(wellness)",
                action: .wellnessCheck(wellness),
                confidence: 0.9
            )
        }
    }
    
    private func generateQueryResponse(_ intent: AppQueryIntent, entities: [Entity], userID: String) async -> SiriResponse {
        switch intent {
        case .summary:
            let timeFrame = entities.first(where: { $0.type == .timeFrame })?.value ?? "today"
            let summary = await dataManager.getSummaryForTimeFrame(timeFrame)
            
            return SiriResponse(
                message: "Here's your \(timeFrame) summary: \(summary)",
                action: .summary(summary),
                confidence: 0.9
            )
            
        case .progress:
            let progress = await dataManager.getOverallProgress()
            return SiriResponse(
                message: "Here's your overall progress: \(String(describing: progress))",
                action: .progress(
                    String(describing: progress)),
                confidence: 0.9
            )
            
        case .help:
            return SiriResponse(
                message: "I can help you with tasks, goals, key indicators, events, and wellness tracking. Just ask me to add, complete, or check on any of these areas!",
                action: .help,
                confidence: 0.9
            )
        default:
            return SiriResponse(message: "Sorry, I didn't understand your query.", action: nil, confidence: 0.5)
        }
    }
    
    private func generateGeneralResponse(_ analysis: IntentAnalysis, userID: String) async -> SiriResponse {
        // Use AI service to generate a contextual response
        let prompt = """
        User said: "\(analysis.context.lastUserMessage ?? "")"
        Context: \(analysis.context.getSummary())
        
        Generate a helpful, conversational response that acknowledges their input and offers assistance with AreaBook features.
        """
        
        let aiResponse = await aiService.generateResponse(prompt: prompt)
        
        return SiriResponse(
            message: aiResponse,
            action: nil,
            confidence: 0.6
        )
    }
    
    // MARK: - Action Execution
    
    private func executeAction(_ action: SiriAction, userID: String) async {
        switch action {
        case .addTask(let task):
            await dataManager.addTask(task)
        case .completeTask(let title):
            await dataManager.completeTaskByTitle(title)
        case .listTasks(_):
            // Data already retrieved
            break
        case .addGoal(let goal):
            await dataManager.addGoal(goal)
        case .updateGoal(let title, let progress):
            await dataManager.updateGoalProgress(title: title, progress: progress)
        case .listGoals(_):
            // Data already retrieved
            break
        case .logKeyIndicator(let name, let value):
            await dataManager.logKeyIndicator(name: name, value: value)
        case .checkProgress(_):
            // Data already retrieved
            break
        case .weeklySummary(_):
            // Data already retrieved
            break
        case .addEvent(let event):
            await dataManager.addEvent(event)
        case .listEvents(_):
            // Data already retrieved
            break
        case .nextEvent(_):
            // Data already retrieved
            break
        case .logMood(let mood):
            await dataManager.logMood(mood: MoodType(rawValue: mood) ?? .good)
        case .logMeditation(let minutes):
            await dataManager.logMeditation(minutes: minutes)
        case .logWater(let glasses):
            await dataManager.logWater(glasses: glasses)
        case .wellnessCheck(_):
            // Data already retrieved
            break
        case .summary(_):
            // Data already retrieved
            break
        case .progress(_):
            // Data already retrieved
            break
        case .help:
            // No action needed
            break
        }
    }
    
    // MARK: - Entity Extraction Helpers
    
    private func extractEntities(_ command: String) -> [Entity] {
        var entities: [Entity] = []
        
        // Extract dates
        if !extractDate(command).isEmpty {
            entities.append(Entity(type: .dueDate, value: extractDate(command)))
        }
        
        // Extract times
        if !extractDateTime(command).isEmpty {
            entities.append(Entity(type: .startTime, value: extractDateTime(command)))
        }
        
        // Extract numbers
        if let number = extractNumber(command) {
            entities.append(Entity(type: .value, value: number))
        }
        
        return entities
    }
    
    private func containsTaskKeywords(_ command: String) -> Bool {
        let keywords = ["task", "todo", "do", "complete", "finish", "done"]
        return keywords.contains { command.contains($0) }
    }
    
    private func containsGoalKeywords(_ command: String) -> Bool {
        let keywords = ["goal", "target", "objective", "aim"]
        return keywords.contains { command.contains($0) }
    }
    
    private func containsKeyIndicatorKeywords(_ command: String) -> Bool {
        let keywords = ["indicator", "metric", "track", "progress", "weekly"]
        return keywords.contains { command.contains($0) }
    }
    
    private func containsEventKeywords(_ command: String) -> Bool {
        let keywords = ["event", "meeting", "appointment", "schedule", "calendar"]
        return keywords.contains { command.contains($0) }
    }
    
    private func containsWellnessKeywords(_ command: String) -> Bool {
        let keywords = ["mood", "feeling", "meditation", "water", "wellness", "health"]
        return keywords.contains { command.contains($0) }
    }
    
    private func containsQueryKeywords(_ command: String) -> Bool {
        let keywords = ["what", "how", "when", "where", "summary", "progress", "help"]
        return keywords.contains { command.contains($0) }
    }
    
    // MARK: - Utility Methods
    
    private func extractTaskTitle(_ command: String) -> String {
        // Simple extraction - look for text after "add" or "create"
        let words = command.components(separatedBy: " ")
        if let addIndex = words.firstIndex(of: "add") ?? words.firstIndex(of: "create") {
            let remainingWords = Array(words.suffix(from: addIndex + 1))
            return remainingWords.joined(separator: " ")
        }
        return "New Task"
    }
    
    private func extractGoalTitle(_ command: String) -> String {
        return extractTaskTitle(command) // Similar logic
    }
    
    private func extractEventTitle(_ command: String) -> String {
        return extractTaskTitle(command) // Similar logic
    }
    
    private func extractPriority(_ command: String) -> String {
        let lowercased = command.lowercased()
        if lowercased.contains("high") || lowercased.contains("urgent") {
            return "high"
        } else if lowercased.contains("low") || lowercased.contains("not urgent") {
            return "low"
        }
        return "medium"
    }
    
    private func extractDate(_ command: String) -> String {
        let lowercased = command.lowercased()
        if lowercased.contains("today") {
            return "today"
        } else if lowercased.contains("tomorrow") {
            return "tomorrow"
        } else if lowercased.contains("next week") {
            return "next week"
        } else if lowercased.contains("next month") {
            return "next month"
        }
        return "today"
    }
    
    private func extractDateTime(_ command: String) -> String {
        return extractDate(command) // Simplified for now
    }
    
    private func extractEndTime(_ command: String) -> String {
        return "in 1 hour" // Default
    }
    
    private func extractTimeFrame(_ command: String) -> String {
        return extractDate(command)
    }
    
    private func extractIndicatorName(_ command: String) -> String {
        // Look for common indicator names
        let indicators = ["scripture", "prayer", "exercise", "reading", "meditation"]
        for indicator in indicators {
            if command.lowercased().contains(indicator) {
                return indicator
            }
        }
        return ""
    }
    
    private func extractValue(_ command: String) -> String {
        return extractNumber(command) ?? "1"
    }
    
    private func extractProgress(_ command: String) -> String {
        return extractNumber(command) ?? "0"
    }
    
    private func extractMood(_ command: String) -> String {
        let lowercased = command.lowercased()
        if lowercased.contains("happy") || lowercased.contains("good") || lowercased.contains("great") {
            return "good"
        } else if lowercased.contains("sad") || lowercased.contains("bad") || lowercased.contains("terrible") {
            return "bad"
        } else if lowercased.contains("okay") || lowercased.contains("fine") || lowercased.contains("neutral") {
            return "neutral"
        }
        return "good"
    }
    
    private func extractMinutes(_ command: String) -> String {
        return extractNumber(command) ?? "10"
    }
    
    private func extractGlasses(_ command: String) -> String {
        return extractNumber(command) ?? "1"
    }
    
    private func extractNumber(_ command: String) -> String? {
        let pattern = "\\b\\d+\\b"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(command.startIndex..<command.endIndex, in: command)
        if let match = regex?.firstMatch(in: command, range: range) {
            return String(command[Range(match.range, in: command)!])
        }
        return nil
    }
    
    private func parseDate(_ dateString: String) -> Date {
        let lowercased = dateString.lowercased()
        let calendar = Calendar.current
        let now = Date()
        
        switch lowercased {
        case "today":
            return calendar.startOfDay(for: now)
        case "tomorrow":
            return calendar.date(byAdding: .day, value: 1, to: now) ?? now
        case "next week":
            return calendar.date(byAdding: .weekOfYear, value: 1, to: now) ?? now
        case "next month":
            return calendar.date(byAdding: .month, value: 1, to: now) ?? now
        default:
            return now
        }
    }
    
    private func parseDateTime(_ dateTimeString: String) -> Date {
        return parseDate(dateTimeString) // Simplified for now
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Structures

struct SiriResponse {
    let message: String
    let action: SiriAction?
    let confidence: Double
}

enum SiriAction {
    case addTask(AppTask)
    case completeTask(String)
    case listTasks([AppTask])
    case addGoal(Goal)
    case updateGoal(String, Double)
    case listGoals([Goal])
    case logKeyIndicator(String, Int)
    case checkProgress(KeyIndicator?)
    case weeklySummary(String)
    case addEvent(CalendarEvent)
    case listEvents([CalendarEvent])
    case nextEvent(CalendarEvent?)
    case logMood(String)
    case logMeditation(Int)
    case logWater(Int)
    case wellnessCheck(String)
    case summary(String)
    case progress(String)
    case help
}

struct IntentAnalysis {
    let intent: AppIntent
    let confidence: Double
    let entities: [Entity]
    let context: ConversationContext
}

enum AppIntent {
    case task(TaskIntent)
    case goal(GoalIntent)
    case keyIndicator(KeyIndicatorIntent)
    case event(EventIntent)
    case wellness(WellnessIntent)
    case query(AppQueryIntent)
    case general
}

enum TaskIntent {
    case add, complete, list
}

enum GoalIntent {
    case add, update, list
}

enum KeyIndicatorIntent {
    case log, check, summary
}

enum EventIntent {
    case add, list, next
}

enum WellnessIntent {
    case logMood, logMeditation, logWater, check
}

enum AppQueryIntent {
    case summary, progress, help, general
}

struct Entity {
    let type: EntityType
    let value: String
}

enum EntityType {
    case taskTitle, goalTitle, eventTitle
    case priority, dueDate, targetDate
    case startTime, endTime, timeFrame
    case indicatorName, value, progress
    case mood, minutes, glasses
}

struct ConversationContext {
    private var messages: [ConversationMessage] = []
    
    mutating func addMessage(_ role: MessageRole, content: String) {
        messages.append(ConversationMessage(role: role, content: content, timestamp: Date()))
        // Keep only last 10 messages
        if messages.count > 10 {
            messages.removeFirst()
        }
    }
    
    func getRecentContext() -> ConversationContext {
        var context = ConversationContext()
        context.messages = messages
        return context
    }
    
    var lastUserMessage: String? {
        return messages.last(where: { $0.role == .user })?.content
    }
    
    func getSummary() -> String {
        return messages.suffix(3).map { "\($0.role): \($0.content)" }.joined(separator: "\n")
    }
}

struct ConversationMessage {
    let role: MessageRole
    let content: String
    let timestamp: Date
}

enum MessageRole {
    case user, assistant
}

class ContextManager {
    private var userContexts: [String: ConversationContext] = [:]
    
    func getContext(for userID: String) -> ConversationContext {
        return userContexts[userID] ?? ConversationContext()
    }
    
    func updateContext(_ context: ConversationContext, for userID: String) {
        userContexts[userID] = context
    }
} 
