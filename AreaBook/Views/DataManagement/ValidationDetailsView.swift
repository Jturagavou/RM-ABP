import SwiftUI

struct ValidationDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var dataManager: DataManager
    @StateObject private var validationService = DataValidationService.shared
    
    @State private var selectedTab: ValidationTab = .overview
    @State private var showingFixSuggestions = false
    @State private var isRunningValidation = false
    @State private var validationResults: [String: ValidationResult] = [:]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Validation Status Header
                ValidationStatusHeader(
                    errorCount: totalErrorCount,
                    warningCount: totalWarningCount,
                    lastValidated: Date()
                )
                
                // Tab Selection
                ValidationTabSelector(selectedTab: $selectedTab)
                
                // Content based on selected tab
                ScrollView {
                    VStack(spacing: 16) {
                        switch selectedTab {
                        case .overview:
                            ValidationOverviewSection(
                                validationResults: validationResults,
                                onRunValidation: runCompleteValidation
                            )
                            
                        case .errors:
                            ValidationErrorsSection(
                                errors: allErrors,
                                onFixError: fixValidationError
                            )
                            
                        case .warnings:
                            ValidationWarningsSection(
                                warnings: allWarnings,
                                onFixWarning: fixValidationWarning
                            )
                            
                        case .suggestions:
                            ValidationSuggestionsSection(
                                suggestions: generateSuggestions()
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Data Validation")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button("Validate") {
                        runCompleteValidation()
                    }
                    .disabled(isRunningValidation)
                    
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                runCompleteValidation()
            }
            .overlay {
                if isRunningValidation {
                    ValidationOverlay()
                }
            }
        }
    }
    
    // MARK: - Validation Actions
    
    private func runCompleteValidation() {
        guard let userId = authViewModel.currentUser?.id else { return }
        
        isRunningValidation = true
        validationResults.removeAll()
        
        Task {
            // Validate all data types
            await validateGoals()
            await validateTasks()
            await validateEvents()
            await validateKeyIndicators()
            await validateGroups()
            await validateDataConsistency()
            
            await MainActor.run {
                isRunningValidation = false
            }
        }
    }
    
    private func validateGoals() async {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []
        
        for goal in dataManager.goals {
            let result = validationService.validateGoal(goal)
            errors.append(contentsOf: result.errors)
            warnings.append(contentsOf: result.warnings)
        }
        
        await MainActor.run {
            validationResults["Goals"] = ValidationResult(
                isValid: errors.isEmpty,
                errors: errors,
                warnings: warnings
            )
        }
    }
    
    private func validateTasks() async {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []
        
        for task in dataManager.tasks {
            let result = validationService.validateTask(task)
            errors.append(contentsOf: result.errors)
            warnings.append(contentsOf: result.warnings)
        }
        
        await MainActor.run {
            validationResults["Tasks"] = ValidationResult(
                isValid: errors.isEmpty,
                errors: errors,
                warnings: warnings
            )
        }
    }
    
    private func validateEvents() async {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []
        
        for event in dataManager.events {
            let result = validationService.validateEvent(event)
            errors.append(contentsOf: result.errors)
            warnings.append(contentsOf: result.warnings)
        }
        
        await MainActor.run {
            validationResults["Events"] = ValidationResult(
                isValid: errors.isEmpty,
                errors: errors,
                warnings: warnings
            )
        }
    }
    
    private func validateKeyIndicators() async {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []
        
        for ki in dataManager.keyIndicators {
            let result = validationService.validateKeyIndicator(ki)
            errors.append(contentsOf: result.errors)
            warnings.append(contentsOf: result.warnings)
        }
        
        await MainActor.run {
            validationResults["Key Indicators"] = ValidationResult(
                isValid: errors.isEmpty,
                errors: errors,
                warnings: warnings
            )
        }
    }
    
    private func validateGroups() async {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []
        
        for group in dataManager.accountabilityGroups {
            let result = validationService.validateAccountabilityGroup(group)
            errors.append(contentsOf: result.errors)
            warnings.append(contentsOf: result.warnings)
        }
        
        await MainActor.run {
            validationResults["Groups"] = ValidationResult(
                isValid: errors.isEmpty,
                errors: errors,
                warnings: warnings
            )
        }
    }
    
    private func validateDataConsistency() async {
        let result = validationService.validateDataConsistency(
            goals: dataManager.goals,
            tasks: dataManager.tasks,
            events: dataManager.events,
            keyIndicators: dataManager.keyIndicators
        )
        
        await MainActor.run {
            validationResults["Data Consistency"] = result
        }
    }
    
    private func fixValidationError(_ error: ValidationError) {
        // Implementation would depend on the specific error type
        print("Fixing error: \(error.message)")
    }
    
    private func fixValidationWarning(_ warning: ValidationWarning) {
        // Implementation would depend on the specific warning type
        print("Fixing warning: \(warning.message)")
    }
    
    // MARK: - Computed Properties
    
    private var totalErrorCount: Int {
        validationResults.values.reduce(0) { $0 + $1.errors.count }
    }
    
    private var totalWarningCount: Int {
        validationResults.values.reduce(0) { $0 + $1.warnings.count }
    }
    
    private var allErrors: [ValidationError] {
        validationResults.values.flatMap { $0.errors }
    }
    
    private var allWarnings: [ValidationWarning] {
        validationResults.values.flatMap { $0.warnings }
    }
    
    private func generateSuggestions() -> [ValidationSuggestion] {
        var suggestions: [ValidationSuggestion] = []
        
        // Generate suggestions based on validation results
        if dataManager.goals.isEmpty {
            suggestions.append(ValidationSuggestion(
                title: "Create Your First Goal",
                description: "Start by creating a goal to track your progress and stay motivated.",
                priority: .high,
                action: "Create Goal"
            ))
        }
        
        if dataManager.keyIndicators.isEmpty {
            suggestions.append(ValidationSuggestion(
                title: "Set Up Key Indicators",
                description: "Key indicators help you measure progress toward your goals.",
                priority: .high,
                action: "Create KI"
            ))
        }
        
        let incompleteTasks = dataManager.tasks.filter { $0.status == .pending }
        if incompleteTasks.count > 10 {
            suggestions.append(ValidationSuggestion(
                title: "Reduce Task Backlog",
                description: "You have \(incompleteTasks.count) pending tasks. Consider completing or removing some.",
                priority: .medium,
                action: "Review Tasks"
            ))
        }
        
        return suggestions
    }
}

