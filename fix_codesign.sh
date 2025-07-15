#!/bin/bash

echo "🔧 iOS Codesign Fix Script"
echo "=========================="
echo "Run this script on your Mac to fix codesign login issues"
echo ""

# Step 1: Basic Keychain Fixes
echo "Step 1: Fixing Keychain Issues..."
security unlock-keychain ~/Library/Keychains/login.keychain
security set-keychain-settings ~/Library/Keychains/login.keychain
security default-keychain -s ~/Library/Keychains/login.keychain
security list-keychains -s ~/Library/Keychains/login.keychain ~/Library/Keychains/System.keychain

# Step 2: Kill Xcode Processes
echo "Step 2: Stopping Xcode processes..."
killall Xcode 2>/dev/null || true
killall Simulator 2>/dev/null || true
killall "iOS Simulator" 2>/dev/null || true

# Step 3: Clean Xcode Data
echo "Step 3: Cleaning Xcode data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf ~/Library/MobileDevice/Provisioning\ Profiles/*
rm -rf ~/Library/Developer/Xcode/iOS\ DeviceSupport/*
rm -rf ~/Library/Developer/Xcode/Archives/*
rm -rf ~/Library/Developer/CoreSimulator/Caches/*
rm -rf ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex/*

# Step 4: Check Certificates
echo "Step 4: Checking certificates..."
echo "Your development certificates:"
security find-identity -v -p codesigning | grep "Apple Development"

# Step 5: Reset Xcode Command Line Tools
echo "Step 5: Resetting Xcode command line tools..."
sudo xcode-select --reset
echo "You may need to run: sudo xcode-select --install"

# Step 6: Clean System Caches
echo "Step 6: Cleaning system caches..."
sudo rm -rf /var/db/DetachedSignatures 2>/dev/null || true
sudo rm -rf /System/Library/Caches/com.apple.coresymbolicationd 2>/dev/null || true

# Step 7: Reset Xcode Preferences
echo "Step 7: Resetting Xcode preferences..."
defaults delete com.apple.dt.Xcode 2>/dev/null || true
defaults delete com.apple.dt.xcodebuild 2>/dev/null || true

# Step 8: Download Apple Root Certificate
echo "Step 8: Downloading Apple root certificate..."
curl -O https://developer.apple.com/certificationauthority/AppleWWDRCA.cer
security import AppleWWDRCA.cer -k ~/Library/Keychains/login.keychain -T /usr/bin/codesign 2>/dev/null || true
rm AppleWWDRCA.cer

echo ""
echo "✅ Script completed!"
echo ""
echo "Next steps:"
echo "1. Open Xcode"
echo "2. Go to Xcode > Preferences > Accounts"
echo "3. Remove and re-add your Apple ID"
echo "4. Go to your project settings > Signing & Capabilities"
echo "5. Toggle 'Automatically manage signing' off and on"
echo "6. Select your team and provisioning profile"
echo "7. Clean build folder (Product > Clean Build Folder)"
echo "8. Try building to your device again"
echo ""
echo "If still having issues, check:"
echo "- Your Apple Developer account is active"
echo "- Your device is registered in your developer account"
echo "- Your certificates haven't expired"