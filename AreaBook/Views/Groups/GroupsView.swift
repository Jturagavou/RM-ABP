import SwiftUI

struct GroupsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var collaborationManager = CollaborationManager.shared
    @State private var showingCreateGroup = false
    @State private var showingJoinGroup = false
    @State private var selectedGroup: AccountabilityGroup?
    @State private var showingUserSuggestions = false
    @State private var unreadNotificationCount = 0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with stats
                    GroupsHeaderCard(
                        totalGroups: collaborationManager.currentUserGroups.count,
                        totalChallenges: collaborationManager.groupChallenges.count,
                        unreadNotifications: unreadNotificationCount
                    )
                    
                    // My Groups Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("My Groups")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Button("Create Group") {
                                showingCreateGroup = true
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                        
                        if collaborationManager.currentUserGroups.isEmpty {
                            EmptyGroupsView {
                                showingCreateGroup = true
                            }
                        } else {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                                ForEach(collaborationManager.currentUserGroups) { group in
                                    GroupCard(group: group) {
                                        selectedGroup = group
                                    }
                                }
                            }
                        }
                    }
                    
                    // Recent Activity Section
                    if !collaborationManager.sharedProgress.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Recent Group Activity")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            RecentActivityList(sharedProgress: collaborationManager.sharedProgress)
                        }
                    }
                    
                    // Active Challenges Section
                    if !collaborationManager.groupChallenges.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Active Challenges")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(collaborationManager.groupChallenges) { challenge in
                                        ChallengeCard(challenge: challenge)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Groups")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Create Group", action: { showingCreateGroup = true })
                        Button("Join Group", action: { showingJoinGroup = true })
                        Divider()
                        Button("Invite Users", action: { showingUserSuggestions = true })
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
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
            .sheet(item: $selectedGroup) { group in
                GroupDetailView(group: group)
            }
            .sheet(isPresented: $showingUserSuggestions) {
                UserSuggestionView { userId in
                    // Handle user selection for invitation
                    print("Selected user: \(userId)")
                }
            }
        }
    }
    
    private func startListeners() {
        guard let userId = authViewModel.currentUser?.id else { return }
        
        collaborationManager.startListeningToUserGroups(userId: userId)
        
        // Start listening to progress for each group
        for group in collaborationManager.currentUserGroups {
            collaborationManager.startListeningToGroupProgress(groupId: group.id)
            collaborationManager.startListeningToGroupChallenges(groupId: group.id)
        }
    }
}

// MARK: - Supporting Views

struct GroupsHeaderCard: View {
    let totalGroups: Int
    let totalChallenges: Int
    let unreadNotifications: Int
    
