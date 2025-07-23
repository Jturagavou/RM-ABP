import SwiftUI
import Firebase

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var dataManager: DataManager
    @State private var showingSignOutAlert = false
    @State private var showingDeleteAccountAlert = false
    @State private var showingClearDataAlert = false
    @State private var showClearDataSuccess = false
    
    var body: some View {
        NavigationView {
            List {
                profileSection
                preferencesSection
                appearanceSection
                dataSyncSection
                supportSection
                widgetDebugSection
                accountSection
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
                    deleteUserAccount()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This action cannot be undone. All your data will be permanently deleted.")
            }
            .alert("Clear All Data", isPresented: $showingClearDataAlert) {
                Button("Clear", role: .destructive) {
                    clearAllUserData()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will permanently delete all your goals, tasks, events, notes, and groups. This action cannot be undone. Are you sure?")
            }
            .alert("All data cleared!", isPresented: $showClearDataSuccess) {
                Button("OK", role: .cancel) { }
            }
        }
    }
    
    private var profileSection: some View {
        Section {
            HStack {
                ProfileAvatarView(avatarURL: authViewModel.currentUser?.avatar)
                
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
    }
                
    private var preferencesSection: some View {
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
            
            NavigationLink(destination: AISettingsView()) {
                Label("AI Assistant", systemImage: "brain.head.profile")
            }
        }
    }
                
    private var appearanceSection: some View {
        Section("Appearance") {
            NavigationLink(destination: ColorSettingsView()) {
                Label("Color Settings", systemImage: "paintbrush")
            }
        }
    }
                
    private var dataSyncSection: some View {
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
            
            NavigationLink(destination: WidgetSettingsView()) {
                Label("iOS Widgets", systemImage: "apps.iphone")
            }
            
            NavigationLink(destination: SiriIntegrationView()) {
                Label("Siri Integration", systemImage: "mic")
            }
            
            // Clear All Data Button
            Button(action: { showingClearDataAlert = true }) {
                Label("Clear All Data", systemImage: "trash")
                    .foregroundColor(.red)
            }
        }
    }
                
    private var supportSection: some View {
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
    }
                
    private var widgetDebugSection: some View {
        Section("Widget Debug") {
            Button(action: {
                WidgetDataService.shared.refreshWidgetData()
            }) {
                Label("Refresh Widget Data", systemImage: "arrow.clockwise")
            }
            
            Button(action: {
                debugAuthenticationState()
            }) {
                Label("Debug Authentication State", systemImage: "person.circle")
            }
            
            Button(action: {
                printCurrentDataStatus()
            }) {
                Label("Show Current Data Status", systemImage: "list.bullet.clipboard")
            }
            
            Button(action: {
                WidgetDataService.shared.createSampleDataForTesting()
            }) {
                Label("Create Sample Widget Data", systemImage: "testtube.2")
            }
            
            Button(action: {
                WidgetDataService.shared.syncDataForWidgets()
            }) {
                Label("Sync All Widget Data", systemImage: "icloud.and.arrow.up")
            }
        }
    }
                
    private var accountSection: some View {
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
    
    private func clearAllUserData() {
        guard let userId = authViewModel.currentUser?.id else { return }
        dataManager.clearAllUserData(userId: userId) {
            showClearDataSuccess = true
        }
    }
    
    private func deleteUserAccount() {
        guard let user = authViewModel.currentUser else { return }
        
        // First clear all user data
        dataManager.clearAllUserData(userId: user.id) {
            // Then delete the user account from Firebase Auth
            authViewModel.deleteUserAccount { success in
                if success {
                    // Account deleted successfully, user will be signed out automatically
                    print("✅ Account deleted successfully")
                } else {
                    print("❌ Failed to delete account")
                }
            }
        }
    }
    
    private func printCurrentDataStatus() {
        print("📊 Current Data Status for Widgets:")
        print("=====================================")
        
        // Show current data counts from DataManager
        print("🔹 Key Indicators: \(dataManager.keyIndicators.count) total")
        print("🔹 Goals: \(dataManager.goals.count) total")
        print("🔹 All Tasks: \(dataManager.tasks.count) total")
        print("🔹 All Events: \(dataManager.events.count) total")
        print("🔹 Notes: \(dataManager.notes.count) total")
        
        // Filter data like widgets do
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        let todaysTasks = dataManager.tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate >= today && dueDate < tomorrow
        }
        
        let todaysEvents = dataManager.events.filter { event in
            return event.startTime >= today && event.startTime < tomorrow
        }
        
        let activeGoals = dataManager.goals.filter { $0.status != .completed }
        
        let recentNotes = Array(dataManager.notes.sorted { $0.createdAt > $1.createdAt }.prefix(5))
        
        print("\n📱 Data That Should Appear in Widgets:")
        print("======================================")
        print("📋 Today's Tasks: \(todaysTasks.count)")
        for task in todaysTasks.prefix(3) {
            print("   • \(task.title) (\(task.status.rawValue))")
        }
        
        print("📅 Today's Events: \(todaysEvents.count)")
        for event in todaysEvents.prefix(3) {
            let timeFormatter = DateFormatter()
            timeFormatter.timeStyle = .short
            print("   • \(event.title) at \(timeFormatter.string(from: event.startTime))")
        }
        
        print("🎯 Active Goals: \(activeGoals.count)")
        for goal in activeGoals.prefix(3) {
            let progress = goal.calculatedProgress
            print("   • \(goal.title) (\(progress)%)")
        }
        
        print("📝 Recent Notes: \(recentNotes.count)")
        for note in recentNotes.prefix(3) {
            print("   • \(note.title)")
        }
        
        print("💚 Key Indicators: \(dataManager.keyIndicators.count)")
        for ki in dataManager.keyIndicators.prefix(3) {
            let progress = Int(ki.progressPercentage * 100)
            print("   • \(ki.name): \(ki.currentWeekProgress)/\(ki.weeklyTarget) (\(progress)%)")
        }
        
        print("\n✅ This data should appear in your widgets!")
        print("If widgets are empty, try 'Force Widget Refresh' above.")
    }
    
    private func debugAuthenticationState() {
        print("🔍 Authentication & Widget Debug Information:")
        print("===========================================")
        
        // Check Firebase Auth state
        if let currentUser = Auth.auth().currentUser {
            print("✅ Firebase Auth: User is signed in")
            print("   - User ID: \(currentUser.uid)")
            print("   - Email: \(currentUser.email ?? "No email")")
            print("   - Display Name: \(currentUser.displayName ?? "No display name")")
            print("   - Email Verified: \(currentUser.isEmailVerified)")
        } else {
            print("❌ Firebase Auth: No user is signed in")
        }
        
        // Check AuthViewModel state
        if let viewModelUser = authViewModel.currentUser {
            print("✅ AuthViewModel: User loaded")
            print("   - User ID: \(viewModelUser.id)")
            print("   - Email: \(viewModelUser.email)")
            print("   - Name: \(viewModelUser.name)")
        } else {
            print("❌ AuthViewModel: No user loaded")
        }
        
        // Check widget data storage
        let widgetUserId: String? = WidgetDataUtilities.loadData(String.self, forKey: "currentUserId")
        let lastSync: Date? = WidgetDataUtilities.loadData(Date.self, forKey: "lastSyncTime")
        
        print("\n📱 Widget Data Storage:")
        print("   - Stored User ID: \(widgetUserId ?? "None")")
        print("   - Last Sync Time: \(lastSync?.description ?? "Never")")
        
        // Test App Group UserDefaults
        let testKey = "auth_debug_test"
        let testValue = ["timestamp": "\(Date())", "test": "auth_debug"]
        WidgetDataUtilities.saveData(testValue, forKey: testKey)
        
        if let loadedTest = WidgetDataUtilities.loadData([String: String].self, forKey: testKey) {
            print("✅ App Group UserDefaults: Working")
            print("   - Test Data: \(loadedTest)")
        } else {
            print("❌ App Group UserDefaults: NOT working!")
        }
        
        // Clean up test data
        WidgetDataUtilities.clearData(forKey: testKey)
        
        print("\n🔧 Troubleshooting Steps:")
        if Auth.auth().currentUser == nil {
            print("1. ❌ User not authenticated - Sign in first")
        } else if authViewModel.currentUser == nil {
            print("1. ❌ AuthViewModel not loaded - Try signing out and back in")
        } else if widgetUserId == nil {
            print("1. ❌ Widget data not synced - Try 'Sync All Widget Data'")
        } else {
            print("1. ✅ Authentication looks good")
        }
        
        print("2. Try 'Force Widget Refresh' if data is stale")
        print("3. Check widget on home screen after sync")
        print("4. If still empty, try signing out and back in")
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
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingShareSheet = false
    @State private var exportURL: URL?
    @State private var isExporting = false
    @State private var exportMessage = ""
    
    var body: some View {
        List {
            Section("Export Options") {
                Button("Export All Data") {
                    exportAllData()
                }
                
                Button("Export Goals Only") {
                    exportGoalsOnly()
                }
                
                Button("Export Tasks Only") {
                    exportTasksOnly()
                }
                
                Button("Export Notes Only") {
                    exportNotesOnly()
                }
            }
            
            Section {
                Text("Exported data will be saved as a JSON file that you can import into other apps or keep as a backup.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if isExporting {
                Section {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Exporting data...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
                }
            }
            
            if !exportMessage.isEmpty {
                Section {
                    Text(exportMessage)
                        .font(.caption)
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                }
            }
        }
        .navigationTitle("Export Data")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportURL {
                ShareSheet(activityItems: [url])
            }
        }
    }
    
    private func exportAllData() {
        isExporting = true
        exportMessage = ""
        
        guard let userId = authViewModel.currentUser?.id else {
            exportMessage = "Error: User not found"
            isExporting = false
            return
        }
        
        let exportData = ExportData(
            userId: userId,
            exportDate: Date(),
            keyIndicators: dataManager.keyIndicators,
            goals: dataManager.goals,
            tasks: dataManager.tasks,
            events: dataManager.events,
            notes: dataManager.notes,
            groups: dataManager.accountabilityGroups
        )
        
        exportToFile(exportData, filename: "areabook_all_data.json")
    }
    
    private func exportGoalsOnly() {
        isExporting = true
        exportMessage = ""
        
        guard let userId = authViewModel.currentUser?.id else {
            exportMessage = "Error: User not found"
            isExporting = false
            return
        }
        
        let exportData = ExportData(
            userId: userId,
            exportDate: Date(),
            keyIndicators: [],
            goals: dataManager.goals,
            tasks: [],
            events: [],
            notes: [],
            groups: []
        )
        
        exportToFile(exportData, filename: "areabook_goals.json")
    }
    
    private func exportTasksOnly() {
        isExporting = true
        exportMessage = ""
        
        guard let userId = authViewModel.currentUser?.id else {
            exportMessage = "Error: User not found"
            isExporting = false
            return
        }
        
        let exportData = ExportData(
            userId: userId,
            exportDate: Date(),
            keyIndicators: [],
            goals: [],
            tasks: dataManager.tasks,
            events: [],
            notes: [],
            groups: []
        )
        
        exportToFile(exportData, filename: "areabook_tasks.json")
    }
    
    private func exportNotesOnly() {
        isExporting = true
        exportMessage = ""
        
        guard let userId = authViewModel.currentUser?.id else {
            exportMessage = "Error: User not found"
            isExporting = false
            return
        }
        
        let exportData = ExportData(
            userId: userId,
            exportDate: Date(),
            keyIndicators: [],
            goals: [],
            tasks: [],
            events: [],
            notes: dataManager.notes,
            groups: []
        )
        
        exportToFile(exportData, filename: "areabook_notes.json")
    }
    
    private func exportToFile(_ data: ExportData, filename: String) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            
            let jsonData = try encoder.encode(data)
            
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsPath.appendingPathComponent(filename)
            
            try jsonData.write(to: fileURL)
            
            exportURL = fileURL
            exportMessage = "Data exported successfully!"
            showingShareSheet = true
        } catch {
            exportMessage = "Error exporting data: \(error.localizedDescription)"
        }
        
        isExporting = false
    }
}

