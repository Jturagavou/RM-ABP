#!/bin/bash

echo "🚀 Quick Codesign Fix"
echo "===================="
echo ""

# Quick fixes that solve 90% of codesign issues
echo "1. Unlocking keychain..."
security unlock-keychain ~/Library/Keychains/login.keychain

echo "2. Setting keychain to never lock..."
security set-keychain-settings ~/Library/Keychains/login.keychain

echo "3. Killing Xcode..."
killall Xcode 2>/dev/null || true

echo "4. Cleaning derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*

echo "5. Cleaning provisioning profiles..."
rm -rf ~/Library/MobileDevice/Provisioning\ Profiles/*

echo "6. Checking your certificates..."
security find-identity -v -p codesigning | grep "Apple Development"

echo ""
echo "✅ Quick fix completed!"
echo ""
echo "Now try:"
echo "1. Open Xcode"
echo "2. Go to your project > Signing & Capabilities"
echo "3. Toggle 'Automatically manage signing' off and on"
echo "4. Build to your device"