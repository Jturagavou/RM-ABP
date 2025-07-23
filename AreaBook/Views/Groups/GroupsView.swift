import SwiftUI
import Firebase

struct GroupsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var collaborationManager = CollaborationManager.shared
    @State private var showingCreateGroup = false
    @State private var showingJoinGroup = false
    @State private var showingJoinWithInviteCode = false
    @State private var showingInvitations = false
    @State private var selectedGroup: AccountabilityGroup?
    @State private var searchText = ""
    @State private var selectedFilter: GroupFilter = .all
    @State private var showingSearch = false
    @State private var showCompetition = false
    @State private var showAnalytics = false
    @State private var isEditingMode = false
    @State private var draggedWidget: GroupWidget?
    @State private var groupWidgets: [GroupWidget] = GroupWidget.defaultWidgets
    
    enum GroupFilter: String, CaseIterable {
        case all = "All"
        case myGroups = "My Groups"
        case publicGroups = "Public"
        case invitations = "Invitations"
        
        var icon: String {
            switch self {
            case .all: return "person.3.fill"
            case .myGroups: return "person.2.fill"
            case .publicGroups: return "globe"
            case .invitations: return "envelope.fill"
            }
        }
    }
    
    var filteredGroups: [AccountabilityGroup] {
        let groups = collaborationManager.currentUserGroups
        
        switch selectedFilter {
        case .all:
            return groups
        case .myGroups:
            return groups.filter { group in
                group.members.contains { $0.userId == authViewModel.currentUser?.id }
            }
        case .publicGroups:
            return groups.filter { $0.settings.isPublic }
        case .invitations:
            return [] // Will be handled separately
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Enhanced Header with Search and Edit Mode Toggle
                    EnhancedGroupsHeader(
                        totalGroups: collaborationManager.currentUserGroups.count,
                        totalChallenges: collaborationManager.groupChallenges.count,
                        unreadNotifications: calculateUnreadNotifications(),
                        searchText: $searchText,
                        showingSearch: $showingSearch,
                        isEditingMode: $isEditingMode
                    )
                    
                    // Modular Groups Widget Grid
                    ModularGroupsGrid(
                        widgets: groupWidgets,
                        isEditingMode: isEditingMode,
                        draggedWidget: $draggedWidget,
                        filteredGroups: filteredGroups,
                        collaborationManager: collaborationManager,
                        showCompetition: showCompetition,
                        showAnalytics: showAnalytics,
                        onCreateGroup: { showingCreateGroup = true },
                        onWidgetMove: moveWidget,
                        onWidgetRemove: removeWidget,
                        onWidgetResize: resizeWidget
                    )
                    
                    // Add Widget Button when in edit mode
                    if isEditingMode {
                        AddGroupWidgetButton {
                            addNewWidget()
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding()
            }
            .navigationTitle("Groups")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { 
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            isEditingMode.toggle()
                        }
                    }) {
                        Image(systemName: isEditingMode ? "checkmark.circle.fill" : "slider.horizontal.3")
                            .font(.title2)
                            .foregroundColor(isEditingMode ? .green : .blue)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    EnhancedGroupsMenu(
                        onCreateGroup: { showingCreateGroup = true },
                        onJoinGroup: { showingJoinGroup = true },
                        onJoinWithCode: { showingJoinWithInviteCode = true },
                        onViewInvitations: { showingInvitations = true }
                    )
                }
            }
            .onAppear {
                startListeners()
            }
            .onDisappear {
                collaborationManager.stopAllListeners()
            }
            .sheet(isPresented: $showingCreateGroup) {
                CreateGroupView()
            }
            .sheet(isPresented: $showingJoinGroup) {
                JoinGroupView()
            }
            .sheet(isPresented: $showingJoinWithInviteCode) {
                JoinWithInviteCodeView()
            }
            .sheet(isPresented: $showingInvitations) {
                GroupInvitationsView()
            }
            .sheet(item: $selectedGroup) { group in
                GroupDetailView(group: group)
            }
        }
    }
    
    private func handleQuickAction(_ action: QuickAction, for group: AccountabilityGroup) {
        switch action {
        case .mute:
            // Handle mute action
            break
        case .pin:
            // Handle pin action
            break
        case .share:
            // Handle share action
            break
        case .settings:
            // Handle settings action
            break
        }
    }
    
    private func startListeners() {
        guard let userId = Auth.auth().currentUser?.uid else { 
            print("❌ GroupsView: No user ID available")
            return 
        }
        
        print("🔍 GroupsView: Starting listeners for user: \(userId)")
        collaborationManager.startListeningToUserGroups(userId: userId)
        
        // Start listening to progress for each group
        for group in collaborationManager.currentUserGroups {
            print("🔍 GroupsView: Starting listeners for group: \(group.name)")
            collaborationManager.startListeningToGroupProgress(groupId: group.id)
            collaborationManager.startListeningToGroupChallenges(groupId: group.id)
        }
    }
    
    private func calculateUnreadNotifications() -> Int {
        // Calculate unread notifications from various sources
        var totalUnread = 0
        
        // Count unread group invitations
        totalUnread += collaborationManager.groupInvitations.count
        
        // Count unread group activity (progress updates, etc.)
        totalUnread += collaborationManager.sharedProgress.values.flatMap { $0 }.filter { progress in
            // Consider progress as unread if it's from the last 24 hours and user hasn't seen it
            let isRecent = progress.timestamp > Date().addingTimeInterval(-24 * 60 * 60)
            return isRecent
        }.count
        
        // Count unread challenge notifications
        totalUnread += collaborationManager.groupChallenges.filter { challenge in
            // Consider challenges as unread if they're new or have updates
            let isRecent = challenge.createdAt > Date().addingTimeInterval(-24 * 60 * 60)
            return isRecent
        }.count
        
        return totalUnread
    }
    
    // MARK: - Widget Management Functions
    
    private func moveWidget(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex != destinationIndex else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            let widget = groupWidgets.remove(at: sourceIndex)
            groupWidgets.insert(widget, at: destinationIndex)
            
            // Update order values
            for (index, _) in groupWidgets.enumerated() {
                groupWidgets[index].order = index
            }
        }
    }
    
    private func removeWidget(at index: Int) {
        guard index < groupWidgets.count else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            groupWidgets[index].isVisible = false
        }
    }
    
    private func resizeWidget(at index: Int, to size: GroupWidgetSize) {
        guard index < groupWidgets.count else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            groupWidgets[index].size = size
        }
    }
    
    private func addNewWidget() {
        let availableTypes = GroupWidgetType.allCases.filter { type in
            !groupWidgets.contains { $0.type == type && $0.isVisible }
        }
        
        guard let newType = availableTypes.first else { return }
        
        let newWidget = GroupWidget(
            type: newType,
            title: newType.rawValue.replacingOccurrences(of: "_", with: " ").capitalized,
            position: GridPosition(row: groupWidgets.count, col: 0),
            order: groupWidgets.count
        )
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            groupWidgets.append(newWidget)
        }
    }
}

// MARK: - Enhanced Components

enum QuickAction {
    case mute
    case pin
    case share
    case settings
}

