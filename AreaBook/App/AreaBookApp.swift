import SwiftUI
import Firebase
import os.log

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
        
        os_log("🚀 AreaBookApp: Initialization complete", log: .default, type: .info)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(AuthViewModel())
                .environmentObject(DataManager.shared)
        }
    }
}