// MARK: - Supporting Views

struct ValidationStatusHeader: View {
    let errorCount: Int
    let warningCount: Int
    let lastValidated: Date
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 24) {
                // Overall Status
                VStack {
                    Image(systemName: statusIcon)
                        .font(.largeTitle)
                        .foregroundColor(statusColor)
                    
                    Text(statusText)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(statusColor)
                }
                
                Spacer()
                
                // Error Count
                ValidationStatusItem(
                    icon: "exclamationmark.triangle.fill",
                    title: "Errors",
                    count: errorCount,
                    color: .red
                )
                
                // Warning Count
                ValidationStatusItem(
                    icon: "exclamationmark.diamond.fill",
                    title: "Warnings",
                    count: warningCount,
                    color: .orange
                )
            }
            
            // Last Validated
            HStack {
                Text("Last validated: \(lastValidated, formatter: DateFormatter.short)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
    }
    
    private var statusIcon: String {
        if errorCount > 0 { return "xmark.circle.fill" }
        else if warningCount > 0 { return "exclamationmark.triangle.fill" }
        else { return "checkmark.circle.fill" }
    }
    
    private var statusColor: Color {
        if errorCount > 0 { return .red }
        else if warningCount > 0 { return .orange }
        else { return .green }
    }
    
    private var statusText: String {
        if errorCount > 0 { return "Issues Found" }
        else if warningCount > 0 { return "Warnings" }
        else { return "All Good" }
    }
}

