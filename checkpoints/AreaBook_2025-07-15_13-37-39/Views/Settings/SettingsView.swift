import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var dataManager: DataManager
    @State private var showingSignOutAlert = false
    @State private var showingDeleteAccountAlert = false
    
    var body: some View {
        NavigationView {
            List {
                // Profile Section
                Section {
                    HStack {
                        AsyncImage(url: URL(string: authViewModel.currentUser?.avatar ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 40))
                        }
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(authViewModel.currentUser?.name ?? "User")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text(authViewModel.currentUser?.email ?? "")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .padding(.vertical, 4)
                }
                
                // Preferences Section
                Section("Preferences") {
                    NavigationLink(destination: PreferencesView()) {
                        Label("App Preferences", systemImage: "slider.horizontal.3")
                    }
                    
                    NavigationLink(destination: NotificationSettingsView()) {
                        Label("Notifications", systemImage: "bell")
                    }
                    
                    NavigationLink(destination: KeyIndicatorsSettingsView()) {
                        Label("Key Indicators", systemImage: "chart.bar")
                    }
                }
                
                // Data & Sync Section
                Section("Data & Sync") {
                    NavigationLink(destination: AccountabilityGroupsView()) {
                        Label("Accountability Groups", systemImage: "person.3")
                    }
                    
                    NavigationLink(destination: DataSyncView()) {
                        Label("Data Sync", systemImage: "icloud")
                    }
                    
                    NavigationLink(destination: ExportDataView()) {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                    }
                }
                
                // Support Section
                Section("Support") {
                    NavigationLink(destination: HelpView()) {
                        Label("Help & FAQ", systemImage: "questionmark.circle")
                    }
                    
                    NavigationLink(destination: FeedbackView()) {
                        Label("Send Feedback", systemImage: "envelope")
                    }
                    
                    NavigationLink(destination: AboutView()) {
                        Label("About AreaBook", systemImage: "info.circle")
                    }
                }
                
                // Account Section
                Section("Account") {
                    Button(action: { showingSignOutAlert = true }) {
                        Label("Sign Out", systemImage: "arrow.right.square")
                            .foregroundColor(.red)
                    }
                    
                    Button(action: { showingDeleteAccountAlert = true }) {
                        Label("Delete Account", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Sign Out", role: .destructive) {
                    authViewModel.signOut()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Delete Account", isPresented: $showingDeleteAccountAlert) {
                Button("Delete", role: .destructive) {
                    // TODO: Implement account deletion
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This action cannot be undone. All your data will be permanently deleted.")
            }
        }
    }
}

// MARK: - Settings Sub-Views

struct PreferencesView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var defaultCalendarView: CalendarViewType = .monthly
    @State private var defaultTaskView: TaskViewType = .day
    @State private var notificationsEnabled: Bool = true
    
    var body: some View {
        List {
            Section("Calendar") {
                Picker("Default View", selection: $defaultCalendarView) {
                    ForEach(CalendarViewType.allCases, id: \.self) { viewType in
                        Text(viewType.rawValue.capitalized).tag(viewType)
                    }
                }
            }
            
            Section("Tasks") {
                Picker("Default View", selection: $defaultTaskView) {
                    ForEach(TaskViewType.allCases, id: \.self) { viewType in
                        Text(viewType.rawValue.capitalized).tag(viewType)
                    }
                }
            }
            
            Section("General") {
                Toggle("Enable Notifications", isOn: $notificationsEnabled)
            }
        }
        .navigationTitle("Preferences")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadPreferences()
        }
    }
    
    private func loadPreferences() {
        guard let settings = authViewModel.currentUser?.settings else { return }
        defaultCalendarView = settings.defaultCalendarView
        defaultTaskView = settings.defaultTaskView
        notificationsEnabled = settings.notificationsEnabled
    }
}

struct NotificationSettingsView: View {
    @State private var pushNotifications = true
    @State private var dailyReminders = true
    @State private var taskReminders = true
    @State private var eventReminders = true
    @State private var encouragements = true
    
    var body: some View {
        List {
            Section("Push Notifications") {
                Toggle("Enable Push Notifications", isOn: $pushNotifications)
            }
            
            Section("Reminders") {
                Toggle("Daily KI Review", isOn: $dailyReminders)
                Toggle("Task Reminders", isOn: $taskReminders)
                Toggle("Event Reminders", isOn: $eventReminders)
            }
            
            Section("Accountability") {
                Toggle("Encouragement Messages", isOn: $encouragements)
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct KeyIndicatorsSettingsView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        List {
            Section("Current Key Indicators") {
                ForEach(dataManager.keyIndicators) { ki in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Circle()
                                .fill(Color(hex: ki.color) ?? .blue)
                                .frame(width: 12, height: 12)
                            Text(ki.name)
                                .font(.headline)
                            Spacer()
                            Text("\(ki.weeklyTarget) \(ki.unit)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        ProgressView(value: ki.progressPercentage)
                            .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: ki.color) ?? .blue))
                    }
                    .padding(.vertical, 4)
                }
                
                if dataManager.keyIndicators.isEmpty {
                    Text("No Key Indicators created yet")
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
        }
        .navigationTitle("Key Indicators")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AccountabilityGroupsView: View {
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        List {
            Section("My Groups") {
                ForEach(dataManager.accountabilityGroups) { group in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(group.name)
                            .font(.headline)
                        Text(group.type.rawValue.capitalized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(group.members.count) members")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                if dataManager.accountabilityGroups.isEmpty {
                    Text("No accountability groups yet")
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
        }
        .navigationTitle("Accountability Groups")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DataSyncView: View {
    @State private var lastSyncDate = Date()
    @State private var isCloudSyncEnabled = true
    @State private var isSyncing = false
    
    var body: some View {
        List {
            Section("Cloud Sync") {
                Toggle("Enable Cloud Sync", isOn: $isCloudSyncEnabled)
                
                HStack {
                    Text("Last Sync")
                    Spacer()
                    Text(lastSyncDate, style: .relative)
                        .foregroundColor(.secondary)
                }
                
                Button(action: syncNow) {
                    HStack {
                        if isSyncing {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text("Sync Now")
                    }
                }
                .disabled(isSyncing)
            }
        }
        .navigationTitle("Data Sync")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func syncNow() {
        isSyncing = true
        // Simulate sync delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            lastSyncDate = Date()
            isSyncing = false
        }
    }
}

struct ExportDataView: View {
    var body: some View {
        List {
            Section("Export Options") {
                Button("Export All Data") {
                    // TODO: Implement data export
                }
                
                Button("Export Goals Only") {
                    // TODO: Implement goals export
                }
                
                Button("Export Tasks Only") {
                    // TODO: Implement tasks export
                }
                
                Button("Export Notes Only") {
                    // TODO: Implement notes export
                }
            }
            
            Section {
                Text("Exported data will be saved as a JSON file that you can import into other apps or keep as a backup.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Export Data")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HelpView: View {
    var body: some View {
        List {
            Section("Getting Started") {
                NavigationLink("How to use AreaBook", destination: Text("Help content"))
                NavigationLink("Creating your first goal", destination: Text("Help content"))
                NavigationLink("Setting up Key Indicators", destination: Text("Help content"))
            }
            
            Section("Features") {
                NavigationLink("Managing Tasks", destination: Text("Help content"))
                NavigationLink("Calendar & Events", destination: Text("Help content"))
                NavigationLink("Note Taking", destination: Text("Help content"))
                NavigationLink("Accountability Groups", destination: Text("Help content"))
            }
        }
        .navigationTitle("Help & FAQ")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FeedbackView: View {
    @State private var feedbackText = ""
    @State private var feedbackType: FeedbackType = .general
    
    enum FeedbackType: String, CaseIterable {
        case general = "General"
        case bug = "Bug Report"
        case feature = "Feature Request"
        case improvement = "Improvement"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Picker("Feedback Type", selection: $feedbackType) {
                    ForEach(FeedbackType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                TextEditor(text: $feedbackText)
                    .frame(minHeight: 200)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
                Button("Send Feedback") {
                    // TODO: Implement feedback sending
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(feedbackText.isEmpty)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Send Feedback")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct AboutView: View {
    var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "book.pages")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("AreaBook")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Version 1.0.0")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Your spiritual productivity companion")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            
            Section("Credits") {
                Text("Developed with ❤️ for spiritual growth and productivity")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthViewModel())
        .environmentObject(DataManager.shared)
}