import SwiftUI

struct UserSuggestionView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var searchText = ""
    @State private var suggestions: [UserSuggestion] = []
    @State private var selectedUsers: [UserSuggestion] = []
    let currentUserId: String

    var body: some View {
        VStack {
            TextField("Search by name or email", text: $searchText)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
                .onChange(of: searchText) { _ in
                    filterSuggestions()
                }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(selectedUsers) { user in
                        HStack {
                            Text(user.name)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(6)
                            Button(action: { removeUser(user) }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                .padding(.horizontal)
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
                        if selectedUsers.contains(where: { $0.userId == user.userId }) {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                        }
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
        if !selectedUsers.contains(where: { $0.userId == user.userId }) {
            selectedUsers.append(user)
        }
    }

    private func removeUser(_ user: UserSuggestion) {
        selectedUsers.removeAll { $0.userId == user.userId }
    }

    private func filterSuggestions() {
        // Filtering handled by computed property
    }
} 