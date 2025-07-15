#!/bin/bash

echo "🔍 iOS App Deployment Debug Script"
echo "=================================="
echo ""

# Check if app was actually installed
echo "1. Checking if app was installed to device..."
xcrun devicectl list devices
echo ""

# Check build settings
echo "2. Checking recent build logs..."
ls -la ~/Library/Developer/Xcode/DerivedData/*/Build/Products/Debug-iphoneos/*.app 2>/dev/null || echo "No Debug-iphoneos apps found"
ls -la ~/Library/Developer/Xcode/DerivedData/*/Build/Products/Release-iphoneos/*.app 2>/dev/null || echo "No Release-iphoneos apps found"
echo ""

# Check device logs
echo "3. Checking device installation logs..."
xcrun devicectl list devices --timeout 5
echo ""

# Check if app bundle exists
echo "4. Looking for AreaBook.app bundle..."
find ~/Library/Developer/Xcode/DerivedData -name "AreaBook.app" -type d 2>/dev/null
echo ""

# Check provisioning profiles
echo "5. Checking provisioning profiles..."
ls -la ~/Library/MobileDevice/Provisioning\ Profiles/ 2>/dev/null | head -5
echo ""

# Check certificates
echo "6. Checking code signing certificates..."
security find-identity -v -p codesigning | grep "Apple Development"
echo ""

echo "Manual checks to perform:"
echo "========================"
echo "1. On your iPhone:"
echo "   - Go to Settings > General > VPN & Device Management"
echo "   - Look for your developer profile"
echo "   - Tap it and select 'Trust [Your Name]'"
echo ""
echo "2. Check iPhone home screen:"
echo "   - App might be in App Library (swipe left from last home screen)"
echo "   - Search for 'AreaBook' using Spotlight search"
echo ""
echo "3. In Xcode:"
echo "   - Window > Devices and Simulators"
echo "   - Select your device"
echo "   - Look under 'Installed Apps' for AreaBook"
echo ""
echo "4. Try installing again:"
echo "   - Product > Clean Build Folder"
echo "   - Product > Build"
echo "   - Make sure your device is selected as destination"
echo ""
echo "5. Check Xcode console for errors:"
echo "   - View > Debug Area > Show Debug Area"
echo "   - Look for installation errors"