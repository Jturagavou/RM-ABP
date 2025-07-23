import SwiftUI
import os.log

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var widgetDataService: WidgetDataService
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                MainTabView()
                    .onAppear {
                        os_log("🔐 ContentView: User is authenticated, showing MainTabView", log: .default, type: .info)
                        os_log("🔐 ContentView: Current user ID: %{public}@", log: .default, type: .info, authViewModel.currentUser?.id ?? "nil")
                        if let userId = authViewModel.currentUser?.id {
                            dataManager.setupListeners(for: userId)
                            // Start widget data sync
                            widgetDataService.syncDataForWidgets()
                            widgetDataService.startRealtimeUpdates()
                        }
                    }
                    .onDisappear {
                        dataManager.removeListeners()
                        widgetDataService.stopRealtimeUpdates()
                    }
            } else {
                AuthenticationView()
                    .onAppear {
                        os_log("🔐 ContentView: User is NOT authenticated, showing AuthenticationView", log: .default, type: .info)
                        os_log("🔐 ContentView: isAuthenticated: %{public}@", log: .default, type: .info, String(describing: authViewModel.isAuthenticated))
                        os_log("🔐 ContentView: currentUser: %{public}@", log: .default, type: .info, authViewModel.currentUser?.id ?? "nil")
                    }
            }
        }
        .onAppear {
            os_log("🔐 ContentView: View appeared - isAuthenticated: %{public}@", log: .default, type: .info, String(describing: authViewModel.isAuthenticated))
        }
        .onChange(of: authViewModel.isAuthenticated) { newValue in
            os_log("🔐 ContentView: Authentication state changed to: %{public}@", log: .default, type: .info, String(describing: newValue))
        }
        .overlay(
            // Error message overlay
            Group {
                if authViewModel.showError {
                    VStack {
                        Spacer()
                        HStack {
                            Text(authViewModel.errorMessage)
                                .foregroundColor(.white)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .background(Color.red.opacity(0.9))
                                .cornerRadius(12)
                            Button(action: { authViewModel.showError = false }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white)
                                    .padding(.trailing, 8)
                            }
                        }
                        if authViewModel.errorMessage.contains("network") || authViewModel.errorMessage.contains("retry") {
                            Button("Retry") {
                                // Add retry logic here if available
                                authViewModel.showError = false
                            }
                            .foregroundColor(.white)
                            .padding(.bottom, 8)
                        }
                    }
                    .padding()
                    .transition(.move(edge: .bottom))
                    .animation(.easeInOut, value: authViewModel.showError)
                }
                
                if dataManager.showError {
                    VStack {
                        Spacer()
                        HStack {
                            Text(dataManager.errorMessage)
                                .foregroundColor(.white)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .background(Color.red.opacity(0.9))
                                .cornerRadius(12)
                            Button(action: { dataManager.showError = false }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white)
                                    .padding(.trailing, 8)
                            }
                        }
                        if dataManager.errorMessage.contains("network") || dataManager.errorMessage.contains("retry") {
                            Button("Retry") {
                                // Add retry logic here if available
                                dataManager.showError = false
                            }
                            .foregroundColor(.white)
                            .padding(.bottom, 8)
                        }
                    }
                    .padding()
                    .transition(.move(edge: .bottom))
                    .animation(.easeInOut, value: dataManager.showError)
                }
            }
        )

    }
}

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab: Tab = .dashboard
    @State private var isDashboardEditMode = false
    @State private var isFloatingButtonExpanded = false
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var isEditingMode = false
    @State private var editingTab: Tab? = nil
    
    // Dynamic tabs based on user's enabled features
    private var availableTabs: [Tab] {
        // For now, show all main tabs regardless of settings
        let mainTabs: [Tab] = [.dashboard, .goals, .calendar, .tasks, .groups, .notes, .settings]
        
        // If user has specific settings, use them, otherwise show main tabs
        let enabledFeatures = authViewModel.currentUser?.settings.enabledFeatures ?? Set(AppFeature.defaultFeatures)
        
        if enabledFeatures.isEmpty || enabledFeatures == Set(AppFeature.defaultFeatures) {
            return mainTabs
        } else {
            return Tab.allCases.filter { tab in
                enabledFeatures.contains(tab.correspondingFeature)
            }
        }
    }
    
    private var currentTabIndex: Int {
        availableTabs.firstIndex(of: selectedTab) ?? 0
    }
    
    enum Tab: String, CaseIterable {
        case dashboard = "Dashboard"
        case goals = "Goals"
        case calendar = "Calendar"
        case tasks = "Tasks"
        case notes = "Notes"
        case wellness = "Wellness"
        case academic = "Academic"
        case fitness = "Fitness"
        case financial = "Financial"
        case groups = "Groups"
        case settings = "Settings"
        
        // Map tabs to AppFeatures
        var correspondingFeature: AppFeature {
            switch self {
            case .dashboard: return .dashboard
            case .goals: return .goals
            case .calendar: return .calendar
            case .tasks: return .tasks
            case .groups: return .groups
            case .notes: return .notes
            case .wellness: return .moodTracking // Using moodTracking as representative for wellness
            case .academic: return .academicTracking
            case .fitness: return .workoutTracking
            case .financial: return .budgetTracking
            case .settings: return .dashboard // Settings is always available
            }
        }
        
        var icon: String {
            switch self {
            case .dashboard: return "house"
            case .goals: return "flag"
            case .calendar: return "calendar"
            case .tasks: return "checkmark.square"
            case .groups: return "person.3"
            case .notes: return "doc.text"
            case .wellness: return "heart"
            case .academic: return "book"
            case .fitness: return "dumbbell"
            case .financial: return "creditcard"
            case .settings: return "gear"
            }
        }
        
        var selectedIcon: String {
            switch self {
            case .dashboard: return "house.fill"
            case .goals: return "flag.fill"
            case .calendar: return "calendar"
            case .tasks: return "checkmark.square.fill"
            case .groups: return "person.3.fill"
            case .notes: return "doc.text.fill"
            case .wellness: return "heart.fill"
            case .academic: return "book.fill"
            case .fitness: return "dumbbell.fill"
            case .financial: return "creditcard.fill"
            case .settings: return "gear"
            }
        }
        
        var shortName: String {
            switch self {
            case .dashboard: return "Home"
            case .goals: return "Goals"
            case .calendar: return "Cal"
            case .tasks: return "Tasks"
            case .groups: return "Groups"
            case .notes: return "Notes"
            case .wellness: return "Health"
            case .academic: return "Study"
            case .fitness: return "Fit"
            case .financial: return "Money"
            case .settings: return "Settings"
            }
        }
    }
    
    @ViewBuilder
    private func tabContent(for tab: Tab) -> some View {
        switch tab {
        case .dashboard:
            DashboardView(externalEditMode: $isDashboardEditMode)
        case .goals:
            GoalsView()
        case .calendar:
            CalendarView()
        case .tasks:
            TasksView()
        case .groups:
            GroupsView()
        case .notes:
            NotesView()
        case .wellness:
            Text("Wellness View - Coming Soon")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
        case .academic:
            Text("Academic View - Coming Soon")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
        case .fitness:
            Text("Fitness View - Coming Soon")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
        case .financial:
            Text("Financial View - Coming Soon")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
        case .settings:
            SettingsView()
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main Content Area
            GeometryReader { geometry in
                ZStack {
                    // Content Views with Swipe Navigation
                    HStack(spacing: 0) {
                        ForEach(Array(availableTabs.enumerated()), id: \.element) { index, tab in
                            tabContent(for: tab)
                                .frame(width: geometry.size.width)
                                .opacity(selectedTab == tab ? 1.0 : 0.0)
                                .scaleEffect(isEditingMode && editingTab == tab && tab != .calendar ? 0.95 : 1.0) // Exempt calendar
                                .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isEditingMode) // Faster animation
                                .onLongPressGesture(minimumDuration: 0.4) { // Faster long press
                                    if tab != .calendar { // Only non-calendar tabs enter editing mode
                                        startEditingMode(for: tab)
                                    }
                                }
                        }
                    }
                    .offset(x: -CGFloat(currentTabIndex) * geometry.size.width + dragOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                isDragging = true
                                dragOffset = value.translation.width
                            }
                            .onEnded { value in
                                isDragging = false
                                let threshold = geometry.size.width * 0.3
                                let newIndex: Int
                                
                                if value.translation.width > threshold && currentTabIndex > 0 {
                                    // Swipe right - go to previous tab
                                    newIndex = currentTabIndex - 1
                                } else if value.translation.width < -threshold && currentTabIndex < availableTabs.count - 1 {
                                    // Swipe left - go to next tab
                                    newIndex = currentTabIndex + 1
                                } else {
                                    // Return to current tab
                                    newIndex = currentTabIndex
                                }
                                
                                withAnimation(.easeOut(duration: 0.3)) {
                                    selectedTab = availableTabs[newIndex]
                                    dragOffset = 0
                                }
                            }
                    )
                }
            }
            
            // Custom Tab Bar
            HStack(spacing: 0) {
                ForEach(availableTabs, id: \.self) { tab in
                    Button(action: {
                        if isEditingMode {
                            exitEditingMode()
                        } else {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedTab = tab
                            }
                        }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: selectedTab == tab ? tab.selectedIcon : tab.icon)
                                .font(.system(size: 20))
                                .foregroundColor(selectedTab == tab ? .blue : .gray)
                            
                            Text(tab.shortName)
                                .font(.caption2)
                                .foregroundColor(selectedTab == tab ? .blue : .gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            Rectangle()
                                .fill(selectedTab == tab ? Color.blue.opacity(0.1) : Color.clear)
                                .animation(.easeInOut(duration: 0.2), value: selectedTab)
                        )
                        .overlay(
                            // Editing mode indicator
                            Group {
                                if isEditingMode && editingTab == tab {
                                    VStack {
                                        HStack {
                                            Spacer()
                                            Circle()
                                                .fill(Color.red)
                                                .frame(width: 8, height: 8)
                                                .offset(x: -4, y: 4)
                                        }
                                        Spacer()
                                    }
                                }
                            }
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Done button when in editing mode
                if isEditingMode {
                    Button("Done") {
                        exitEditingMode()
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                    .transition(.opacity.combined(with: .scale))
                }
            }
            .background(Color(.systemBackground))
            .overlay(
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 0.5)
                    .frame(maxWidth: .infinity, alignment: .top)
            )
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: -1)
        }
        .overlay(
            // Floating Action Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    FloatingActionButton(
                        isExpanded: $isFloatingButtonExpanded,
                        selectedTab: selectedTab
                    )
                    .padding(.trailing, 20)
                    .padding(.bottom, 100) // Above tab bar
                }
            }
        )
        .ignoresSafeArea(.keyboard)
        .ignoresSafeArea(.container, edges: .bottom)
    }
    
    // MARK: - Editing Mode Functions
    
    private func startEditingMode(for tab: Tab) {
        guard tab != .calendar else { return } // Calendar is exempt from editing mode
        
        withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) { // Faster animation
            isEditingMode = true
            editingTab = tab
        }
        
        // Haptic feedback like iPhone
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Shorter auto-exit time for more responsive feel
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { // Reduced from 3 seconds
            if isEditingMode {
                exitEditingMode()
            }
        }
    }
    
    private func exitEditingMode() {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) { // Faster animation
            isEditingMode = false
            editingTab = nil
        }
    }
}

