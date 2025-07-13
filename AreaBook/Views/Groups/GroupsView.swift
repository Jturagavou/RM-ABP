import SwiftUI

struct GroupsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var collaborationManager = CollaborationManager.shared
    @State private var showingCreateGroup = false
    @State private var showingJoinGroup = false
    @State private var selectedGroup: AccountabilityGroup?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with stats
                    GroupsHeaderCard(
                        totalGroups: collaborationManager.currentUserGroups.count,
                        totalChallenges: collaborationManager.groupChallenges.count,
                        unreadNotifications: 0 // TODO: Implement notification count
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
                    
                    if let userRole = getCurrentUserRole(in: group) {
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
    
    private func getCurrentUserRole(in group: AccountabilityGroup) -> GroupRole? {
        // TODO: Get current user ID from auth
        return group.members.first?.role
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
                Text(activityDescription)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(progress.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
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
        // TODO: Parse progress.data for more specific descriptions
        switch progress.type {
        case .kiUpdate: return "Updated life tracker progress"
        case .goalProgress: return "Made progress on a goal"
        case .taskCompleted: return "Completed a task"
        case .milestone: return "Reached a milestone"
        case .achievement: return "Unlocked an achievement"
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
    
    var body: some View {
        NavigationView {
            Form {
                Section("Group Details") {
                    TextField("Group Name", text: $groupName)
                    TextField("Description", text: $groupDescription, axis: .vertical)
                        .lineLimit(3)
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
                print("Error creating group: \(error)")
                // TODO: Show error alert
            }
            
            isCreating = false
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
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // Members List
                    GroupMembersSection(members: group.members)
                    
                    // Recent Activity
                    // TODO: Show group-specific activity
                    
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
        }
    }
    
    private func canModerateGroup() -> Bool {
        // TODO: Check if current user can moderate this group
        return true
    }
}

struct GroupMembersSection: View {
    let members: [GroupMember]
    
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
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color.blue)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(member.userId.prefix(1).uppercased())
                        .font(.headline)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(member.userId) // TODO: Get actual user name
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