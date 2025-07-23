import SwiftUI

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
    case aiQuestions = 1
    case featureProposal = 2
    case featureShopping = 3
    case dashboardCustomization = 4
    case conflictResolution = 5
    case completion = 6
    
    @ViewBuilder
    func view(viewModel: OnboardingViewModel) -> some View {
        switch self {
        case .welcome:
            WelcomeScreen(viewModel: viewModel)
        case .aiQuestions:
            AIQuestionsScreen(viewModel: viewModel)
        case .featureProposal:
            FeatureProposalScreen(viewModel: viewModel)
        case .featureShopping:
            FeatureShoppingScreen(viewModel: viewModel)
        case .dashboardCustomization:
            DashboardCustomizationScreen(viewModel: viewModel)
        case .conflictResolution:
            ConflictResolutionScreen(viewModel: viewModel)
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
    
    // AI-driven onboarding properties
    @Published var onboardingAnswers: [String] = []
    @Published var featureProposal: FeatureProposal? = nil
    @Published var selectedFeatures: Set<AppFeature> = Set(AppFeature.defaultFeatures)
    @Published var selectedWidgets: [DashboardWidget] = DashboardLayout.default.widgets
    @Published var featureConflicts: [String] = []
    
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
        // Save selected Key Indicators (if any were selected in old flow)
        saveSelectedKeyIndicators()
        
        // Save sample goals (if any were selected in old flow)
        saveSampleGoals()
        
        // Mark onboarding as complete
        UserDefaults.standard.set(true, forKey: "onboarding_completed")
        UserDefaults.standard.set(Date(), forKey: "onboarding_completed_date")
        
        // Request notification permissions if needed
        if notificationsEnabled {
            requestNotificationPermissions()
        }
        
        print("✅ Onboarding: Completed successfully")
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
    
    // AI-driven onboarding methods
    func answerOnboardingQuestion(_ answer: String) {
        onboardingAnswers.append(answer)
        if onboardingAnswers.count == OnboardingAI.questions.count {
            // All questions answered, propose features
            featureProposal = OnboardingAI.proposeFeatures(from: onboardingAnswers)
            selectedFeatures = Set(featureProposal?.proposedFeatures ?? AppFeature.defaultFeatures)
            selectedWidgets = featureProposal?.proposedDashboard.widgets ?? DashboardLayout.default.widgets
            featureConflicts = OnboardingAI.detectConflicts(selected: Array(selectedFeatures))
        }
    }
    
    func addFeature(_ feature: AppFeature) {
        selectedFeatures.insert(feature)
        featureConflicts = OnboardingAI.detectConflicts(selected: Array(selectedFeatures))
    }
    
    func removeFeature(_ feature: AppFeature) {
        selectedFeatures.remove(feature)
        featureConflicts = OnboardingAI.detectConflicts(selected: Array(selectedFeatures))
    }
    
    func addWidget(_ widget: DashboardWidget) {
        selectedWidgets.append(widget)
    }
    
    func removeWidget(_ widget: DashboardWidget) {
        selectedWidgets.removeAll { $0.id == widget.id }
    }
    
    func confirmOnboarding() {
        guard let authViewModel = authViewModel,
              let dataManager = dataManager,
              let userId = authViewModel.currentUser?.id else { return }
        
        // Update user settings with new preferences
        var updatedUser = authViewModel.currentUser!
        updatedUser.settings.userProfile = featureProposal?.proposedProfile ?? .general
        updatedUser.settings.enabledFeatures = selectedFeatures
        updatedUser.settings.dashboardLayout = DashboardLayout(
            widgets: selectedWidgets,
            gridRows: 2,
            gridCols: 2
        )
        updatedUser.settings.customWidgets = selectedWidgets
        
        // Save updated user to Firestore
        dataManager.updateUser(updatedUser, userId: userId) { success in
            if success {
                print("✅ Onboarding: User preferences saved successfully")
                // Update the current user in AuthViewModel
                DispatchQueue.main.async {
                    self.authViewModel?.currentUser = updatedUser
                }
            } else {
                print("❌ Onboarding: Failed to save user preferences")
            }
        }
        
        // Save to UserDefaults for immediate access
        saveToUserDefaults()
        
        // Complete the onboarding process
        completeOnboarding()
    }
    
    private func saveToUserDefaults() {
        let defaults = UserDefaults.standard
        
        // Save user profile
        defaults.set(featureProposal?.proposedProfile.rawValue ?? UserProfile.general.rawValue, forKey: "user_profile")
        
        // Save enabled features
        let featureStrings = Array(selectedFeatures).map { $0.rawValue }
        defaults.set(featureStrings, forKey: "enabled_features")
        
        // Save dashboard layout
        if let layoutData = try? JSONEncoder().encode(DashboardLayout(
            widgets: selectedWidgets,
            gridRows: 2,
            gridCols: 2
        )) {
            defaults.set(layoutData, forKey: "dashboard_layout")
        }
        
        // Save custom widgets
        if let widgetsData = try? JSONEncoder().encode(selectedWidgets) {
            defaults.set(widgetsData, forKey: "custom_widgets")
        }
        
        // Mark onboarding as completed
        defaults.set(true, forKey: "onboarding_completed")
        defaults.set(Date(), forKey: "onboarding_completed_date")
        
        print("✅ Onboarding: Preferences saved to UserDefaults")
    }
}

// --- AI-driven onboarding additions ---
struct OnboardingQuestion: Identifiable {
    let id = UUID()
    let text: String
    let options: [String]?
}

struct FeatureProposal {
    var proposedProfile: UserProfile
    var proposedFeatures: [AppFeature]
    var proposedDashboard: DashboardLayout
    var conflicts: [String] = []
}

struct OnboardingAI {
    static let questions: [OnboardingQuestion] = [
        OnboardingQuestion(text: "What is your main goal with the app?", options: ["Productivity", "Wellbeing", "Academic", "Business", "Family, Relationship", "Fitness", "Creative", "Religious", "Language", "Financial", "Travel", "Volunteer", "Recovery"]),
        OnboardingQuestion(text: "Which areas do you want to focus on?", options:["Tasks & Goals", "Habits & Tracking", "Calendar & Time", "Notes & Ideas", "Social & Groups", "Health & Wellness", "Learning & Growth", "Work& Career", "Family & Relationships", "Creative Projects", "Spiritual Life", "Financial Planning", "Travel & Adventure", "Community Service"]),
        OnboardingQuestion(text: "How do you prefer to track progress?", options: ["Daily habits,Weekly goals", "Monthly milestones", "Flexible tracking", "Not sure"]),
        OnboardingQuestion(text: "Do you want social/accountability features?", options: ["Yes, with groups", "Yes, with sharing", "No, private only", "Maybe later"]),
        OnboardingQuestion(text: "What's your biggest challenge right now?", options: ["Time management", "Organization", "Health habits", "Work-life balance", "Learning new skills", "Financial planning", "Relationship building", "Stress management", "Other"])
    ]
    
    // AI Logic for Feature Proposal
    static func proposeFeatures(from answers: [String]) -> FeatureProposal {
        guard answers.count >= 3 else {
            return FeatureProposal(
                proposedProfile: .general,
                proposedFeatures: AppFeature.defaultFeatures,
                proposedDashboard: DashboardLayout.default
            )
        }
        
        let mainGoal = answers[0]
        let focusAreas = answers[1]
        let trackingPreference = answers[2]
        let socialPreference = answers.count > 3 ? answers[3] : "No"
        let biggestChallenge = answers.count > 4 ? answers[4] : "Time management"
        // Determine user profile based on main goal
        let profile = mapGoalToProfile(mainGoal)
        
        // Get base features for the profile
        var proposedFeatures = getBaseFeatures(for: profile)
        
        // Add features based on focus areas
        proposedFeatures.append(contentsOf: getFeaturesForFocusAreas(focusAreas))
        
        // Add features based on tracking preference
        proposedFeatures.append(contentsOf: getFeaturesForTracking(trackingPreference))
        
        // Add social features based on preference
        if socialPreference.contains("Yes") {
            proposedFeatures.append(contentsOf: [.groups, .sharing, .accountability])
        }
        
        // Add features to address biggest challenge
        proposedFeatures.append(contentsOf: getFeaturesForChallenge(biggestChallenge))
        
        // Remove duplicates and ensure core features are included
        proposedFeatures = Array(Set(proposedFeatures))
        if !proposedFeatures.contains(.dashboard) {
            proposedFeatures.append(.dashboard)
        }
        
        // Create dashboard layout based on selected features
        let dashboard = createDashboardLayout(for: proposedFeatures)
        
        return FeatureProposal(
            proposedProfile: profile,
            proposedFeatures: proposedFeatures,
            proposedDashboard: dashboard
        )
    }
    
    // Map user goals to profiles
    private static func mapGoalToProfile(_ goal: String) -> UserProfile {
        switch goal.lowercased() {
        case let g where g.contains("productivity"): return .general
        case let g where g.contains("wellbeing"): return .wellbeing
        case let g where g.contains("academic"): return .student
        case let g where g.contains("business"): return .business
        case let g where g.contains("family"): return .family
        case let g where g.contains("relationship"): return .relationship
        case let g where g.contains("fitness"): return .fitness
        case let g where g.contains("creative"): return .creative
        case let g where g.contains("religious"): return .religious
        case let g where g.contains("language"): return .language
        case let g where g.contains("financial"): return .financial
        case let g where g.contains("travel"): return .travel
        case let g where g.contains("volunteer"): return .volunteer
        case let g where g.contains("recovery"): return .rehab
        default: return .general
        }
    }
    
    // Get base features for each profile
    private static func getBaseFeatures(for profile: UserProfile) -> [AppFeature] {
        switch profile {
        case .student:
            return [.goals, .tasks, .calendar, .notes, .keyIndicators, .academicTracking, .studyTimer, .assignmentManager]
        case .business:
            return [.goals, .tasks, .calendar, .notes, .keyIndicators, .businessMetrics, .teamManagement, .financialTracking]
        case .workplace:
            return [.goals, .tasks, .calendar, .notes, .keyIndicators, .professionalDevelopment, .workLifeBalance]
        case .family:
            return [.goals, .tasks, .calendar, .notes, .keyIndicators, .familyActivities, .parentingGoals, .householdManagement]
        case .relationship:
            return [.goals, .tasks, .calendar, .notes, .keyIndicators, .relationshipGoals, .communicationTracking, .datePlanning]
        case .wellbeing:
            return [.goals, .tasks, .calendar, .notes, .keyIndicators, .moodTracking, .meditationTimer, .selfCareRoutines]
        case .fitness:
            return [.goals, .tasks, .calendar, .notes, .keyIndicators, .workoutTracking, .nutritionTracking, .healthMonitoring]
        case .creative:
            return [.goals, .tasks, .calendar, .notes, .keyIndicators, .projectTracking, .inspirationLog, .portfolioGoals]
        case .religious:
            return [.goals, .tasks, .calendar, .notes, .keyIndicators, .prayerTracking, .scriptureStudy, .serviceActivities]
        case .language:
            return [.goals, .tasks, .calendar, .notes, .keyIndicators, .studySessions, .vocabularyPractice, .conversationTracking]
        case .financial:
            return [.goals, .tasks, .calendar, .notes, .keyIndicators, .budgetTracking, .savingsGoals, .investmentMonitoring]
        case .travel:
            return [.goals, .tasks, .calendar, .notes, .keyIndicators, .tripPlanning, .bucketList, .travelMemories]
        case .volunteer:
            return [.goals, .tasks, .calendar, .notes, .keyIndicators, .serviceHours, .donationTracking, .communityInvolvement]
        case .rehab:
            return [.goals, .tasks, .calendar, .notes, .keyIndicators, .recoveryMilestones, .triggerTracking, .supportNetwork]
        default:
            return AppFeature.defaultFeatures
        }
    }
    
    // Get features based on focus areas
    private static func getFeaturesForFocusAreas(_ focusAreas: String) -> [AppFeature] {
        var features: [AppFeature] = []
        
        if focusAreas.contains("Tasks & Goals") {
            features.append(contentsOf: [.goals, .tasks])
        }
        if focusAreas.contains("Habits & Tracking") {
            features.append(.keyIndicators)
        }
        if focusAreas.contains("Calendar & Time") {
            features.append(.calendar)
        }
        if focusAreas.contains("Notes & Ideas") {
            features.append(.notes)
        }
        if focusAreas.contains("Social & Groups") {
            features.append(contentsOf: [.groups, .sharing, .accountability])
        }
        if focusAreas.contains("Health & Wellness") {
            features.append(contentsOf: [.moodTracking, .meditationTimer, .selfCareRoutines])
        }
        if focusAreas.contains("Learning & Growth") {
            features.append(contentsOf: [.academicTracking, .studyTimer, .professionalDevelopment])
        }
        if focusAreas.contains("Work & Career") {
            features.append(contentsOf: [.businessMetrics, .teamManagement, .professionalDevelopment])
        }
        if focusAreas.contains("Family & Relationships") {
            features.append(contentsOf: [.familyActivities, .relationshipGoals, .communicationTracking])
        }
        if focusAreas.contains("Creative Projects") {
            features.append(contentsOf: [.projectTracking, .inspirationLog, .portfolioGoals])
        }
        if focusAreas.contains("Spiritual Life") {
            features.append(contentsOf: [.prayerTracking, .scriptureStudy, .serviceActivities])
        }
        if focusAreas.contains("Financial Planning") {
            features.append(contentsOf: [.budgetTracking, .savingsGoals, .investmentMonitoring])
        }
        if focusAreas.contains("Travel & Adventure") {
            features.append(contentsOf: [.tripPlanning, .bucketList, .travelMemories])
        }
        if focusAreas.contains("Community Service") {
            features.append(contentsOf: [.serviceHours, .donationTracking, .communityInvolvement])
        }
        
        return features
    }
    
    // Get features based on tracking preference
    private static func getFeaturesForTracking(_ preference: String) -> [AppFeature] {
        switch preference.lowercased() {
        case let p where p.contains("daily"):
            return [.keyIndicators, .moodTracking]
        case let p where p.contains("weekly"):
            return [.keyIndicators, .goals]
        case let p where p.contains("monthly"):
            return [.goals, .businessMetrics]
        case let p where p.contains("flexible"):
            return [.notes, .tasks]
        default:
            return [.keyIndicators]
        }
    }
    
    // Get features to address specific challenges
    private static func getFeaturesForChallenge(_ challenge: String) -> [AppFeature] {
        switch challenge.lowercased() {
        case let c where c.contains("time"):
            return [.calendar, .tasks, .workLifeBalance]
        case let c where c.contains("motivation"):
            return [.goals, .aiAssistant, .aiAssistant]
        case let c where c.contains("organization"):
            return [.tasks, .notes, .keyIndicators]
        case let c where c.contains("health"):
            return [.workoutTracking, .nutritionTracking, .healthMonitoring]
        case let c where c.contains("work-life"):
            return [.workLifeBalance, .calendar, .familyActivities]
        case let c where c.contains("learning"):
            return [.academicTracking, .studyTimer, .professionalDevelopment]
        case let c where c.contains("financial"):
            return [.budgetTracking, .savingsGoals, .financialTracking]
        case let c where c.contains("relationship"):
            return [.relationshipGoals, .communicationTracking, .datePlanning]
        case let c where c.contains("stress"):
            return [.moodTracking, .meditationTimer, .selfCareRoutines]
        default:
            return []
        }
    }
    
    // Create dashboard layout based on selected features
    private static func createDashboardLayout(for features: [AppFeature]) -> DashboardLayout {
        var widgets: [DashboardWidget] = []
        var position = (row: 0, col: 0)
        
        // Always include key indicators if available
        if features.contains(.keyIndicators) {
            widgets.append(DashboardWidget(type: .keyIndicators, size: .medium, position: position))
            position = nextPosition(position)
        }
        
        // Add tasks widget
        if features.contains(.tasks) {
            widgets.append(DashboardWidget(type: .tasks, size: .medium, position: position))
            position = nextPosition(position)
        }
        
        // Add goals widget
        if features.contains(.goals) {
            widgets.append(DashboardWidget(type: .goals, size: .medium, position: position))
            position = nextPosition(position)
        }
        
        // Add events widget
        if features.contains(.calendar) {
            widgets.append(DashboardWidget(type: .events, size: .medium, position: position))
            position = nextPosition(position)
        }
        
        // Add AI suggestions if AI assistant is enabled
        if features.contains(.aiAssistant) {
            widgets.append(DashboardWidget(type: .aiSuggestions, size: .standard, position: position))
            position = nextPosition(position)
        }
        
        // Add motivational quote
        widgets.append(DashboardWidget(type: .aiAssistant, size: .standard, position: position))
        
        // Calculate grid size based on widgets
        let maxRow = widgets.map { $0.position.row }.max() ?? 0
        let maxCol = widgets.map { $0.position.col }.max() ?? 0
        return DashboardLayout(
            widgets: widgets,
            gridRows: maxRow + 1,
            gridCols: maxCol + 1
        )
    }
    
    private static func nextPosition(_ current: (row: Int, col: Int)) -> (row: Int, col: Int) {
        if current.col < 1 {
            return (current.row, current.col + 1)
        } else {
            return (current.row + 1, 0)
        }
    }
    
    // Conflict Detection Logic
    static func detectConflicts(selected: [AppFeature]) -> [String] {
        var conflicts: [String] = []
        
        // Check for profile conflicts
        let profiles = getProfilesForFeatures(selected)
        if profiles.count > 2 {
            conflicts.append("You've selected features from multiple profiles (\(profiles.map { $0.displayName }.joined(separator: ", "))). This might create a complex setup.")
        }
        
        // Check for tracking conflicts
        if selected.contains(.keyIndicators) && selected.contains(.businessMetrics) {
            conflicts.append("Both Life Trackers and Business Metrics track progress. Consider focusing on one for clarity.")
        }
        
        // Check for social conflicts
        if selected.contains(.groups) && !selected.contains(.sharing) {
            conflicts.append("Groups work best with sharing enabled. Consider adding sharing features.")
        }
        
        // Check for productivity conflicts
        if selected.contains(.siriShortcuts) && !selected.contains(.tasks) && !selected.contains(.calendar) {
            conflicts.append("Siri Shortcuts work best with Tasks or Calendar. Consider adding these features.")
        }
        
        // Check for wellness conflicts
        if selected.contains(.moodTracking) && selected.contains(.workoutTracking) {
            conflicts.append("Both Mood Tracking and Workout Tracking can be overwhelming. Consider starting with one.")
        }
        
        // Check for academic conflicts
        if selected.contains(.academicTracking) && selected.contains(.professionalDevelopment) {
            conflicts.append("Academic Tracking and Professional Development might overlap. Consider which is more relevant.")
        }
        
        // Check for financial conflicts
        if selected.contains(.budgetTracking) && selected.contains(.financialTracking) {
            conflicts.append("Both Budget Tracking and Financial Tracking handle finances. Consider which you need more.")
        }
        
        // Check for too many features
        if selected.count > 12 {
            conflicts.append("You've selected many features (\(selected.count)). Consider starting with fewer features to avoid overwhelm.")
        }
        
        return conflicts
    }
    
    private static func getProfilesForFeatures(_ features: [AppFeature]) -> [UserProfile] {
        var profiles: Set<UserProfile> = []
        
        for feature in features {
            switch feature {
            case .academicTracking, .studyTimer, .assignmentManager:
                profiles.insert(.student)
            case .businessMetrics, .teamManagement, .financialTracking:
                profiles.insert(.business)
            case .professionalDevelopment, .workLifeBalance:
                profiles.insert(.workplace)
            case .familyActivities, .parentingGoals, .householdManagement:
                profiles.insert(.family)
            case .relationshipGoals, .communicationTracking, .datePlanning:
                profiles.insert(.relationship)
            case .moodTracking, .meditationTimer, .selfCareRoutines:
                profiles.insert(.wellbeing)
            case .workoutTracking, .nutritionTracking, .healthMonitoring:
                profiles.insert(.fitness)
            case .projectTracking, .inspirationLog, .portfolioGoals:
                profiles.insert(.creative)
            case .prayerTracking, .scriptureStudy, .serviceActivities:
                profiles.insert(.religious)
            case .studySessions, .vocabularyPractice, .conversationTracking:
                profiles.insert(.language)
            case .budgetTracking, .savingsGoals, .investmentMonitoring:
                profiles.insert(.financial)
            case .tripPlanning, .bucketList, .travelMemories:
                profiles.insert(.travel)
            case .serviceHours, .donationTracking, .communityInvolvement:
                profiles.insert(.volunteer)
            case .recoveryMilestones, .triggerTracking, .supportNetwork:
                profiles.insert(.rehab)
            default:
                profiles.insert(.general)
            }
        }
        
        return Array(profiles)
    }
}


// --- End AI-driven onboarding additions ---

// MARK: - Welcome Screen
struct WelcomeScreen: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // App Icon and Title
            VStack(spacing: 20) {
                Image("AppLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                
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

// MARK: - AI Questions Screen
struct AIQuestionsScreen: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var currentQuestionIndex = 0
    @State private var selectedAnswer = ""
    @State private var customAnswer = ""
    
    var body: some View {
        VStack(spacing:30) {
            // Progress indicator
            ProgressView(value: Double(currentQuestionIndex + 1) / Double(OnboardingAI.questions.count))
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .padding(.horizontal)
            
            Spacer()
            
            // Question
            VStack(spacing: 20) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Let's personalize your experience")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text(OnboardingAI.questions[currentQuestionIndex].text)
                    .font(.title3)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            // Answer options
            VStack(spacing: 16) {
                if let options = OnboardingAI.questions[currentQuestionIndex].options {
                    ForEach(options, id: \.self) { option in
                        Button(action: {
                            selectedAnswer = option
                            submitAnswer()
                        }) {
                            HStack {
                                Text(option)
                                    .font(.body)
                                    .fontWeight(.medium)
                                Spacer()
                                if selectedAnswer == option {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding()
                            .background(selectedAnswer == option ? Color.blue.opacity(0.1) : Color(.secondarySystemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedAnswer == option ? Color.blue : Color.clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                } else {
                    // Custom text input
                    TextField("Type your answer...", text: $customAnswer)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    Button("Continue") {
                        selectedAnswer = customAnswer
                        submitAnswer()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(customAnswer.isEmpty ? Color.gray : Color.blue)
                    .cornerRadius(12)
                    .disabled(customAnswer.isEmpty)
                    .padding(.horizontal)
                }
            }
            
            Spacer()
            
            // Navigation
            HStack {
                if currentQuestionIndex > 0 {
                Button("Back") {
                        currentQuestionIndex -= 1
                        selectedAnswer = ""
                        customAnswer = ""
                }
                .foregroundColor(.blue)
                }
                
                Spacer()
                
                Text("\(currentQuestionIndex + 1) of \(OnboardingAI.questions.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
        }
        .padding()
        .onAppear {
            selectedAnswer = ""
            customAnswer = ""
        }
    }
    
    private func submitAnswer() {
        viewModel.answerOnboardingQuestion(selectedAnswer)
        if currentQuestionIndex < OnboardingAI.questions.count - 1 {
            currentQuestionIndex += 1
            selectedAnswer = ""
            customAnswer = ""
        } else {
            viewModel.nextStep()
        }
    }
}

// MARK: - Feature Proposal Screen
struct FeatureProposalScreen: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing:30) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                
                Text("Your Personalized App")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Based on your answers, here's what we recommend:")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Profile recommendation
            if let proposal = viewModel.featureProposal {
                VStack(spacing: 20) {
                    ProfileCard(profile: proposal.proposedProfile)
                    
                    Text("Recommended Features")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        ForEach(proposal.proposedFeatures, id: \.self) { feature in
                            FeatureCard(feature: feature, isSelected: true)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Navigation
            HStack {
                Button("Back") {
                    viewModel.previousStep()
                }
                .foregroundColor(.blue)
                
                Spacer()
                
                Button("Customize") {
                    viewModel.nextStep()
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.orange)
                .cornerRadius(8)
            }
        }
        .padding()
    }
}

// MARK: - Feature Shopping Screen
struct FeatureShoppingScreen: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var selectedCategory: FeatureCategory = .core
    @State private var searchText = ""
    
    var filteredFeatures: [AppFeature] {
        let categoryFeatures = FeatureCatalog.features(for: selectedCategory)
        if searchText.isEmpty {
            return categoryFeatures
        } else {
            return categoryFeatures.filter { feature in
                feature.displayName.localizedCaseInsensitiveContains(searchText) ||
                feature.description.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack(spacing:20) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "cart")
                    .font(.system(size: 50))
                    .foregroundColor(.green)
                
                Text("Feature Store")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Add or remove features to customize your experience")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search features...", text: $searchText)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // Category tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(FeatureCategory.allCases, id: \.self) { category in
                        Button(action: {
                            selectedCategory = category
                        }) {
                            Text(category.displayName)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedCategory == category ? Color.blue : Color(.tertiarySystemBackground))
                                .foregroundColor(selectedCategory == category ? .white : .primary)
                                .cornerRadius(20)
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Features grid
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    ForEach(filteredFeatures, id: \.self) { feature in
                        FeatureShoppingCard(
                            feature: feature,
                            isSelected: viewModel.selectedFeatures.contains(feature)
                        ) {
                            if viewModel.selectedFeatures.contains(feature) {
                                viewModel.removeFeature(feature)
                            } else {
                                viewModel.addFeature(feature)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Selected count
            HStack {
                Text("\(viewModel.selectedFeatures.count) features selected")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Continue") {
                    viewModel.nextStep()
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.green)
                .cornerRadius(8)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

// MARK: - Dashboard Customization Screen
struct DashboardCustomizationScreen: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var selectedWidgetType: DashboardWidgetType = .keyIndicators
    
    var body: some View {
        VStack(spacing:20) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 50))
                    .foregroundColor(.purple)
                
                Text("Customize Your Dashboard")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Choose widgets to display on your dashboard")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Dashboard preview
            VStack(spacing: 12) {
                Text("Dashboard Preview")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                DashboardPreview(widgets: viewModel.selectedWidgets)
            }
            
            // Widget selection
            VStack(spacing: 16) {
                Text("Available Widgets")
                        .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                    ForEach(DashboardWidgetType.allCases, id: \.self) { widgetType in
                        WidgetSelectionCard(
                            widgetType: widgetType,
                            isSelected: viewModel.selectedWidgets.contains { $0.type == widgetType }
                        ) {
                            if let existingWidget = viewModel.selectedWidgets.first(where: { $0.type == widgetType }) {
                                viewModel.removeWidget(existingWidget)
                            } else {
                                let newWidget = DashboardWidget(
                                    type: widgetType,
                                    size: .medium,
                                    position: (0, 0)
                                )
                                viewModel.addWidget(newWidget)
                            }
                        }
                    }
                }
            }
            
            Spacer()
            
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
                .background(Color.purple)
                .cornerRadius(8)
            }
        }
        .padding()
    }
}

// MARK: - Conflict Resolution Screen
struct ConflictResolutionScreen: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing:30) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                
                Text("Feature Conflicts Detected")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("We found some potential conflicts in your selection")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if viewModel.featureConflicts.isEmpty {
                // No conflicts
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text("No Conflicts Found!")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Your feature selection looks great. You're ready to continue!")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            } else {
                // Show conflicts
            VStack(spacing: 16) {
                    Text("Conflicts to Review")
                    .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    ForEach(viewModel.featureConflicts, id: \.self) { conflict in
                        ConflictCard(conflict: conflict)
                    }
                }
            }
            
            Spacer()
            
            // Navigation
            HStack {
                Button("Back to Features") {
                    viewModel.currentStep = .featureShopping
                }
                .foregroundColor(.blue)
            
            Spacer()
            
                Button("Continue Anyway") {
                    viewModel.nextStep()
                }
                    .font(.headline)
                    .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.orange)
                .cornerRadius(8)
            }
        }
        .padding()
    }
}

// MARK: - Supporting Views
struct ProfileCard: View {
    let profile: UserProfile
    
    var body: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(profile.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(profile.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct FeatureCard: View {
    let feature: AppFeature
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: feature.icon)
                .font(.system(size: 24))
                .foregroundColor(feature.color)
            
            Text(feature.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(isSelected ? feature.color.opacity(0.1) : Color(.tertiarySystemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? feature.color : Color.clear, lineWidth: 2)
        )
    }
}

struct FeatureShoppingCard: View {
    let feature: AppFeature
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        VStack(spacing:12) {
            HStack {
                Image(systemName: feature.icon)
                    .font(.system(size: 24))
                    .foregroundColor(feature.color)
                
                Spacer()
                
                Button(action: onToggle) {
                    Image(systemName: isSelected ? "minus.circle.fill" : "plus.circle.fill")
                        .foregroundColor(isSelected ? .red : .green)
                        .font(.title2)
                }
            }
            
                VStack(alignment: .leading, spacing: 4) {
                Text(feature.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                Text(feature.description)
                        .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(isSelected ? feature.color.opacity(0.1) : Color(.secondarySystemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? feature.color : Color.clear, lineWidth: 2)
        )
    }
}

struct DashboardPreview: View {
    let widgets: [DashboardWidget]
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(0..<2) { row in
                HStack(spacing: 8) {
                    ForEach(0..<2) { col in
                        if let widget = widgets.first(where: { $0.position == (row, col) }) {
                            WidgetPreview(widget: widget)
                        } else {
                            EmptyWidgetSlot()
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
    }
}

struct WidgetPreview: View {
    let widget: DashboardWidget
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: widget.type.icon)
                .font(.system(size: 16))
                .foregroundColor(.blue)
            
            Text(widget.type.displayName)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
}

struct EmptyWidgetSlot: View {
    var body: some View {
        Rectangle()
            .fill(Color(.quaternarySystemFill))
            .cornerRadius(8)
            .overlay(
                Image(systemName: "plus")
                    .foregroundColor(.secondary)
                    .font(.caption)
            )
    }
}

struct WidgetSelectionCard: View {
    let widgetType: DashboardWidgetType
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            VStack(spacing: 8) {
                Image(systemName: widgetType.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(widgetType.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.blue : Color(.secondarySystemBackground))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ConflictCard: View {
    let conflict: String
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            
            Text(conflict)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
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

// MARK: - Feature Preview Row
struct FeaturePreviewRow: View {
    let icon: String
    let title: String
    let description: String
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Completion Screen
struct CompletionScreen: View {
    @ObservedObject var viewModel: OnboardingViewModel
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            Text("Setup Complete!")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("You're ready to start using AreaBook.")
                .font(.title2)
                .foregroundColor(.secondary)
            Spacer()
            Button(action: {
                viewModel.completeOnboarding()
            }) {
                Text("Continue")
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

#Preview {
    OnboardingFlow()
        .environmentObject(AuthViewModel.shared)
        .environmentObject(DataManager.shared)
}