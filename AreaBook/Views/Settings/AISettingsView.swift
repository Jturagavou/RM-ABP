import SwiftUI
import FirebaseAuth

struct AISettingsView: View {
    @StateObject private var aiService = AIService.shared
    @State private var showingOnboarding = false
    @State private var showingPrivacyInfo = false
    
    var body: some View {
        NavigationView {
            Form {
                // AI Assistant Status
                Section {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.accentColor)
                        Text("AI Assistant")
                        Spacer()
                        if let _ = aiService.userProfile {
                            Text("Enabled")
                                .foregroundColor(.green)
                        }
                    }
                } header: {
                    Text("Status")
                }
                
                // User Role & Preferences
                if let profile = aiService.userProfile {
                    Section {
                        NavigationLink {
                            RoleSelectionView(selectedProfile: Binding(
                                get: { profile.settings.userProfile },
                                set: { newProfile in
                                    var updatedProfile = profile
                                    updatedProfile.settings.userProfile = newProfile
                                    aiService.saveUserProfile(updatedProfile)
                                }
                            ))
                        } label: {
                            HStack {
                                Image(systemName: "person.crop.circle")
                                Text("Primary Focus")
                                Spacer()
                                Text(profile.settings.userProfile.displayName)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        NavigationLink {
                            AIPreferencesView(preferences: Binding(
                                get: { profile.settings.aiPreferences },
                                set: { newPreferences in
                                    var updatedProfile = profile
                                    updatedProfile.settings.aiPreferences = newPreferences
                                    aiService.saveUserProfile(updatedProfile)
                                }
                            ))
                        } label: {
                            HStack {
                                Image(systemName: "slider.horizontal.3")
                                Text("Assistant Preferences")
                            }
                        }
                    } header: {
                        Text("Personalization")
                    }
                }
                
                // Privacy Settings
                Section {
                    if let profile = aiService.userProfile {
                        Toggle("Passive AI Observations", isOn: Binding(
                            get: { false },
                            set: { newValue in
                                let updatedProfile = profile
                                // updatedProfile.settings.passiveAIOptIn = newValue
                                aiService.saveUserProfile(updatedProfile)
                            }
                        ))
                        
                        Toggle("Assistant Interaction Logging", isOn: Binding(
                            get: { false },
                            set: { newValue in
                                let updatedProfile = profile
                                // updatedProfile.settings.assistantLoggingOptIn = newValue
                                aiService.saveUserProfile(updatedProfile)
                            }
                        ))
                        
                        Toggle("Emotional Tracking", isOn: Binding(
                            get: { false },
                            set: { newValue in
                                let updatedProfile = profile
                                // updatedProfile.settings.emotionalTrackingOptIn = newValue
                                aiService.saveUserProfile(updatedProfile)
                            }
                        ))
                    }
                    
                    Button("Learn More About Privacy") {
                        showingPrivacyInfo = true
                    }
                    .foregroundColor(.accentColor)
                } header: {
                    Text("Privacy & Data")
                } footer: {
                    Text("Your data is used only to provide personalized AI assistance. You can control what data is collected and used.")
                }
                
                // AI Features
                Section {
                    NavigationLink {
                        AISuggestionsListView()
                    } label: {
                        HStack {
                            Image(systemName: "lightbulb")
                            Text("AI Suggestions")
                            Spacer()
                            if !aiService.currentSuggestions.isEmpty {
                                Text("\(aiService.currentSuggestions.count)")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(Color.accentColor)
                                    )
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    
                    NavigationLink {
                        AssistantPlansView()
                    } label: {
                        HStack {
                            Image(systemName: "wand.and.stars")
                            Text("Generated Plans")
                        }
                    }
                    
                    NavigationLink {
                        AssistantLogsView()
                    } label: {
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                            Text("Interaction History")
                        }
                    }
                } header: {
                    Text("AI Features")
                }
                
                // Data Management
                Section {
                    Button("Re-run Onboarding") {
                        showingOnboarding = true
                    }
                    .foregroundColor(.accentColor)
                    
                    Button("Reset AI Profile") {
                        resetAIProfile()
                    }
                    .foregroundColor(.red)
                } header: {
                    Text("Data Management")
                } footer: {
                    Text("Resetting your AI profile will clear all learned patterns and start fresh.")
                }
            }
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingOnboarding) {
                // TODO: Add AI onboarding view in future update
                Text("AI Onboarding")
                    .padding()
            }
            .sheet(isPresented: $showingPrivacyInfo) {
                PrivacyInfoView()
            }
        }
    }
    
    private func resetAIProfile() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Create a new passive profile
        let newProfile = PassiveAIProfile(userId: userId)
        aiService.savePassiveProfile(newProfile)
        
        // Clear suggestions
        for suggestion in aiService.currentSuggestions {
            aiService.dismissSuggestion(suggestion)
        }
    }
}

