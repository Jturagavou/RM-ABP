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
                    deleteAccount()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This action cannot be undone. All your data will be permanently deleted.")
            }
        }
    }
    
    private func deleteAccount() {
        guard let userId = authViewModel.currentUser?.id else { return }
        
        Task {
            do {
                // Delete all user data from Firestore
                try await dataManager.deleteAllUserData(userId: userId)
                
                // Delete the user account from Firebase Auth
                try await authViewModel.deleteAccount()
                
                await MainActor.run {
                    // User will be automatically signed out
                }
            } catch {
                await MainActor.run {
                    // Handle error - you might want to show an alert
                    print("Failed to delete account: \(error)")
                }
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
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var exportService = DataExportService.shared
    
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var exportMessage = ""
    @State private var shareItems: [Any] = []
    @State private var showingShareSheet = false
    @State private var showingImportPicker = false
    @State private var exportSummary: ExportSummary?
    
    var body: some View {
        List {
            Section("Export Options") {
                Button("Export All Data") {
                    exportData(type: .all)
                }
                .disabled(isExporting)
                
                Button("Export Goals Only") {
                    exportData(type: .goals)
                }
                .disabled(isExporting)
                
                Button("Export Tasks Only") {
                    exportData(type: .tasks)
                }
                .disabled(isExporting)
                
                Button("Export Notes Only") {
                    exportData(type: .notes)
                }
                .disabled(isExporting)
            }
            
            Section("Import Options") {
                Button("Import from JSON") {
                    showingImportPicker = true
                }
                .disabled(isImporting)
            }
            
            if let summary = exportSummary {
                Section("Last Export Summary") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Export Date: \(summary.exportDate, style: .date)")
                        Text("Total Items: \(summary.totalItems)")
                        Text("Goals: \(summary.goalCount)")
                        Text("Tasks: \(summary.taskCount)")
                        Text("Notes: \(summary.noteCount)")
                        Text("Key Indicators: \(summary.keyIndicatorCount)")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            
            Section {
                Text("Exported data will be saved as a JSON file that you can import into other apps or keep as a backup.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if !exportMessage.isEmpty {
                Section("Status") {
                    Text(exportMessage)
                        .font(.caption)
                        .foregroundColor(exportMessage.contains("failed") ? .red : .green)
                }
            }
        }
        .navigationTitle("Export Data")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if isExporting || isImporting {
                ProgressView(isExporting ? "Exporting..." : "Importing...")
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                    .shadow(radius: 4)
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: shareItems)
        }
        .fileImporter(
            isPresented: $showingImportPicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result: result)
        }
    }
    
    enum ExportType {
        case all, goals, tasks, notes
    }
    
    private func exportData(type: ExportType) {
        guard let userId = authViewModel.currentUser?.id else { return }
        
        isExporting = true
        exportMessage = ""
        
        Task {
            do {
                let exportData: ExportData
                
                switch type {
                case .all:
                    exportData = try await exportService.exportAllData(from: dataManager, userId: userId)
                case .goals:
                    exportData = ExportData(
                        exportDate: Date(),
                        userId: userId,
                        keyIndicators: [],
                        goals: dataManager.goals,
                        events: [],
                        tasks: [],
                        notes: [],
                        accountabilityGroups: [],
                        userPreferences: UserPreferences.current
                    )
                case .tasks:
                    exportData = ExportData(
                        exportDate: Date(),
                        userId: userId,
                        keyIndicators: [],
                        goals: [],
                        events: [],
                        tasks: dataManager.tasks,
                        notes: [],
                        accountabilityGroups: [],
                        userPreferences: UserPreferences.current
                    )
                case .notes:
                    exportData = ExportData(
                        exportDate: Date(),
                        userId: userId,
                        keyIndicators: [],
                        goals: [],
                        events: [],
                        tasks: [],
                        notes: dataManager.notes,
                        accountabilityGroups: [],
                        userPreferences: UserPreferences.current
                    )
                }
                
                exportSummary = exportData.summary
                
                let jsonData = try exportService.exportToJSON(data: exportData)
                let fileName = "AreaBook_\(type)_Export_\(Date().formatted(.iso8601.day().month().year())).json"
                let url = try saveExportedData(jsonData, filename: fileName)
                
                await MainActor.run {
                    shareItems = [url]
                    exportMessage = "Export completed successfully!"
                    showingShareSheet = true
                }
                
            } catch {
                await MainActor.run {
                    exportMessage = "Export failed: \(error.localizedDescription)"
                }
            }
            
            await MainActor.run {
                isExporting = false
            }
        }
    }
    
    private func handleImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            isImporting = true
            exportMessage = ""
            
            Task {
                do {
                    let data = try Data(contentsOf: url)
                    let importData = try exportService.importFromJSON(data: data)
                    
                    guard let userId = authViewModel.currentUser?.id else { return }
                    try await exportService.importData(importData, to: dataManager, userId: userId)
                    
                    await MainActor.run {
                        exportMessage = "Import completed successfully!"
                    }
                    
                } catch {
                    await MainActor.run {
                        exportMessage = "Import failed: \(error.localizedDescription)"
                    }
                }
                
                await MainActor.run {
                    isImporting = false
                }
            }
            
        case .failure(let error):
            exportMessage = "Import failed: \(error.localizedDescription)"
        }
    }
    
    private func saveExportedData(_ data: Data, filename: String) throws -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(filename)
        try data.write(to: fileURL)
        return fileURL
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct HelpView: View {
    var body: some View {
        List {
            Section("Getting Started") {
                NavigationLink("How to use AreaBook", destination: HelpContentView(
                    title: "How to use AreaBook",
                    content: """
                    Welcome to AreaBook! This app helps you track your life goals and habits.
                    
                    **Getting Started:**
                    1. Create Key Indicators (KIs) to track weekly habits
                    2. Set up Goals and link them to your KIs
                    3. Create Tasks and Events to work towards your goals
                    4. Use Notes to capture thoughts and ideas
                    5. Join Groups to share progress with others
                    
                    **Navigation:**
                    - Dashboard: Overview of your progress
                    - Goals: Create and manage your goals
                    - Calendar: Schedule events and activities
                    - Tasks: Manage your to-do items
                    - Notes: Capture thoughts and ideas
                    - Groups: Connect with others
                    """
                ))
                NavigationLink("Creating your first goal", destination: HelpContentView(
                    title: "Creating Your First Goal",
                    content: """
                    Goals are the foundation of your progress tracking in AreaBook.
                    
                    **Steps to Create a Goal:**
                    1. Go to the Goals tab
                    2. Tap the + button to create a new goal
                    3. Enter a clear, specific title
                    4. Write a detailed description
                    5. Set a target date (optional)
                    6. Link to relevant Key Indicators
                    7. Add sticky notes for brainstorming
                    8. Choose a category if you have dividers set up
                    
                    **Tips:**
                    - Make goals specific and measurable
                    - Break large goals into smaller tasks
                    - Use sticky notes to capture ideas
                    - Review progress regularly
                    """
                ))
                NavigationLink("Setting up Key Indicators", destination: HelpContentView(
                    title: "Setting up Key Indicators",
                    content: """
                    Key Indicators (KIs) are weekly habits that help you achieve your goals.
                    
                    **Creating a KI:**
                    1. Go to Key Indicators from the dashboard
                    2. Choose from templates or create custom
                    3. Set a weekly target (e.g., 7 for daily habits)
                    4. Choose a unit (sessions, hours, pages, etc.)
                    5. Pick a color for visual organization
                    
                    **Common KI Examples:**
                    - Exercise: 5 sessions per week
                    - Reading: 7 hours per week
                    - Water: 56 glasses per week (8 daily)
                    - Meditation: 7 sessions per week
                    
                    **Updating Progress:**
                    - Use +1 and +5 buttons for quick updates
                    - Progress resets weekly
                    - Link tasks and events to auto-update KIs
                    """
                ))
            }
            
            Section("Features") {
                NavigationLink("Managing Tasks", destination: HelpContentView(
                    title: "Managing Tasks",
                    content: """
                    Tasks help you break down goals into actionable steps.
                    
                    **Creating Tasks:**
                    1. Go to Tasks tab or use the + button
                    2. Enter a clear task title
                    3. Set priority (High, Medium, Low)
                    4. Add due date if needed
                    5. Link to goals and Key Indicators
                    6. Add subtasks for complex work
                    
                    **Task Features:**
                    - Priority color coding
                    - Due date tracking
                    - Subtask management
                    - Time estimation
                    - Goal and KI linking
                    
                    **Completing Tasks:**
                    - Mark tasks as complete
                    - Linked KIs automatically update
                    - Goal progress increases
                    - Timeline entries are created
                    """
                ))
                NavigationLink("Calendar & Events", destination: HelpContentView(
                    title: "Calendar & Events",
                    content: """
                    Use the calendar to schedule activities and track your time.
                    
                    **Creating Events:**
                    1. Go to Calendar tab
                    2. Hold and drag on a date to create quickly
                    3. Or use the + button for detailed creation
                    4. Set start and end times
                    5. Choose a category
                    6. Link to goals and KIs
                    
                    **Recurring Events:**
                    - Daily, weekly, monthly, yearly patterns
                    - Custom day-of-week selection
                    - End date options
                    - Automatic generation
                    
                    **Event Categories:**
                    - Personal, Work, Health, Social, Learning
                    - Color-coded for easy identification
                    - Customizable categories
                    """
                ))
                NavigationLink("Note Taking", destination: HelpContentView(
                    title: "Note Taking",
                    content: """
                    Capture thoughts, ideas, and insights with the Notes feature.
                    
                    **Creating Notes:**
                    1. Go to Notes tab
                    2. Tap "New Note"
                    3. Add title and content
                    4. Use markdown for formatting
                    5. Add tags for organization
                    6. Link to goals, tasks, and other notes
                    
                    **Note Features:**
                    - Markdown support for rich text
                    - Tag system for organization
                    - Linking to goals and tasks
                    - Bi-directional note linking
                    - Search functionality
                    - Preview mode
                    
                    **Organization Tips:**
                    - Use descriptive titles
                    - Add relevant tags
                    - Link related content
                    - Review and update regularly
                    """
                ))
                NavigationLink("Accountability Groups", destination: HelpContentView(
                    title: "Accountability Groups",
                    content: """
                    Connect with others to share progress and stay motivated.
                    
                    **Creating Groups:**
                    1. Go to Groups tab
                    2. Tap "Create Group"
                    3. Enter group name and description
                    4. Configure privacy settings
                    5. Invite members using invitation codes
                    
                    **Group Features:**
                    - Progress sharing
                    - Group challenges
                    - Activity feeds
                    - Member management
                    - Role-based permissions
                    
                    **Joining Groups:**
                    1. Get invitation code from group admin
                    2. Go to Groups tab
                    3. Tap "Join Group"
                    4. Enter invitation code
                    5. Start participating!
                    
                    **Group Roles:**
                    - Admin: Full management access
                    - Moderator: Can manage members
                    - Member: Can participate and share
                    """
                ))
            }
            
            Section("Tips & Tricks") {
                NavigationLink("Widgets & Siri", destination: HelpContentView(
                    title: "Widgets & Siri",
                    content: """
                    Use widgets and Siri shortcuts for quick access to your data.
                    
                    **Home Screen Widgets:**
                    1. Long press on home screen
                    2. Tap the + button
                    3. Search for "AreaBook"
                    4. Choose widget size
                    5. Add to home screen
                    
                    **Widget Sizes:**
                    - Small: KI progress + counts
                    - Medium: KI progress + today's items
                    - Large: Full dashboard view
                    
                    **Siri Shortcuts:**
                    - "Add task to AreaBook"
                    - "Log task success"
                    - "Update my progress"
                    - "What's my schedule today"
                    - "Review my key indicators"
                    
                    **Setting up Siri:**
                    1. Go to Settings > Siri & Search
                    2. Enable "Listen for Hey Siri"
                    3. Use the shortcuts above
                    4. Siri will learn your patterns
                    """
                ))
            }
        }
        .navigationTitle("Help & FAQ")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HelpContentView: View {
    let title: String
    let content: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(content)
                    .font(.body)
                    .lineSpacing(4)
            }
            .padding()
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FeedbackView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var feedbackText = ""
    @State private var feedbackType: FeedbackType = .general
    @State private var isSending = false
    @State private var showingSuccessAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
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
                    sendFeedback()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(feedbackText.isEmpty || isSending)
                
                if isSending {
                    ProgressView("Sending feedback...")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Send Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Feedback Sent", isPresented: $showingSuccessAlert) {
                Button("OK") { }
            } message: {
                Text("Thank you for your feedback! We'll review it and get back to you if needed.")
            }
            .alert("Error", isPresented: $showingErrorAlert) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func sendFeedback() {
        guard let userId = authViewModel.currentUser?.id else { return }
        
        isSending = true
        
        Task {
            do {
                let feedback = [
                    "userId": userId,
                    "userEmail": authViewModel.currentUser?.email ?? "unknown",
                    "type": feedbackType.rawValue,
                    "message": feedbackText,
                    "timestamp": Date().timeIntervalSince1970,
                    "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
                ]
                
                let db = Firestore.firestore()
                try await db.collection("feedback").addDocument(data: feedback)
                
                await MainActor.run {
                    isSending = false
                    feedbackText = ""
                    showingSuccessAlert = true
                }
                
            } catch {
                await MainActor.run {
                    isSending = false
                    errorMessage = "Failed to send feedback: \(error.localizedDescription)"
                    showingErrorAlert = true
                }
            }
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