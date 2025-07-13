import SwiftUI
import Firebase

@main
struct AreaBookApp: App {
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(AuthViewModel())
                .environmentObject(DataManager.shared)
        }
    }
}