struct DynamicTabBar: View {
    let availableTabs: [MainTabView.Tab]
    @Binding var selectedTab: MainTabView.Tab
    let isEditMode: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(availableTabs, id: \.self) { tab in
                CustomTabItem(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    action: { selectedTab = tab }
                )
            }
        }
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(.separator)),
            alignment: .top
        )
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: -1)
        .opacity(isEditMode ? 0.3 : 1.0)
        .animation(.easeInOut(duration: 0.3), value: isEditMode)
    }
}

struct CustomTabItem: View {
    let tab: MainTabView.Tab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? Color.accentColor : .secondary)
                
                Text(tab.shortName)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? Color.accentColor : .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DynamicFloatingButton: View {
    let selectedTab: MainTabView.Tab
    let enabledFeatures: Set<AppFeature>
    @Binding var isExpanded: Bool
    @State private var showingCreateTask = false
    @State private var showingCreateEvent = false
    @State private var showingCreateGoal = false
    @State private var showingCreateNote = false
    @State private var showingCreateKeyIndicator = false
    
    // Dynamic action items based on enabled features
    private var availableActions: [FloatingAction] {
        var actions: [FloatingAction] = []
        
        if enabledFeatures.contains(.tasks) {
            actions.append(FloatingAction(
                icon: "checkmark.square",
                label: "Task",
                action: { showingCreateTask = true }
            ))
        }
        
        if enabledFeatures.contains(.calendar) {
            actions.append(FloatingAction(
                icon: "calendar",
                label: "Event",
                action: { showingCreateEvent = true }
            ))
        }
        
        if enabledFeatures.contains(.goals) {
            actions.append(FloatingAction(
                icon: "flag",
                label: "Goal",
                action: { showingCreateGoal = true }
            ))
        }
        
        if enabledFeatures.contains(.notes) {
            actions.append(FloatingAction(
                icon: "doc.text",
                label: "Note",
                action: { showingCreateNote = true }
            ))
        }
        
        if enabledFeatures.contains(.keyIndicators) {
            actions.append(FloatingAction(
                icon: "chart.bar",
                label: "Tracker",
                action: { showingCreateKeyIndicator = true }
            ))
        }
        
        // Wellness features
        if enabledFeatures.contains(.moodTracking) || enabledFeatures.contains(.meditationTimer) || enabledFeatures.contains(.selfCareRoutines) {
            actions.append(FloatingAction(
                icon: "heart",
                label: "Wellness",
                action: { /* Navigate to wellness */ }
            ))
        }
        
        // Academic features
        if enabledFeatures.contains(.academicTracking) || enabledFeatures.contains(.studyTimer) || enabledFeatures.contains(.assignmentManager) {
            actions.append(FloatingAction(
                icon: "book",
                label: "Study",
                action: { /* Navigate to academic */ }
            ))
        }
        
        // Fitness features
        if enabledFeatures.contains(.workoutTracking) || enabledFeatures.contains(.nutritionTracking) || enabledFeatures.contains(.healthMonitoring) {
            actions.append(FloatingAction(
                icon: "dumbbell",
                label: "Fitness",
                action: { /* Navigate to fitness */ }
            ))
        }
        
        // Financial features
        if enabledFeatures.contains(.budgetTracking) || enabledFeatures.contains(.savingsGoals) || enabledFeatures.contains(.investmentMonitoring) {
            actions.append(FloatingAction(
                icon: "creditcard",
                label: "Finance",
                action: { /* Navigate to financial */ }
            ))
        }
        
        return actions
    }
    
    var body: some View {
        VStack(spacing: 16) {
            if isExpanded {
                // Show available actions based on enabled features
                ForEach(availableActions, id: \.label) { action in
                    FloatingActionItem(
                        icon: action.icon,
                        label: action.label,
                        color: Color.accentColor,
                        action: action.action
                    )
                }
            }
            
            // Main Plus Button - only show if there are available actions
            if !availableActions.isEmpty {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "xmark" : "plus")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.accentColor)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                        .rotationEffect(.degrees(isExpanded ? 45 : 0))
                }
            }
        }
        .sheet(isPresented: $showingCreateTask) {
            CreateTaskView()
                .environmentObject(DataManager.shared)
                .environmentObject(AuthViewModel.shared)
        }
        .onChange(of: showingCreateTask) { newValue in
            if newValue {
                isExpanded = false
            }
        }
        .sheet(isPresented: $showingCreateEvent) {
            CreateEventView()
                .environmentObject(DataManager.shared)
                .environmentObject(AuthViewModel.shared)
        }
        .onChange(of: showingCreateEvent) { newValue in
            if newValue {
                isExpanded = false
            }
        }
        .sheet(isPresented: $showingCreateGoal) {
            CreateGoalView()
                .environmentObject(DataManager.shared)
                .environmentObject(AuthViewModel.shared)
        }
        .onChange(of: showingCreateGoal) { newValue in
            if newValue {
                isExpanded = false
            }
        }
        .sheet(isPresented: $showingCreateNote) {
            CreateNoteView()
                .environmentObject(DataManager.shared)
                .environmentObject(AuthViewModel.shared)
        }
        .onChange(of: showingCreateNote) { newValue in
            if newValue {
                isExpanded = false
            }
        }
        .sheet(isPresented: $showingCreateKeyIndicator) {
            CreateKeyIndicatorView()
                .environmentObject(DataManager.shared)
                .environmentObject(AuthViewModel.shared)
        }
        .onChange(of: showingCreateKeyIndicator) { newValue in
            if newValue {
                isExpanded = false
            }
        }
    }
}

