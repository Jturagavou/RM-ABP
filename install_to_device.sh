#!/bin/bash

echo "📱 AreaBook App Installation Script"
echo "==================================="
echo ""

# Step 1: Check if device is connected
echo "🔍 Step 1: Checking for connected devices..."
DEVICES=$(xcrun devicectl list devices 2>/dev/null)
if [ $? -eq 0 ]; then
    echo "✅ Device control available"
    echo "$DEVICES"
    DEVICE_ID=$(echo "$DEVICES" | grep -E "iPhone|iPad" | head -1 | awk '{print $1}')
    if [ ! -z "$DEVICE_ID" ]; then
        echo "📱 Found device: $DEVICE_ID"
    else
        echo "❌ No iPhone/iPad found"
    fi
else
    echo "❌ xcrun devicectl not available, using alternative methods"
fi
echo ""

# Step 2: Find the project
echo "🔍 Step 2: Looking for AreaBook project..."
if [ -f "AreaBook.xcodeproj/project.pbxproj" ]; then
    echo "✅ Found AreaBook.xcodeproj"
    PROJECT_PATH="AreaBook.xcodeproj"
elif [ -f "AreaBook.xcworkspace/contents.xcworkspacedata" ]; then
    echo "✅ Found AreaBook.xcworkspace"
    PROJECT_PATH="AreaBook.xcworkspace"
else
    echo "❌ AreaBook project not found in current directory"
    echo "Please run this script from your AreaBook project folder"
    exit 1
fi
echo ""

# Step 3: Check for built app
echo "🔍 Step 3: Looking for built app..."
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "AreaBook.app" -type d 2>/dev/null | head -1)
if [ ! -z "$APP_PATH" ]; then
    echo "✅ Found app at: $APP_PATH"
else
    echo "❌ AreaBook.app not found. Building first..."
    echo ""
    echo "🔨 Building AreaBook..."
    
    # Get list of available devices for destination
    echo "Available devices:"
    xcrun xcodebuild -project "$PROJECT_PATH" -scheme AreaBook -showdestinations | grep "platform:iOS" | head -5
    echo ""
    
    # Build for device
    echo "Building for device..."
    if [[ "$PROJECT_PATH" == *.xcworkspace ]]; then
        xcrun xcodebuild -workspace "$PROJECT_PATH" -scheme AreaBook -configuration Debug -destination 'generic/platform=iOS' build
    else
        xcrun xcodebuild -project "$PROJECT_PATH" -scheme AreaBook -configuration Debug -destination 'generic/platform=iOS' build
    fi
    
    # Check if build succeeded
    APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "AreaBook.app" -type d 2>/dev/null | head -1)
    if [ ! -z "$APP_PATH" ]; then
        echo "✅ Build successful! App at: $APP_PATH"
    else
        echo "❌ Build failed. Check the output above for errors."
        exit 1
    fi
fi
echo ""

# Step 4: Install to device
echo "🚀 Step 4: Installing to device..."
if [ ! -z "$DEVICE_ID" ] && [ ! -z "$APP_PATH" ]; then
    echo "Installing $APP_PATH to device $DEVICE_ID..."
    xcrun devicectl device install app --device "$DEVICE_ID" "$APP_PATH"
    
    if [ $? -eq 0 ]; then
        echo "✅ Installation successful!"
        echo ""
        echo "📱 Next steps on your iPhone:"
        echo "1. Go to Settings > General > VPN & Device Management"
        echo "2. Find your developer profile and trust it"
        echo "3. Look for AreaBook on your home screen or App Library"
    else
        echo "❌ Installation failed"
    fi
else
    echo "❌ Cannot install - missing device ID or app path"
    echo ""
    echo "Manual installation steps:"
    echo "1. Open Xcode"
    echo "2. Make sure your iPhone is selected (top left)"
    echo "3. Press ⌘R (Product > Run)"
    echo "4. Watch for 'Installing...' in the status bar"
fi
echo ""

# Step 5: Verification
echo "🔍 Step 5: Verification steps..."
echo "Run these checks on your iPhone:"
echo "1. Settings > General > VPN & Device Management"
echo "   - Should show your developer profile"
echo "   - Trust the profile if present"
echo ""
echo "2. Check for the app:"
echo "   - Look on home screen"
echo "   - Swipe left to App Library"
echo "   - Search 'AreaBook' in Spotlight"
echo ""
echo "3. If still not found:"
echo "   - Restart your iPhone"
echo "   - Try running this script again"
echo "   - Use Xcode: Window > Devices and Simulators"
echo ""

echo "🎯 Installation script completed!"