import Foundation
import SwiftUI
import Intents
import IntentsUI

// MARK: - Siri Shortcuts Manager
class SiriShortcutsManager: NSObject, ObservableObject {
    static let shared = SiriShortcutsManager()
    
    private override init() {
        super.init()
    }
    
    // MARK: - Quick Add Task Shortcut
    func createQuickAddTaskShortcut() -> INShortcut? {
        let intent = QuickAddTaskIntent()
        intent.suggestedInvocationPhrase = "Add task to AreaBook"
        
        return INShortcut(intent: intent)
    }
    
    // MARK: - Log Task Success Shortcut
    func createLogTaskSuccessShortcut() -> INShortcut? {
        let intent = LogTaskSuccessIntent()
        intent.suggestedInvocationPhrase = "Log task success"
        
        return INShortcut(intent: intent)
    }
    
    // MARK: - Update Key Indicator Shortcut
    func createUpdateKIShortcut() -> INShortcut? {
        let intent = UpdateKeyIndicatorIntent()
        intent.suggestedInvocationPhrase = "Update my life tracker"
        
        return INShortcut(intent: intent)
    }
    
    // MARK: - Get Today's Schedule Shortcut
    func createTodaysScheduleShortcut() -> INShortcut? {
        let intent = GetTodaysScheduleIntent()
        intent.suggestedInvocationPhrase = "What's my schedule today"
        
        return INShortcut(intent: intent)
    }
    
    // MARK: - Daily KI Review Shortcut
    func createDailyKIReviewShortcut() -> INShortcut? {
        let intent = DailyKIReviewIntent()
        intent.suggestedInvocationPhrase = "Review my life trackers"
        
        return INShortcut(intent: intent)
    }
    
    // MARK: - Donate Shortcuts
    func donateShortcuts() {
        // Donate commonly used shortcuts to Siri
        if let taskShortcut = createQuickAddTaskShortcut() {
            INVoiceShortcutCenter.shared.setShortcutSuggestions([taskShortcut])
        }
        
        // Donate user activity for app discovery
        let userActivity = NSUserActivity(activityType: "com.areabook.app.openDashboard")
        userActivity.title = "Open AreaBook Dashboard"
        userActivity.isEligibleForSearch = true
        userActivity.isEligibleForPrediction = true
        userActivity.persistentIdentifier = "openDashboard"
        userActivity.becomeCurrent()
    }
    
    // MARK: - Present Add to Siri
    func presentAddToSiri(shortcut: INShortcut, from viewController: UIViewController) {
        let addShortcutVC = INUIAddVoiceShortcutViewController(shortcut: shortcut)
        addShortcutVC.delegate = self
        viewController.present(addShortcutVC, animated: true)
    }
}

// MARK: - Siri Shortcuts Delegate
extension SiriShortcutsManager: INUIAddVoiceShortcutViewControllerDelegate {
    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController, didFinishWith voiceShortcut: INVoiceShortcut?, error: Error?) {
        controller.dismiss(animated: true)
    }
    
    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        controller.dismiss(animated: true)
    }
}

// MARK: - Custom Intent Definitions

class QuickAddTaskIntent: INIntent {
    @NSManaged public var taskTitle: String?
    @NSManaged public var priority: String?
    @NSManaged public var dueDate: Date?
}

class LogTaskSuccessIntent: INIntent {
    @NSManaged public var taskId: String?
    @NSManaged public var success: Bool
    @NSManaged public var notes: String?
}

class UpdateKeyIndicatorIntent: INIntent {
    @NSManaged public var keyIndicatorId: String?
    @NSManaged public var progressValue: NSNumber?
}

class GetTodaysScheduleIntent: INIntent {
    // No parameters needed - returns today's schedule
}

class DailyKIReviewIntent: INIntent {
    // No parameters needed - opens KI review interface
}

// MARK: - Intent Handlers
class QuickAddTaskIntentHandler: NSObject, QuickAddTaskIntentHandling {
    func handle(intent: QuickAddTaskIntent, completion: @escaping (QuickAddTaskIntentResponse) -> Void) {
        guard let title = intent.taskTitle, !title.isEmpty else {
            completion(QuickAddTaskIntentResponse(code: .failure, userActivity: nil))
            return
        }
        
        // Create task via DataManager
        let task = Task(
            title: title,
            priority: TaskPriority(rawValue: intent.priority ?? "medium") ?? .medium,
            dueDate: intent.dueDate
        )
        
        // Save task (would need user context)
        // DataManager.shared.createTask(task, userId: userId)
        
        let response = QuickAddTaskIntentResponse(code: .success, userActivity: nil)
        response.taskTitle = title
        completion(response)
    }
}