struct RoleSelectionView: View {
    @Binding var selectedProfile: UserProfile
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            ForEach(UserProfile.allCases, id: \.self) { role in
                Button(action: {
                    selectedProfile = role
                    dismiss()
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(role.displayName)
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            Text(role.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if selectedProfile == role {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .navigationTitle("Primary Focus")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AIPreferencesView: View {
    @Binding var preferences: AIPreferences
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            Section {
                Picker("Assistant Style", selection: $preferences.assistantStyle) {
                    ForEach(AssistantStyle.allCases, id: \.self) { style in
                        Text(style.rawValue.capitalized)
                            .tag(style)
                    }
                }
            } header: {
                Text("Preferences")
            } footer: {
                Text("These settings will customize how the AI assistant interacts with you and what data it collects.")
            }
        }
        .navigationTitle("AI Preferences")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AISuggestionsListView: View {
    @StateObject private var aiService = AIService.shared
    
    var body: some View {
        List {
            if aiService.currentSuggestions.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "lightbulb")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("No Suggestions")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("AI suggestions will appear here based on your activity patterns.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                ForEach(aiService.currentSuggestions) { suggestion in
                    SuggestionRowView(suggestion: suggestion)
                }
            }
        }
        .navigationTitle("AI Suggestions")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SuggestionRowView: View {
    let suggestion: AISuggestion
    @StateObject private var aiService = AIService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: suggestion.type.icon)
                    .foregroundColor(suggestion.priority.color)
                
                Text(suggestion.type.displayName)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(suggestion.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(suggestion.message)
                .font(.body)
                .foregroundColor(.secondary)
            
            if suggestion.status == .pending {
                HStack {
                    Button("Accept") {
                        aiService.acceptSuggestion(suggestion)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    
                    Button("Dismiss") {
                        aiService.dismissSuggestion(suggestion)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    
                    Spacer()
                }
            } else {
                HStack {
                    Text(suggestion.status.rawValue.capitalized)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(statusColor.opacity(0.2))
                        )
                        .foregroundColor(statusColor)
                    
                    Spacer()
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var statusColor: Color {
        switch suggestion.status {
        case .accepted: return .green
        case .dismissed: return .red
        case .expired: return .orange
        case .pending: return .blue
        }
    }
}

struct AssistantPlansView: View {
    @State private var plans: [AssistantPlan] = []
    @State private var isLoading = true
    
    var body: some View {
        List {
            if isLoading {
                ProgressView("Loading plans...")
            } else if plans.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("No Plans")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("AI-generated plans will appear here.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                ForEach(plans) { plan in
                    PlanRowView(plan: plan)
                }
            }
        }
        .navigationTitle("Generated Plans")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadPlans()
        }
    }
    
    private func loadPlans() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        Task {
            let loadedPlans = await AIService.shared.loadAssistantPlans(userId: userId)
            await MainActor.run {
                plans = loadedPlans
                isLoading = false
            }
        }
    }
}

struct PlanRowView: View {
    let plan: AssistantPlan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(plan.intent)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(plan.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Label("\(plan.goals.count) Goals", systemImage: "target")
                Label("\(plan.tasks.count) Tasks", systemImage: "checklist")
                Label("\(plan.events.count) Events", systemImage: "calendar")
                Label("\(plan.notes.count) Notes", systemImage: "doc.text")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            Text(plan.status.rawValue.capitalized)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(statusColor.opacity(0.2))
                )
                .foregroundColor(statusColor)
        }
        .padding(.vertical, 4)
    }
    
    private var statusColor: Color {
        switch plan.status {
        case .draft: return .orange
        case .active: return .green
        case .completed: return .blue
        case .cancelled: return .red
        }
    }
}

struct AssistantLogsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("Coming Soon")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Interaction history and analytics will be available in a future update.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .navigationTitle("Interaction History")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacyInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        PrivacySection(
                            title: "What Data We Collect",
                            content: "We collect information about your tasks, goals, events, and notes to provide personalized AI assistance. This includes completion patterns, preferences, and interaction history."
                        )
                        
                        PrivacySection(
                            title: "How We Use Your Data",
                            content: "Your data is used exclusively to generate personalized suggestions, create plans, and improve the AI assistant's understanding of your needs and patterns."
                        )
                        
                        PrivacySection(
                            title: "Data Security",
                            content: "All data is encrypted in transit and at rest. We use industry-standard security measures to protect your information."
                        )
                        
                        PrivacySection(
                            title: "Your Control",
                            content: "You can control what data is collected through the privacy settings. You can disable features, delete your AI profile, or opt out of data collection entirely."
                        )
                        
                        PrivacySection(
                            title: "Third-Party Services",
                            content: "We may use third-party AI services (like OpenAI) to generate responses. These services are bound by strict privacy agreements and do not retain your personal data."
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Privacy & Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PrivacySection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    AISettingsView()
} 