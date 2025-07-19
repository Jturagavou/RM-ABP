import SwiftUI

struct UserSuggestionView: View {
    let onUserSelected: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedUsers = Set<String>()
    
    // Mock users for demonstration - in real app, this would come from a user search service
    @State private var suggestedUsers = [
        UserSuggestion(id: "1", name: "John Doe", email: "john@example.com"),
        UserSuggestion(id: "2", name: "Jane Smith", email: "jane@example.com"),
        UserSuggestion(id: "3", name: "Bob Johnson", email: "bob@example.com"),
        UserSuggestion(id: "4", name: "Alice Brown", email: "alice@example.com"),
        UserSuggestion(id: "5", name: "Charlie Davis", email: "charlie@example.com")
    ]
    
    var filteredUsers: [UserSuggestion] {
        if searchText.isEmpty {
            return suggestedUsers
        } else {
            return suggestedUsers.filter { user in
                user.name.localizedCaseInsensitiveContains(searchText) ||
                user.email.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search users...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding()
                
                // User List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredUsers) { user in
                            UserSuggestionRow(
                                user: user,
                                isSelected: selectedUsers.contains(user.id)
                            ) {
                                if selectedUsers.contains(user.id) {
                                    selectedUsers.remove(user.id)
                                } else {
                                    selectedUsers.insert(user.id)
                                }
                            }
                        }
                        
                        if filteredUsers.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "person.slash")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                                Text("No users found")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 50)
                        }
                    }
                    .padding()
                }
                
                // Bottom Action Bar
                if !selectedUsers.isEmpty {
                    VStack {
                        Divider()
                        HStack {
                            Text("\(selectedUsers.count) user\(selectedUsers.count == 1 ? "" : "s") selected")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button("Invite") {
                                inviteSelectedUsers()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                    }
                    .background(Color(.systemBackground))
                }
            }
            .navigationTitle("Invite Users")
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
    
    private func inviteSelectedUsers() {
        // In real app, this would send invitations
        for userId in selectedUsers {
            onUserSelected(userId)
        }
        dismiss()
    }
}

struct UserSuggestion: Identifiable {
    let id: String
    let name: String
    let email: String
}

struct UserSuggestionRow: View {
    let user: UserSuggestion
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(user.name.prefix(1).uppercased())
                            .font(.headline)
                            .foregroundColor(.blue)
                    )
                
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
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.title2)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    UserSuggestionView { userId in
        print("Selected user: \(userId)")
    }
}