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
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isExporting = false
    @State private var showShareSheet = false
    @State private var exportURL: URL?
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var successMessage = ""
    
    var body: some View {
        List {
            Section("Export Options") {
                Button(action: exportAllData) {
                    Label("Export All Data", systemImage: "square.and.arrow.up")
                }
                .disabled(isExporting)
                
                Button(action: exportGoals) {
                    Label("Export Goals Only", systemImage: "flag")
                }
                .disabled(isExporting)
                
                Button(action: exportTasks) {
                    Label("Export Tasks Only", systemImage: "checkmark.square")
                }
                .disabled(isExporting)
                
                Button(action: exportNotes) {
                    Label("Export Notes Only", systemImage: "doc.text")
                }
                .disabled(isExporting)
                
                Button(action: exportKeyIndicators) {
                    Label("Export Key Indicators", systemImage: "chart.bar")
                }
                .disabled(isExporting)
            }
            
            Section("Export to CSV") {
                Button(action: exportTasksCSV) {
                    Label("Export Tasks as CSV", systemImage: "tablecells")
                }
                .disabled(isExporting)
                
                Button(action: exportGoalsCSV) {
                    Label("Export Goals as CSV", systemImage: "tablecells")
                }
                .disabled(isExporting)
            }
            
            Section {
                Text("Exported data will be saved as a JSON or CSV file that you can import into other apps or keep as a backup.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Export Data")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if isExporting {
                LoadingOverlay(message: "Exporting...")
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = exportURL {
                ShareSheet(items: [url])
            }
        }
        .alert("Export Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .overlay(alignment: .top) {
            if showSuccess {
                SuccessToast(message: successMessage, icon: "checkmark.circle.fill", isShowing: $showSuccess)
                    .padding(.top, 50)
            }
        }
    }
    
    private func exportAllData() {
        guard let userId = authViewModel.currentUser?.id else { return }
        
        isExporting = true
        Task {
            do {
                let url = try DataExportService.shared.exportAllData(for: userId, dataManager: dataManager)
                await MainActor.run {
                    exportURL = url
                    showShareSheet = true
                    isExporting = false
                    successMessage = "All data exported successfully"
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isExporting = false
                }
            }
        }
    }
    
    private func exportGoals() {
        isExporting = true
        Task {
            do {
                let url = try DataExportService.shared.exportGoals(goals: dataManager.goals)
                await MainActor.run {
                    exportURL = url
                    showShareSheet = true
                    isExporting = false
                    successMessage = "Goals exported successfully"
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isExporting = false
                }
            }
        }
    }
    
    private func exportTasks() {
        isExporting = true
        Task {
            do {
                let url = try DataExportService.shared.exportTasks(tasks: dataManager.tasks)
                await MainActor.run {
                    exportURL = url
                    showShareSheet = true
                    isExporting = false
                    successMessage = "Tasks exported successfully"
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isExporting = false
                }
            }
        }
    }
    
    private func exportNotes() {
        isExporting = true
        Task {
            do {
                let url = try DataExportService.shared.exportNotes(notes: dataManager.notes)
                await MainActor.run {
                    exportURL = url
                    showShareSheet = true
                    isExporting = false
                    successMessage = "Notes exported successfully"
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isExporting = false
                }
            }
        }
    }
    
    private func exportKeyIndicators() {
        isExporting = true
        Task {
            do {
                let url = try DataExportService.shared.exportKeyIndicators(keyIndicators: dataManager.keyIndicators)
                await MainActor.run {
                    exportURL = url
                    showShareSheet = true
                    isExporting = false
                    successMessage = "Key Indicators exported successfully"
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isExporting = false
                }
            }
        }
    }
    
    private func exportTasksCSV() {
        isExporting = true
        Task {
            do {
                let url = try DataExportService.shared.exportTasksToCSV(tasks: dataManager.tasks)
                await MainActor.run {
                    exportURL = url
                    showShareSheet = true
                    isExporting = false
                    successMessage = "Tasks CSV exported successfully"
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isExporting = false
                }
            }
        }
    }
    
    private func exportGoalsCSV() {
        isExporting = true
        Task {
            do {
                let url = try DataExportService.shared.exportGoalsToCSV(goals: dataManager.goals)
                await MainActor.run {
                    exportURL = url
                    showShareSheet = true
                    isExporting = false
                    successMessage = "Goals CSV exported successfully"
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isExporting = false
                }
            }
        }
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
                NavigationLink("How to use AreaBook", destination: HowToUseAreaBookView())
                NavigationLink("Creating your first goal", destination: CreatingFirstGoalView())
                NavigationLink("Setting up Key Indicators", destination: SettingUpKeyIndicatorsView())
            }
            
            Section("Features") {
                NavigationLink("Managing Tasks", destination: ManagingTasksHelpView())
                NavigationLink("Calendar & Events", destination: CalendarEventsHelpView())
                NavigationLink("Note Taking", destination: NoteTakingHelpView())
                NavigationLink("Accountability Groups", destination: AccountabilityGroupsHelpView())
            }
            
            Section("Advanced") {
                NavigationLink("Siri Shortcuts", destination: SiriShortcutsHelpView())
                NavigationLink("Widgets", destination: WidgetsHelpView())
                NavigationLink("Data Export/Import", destination: DataExportImportHelpView())
            }
        }
        .navigationTitle("Help & FAQ")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Additional Help Views
struct ManagingTasksHelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Managing Tasks")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Tasks help you break down your goals into actionable items. Here's how to manage them effectively:")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                HelpSection(
                    title: "Creating Tasks",
                    icon: "plus.circle",
                    description: "Add tasks with priorities, due dates, and subtasks",
                    tips: [
                        "Use high priority for urgent tasks",
                        "Add subtasks to break down complex items",
                        "Link tasks to goals or events for context",
                        "Set realistic due dates"
                    ]
                )
                
                HelpSection(
                    title: "Task Filters",
                    icon: "line.horizontal.3.decrease.circle",
                    description: "Filter tasks to focus on what matters",
                    tips: [
                        "All: View everything at once",
                        "Pending: Focus on incomplete tasks",
                        "Completed: Review your accomplishments",
                        "Overdue: Catch up on missed deadlines"
                    ]
                )
                
                HelpSection(
                    title: "Quick Actions",
                    icon: "hand.tap",
                    description: "Interact with tasks efficiently",
                    tips: [
                        "Tap the circle to mark complete",
                        "Swipe left to delete",
                        "Tap the task to edit details",
                        "Long press for more options"
                    ]
                )
            }
            .padding()
        }
        .navigationTitle("Managing Tasks")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CalendarEventsHelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Calendar & Events")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                HelpSection(
                    title: "Creating Events",
                    icon: "calendar.badge.plus",
                    description: "Schedule and organize your time effectively",
                    tips: [
                        "Set all-day events for important dates",
                        "Create recurring events for regular activities",
                        "Link events to goals for better tracking",
                        "Add tasks to events for preparation"
                    ]
                )
                
                HelpSection(
                    title: "Recurring Events",
                    icon: "repeat",
                    description: "Set up repeating schedules easily",
                    tips: [
                        "Daily: For everyday habits",
                        "Weekly: Select specific days",
                        "Monthly: Same date each month",
                        "Yearly: Annual occasions"
                    ]
                )
            }
            .padding()
        }
        .navigationTitle("Calendar & Events")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct NoteTakingHelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Note Taking")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                HelpSection(
                    title: "Creating Notes",
                    icon: "doc.text",
                    description: "Capture thoughts and ideas effectively",
                    tips: [
                        "Use tags to organize notes by topic",
                        "Link notes to goals and tasks",
                        "Search notes by title or content",
                        "Create folders for organization"
                    ]
                )
            }
            .padding()
        }
        .navigationTitle("Note Taking")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AccountabilityGroupsHelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Accountability Groups")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                HelpSection(
                    title: "Creating Groups",
                    icon: "person.3",
                    description: "Share progress with friends and family",
                    tips: [
                        "Create groups for different purposes",
                        "Share invitation codes securely",
                        "Set group permissions and privacy",
                        "Create challenges to motivate members"
                    ]
                )
                
                HelpSection(
                    title: "Group Features",
                    icon: "bubble.left.and.bubble.right",
                    description: "Collaborate and stay motivated together",
                    tips: [
                        "Share progress updates automatically",
                        "Create group challenges",
                        "Send encouragements to members",
                        "Track group statistics"
                    ]
                )
            }
            .padding()
        }
        .navigationTitle("Accountability Groups")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SiriShortcutsHelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Siri Shortcuts")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Use voice commands to update your progress hands-free:")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 16) {
                    SiriCommandCard(
                        phrase: "Add task to AreaBook",
                        description: "Quickly create a new task",
                        example: "Hey Siri, add task to AreaBook"
                    )
                    
                    SiriCommandCard(
                        phrase: "Log task success",
                        description: "Mark a task as completed",
                        example: "Hey Siri, log task success"
                    )
                    
                    SiriCommandCard(
                        phrase: "Update my life tracker",
                        description: "Record progress on key indicators",
                        example: "Hey Siri, update my life tracker"
                    )
                    
                    SiriCommandCard(
                        phrase: "What's my schedule today",
                        description: "Get your daily overview",
                        example: "Hey Siri, what's my schedule today"
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Siri Shortcuts")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct WidgetsHelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Home Screen Widgets")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Add widgets to your home screen for quick access:")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                WidgetInfoCard(
                    size: "Small",
                    description: "Shows key indicator progress and task count",
                    features: ["Progress bars", "Task summary"]
                )
                
                WidgetInfoCard(
                    size: "Medium",
                    description: "Displays multiple key indicators with details",
                    features: ["4 key indicators", "Progress percentages", "Quick glance"]
                )
                
                WidgetInfoCard(
                    size: "Large",
                    description: "Full dashboard overview on your home screen",
                    features: ["All key indicators", "Today's tasks", "Upcoming events"]
                )
            }
            .padding()
        }
        .navigationTitle("Widgets")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DataExportImportHelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Data Export & Import")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                HelpSection(
                    title: "Export Options",
                    icon: "square.and.arrow.up",
                    description: "Back up your data in multiple formats",
                    tips: [
                        "JSON format for complete backup",
                        "CSV format for spreadsheet analysis",
                        "Export all data or specific sections",
                        "Share files via email or cloud storage"
                    ]
                )
                
                HelpSection(
                    title: "Import Data",
                    icon: "square.and.arrow.down",
                    description: "Restore your data from backups",
                    tips: [
                        "Import from JSON backups",
                        "Merge or replace existing data",
                        "Validate data before importing",
                        "Keep regular backups"
                    ]
                )
            }
            .padding()
        }
        .navigationTitle("Data Export & Import")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Supporting Components
struct SiriCommandCard: View {
    let phrase: String
    let description: String
    let example: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "mic.fill")
                    .foregroundColor(.purple)
                Text(phrase)
                    .font(.headline)
            }
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(example)
                .font(.caption)
                .foregroundColor(.blue)
                .italic()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct WidgetInfoCard: View {
    let size: String
    let description: String
    let features: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(size) Widget")
                .font(.headline)
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(features, id: \.self) { feature in
                    HStack {
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text(feature)
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
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