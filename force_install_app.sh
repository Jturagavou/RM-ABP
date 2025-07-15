#!/bin/bash

echo "🚀 Force Install AreaBook App"
echo "============================="
echo ""

# Get device ID
echo "1. Finding connected devices..."
DEVICE_ID=$(xcrun devicectl list devices | grep -E "iPhone|iPad" | head -1 | awk '{print $1}')
echo "Device ID: $DEVICE_ID"
echo ""

# Find the app bundle
echo "2. Finding AreaBook.app bundle..."
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "AreaBook.app" -type d | head -1)
echo "App path: $APP_PATH"
echo ""

if [ -z "$APP_PATH" ]; then
    echo "❌ AreaBook.app not found. Need to build first."
    echo "Run this in Xcode:"
    echo "1. Product > Clean Build Folder"
    echo "2. Product > Build (NOT Run)"
    echo "3. Make sure your device is selected as destination"
    exit 1
fi

# Install the app
echo "3. Installing app to device..."
if [ ! -z "$DEVICE_ID" ]; then
    xcrun devicectl device install app --device "$DEVICE_ID" "$APP_PATH"
    echo ""
    echo "4. Checking if app is installed..."
    xcrun devicectl device list apps --device "$DEVICE_ID" | grep -i areabook
else
    echo "❌ No device found. Make sure your iPhone is connected and trusted."
    echo ""
    echo "Alternative installation methods:"
    echo "1. Use Xcode: Product > Run (⌘R)"
    echo "2. Use Xcode: Window > Devices and Simulators > Install App"
    echo "3. Drag .app file to device in Devices window"
fi

echo ""
echo "If app still doesn't appear:"
echo "1. Check Settings > General > VPN & Device Management"
echo "2. Trust your developer profile"
echo "3. Restart your iPhone"
echo "4. Look in App Library (swipe left from last home screen)"
echo "5. Search for 'AreaBook' using Spotlight"