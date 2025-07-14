#!/bin/bash

# Fix missing imports in all view files

echo "🔧 Fixing missing imports in view files..."

# List of files that need Firebase imports
firebase_files=(
    "AreaBook/Views/Settings/SettingsView.swift"
    "AreaBook/Views/Goals/CreateGoalView.swift"
    "AreaBook/Views/Goals/GoalsView.swift"
    "AreaBook/Views/Onboarding/OnboardingFlow.swift"
    "AreaBook/Views/Groups/GroupsView.swift"
    "AreaBook/Views/Notes/NotesView.swift"
    "AreaBook/Views/Calendar/CalendarView.swift"
    "AreaBook/Views/Calendar/CreateEventView.swift"
    "AreaBook/Views/Dashboard/DashboardView.swift"
    "AreaBook/Views/Auth/AuthenticationView.swift"
    "AreaBook/Views/KeyIndicators/CreateKeyIndicatorView.swift"
    "AreaBook/Views/Tasks/CreateTaskView.swift"
    "AreaBook/Views/Tasks/TasksView.swift"
)

# Fix Firebase imports
for file in "${firebase_files[@]}"; do
    if [ -f "$file" ]; then
        # Check if Firebase import is missing
        if grep -q "Firestore\|Auth\|Firebase" "$file" && ! grep -q "import Firebase" "$file"; then
            # Add Firebase import after SwiftUI import
            sed -i '/import SwiftUI/a import Firebase\nimport FirebaseFirestore' "$file"
            echo "✅ Added Firebase imports to $file"
        fi
        
        # Check if Combine import is missing but needed
        if grep -q "Combine\|@Published\|AnyCancellable" "$file" && ! grep -q "import Combine" "$file"; then
            sed -i '/import SwiftUI/a import Combine' "$file"
            echo "✅ Added Combine import to $file"
        fi
    fi
done

# Special case for OnboardingFlow.swift which needs Combine
if [ -f "AreaBook/Views/Onboarding/OnboardingFlow.swift" ]; then
    if ! grep -q "import Combine" "AreaBook/Views/Onboarding/OnboardingFlow.swift"; then
        sed -i '/import SwiftUI/a import Combine' "AreaBook/Views/Onboarding/OnboardingFlow.swift"
        echo "✅ Added Combine import to OnboardingFlow.swift"
    fi
fi

echo "🎉 Import fixes completed!"