struct ValidationStatusItem: View {
    let icon: String
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                Text("\(count)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct ValidationTabSelector: View {
    @Binding var selectedTab: ValidationTab
    
    var body: some View {
        HStack {
            ForEach(ValidationTab.allCases, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.caption)
                        Text(tab.title)
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(selectedTab == tab ? .blue : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(selectedTab == tab ? Color.blue.opacity(0.1) : Color.clear)
                    .cornerRadius(6)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}

struct ValidationOverviewSection: View {
    let validationResults: [String: ValidationResult]
    let onRunValidation: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Validation Overview")
                .font(.headline)
                .fontWeight(.semibold)
            
            if validationResults.isEmpty {
                ValidationEmptyState(onRunValidation: onRunValidation)
            } else {
                ForEach(Array(validationResults.keys.sorted()), id: \.self) { category in
                    if let result = validationResults[category] {
                        ValidationCategoryCard(category: category, result: result)
                    }
                }
                
                // Data Quality Score
                DataQualityScoreCard(results: validationResults)
            }
        }
    }
}

struct ValidationEmptyState: View {
    let onRunValidation: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.shield")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            
            VStack(spacing: 8) {
                Text("Ready to Validate")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Run validation to check your data quality and identify any issues that need attention.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: onRunValidation) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Run Validation")
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct ValidationCategoryCard: View {
    let category: String
    let result: ValidationResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: iconForCategory(category))
                    .font(.title3)
                    .foregroundColor(colorForResult(result))
                
                Text(category)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                ValidationStatusBadge(result: result)
            }
            
            if !result.errors.isEmpty || !result.warnings.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    if !result.errors.isEmpty {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                            Text("\(result.errors.count) error\(result.errors.count == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    if !result.warnings.isEmpty {
                        HStack {
                            Image(systemName: "exclamationmark.diamond.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Text("\(result.warnings.count) warning\(result.warnings.count == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
    
    private func iconForCategory(_ category: String) -> String {
        switch category {
        case "Goals": return "target"
        case "Tasks": return "checkmark.circle"
        case "Events": return "calendar"
        case "Key Indicators": return "chart.bar"
        case "Groups": return "person.3"
        case "Data Consistency": return "link"
        default: return "doc"
        }
    }
    
    private func colorForResult(_ result: ValidationResult) -> Color {
        if !result.errors.isEmpty { return .red }
        else if !result.warnings.isEmpty { return .orange }
        else { return .green }
    }
}

struct ValidationStatusBadge: View {
    let result: ValidationResult
    
    var body: some View {
        Text(statusText)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(backgroundColor)
            .foregroundColor(.white)
            .cornerRadius(4)
    }
    
    private var statusText: String {
        if !result.errors.isEmpty { return "Error" }
        else if !result.warnings.isEmpty { return "Warning" }
        else { return "Valid" }
    }
    
    private var backgroundColor: Color {
        if !result.errors.isEmpty { return .red }
        else if !result.warnings.isEmpty { return .orange }
        else { return .green }
    }
}

struct DataQualityScoreCard: View {
    let results: [String: ValidationResult]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Data Quality Score")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 20) {
                // Circular Progress
                ZStack {
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 8)
                        .frame(width: 100, height: 100)
                    
                    Circle()
                        .trim(from: 0, to: qualityScore / 100)
                        .stroke(scoreColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1), value: qualityScore)
                    
                    VStack {
                        Text("\(Int(qualityScore))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(scoreColor)
                        Text("Score")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(scoreDescription)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(scoreAdvice)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Score Breakdown
                    QualityScoreBreakdown(results: results)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var qualityScore: Double {
        let totalItems = results.values.reduce(0) { total, result in
            total + result.errors.count + result.warnings.count
        }
        
        let totalCategories = results.count
        
        if totalCategories == 0 { return 100 }
        
        let errorPenalty = results.values.reduce(0) { $0 + $1.errors.count } * 20
        let warningPenalty = results.values.reduce(0) { $0 + $1.warnings.count } * 10
        
        return max(0, 100 - Double(errorPenalty + warningPenalty))
    }
    
    private var scoreColor: Color {
        if qualityScore >= 80 { return .green }
        else if qualityScore >= 60 { return .blue }
        else if qualityScore >= 40 { return .orange }
        else { return .red }
    }
    
    private var scoreDescription: String {
        if qualityScore >= 80 { return "Excellent Quality" }
        else if qualityScore >= 60 { return "Good Quality" }
        else if qualityScore >= 40 { return "Needs Improvement" }
        else { return "Poor Quality" }
    }
    
    private var scoreAdvice: String {
        if qualityScore >= 80 { return "Your data is well-maintained!" }
        else if qualityScore >= 60 { return "Minor issues to address." }
        else if qualityScore >= 40 { return "Several issues need attention." }
        else { return "Significant data quality issues." }
    }
}

struct QualityScoreBreakdown: View {
    let results: [String: ValidationResult]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            BreakdownItem(
                title: "Valid Categories",
                value: validCategories,
                total: results.count,
                color: .green
            )
            
            BreakdownItem(
                title: "With Warnings",
                value: warningCategories,
                total: results.count,
                color: .orange
            )
            
            BreakdownItem(
                title: "With Errors",
                value: errorCategories,
                total: results.count,
                color: .red
            )
        }
    }
    
    private var validCategories: Int {
        results.values.filter { $0.errors.isEmpty && $0.warnings.isEmpty }.count
    }
    
    private var warningCategories: Int {
        results.values.filter { $0.errors.isEmpty && !$0.warnings.isEmpty }.count
    }
    
    private var errorCategories: Int {
        results.values.filter { !$0.errors.isEmpty }.count
    }
}

struct BreakdownItem: View {
    let title: String
    let value: Int
    let total: Int
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            Spacer()
            Text("\(value)/\(total)")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

struct ValidationErrorsSection: View {
    let errors: [ValidationError]
    let onFixError: (ValidationError) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Validation Errors")
                .font(.headline)
                .fontWeight(.semibold)
            
            if errors.isEmpty {
                ValidationEmptySection(
                    icon: "checkmark.circle.fill",
                    title: "No Errors Found",
                    message: "All your data passes validation checks.",
                    color: .green
                )
            } else {
                ForEach(errors) { error in
                    ValidationErrorCard(error: error, onFix: { onFixError(error) })
                }
            }
        }
    }
}

struct ValidationWarningsSection: View {
    let warnings: [ValidationWarning]
    let onFixWarning: (ValidationWarning) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Validation Warnings")
                .font(.headline)
                .fontWeight(.semibold)
            
            if warnings.isEmpty {
                ValidationEmptySection(
                    icon: "checkmark.circle.fill",
                    title: "No Warnings",
                    message: "Your data follows all best practices.",
                    color: .green
                )
            } else {
                ForEach(warnings) { warning in
                    ValidationWarningCard(warning: warning, onFix: { onFixWarning(warning) })
                }
            }
        }
    }
}

struct ValidationSuggestionsSection: View {
    let suggestions: [ValidationSuggestion]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Suggestions")
                .font(.headline)
                .fontWeight(.semibold)
            
            if suggestions.isEmpty {
                ValidationEmptySection(
                    icon: "lightbulb.fill",
                    title: "No Suggestions",
                    message: "Your data setup looks great!",
                    color: .blue
                )
            } else {
                ForEach(suggestions) { suggestion in
                    ValidationSuggestionCard(suggestion: suggestion)
                }
            }
        }
    }
}

