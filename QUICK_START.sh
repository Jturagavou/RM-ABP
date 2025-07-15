#!/bin/bash

echo "🚀 AreaBook Quick Start Script"
echo "================================"

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ This script requires macOS to run iOS apps"
    echo "Please run this on a Mac with Xcode installed"
    exit 1
fi

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode is not installed or not in PATH"
    echo "Please install Xcode from the App Store"
    exit 1
fi

# Check if we have the project file
if [ ! -f "AreaBook.xcodeproj/project.pbxproj" ]; then
    echo "❌ AreaBook.xcodeproj not found"
    echo "Please make sure you're in the project directory"
    exit 1
fi

echo "✅ macOS detected"
echo "✅ Xcode found"
echo "✅ Project file found"

# Check for Firebase config
if [ ! -f "AreaBook/GoogleService-Info.plist" ]; then
    echo "⚠️  Firebase configuration not found"
    echo "The app will compile but won't have backend functionality"
    echo "To set up Firebase:"
    echo "1. Go to https://console.firebase.google.com/"
    echo "2. Create a new project"
    echo "3. Add iOS app with bundle ID: com.areabook.app"
    echo "4. Download GoogleService-Info.plist"
    echo "5. Replace the template file in AreaBook/"
    echo ""
    read -p "Continue without Firebase? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    echo "✅ Firebase configuration found"
fi

# List available simulators
echo ""
echo "📱 Available iOS Simulators:"
xcrun simctl list devices available | grep "iPhone\|iPad" | head -10

# Get the first available iPhone simulator
SIMULATOR=$(xcrun simctl list devices available | grep "iPhone" | head -1 | sed 's/.*(\([^)]*\)).*/\1/')

if [ -z "$SIMULATOR" ]; then
    echo "❌ No iPhone simulators found"
    echo "Please install iOS simulators through Xcode"
    exit 1
fi

echo ""
echo "🎯 Using simulator: $SIMULATOR"
echo ""

# Build and run the app
echo "🔨 Building AreaBook..."
xcodebuild -project AreaBook.xcodeproj \
           -scheme AreaBook \
           -destination "platform=iOS Simulator,id=$SIMULATOR" \
           -configuration Debug \
           build

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    
    # Boot the simulator if not already running
    echo "🚀 Starting simulator..."
    xcrun simctl boot "$SIMULATOR" 2>/dev/null
    
    # Open simulator app
    open -a Simulator
    
    # Install the app
    echo "📲 Installing AreaBook..."
    xcrun simctl install "$SIMULATOR" build/Debug-iphonesimulator/AreaBook.app
    
    # Launch the app
    echo "🎉 Launching AreaBook..."
    xcrun simctl launch "$SIMULATOR" com.areabook.app
    
    echo ""
    echo "✅ AreaBook is now running in the simulator!"
    echo ""
    echo "🎮 Quick Test Guide:"
    echo "1. Sign up with: test@example.com / password123"
    echo "2. Create a Key Indicator: 'Exercise' with target 7"
    echo "3. Create a Goal: 'Get Fit' and link to Exercise KI"
    echo "4. Create a Task: 'Go for a run' and link to the goal"
    echo "5. Complete the task and watch progress update"
    echo "6. Test the new features we added:"
    echo "   - Note Management (create notes with linking)"
    echo "   - Data Export (export your data to JSON)"
    echo "   - Help Content (comprehensive help system)"
    echo "   - Feedback System (submit feedback)"
    echo ""
    echo "🔧 To test widgets:"
    echo "1. Go to iOS home screen"
    echo "2. Long press to enter edit mode"
    echo "3. Tap + to add widget"
    echo "4. Search for 'AreaBook'"
    echo "5. Add widget to home screen"
    
else
    echo "❌ Build failed!"
    echo "Check the error messages above"
    echo ""
    echo "Common solutions:"
    echo "1. Clean build folder: Product → Clean Build Folder in Xcode"
    echo "2. Reset simulator: Device → Erase All Content and Settings"
    echo "3. Update Xcode to latest version"
    echo "4. Check Firebase configuration"
    exit 1
fi