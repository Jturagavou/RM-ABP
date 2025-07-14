#!/bin/bash

# AreaBook Build Fix Script
# This script identifies and fixes common Swift compilation issues

echo "🔧 AreaBook Build Fix Script Starting..."
echo "========================================"

# Function to check for duplicate extensions
check_duplicate_extensions() {
    echo "📋 Checking for duplicate extensions..."
    
    # Check for duplicate Date extensions
    date_extensions=$(find . -name "*.swift" -exec grep -l "extension Date" {} \; | wc -l)
    if [ "$date_extensions" -gt 1 ]; then
        echo "⚠️  Found multiple Date extensions - potential redeclaration issue"
        find . -name "*.swift" -exec grep -n "extension Date" {} +
    else
        echo "✅ No duplicate Date extensions found"
    fi
    
    # Check for duplicate iso8601String properties
    iso_properties=$(find . -name "*.swift" -exec grep -l "var iso8601String" {} \; | wc -l)
    if [ "$iso_properties" -gt 1 ]; then
        echo "⚠️  Found multiple iso8601String properties - potential redeclaration issue"
        find . -name "*.swift" -exec grep -n "var iso8601String" {} +
    else
        echo "✅ No duplicate iso8601String properties found"
    fi
}

# Function to check for missing imports
check_missing_imports() {
    echo "📋 Checking for missing imports..."
    
    # Check files that use Firebase but might be missing imports
    for file in $(find . -name "*.swift"); do
        if grep -q "Firestore\|Auth\|Firebase" "$file" && ! grep -q "import Firebase" "$file"; then
            echo "⚠️  $file uses Firebase but missing import"
        fi
        
        if grep -q "SwiftUI\|View\|@State\|@Published" "$file" && ! grep -q "import SwiftUI" "$file"; then
            echo "⚠️  $file uses SwiftUI but missing import"
        fi
        
        if grep -q "Combine\|@Published\|AnyCancellable" "$file" && ! grep -q "import Combine" "$file"; then
            echo "⚠️  $file uses Combine but missing import"
        fi
    done
}

# Function to check for syntax issues
check_syntax_issues() {
    echo "📋 Checking for common syntax issues..."
    
    # Check for unmatched braces
    for file in $(find . -name "*.swift"); do
        open_braces=$(grep -o "{" "$file" | wc -l)
        close_braces=$(grep -o "}" "$file" | wc -l)
        if [ "$open_braces" -ne "$close_braces" ]; then
            echo "⚠️  $file has unmatched braces: $open_braces open, $close_braces close"
        fi
    done
    
    # Check for incomplete function signatures
    grep -n "func.*{$" $(find . -name "*.swift") | head -10
}

# Function to fix common issues
fix_common_issues() {
    echo "🔧 Applying common fixes..."
    
    # Ensure all Swift files have proper imports
    for file in $(find . -name "*.swift"); do
        # Add Foundation import if missing but needed
        if grep -q "Date\|URL\|UUID\|JSONEncoder\|JSONDecoder" "$file" && ! grep -q "import Foundation" "$file"; then
            sed -i '1i import Foundation' "$file"
            echo "✅ Added Foundation import to $file"
        fi
    done
}

# Function to validate project structure
validate_project_structure() {
    echo "📋 Validating project structure..."
    
    required_files=(
        "AreaBook/App/AreaBookApp.swift"
        "AreaBook/Models/Models.swift"
        "AreaBook/ViewModels/AuthViewModel.swift"
        "AreaBook/Services/DataManager.swift"
        "AreaBook/Services/FirebaseService.swift"
        "AreaBook/Views/ContentView.swift"
    )
    
    for file in "${required_files[@]}"; do
        if [ -f "$file" ]; then
            echo "✅ $file exists"
        else
            echo "❌ $file missing"
        fi
    done
}

# Function to check for Firebase configuration
check_firebase_config() {
    echo "📋 Checking Firebase configuration..."
    
    if [ -f "AreaBook/GoogleService-Info.plist" ]; then
        if grep -q "YOUR_API_KEY" "AreaBook/GoogleService-Info.plist"; then
            echo "⚠️  GoogleService-Info.plist contains template values - needs real Firebase config"
        else
            echo "✅ GoogleService-Info.plist appears to be configured"
        fi
    else
        echo "❌ GoogleService-Info.plist missing"
    fi
}

# Function to generate build report
generate_build_report() {
    echo "📊 Generating build readiness report..."
    
    total_swift_files=$(find . -name "*.swift" | wc -l)
    total_lines=$(find . -name "*.swift" -exec wc -l {} + | tail -1 | awk '{print $1}')
    
    echo "========================================"
    echo "📊 BUILD READINESS REPORT"
    echo "========================================"
    echo "Total Swift files: $total_swift_files"
    echo "Total lines of code: $total_lines"
    echo ""
    echo "Core Components Status:"
    echo "- Authentication: $([ -f "AreaBook/ViewModels/AuthViewModel.swift" ] && echo "✅" || echo "❌")"
    echo "- Data Management: $([ -f "AreaBook/Services/DataManager.swift" ] && echo "✅" || echo "❌")"
    echo "- Firebase Service: $([ -f "AreaBook/Services/FirebaseService.swift" ] && echo "✅" || echo "❌")"
    echo "- Main Views: $([ -f "AreaBook/Views/ContentView.swift" ] && echo "✅" || echo "❌")"
    echo "- Models: $([ -f "AreaBook/Models/Models.swift" ] && echo "✅" || echo "❌")"
    echo ""
    echo "Next Steps:"
    echo "1. Set up Firebase project and replace GoogleService-Info.plist"
    echo "2. Create Xcode project and add source files"
    echo "3. Configure Swift Package Manager dependencies"
    echo "4. Build and test the application"
    echo "========================================"
}

# Main execution
main() {
    check_duplicate_extensions
    echo ""
    check_missing_imports
    echo ""
    check_syntax_issues
    echo ""
    validate_project_structure
    echo ""
    check_firebase_config
    echo ""
    fix_common_issues
    echo ""
    generate_build_report
    
    echo ""
    echo "🎉 Build fix script completed!"
    echo "Review the output above for any issues that need manual attention."
}

# Run the main function
main