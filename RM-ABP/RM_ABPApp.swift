import SwiftUI

@main
struct RM_ABPApp: App {
    @StateObject private var agentManager = AgentManager()
    @StateObject private var resourceManager = ResourceManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(agentManager)
                .environmentObject(resourceManager)
        }
    }
}