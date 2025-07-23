import SwiftUI
import Firebase

@main
struct AreaBookApp: App {
    
    init() {
        FirebaseService.shared.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(AuthViewModel.shared)
                .environmentObject(DataManager.shared)
        }
        .windowResizability(.contentSize)
        .windowToolbarStyle(.unified)
    }
}