# URGENT: Build System Using Old Code

## Problem
The app is crashing because it's running old checkpoint code, NOT the current fixed code.

## Evidence
1. Crash at: `let userData = try JSONSerialization.data(withJSONObject: data)`
2. This line EXISTS in `/workspace/checkpoints/AreaBook_2025-07-15_13-37-39/ViewModels/AuthViewModel.swift:85`
3. This line DOES NOT EXIST in current `/workspace/AreaBook/ViewModels/AuthViewModel.swift`

## Immediate Actions Required

### 1. Clean Everything
```bash
# In Xcode, use Product > Clean Build Folder (Cmd+Shift+K)
# Or from terminal:
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf /workspace/build
rm -rf /workspace/DerivedData
```

### 2. Ensure Correct Target
- Make sure Xcode is building from `/workspace/AreaBook/` NOT `/workspace/checkpoints/`
- Check Build Settings > Search Paths
- Remove any references to checkpoint directories

### 3. Verify Current Code is Being Used
The current AuthViewModel.swift (line 138) correctly uses:
```swift
if let user = User(dictionary: userData) {
```

NOT the problematic:
```swift
let userData = try JSONSerialization.data(withJSONObject: data)
```

### 4. Force Rebuild
1. Close Xcode completely
2. Delete DerivedData
3. Open Xcode
4. Clean Build Folder (Cmd+Shift+K)
5. Build and Run (Cmd+R)

## Verification
After rebuild, logs should show:
- "AuthViewModel configured"
- "AIService configured"
- "WidgetDataService configured"
- "CollaborationManager configured"

These are currently missing because old code is running.