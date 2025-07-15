import Foundation
import WidgetKit

// MARK: - Widget Data Testing Utility
class WidgetDataTest {
    static let shared = WidgetDataTest()
    
    private let sharedDefaults = UserDefaults(suiteName: "group.com.areabook.app")
    
    private init() {}
    
    func testWidgetDataSharing() {
        print("🧪 Testing Widget Data Sharing...")
        
        // Test 1: Check if shared UserDefaults is accessible
        if let sharedDefaults = sharedDefaults {
            print("✅ Shared UserDefaults accessible")
        } else {
            print("❌ Shared UserDefaults NOT accessible")
            return
        }
        
        // Test 2: Check if data exists in shared storage
        let keyIndicatorsData = sharedDefaults?.data(forKey: "keyIndicators")
        let tasksData = sharedDefaults?.data(forKey: "todaysTasks")
        let eventsData = sharedDefaults?.data(forKey: "todaysEvents")
        
        print("📊 Widget Data Status:")
        print("- Key Indicators: \(keyIndicatorsData?.count ?? 0) bytes")
        print("- Today's Tasks: \(tasksData?.count ?? 0) bytes")
        print("- Today's Events: \(eventsData?.count ?? 0) bytes")
        
        // Test 3: Try to decode the data
        do {
            if let keyIndicatorsData = keyIndicatorsData, !keyIndicatorsData.isEmpty {
                let keyIndicators = try JSONDecoder().decode([KeyIndicator].self, from: keyIndicatorsData)
                print("✅ Key Indicators decoded: \(keyIndicators.count) items")
                
                for ki in keyIndicators.prefix(3) {
                    print("  - \(ki.title): \(ki.currentWeekProgress)/\(ki.weeklyTarget)")
                }
            } else {
                print("⚠️ No Key Indicators data found")
            }
            
            if let tasksData = tasksData, !tasksData.isEmpty {
                let tasks = try JSONDecoder().decode([Task].self, from: tasksData)
                print("✅ Tasks decoded: \(tasks.count) items")
                
                for task in tasks.prefix(3) {
                    print("  - \(task.title): \(task.status.rawValue)")
                }
            } else {
                print("⚠️ No Tasks data found")
            }
            
            if let eventsData = eventsData, !eventsData.isEmpty {
                let events = try JSONDecoder().decode([CalendarEvent].self, from: eventsData)
                print("✅ Events decoded: \(events.count) items")
                
                for event in events.prefix(3) {
                    print("  - \(event.title): \(event.startTime)")
                }
            } else {
                print("⚠️ No Events data found")
            }
            
        } catch {
            print("❌ Failed to decode widget data: \(error)")
        }
        
        // Test 4: Force widget reload
        print("🔄 Forcing widget reload...")
        WidgetCenter.shared.reloadAllTimelines()
        print("✅ Widget reload triggered")
    }
    
    func writeTestData() {
        print("📝 Writing test data to widget storage...")
        
        guard let sharedDefaults = sharedDefaults else {
            print("❌ Cannot access shared UserDefaults")
            return
        }
        
        // Create test data
        let testKI = KeyIndicator(
            title: "Test KI",
            description: "Test description",
            unit: "sessions",
            weeklyTarget: 7,
            currentWeekProgress: 3,
            color: "#FF0000"
        )
        
        let testTask = Task(
            title: "Test Task",
            description: "Test task description",
            priority: .medium,
            status: .pending,
            dueDate: Date(),
            linkedGoalId: nil,
            linkedKeyIndicatorIds: []
        )
        
        let testEvent = CalendarEvent(
            title: "Test Event",
            description: "Test event description",
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600),
            category: .personal,
            linkedGoalId: nil,
            linkedKeyIndicatorIds: []
        )
        
        do {
            // Encode and save test data
            let kiData = try JSONEncoder().encode([testKI])
            let taskData = try JSONEncoder().encode([testTask])
            let eventData = try JSONEncoder().encode([testEvent])
            
            sharedDefaults.set(kiData, forKey: "keyIndicators")
            sharedDefaults.set(taskData, forKey: "todaysTasks")
            sharedDefaults.set(eventData, forKey: "todaysEvents")
            
            print("✅ Test data written successfully")
            
            // Force widget reload
            WidgetCenter.shared.reloadAllTimelines()
            print("✅ Widget reload triggered")
            
        } catch {
            print("❌ Failed to write test data: \(error)")
        }
    }
    
    func clearWidgetData() {
        print("🗑️ Clearing widget data...")
        
        guard let sharedDefaults = sharedDefaults else {
            print("❌ Cannot access shared UserDefaults")
            return
        }
        
        sharedDefaults.removeObject(forKey: "keyIndicators")
        sharedDefaults.removeObject(forKey: "todaysTasks")
        sharedDefaults.removeObject(forKey: "todaysEvents")
        
        print("✅ Widget data cleared")
        
        // Force widget reload
        WidgetCenter.shared.reloadAllTimelines()
        print("✅ Widget reload triggered")
    }
    
    func runFullTest() {
        print("🚀 Running full widget test suite...")
        print("=" * 50)
        
        testWidgetDataSharing()
        
        print("\n" + "=" * 50)
        print("🔄 Testing with fresh data from DataManager...")
        
        // Trigger data update from DataManager
        DataManager.shared.updateAllWidgetData()
        
        // Wait a moment for the data to be written
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.testWidgetDataSharing()
        }
        
        print("\n" + "=" * 50)
        print("✅ Widget test suite completed")
    }
}

// Extension for string repetition
extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
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