# 🚀 Running AreaBook in iOS Simulator

## Prerequisites

Before running the app, make sure you have:
- **Xcode 15.0+** installed on your Mac
- **iOS 17.0+ Simulator** (or iOS 16.0+ minimum)
- **Firebase project** configured (see setup below)

## Quick Start

### 1. Open the Project
```bash
cd /path/to/your/AreaBook/project
open AreaBook.xcodeproj
```

### 2. Select Simulator
- In Xcode, click the device dropdown (top left)
- Select an iOS Simulator (e.g., "iPhone 15 Pro")
- Make sure it's **NOT** set to "Any iOS Device"

### 3. Build and Run
- Press **⌘R** or click the "Run" button
- Wait for the build to complete
- The app will launch in the iOS Simulator

## 🔧 If Build Fails

### Common Issues and Solutions

#### 1. **Firebase Configuration Missing**
**Error**: `GoogleService-Info.plist not found`

**Solution**:
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new project or select existing
3. Add iOS app with bundle ID: `com.areabook.app`
4. Download `GoogleService-Info.plist`
5. Replace the template file in your project

#### 2. **Missing Dependencies**
**Error**: `No such module 'Firebase'`

**Solution**:
- Xcode should automatically resolve Swift Package Manager dependencies
- If not, go to **File > Add Package Dependencies** and add:
  ```
  https://github.com/firebase/firebase-ios-sdk
  ```

#### 3. **Build Errors in New Files**
**Error**: Various Swift compilation errors

**Solution**:
```bash
# Clean build folder
⌘⇧K (or Product > Clean Build Folder)

# Reset package caches
File > Packages > Reset Package Caches

# Try building again
⌘R
```

#### 4. **Simulator Not Available**
**Error**: No simulators in device list

**Solution**:
```bash
# Install iOS Simulator
xcode-select --install

# Or in Xcode:
# Window > Devices and Simulators > Simulators > + (Add new simulator)
```

## 🎯 Testing the New Features

Once the app is running, you can test all the new features:

### **1. Goal Timeline & Progress Logging**
1. Create a new goal
2. Add tasks linked to that goal
3. Complete the tasks
4. Tap on the goal to see the timeline entries

### **2. Improved Layout**
- Notice the app content sits higher on screen
- Floating action button is properly positioned
- Better spacing throughout the app

### **3. Goal Categories/Dividers**
1. Go to Goals tab
2. Tap the "+" menu → "New Category"
3. Create categories with custom colors/icons
4. Create goals and assign them to categories

### **4. Hold and Drag Event Creation**
1. Go to Calendar tab
2. **Hold and drag** on the calendar picker
3. Release to create an event for that date
4. The event creation form opens with the date pre-filled

### **5. Groups with Member Suggestions**
1. Go to Groups tab (if available)
2. Tap "Create Group"
3. Tap "Add Members" 
4. See the working search and suggestions

## 📱 Simulator Controls

### Useful Simulator Shortcuts:
- **⌘R**: Run/Restart app
- **⌘⇧H**: Go to home screen
- **⌘⇧A**: Open App Library
- **⌘K**: Toggle software keyboard
- **⌘→**: Rotate device right
- **⌘←**: Rotate device left

### Device Menu:
- **Device > Shake**: Simulate device shake
- **Device > Location**: Simulate location changes
- **Device > Appearance**: Toggle Dark/Light mode

## 🐛 Debugging Tips

### If App Crashes:
1. **Check Console**: View > Debug Area > Show Debug Area
2. **Look for red errors** in the console
3. **Common issues**:
   - Firebase not configured
   - Missing user authentication
   - Data model conflicts

### Performance Testing:
1. **Instruments**: Product > Profile
2. **Memory usage**: Watch for memory leaks
3. **CPU usage**: Monitor during heavy operations

## 🔄 Hot Reload Alternative

For faster development, you can use:
1. **SwiftUI Previews**: Click "Resume" in preview canvas
2. **Live Preview**: Pin preview to see changes instantly
3. **Simulator**: Keep running and use ⌘R to reload

## 📊 Features to Test

### **Timeline System**:
- [ ] Create goal with tasks
- [ ] Complete tasks and see timeline entries
- [ ] Check progress logging
- [ ] View detailed timeline in goal detail

### **Layout Improvements**:
- [ ] Check content positioning on different devices
- [ ] Test floating button placement
- [ ] Verify safe area handling

### **Goal Categories**:
- [ ] Create custom categories
- [ ] Assign goals to categories
- [ ] Test category organization

### **Calendar Drag**:
- [ ] Hold and drag on calendar
- [ ] Verify event creation with correct date
- [ ] Test haptic feedback

### **Groups**:
- [ ] Create group with members
- [ ] Test member search functionality
- [ ] Verify suggestions appear

## 🚨 Troubleshooting

### Build Successful but App Won't Launch:
1. **Reset Simulator**: Device > Erase All Content and Settings
2. **Clean Build**: ⌘⇧K then ⌘R
3. **Restart Xcode**: Quit and reopen Xcode

### Firebase Authentication Issues:
1. Check Firebase Auth is enabled in console
2. Verify bundle ID matches Firebase project
3. Ensure GoogleService-Info.plist is properly added

### UI Layout Issues:
1. Test on different simulator sizes
2. Check safe area constraints
3. Verify Auto Layout is working

---

## 🎉 Ready to Run!

Your AreaBook app now includes:
- ✅ Goal timeline and progress logging
- ✅ Improved screen positioning
- ✅ Goal categories with custom dividers
- ✅ Hold-and-drag event creation
- ✅ Working group member suggestions

**Run the app and enjoy testing all the new features!**