# AreaBook - iOS Native App

A comprehensive spiritual productivity companion app built with SwiftUI and Firebase.

## Features

✅ **Dashboard** - Weekly Key Indicators (KIs) with progress tracking, today's tasks and events, motivational quotes
✅ **Goals Management** - Create, edit, delete goals with KI linking and progress tracking
✅ **Calendar & Events** - Monthly/weekly views, recurring events, task linking
✅ **Task Management** - Priority-based tasks, subtasks, goal/event linking
✅ **Note Taking** - Markdown support, bi-directional linking, tagging
✅ **Key Indicators** - Customizable weekly targets with progress tracking
✅ **Accountability Groups** - Multi-tiered groups (District > Companionship)
✅ **Authentication** - Firebase Auth with email/password
✅ **Real-time Sync** - Firebase Firestore for data synchronization

## Prerequisites

- Xcode 15.0 or later
- iOS 16.0 or later
- Firebase Project

## Firebase Setup

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project"
3. Enter "AreaBook" as project name
4. Enable Google Analytics (optional)
5. Create project

### 2. Add iOS App to Firebase

1. In Firebase Console, click "Add app" → iOS
2. Enter Bundle ID: `com.areabook.app`
3. Enter App nickname: `AreaBook`
4. Download `GoogleService-Info.plist`

### 3. Configure Firebase Services

#### Authentication
1. Go to Authentication → Sign-in method
2. Enable "Email/Password"
3. Optional: Enable "Google" sign-in

#### Firestore Database
1. Go to Firestore Database
2. Click "Create database"
3. Start in "Test mode" (for development)
4. Choose location close to your users

#### Storage (Optional)
1. Go to Storage
2. Get started with default rules

### 4. Update Configuration Files

1. **Replace GoogleService-Info.plist**
   - Delete the template `GoogleService-Info.plist`
   - Add your downloaded `GoogleService-Info.plist` to the project root

2. **Update Info.plist**
   - Replace `YOUR_REVERSED_CLIENT_ID` in `Info.plist` with your actual reversed client ID from `GoogleService-Info.plist`

3. **Update Bundle Identifier**
   - In Xcode, set your app's Bundle Identifier to match Firebase configuration

## Project Structure

```
AreaBook/
├── App/
│   └── AreaBookApp.swift          # Main app entry point
├── Models/
│   └── Models.swift               # Data models
├── ViewModels/
│   └── AuthViewModel.swift        # Authentication logic
├── Services/
│   ├── FirebaseService.swift      # Firebase configuration
│   └── DataManager.swift          # Data management
├── Views/
│   ├── ContentView.swift          # Main content view
│   ├── Auth/
│   │   └── AuthenticationView.swift
│   ├── Dashboard/
│   │   └── DashboardView.swift
│   ├── Goals/
│   │   └── GoalsView.swift
│   ├── Calendar/
│   │   └── CalendarView.swift
│   ├── Tasks/
│   │   └── TasksView.swift
│   ├── Notes/
│   │   └── NotesView.swift
│   └── Settings/
│       └── SettingsView.swift
├── GoogleService-Info.plist       # Firebase config
├── Info.plist                     # App configuration
└── Package.swift                  # Dependencies
```

## Dependencies

The app uses Swift Package Manager for dependencies:

- Firebase iOS SDK
  - FirebaseAuth
  - FirebaseFirestore
  - FirebaseStorage
  - FirebaseMessaging
  - FirebaseAnalytics
  - FirebaseCrashlytics

## Building and Running

1. Open `AreaBook.xcodeproj` in Xcode
2. Select your development team in project settings
3. Connect your iOS device or use Simulator
4. Build and run (⌘+R)

## Data Structure

### Firestore Collections

```
users/{userId}
├── keyIndicators/{kiId}
├── goals/{goalId}
├── events/{eventId}
├── tasks/{taskId}
└── notes/{noteId}

accountabilityGroups/{groupId}
encouragements/{encouragementId}
```

### Key Models

- **User**: Profile and settings
- **KeyIndicator**: Weekly trackable metrics
- **Goal**: Long-term objectives with progress
- **CalendarEvent**: Scheduled activities
- **Task**: Action items with priorities
- **Note**: Markdown content with linking
- **AccountabilityGroup**: Team collaboration

## Security Rules

Update Firestore security rules to protect user data:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Accountability groups access based on membership
    match /accountabilityGroups/{groupId} {
      allow read, write: if request.auth != null && 
        request.auth.uid in resource.data.members;
    }
    
    // Encouragements - users can read their own and create new ones
    match /encouragements/{encouragementId} {
      allow read: if request.auth != null && 
        (request.auth.uid == resource.data.toUserId || 
         request.auth.uid == resource.data.fromUserId);
      allow create: if request.auth != null && 
        request.auth.uid == request.resource.data.fromUserId;
    }
  }
}
```

## Push Notifications Setup

1. Enable Push Notifications in Xcode capabilities
2. Upload APNs certificate to Firebase Console
3. Configure notification handling in `FirebaseService.swift`

## Troubleshooting

### Common Issues

1. **Build Errors**
   - Ensure all Firebase dependencies are properly resolved
   - Clean build folder (⇧⌘K) and rebuild

2. **Firebase Connection Issues**
   - Verify `GoogleService-Info.plist` is in project
   - Check Bundle ID matches Firebase configuration
   - Ensure internet connection for first-time setup

3. **Authentication Issues**
   - Verify Email/Password is enabled in Firebase Console
   - Check error messages in Xcode console

### Debug Mode

Add debug prints in `FirebaseService.swift` to monitor Firebase operations:

```swift
func configure() {
    FirebaseApp.configure()
    print("Firebase configured successfully")
    print("Project ID: \(FirebaseApp.app()?.options.projectID ?? "Unknown")")
}
```

## Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions:
- Create an issue in this repository
- Check Firebase documentation: https://firebase.google.com/docs
- iOS Development resources: https://developer.apple.com/documentation/

---

Built with ❤️ for spiritual growth and productivity