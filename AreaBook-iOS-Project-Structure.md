# AreaBook iOS Project Structure

## 📱 Xcode Project Setup

### Project Configuration
```
AreaBook.xcodeproj
├── AreaBook/
│   ├── App/
│   │   ├── AreaBookApp.swift
│   │   ├── ContentView.swift
│   │   └── SceneDelegate.swift
│   ├── Core/
│   │   ├── Authentication/
│   │   │   ├── AuthViewModel.swift
│   │   │   ├── LoginView.swift
│   │   │   ├── SignUpView.swift
│   │   │   └── OnboardingView.swift
│   │   ├── Dashboard/
│   │   │   ├── DashboardView.swift
│   │   │   ├── DashboardViewModel.swift
│   │   │   └── KIProgressView.swift
│   │   ├── Goals/
│   │   │   ├── GoalsView.swift
│   │   │   ├── GoalDetailView.swift
│   │   │   ├── GoalCreationView.swift
│   │   │   └── GoalsViewModel.swift
│   │   ├── Calendar/
│   │   │   ├── CalendarView.swift
│   │   │   ├── EventDetailView.swift
│   │   │   ├── EventCreationView.swift
│   │   │   └── CalendarViewModel.swift
│   │   ├── Tasks/
│   │   │   ├── TasksView.swift
│   │   │   ├── TaskDetailView.swift
│   │   │   ├── TaskCreationView.swift
│   │   │   └── TasksViewModel.swift
│   │   ├── Notes/
│   │   │   ├── NotesView.swift
│   │   │   ├── NoteDetailView.swift
│   │   │   ├── NoteEditorView.swift
│   │   │   ├── NoteGraphView.swift
│   │   │   └── NotesViewModel.swift
│   │   ├── KeyIndicators/
│   │   │   ├── KISetupView.swift
│   │   │   ├── KIEditView.swift
│   │   │   └── KIViewModel.swift
│   │   ├── AccountabilityGroups/
│   │   │   ├── GroupsView.swift
│   │   │   ├── GroupDetailView.swift
│   │   │   ├── MemberPlannerView.swift
│   │   │   └── GroupsViewModel.swift
│   │   └── Settings/
│   │       ├── SettingsView.swift
│   │       ├── ProfileView.swift
│   │       └── SettingsViewModel.swift
│   ├── Models/
│   │   ├── User.swift
│   │   ├── Goal.swift
│   │   ├── Event.swift
│   │   ├── Task.swift
│   │   ├── Note.swift
│   │   ├── KeyIndicator.swift
│   │   └── AccountabilityGroup.swift
│   ├── Services/
│   │   ├── FirebaseService.swift
│   │   ├── AuthService.swift
│   │   ├── FirestoreService.swift
│   │   ├── NotificationService.swift
│   │   └── SiriShortcutsService.swift
│   ├── Utilities/
│   │   ├── Extensions/
│   │   │   ├── Date+Extensions.swift
│   │   │   ├── Color+Extensions.swift
│   │   │   └── View+Extensions.swift
│   │   ├── Constants.swift
│   │   ├── Enums.swift
│   │   └── ValidationHelpers.swift
│   ├── Components/
│   │   ├── Common/
│   │   │   ├── CustomButton.swift
│   │   │   ├── CustomTextField.swift
│   │   │   ├── LoadingView.swift
│   │   │   └── EmptyStateView.swift
│   │   ├── Navigation/
│   │   │   ├── TabBarView.swift
│   │   │   ├── NavigationHeaderView.swift
│   │   │   └── FloatingActionButton.swift
│   │   └── Specialized/
│   │       ├── ProgressRingView.swift
│   │       ├── CalendarWeekView.swift
│   │       ├── NoteCardView.swift
│   │       └── KICardView.swift
│   └── Resources/
│       ├── Assets.xcassets/
│       ├── GoogleService-Info.plist
│       ├── Info.plist
│       └── Localizable.strings
├── AreaBookWidgets/
│   ├── DashboardWidget.swift
│   ├── KIWidget.swift
│   └── Info.plist
├── AreaBookIntents/
│   ├── LogTaskIntentHandler.swift
│   ├── CreateEventIntentHandler.swift
│   └── Info.plist
└── Podfile
```

