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
    @State private var showingQuickActions = false
    
    enum Tab: String, CaseIterable {
        case dashboard = "Dashboard"
        case goals = "Goals"
        case calendar = "Calendar"
        case tasks = "Tasks"
        case notes = "Notes"
        
        var icon: String {
            switch self {
            case .dashboard: return "house.fill"
            case .goals: return "flag.fill"
            case .calendar: return "calendar"
            case .tasks: return "checkmark.square.fill"
            case .notes: return "doc.text.fill"
            }
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tabItem {
                        Label("Dashboard", systemImage: "house.fill")
                    }
                    .tag(Tab.dashboard)
                
                GoalsView()
                    .tabItem {
                        Label("Goals", systemImage: "flag.fill")
                    }
                    .tag(Tab.goals)
                
                CalendarView()
                    .tabItem {
                        Label("Calendar", systemImage: "calendar")
                    }
                    .tag(Tab.calendar)
                
                TasksView()
                    .tabItem {
                        Label("Tasks", systemImage: "checkmark.square.fill")
                    }
                    .tag(Tab.tasks)
                
                NotesView()
                    .tabItem {
                        Label("Notes", systemImage: "doc.text.fill")
                    }
                    .tag(Tab.notes)
            }
            
            // Floating Action Button
            FloatingActionButton(showingQuickActions: $showingQuickActions)
                .padding(.bottom, 90)
                .padding(.trailing, 20)
        }
        .overlay {
            if showingQuickActions {
                QuickActionsMenu(isPresented: $showingQuickActions)
                    .transition(.opacity)
            }
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