// MARK: - Supporting Views and Models

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct ExportData: Codable {
    let userId: String
    let exportDate: Date
    let keyIndicators: [KeyIndicator]
    let goals: [Goal]
    let tasks: [AppTask]
    let events: [CalendarEvent]
    let notes: [Note]
    let groups: [AccountabilityGroup]
    
    var summary: String {
        """
        AreaBook Data Export
        User ID: \(userId)
        Export Date: \(exportDate.formatted())
        
        Summary:
        - Key Indicators: \(keyIndicators.count)
        - Goals: \(goals.count)
        - Tasks: \(tasks.count)
        - Events: \(events.count)
        - Notes: \(notes.count)
        - Groups: \(groups.count)
        """
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
    @State private var includeSystemInfo = true
    @State private var showingSendAlert = false
    @State private var isSending = false
    @State private var sendSuccess = false
    
    var body: some View {
        List {
            Section("Send Feedback") {
                Text("We'd love to hear from you! Send us your feedback, suggestions, or report any issues you encounter.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Section("Feedback Type") {
                Picker("Type", selection: $feedbackType) {
                    ForEach(FeedbackType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
                
            Section("Your Feedback") {
                TextEditor(text: $feedbackText)
                    .frame(minHeight: 120)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                
                Text("\(feedbackText.count) characters")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("Additional Information") {
                Toggle("Include System Information", isOn: $includeSystemInfo)
                
                if includeSystemInfo {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("System Info:")
                            .font(.caption)
                            .fontWeight(.semibold)
                        
                        Text(systemInfo)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section {
                Button(action: sendFeedback) {
                    HStack {
                        if isSending {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text("Send Feedback")
                            .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                }
                .disabled(feedbackText.isEmpty || isSending)
            }
            
            if sendSuccess {
                Section {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Feedback sent successfully! Thank you.")
                            .foregroundColor(.green)
            }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
                }
            }
        }
            .navigationTitle("Send Feedback")
            .navigationBarTitleDisplayMode(.inline)
        .alert("Send Feedback", isPresented: $showingSendAlert) {
            Button("Send", role: .destructive) {
                submitFeedback()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to send this feedback?")
        }
    }
    
    private var systemInfo: String {
        let device = UIDevice.current
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        
        return """
        Device: \(device.model)
        iOS Version: \(device.systemVersion)
        App Version: \(appVersion) (\(buildNumber))
        Date: \(Date().formatted())
        """
    }
    
    private func sendFeedback() {
        showingSendAlert = true
    }
    
    private func submitFeedback() {
        isSending = true
        sendSuccess = false
        
        let _ = FeedbackData(
            type: feedbackType,
            message: feedbackText,
            systemInfo: includeSystemInfo ? systemInfo : nil,
            timestamp: Date()
        )
        
        // Simulate sending feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isSending = false
            sendSuccess = true
            feedbackText = ""
            
            // Reset after showing success message
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                sendSuccess = false
            }
        }
    }
}

// MARK: - Supporting Models

enum FeedbackType: String, CaseIterable, Codable {
    case general, bug, feature, improvement, other
    
    var displayName: String {
        switch self {
        case .general: return "General"
        case .bug: return "Bug Report"
        case .feature: return "Feature Request"
        case .improvement: return "Improvement"
        case .other: return "Other"
        }
    }
}

struct FeedbackData: Codable {
    let type: FeedbackType
    let message: String
    let systemInfo: String?
    let timestamp: Date
}

struct AboutView: View {
    var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    Image("AppLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                    
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

struct WidgetSettingsView: View {
    @State private var widgetSize: WidgetSize = .medium
    @State private var widgetTheme: WidgetTheme = .system
    @State private var refreshInterval: RefreshInterval = .fifteenMinutes
    @State private var showKeyIndicators = true
    @State private var showTasks = true
    @State private var showEvents = true
    
    var body: some View {
        List {
            Section("Widget Size") {
                Picker("Size", selection: $widgetSize) {
                    ForEach(WidgetSize.allCases, id: \.self) { size in
                        Text(size.displayName).tag(size)
                    }
                }
            }
            
            Section("Appearance") {
                Picker("Theme", selection: $widgetTheme) {
                    ForEach(WidgetTheme.allCases, id: \.self) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
            }
            
            Section("Content") {
                Toggle("Show Key Indicators", isOn: $showKeyIndicators)
                Toggle("Show Tasks", isOn: $showTasks)
                Toggle("Show Events", isOn: $showEvents)
            }
            
            Section("Refresh") {
                Picker("Refresh Interval", selection: $refreshInterval) {
                    ForEach(RefreshInterval.allCases, id: \.self) { interval in
                        Text(interval.displayName).tag(interval)
                    }
                }
            }
        }
        .navigationTitle("Widget Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SiriIntegrationView: View {
    @State private var siriEnabled = true
    @State private var shortcuts: [String] = []
    
    var body: some View {
        List {
            Section("Siri Integration") {
                Toggle("Enable Siri", isOn: $siriEnabled)
                
                if siriEnabled {
                    Text("You can ask Siri to:")
                        .font(.headline)
                        .padding(.top, 8)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• \"Add a task to AreaBook\"")
                        Text("• \"Show my goals\"")
                        Text("• \"Complete task [name]\"")
                        Text("• \"What's my progress?\"")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 16)
                }
            }
            
            Section("Shortcuts") {
                ForEach(shortcuts, id: \.self) { shortcut in
                    Text(shortcut)
                }
                
                if shortcuts.isEmpty {
                    Text("No shortcuts created yet")
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
        }
        .navigationTitle("Siri Integration")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Profile Avatar View
struct ProfileAvatarView: View {
    let avatarURL: String?
    
    var body: some View {
        let url = URL(string: avatarURL ?? "")
        AsyncImage(url: url) { image in
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
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthViewModel.shared)
        .environmentObject(DataManager.shared)
}
