#!/bin/bash

# Comprehensive Build Validation Script for AreaBook
# This script validates that the codebase is ready for compilation

echo "🔍 AreaBook Build Validation Starting..."
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
ERRORS=0
WARNINGS=0
CHECKS=0

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    CHECKS=$((CHECKS + 1))
    
    case $status in
        "PASS")
            echo -e "${GREEN}✅ $message${NC}"
            ;;
        "WARN")
            echo -e "${YELLOW}⚠️  $message${NC}"
            WARNINGS=$((WARNINGS + 1))
            ;;
        "FAIL")
            echo -e "${RED}❌ $message${NC}"
            ERRORS=$((ERRORS + 1))
            ;;
        "INFO")
            echo -e "${BLUE}ℹ️  $message${NC}"
            ;;
    esac
}

# Check 1: Project Structure
echo -e "\n${BLUE}📁 Checking Project Structure...${NC}"
required_files=(
    "AreaBook/App/AreaBookApp.swift"
    "AreaBook/Models/Models.swift"
    "AreaBook/ViewModels/AuthViewModel.swift"
    "AreaBook/Services/DataManager.swift"
    "AreaBook/Services/FirebaseService.swift"
    "AreaBook/Views/ContentView.swift"
    "AreaBook/Views/Auth/AuthenticationView.swift"
    "AreaBook/Views/Dashboard/DashboardView.swift"
    "AreaBook/Views/Goals/GoalsView.swift"
    "AreaBook/Views/Calendar/CalendarView.swift"
    "AreaBook/Views/Tasks/TasksView.swift"
    "AreaBook/Views/Notes/NotesView.swift"
    "AreaBook/Views/Settings/SettingsView.swift"
    "AreaBook/Widgets/AreaBookWidget.swift"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        print_status "PASS" "Required file exists: $file"
    else
        print_status "FAIL" "Missing required file: $file"
    fi
done

# Check 2: Import Statements
echo -e "\n${BLUE}📦 Checking Import Statements...${NC}"

# Check for missing Foundation imports
for file in $(find . -name "*.swift"); do
    if grep -q "Date\|URL\|UUID\|JSONEncoder\|JSONDecoder" "$file" && ! grep -q "import Foundation" "$file"; then
        print_status "FAIL" "Missing Foundation import: $file"
    fi
done

# Check for missing SwiftUI imports in view files
for file in $(find . -path "*/Views/*.swift" -o -path "*/Widgets/*.swift"); do
    if grep -q "View\|@State\|@Published\|@ObservedObject" "$file" && ! grep -q "import SwiftUI" "$file"; then
        print_status "FAIL" "Missing SwiftUI import: $file"
    fi
done

# Check for missing Firebase imports (exclude Package.swift)
for file in $(find . -name "*.swift" ! -name "Package.swift"); do
    if grep -q "Firestore\|Auth\|Firebase" "$file" && ! grep -q "import Firebase" "$file"; then
        print_status "FAIL" "Missing Firebase import: $file"
    fi
done

# Check for missing Combine imports
for file in $(find . -name "*.swift"); do
    if grep -q "@Published\|AnyCancellable\|PassthroughSubject" "$file" && ! grep -q "import Combine" "$file"; then
        print_status "FAIL" "Missing Combine import: $file"
    fi
done

if [ $ERRORS -eq 0 ]; then
    print_status "PASS" "All import statements appear correct"
fi

# Check 3: Syntax Validation
echo -e "\n${BLUE}🔍 Checking Syntax Issues...${NC}"

# Check for unmatched braces
for file in $(find . -name "*.swift"); do
    open_braces=$(grep -o "{" "$file" | wc -l)
    close_braces=$(grep -o "}" "$file" | wc -l)
    if [ "$open_braces" -ne "$close_braces" ]; then
        print_status "FAIL" "Unmatched braces in $file: $open_braces open, $close_braces close"
    fi
done

# Check for duplicate extensions
date_extensions=$(find . -name "*.swift" -exec grep -l "extension Date" {} \; | wc -l)
if [ "$date_extensions" -gt 1 ]; then
    print_status "WARN" "Multiple Date extensions found - potential redeclaration"
    find . -name "*.swift" -exec grep -n "extension Date" {} +
else
    print_status "PASS" "No duplicate Date extensions"
fi

# Check for duplicate iso8601String properties
iso_properties=$(find . -name "*.swift" -exec grep -l "var iso8601String" {} \; | wc -l)
if [ "$iso_properties" -gt 1 ]; then
    print_status "FAIL" "Multiple iso8601String properties found - redeclaration error"
else
    print_status "PASS" "No duplicate iso8601String properties"
fi

# Check 4: Firebase Configuration
echo -e "\n${BLUE}🔥 Checking Firebase Configuration...${NC}"

if [ -f "AreaBook/GoogleService-Info.plist" ]; then
    if grep -q "YOUR_API_KEY\|YOUR_PROJECT_ID\|YOUR_CLIENT_ID" "AreaBook/GoogleService-Info.plist"; then
        print_status "WARN" "GoogleService-Info.plist contains template values - needs real Firebase config"
    else
        print_status "PASS" "GoogleService-Info.plist appears to be configured"
    fi
else
    print_status "FAIL" "GoogleService-Info.plist missing"
fi

# Check 5: Dependencies
echo -e "\n${BLUE}📋 Checking Dependencies...${NC}"

if [ -f "Package.swift" ]; then
    print_status "PASS" "Package.swift exists"
    
    # Check for required Firebase dependencies
    if grep -q "firebase-ios-sdk" "Package.swift"; then
        print_status "PASS" "Firebase iOS SDK dependency found"
    else
        print_status "FAIL" "Firebase iOS SDK dependency missing"
    fi
    
    if grep -q "FirebaseAuth" "Package.swift"; then
        print_status "PASS" "FirebaseAuth dependency found"
    else
        print_status "FAIL" "FirebaseAuth dependency missing"
    fi
    
    if grep -q "FirebaseFirestore" "Package.swift"; then
        print_status "PASS" "FirebaseFirestore dependency found"
    else
        print_status "FAIL" "FirebaseFirestore dependency missing"
    fi
else
    print_status "FAIL" "Package.swift missing"
fi

# Check 6: Code Quality
echo -e "\n${BLUE}🧹 Checking Code Quality...${NC}"

# Check for TODO and FIXME comments
todo_count=$(find . -name "*.swift" -exec grep -c "TODO\|FIXME" {} + | awk '{sum += $1} END {print sum}')
if [ "$todo_count" -gt 0 ]; then
    print_status "WARN" "Found $todo_count TODO/FIXME comments"
else
    print_status "PASS" "No TODO/FIXME comments found"
fi

# Check for print statements (should use proper logging)
print_count=$(find . -name "*.swift" -exec grep -c "print(" {} + | awk '{sum += $1} END {print sum}')
if [ "$print_count" -gt 0 ]; then
    print_status "WARN" "Found $print_count print statements - consider using proper logging"
else
    print_status "PASS" "No print statements found"
fi

# Generate Statistics
echo -e "\n${BLUE}📊 Generating Project Statistics...${NC}"
total_swift_files=$(find . -name "*.swift" | wc -l)
total_lines=$(find . -name "*.swift" -exec wc -l {} + | tail -1 | awk '{print $1}')
view_files=$(find . -path "*/Views/*.swift" | wc -l)
service_files=$(find . -path "*/Services/*.swift" | wc -l)
model_files=$(find . -path "*/Models/*.swift" | wc -l)

print_status "INFO" "Total Swift files: $total_swift_files"
print_status "INFO" "Total lines of code: $total_lines"
print_status "INFO" "View files: $view_files"
print_status "INFO" "Service files: $service_files"
print_status "INFO" "Model files: $model_files"

# Final Report
echo -e "\n${BLUE}📋 BUILD VALIDATION REPORT${NC}"
echo "=========================================="
echo -e "Total Checks: $CHECKS"
echo -e "Errors: ${RED}$ERRORS${NC}"
echo -e "Warnings: ${YELLOW}$WARNINGS${NC}"
echo -e "Passed: ${GREEN}$((CHECKS - ERRORS - WARNINGS))${NC}"
echo ""

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}🎉 BUILD VALIDATION PASSED!${NC}"
    echo "The codebase appears ready for compilation."
    echo ""
    echo "Next Steps:"
    echo "1. Set up Firebase project and replace GoogleService-Info.plist"
    echo "2. Create Xcode project and add source files"
    echo "3. Configure Swift Package Manager dependencies"
    echo "4. Build and test the application"
else
    echo -e "${RED}❌ BUILD VALIDATION FAILED!${NC}"
    echo "Please fix the $ERRORS error(s) before attempting to build."
fi

if [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}⚠️  $WARNINGS warning(s) found - review recommended${NC}"
fi

echo "=========================================="

# Exit with appropriate code
if [ $ERRORS -eq 0 ]; then
    exit 0
else
    exit 1
fi