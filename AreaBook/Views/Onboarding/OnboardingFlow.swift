import Foundation
import SwiftUI
import Combine
import Firebase
import FirebaseFirestore

struct OnboardingFlow: View {
    @StateObject private var onboardingViewModel = OnboardingViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        TabView(selection: $onboardingViewModel.currentStep) {
            ForEach(OnboardingStep.allCases, id: \.self) { step in
                step.view(viewModel: onboardingViewModel)
                    .tag(step)
            }
        }
        .tabViewStyle(PageTabViewStyle())
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
        .onAppear {
            onboardingViewModel.setup(authViewModel: authViewModel, dataManager: dataManager)
        }
    }
}

// MARK: - Onboarding Steps
enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case features = 1
    case keyIndicators = 2
    case goals = 3
    case notifications = 4
    case completion = 5
    
    @ViewBuilder
    func view(viewModel: OnboardingViewModel) -> some View {
        switch self {
        case .welcome:
            WelcomeScreen(viewModel: viewModel)
        case .features:
            FeaturesScreen(viewModel: viewModel)
        case .keyIndicators:
            KeyIndicatorsSetupScreen(viewModel: viewModel)
        case .goals:
            GoalsSetupScreen(viewModel: viewModel)
        case .notifications:
            NotificationPermissionScreen(viewModel: viewModel)
        case .completion:
            CompletionScreen(viewModel: viewModel)
        }
    }
}

// MARK: - Onboarding View Model
class OnboardingViewModel: ObservableObject {
    @Published var currentStep: OnboardingStep = .welcome
    @Published var selectedKeyIndicators: Set<String> = []
    @Published var customKeyIndicators: [KeyIndicator] = []
    @Published var sampleGoals: [Goal] = []
    @Published var userName: String = ""
    @Published var notificationsEnabled = false
    
    private var authViewModel: AuthViewModel?
    private var dataManager: DataManager?
    
    func setup(authViewModel: AuthViewModel, dataManager: DataManager) {
        self.authViewModel = authViewModel
        self.dataManager = dataManager
        self.userName = authViewModel.currentUser?.name ?? "Friend"
    }
    
    func nextStep() {
        if currentStep.rawValue < OnboardingStep.allCases.count - 1 {
            currentStep = OnboardingStep(rawValue: currentStep.rawValue + 1) ?? .welcome
        }
    }
    
    func previousStep() {
        if currentStep.rawValue > 0 {
            currentStep = OnboardingStep(rawValue: currentStep.rawValue - 1) ?? .welcome
        }
    }
    
    func completeOnboarding() {
        // Save selected Key Indicators
        saveSelectedKeyIndicators()
        
        // Save sample goals
        saveSampleGoals()
        
        // Mark onboarding as complete
        UserDefaults.standard.set(true, forKey: "onboarding_completed")
        
        // Request notification permissions if needed
        if notificationsEnabled {
            requestNotificationPermissions()
        }
    }
    
    private func saveSelectedKeyIndicators() {
        guard let userId = authViewModel?.currentUser?.id,
              let dataManager = dataManager else { return }
        
        // Save predefined KIs
        for kiName in selectedKeyIndicators {
            if let template = KeyIndicatorTemplate.templates.first(where: { $0.name == kiName }) {
                let ki = KeyIndicator(
                    name: template.name,
                    weeklyTarget: template.weeklyTarget,
                    unit: template.unit,
                    color: template.color
                )
                dataManager.createKeyIndicator(ki, userId: userId)
            }
        }
        
        // Save custom KIs
        for ki in customKeyIndicators {
            dataManager.createKeyIndicator(ki, userId: userId)
        }
    }
    
    private func saveSampleGoals() {
        guard let userId = authViewModel?.currentUser?.id,
              let dataManager = dataManager else { return }
        
        for goal in sampleGoals {
            dataManager.createGoal(goal, userId: userId)
        }
    }
    
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.notificationsEnabled = granted
            }
        }
    }
}

