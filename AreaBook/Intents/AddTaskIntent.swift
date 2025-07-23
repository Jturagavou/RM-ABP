import Intents

@available(iOS 12.0, *)
class AddTaskIntent: INIntent {
    @objc dynamic var title: String?
    @objc dynamic var description: String?
    @objc dynamic var priority: TaskPriority?
    @objc dynamic var dueDate: Date?
}

@available(iOS 12.0, *)
class AddTaskIntentResponse: INIntentResponse {
    init(code: AddTaskIntentResponseCode, userActivity: NSUserActivity?) {
        super.init()
        self.code = code
        self.userActivity = userActivity
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    @objc dynamic var code: AddTaskIntentResponseCode = .unspecified
}

@available(iOS 12.0, *)
enum AddTaskIntentResponseCode: Int {
    case unspecified = 0
    case ready = 1
    case continueInApp = 2
    case inProgress = 3
    case success = 4
    case failure = 5
    case failureRequiringAppLaunch = 6
}

@available(iOS 12.0, *)
enum TaskPriority: Int, CaseIterable {
    case low = 0
    case medium = 1
    case high = 2
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }
} 