class LogTaskSuccessIntentHandler: NSObject, LogTaskSuccessIntentHandling {
    func handle(intent: LogTaskSuccessIntent, completion: @escaping (LogTaskSuccessIntentResponse) -> Void) {
        // Handle task success logging
        let response = LogTaskSuccessIntentResponse(code: .success, userActivity: nil)
        completion(response)
    }
}

class UpdateKeyIndicatorIntentHandler: NSObject, UpdateKeyIndicatorIntentHandling {
    func handle(intent: UpdateKeyIndicatorIntent, completion: @escaping (UpdateKeyIndicatorIntentResponse) -> Void) {
        // Handle KI update
        let response = UpdateKeyIndicatorIntentResponse(code: .success, userActivity: nil)
        completion(response)
    }
}

class GetTodaysScheduleIntentHandler: NSObject, GetTodaysScheduleIntentHandling {
    func handle(intent: GetTodaysScheduleIntent, completion: @escaping (GetTodaysScheduleIntentResponse) -> Void) {
        // Get today's schedule from DataManager
        let response = GetTodaysScheduleIntentResponse(code: .success, userActivity: nil)
        response.scheduleText = "You have 3 tasks and 2 events today"
        completion(response)
    }
}

class DailyKIReviewIntentHandler: NSObject, DailyKIReviewIntentHandling {
    func handle(intent: DailyKIReviewIntent, completion: @escaping (DailyKIReviewIntentResponse) -> Void) {
        // Open KI review interface
        let response = DailyKIReviewIntentResponse(code: .success, userActivity: nil)
        completion(response)
    }
}

// MARK: - Intent Response Classes
class QuickAddTaskIntentResponse: INIntentResponse {
    @NSManaged public var taskTitle: String?
    
    convenience init(code: Code, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
    
    public enum Code: Int {
        case unspecified = 0
        case ready = 1
        case continueInApp = 2
        case inProgress = 3
        case success = 4
        case failure = 5
        case failureRequiringAppLaunch = 6
    }
    
    @NSManaged public var code: Code
}

class LogTaskSuccessIntentResponse: INIntentResponse {
    convenience init(code: Code, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
    
    public enum Code: Int {
        case unspecified = 0
        case ready = 1
        case continueInApp = 2
        case inProgress = 3
        case success = 4
        case failure = 5
    }
    
    @NSManaged public var code: Code
}

class UpdateKeyIndicatorIntentResponse: INIntentResponse {
    convenience init(code: Code, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
    
    public enum Code: Int {
        case unspecified = 0
        case ready = 1
        case continueInApp = 2
        case inProgress = 3
        case success = 4
        case failure = 5
    }
    
    @NSManaged public var code: Code
}

class GetTodaysScheduleIntentResponse: INIntentResponse {
    @NSManaged public var scheduleText: String?
    
    convenience init(code: Code, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
    
    public enum Code: Int {
        case unspecified = 0
        case ready = 1
        case continueInApp = 2
        case inProgress = 3
        case success = 4
        case failure = 5
    }
    
    @NSManaged public var code: Code
}

class DailyKIReviewIntentResponse: INIntentResponse {
    convenience init(code: Code, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
    
    public enum Code: Int {
        case unspecified = 0
        case ready = 1
        case continueInApp = 2
        case inProgress = 3
        case success = 4
        case failure = 5
    }
    
    @NSManaged public var code: Code
}

// MARK: - Protocol Definitions (these would typically be generated from .intentdefinition files)
@objc protocol QuickAddTaskIntentHandling {
    func handle(intent: QuickAddTaskIntent, completion: @escaping (QuickAddTaskIntentResponse) -> Void)
}

@objc protocol LogTaskSuccessIntentHandling {
    func handle(intent: LogTaskSuccessIntent, completion: @escaping (LogTaskSuccessIntentResponse) -> Void)
}

@objc protocol UpdateKeyIndicatorIntentHandling {
    func handle(intent: UpdateKeyIndicatorIntent, completion: @escaping (UpdateKeyIndicatorIntentResponse) -> Void)
}

@objc protocol GetTodaysScheduleIntentHandling {
    func handle(intent: GetTodaysScheduleIntent, completion: @escaping (GetTodaysScheduleIntentResponse) -> Void)
}

@objc protocol DailyKIReviewIntentHandling {
    func handle(intent: DailyKIReviewIntent, completion: @escaping (DailyKIReviewIntentResponse) -> Void)
}