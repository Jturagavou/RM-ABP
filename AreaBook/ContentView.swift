import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                MainTabView()
                    .onAppear {
                        if let userId = authViewModel.currentUser?.id {
                            dataManager.setupListeners(for: userId)
                        }
                    }
                    .onDisappear {
                        dataManager.removeListeners()
                    }
            } else {
                AuthenticationView()
            }
        }
        .overlay(
            // Toast notifications
            VStack {
                if authViewModel.showError {
                    ToastView(
                        message: authViewModel.errorMessage,
                        type: .error,
                        isShowing: $authViewModel.showError
                    )
                    .onAppear {
                        HapticManager.shared.error()
                    }
                }
                
                if dataManager.showError {
                    ToastView(
                        message: dataManager.errorMessage,
                        type: .error,
                        isShowing: $dataManager.showError
                    )
                    .onAppear {
                        HapticManager.shared.error()
                    }
                }
                
                Spacer()
            }
            .animation(.smoothAppear, value: authViewModel.showError || dataManager.showError)
        )
    }
}

struct MainTabView: View {
    @State private var selectedTab: Tab = .dashboard
    @State private var showingCreateSheet = false
    
    enum Tab: String, CaseIterable {
        case dashboard = "Dashboard"
        case goals = "Goals"
        case calendar = "Calendar"
        case tasks = "Tasks"
        case notes = "Notes"
        case settings = "Settings"
        
        var icon: String {
            switch self {
            case .dashboard: return "house"
            case .goals: return "flag"
            case .calendar: return "calendar"
            case .tasks: return "checkmark.square"
            case .notes: return "doc.text"
            case .settings: return "gear"
            }
        }
        
        var selectedIcon: String {
            switch self {
            case .dashboard: return "house.fill"
            case .goals: return "flag.fill"
            case .calendar: return "calendar"
            case .tasks: return "checkmark.square.fill"
            case .notes: return "doc.text.fill"
            case .settings: return "gear"
            }
        }
        
        var createIcon: String {
            switch self {
            case .dashboard: return "plus"
            case .goals: return "flag.badge.plus"
            case .calendar: return "calendar.badge.plus"
            case .tasks: return "checkmark.square.badge.plus"
            case .notes: return "doc.text.badge.plus"
            case .settings: return "plus"
            }
        }
        
        var accentColor: Color {
            switch self {
            case .dashboard: return .blue
            case .goals: return .orange
            case .calendar: return .purple
            case .tasks: return .green
            case .notes: return .indigo
            case .settings: return .gray
            }
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Image(systemName: selectedTab == .dashboard ? Tab.dashboard.selectedIcon : Tab.dashboard.icon)
                    Text(Tab.dashboard.rawValue)
                }
                .tag(Tab.dashboard)
            
            GoalsView()
                .tabItem {
                    Image(systemName: selectedTab == .goals ? Tab.goals.selectedIcon : Tab.goals.icon)
                    Text(Tab.goals.rawValue)
                }
                .tag(Tab.goals)
            
            CalendarView()
                .tabItem {
                    Image(systemName: selectedTab == .calendar ? Tab.calendar.selectedIcon : Tab.calendar.icon)
                    Text(Tab.calendar.rawValue)
                }
                .tag(Tab.calendar)
            
            TasksView()
                .tabItem {
                    Image(systemName: selectedTab == .tasks ? Tab.tasks.selectedIcon : Tab.tasks.icon)
                    Text(Tab.tasks.rawValue)
                }
                .tag(Tab.tasks)
            
            NotesView()
                .tabItem {
                    Image(systemName: selectedTab == .notes ? Tab.notes.selectedIcon : Tab.notes.icon)
                    Text(Tab.notes.rawValue)
                }
                .tag(Tab.notes)
            
            SettingsView()
                .tabItem {
                    Image(systemName: selectedTab == .settings ? Tab.settings.selectedIcon : Tab.settings.icon)
                    Text(Tab.settings.rawValue)
                }
                .tag(Tab.settings)
        }
        .accentColor(.blue)
        .overlay(
            // Floating Add Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    FloatingActionButton(selectedTab: selectedTab) {
                        showingCreateSheet = true
                    }
                    .padding()
                }
            }
        )
        .sheet(isPresented: $showingCreateSheet) {
            CreateItemSheet(selectedTab: selectedTab)
        }
    }
}

struct FloatingActionButton: View {
    let selectedTab: MainTabView.Tab
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            HapticManager.shared.light()
            withAnimation(.springBounce) {
                action()
            }
        }) {
            Image(systemName: selectedTab.createIcon)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    LinearGradient(
                        colors: [selectedTab.accentColor, selectedTab.accentColor.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
                .shadow(
                    color: selectedTab.accentColor.opacity(0.3),
                    radius: isPressed ? 4 : 8,
                    x: 0,
                    y: isPressed ? 2 :4
                )
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

struct CreateItemSheet: View {
    let selectedTab: MainTabView.Tab
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCreateOption: CreateOption = .task
    @State private var showingCreateView = false
    
    enum CreateOption: String, CaseIterable {
        case task = "Task"
        case event = "Event"
        case goal = "Goal"
        case note = "Note"
        case keyIndicator = "Key Indicator"
        
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
            case .event: return .purple
            case .goal: return .orange
            case .note: return .indigo
            case .keyIndicator: return .blue
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Create New")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 20) {
                    ForEach(CreateOption.allCases, id: \.self) { option in
                        CreateOptionCard(option: option) {
                            HapticManager.shared.medium()
                            selectedCreateOption = option
                            showingCreateView = true
                        }
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        HapticManager.shared.light()
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreateView) {
            createViewForOption(selectedCreateOption)
        }
    }
    
    @ViewBuilder
    private func createViewForOption(_ option: CreateOption) -> some View {
        switch option {
        case .task:
            CreateTaskView()
        case .event:
            CreateEventView()
        case .goal:
            CreateGoalView()
        case .note:
            CreateNoteView()
        case .keyIndicator:
            CreateKeyIndicatorView()
        }
    }
}

struct CreateOptionCard: View {
    let option: CreateItemSheet.CreateOption
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: option.icon)
                    .font(.system(size: 30))
                    .foregroundColor(option.color)
                    .scaleEffect(isPressed ? 0.9 : 1.0)
                
                Text(option.rawValue)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            .frame(height: 100)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(option.color.opacity(0.3), lineWidth: 2)
                    )
            )
            .shadow(
                color: option.color.opacity(0.1),
                radius: isPressed ? 2 : 4,
                x: 0,
                y: isPressed ? 1 : 2
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel.shared)
        .environmentObject(DataManager.shared)
}