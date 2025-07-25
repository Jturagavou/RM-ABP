import SwiftUI
import os.log

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                MainTabView()
                    .onAppear {
                        os_log("🔐 ContentView: User is authenticated, showing MainTabView", log: .default, type: .info)
                        os_log("🔐 ContentView: Current user ID: %{public}@", log: .default, type: .info, authViewModel.currentUser?.id ?? "nil")
                        if let userId = authViewModel.currentUser?.id {
                            dataManager.setupListeners(for: userId)
                        }
                    }
                    .onDisappear {
                        dataManager.removeListeners()
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
                        Text(authViewModel.errorMessage)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(10)
                            .padding()
                    }
                    .transition(.move(edge: .bottom))
                    .animation(.easeInOut, value: authViewModel.showError)
                }
                
                if dataManager.showError {
                    VStack {
                        Spacer()
                        Text(dataManager.errorMessage)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(10)
                            .padding()
                    }
                    .transition(.move(edge: .bottom))
                    .animation(.easeInOut, value: dataManager.showError)
                }
            }
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
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Color.blue)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
        }
    }
}

struct CreateItemSheet: View {
    let selectedTab: MainTabView.Tab
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCreateOption: CreateOption = .task
    
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
                            selectedCreateOption = option
                            // Navigate to appropriate creation view
                            dismiss()
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
                        dismiss()
                    }
                }
            }
        }
    }
}

struct CreateOptionCard: View {
    let option: CreateItemSheet.CreateOption
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: option.icon)
                    .font(.system(size: 30))
                    .foregroundColor(.blue)
                
                Text(option.rawValue)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            .frame(height: 100)
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
        .environmentObject(DataManager.shared)
}