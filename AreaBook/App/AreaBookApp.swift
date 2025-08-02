import SwiftUI
import Firebase
import WidgetKit
import os.log
import BackgroundTasks

@main
struct AreaBookApp: App {
    
    // Initialize Firebase immediately when the app starts
    init() {
        os_log("🚀 AreaBookApp: Starting initialization...", log: .default, type: .info)
        
        // Configure Firebase first, before any other services
        FirebaseService.shared.configure()
        os_log("🚀 AreaBookApp: Firebase configured", log: .default, type: .info)
        
        // Configure other services after Firebase
        DataManager.shared.configure()
        os_log("🚀 AreaBookApp: DataManager configured", log: .default, type: .info)
        
        // Initialize widget data service
        let _ = WidgetDataService.shared
        os_log("🚀 AreaBookApp: WidgetDataService initialized", log: .default, type: .info)
        
        // Initialize Siri AI agent
        let _ = SiriAIAgent.shared
        os_log("🚀 AreaBookApp: SiriAIAgent initialized", log: .default, type: .info)
        
        // Register background task for widget refresh
        registerBackgroundTasks()
        os_log("🚀 AreaBookApp: Background tasks registered", log: .default, type: .info)
        
        os_log("🚀 AreaBookApp: Initialization complete", log: .default, type: .info)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(AuthViewModel.shared)
                .environmentObject(DataManager.shared)
                .environmentObject(ColorThemeManager.shared)
                .environmentObject(AIService.shared)
                .environmentObject(WidgetDataService.shared)
                .environmentObject(SiriAIAgent.shared)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                    scheduleBackgroundWidgetRefresh()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    handleAppWillEnterForeground()
                }
        }
    }
    
    // MARK: - Background Task Management
    
    private func registerBackgroundTasks() {
        // Register background app refresh task for widget updates
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.areabook.widget-refresh", using: nil) { task in
            os_log("🔄 AreaBookApp: Background widget refresh task started", log: .default, type: .info)
            guard let appRefreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            self.handleBackgroundWidgetRefresh(task: appRefreshTask)
        }
    }
    
    private func scheduleBackgroundWidgetRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.areabook.widget-refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 5 * 60) // 5 minutes from now
        
        do {
            try BGTaskScheduler.shared.submit(request)
            os_log("✅ AreaBookApp: Background widget refresh scheduled", log: .default, type: .info)
        } catch {
            os_log("❌ AreaBookApp: Failed to schedule background refresh: %{public}@", log: .default, type: .error, error.localizedDescription)
        }
    }
    
    private func handleBackgroundWidgetRefresh(task: BGAppRefreshTask) {
        // Schedule next refresh
        scheduleBackgroundWidgetRefresh()
        
        // Handle the refresh with a timeout
        task.expirationHandler = {
            os_log("⏰ AreaBookApp: Background widget refresh expired", log: .default, type: .info)
            task.setTaskCompleted(success: false)
        }
        
        // Perform widget data refresh
        WidgetDataService.shared.syncDataForWidgets()
        
        // Mark task as completed
        task.setTaskCompleted(success: true)
        os_log("✅ AreaBookApp: Background widget refresh completed", log: .default, type: .info)
    }
    
    private func handleAppWillEnterForeground() {
        os_log("🔄 AreaBookApp: App entering foreground, checking widget data freshness", log: .default, type: .info)
        
        // Refresh widget data when app comes to foreground
        os_log("🔄 AreaBookApp: Refreshing widget data for foreground app activation", log: .default, type: .info)
        WidgetDataService.shared.syncDataForWidgets()
    }
}