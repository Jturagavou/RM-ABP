import SwiftUI

struct UserSuggestionView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var suggestions: [UserSuggestion] = []
    let currentUserId: String
    @Binding var selectedMembers: Set<String>

    var body: some View {
        NavigationView {
        VStack {
            TextField("Search by name or email", text: $searchText)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
                .onChange(of: searchText) { _ in
                    filterSuggestions()
                }
                
            List(filteredSuggestions) { user in
                Button(action: { selectUser(user) }) {
                    HStack {
                        if let avatar = user.avatar, let url = URL(string: avatar) {
                            AsyncImage(url: url) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Color.gray
                            }
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                        } else {
                            Circle().fill(Color.gray).frame(width: 32, height: 32)
                        }
                        VStack(alignment: .leading) {
                            Text(user.name)
                            Text(user.email).font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                            if selectedMembers.contains(user.userId) {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                        }
                        }
                    }
                }
            }
            .navigationTitle("Add Members")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear(perform: loadSuggestions)
    }

    var filteredSuggestions: [UserSuggestion] {
        if searchText.isEmpty { return suggestions }
        return suggestions.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.email.localizedCaseInsensitiveContains(searchText)
        }
    }

    private func loadSuggestions() {
        Task {
            let result = await dataManager.getActiveUsersForSuggestions(currentUserId: currentUserId)
            suggestions = result
        }
    }

    private func selectUser(_ user: UserSuggestion) {
        if !selectedMembers.contains(user.userId) {
            selectedMembers.insert(user.userId)
        } else {
            selectedMembers.remove(user.userId)
        }
    }

    private func removeUser(_ user: UserSuggestion) {
        selectedMembers.removeAll { $0 == user.userId }
    }

    private func filterSuggestions() {
        // Filtering handled by computed property
    }
} 