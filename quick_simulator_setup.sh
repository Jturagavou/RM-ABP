#!/bin/bash

echo "🚀 AreaBook Quick Simulator Setup"
echo "================================="
echo ""

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ This script is designed for macOS only"
    echo "Please run this on your Mac with Xcode installed"
    exit 1
fi

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode is not installed or not in PATH"
    echo "Please install Xcode from the App Store"
    exit 1
fi

echo "✅ Xcode found"

# Check if project exists
if [ ! -f "AreaBook.xcodeproj/project.pbxproj" ]; then
    echo "❌ AreaBook.xcodeproj not found"
    echo "Please run this script from the AreaBook project directory"
    exit 1
fi

echo "✅ AreaBook project found"

# Check for Firebase configuration
if [ ! -f "AreaBook/GoogleService-Info.plist" ]; then
    echo "⚠️  GoogleService-Info.plist not found"
    echo "You'll need to:"
    echo "1. Go to https://console.firebase.google.com"
    echo "2. Create/select a Firebase project"
    echo "3. Add iOS app with bundle ID: com.areabook.app"
    echo "4. Download GoogleService-Info.plist"
    echo "5. Replace the template file in AreaBook/"
    echo ""
    read -p "Continue anyway? (y/n): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    echo "✅ Firebase configuration found"
fi

# List available simulators
echo ""
echo "📱 Available iOS Simulators:"
xcrun simctl list devices iOS | grep -E "\s+iPhone|iPad" | head -10

echo ""
echo "🔧 Setting up for simulator run..."

# Clean any previous builds
echo "Cleaning previous builds..."
xcodebuild clean -project AreaBook.xcodeproj -scheme AreaBook > /dev/null 2>&1

# Get the first available iPhone simulator
SIMULATOR_ID=$(xcrun simctl list devices iOS | grep "iPhone" | head -1 | grep -E -o "\([0-9A-F-]{36}\)" | tr -d "()")

if [ -z "$SIMULATOR_ID" ]; then
    echo "❌ No iPhone simulator found"
    echo "Please install iOS Simulator through Xcode"
    exit 1
fi

SIMULATOR_NAME=$(xcrun simctl list devices iOS | grep "$SIMULATOR_ID" | sed 's/.*iPhone/iPhone/' | sed 's/ (.*//')
echo "🎯 Using simulator: $SIMULATOR_NAME"

# Build and run
echo ""
echo "🏗️  Building AreaBook for simulator..."
echo "This may take a few minutes..."

xcodebuild build -project AreaBook.xcodeproj -scheme AreaBook -destination "id=$SIMULATOR_ID" | grep -E "(error|warning|succeeded|failed)" || echo "Building..."

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo ""
    echo "🚀 Launching in simulator..."
    
    # Boot simulator if not already running
    xcrun simctl boot "$SIMULATOR_ID" > /dev/null 2>&1
    
    # Open simulator app
    open -a Simulator
    
    # Install and run the app
    xcodebuild run -project AreaBook.xcodeproj -scheme AreaBook -destination "id=$SIMULATOR_ID" > /dev/null 2>&1 &
    
    echo "✅ AreaBook should now be launching in the simulator!"
    echo ""
    echo "🎯 Test the new features:"
    echo "1. Goal timeline and progress logging"
    echo "2. Improved layout positioning"
    echo "3. Goal categories with custom dividers"
    echo "4. Hold-and-drag event creation in Calendar"
    echo "5. Groups with member suggestions"
    echo ""
    echo "📱 Simulator controls:"
    echo "- ⌘R: Restart app"
    echo "- ⌘⇧H: Home screen"
    echo "- ⌘K: Toggle keyboard"
    echo ""
    echo "🐛 If issues occur:"
    echo "- Check Xcode console for errors"
    echo "- Ensure Firebase is configured"
    echo "- Try: Product > Clean Build Folder"
    
else
    echo "❌ Build failed"
    echo ""
    echo "🔧 Troubleshooting steps:"
    echo "1. Open AreaBook.xcodeproj in Xcode"
    echo "2. Check for build errors in the issue navigator"
    echo "3. Ensure all dependencies are resolved"
    echo "4. Try Product > Clean Build Folder"
    echo "5. Check Firebase configuration"
    echo ""
    echo "📖 See run_in_simulator.md for detailed troubleshooting"
fi