struct FloatingAction {
    let icon: String
    let label: String
    let action: () -> Void
}

struct FloatingActionItem: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(color)
                    .clipShape(Circle())
                
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Floating Action Button
struct FloatingActionButton: View {
    @Binding var isExpanded: Bool
    let selectedTab: MainTabView.Tab
    @State private var showingCreateSheet = false
    @State private var createType: CreateType = .task
    
    enum CreateType {
        case task, event, goal, note, keyIndicator
        
        var title: String {
            switch self {
            case .task: return "New Task"
            case .event: return "New Event"
            case .goal: return "New Goal"
            case .note: return "New Note"
            case .keyIndicator: return "New Key Indicator"
            }
        }
        
        var icon: String {
            switch self {
            case .task: return "checkmark.square"
            case .event: return "calendar"
            case .goal: return "flag"
            case .note: return "doc.text"
            case .keyIndicator: return "chart.bar"
            }
        }
        
        var color: Color {
            switch self {
            case .task: return .green
            case .event: return .blue
            case .goal: return .orange
            case .note: return .purple
            case .keyIndicator: return .red
            }
        }
    }
    
    private var quickActions: [CreateType] {
        switch selectedTab {
        case .tasks:
            return [.task, .goal]
        case .calendar:
            return [.event, .task]
        case .goals:
            return [.goal, .keyIndicator]
        case .notes:
            return [.note, .task]
        default:
            return [.task, .event, .goal, .note]
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Quick action buttons (when expanded)
            if isExpanded {
                ForEach(quickActions.reversed(), id: \.self) { action in
                    Button(action: {
                        createType = action
                        showingCreateSheet = true
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isExpanded = false
                        }
                    }) {
                        HStack {
                            Image(systemName: action.icon)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text(action.title)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(action.color)
                        .cornerRadius(25)
                        .shadow(color: action.color.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            
            // Main FAB button
            Button(action: {
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    isExpanded.toggle()
                }
            }) {
                Image(systemName: isExpanded ? "xmark" : "plus")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue, .purple]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .shadow(color: .blue.opacity(0.4), radius: 4, x: 0, y: 2) // Reduced radius from 8 to 4 for better performance
                    .scaleEffect(isExpanded ? 0.9 : 1.0) // Added scale effect for better visual feedback
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            createView(for: createType)
        }
    }
    
    @ViewBuilder
    private func createView(for type: CreateType) -> some View {
        switch type {
        case .task:
            CreateTaskView()
                .environmentObject(DataManager.shared)
                .environmentObject(AuthViewModel.shared)
        case .event:
            CreateEventView()
                .environmentObject(DataManager.shared)
                .environmentObject(AuthViewModel.shared)
        case .goal:
            CreateGoalView()
                .environmentObject(DataManager.shared)
                .environmentObject(AuthViewModel.shared)
        case .note:
            CreateNoteView()
                .environmentObject(DataManager.shared)
                .environmentObject(AuthViewModel.shared)
        case .keyIndicator:
            CreateKeyIndicatorView()
                .environmentObject(DataManager.shared)
                .environmentObject(AuthViewModel.shared)
        }
    }
}


#Preview {
    ContentView()
        .environmentObject(AuthViewModel.shared)
        .environmentObject(DataManager.shared)
}