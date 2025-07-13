#!/bin/bash

echo "🔍 AreaBook App Status Check"
echo "=========================="
echo "Time: $(date)"
echo ""

# Check Swift files
echo "📱 Swift Files:"
swift_count=$(find . -name "*.swift" | wc -l)
echo "  Found: $swift_count Swift files"
find . -name "*.swift" | while read file; do
    lines=$(wc -l < "$file")
    echo "  ✅ $file ($lines lines)"
done
echo ""

# Check critical missing files
echo "🚨 Critical Missing Files:"
missing_files=("AuthViewModel.swift" "LoginView.swift" "MainTabView.swift" "GoogleService-Info.plist" "AreaBook.xcodeproj")
for file in "${missing_files[@]}"; do
    if [ ! -e "$file" ]; then
        echo "  ❌ $file"
    else
        echo "  ✅ $file"
    fi
done
echo ""

# Check project structure
echo "📂 Project Structure:"
if [ -d "AreaBook.xcodeproj" ] || [ -d "AreaBook.xcworkspace" ]; then
    echo "  ✅ Xcode project exists"
else
    echo "  ❌ No Xcode project found"
fi

if [ -f "Podfile" ] || [ -f "Package.swift" ]; then
    echo "  ✅ Dependency file exists"
else
    echo "  ❌ No dependency management file"
fi

if [ -f "GoogleService-Info.plist" ]; then
    echo "  ✅ Firebase configured"
else
    echo "  ❌ Firebase not configured"
fi
echo ""

# Overall status
echo "📊 Overall Status:"
if [ $swift_count -lt 10 ]; then
    echo "  ❌ Incomplete - Need more Swift files"
elif [ ! -f "GoogleService-Info.plist" ]; then
    echo "  ⚠️  Almost ready - Need Firebase config"
elif [ ! -d "AreaBook.xcodeproj" ]; then
    echo "  ⚠️  Almost ready - Need Xcode project"
else
    echo "  ✅ Ready for testing"
fi

echo ""
echo "💡 Run this script anytime to check progress!"
echo "📋 See AreaBook_Test_Errors.md for detailed issues"