import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab = 0
    @State private var showingCreateSheet = false
    @State private var createType: CreateType = .task
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard Tab
            DashboardView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Dashboard")
                }
                .tag(0)
            
            // Goals Tab
            GoalsView()
                .tabItem {
                    Image(systemName: "target")
                    Text("Goals")
                }
                .tag(1)
            
            // Calendar Tab
            CalendarView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Calendar")
                }
                .tag(2)
            
            // Tasks Tab
            TasksView()
                .tabItem {
                    Image(systemName: "checkmark.square")
                    Text("Tasks")
                }
                .tag(3)
            
            // Notes Tab
            NotesView()
                .tabItem {
                    Image(systemName: "note.text")
                    Text("Notes")
                }
                .tag(4)
        }
        .overlay(
            // Floating Action Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    
                    Button(action: {
                        showingCreateSheet = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue, .purple]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Circle())
                            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 90) // Above tab bar
                }
            }
        )
        .sheet(isPresented: $showingCreateSheet) {
            CreateItemSheet(createType: $createType)
        }
    }
}

// Create Item Sheet
struct CreateItemSheet: View {
    @Binding var createType: CreateType
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Create New")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 20) {
                    CreateButton(
                        title: "Task",
                        icon: "checkmark.square",
                        color: .blue,
                        action: {
                            createType = .task
                            // Navigate to task creation
                            dismiss()
                        }
                    )
                    
                    CreateButton(
                        title: "Event",
                        icon: "calendar.badge.plus",
                        color: .green,
                        action: {
                            createType = .event
                            // Navigate to event creation
                            dismiss()
                        }
                    )
                    
                    CreateButton(
                        title: "Goal",
                        icon: "target",
                        color: .orange,
                        action: {
                            createType = .goal
                            // Navigate to goal creation
                            dismiss()
                        }
                    )
                    
                    CreateButton(
                        title: "Note",
                        icon: "note.text",
                        color: .purple,
                        action: {
                            createType = .note
                            // Navigate to note creation
                            dismiss()
                        }
                    )
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
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

// Create Button Component
struct CreateButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(Color(.systemGray6))
            .cornerRadius(16)
        }
    }
}

// Placeholder Views for each tab
struct DashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Welcome back,")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text(authViewModel.currentUser?.fullname ?? "User")
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                authViewModel.signOut()
                            }) {
                                Image(systemName: "person.circle")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top)
                    }
                    
                    // Key Indicators Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("This Week's Progress")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(0..<4) { index in
                                    KIProgressCard(
                                        title: "KI \(index + 1)",
                                        current: index * 2,
                                        target: 10,
                                        color: [.blue, .green, .orange, .purple][index]
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Today's Tasks
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Today's Tasks")
                                .font(.headline)
                            Spacer()
                            Text("3 remaining")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        
                        VStack(spacing: 8) {
                            ForEach(0..<3) { index in
                                TaskRowView(
                                    title: "Sample Task \(index + 1)",
                                    isCompleted: index == 0
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 100) // Space for floating button
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// Key Indicator Progress Card
struct KIProgressCard: View {
    let title: String
    let current: Int
    let target: Int
    let color: Color
    
    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(Double(current) / Double(target), 1.0)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            CircularProgressView(progress: progress, color: color)
                .frame(width: 60, height: 60)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
            
            Text("\(current)/\(target)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .frame(width: 100)
    }
}

// Circular Progress View
struct CircularProgressView: View {
    let progress: Double
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 6)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)
            
            Text("\(Int(progress * 100))%")
                .font(.caption2)
                .fontWeight(.bold)
        }
    }
}

// Task Row View
struct TaskRowView: View {
    let title: String
    @State var isCompleted: Bool
    
    var body: some View {
        HStack {
            Button(action: {
                isCompleted.toggle()
            }) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isCompleted ? .green : .gray)
                    .font(.title3)
            }
            
            Text(title)
                .strikethrough(isCompleted)
                .foregroundColor(isCompleted ? .secondary : .primary)
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// Placeholder views for other tabs
struct GoalsView: View {
    var body: some View {
        NavigationView {
            Text("Goals View - Coming Soon")
                .navigationTitle("Goals")
        }
    }
}

struct CalendarView: View {
    var body: some View {
        NavigationView {
            Text("Calendar View - Coming Soon")
                .navigationTitle("Calendar")
        }
    }
}

struct TasksView: View {
    var body: some View {
        NavigationView {
            Text("Tasks View - Coming Soon")
                .navigationTitle("Tasks")
        }
    }
}

struct NotesView: View {
    var body: some View {
        NavigationView {
            Text("Notes View - Coming Soon")
                .navigationTitle("Notes")
        }
    }
}

enum CreateType: CaseIterable {
    case task, event, goal, note
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(AuthViewModel())
    }
}