// MARK: - Welcome Screen
struct WelcomeScreen: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // App Icon and Title
            VStack(spacing: 20) {
                Image(systemName: "book.pages.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Welcome to AreaBook")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Your life tracking companion")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // Features Preview
            VStack(spacing: 16) {
                FeaturePreviewRow(icon: "target", title: "Track Life Metrics", description: "Monitor your daily habits and goals")
                FeaturePreviewRow(icon: "calendar", title: "Schedule Events", description: "Plan and organize your activities")
                FeaturePreviewRow(icon: "checkmark.circle", title: "Manage Tasks", description: "Stay organized with actionable items")
                FeaturePreviewRow(icon: "chart.bar", title: "View Progress", description: "See your growth over time")
            }
            
            Spacer()
            
            // Get Started Button
            Button(action: {
                viewModel.nextStep()
            }) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

// MARK: - Features Screen
struct FeaturesScreen: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    private let features = [
        OnboardingFeature(
            icon: "target",
            title: "Life Trackers",
            description: "Track weekly habits like exercise, reading, water intake, and more",
            color: .blue
        ),
        OnboardingFeature(
            icon: "star.circle",
            title: "Goals with Sticky Notes",
            description: "Set long-term goals and brainstorm with interactive sticky notes",
            color: .green
        ),
        OnboardingFeature(
            icon: "calendar.badge.plus",
            title: "Smart Calendar",
            description: "Schedule events with recurring patterns and task integration",
            color: .orange
        ),
        OnboardingFeature(
            icon: "checklist",
            title: "Task Management",
            description: "Break down goals into actionable tasks with subtasks and priorities",
            color: .purple
        ),
        OnboardingFeature(
            icon: "mic",
            title: "Siri Integration",
            description: "Use voice commands to add tasks and update progress",
            color: .red
        ),
        OnboardingFeature(
            icon: "apps.iphone",
            title: "Home Screen Widgets",
            description: "See your progress at a glance with customizable widgets",
            color: .indigo
        )
    ]
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 16) {
                Text("Powerful Features")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Everything you need to track your life goals and habits")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Features Grid
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 20) {
                    ForEach(features) { feature in
                        FeatureCard(feature: feature)
                    }
                }
            }
            
            // Navigation
            HStack {
                Button("Back") {
                    viewModel.previousStep()
                }
                .foregroundColor(.blue)
                
                Spacer()
                
                Button("Continue") {
                    viewModel.nextStep()
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(8)
            }
        }
        .padding()
    }
}

// MARK: - Key Indicators Setup Screen
struct KeyIndicatorsSetupScreen: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var showingCustomKI = false
    
    private let recommendedKIs = [
        "Exercise", "Reading", "Water Intake", "Sleep Hours",
        "Meditation", "Learning", "Social Time", "Creative Work"
    ]
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 16) {
                Text("Set Up Life Trackers")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Choose the habits and activities you want to track weekly")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Recommended KIs
            ScrollView {
                VStack(spacing: 20) {
                    Text("Recommended")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        ForEach(recommendedKIs, id: \.self) { ki in
                            KISelectionCard(
                                name: ki,
                                isSelected: viewModel.selectedKeyIndicators.contains(ki)
                            ) {
                                if viewModel.selectedKeyIndicators.contains(ki) {
                                    viewModel.selectedKeyIndicators.remove(ki)
                                } else {
                                    viewModel.selectedKeyIndicators.insert(ki)
                                }
                            }
                        }
                    }
                    
                    Button("Add Custom Life Tracker") {
                        showingCustomKI = true
                    }
                    .foregroundColor(.blue)
                    .padding(.top)
                }
            }
            
            // Navigation
            HStack {
                Button("Back") {
                    viewModel.previousStep()
                }
                .foregroundColor(.blue)
                
                Spacer()
                
                Button("Continue") {
                    viewModel.nextStep()
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(viewModel.selectedKeyIndicators.isEmpty ? Color.gray : Color.blue)
                .cornerRadius(8)
                .disabled(viewModel.selectedKeyIndicators.isEmpty)
            }
        }
        .padding()
        .sheet(isPresented: $showingCustomKI) {
            CustomKICreationSheet(viewModel: viewModel)
        }
    }
}