struct EnhancedGroupsHeader: View {
    let totalGroups: Int
    let totalChallenges: Int
    let unreadNotifications: Int
    @Binding var searchText: String
    @Binding var showingSearch: Bool
    @Binding var isEditingMode: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Stats Cards
            HStack(spacing: 12) {
                EnhancedStatCard(
                    icon: "person.3.fill",
                    title: "Groups",
                    value: "\(totalGroups)",
                    color: .blue,
                    gradient: LinearGradient(colors: [.blue, .blue.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                
                EnhancedStatCard(
                    icon: "target",
                    title: "Challenges",
                    value: "\(totalChallenges)",
                    color: .orange,
                    gradient: LinearGradient(colors: [.orange, .orange.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                
                EnhancedStatCard(
                    icon: "bell.fill",
                    title: "Updates",
                    value: "\(unreadNotifications)",
                    color: .red,
                    gradient: LinearGradient(colors: [.red, .red.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            }
            
            // Search Bar
            if showingSearch {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search groups...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

struct EnhancedStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    let gradient: LinearGradient
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(gradient)
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.white)
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct GroupFilterTabs: View {
    @Binding var selectedFilter: GroupsView.GroupFilter
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(GroupsView.GroupFilter.allCases, id: \.self) { filter in
                    FilterTabButton(
                        filter: filter,
                        isSelected: selectedFilter == filter,
                        action: { selectedFilter = filter }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

struct FilterTabButton: View {
    let filter: GroupsView.GroupFilter
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: filter.icon)
                    .font(.caption)
                
                Text(filter.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EnhancedGroupCard: View {
    let group: AccountabilityGroup
    let onTap: () -> Void
    let onQuickAction: (QuickAction) -> Void
    
    @EnvironmentObject var dataManager: DataManager
    @StateObject private var collaborationManager = CollaborationManager.shared
    @State private var showingQuickActions = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with group info and quick actions
            HStack {
                // Group Avatar
                GroupAvatar(group: group)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Label("\(group.members.count)", systemImage: "person.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        if group.settings.isPublic {
                            Label("Public", systemImage: "globe")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        
                        if let userRole = getCurrentUserRole(in: group) {
                            Text(userRole.rawValue.capitalized)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(roleColor(for: userRole).opacity(0.2))
                                .foregroundColor(roleColor(for: userRole))
                                .cornerRadius(4)
                        }
                    }
                }
                
                Spacer()
                
                // Quick Actions Menu
                Menu {
                    Button("Pin Group", action: { onQuickAction(.pin) })
                    Button("Mute Notifications", action: { onQuickAction(.mute) })
                    Button("Share Group", action: { onQuickAction(.share) })
                    Divider()
                    Button("Group Settings", action: { onQuickAction(.settings) })
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            
            // Description
            if !group.settings.description.isEmpty {
                Text(group.settings.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
            
            // Member Progress Preview
            MemberProgressPreview(group: group)
                .padding(.horizontal)
                .padding(.bottom, 12)
            
            // Activity Indicator
            if hasRecentActivity {
                HStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                    
                    Text("Active now")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2) // Reduced radius from 12 to 4 for better performance
        .onTapGesture {
            onTap()
        }
    }
    
    private var hasRecentActivity: Bool {
        // Check if there's been activity in the last hour
        let oneHourAgo = Date().addingTimeInterval(-3600)
        return group.updatedAt > oneHourAgo
    }
    
    private func getCurrentUserRole(in group: AccountabilityGroup) -> GroupRole? {
        return group.members.first?.role
    }
    
    private func roleColor(for role: GroupRole) -> Color {
        switch role {
        case .admin: return .red
        case .leader: return .orange
        case .moderator: return .purple
        case .member: return .blue
        case .viewer: return .gray
        }
    }
}

struct GroupAvatar: View {
    let group: AccountabilityGroup
    
    var body: some View {
        ZStack {
            Circle()
                .fill(groupAvatarGradient)
                .frame(width: 50, height: 50)
            
            Text(group.name.prefix(2).uppercased())
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
    }
    
    private var groupAvatarGradient: LinearGradient {
        let colors: [Color] = [.blue, .purple, .green, .orange, .red, .pink]
        let index = abs(group.name.hashValue) % colors.count
        let color = colors[index]
        return LinearGradient(colors: [color, color.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

struct MemberProgressPreview: View {
    let group: AccountabilityGroup
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Member Progress")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(group.members.count) members")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Progress bars for top 3 members
            VStack(spacing: 6) {
                ForEach(Array(group.members.prefix(3)), id: \.userId) { member in
                    MemberProgressBar(member: member)
                }
                
                if group.members.count > 3 {
                    Text("+\(group.members.count - 3) more members")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }
            }
        }
    }
}

struct MemberProgressBar: View {
    let member: GroupMember
    @State private var progress: Double = 0
    
    var body: some View {
        HStack(spacing: 8) {
            // Member avatar
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 16, height: 16)
                .overlay(
                    Text(member.userId.prefix(1).uppercased())
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                )
            
            // Member name
            Text(member.userId.prefix(8))
                .font(.caption2)
                .lineLimit(1)
            
            Spacer()
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(progressColor)
                        .frame(width: geometry.size.width * progress, height: 4)
                        .cornerRadius(2)
                }
            }
            .frame(height: 4)
            
            // Progress percentage
            Text("\(Int(progress * 100))%")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(progressColor)
                .frame(width: 30, alignment: .trailing)
        }
        .onAppear {
            // Simulate loading progress
            withAnimation(.easeInOut(duration: 1.0)) {
                progress = Double.random(in: 0.3...0.9)
            }
        }
    }
    
    private var progressColor: Color {
        switch progress {
        case 0.8...:
            return .green
        case 0.5...:
            return .orange
        default:
            return .red
        }
    }
}

struct EnhancedEmptyGroupsView: View {
    let onCreateGroup: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Animated illustration
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.blue.opacity(0.1), .purple.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "person.3")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
            }
            
            VStack(spacing: 12) {
                Text("No Groups Yet")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Create or join groups to share progress with friends and family. Build accountability together!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            
            VStack(spacing: 12) {
                Button(action: onCreateGroup) {
                    Label("Create Your First Group", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                
                Button("Discover Public Groups") {
                    // Navigate to public groups
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(20)
    }
}

struct EnhancedGroupsMenu: View {
    let onCreateGroup: () -> Void
    let onJoinGroup: () -> Void
    let onJoinWithCode: () -> Void
    let onViewInvitations: () -> Void
    
    var body: some View {
        Menu {
            Button(action: onCreateGroup) {
                Label("Create Group", systemImage: "plus.circle")
            }
            
            Button(action: onJoinGroup) {
                Label("Join Group", systemImage: "person.badge.plus")
            }
            
            Button(action: onJoinWithCode) {
                Label("Join with Code", systemImage: "key")
            }
            
            Divider()
            
            Button(action: onViewInvitations) {
                Label("Invitations", systemImage: "envelope")
            }
        } label: {
            Image(systemName: "plus.circle.fill")
                .font(.title2)
                .foregroundColor(.blue)
        }
    }
}

struct EnhancedRecentActivitySection: View {
    let sharedProgress: [String: [ProgressShare]]
    
    var allProgress: [ProgressShare] {
        sharedProgress.values.flatMap { $0 }.sorted { $0.timestamp > $1.timestamp }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Activity")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to full activity view
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            VStack(spacing: 12) {
                ForEach(allProgress.prefix(3)) { progress in
                    EnhancedProgressActivityRow(progress: progress)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
}

struct EnhancedProgressActivityRow: View {
    let progress: ProgressShare
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconGradient)
                    .frame(width: 36, height: 36)
                
                Image(systemName: iconName)
                    .font(.caption)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(activityDescription)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(progress.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private var iconName: String {
        switch progress.type {
        case .goals: return "star"
        case .events: return "calendar"
        case .tasks: return "checkmark"
        case .kis: return "chart.bar"
        case .kiUpdate: return "target"
        case .goalProgress: return "star.fill"
        case .taskCompleted: return "checkmark"
        case .milestone: return "flag.fill"
        case .achievement: return "trophy.fill"
        }
    }
    
    private var iconGradient: LinearGradient {
        switch progress.type {
        case .goals, .goalProgress: return LinearGradient(colors: [.green, .green.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .events: return LinearGradient(colors: [.blue, .blue.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .tasks, .taskCompleted: return LinearGradient(colors: [.orange, .orange.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .kis, .kiUpdate: return LinearGradient(colors: [.purple, .purple.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .milestone: return LinearGradient(colors: [.purple, .purple.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .achievement: return LinearGradient(colors: [.yellow, .yellow.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    private var activityDescription: String {
        switch progress.type {
        case .goals: return "Made progress on a goal"
        case .events: return "Attended an event"
        case .tasks: return "Completed a task"
        case .kis: return "Updated a key indicator"
        case .kiUpdate: return "Updated life tracker progress"
        case .goalProgress: return "Made progress on a goal"
        case .taskCompleted: return "Completed a task"
        case .milestone: return "Reached a milestone"
        case .achievement: return "Unlocked an achievement"
        }
    }
}

struct EnhancedChallengesSection: View {
    let challenges: [GroupChallenge]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Active Challenges")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to challenges view
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(challenges) { challenge in
                        EnhancedChallengeCard(challenge: challenge)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct EnhancedChallengeCard: View {
    let challenge: GroupChallenge
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.orange, .orange.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "target")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(challenge.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    
                    Text("\(challenge.participants.count) participants")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Description
            Text(challenge.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            // Progress
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Target:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(challenge.target)) \(challenge.unit)")
                        .font(.caption)
                        .fontWeight(.medium)
                    Spacer()
                }
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .frame(height: 6)
                            .cornerRadius(3)
                        
                        Rectangle()
                            .fill(LinearGradient(colors: [.orange, .orange.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geometry.size.width * 0.6, height: 6) // 60% progress
                            .cornerRadius(3)
                    }
                }
                .frame(height: 6)
            }
            
            // Footer
            HStack {
                Text("Ends \(challenge.endDate, style: .date)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("View") {
                    // Navigate to challenge detail
                }
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.orange)
            }
        }
        .padding()
        .frame(width: 280)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Create Group View

struct CreateGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var collaborationManager = CollaborationManager.shared
    
    @State private var groupName = ""
    @State private var groupDescription = ""
    @State private var isPublic = false
    @State private var allowInvitations = true
    @State private var shareProgress = true
    @State private var allowChallenges = true
    @State private var isCreating = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var createdGroup: AccountabilityGroup?
    @State private var showInviteOptions = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Group Details") {
                    TextField("Group Name", text: $groupName)
                        .textInputAutocapitalization(.words)
                    
                    TextField("Description", text: $groupDescription, axis: .vertical)
                        .lineLimit(3...)
                        .textInputAutocapitalization(.sentences)
                }
                
                Section("Settings") {
                    Toggle("Public Group", isOn: $isPublic)
                    Toggle("Allow Invitations", isOn: $allowInvitations)
                    Toggle("Share Progress", isOn: $shareProgress)
                    Toggle("Allow Challenges", isOn: $allowChallenges)
                }
                
                Section("Privacy") {
                    Text("Public groups can be discovered by other users. Private groups are invitation-only.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if isCreating {
                    Section {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Creating group...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                    }
                }
            }
            .navigationTitle("Create Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isCreating)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createGroup()
                    }
                    .disabled(groupName.isEmpty || isCreating)
                    .fontWeight(.semibold)
                }
            }
        }
        .sheet(isPresented: $showInviteOptions) {
            if let group = createdGroup {
                GroupInviteOptionsView(group: group) {
                    dismiss()
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func createGroup() {
        guard let userId = Auth.auth().currentUser?.uid else { 
            errorMessage = "Please log in to create a group"
            showError = true
            return 
        }
        
        guard !groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter a group name"
            showError = true
            return
        }
        
        isCreating = true
        errorMessage = ""
        
        Task {
            do {
                // Create the basic group first
                let group = try await collaborationManager.createGroup(
                    name: groupName.trimmingCharacters(in: .whitespacesAndNewlines),
                    description: groupDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                    creatorId: userId
                )
                
                // Update group settings if they differ from defaults
                if !isPublic || !allowInvitations || !shareProgress || !allowChallenges || !groupDescription.isEmpty {
                    try await updateGroupSettings(groupId: group.id)
                }
                
                await MainActor.run {
                    self.isCreating = false
                    self.createdGroup = group
                    self.showInviteOptions = true
                }
            } catch {
                await MainActor.run {
                    self.isCreating = false
                    self.errorMessage = "Failed to create group: \(error.localizedDescription)"
                    self.showError = true
                }
                print("❌ CreateGroupView: Error creating group: \(error)")
            }
        }
    }
    
    private func updateGroupSettings(groupId: String) async throws {
        // Create updated settings
        let settings = GroupSettings(from: [
            "isPublic": isPublic,
            "allowInvitations": allowInvitations,
            "shareProgress": shareProgress,
            "allowChallenges": allowChallenges,
            "description": groupDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        ])
        
        // Update the group document with new settings
        let db = Firestore.firestore()
        try await db.collection("accountabilityGroups").document(groupId).updateData([
            "settings": [
                "isPublic": settings.isPublic,
                "allowInvitations": settings.allowInvitations,
                "shareProgress": settings.shareProgress,
                "allowChallenges": settings.allowChallenges,
                "description": settings.description
            ],
            "updatedAt": Timestamp(date: Date())
        ])
        
        print("✅ CreateGroupView: Updated group settings for group \(groupId)")
    }
}

// MARK: - Group Invite Options View

struct GroupInviteOptionsView: View {
    let group: AccountabilityGroup
    let onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss
    @StateObject private var collaborationManager = CollaborationManager.shared
    
    @State private var showUserSearch = false
    @State private var inviteLink = ""
    @State private var isGeneratingLink = false
    @State private var showShareSheet = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Success Header
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                Text("Group Created!")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("'\(group.name)' is ready. Now invite people to join your group.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Group Info Card
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(group.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text("Admin")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(6)
                }
                
                if !group.settings.description.isEmpty {
                    Text(group.settings.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Invite Code:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(group.inviteCode)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                        .textSelection(.enabled)
                    
                    Spacer()
                    
                    Button(action: copyInviteCode) {
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            
            // Invite Options
            VStack(spacing: 16) {
                Text("Invite People")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Search and Invite Users
                Button(action: { showUserSearch = true }) {
                    HStack {
                        Image(systemName: "person.badge.plus")
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Search & Invite Users")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("Find existing users by name or email")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Share Invite Link
                Button(action: generateAndShareLink) {
                    HStack {
                        if isGeneratingLink {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "link")
                                .font(.title2)
                                .foregroundColor(.green)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Share Invite Link")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("Create a link anyone can use to join")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isGeneratingLink)
                
                // Skip for Now
                Button("Skip for Now") {
                    onComplete()
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Invite Members")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    onComplete()
                }
                .fontWeight(.semibold)
            }
        }
        .sheet(isPresented: $showUserSearch) {
            UserSearchAndInviteView(group: group)
        }
        .sheet(isPresented: $showShareSheet) {
            if !inviteLink.isEmpty {
                ShareSheet(activityItems: [inviteLink])
            }
        }
    }
    
    private func copyInviteCode() {
        UIPasteboard.general.string = group.inviteCode
        // TODO: Show toast/feedback that code was copied
    }
    
    private func generateAndShareLink() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        isGeneratingLink = true
        
        Task {
            do {
                let link = try await collaborationManager.generatePublicInviteLink(
                    groupId: group.id,
                    fromUserId: userId
                )
                
                await MainActor.run {
                    self.inviteLink = link
                    self.isGeneratingLink = false
                    self.showShareSheet = true
                }
            } catch {
                await MainActor.run {
                    self.isGeneratingLink = false
                    print("❌ Error generating invite link: \(error)")
                }
            }
        }
    }
}

// MARK: - Join Group View

struct JoinGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var collaborationManager = CollaborationManager.shared
    
    @State private var invitationCode = ""
    @State private var isJoining = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Join a Group")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Enter the invitation code shared by a group member")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                TextField("Invitation Code", text: $invitationCode)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textInputAutocapitalization(.characters)
                
                Button("Join Group") {
                    joinGroup()
                }
                .buttonStyle(.borderedProminent)
                .disabled(invitationCode.isEmpty || isJoining)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Join Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func joinGroup() {
        guard let userId = authViewModel.currentUser?.id else { return }
        
        isJoining = true
        
        Task {
            do {
                // TODO: Extract group ID from invitation code
                let groupId = "extracted_group_id"
                try await collaborationManager.joinGroup(
                    groupId: groupId,
                    userId: userId,
                    invitationCode: invitationCode
                )
                
                DispatchQueue.main.async {
                    dismiss()
                }
            } catch {
                print("Error joining group: \(error)")
                // TODO: Show error alert
            }
            
            isJoining = false
        }
    }
}

// MARK: - Group Detail View

struct GroupDetailView: View {
    let group: AccountabilityGroup
    @Environment(\.dismiss) private var dismiss
    @State private var showingUserSearch = false
    @State private var selectedTab: GroupDetailTab = .members
    @State private var selectedMemberForPlanner: GroupMember?
    
    enum GroupDetailTab: String, CaseIterable {
        case members = "Members"
        case progress = "Progress"
        case planner = "Planner"
        case activity = "Activity"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Group Header
                GroupHeaderSection(group: group)
                
                // Tab Navigation
                GroupTabNavigation(selectedTab: $selectedTab)
                
                // Tab Content
                TabView(selection: $selectedTab) {
                    // Members Tab
                    MembersTabView(group: group, selectedMemberForPlanner: $selectedMemberForPlanner)
                        .tag(GroupDetailTab.members)
                    
                    // Progress Tab - Shows all members' KI progress
                    ProgressTabView(group: group)
                        .tag(GroupDetailTab.progress)
                    
                    // Planner Tab - View selected member's planner
                    PlannerTabView(group: group, selectedMember: selectedMemberForPlanner)
                        .tag(GroupDetailTab.planner)
                    
                    // Activity Tab
                    ActivityTabView(group: group)
                        .tag(GroupDetailTab.activity)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle(group.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingUserSearch) {
                UserSearchAndInviteView(group: group)
            }
        }
    }
}

// MARK: - Group Header Section
struct GroupHeaderSection: View {
    let group: AccountabilityGroup
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(group.settings.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(group.members.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text("Members")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Label("Created \(group.createdAt, style: .date)", systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if !group.inviteCode.isEmpty {
                    HStack {
                        Text("Code: \(group.inviteCode)")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Button(action: {
                            UIPasteboard.general.string = group.inviteCode
                        }) {
                            Image(systemName: "doc.on.doc")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
    }
}

// MARK: - Tab Navigation
struct GroupTabNavigation: View {
    @Binding var selectedTab: GroupDetailView.GroupDetailTab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(GroupDetailView.GroupDetailTab.allCases, id: \.self) { tab in
                Button(action: {
                    selectedTab = tab
                }) {
                    VStack(spacing: 4) {
                        Text(tab.rawValue)
                            .font(.subheadline)
                            .fontWeight(selectedTab == tab ? .semibold : .regular)
                        
                        Rectangle()
                            .fill(selectedTab == tab ? Color.blue : Color.clear)
                            .frame(height: 2)
                    }
                    .foregroundColor(selectedTab == tab ? .blue : .secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .background(Color(.systemBackground))
    }
}

// MARK: - Members Tab
struct MembersTabView: View {
    let group: AccountabilityGroup
    @Binding var selectedMemberForPlanner: GroupMember?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(group.members, id: \.userId) { member in
                    MemberDetailCard(member: member) {
                        selectedMemberForPlanner = member
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Progress Tab
struct ProgressTabView: View {
    let group: AccountabilityGroup
    @State private var memberProgressData: [String: [Goal]] = [:]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Key Indicators Progress")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .padding(.horizontal)
                
                LazyVStack(spacing: 16) {
                    ForEach(group.members, id: \.userId) { member in
                        MemberKIProgressCard(
                            member: member, 
                            kiGoals: memberProgressData[member.userId] ?? []
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .onAppear {
            loadMemberProgressData()
        }
    }
    
    private func loadMemberProgressData() {
        // TODO: Load each member's KI goals from Firebase
        // For now, use placeholder data
        for member in group.members {
            memberProgressData[member.userId] = createPlaceholderKIGoals()
        }
    }
    
    private func createPlaceholderKIGoals() -> [Goal] {
        return [
            createPlaceholderGoal(title: "Scripture Study", progress: Double.random(in: 0...100)),
            createPlaceholderGoal(title: "Prayer", progress: Double.random(in: 0...100)),
            createPlaceholderGoal(title: "Exercise", progress: Double.random(in: 0...100))
        ]
    }
    
    private func createPlaceholderGoal(title: String, progress: Double) -> Goal {
        var goal = Goal(
            title: title,
            description: "",
            keyIndicatorIds: [],
            targetValue: 100
        )
        goal.isKeyIndicator = true
        goal.currentValue = progress
        return goal
    }
}

// MARK: - Planner Tab
struct PlannerTabView: View {
    let group: AccountabilityGroup
    let selectedMember: GroupMember?
    @EnvironmentObject var authViewModel: AuthViewModel  // Add missing environment object
    
    var body: some View {
        VStack {
            if let member = selectedMember {
                MemberPlannerView(member: member, group: group)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("Select a Member")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Choose a group member from the Members tab to view their planner and add comments")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground))
            }
        }
    }
}

// MARK: - Activity Tab
struct ActivityTabView: View {
    let group: AccountabilityGroup
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Recent Activity")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .padding(.horizontal)
                
                // TODO: Show real group activity
                VStack(spacing: 12) {
                    ForEach(0..<5, id: \.self) { index in
                        GroupActivityItem(
                            icon: "checkmark.circle.fill",
                            title: "Member completed a goal",
                            subtitle: "2 hours ago",
                            color: .green
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Member Detail Card
struct MemberDetailCard: View {
    let member: GroupMember
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                // Member Avatar
                Circle()
                    .fill(Color.blue)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(String(member.userId.prefix(1)).uppercased())
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    )
                
                // Member Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(member.userId) // TODO: Get actual user name
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("Joined \(member.joinedAt, style: .date)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Role Badge
                Text(member.role.rawValue.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(roleColor.opacity(0.2))
                    .foregroundColor(roleColor)
                    .cornerRadius(6)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var roleColor: Color {
        switch member.role {
        case .admin: return .red
        case .leader: return .blue
        case .member: return .green
        case .viewer: return .gray
        case .moderator: return .orange
        }
    }
}

// MARK: - Member KI Progress Card
struct MemberKIProgressCard: View {
    let member: GroupMember
    let kiGoals: [Goal]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(member.userId) // TODO: Get actual user name
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Label("\(kiGoals.count)", systemImage: "chart.bar.xaxis")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            LazyVStack(spacing: 8) {
                ForEach(kiGoals, id: \.id) { goal in
                    GroupKIProgressRow(goal: goal)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - KI Progress Row
struct GroupKIProgressRow: View {
    let goal: Goal
    
    var body: some View {
        HStack(spacing: 12) {
            // Progress Indicator (Circle)
            Circle()
                .fill(progressColor)
                .frame(width: 10, height: 10)
            
            // Goal Details
            VStack(alignment: .leading, spacing: 2) {
                Text(goal.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(goal.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Text("\(Int(goal.currentValue))/\(Int(goal.targetValue))")
                        .font(.caption2)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(Int(goal.keyIndicatorProgressPercentage))%")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(progressColor)
                }
            }
        }
    }
    
    private var progressColor: Color {
        switch goal.keyIndicatorProgressPercentage {
        case 80...: return .green
        case 50...: return .orange
        default: return .red
        }
    }
}

// MARK: - Member Planner View
struct MemberPlannerView: View {
    let member: GroupMember
    let group: AccountabilityGroup
    @EnvironmentObject var authViewModel: AuthViewModel  // Add missing environment object
    
    @State private var plannerItems: [PlannerItem] = []
    @State private var newItemTitle = ""
    @State private var newItemDescription = ""
    @State private var isAddingItem = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Planner for \(member.userId)")
                .font(.headline)
                .fontWeight(.semibold)
            
            if plannerItems.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No items in planner for \(member.userId)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground))
            } else {
                List {
                    ForEach(plannerItems, id: \.id) { item in
                        PlannerItemRow(item: item)
                    }
                    .onDelete(perform: deleteItem)
                }
            }
            
            if isAddingItem {
                VStack(spacing: 12) {
                    TextField("Title", text: $newItemTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Description (Optional)", text: $newItemDescription, axis: .vertical)
                        .lineLimit(3)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    HStack {
                        Button("Cancel") {
                            isAddingItem = false
                            newItemTitle = ""
                            newItemDescription = ""
                        }
                        .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button("Add Item") {
                            addItem()
                        }
                        .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
        }
        .padding()
    }
    
    private func addItem() {
        guard let userId = authViewModel.currentUser?.id else { return }
        
        let newItem = PlannerItem(
            id: UUID().uuidString,
            title: newItemTitle,
            description: newItemDescription,
            userId: userId,
            groupId: group.id,
            createdAt: Date()
        )
        
        plannerItems.append(newItem)
        isAddingItem = false
        newItemTitle = ""
        newItemDescription = ""
    }
    
    private func deleteItem(at offsets: IndexSet) {
        plannerItems.remove(atOffsets: offsets)
    }
}

// MARK: - Planner Item Row
struct PlannerItemRow: View {
    let item: PlannerItem
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if !item.description.isEmpty {
                    Text(item.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            Text(item.createdAt, style: .relative)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Group Invitations View
struct GroupInvitationsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var collaborationManager = CollaborationManager.shared
    
    @State private var invitations: [GroupInvitation] = []
    @State private var isLoading = true
    @State private var errorMessage = ""
    @State private var showError = false
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading invitations...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top)
                    }
                } else if invitations.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "envelope.open")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("No Pending Invitations")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        Text("You don't have any pending group invitations")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(invitations, id: \.id) { invitation in
                        GroupInvitationRow(invitation: invitation) { accept in
                            respondToInvitation(invitation, accept: accept)
                        }
                    }
                }
            }
            .navigationTitle("Group Invitations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .refreshable {
                await loadInvitations()
            }
        }
        .task {
            await loadInvitations()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func loadInvitations() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        
        do {
            let results = try await collaborationManager.getUserInvitations(userId: userId)
            await MainActor.run {
                invitations = results
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    private func respondToInvitation(_ invitation: GroupInvitation, accept: Bool) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        Task {
            do {
                if accept {
                    try await collaborationManager.acceptGroupInvitation(
                        invitationId: invitation.id,
                        userId: userId
                    )
                } else {
                    try await collaborationManager.declineGroupInvitation(
                        invitationId: invitation.id,
                        userId: userId
                    )
                }
                
                // Reload invitations
                await loadInvitations()
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

struct GroupInvitationRow: View {
    let invitation: GroupInvitation
    let onRespond: (Bool) -> Void
    
    @State private var showingResponseButtons = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(invitation.groupName)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Invitation from \(invitation.fromUserId)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(invitation.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Message
            if !invitation.message.isEmpty {
                Text(invitation.message)
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            
            // Response Buttons
            if !showingResponseButtons {
                Button("View Invitation") {
                    showingResponseButtons = true
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            } else {
                HStack(spacing: 12) {
                    Button("Accept") {
                        onRespond(true)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    
                    Button("Decline") {
                        onRespond(false)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Data Models for Planner
struct PlannerItem: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let userId: String
    let groupId: String
    let createdAt: Date
    var comments: [PlannerComment] = []
}

struct PlannerComment: Identifiable, Codable {
    let id: String
    let content: String
    let userId: String
    let createdAt: Date
}

// MARK: - Group Activity Item
struct GroupActivityItem: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 30, height: 30)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    GroupsView()
        .environmentObject(AuthViewModel.shared)
}

// MARK: - Missing Views
struct JoinWithInviteCodeView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var collaborationManager = CollaborationManager.shared
    
    @State private var inviteCode = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var showError = false
    @State private var groupPreview: PublicInviteLinkInfo?
    @State private var showGroupPreview = false
    @State private var showingQRScanner = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                    
                    Text("Join a Group")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Enter an invite code or paste an invite link to join a group")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                
                // Input Section
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Invite Code or Link")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        TextField("Enter invite code or paste link", text: $inviteCode)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.allCharacters)
                            .autocorrectionDisabled()
                            .onSubmit {
                                processInvite()
                            }
                    }
                    
                    // Instructions
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How to join:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "1.circle.fill")
                                    .foregroundColor(.blue)
                                Text("Enter a 6-character invite code (e.g. ABC123)")
                                    .font(.caption)
                            }
                            
                            HStack {
                                Image(systemName: "2.circle.fill")
                                    .foregroundColor(.blue)
                                Text("Or paste a full invite link from a friend")
                                    .font(.caption)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                // Group Preview (if link detected)
                if let preview = groupPreview, showGroupPreview {
                    GroupPreviewCard(preview: preview)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: processInvite) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "person.badge.plus")
                            }
                            Text(isLoading ? "Processing..." : "Join Group")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(inviteCode.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(12)
                    }
                    .disabled(inviteCode.isEmpty || isLoading)
                    
                    Button("Scan QR Code") {
                        showingQRScanner = true
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onChange(of: inviteCode) { newValue in
                detectInviteLink(newValue)
            }
        }
        .alert("Success!", isPresented: $showSuccess) {
            Button("OK") { dismiss() }
        } message: {
            Text("Successfully joined the group!")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showingQRScanner) {
            QRScannerView { scannedCode in
                inviteCode = scannedCode
                showingQRScanner = false
            }
        }
    }
    
    private func detectInviteLink(_ input: String) {
        // Check if input looks like a URL
        if input.contains("areabook.app/invite") || input.contains("://") {
            guard let url = URL(string: input),
                  let userId = Auth.auth().currentUser?.uid else { return }
            
            Task {
                do {
                    let preview = try await collaborationManager.processPublicInviteLink(url: url, userId: userId)
                    await MainActor.run {
                        self.groupPreview = preview
                        self.showGroupPreview = true
                    }
                } catch {
                    // If URL processing fails, treat as regular invite code
                    await MainActor.run {
                        self.showGroupPreview = false
                        self.groupPreview = nil
                    }
                }
            }
        } else {
            showGroupPreview = false
            groupPreview = nil
        }
    }
    
    private func processInvite() {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "Please log in to join a group"
            showError = true
            return
        }
        
        isLoading = true
        
        Task {
            do {
                // Check if it's a URL or just an invite code
                if inviteCode.contains("areabook.app/invite") || inviteCode.contains("://") {
                    // Handle as public invite link
                    guard let url = URL(string: inviteCode) else {
                        throw CollaborationError.invalidInviteLink
                    }
                    
                    let linkInfo = try await collaborationManager.processPublicInviteLink(url: url, userId: userId)
                    try await collaborationManager.joinGroupViaPublicLink(inviteCode: linkInfo.inviteCode, userId: userId)
                } else {
                    // Handle as direct invite code
                    try await collaborationManager.joinGroupWithInviteCode(inviteCode: inviteCode.uppercased(), userId: userId)
                }
                
                await MainActor.run {
                    self.isLoading = false
                    self.showSuccess = true
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                }
            }
        }
    }
}

// MARK: - Group Preview Card
struct GroupPreviewCard: View {
    let preview: PublicInviteLinkInfo
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(preview.groupName)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("\(preview.memberCount) member\(preview.memberCount == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                statusIndicator
            }
            
            if preview.needsAppDownload {
                VStack(spacing: 8) {
                    Text("Welcome to AreaBook!")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("Create an account to join this group and start tracking your goals together.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
    }
    
    @ViewBuilder
    private var statusIndicator: some View {
        switch preview.userStatus {
        case .notLoggedIn:
            Label("Sign up required", systemImage: "person.badge.plus")
                .font(.caption)
                .foregroundColor(.orange)
        case .canJoin:
            Label("Ready to join", systemImage: "checkmark.circle.fill")
                .font(.caption)
                .foregroundColor(.green)
        case .alreadyMember:
            Label("Already a member", systemImage: "person.check")
                .font(.caption)
                .foregroundColor(.blue)
        }
    }
}

struct UserSearchAndInviteView: View {
    let group: AccountabilityGroup
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var collaborationManager = CollaborationManager.shared
    
    @State private var searchText = ""
    @State private var searchResults: [UserSuggestion] = []
    @State private var selectedUsers: Set<String> = []
    @State private var inviteMessage = ""
    @State private var isSearching = false
    @State private var isSending = false
    @State private var showSuccess = false
    @State private var errorMessage = ""
    @State private var showError = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Section
                VStack(spacing: 16) {
                    Text("Invite Users to \(group.name)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                    
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Search by name or email", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    // Search Results
                    if isSearching {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Searching...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    } else if searchResults.isEmpty && !searchText.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "person.2.slash")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("No users found")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("Try searching with a different name or email")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    }
                }
                .padding()
                
                // Results List
                if !searchResults.isEmpty {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(searchResults) { user in
                                UserResultCard(
                                    user: user,
                                    isSelected: selectedUsers.contains(user.id),
                                    isCurrentMember: group.members.contains { $0.userId == user.id }
                                ) {
                                    if selectedUsers.contains(user.id) {
                                        selectedUsers.remove(user.id)
                                    } else {
                                        selectedUsers.insert(user.id)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
                
                Spacer()
                
                // Selected Users & Message
                if !selectedUsers.isEmpty {
                    VStack(spacing: 16) {
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Selected Users (\(selectedUsers.count))")
                                .font(.headline)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(selectedUsers.sorted(), id: \.self) { userId in
                                        if let user = searchResults.first(where: { $0.id == userId }) {
                                            SelectedUserTag(user: user) {
                                                selectedUsers.remove(userId)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 4)
                            }
                            
                            // Custom Message
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Invitation Message (Optional)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                TextEditor(text: $inviteMessage)
                                    .frame(height: 60)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                            }
                        }
                        .padding()
                        
                        // Send Invitations Button
                        Button(action: sendInvitations) {
                            HStack {
                                if isSending {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "paperplane.fill")
                                }
                                Text(isSending ? "Sending..." : "Send Invitations")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                        .disabled(isSending)
                        .padding(.horizontal)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Share Link") {
                        shareInviteLink()
                    }
                    .font(.subheadline)
                }
            }
        }
        .onChange(of: searchText) { newValue in
            searchUsers(query: newValue)
        }
        .alert("Success", isPresented: $showSuccess) {
            Button("OK") { dismiss() }
        } message: {
            Text("Invitations sent successfully!")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func searchUsers(query: String) {
        guard query.count >= 2 else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        Task {
            do {
                let results = try await collaborationManager.searchUsers(query: query)
                await MainActor.run {
                    self.searchResults = results
                    self.isSearching = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to search users: \(error.localizedDescription)"
                    self.showError = true
                    self.isSearching = false
                }
            }
        }
    }
    
    private func sendInvitations() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        isSending = true
        
        Task {
            var successCount = 0
            var errors: [String] = []
            
            for userId in selectedUsers {
                do {
                    try await collaborationManager.sendGroupInvitation(
                        groupId: group.id,
                        fromUserId: currentUserId,
                        toUserId: userId,
                        message: inviteMessage
                    )
                    successCount += 1
                } catch {
                    if let user = searchResults.first(where: { $0.id == userId }) {
                        errors.append("Failed to invite \(user.name): \(error.localizedDescription)")
                    }
                }
            }
            
            await MainActor.run {
                self.isSending = false
                
                if errors.isEmpty {
                    self.showSuccess = true
                } else {
                    self.errorMessage = errors.joined(separator: "\n")
                    self.showError = true
                }
            }
        }
    }
    
    private func shareInviteLink() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        Task {
            do {
                let inviteURL = try await collaborationManager.generatePublicInviteLink(
                    groupId: group.id,
                    fromUserId: currentUserId
                )
                
                await MainActor.run {
                    let activityViewController = UIActivityViewController(
                        activityItems: [inviteURL],
                        applicationActivities: nil
                    )
                    
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootViewController = windowScene.windows.first?.rootViewController {
                        rootViewController.present(activityViewController, animated: true)
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to generate invite link: \(error.localizedDescription)"
                    self.showError = true
                }
            }
        }
    }
}

// MARK: - User Result Card
struct UserResultCard: View {
    let user: UserSuggestion
    let isSelected: Bool
    let isCurrentMember: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            AsyncImage(url: user.avatar != nil ? URL(string: user.avatar!) : nil) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.blue.gradient)
                    .overlay(
                        Text(user.name.prefix(1).uppercased())
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    )
            }
            .frame(width: 44, height: 44)
            .clipShape(Circle())
            
            // User Info
            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Last seen \(user.lastSeen, style: .relative)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Action Button
            if isCurrentMember {
                Text("Member")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
            } else {
                Button(action: onToggle) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "plus.circle")
                        .font(.title2)
                        .foregroundColor(isSelected ? .green : .blue)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Selected User Tag
struct SelectedUserTag: View {
    let user: UserSuggestion
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Text(user.name)
                .font(.caption)
                .fontWeight(.medium)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray5))
        .cornerRadius(8)
    }
}

// MARK: - QR Scanner View
struct QRScannerView: View {
    @Environment(\.dismiss) private var dismiss
    let onCodeScanned: (String) -> Void
    
    @State private var isScanning = false
    @State private var scannedCode = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // Camera view placeholder
                Color.black
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    // Scanning overlay
                    VStack(spacing: 20) {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                        
                        Text("Position QR code within frame")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Scanning for invite codes...")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    // Manual entry option
                    VStack(spacing: 12) {
                        Text("Can't scan?")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Button("Enter Code Manually") {
                            dismiss()
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    }
                    .padding(.bottom, 50)
                }
            }
            .navigationTitle("Scan QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .onAppear {
                startScanning()
            }
            .alert("Scanning Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func startScanning() {
        isScanning = true
        
        // Simulate QR code scanning
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            // For demo purposes, simulate a scanned code
            let demoCode = "ABC123"
            onCodeScanned(demoCode)
        }
    }
}

// MARK: - Analytics & Insights Components

struct GroupAnalyticsSection: View {
    let groups: [AccountabilityGroup]
    @State private var selectedTimeframe: AnalyticsTimeframe = .week
    @State private var showingDetailedAnalytics = false
    
    enum AnalyticsTimeframe: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case quarter = "Quarter"
        
        var icon: String {
            switch self {
            case .week: return "calendar"
            case .month: return "calendar.badge.clock"
            case .quarter: return "chart.bar.fill"
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Analytics & Insights")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("View Details") {
                    showingDetailedAnalytics = true
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            // Timeframe Selector
            HStack {
                Text("Timeframe:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ForEach(AnalyticsTimeframe.allCases, id: \.self) { timeframe in
                    Button(action: { selectedTimeframe = timeframe }) {
                        HStack(spacing: 4) {
                            Image(systemName: timeframe.icon)
                                .font(.caption)
                            Text(timeframe.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(selectedTimeframe == timeframe ? Color.green : Color(.systemGray6))
                        .foregroundColor(selectedTimeframe == timeframe ? .white : .primary)
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // Analytics Cards
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                GroupHealthCard(groups: groups, timeframe: selectedTimeframe)
                EngagementMetricsCard(groups: groups, timeframe: selectedTimeframe)
                GoalCompletionCard(groups: groups, timeframe: selectedTimeframe)
                ActivityTrendsCard(groups: groups, timeframe: selectedTimeframe)
            }
        }
        .sheet(isPresented: $showingDetailedAnalytics) {
            DetailedAnalyticsView(groups: groups, timeframe: selectedTimeframe)
        }
    }
}

struct GroupHealthCard: View {
    let groups: [AccountabilityGroup]
    let timeframe: GroupAnalyticsSection.AnalyticsTimeframe
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.fill")
                    .font(.title2)
                    .foregroundColor(.red)
                
                Spacer()
                
                Text("\(healthScore)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(healthColor)
            }
            
            Text("Group Health")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(healthDescription)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            // Health indicator
            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { index in
                    Circle()
                        .fill(index < healthScore / 20 ? healthColor : Color(.systemGray4))
                        .frame(width: 8, height: 8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var healthScore: Int {
        // Calculate group health based on activity, engagement, and goal completion
        let totalMembers = groups.reduce(0) { $0 + $1.members.count }
        let activeMembers = groups.reduce(0) { $0 + $1.members.filter { $0.lastActivity > Date().addingTimeInterval(-7 * 24 * 60 * 60) }.count }
        
        guard totalMembers > 0 else { return 0 }
        let activityRate = Double(activeMembers) / Double(totalMembers)
        return Int(activityRate * 100)
    }
    
    private var healthColor: Color {
        switch healthScore {
        case 80...: return .green
        case 60...: return .orange
        default: return .red
        }
    }
    
    private var healthDescription: String {
        switch healthScore {
        case 80...: return "Excellent group health with high engagement"
        case 60...: return "Good group health, some room for improvement"
        default: return "Group health needs attention"
        }
    }
}

struct EngagementMetricsCard: View {
    let groups: [AccountabilityGroup]
    let timeframe: GroupAnalyticsSection.AnalyticsTimeframe
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Spacer()
                
                Text("\(engagementRate)%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            Text("Engagement Rate")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(engagementDescription)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            // Engagement trend
            HStack {
                Image(systemName: engagementTrend > 0 ? "arrow.up" : "arrow.down")
                    .font(.caption)
                    .foregroundColor(engagementTrend > 0 ? .green : .red)
                
                Text("\(abs(engagementTrend))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(engagementTrend > 0 ? .green : .red)
                
                Text("vs last period")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var engagementRate: Int {
        // Calculate engagement rate based on member activity
        let totalMembers = groups.reduce(0) { $0 + $1.members.count }
        let activeMembers = groups.reduce(0) { $0 + $1.members.filter { $0.lastActivity > Date().addingTimeInterval(-3 * 24 * 60 * 60) }.count }
        
        guard totalMembers > 0 else { return 0 }
        return Int((Double(activeMembers) / Double(totalMembers)) * 100)
    }
    
    private var engagementTrend: Int {
        // Simulate engagement trend
        return Int.random(in: -15...25)
    }
    
    private var engagementDescription: String {
        if engagementTrend > 0 {
            return "Engagement is trending upward"
        } else if engagementTrend < 0 {
            return "Engagement has decreased slightly"
        } else {
            return "Engagement is stable"
        }
    }
}

struct GoalCompletionCard: View {
    let groups: [AccountabilityGroup]
    let timeframe: GroupAnalyticsSection.AnalyticsTimeframe
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "target")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                Spacer()
                
                Text("\(completionRate)%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
            }
            
            Text("Goal Completion")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(completionDescription)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 6)
                        .cornerRadius(3)
                    
                    Rectangle()
                        .fill(LinearGradient(colors: [.orange, .orange.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geometry.size.width * (Double(completionRate) / 100.0), height: 6)
                        .cornerRadius(3)
                }
            }
            .frame(height: 6)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var completionRate: Int {
        // Simulate goal completion rate
        return Int.random(in: 45...85)
    }
    
    private var completionDescription: String {
        switch completionRate {
        case 80...: return "Excellent goal completion rate"
        case 60...: return "Good progress on goals"
        default: return "Goals need more attention"
        }
    }
}

struct ActivityTrendsCard: View {
    let groups: [AccountabilityGroup]
    let timeframe: GroupAnalyticsSection.AnalyticsTimeframe
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.fill")
                    .font(.title2)
                    .foregroundColor(.purple)
                
                Spacer()
                
                Text("\(peakActivityHour):00")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
            }
            
            Text("Peak Activity")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Most active time of day")
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            // Activity pattern
            HStack(spacing: 2) {
                ForEach(0..<7, id: \.self) { day in
                    VStack {
                        Rectangle()
                            .fill(activityColor(for: day))
                            .frame(width: 8, height: CGFloat(activityLevel(for: day)))
                            .cornerRadius(2)
                        
                        Text(dayLabel(for: day))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var peakActivityHour: Int {
        // Simulate peak activity hour
        return Int.random(in: 9...21)
    }
    
    private func activityLevel(for day: Int) -> Int {
        // Simulate activity levels for each day
        return Int.random(in: 20...80)
    }
    
    private func activityColor(for day: Int) -> Color {
        let level = activityLevel(for: day)
        switch level {
        case 60...: return .purple
        case 40...: return .purple.opacity(0.7)
        default: return .purple.opacity(0.3)
        }
    }
    
    private func dayLabel(for day: Int) -> String {
        let days = ["M", "T", "W", "T", "F", "S", "S"]
        return days[day]
    }
}

struct SmartRecommendationsSection: View {
    @State private var recommendations: [SmartRecommendation] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Smart Recommendations")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to full recommendations
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            if recommendations.isEmpty {
                // Generate sample recommendations
                let sampleRecommendations = [
                    SmartRecommendation(
                        type: .engagement,
                        title: "Boost Group Engagement",
                        description: "Schedule a group check-in this week to increase member participation",
                        priority: .high,
                        action: "Schedule Check-in"
                    ),
                    SmartRecommendation(
                        type: .goals,
                        title: "Set Weekly Goals",
                        description: "Create shared goals for the group to improve accountability",
                        priority: .medium,
                        action: "Create Goals"
                    ),
                    SmartRecommendation(
                        type: .activity,
                        title: "Plan Group Activity",
                        description: "Organize a virtual meetup to strengthen group bonds",
                        priority: .low,
                        action: "Plan Activity"
                    )
                ]
                
                VStack(spacing: 12) {
                    ForEach(sampleRecommendations) { recommendation in
                        RecommendationCard(recommendation: recommendation)
                    }
                }
            } else {
                VStack(spacing: 12) {
                    ForEach(recommendations) { recommendation in
                        RecommendationCard(recommendation: recommendation)
                    }
                }
            }
        }
        .onAppear {
            // Load recommendations
            recommendations = []
        }
    }
}

struct RecommendationCard: View {
    let recommendation: SmartRecommendation
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(recommendationTypeColor)
                    .frame(width: 40, height: 40)
                
                Image(systemName: recommendationTypeIcon)
                    .font(.title3)
                    .foregroundColor(.white)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(recommendation.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    PriorityBadge(priority: recommendation.priority)
                }
                
                Text(recommendation.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            // Action Button
            Button(recommendation.action) {
                // Handle recommendation action
            }
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(recommendationTypeColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(recommendationTypeColor.opacity(0.1))
            .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var recommendationTypeColor: Color {
        switch recommendation.type {
        case .engagement: return .blue
        case .goals: return .green
        case .activity: return .orange
        case .communication: return .purple
        }
    }
    
    private var recommendationTypeIcon: String {
        switch recommendation.type {
        case .engagement: return "person.3.fill"
        case .goals: return "target"
        case .activity: return "calendar"
        case .communication: return "message.fill"
        }
    }
}

struct PriorityBadge: View {
    let priority: SmartRecommendation.Priority
    
    var body: some View {
        Text(priority.rawValue)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(priorityColor.opacity(0.2))
            .foregroundColor(priorityColor)
            .cornerRadius(4)
    }
    
    private var priorityColor: Color {
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .green
        }
    }
}

// MARK: - Analytics Models

struct SmartRecommendation: Identifiable {
    let id = UUID()
    let type: RecommendationType
    let title: String
    let description: String
    let priority: Priority
    let action: String
    
    enum RecommendationType {
        case engagement
        case goals
        case activity
        case communication
    }
    
    enum Priority: String {
        case high = "High"
        case medium = "Medium"
        case low = "Low"
    }
}

// MARK: - Detailed Analytics View

struct DetailedAnalyticsView: View {
    let groups: [AccountabilityGroup]
    let timeframe: GroupAnalyticsSection.AnalyticsTimeframe
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Overview Stats
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Overview")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                            AnalyticsStatCard(
                                icon: "person.3.fill",
                                title: "Total Groups",
                                value: "\(groups.count)",
                                color: .blue
                            )
                            
                            AnalyticsStatCard(
                                icon: "person.fill",
                                title: "Total Members",
                                value: "\(totalMembers)",
                                color: .green
                            )
                            
                            AnalyticsStatCard(
                                icon: "target",
                                title: "Active Goals",
                                value: "\(activeGoals)",
                                color: .orange
                            )
                            
                            AnalyticsStatCard(
                                icon: "chart.line.uptrend.xyaxis",
                                title: "Avg. Engagement",
                                value: "\(averageEngagement)%",
                                color: .purple
                            )
                        }
                    }
                    
                    // Performance Charts
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Performance Trends")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        PerformanceChartCard()
                    }
                    
                    // Member Activity
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Member Activity")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        MemberActivityCard(groups: groups)
                    }
                }
                .padding()
            }
            .navigationTitle("Analytics")
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
    
    private var totalMembers: Int {
        groups.reduce(0) { $0 + $1.members.count }
    }
    
    private var activeGoals: Int {
        // Simulate active goals count
        return Int.random(in: 10...50)
    }
    
    private var averageEngagement: Int {
        // Calculate average engagement
        let totalMembers = groups.reduce(0) { $0 + $1.members.count }
        let activeMembers = groups.reduce(0) { $0 + $1.members.filter { $0.lastActivity > Date().addingTimeInterval(-7 * 24 * 60 * 60) }.count }
        
        guard totalMembers > 0 else { return 0 }
        return Int((Double(activeMembers) / Double(totalMembers)) * 100)
    }
}

struct AnalyticsStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct PerformanceChartCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Performance")
                .font(.subheadline)
                .fontWeight(.medium)
            
            // Simulated chart
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<7, id: \.self) { day in
                    VStack {
                        Rectangle()
                            .fill(LinearGradient(colors: [.blue, .blue.opacity(0.7)], startPoint: .bottom, endPoint: .top))
                            .frame(width: 20, height: CGFloat.random(in: 30...80))
                            .cornerRadius(4)
                        
                        Text(dayLabel(for: day))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(height: 100)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private func dayLabel(for day: Int) -> String {
        let days = ["M", "T", "W", "T", "F", "S", "S"]
        return days[day]
    }
}

struct MemberActivityCard: View {
    let groups: [AccountabilityGroup]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Most Active Members")
                .font(.subheadline)
                .fontWeight(.medium)
            
            VStack(spacing: 8) {
                ForEach(Array(topMembers.prefix(5)), id: \.userId) { member in
                    HStack {
                        Circle()
                            .fill(Color.blue.opacity(0.3))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Text(member.userId.prefix(1).uppercased())
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                            )
                        
                        Text(member.userId.prefix(8))
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text("\(memberActivityLevel(for: member))%")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var topMembers: [GroupMember] {
        groups.flatMap { $0.members }.sorted { member1, member2 in
            memberActivityLevel(for: member1) > memberActivityLevel(for: member2)
        }
    }
    
    private func memberActivityLevel(for member: GroupMember) -> Int {
        // Simulate activity level based on last activity
        let daysSinceActivity = Calendar.current.dateComponents([.day], from: member.lastActivity, to: Date()).day ?? 0
        return max(0, 100 - (daysSinceActivity * 10))
    }
}

// MARK: - Competition & Leaderboard Components

struct GroupLeaderboardsSection: View {
    let groups: [AccountabilityGroup]
    @State private var selectedTimeframe: LeaderboardTimeframe = .week
    @State private var selectedCategory: LeaderboardCategory = .goals
    
    enum LeaderboardTimeframe: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case allTime = "All Time"
        
        var icon: String {
            switch self {
            case .week: return "calendar"
            case .month: return "calendar.badge.clock"
            case .allTime: return "trophy"
            }
        }
    }
    
    enum LeaderboardCategory: String, CaseIterable {
        case goals = "Goals"
        case tasks = "Tasks"
        case events = "Events"
        case kis = "Key Indicators"
        
        var icon: String {
            switch self {
            case .goals: return "star"
            case .tasks: return "checkmark"
            case .events: return "calendar"
            case .kis: return "chart.bar"
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Leaderboards")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to full leaderboards
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            // Timeframe and Category Selectors
            VStack(spacing: 12) {
                // Timeframe Selector
                HStack {
                    Text("Timeframe:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(LeaderboardTimeframe.allCases, id: \.self) { timeframe in
                        Button(action: { selectedTimeframe = timeframe }) {
                            HStack(spacing: 4) {
                                Image(systemName: timeframe.icon)
                                    .font(.caption)
                                Text(timeframe.rawValue)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(selectedTimeframe == timeframe ? Color.blue : Color(.systemGray6))
                            .foregroundColor(selectedTimeframe == timeframe ? .white : .primary)
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                // Category Selector
                HStack {
                    Text("Category:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(LeaderboardCategory.allCases, id: \.self) { category in
                        Button(action: { selectedCategory = category }) {
                            HStack(spacing: 4) {
                                Image(systemName: category.icon)
                                    .font(.caption)
                                Text(category.rawValue)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(selectedCategory == category ? Color.orange : Color(.systemGray6))
                            .foregroundColor(selectedCategory == category ? .white : .primary)
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            // Leaderboard Cards
            VStack(spacing: 12) {
                ForEach(Array(groups.enumerated()), id: \.element.id) { index, group in
                    LeaderboardCard(
                        group: group,
                        rank: index + 1,
                        score: calculateGroupScore(group, category: selectedCategory, timeframe: selectedTimeframe),
                        category: selectedCategory
                    )
                }
            }
        }
    }
    
    private func calculateGroupScore(_ group: AccountabilityGroup, category: LeaderboardCategory, timeframe: LeaderboardTimeframe) -> Int {
        // Simulate score calculation based on group activity
        let baseScore = group.members.count * 10
        let activityMultiplier = Double.random(in: 0.5...1.5)
        let timeframeMultiplier: Double = {
            switch timeframe {
            case .week: return 1.0
            case .month: return 1.2
            case .allTime: return 1.5
            }
        }()
        
        return Int(Double(baseScore) * activityMultiplier * timeframeMultiplier)
    }
}

struct LeaderboardCard: View {
    let group: AccountabilityGroup
    let rank: Int
    let score: Int
    let category: GroupLeaderboardsSection.LeaderboardCategory
    
    var body: some View {
        HStack(spacing: 16) {
            // Rank Badge
            ZStack {
                Circle()
                    .fill(rankGradient)
                    .frame(width: 40, height: 40)
                
                Text("\(rank)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            // Group Info
            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Label("\(group.members.count) members", systemImage: "person.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if rank == 1 {
                        Label("🏆 Champion", systemImage: "trophy.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }
            }
            
            Spacer()
            
            // Score
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(score)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(rankColor)
                
                Text(category.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var rankGradient: LinearGradient {
        switch rank {
        case 1:
            return LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 2:
            return LinearGradient(colors: [.gray, .gray.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 3:
            return LinearGradient(colors: [.brown, .brown.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            return LinearGradient(colors: [.blue, .blue.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    private var rankColor: Color {
        switch rank {
        case 1: return .orange
        case 2: return .gray
        case 3: return .brown
        default: return .blue
        }
    }
}

struct WeeklyCompetitionSection: View {
    @State private var currentCompetition: WeeklyCompetition?
    @State private var showingCompetitionDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Weekly Competition")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                if let competition = currentCompetition {
                    Text("\(competition.daysRemaining) days left")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(8)
                }
            }
            
            if let competition = currentCompetition {
                WeeklyCompetitionCard(
                    competition: competition,
                    onTap: { showingCompetitionDetails = true }
                )
            } else {
                CreateCompetitionCard {
                    // Create new competition
                    currentCompetition = WeeklyCompetition.sample
                }
            }
        }
        .onAppear {
            // Load current competition
            currentCompetition = WeeklyCompetition.sample
        }
        .sheet(isPresented: $showingCompetitionDetails) {
            if let competition = currentCompetition {
                CompetitionDetailView(competition: competition)
            }
        }
    }
}

struct WeeklyCompetitionCard: View {
    let competition: WeeklyCompetition
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.purple, .purple.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "trophy.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(competition.title)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(competition.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            
            // Progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Progress")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(competition.participants.count) participants")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .frame(height: 8)
                            .cornerRadius(4)
                        
                        Rectangle()
                            .fill(LinearGradient(colors: [.purple, .purple.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geometry.size.width * competition.progress, height: 8)
                            .cornerRadius(4)
                    }
                }
                .frame(height: 8)
                
                Text("\(Int(competition.progress * 100))% complete")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Top Participants
            VStack(alignment: .leading, spacing: 8) {
                Text("Top Participants")
                    .font(.caption)
                    .fontWeight(.medium)
                
                HStack(spacing: 12) {
                    ForEach(Array(competition.participants.prefix(3)), id: \.userId) { participant in
                        ParticipantAvatar(participant: participant)
                    }
                    
                    if competition.participants.count > 3 {
                        Text("+\(competition.participants.count - 3)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Action Button
            Button(action: onTap) {
                Text("View Details")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(LinearGradient(colors: [.purple, .purple.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2) // Reduced radius from 12 to 4 for better performance
        .onTapGesture {
            onTap()
        }
    }
}

struct CreateCompetitionCard: View {
    let onCreate: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.purple.opacity(0.1), .blue.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.purple)
            }
            
            VStack(spacing: 8) {
                Text("No Active Competition")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Create a weekly competition to boost group engagement and motivation")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: onCreate) {
                Label("Create Competition", systemImage: "trophy.fill")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(LinearGradient(colors: [.purple, .purple.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2) // Reduced radius from 12 to 4 for better performance
    }
}

struct ParticipantAvatar: View {
    let participant: CompetitionParticipant
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.blue, .blue.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 32, height: 32)
                
                Text(participant.userId.prefix(1).uppercased())
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Text("\(participant.score)")
                .font(.caption2)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Competition Models

struct WeeklyCompetition: Identifiable {
    let id: String
    let title: String
    let description: String
    let startDate: Date
    let endDate: Date
    let participants: [CompetitionParticipant]
    let progress: Double
    
    var daysRemaining: Int {
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: Date(), to: endDate).day ?? 0
    }
    
    static var sample: WeeklyCompetition {
        WeeklyCompetition(
            id: UUID().uuidString,
            title: "Goal Completion Challenge",
            description: "Complete the most goals this week and win exclusive rewards!",
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
            participants: [
                CompetitionParticipant(userId: "user1", score: 85),
                CompetitionParticipant(userId: "user2", score: 72),
                CompetitionParticipant(userId: "user3", score: 68),
                CompetitionParticipant(userId: "user4", score: 45)
            ],
            progress: 0.6
        )
    }
}

struct CompetitionParticipant {
    let userId: String
    let score: Int
}

// MARK: - Competition Detail View

struct CompetitionDetailView: View {
    let competition: WeeklyCompetition
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Competition Header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [.purple, .purple.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 8) {
                            Text(competition.title)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(competition.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    
                    // Competition Stats
                    HStack(spacing: 20) {
                        CompetitionStatCard(
                            icon: "person.3.fill",
                            title: "Participants",
                            value: "\(competition.participants.count)",
                            color: .blue
                        )
                        
                        CompetitionStatCard(
                            icon: "clock.fill",
                            title: "Days Left",
                            value: "\(competition.daysRemaining)",
                            color: .orange
                        )
                        
                        CompetitionStatCard(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Progress",
                            value: "\(Int(competition.progress * 100))%",
                            color: .green
                        )
                    }
                    
                    // Leaderboard
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Leaderboard")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        VStack(spacing: 8) {
                            ForEach(Array(competition.participants.enumerated()), id: \.element.userId) { index, participant in
                                CompetitionLeaderboardRow(
                                    participant: participant,
                                    rank: index + 1
                                )
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Competition")
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

struct CompetitionStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct CompetitionLeaderboardRow: View {
    let participant: CompetitionParticipant
    let rank: Int
    
    var body: some View {
        HStack(spacing: 16) {
            // Rank
            ZStack {
                Circle()
                    .fill(rankColor)
                    .frame(width: 32, height: 32)
                
                Text("\(rank)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            // Participant
            VStack(alignment: .leading, spacing: 2) {
                Text(participant.userId)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Member")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Score
            Text("\(participant.score) pts")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(rankColor)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var rankColor: Color {
        switch rank {
        case 1: return .orange
        case 2: return .gray
        case 3: return .brown
        default: return .blue
        }
    }
}

// MARK: - Modular Groups Grid

struct ModularGroupsGrid: View {
    let widgets: [GroupWidget]
    let isEditingMode: Bool
    @Binding var draggedWidget: GroupWidget?
    let filteredGroups: [AccountabilityGroup]
    let collaborationManager: CollaborationManager
    let showCompetition: Bool
    let showAnalytics: Bool
    let onCreateGroup: () -> Void
    let onWidgetMove: (Int, Int) -> Void
    let onWidgetRemove: (Int) -> Void
    let onWidgetResize: (Int, GroupWidgetSize) -> Void
    
    private let gridSpacing: CGFloat = 16
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: gridSpacing) {
            ForEach(widgets.filter { $0.isVisible }.sorted { $0.order < $1.order }) { widget in
                GroupWidgetView(
                    widget: widget,
                    isEditingMode: isEditingMode,
                    filteredGroups: filteredGroups,
                    collaborationManager: collaborationManager,
                    showCompetition: showCompetition,
                    showAnalytics: showAnalytics,
                    onCreateGroup: onCreateGroup,
                    onRemove: {
                        if let index = widgets.firstIndex(where: { $0.id == widget.id }) {
                            onWidgetRemove(index)
                        }
                    },
                    onResize: { size in
                        if let index = widgets.firstIndex(where: { $0.id == widget.id }) {
                            onWidgetResize(index, size)
                        }
                    }
                )
                .opacity(draggedWidget?.id == widget.id ? 0.5 : 1.0)
                .scaleEffect(isEditingMode ? 0.95 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isEditingMode)
            }
        }
    }
}

// MARK: - Group Widget View

struct GroupWidgetView: View {
    let widget: GroupWidget
    let isEditingMode: Bool
    let filteredGroups: [AccountabilityGroup]
    let collaborationManager: CollaborationManager
    let showCompetition: Bool
    let showAnalytics: Bool
    let onCreateGroup: () -> Void
    let onRemove: () -> Void
    let onResize: (GroupWidgetSize) -> Void
    
    var body: some View {
        ZStack {
            // Widget Content
            Group {
                switch widget.type {
                case .myGroups:
                    MyGroupsWidget(groups: filteredGroups, onCreateGroup: onCreateGroup)
                case .recentActivity:
                    RecentActivityWidget(sharedProgress: collaborationManager.sharedProgress)
                case .invitations:
                    InvitationsWidget(invitations: collaborationManager.groupInvitations)
                case .groupStats:
                    GroupStatsWidget(groups: filteredGroups)
                case .leaderboard:
                    if showCompetition {
                        LeaderboardWidget(groups: filteredGroups)
                    } else {
                        EmptyWidget(message: "Enable competition to see leaderboard")
                    }
                case .challenges:
                    ChallengesWidget(challenges: collaborationManager.groupChallenges)
                case .analytics:
                    if showAnalytics {
                        AnalyticsWidget(groups: filteredGroups)
                    } else {
                        EmptyWidget(message: "Enable analytics to see insights")
                    }
                case .recommendations:
                    RecommendationsWidget()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            
            // Edit Mode Overlay
            if isEditingMode {
                VStack {
                    HStack {
                        // Remove button
                        Button(action: onRemove) {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.red)
                                .background(Color.white)
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        // Resize button
                        Menu {
                            ForEach(GroupWidgetSize.allCases, id: \.self) { size in
                                Button(size.rawValue.capitalized) {
                                    onResize(size)
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.title3)
                                .foregroundColor(.blue)
                                .background(Color.white)
                                .clipShape(Circle())
                        }
                    }
                    Spacer()
                }
                .padding(8)
            }
        }
        .frame(height: widgetHeight)
    }
    
    private var widgetHeight: CGFloat {
        switch widget.size {
        case .small: return 120
        case .medium: return 180
        case .large: return 240
        }
    }
}

// MARK: - Individual Widget Views

struct MyGroupsWidget: View {
    let groups: [AccountabilityGroup]
    let onCreateGroup: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("My Groups")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: onCreateGroup) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            
            if groups.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "person.3")
                        .font(.title2)
                        .foregroundColor(.gray)
                    
                    Text("No groups yet")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(groups.prefix(3)) { group in
                            CompactGroupCard(group: group)
                        }
                        
                        if groups.count > 3 {
                            Text("+\(groups.count - 3) more")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
    }
}

struct RecentActivityWidget: View {
    let sharedProgress: [String: [ProgressShare]]
    
    var allProgress: [ProgressShare] {
        sharedProgress.values.flatMap { $0 }.sorted { $0.timestamp > $1.timestamp }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)
                .fontWeight(.bold)
            
            if allProgress.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.title2)
                        .foregroundColor(.gray)
                    
                    Text("No recent activity")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(allProgress.prefix(3)) { progress in
                            CompactActivityRow(progress: progress)
                        }
                    }
                }
            }
        }
        .padding()
    }
}

struct InvitationsWidget: View {
    let invitations: [GroupInvitation]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Invitations")
                .font(.headline)
                .fontWeight(.bold)
            
            if invitations.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "envelope")
                        .font(.title2)
                        .foregroundColor(.gray)
                    
                    Text("No pending invitations")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(invitations.prefix(2)) { invitation in
                            CompactInvitationRow(invitation: invitation)
                        }
                        
                        if invitations.count > 2 {
                            Text("+\(invitations.count - 2) more")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
    }
}

struct GroupStatsWidget: View {
    let groups: [AccountabilityGroup]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Group Stats")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: 8) {
                StatRow(label: "Total Groups", value: "\(groups.count)")
                StatRow(label: "Total Members", value: "\(groups.reduce(0) { $0 + $1.members.count })")
                StatRow(label: "Active Groups", value: "\(groups.filter { $0.updatedAt > Date().addingTimeInterval(-86400) }.count)")
            }
        }
        .padding()
    }
}

struct LeaderboardWidget: View {
    let groups: [AccountabilityGroup]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Leaderboard")
                .font(.headline)
                .fontWeight(.bold)
            
            // Placeholder leaderboard content
            VStack(spacing: 6) {
                ForEach(0..<3) { index in
                    HStack {
                        Text("#\(index + 1)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                        
                        Text("Group \(index + 1)")
                            .font(.caption)
                        
                        Spacer()
                        
                        Text("\(100 - index * 10)%")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .padding()
    }
}

struct ChallengesWidget: View {
    let challenges: [GroupChallenge]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Challenges")
                .font(.headline)
                .fontWeight(.bold)
            
            if challenges.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "target")
                        .font(.title2)
                        .foregroundColor(.gray)
                    
                    Text("No active challenges")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(challenges.prefix(2)) { challenge in
                            CompactChallengeRow(challenge: challenge)
                        }
                    }
                }
            }
        }
        .padding()
    }
}

struct AnalyticsWidget: View {
    let groups: [AccountabilityGroup]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Analytics")
                .font(.headline)
                .fontWeight(.bold)
            
            // Placeholder analytics content
            VStack(spacing: 6) {
                StatRow(label: "Weekly Growth", value: "+12%")
                StatRow(label: "Engagement", value: "85%")
                StatRow(label: "Completion Rate", value: "78%")
            }
        }
        .padding()
    }
}

struct RecommendationsWidget: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommendations")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: 6) {
                Text("• Join fitness groups for motivation")
                    .font(.caption)
                Text("• Create study groups for learning")
                    .font(.caption)
                Text("• Set up accountability partners")
                    .font(.caption)
            }
        }
        .padding()
    }
}

struct EmptyWidget: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.circle")
                .font(.title2)
                .foregroundColor(.gray)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Support Views

struct CompactGroupCard: View {
    let group: AccountabilityGroup
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 24, height: 24)
                .overlay(
                    Text(group.name.prefix(1).uppercased())
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                )
            
            Text(group.name)
                .font(.caption)
                .lineLimit(1)
            
            Spacer()
            
            Text("\(group.members.count)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct CompactActivityRow: View {
    let progress: ProgressShare
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.green)
                .frame(width: 6, height: 6)
            
            Text("Progress update")
                .font(.caption2)
                .lineLimit(1)
            
            Spacer()
            
            Text(formatTime(progress.timestamp))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct CompactInvitationRow: View {
    let invitation: GroupInvitation
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.orange)
                .frame(width: 6, height: 6)
            
            Text("Group invite")
                .font(.caption2)
                .lineLimit(1)
            
            Spacer()
            
            Text("Pending")
                .font(.caption2)
                .foregroundColor(.orange)
        }
    }
}

struct CompactChallengeRow: View {
    let challenge: GroupChallenge
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.red)
                .frame(width: 6, height: 6)
            
            Text(challenge.title)
                .font(.caption2)
                .lineLimit(1)
            
            Spacer()
            
            Text("Active")
                .font(.caption2)
                .foregroundColor(.red)
        }
    }
}

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

struct AddGroupWidgetButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                
                Text("Add Widget")
                    .font(.headline)
                    .fontWeight(.medium)
            }
            .foregroundColor(.blue)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.blue.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8]))
            )
        }
    }
}