## 🔥 Firebase Dependencies (Podfile)
```ruby
platform :ios, '15.0'
use_frameworks!

target 'AreaBook' do
  pod 'Firebase/Analytics'
  pod 'Firebase/Auth'
  pod 'Firebase/Firestore'
  pod 'Firebase/Storage'
  pod 'Firebase/Messaging'
end

target 'AreaBookWidgets' do
  pod 'Firebase/Analytics'
  pod 'Firebase/Firestore'
end
```

## 📊 Core Data Models

### User Model
```swift
import Foundation
import FirebaseFirestore

struct User: Codable, Identifiable {
    @DocumentID var id: String?
    let email: String
    let name: String
    let createdAt: Date
    var keyIndicators: [KeyIndicator]
    var accountabilityGroups: [String] // Group IDs
    var settings: UserSettings
}
```

### Goal Model
```swift
import Foundation
import FirebaseFirestore

struct Goal: Codable, Identifiable {
    @DocumentID var id: String?
    let title: String
    let description: String
    let keyIndicatorId: String?
    let createdAt: Date
    let targetDate: Date?
    var progress: Double // 0.0 - 1.0
    var linkedNotes: [String] // Note IDs
    var tasks: [String] // Task IDs
    var isCompleted: Bool
}
```

### Event Model
```swift
import Foundation
import FirebaseFirestore

struct Event: Codable, Identifiable {
    @DocumentID var id: String?
    let title: String
    let description: String
    let startTime: Date
    let endTime: Date
    let category: EventCategory
    let goalId: String?
    var associatedTasks: [String] // Task IDs
    var isRecurring: Bool
    var recurrenceRule: RecurrenceRule?
    var completionStatus: EventCompletionStatus
}

enum EventCategory: String, CaseIterable, Codable {
    case church = "Church"
    case school = "School"
    case personal = "Personal"
    case work = "Work"
}

enum EventCompletionStatus: String, Codable {
    case pending = "pending"
    case success = "success"
    case failure = "failure"
    case warning = "warning"
}
```

## 🎯 Key Features Implementation

### 1. Dashboard KI Progress
```swift
struct KIProgressView: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2)) {
            ForEach(viewModel.keyIndicators) { ki in
                KICardView(
                    title: ki.name,
                    current: ki.currentWeekProgress,
                    target: ki.weeklyTarget,
                    progress: ki.progressPercentage
                )
            }
        }
    }
}
```

### 2. Note Linking System
```swift
struct NoteEditorView: View {
    @State private var noteContent: String = ""
    @State private var linkedNotes: [Note] = []
    
    private func detectLinkedNotes() {
        // Parse [[Note Title]] syntax
        // Update bidirectional links
        // Refresh note graph
    }
}
```

### 3. Accountability Groups
```swift
struct GroupDetailView: View {
    let group: AccountabilityGroup
    @State private var selectedMember: User?
    @State private var showingFullSync = false
    
    var body: some View {
        VStack {
            // Member list with KI overview
            // Full sync toggle
            // Encouragement sending
        }
    }
}
```

## 🚀 Setup Instructions

When you have access to macOS:

1. **Install Xcode** (latest version)
2. **Install CocoaPods**: `sudo gem install cocoapods`
3. **Create new iOS project** in Xcode
4. **Add Firebase configuration**:
   - Add `GoogleService-Info.plist`
   - Install Firebase pods: `pod install`
5. **Implement the above structure**
6. **Configure capabilities**:
   - Push Notifications
   - Background App Refresh
   - Siri & Shortcuts

## 🧪 Testing on iOS

- **iOS Simulator**: Built into Xcode
- **Physical Device**: Connect iPhone/iPad via USB
- **TestFlight**: For beta testing
- **Unit Tests**: XCTest framework
- **UI Tests**: XCUITest framework

This structure provides everything you need for a complete iOS AreaBook app with all your planned features!