# Firebase Setup Guide for AreaBook iOS App

## 📱 App Bundle Information
- **Bundle ID**: `com.areabook.ios`
- **App Name**: AreaBook
- **Platform**: iOS
- **Minimum iOS Version**: 15.0

## 🔥 Firebase Project Setup

### Step 1: Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or "Add project"
3. Enter project name: **AreaBook**
4. Enable Google Analytics (recommended)
5. Choose or create a Google Analytics account
6. Click "Create project"

### Step 2: Add iOS App to Firebase
1. In your Firebase project dashboard, click **"Add app"**
2. Select the **iOS** platform
3. Enter the bundle ID: **`com.areabook.ios`**
4. Enter app nickname: **AreaBook iOS**
5. Leave App Store ID empty for now
6. Click **"Register app"**

### Step 3: Download Configuration File
1. Download the **`GoogleService-Info.plist`** file
2. **Important**: Save this file to your AreaBook project directory
3. In Xcode, drag this file into your project (make sure "Add to target" is checked)

### Step 4: Firebase Services to Enable

#### Authentication
1. Go to **Authentication** > **Sign-in method**
2. Enable **Email/Password** sign-in
3. Optional: Enable **Google** sign-in for social login

#### Cloud Firestore
1. Go to **Firestore Database**
2. Click **"Create database"**
3. Choose **"Start in test mode"** for development
4. Select a location close to your users

#### Security Rules (Set these in Firestore Rules tab):
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Goals, tasks, events linked to user
    match /users/{userId}/goals/{goalId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /users/{userId}/tasks/{taskId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /users/{userId}/events/{eventId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /users/{userId}/notes/{noteId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Accountability groups
    match /accountabilityGroups/{groupId} {
      allow read, write: if request.auth != null && 
        request.auth.uid in resource.data.memberIds;
    }
  }
}
```

## 📋 Xcode Project Configuration

### 1. Open Xcode Project
- Create new iOS project with:
  - Product Name: **AreaBook**
  - Bundle Identifier: **com.areabook.ios**
  - Language: **Swift**
  - Interface: **SwiftUI**
  - Use Core Data: **No** (we're using Firestore)

### 2. Add Firebase Configuration
1. Drag `GoogleService-Info.plist` into Xcode project
2. Ensure it's added to the AreaBook target
3. The file should appear in your project navigator

### 3. Install Dependencies
```bash
# Navigate to your project directory
cd /path/to/AreaBook

# Install CocoaPods if not already installed
sudo gem install cocoapods

# Install Firebase dependencies
pod install

# Open the workspace (not .xcodeproj)
open AreaBook.xcworkspace
```

### 4. Add Required Capabilities in Xcode
1. Select your project in navigator
2. Go to **Signing & Capabilities**
3. Add these capabilities:
   - **Push Notifications**
   - **Background Modes** (Background App Refresh)

## 🧪 Testing Firebase Setup

### Test Authentication
```swift
// In a test view or your login screen
import Firebase

// Test Firebase configuration
print("Firebase configured: \(FirebaseApp.app() != nil)")

// Test auth connection
Auth.auth().addStateDidChangeListener { auth, user in
    if let user = user {
        print("User signed in: \(user.email ?? "No email")")
    } else {
        print("No user signed in")
    }
}
```

### Test Firestore Connection
```swift
import FirebaseFirestore

// Test Firestore connection
let db = Firestore.firestore()
db.collection("test").document("connection").setData([
    "status": "connected",
    "timestamp": Date()
]) { error in
    if let error = error {
        print("Firestore error: \(error)")
    } else {
        print("Firestore connected successfully!")
    }
}
```

## ⚠️ Common Issues & Solutions

### Issue: "GoogleService-Info.plist not found"
**Solution**: Ensure the plist file is:
- In your Xcode project root
- Added to the AreaBook target
- Named exactly `GoogleService-Info.plist`

### Issue: Bundle ID mismatch
**Solution**: Ensure bundle ID in:
- Firebase console: `com.areabook.ios`
- Xcode project settings: `com.areabook.ios`
- Info.plist: `com.areabook.ios`

### Issue: Firebase not initializing
**Solution**: Check that `FirebaseApp.configure()` is called in:
```swift
// AreaBookApp.swift
import Firebase

@main
struct AreaBookApp: App {
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

## 📝 Next Steps After Setup

1. **Test the configuration** using the test code above
2. **Implement authentication flow** in your app
3. **Set up Firestore collections** for your data models
4. **Configure push notifications** for reminders
5. **Set up analytics** to track user engagement

## 🔒 Security Considerations

- Never commit `GoogleService-Info.plist` to public repositories
- Use Firebase Security Rules to protect user data
- Enable App Check for production apps
- Set up proper authentication flows

---

**Bundle ID**: `com.areabook.ios`  
**Firebase Configuration**: Complete this setup to enable all AreaBook features!