struct ValidationEmptySection: View {
    let icon: String
    let title: String
    let message: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundColor(color)
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct ValidationErrorCard: View {
    let error: ValidationError
    let onFix: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(error.field)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(error.ruleType.rawValue.capitalized)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                SeverityBadge(severity: error.severity)
            }
            
            Text(error.message)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button(action: onFix) {
                HStack {
                    Image(systemName: "wrench.fill")
                        .font(.caption)
                    Text("Fix Issue")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(6)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }
}

struct ValidationWarningCard: View {
    let warning: ValidationWarning
    let onFix: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.diamond.fill")
                    .foregroundColor(.orange)
                
                Text(warning.field)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            Text(warning.message)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let suggestion = warning.suggestion {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption2)
                        .foregroundColor(.blue)
                    Text(suggestion)
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
                .padding(.top, 4)
            }
            
            Button(action: onFix) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                    Text("Apply Suggestion")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(6)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

struct ValidationSuggestionCard: View {
    let suggestion: ValidationSuggestion
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(suggestion.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    PriorityBadge(priority: suggestion.priority)
                }
                
                Spacer()
            }
            
            Text(suggestion.description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button(action: {}) {
                HStack {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.caption)
                    Text(suggestion.action)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(6)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
}

struct SeverityBadge: View {
    let severity: ValidationSeverity
    
    var body: some View {
        Text(severity.rawValue.capitalized)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(colorForSeverity(severity))
            .foregroundColor(.white)
            .cornerRadius(4)
    }
    
    private func colorForSeverity(_ severity: ValidationSeverity) -> Color {
        switch severity {
        case .error: return .red
        case .warning: return .orange
        case .info: return .blue
        }
    }
}

struct PriorityBadge: View {
    let priority: ValidationPriority
    
    var body: some View {
        Text(priority.rawValue.capitalized)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(colorForPriority(priority))
            .foregroundColor(.white)
            .cornerRadius(4)
    }
    
    private func colorForPriority(_ priority: ValidationPriority) -> Color {
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
}

struct ValidationOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                
                Text("Validating Data...")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("This may take a moment")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(32)
            .background(Color.black.opacity(0.8))
            .cornerRadius(16)
        }
    }
}

// MARK: - Supporting Types

enum ValidationTab: CaseIterable {
    case overview, errors, warnings, suggestions
    
    var title: String {
        switch self {
        case .overview: return "Overview"
        case .errors: return "Errors"
        case .warnings: return "Warnings"
        case .suggestions: return "Suggestions"
        }
    }
    
    var icon: String {
        switch self {
        case .overview: return "chart.bar.fill"
        case .errors: return "exclamationmark.triangle.fill"
        case .warnings: return "exclamationmark.diamond.fill"
        case .suggestions: return "lightbulb.fill"
        }
    }
}

struct ValidationSuggestion: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let priority: ValidationPriority
    let action: String
}

enum ValidationPriority: String, CaseIterable {
    case high = "high"
    case medium = "medium"
    case low = "low"
}

extension DateFormatter {
    static let short: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}

#Preview {
    ValidationDetailsView()
        .environmentObject(AuthViewModel())
        .environmentObject(DataManager.shared)
}