    var body: some View {
        HStack(spacing: 20) {
            GroupStatItem(icon: "person.3.fill", title: "Groups", value: "\(totalGroups)", color: .blue)
            GroupStatItem(icon: "target", title: "Challenges", value: "\(totalChallenges)", color: .orange)
            GroupStatItem(icon: "bell.fill", title: "Updates", value: "\(unreadNotifications)", color: .red)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct GroupStatItem: View {
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
    }
}

struct EmptyGroupsView: View {
    let onCreateGroup: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("No Groups Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Create or join groups to share progress with friends and family")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Create Your First Group") {
                onCreateGroup()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct GroupCard: View {
    let group: AccountabilityGroup
    let onTap: () -> Void
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(group.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(group.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Label("\(group.members.count)", systemImage: "person.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    if let userId = authViewModel.currentUser?.id,
                       let userRole = group.members.first(where: { $0.userId == userId })?.role {
                        Text(userRole.rawValue.capitalized)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RecentActivityList: View {
    let sharedProgress: [String: [ProgressShare]]
    
    var allProgress: [ProgressShare] {
        sharedProgress.values.flatMap { $0 }.sorted { $0.timestamp > $1.timestamp }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(allProgress.prefix(5)) { progress in
                ProgressActivityRow(progress: progress)
            }
            
            if allProgress.count > 5 {
                Button("View All Activity") {
                    // Navigate to full activity view
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ProgressActivityRow: View {
    let progress: ProgressShare
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var userName: String = "User"
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(iconColor)
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: iconName)
                        .font(.caption)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(userName) \(activityDescription)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(progress.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .onAppear {
            loadUserName()
        }
    }
    
    private func loadUserName() {
        // If it's the current user, use their name
        if let currentUser = authViewModel.currentUser,
           currentUser.id == progress.userId {
            userName = currentUser.name
        } else {
            // Otherwise, show a placeholder or fetch from somewhere
            userName = "User"
        }
    }
    
    private var iconName: String {
        switch progress.type {
        case .kiUpdate: return "target"
        case .goalProgress: return "star.fill"
        case .taskCompleted: return "checkmark"
        case .milestone: return "flag.fill"
        case .achievement: return "trophy.fill"
        }
    }
    
    private var iconColor: Color {
        switch progress.type {
        case .kiUpdate: return .blue
        case .goalProgress: return .green
        case .taskCompleted: return .orange
        case .milestone: return .purple
        case .achievement: return .yellow
        }
    }
    
    private var activityDescription: String {
        switch progress.type {
        case .kiUpdate:
            if let kiName = progress.data["name"] as? String,
               let value = progress.data["value"] as? Int {
                return "updated \(kiName) to \(value)"
            }
            return "updated life tracker progress"
        case .goalProgress:
            if let goalTitle = progress.data["title"] as? String,
               let progressValue = progress.data["progress"] as? Int {
                return "made \(progressValue)% progress on \(goalTitle)"
            }
            return "made progress on a goal"
        case .taskCompleted:
            if let taskTitle = progress.data["title"] as? String {
                return "completed task: \(taskTitle)"
            }
            return "completed a task"
        case .milestone:
            if let milestone = progress.data["milestone"] as? String {
                return "reached milestone: \(milestone)"
            }
            return "reached a milestone"
        case .achievement:
            if let achievement = progress.data["achievement"] as? String {
                return "unlocked: \(achievement)"
            }
            return "unlocked an achievement"
        }
    }
}

struct ChallengeCard: View {
    let challenge: GroupChallenge
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(challenge.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                Text(challenge.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
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
                
                HStack {
                    Label("\(challenge.participants.count)", systemImage: "person.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Text("Ends \(challenge.endDate, style: .date)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Button("View Challenge") {
                // Navigate to challenge detail
            }
            .font(.caption)
            .foregroundColor(.blue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(6)
        }
        .padding()
        .frame(width: 200)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Create Group View (Fixed)

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
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Group Details") {
                    TextField("Group Name", text: $groupName)
                    TextField("Description", text: $groupDescription, axis: .vertical)
                        .lineLimit(3...5)
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
            }
            .navigationTitle("Create Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createGroup()
                    }
                    .disabled(groupName.isEmpty || isCreating)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func createGroup() {
        guard let userId = authViewModel.currentUser?.id else { return }
        
        isCreating = true
        
        Task {
            do {
                let _ = try await collaborationManager.createGroup(
                    name: groupName,
                    description: groupDescription,
                    creatorId: userId
                )
                
                DispatchQueue.main.async {
                    dismiss()
                }
            } catch {
                DispatchQueue.main.async {
                    errorMessage = "Failed to create group: \(error.localizedDescription)"
                    showError = true
                }
            }
            
            DispatchQueue.main.async {
                isCreating = false
            }
        }
    }
}

// MARK: - Join Group View (Fixed)

struct JoinGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var collaborationManager = CollaborationManager.shared
    
    @State private var invitationCode = ""
    @State private var isJoining = false
    @State private var showError = false
    @State private var errorMessage = ""
    
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
                    .autocorrectionDisabled()
                
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
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func joinGroup() {
        guard let userId = authViewModel.currentUser?.id else { return }
        
        isJoining = true
        
        Task {
            do {
                // Find group by invitation code
                guard let group = try await collaborationManager.findGroupByInvitationCode(invitationCode) else {
                    throw CollaborationError.invalidInvitationCode
                }
                
                try await collaborationManager.joinGroup(
                    groupId: group.id,
                    userId: userId,
                    invitationCode: invitationCode.uppercased()
                )
                
                DispatchQueue.main.async {
                    dismiss()
                }
            } catch CollaborationError.userAlreadyInGroup {
                DispatchQueue.main.async {
                    errorMessage = "You are already a member of this group"
                    showError = true
                }
            } catch CollaborationError.invalidInvitationCode {
                DispatchQueue.main.async {
                    errorMessage = "Invalid invitation code"
                    showError = true
                }
            } catch {
                DispatchQueue.main.async {
                    errorMessage = "Failed to join group: \(error.localizedDescription)"
                    showError = true
                }
            }
            
            DispatchQueue.main.async {
                isJoining = false
            }
        }
    }
}

// MARK: - Group Detail View (Fixed)

struct GroupDetailView: View {
    let group: AccountabilityGroup
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingInvitationCode = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Group Info Header
                    VStack(alignment: .leading, spacing: 12) {
                        Text(group.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(group.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Label("\(group.members.count) members", systemImage: "person.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                            
                            Spacer()
                            
                            Text("Created \(group.createdAt, style: .date)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if canModerateGroup() {
                            Button {
                                showingInvitationCode = true
                            } label: {
                                Label("Show Invitation Code", systemImage: "square.and.arrow.up")
                                    .font(.caption)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // Members List
                    GroupMembersSection(members: group.members)
                    
                    // Group Settings
                    if canModerateGroup() {
                        GroupSettingsSection(settings: group.settings)
                    }
                }
                .padding()
            }
            .navigationTitle("Group Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Invitation Code", isPresented: $showingInvitationCode) {
                Button("Copy", role: .none) {
                    UIPasteboard.general.string = group.invitationCode
                }
                Button("OK", role: .cancel) { }
            } message: {
                Text("Share this code with others to invite them:\n\n\(group.invitationCode)")
            }
        }
    }
    
    private func canModerateGroup() -> Bool {
        guard let userId = authViewModel.currentUser?.id else { return false }
        return group.members.first(where: { $0.userId == userId })?.role == .admin ||
               group.members.first(where: { $0.userId == userId })?.role == .moderator
    }
}

struct GroupMembersSection: View {
    let members: [GroupMember]
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Members")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVStack(spacing: 12) {
                ForEach(members, id: \.userId) { member in
                    GroupMemberRow(member: member)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct GroupMemberRow: View {
    let member: GroupMember
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var userName: String = ""
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color.blue)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(userName.prefix(1).uppercased())
                        .font(.headline)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(userName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Joined \(member.joinedAt, style: .date)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(member.role.rawValue.capitalized)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(roleColor.opacity(0.2))
                .foregroundColor(roleColor)
                .cornerRadius(6)
        }
        .onAppear {
            loadUserName()
        }
    }
    
    private func loadUserName() {
        if let currentUser = authViewModel.currentUser,
           currentUser.id == member.userId {
            userName = currentUser.name
        } else {
            userName = "User \(member.userId.prefix(4))"
        }
    }
    
    private var roleColor: Color {
        switch member.role {
        case .admin: return .red
        case .moderator: return .orange
        case .member: return .blue
        }
    }
}

struct GroupSettingsSection: View {
    let settings: GroupSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Group Settings")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                SettingRow(title: "Public Group", value: settings.isPublic ? "Yes" : "No")
                SettingRow(title: "Allow Invitations", value: settings.allowInvitations ? "Yes" : "No")
                SettingRow(title: "Share Progress", value: settings.shareProgress ? "Yes" : "No")
                SettingRow(title: "Allow Challenges", value: settings.allowChallenges ? "Yes" : "No")
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct SettingRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    GroupsView()
        .environmentObject(AuthViewModel())
}