// MARK: - Goals Setup Screen
struct GoalsSetupScreen: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var showingGoalCreation = false
    
    private let sampleGoals = [
        SampleGoal(
            title: "Daily Exercise Routine",
            description: "Establish a consistent 30-minute daily workout habit",
            category: "Health & Fitness"
        ),
        SampleGoal(
            title: "Read 12 Books This Year",
            description: "Read one book per month to expand knowledge and skills",
            category: "Personal Growth"
        ),
        SampleGoal(
            title: "Learn a New Skill",
            description: "Dedicate time each week to learning something new",
            category: "Education"
        ),
        SampleGoal(
            title: "Improve Work-Life Balance",
            description: "Set boundaries and make time for family and hobbies",
            category: "Life Balance"
        )
    ]
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 16) {
                Text("Set Your Goals")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Choose some initial goals to get started")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Sample Goals
            ScrollView {
                VStack(spacing: 16) {
                    Text("Suggested Goals")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    ForEach(sampleGoals, id: \.title) { sampleGoal in
                        SampleGoalCard(
                            sampleGoal: sampleGoal,
                            isSelected: viewModel.sampleGoals.contains { $0.title == sampleGoal.title }
                        ) {
                            if let index = viewModel.sampleGoals.firstIndex(where: { $0.title == sampleGoal.title }) {
                                viewModel.sampleGoals.remove(at: index)
                            } else {
                                let goal = Goal(
                                    title: sampleGoal.title,
                                    description: sampleGoal.description,
                                    keyIndicatorIds: [],
                                    targetDate: Calendar.current.date(byAdding: .month, value: 3, to: Date())
                                )
                                viewModel.sampleGoals.append(goal)
                            }
                        }
                    }
                    
                    Button("Create Custom Goal") {
                        showingGoalCreation = true
                    }
                    .foregroundColor(.blue)
                    .padding(.top)
                }
            }
            
            // Navigation
            HStack {
                Button("Back") {
                    viewModel.previousStep()
                }
                .foregroundColor(.blue)
                
                Spacer()
                
                Button("Continue") {
                    viewModel.nextStep()
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(8)
            }
        }
        .padding()
        .sheet(isPresented: $showingGoalCreation) {
            // Custom goal creation sheet would go here
            Text("Custom Goal Creation")
        }
    }
}

// MARK: - Notification Permission Screen
struct NotificationPermissionScreen: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Icon and Title
            VStack(spacing: 20) {
                Image(systemName: "bell.badge")
                    .font(.system(size: 80))
                    .foregroundColor(.orange)
                
                Text("Stay on Track")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Get gentle reminders for your daily habits and goals")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // Benefits
            VStack(spacing: 20) {
                NotificationBenefit(icon: "clock", title: "Task Reminders", description: "Never miss important activities and habits")
                NotificationBenefit(icon: "chart.bar", title: "Progress Updates", description: "Weekly summaries of your personal growth")
                NotificationBenefit(icon: "star", title: "Encouragement", description: "Motivational messages to keep you going")
            }
            
            Spacer()
            
            // Permission Buttons
            VStack(spacing: 16) {
                Button(action: {
                    viewModel.notificationsEnabled = true
                    viewModel.nextStep()
                }) {
                    Text("Enable Notifications")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(12)
                }
                
                Button(action: {
                    viewModel.notificationsEnabled = false
                    viewModel.nextStep()
                }) {
                    Text("Maybe Later")
                        .font(.headline)
                        .foregroundColor(.orange)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                }
            }
            
            Button("Back") {
                viewModel.previousStep()
            }
            .foregroundColor(.blue)
            .padding(.top)
        }
        .padding()
    }
}

