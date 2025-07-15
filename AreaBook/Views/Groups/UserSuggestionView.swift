import SwiftUI

struct UserSuggestionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var searchText = ""
    @State private var suggestions: [UserSuggestion] = []
    @State private var isLoading = false
    @State private var selectedUsers: Set<String> = []
    
    let onUsersSelected: ([UserSuggestion]) -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search by name or email", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            searchUsers()
                        }
                    
                    Button("Search") {
                        searchUsers()
                    }
                    .disabled(searchText.isEmpty)
                }
                .padding()
                
                // Loading State
                if isLoading {
                    ProgressView("Searching...")
                        .padding()
                }
                
                // Suggestions List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(suggestions) { suggestion in
                            UserSuggestionCard(
                                suggestion: suggestion,
                                isSelected: selectedUsers.contains(suggestion.id)
                            ) {
                                if selectedUsers.contains(suggestion.id) {
                                    selectedUsers.remove(suggestion.id)
                                } else {
                                    selectedUsers.insert(suggestion.id)
                                }
                            }
                        }
                        
                        if suggestions.isEmpty && !isLoading && !searchText.isEmpty {
                            EmptySearchResultsView()
                        }
                    }
                    .padding()
                }
                
                Spacer()
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
                    Button("Add (\(selectedUsers.count))") {
                        let selectedSuggestions = suggestions.filter { selectedUsers.contains($0.id) }
                        onUsersSelected(selectedSuggestions)
                        dismiss()
                    }
                    .disabled(selectedUsers.isEmpty)
                }
            }
            .onAppear {
                loadInitialSuggestions()
            }
        }
    }
    
    private func searchUsers() {
        guard !searchText.isEmpty else { return }
        
        isLoading = true
        
        Task {
            let results = await dataManager.getUserSuggestions(searchText: searchText, limit: 20)
            
            DispatchQueue.main.async {
                self.suggestions = results
                self.isLoading = false
            }
        }
    }
    
    private func loadInitialSuggestions() {
        isLoading = true
        
        Task {
            let results = await dataManager.getUserSuggestions(limit: 10)
            
            DispatchQueue.main.async {
                self.suggestions = results
                self.isLoading = false
            }
        }
    }
}

struct UserSuggestionCard: View {
    let suggestion: UserSuggestion
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Avatar
                if let avatarURL = suggestion.avatar {
                    AsyncImage(url: URL(string: avatarURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Color.blue)
                            .overlay(
                                Text(suggestion.name.prefix(1).uppercased())
                                    .font(.headline)
                                    .foregroundColor(.white)
                            )
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 50, height: 50)
                        .overlay(
                            Text(suggestion.name.prefix(1).uppercased())
                                .font(.headline)
                                .foregroundColor(.white)
                        )
                }
                
                // User Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(suggestion.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(suggestion.email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if suggestion.mutualConnections > 0 {
                        Text("\(suggestion.mutualConnections) mutual connections")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                    
                    if let lastSeen = suggestion.lastSeen {
                        Text("Last seen \(lastSeen, style: .relative)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Selection Indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.title3)
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EmptySearchResultsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.fill.questionmark")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("No Users Found")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Try searching with a different name or email address")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 40)
    }
}

#Preview {
    UserSuggestionView { users in
        print("Selected users: \(users)")
    }
    .environmentObject(DataManager.shared)
    .environmentObject(AuthViewModel())
}