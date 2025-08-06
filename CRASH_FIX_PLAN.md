# Comprehensive Crash Fix Plan

## Issues Identified

### 1. **Missing Service Configuration Logs**
- AuthViewModel.configure() is never called
- AIService.configure() is never called  
- WidgetDataService.configure() is never called
- CollaborationManager.configure() is never called
- "Initialization complete" appears right after DataManager

**Root Cause**: There are duplicate log messages in the output. One set from an older build is interfering.

### 2. **Firebase Timestamp Crash**
The crash is still happening: `'Invalid type in JSON write (FIRTimestamp)'`

**Root Cause**: Even with our fixes, somewhere FIRTimestamp is still being serialized.

### 3. **SceneDelegate Warnings**
`Info.plist configuration "(no name)" for UIWindowSceneSessionRoleApplication contained UISceneDelegateClassName key, but could not load class with name "AreaBook.SceneDelegate"`

**Root Cause**: Info.plist references a SceneDelegate that doesn't exist in SwiftUI apps.

### 4. **Firebase Configuration Warning**
`The default Firebase app has not yet been configured`

**Root Cause**: This is a timing issue - Firebase logs this before FirebaseApp.configure() runs.

## Action Plan

### Step 1: Fix Info.plist SceneDelegate Issue
- Remove UISceneDelegateClassName from Info.plist
- Remove UIApplicationSceneManifest if using pure SwiftUI

### Step 2: Find ALL FIRTimestamp Serialization Points
1. Search for all JSON serialization calls
2. Search for all os_log calls that might log Firebase data
3. Check for any Codable usage with Firebase documents
4. Check widget data serialization

### Step 3: Fix Service Initialization Order
1. Add logging to track which services are actually being initialized
2. Ensure no service accesses another during init
3. Add guard checks in configure() methods

### Step 4: Add Defensive Programming
1. Add nil checks for all Firebase operations
2. Add try-catch blocks around all JSON operations
3. Add explicit type conversions for all Date fields

### Step 5: Create Debug Build
1. Add verbose logging at every Firebase data access point
2. Log the exact location of JSON serialization
3. Identify the specific field causing the crash

## Immediate Actions

### 1. Add Debug Logging to Find Crash Location
```swift
// In AuthViewModel.loadUserData
os_log("📍 AuthViewModel: About to decode user data", log: .default, type: .info)
// Add logging before each potential crash point
```

### 2. Check All Data Serialization Points
- WidgetDataService JSON encoding
- UserSettings JSON operations
- Any place using JSONEncoder/JSONSerialization

### 3. Verify Service Dependencies
- Ensure no circular dependencies
- Check that all services wait for Firebase before accessing it

### 4. Test Isolation
- Comment out service configurations one by one
- Identify which service is causing the crash