// MARK: - Completion Screen
struct CompletionScreen: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Success Animation
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                
                Text("You're All Set!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Welcome to your personal growth journey, \(viewModel.userName)!")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // Summary
            VStack(spacing: 16) {
                Text("Here's what you've set up:")
                    .font(.headline)
                
                SummaryCard(
                    icon: "target",
                    title: "Life Trackers",
                    count: viewModel.selectedKeyIndicators.count + viewModel.customKeyIndicators.count,
                    color: .blue
                )
                
                SummaryCard(
                    icon: "star.circle",
                    title: "Goals",
                    count: viewModel.sampleGoals.count,
                    color: .green
                )
                
                SummaryCard(
                    icon: "bell",
                    title: "Notifications",
                    count: viewModel.notificationsEnabled ? 1 : 0,
                    color: .orange
                )
            }
            
            Spacer()
            
            // Complete Button
            Button(action: {
                viewModel.completeOnboarding()
            }) {
                Text("Start Your Journey")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
            }
        }
        .padding()
    }
}

// MARK: - Supporting Views
struct FeaturePreviewRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct OnboardingFeature: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let color: Color
}

struct FeatureCard: View {
    let feature: OnboardingFeature
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: feature.icon)
                .font(.system(size: 40))
                .foregroundColor(feature.color)
            
            Text(feature.title)
                .font(.headline)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            Text(feature.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct KISelectionCard: View {
    let name: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .white : .gray)
            }
            .padding(12)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SampleGoal {
    let title: String
    let description: String
    let category: String
}

struct SampleGoalCard: View {
    let sampleGoal: SampleGoal
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(sampleGoal.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(sampleGoal.description)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .white : .gray)
            }
            .padding(12)
            .background(isSelected ? Color.green : Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NotificationBenefit: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.orange)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct SummaryCard: View {
    let icon: String
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(title)
                .font(.headline)
            
            Spacer()
            
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
}

struct CustomKICreationSheet: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var unit = ""
    @State private var weeklyTarget = ""
    @State private var selectedColor = "#3B82F6"
    
    var body: some View {
        NavigationView {
            Form {
                Section("Life Tracker Details") {
                    TextField("Name (e.g., Family History)", text: $name)
                    TextField("Unit (e.g., entries, hours)", text: $unit)
                    TextField("Weekly Target (e.g., 3)", text: $weeklyTarget)
                        .keyboardType(.numberPad)
                }
                
                Section("Color") {
                    // Color picker would go here
                    Text("Color selection")
                }
            }
            .navigationTitle("Custom Life Tracker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        let ki = KeyIndicator(
                            name: name,
                            weeklyTarget: Int(weeklyTarget) ?? 1,
                            unit: unit,
                            color: selectedColor
                        )
                        viewModel.customKeyIndicators.append(ki)
                        dismiss()
                    }
                    .disabled(name.isEmpty || unit.isEmpty || weeklyTarget.isEmpty)
                }
            }
        }
    }
}

// MARK: - Key Indicator Templates
struct KeyIndicatorTemplate {
    let name: String
    let weeklyTarget: Int
    let unit: String
    let color: String
    
    static let templates = [
        KeyIndicatorTemplate(name: "Exercise", weeklyTarget: 5, unit: "sessions", color: "#84CC16"),
        KeyIndicatorTemplate(name: "Reading", weeklyTarget: 7, unit: "books", color: "#3B82F6"),
        KeyIndicatorTemplate(name: "Water Intake", weeklyTarget: 56, unit: "glasses", color: "#06B6D4"),
        KeyIndicatorTemplate(name: "Sleep Hours", weeklyTarget: 56, unit: "hours", color: "#8B5CF6"),
        KeyIndicatorTemplate(name: "Meditation", weeklyTarget: 210, unit: "minutes", color: "#10B981"),
        KeyIndicatorTemplate(name: "Learning", weeklyTarget: 10, unit: "hours", color: "#F59E0B"),
        KeyIndicatorTemplate(name: "Social Time", weeklyTarget: 8, unit: "hours", color: "#EC4899"),
        KeyIndicatorTemplate(name: "Creative Work", weeklyTarget: 6, unit: "hours", color: "#F97316")
    ]
}

#Preview {
    OnboardingFlow()
        .environmentObject(AuthViewModel())
        .environmentObject(DataManager.shared)
}