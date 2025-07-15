import SwiftUI

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
    @State private var selectedMembers: Set<String> = []
    @State private var searchText = ""
    @State private var suggestedUsers: [User] = []
    @State private var showingMemberSearch = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Group Details") {
                    TextField("Group Name", text: $groupName)
                    TextField("Description", text: $groupDescription, axis: .vertical)
                        .lineLimit(3)
                }
                
                Section("Invite Members") {
                    Button("Add Members") {
                        showingMemberSearch = true
                    }
                    .foregroundColor(.blue)
                    
                    if !selectedMembers.isEmpty {
                        ForEach(Array(selectedMembers), id: \.self) { memberId in
                            HStack {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Text(memberId.prefix(1).uppercased())
                                            .font(.caption)
                                            .foregroundColor(.white)
                                    )
                                
                                VStack(alignment: .leading) {
                                    Text(memberId) // In real app, this would be the user's display name
                                        .font(.subheadline)
                                    Text("Member")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button("Remove") {
                                    selectedMembers.remove(memberId)
                                }
                                .font(.caption)
                                .foregroundColor(.red)
                            }
                        }
                    }
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
            .sheet(isPresented: $showingMemberSearch) {
                MemberSearchView(
                    selectedMembers: $selectedMembers,
                    suggestedUsers: $suggestedUsers
                )
            }
            .onAppear {
                loadSuggestedUsers()
            }
        }
    }
    
    private func createGroup() {
        guard let userId = authViewModel.currentUser?.id else { return }
        
        isCreating = true
        
        Task {
            do {
                let group = try await collaborationManager.createGroup(
                    name: groupName,
                    description: groupDescription,
                    creatorId: userId
                )
                
                // Invite selected members
                for memberId in selectedMembers {
                    try? await collaborationManager.inviteUserToGroup(
                        groupId: group.id,
                        userId: memberId,
                        invitedBy: userId
                    )
                }
                
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
    
    private func loadSuggestedUsers() {
        // In a real app, this would fetch users from your backend
        // For now, we'll create some mock users
        suggestedUsers = [
            User(id: "user1", email: "john@example.com", name: "John Doe", avatar: nil, createdAt: Date(), lastSeen: Date(), settings: UserSettings()),
            User(id: "user2", email: "jane@example.com", name: "Jane Smith", avatar: nil, createdAt: Date(), lastSeen: Date(), settings: UserSettings()),
            User(id: "user3", email: "bob@example.com", name: "Bob Johnson", avatar: nil, createdAt: Date(), lastSeen: Date(), settings: UserSettings()),
            User(id: "user4", email: "alice@example.com", name: "Alice Wilson", avatar: nil, createdAt: Date(), lastSeen: Date(), settings: UserSettings()),
            User(id: "user5", email: "charlie@example.com", name: "Charlie Brown", avatar: nil, createdAt: Date(), lastSeen: Date(), settings: UserSettings())
        ]
    }
}

struct MemberSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedMembers: Set<String>
    @Binding var suggestedUsers: [User]
    
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search users...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
                
                // User List
                List {
                    Section("Suggested Users") {
                        ForEach(filteredUsers) { user in
                            UserRowView(
                                user: user,
                                isSelected: selectedMembers.contains(user.id)
                            ) {
                                if selectedMembers.contains(user.id) {
                                    selectedMembers.remove(user.id)
                                } else {
                                    selectedMembers.insert(user.id)
                                }
                            }
                        }
                    }
                    
                    if filteredUsers.isEmpty && !searchText.isEmpty {
                        Section {
                            HStack {
                                Spacer()
                                VStack(spacing: 12) {
                                    Image(systemName: "person.fill.questionmark")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                    
                                    Text("No users found")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Text("Try searching with a different name or email")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .padding(.vertical, 20)
                                Spacer()
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Add Members")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var filteredUsers: [User] {
        if searchText.isEmpty {
            return suggestedUsers
        } else {
            return suggestedUsers.filter { user in
                user.name.localizedCaseInsensitiveContains(searchText) ||
                user.email.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

struct UserRowView: View {
    let user: User
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                // Avatar
                AsyncImage(url: URL(string: user.avatar ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.blue)
                        .overlay(
                            Text(user.name.prefix(1).uppercased())
                                .font(.headline)
                                .foregroundColor(.white)
                        )
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                
                // User Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(user.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(user.email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Selection Indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.title2)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    CreateGroupView()
        .environmentObject(AuthViewModel())
}