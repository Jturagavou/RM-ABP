import Foundation
import SwiftUI

// MARK: - Widget Data Testing Utility
class WidgetDataTest {
    static let shared = WidgetDataTest()
    
    private let sharedDefaults = UserDefaults(suiteName: "group.com.areabook.app")
    
    private init() {}
    
    // Test if widget data is being shared correctly
    func testWidgetDataSharing() {
        print("=== Widget Data Sharing Test ===")
        
        // Test Key Indicators data
        if let kiData = sharedDefaults?.data(forKey: "keyIndicators") {
            print("✅ Key Indicators data found: \(kiData.count) bytes")
            
            do {
                let keyIndicators = try JSONDecoder().decode([KeyIndicator].self, from: kiData)
                print("   - Decoded \(keyIndicators.count) Key Indicators")
                for ki in keyIndicators.prefix(3) {
                    print("   - \(ki.name): \(ki.currentWeekProgress)/\(ki.weeklyTarget) (\(Int(ki.progressPercentage * 100))%)")
                }
            } catch {
                print("❌ Failed to decode Key Indicators: \(error)")
            }
        } else {
            print("❌ No Key Indicators data found")
        }
        
        // Test Today's Tasks data
        if let tasksData = sharedDefaults?.data(forKey: "todaysTasks") {
            print("✅ Today's Tasks data found: \(tasksData.count) bytes")
            
            do {
                let tasks = try JSONDecoder().decode([Task].self, from: tasksData)
                print("   - Decoded \(tasks.count) tasks for today")
                for task in tasks.prefix(3) {
                    print("   - \(task.title) (\(task.status.rawValue))")
                }
            } catch {
                print("❌ Failed to decode Today's Tasks: \(error)")
            }
        } else {
            print("❌ No Today's Tasks data found")
        }
        
        // Test Today's Events data
        if let eventsData = sharedDefaults?.data(forKey: "todaysEvents") {
            print("✅ Today's Events data found: \(eventsData.count) bytes")
            
            do {
                let events = try JSONDecoder().decode([CalendarEvent].self, from: eventsData)
                print("   - Decoded \(events.count) events for today")
                for event in events.prefix(3) {
                    print("   - \(event.title) at \(event.startTime.formatted(.dateTime.hour().minute()))")
                }
            } catch {
                print("❌ Failed to decode Today's Events: \(error)")
            }
        } else {
            print("❌ No Today's Events data found")
        }
        
        print("=== End Widget Data Test ===")
    }
    
    // Force update widget data for testing
    func forceUpdateWidgetData() {
        print("🔄 Forcing widget data update...")
        DataManager.shared.updateAllWidgetData()
        print("✅ Widget data update completed")
    }
    
    // Clear widget data for testing
    func clearWidgetData() {
        print("🗑️ Clearing widget data...")
        sharedDefaults?.removeObject(forKey: "keyIndicators")
        sharedDefaults?.removeObject(forKey: "todaysTasks")
        sharedDefaults?.removeObject(forKey: "todaysEvents")
        print("✅ Widget data cleared")
    }
}

// MARK: - Widget Data Test View (for debugging)
struct WidgetDataTestView: View {
    @State private var testResults = "Tap 'Run Test' to check widget data sharing"
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Widget Data Sharing Test")
                    .font(.title2)
                    .fontWeight(.bold)
                
                ScrollView {
                    Text(testResults)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                VStack(spacing: 12) {
                    Button("Run Test") {
                        runTest()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Force Update") {
                        forceUpdate()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Clear Data") {
                        clearData()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                }
            }
            .padding()
            .navigationTitle("Widget Debug")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func runTest() {
        testResults = "Running widget data test...\n\n"
        
        // Capture print output
        let originalPrint = print
        var capturedOutput = ""
        
        // Redirect print to capture output
        func captureOutput(_ items: Any..., separator: String = " ", terminator: String = "\n") {
            let output = items.map { "\($0)" }.joined(separator: separator)
            capturedOutput += output + terminator
        }
        
        // Run test with captured output
        WidgetDataTest.shared.testWidgetDataSharing()
        
        // Update UI with results
        DispatchQueue.main.async {
            testResults = capturedOutput.isEmpty ? "No output captured" : capturedOutput
        }
    }
    
    private func forceUpdate() {
        testResults = "Forcing widget data update...\n\n"
        WidgetDataTest.shared.forceUpdateWidgetData()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            runTest()
        }
    }
    
    private func clearData() {
        testResults = "Clearing widget data...\n\n"
        WidgetDataTest.shared.clearWidgetData()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            runTest()
        }
    }
}

#Preview {
    WidgetDataTestView()
}