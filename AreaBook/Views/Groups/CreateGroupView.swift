import SwiftUI

struct CreateGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var name = ""
    @State private var description = ""
    @State private var groupType: GroupType = .district
    @State private var parentGroupId: String?
    @State private var selectedMembers: Set<String> = []
    @State private var showingMemberPicker = false
    @State private var showingParentGroupPicker = false
    @State private var availableParentGroups: [AccountabilityGroup] = []
    @State private var groupColor: GroupColor = .blue
    @State private var tags: [String] = []
    @State private var newTag = ""
    @State private var linkedGoalIds: Set<String> = []
    @State private var linkedTaskIds: Set<String> = []
    @State private var linkedEventIds: Set<String> = []
    @State private var showingGoalPicker = false
    @State private var showingTaskPicker = false
    @State private var showingEventPicker = false
    @State private var memberSuggestions: [UserSuggestion] = []
    
    // Group Settings
    @State private var isPublic = false
    @State private var allowInvitations = true
    @State private var shareProgress = true
    @State private var allowChallenges = true
    
    let groupToEdit: AccountabilityGroup?
    
    enum GroupColor: String, CaseIterable {
        case blue = "Blue"
        case green = "Green"
        case purple = "Purple"
        case orange = "Orange"
        case red = "Red"
        case pink = "Pink"
        case yellow = "Yellow"
        case gray = "Gray"
        
        var color: Color {
            switch self {
            case .blue: return .blue
            case .green: return .green
            case .purple: return .purple
            case .orange: return .orange
            case .red: return .red
            case .pink: return .pink
            case .yellow: return .yellow
            case .gray: return .gray
            }
        }
    }
    
    init(groupToEdit: AccountabilityGroup? = nil) {
        self.groupToEdit = groupToEdit
        if let group = groupToEdit {
            _name = State(initialValue: group.name)
            _description = State(initialValue: group.settings.description)
            _groupType = State(initialValue: group.type)
            _parentGroupId = State(initialValue: group.parentGroupId)
            _isPublic = State(initialValue: group.settings.isPublic)
            _allowInvitations = State(initialValue: group.settings.allowInvitations)
            _shareProgress = State(initialValue: group.settings.shareProgress)
            _allowChallenges = State(initialValue: group.settings.allowChallenges)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Basic Information Section
                Section("Basic Information") {
                    TextField("Group Name", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Description", text: $description, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                    
                    Picker("Group Type", selection: $groupType) {
                        ForEach(GroupType.allCases, id: \.self) { type in
                            Label(type.displayName, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    if groupType == .companionship {
                        HStack {
                            Text("Parent District")
                            Spacer()
                            if let parentId = parentGroupId,
                               let parentGroup = availableParentGroups.first(where: { $0.id == parentId }) {
                                Text(parentGroup.name)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Select District")
                                    .foregroundColor(.blue)
                            }
                            
                            Button("Choose") {
                                showingParentGroupPicker = true
                            }
                            .foregroundColor(.blue)
                        }
                    }
                    
                    HStack {
                        Text("Color")
                        Spacer()
                        ForEach(GroupColor.allCases, id: \.self) { color in
                            Circle()
                                .fill(color.color)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Circle()
                                        .stroke(groupColor == color ? Color.primary : Color.clear, lineWidth: 2)
                                )
                                .onTapGesture {
                                    groupColor = color
                                }
                        }
                    }
                }
                
                // Group Settings Section
                Section("Group Settings") {
                    Toggle("Public Group", isOn: $isPublic)
                        .onChange(of: isPublic) { newValue in
                            if newValue {
                                allowInvitations = true
                            }
                        }
                    
                    Toggle("Allow Invitations", isOn: $allowInvitations)
                        .disabled(isPublic)
                    
                    Toggle("Share Progress", isOn: $shareProgress)
                        .onChange(of: shareProgress) { newValue in
                            if !newValue {
                                allowChallenges = false
                            }
                        }
                    
                    Toggle("Allow Challenges", isOn: $allowChallenges)
                        .disabled(!shareProgress)
                }
                
                // Members Section
                Section("Members") {
                    HStack {
                        Text("Selected Members")
                        Spacer()
                        Text("\(selectedMembers.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Add Members") {
                        showingMemberPicker = true
                    }
                    .foregroundColor(.blue)
                    
                    if !selectedMembers.isEmpty {
                        ForEach(Array(selectedMembers), id: \.self) { memberId in
                            if let memberSuggestion = memberSuggestions.first(where: { $0.userId == memberId }) {
                                HStack {
                                    AsyncImage(url: URL(string: memberSuggestion.avatar ?? "")) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Image(systemName: "person.circle.fill")
                                            .foregroundColor(.blue)
                                    }
                                    .frame(width: 32, height: 32)
                                    .clipShape(Circle())
                                    
                                    VStack(alignment: .leading) {
                                        Text(memberSuggestion.name)
                                            .font(.subheadline)
                                        Text(memberSuggestion.email)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Button("Remove") {
                                        selectedMembers.remove(memberId)
                                    }
                                    .foregroundColor(.red)
                                    .font(.caption)
                                }
                            } else {
                                // Fallback for members not in suggestions
                                HStack {
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Text(String(memberId.prefix(1)).uppercased())
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        )
                                    
                                    VStack(alignment: .leading) {
                                        Text("Member \(memberId.prefix(8))")
                                            .font(.subheadline)
                                        Text("Member")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Button("Remove") {
                                        selectedMembers.remove(memberId)
                                    }
                                    .foregroundColor(.red)
                                    .font(.caption)
                                }
                            }
                        }
                    }
                }
                
                // Tags Section
                Section("Tags") {
                    HStack {
                        TextField("Add tag", text: $newTag)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button("Add") {
                            if !newTag.isEmpty && !tags.contains(newTag) {
                                tags.append(newTag)
                                newTag = ""
                            }
                        }
                        .disabled(newTag.isEmpty)
                    }
                    
                    if !tags.isEmpty {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                            ForEach(tags, id: \.self) { tag in
                                HStack {
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(8)
                                    
                                    Spacer()
                                    
                                    Button("×") {
                                        tags.removeAll { $0 == tag }
                                    }
                                    .foregroundColor(.red)
                                    .font(.caption)
                                }
                            }
                        }
                    }
                }
                
                // Linked Items Section
                Section("Linked Items") {
                    HStack {
                        Text("Linked Goals")
                        Spacer()
                        Text("\(linkedGoalIds.count)")
                            .foregroundColor(.secondary)
                        
                        Button("Add") {
                            showingGoalPicker = true
                        }
                        .foregroundColor(.blue)
                    }
                    
                    HStack {
                        Text("Linked Tasks")
                        Spacer()
                        Text("\(linkedTaskIds.count)")
                            .foregroundColor(.secondary)
                        
                        Button("Add") {
                            showingTaskPicker = true
                        }
                        .foregroundColor(.blue)
                    }
                    
                    HStack {
                        Text("Linked Events")
                        Spacer()
                        Text("\(linkedEventIds.count)")
                            .foregroundColor(.secondary)
                        
                        Button("Add") {
                            showingEventPicker = true
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            .navigationTitle(groupToEdit == nil ? "Create Group" : "Edit Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveGroup()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
        .onAppear {
            loadParentGroups()
            loadMemberSuggestions()
        }
        .sheet(isPresented: $showingParentGroupPicker) {
            ParentGroupPickerView(selectedGroupId: $parentGroupId, availableGroups: availableParentGroups)
        }
        .sheet(isPresented: $showingMemberPicker) {
            if let currentUserId = authViewModel.currentUser?.id {
                UserSuggestionView(currentUserId: currentUserId, selectedMembers: $selectedMembers)
                    .environmentObject(dataManager)
                    .environmentObject(authViewModel)
            } else {
                Text("User not authenticated")
            }
        }
        .sheet(isPresented: $showingGoalPicker) {
            GoalPickerView(selectedGoalIds: $linkedGoalIds)
        }
        .sheet(isPresented: $showingTaskPicker) {
            TaskPickerView(selectedTaskIds: $linkedTaskIds)
        }
        .sheet(isPresented: $showingEventPicker) {
            EventPickerView(selectedEventIds: $linkedEventIds)
        }
    }
    
    private func loadParentGroups() {
        // Load available district groups for companionship selection
        if groupType == .companionship {
            // This would load from DataManager
            // For now, we'll use placeholder data
            availableParentGroups = []
        }
    }
    
    private func loadMemberSuggestions() {
        guard let currentUserId = authViewModel.currentUser?.id else { return }
        
        Task {
            let userSuggestions = await dataManager.getActiveUsersForSuggestions(currentUserId: currentUserId)
            
            await MainActor.run {
                self.memberSuggestions = userSuggestions
            }
        }
    }
    
    private func saveGroup() {
        guard let currentUser = authViewModel.currentUser else { return }
        
        var settings = GroupSettings()
        settings.isPublic = isPublic
        settings.allowInvitations = allowInvitations
        settings.shareProgress = shareProgress
        settings.allowChallenges = allowChallenges
        settings.description = description
        
        var group = AccountabilityGroup(
            name: name,
            type: groupType,
            parentGroupId: groupType == .companionship ? parentGroupId : nil
        )
        
        // Add current user as admin
        let adminMember = GroupMember(userId: currentUser.id, role: .admin)
        group.members.append(adminMember)
        
        // Add selected members
        for memberId in selectedMembers {
            let member = GroupMember(userId: memberId, role: .member)
            group.members.append(member)
        }
        
        // Save to DataManager
        Task {
            do {
                if let existingGroup = groupToEdit {
                    dataManager.updateAccountabilityGroup(group)
                } else {
                    dataManager.createAccountabilityGroup(group)
                }
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("Error saving group: \(error)")
            }
        }
    }
}

// MARK: - Supporting Views

struct ParentGroupPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedGroupId: String?
    let availableGroups: [AccountabilityGroup]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(availableGroups) { group in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(group.name)
                                .font(.headline)
                            Text("\(group.members.count) members")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if selectedGroupId == group.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedGroupId = group.id
                        dismiss()
                    }
                }
            }
            .navigationTitle("Select District")
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

struct MemberPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @Binding var selectedMembers: Set<String>
    
    @State private var suggestions: [UserSuggestion] = []
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var showingSearchResults = false
    
    var filteredSuggestions: [UserSuggestion] {
        if searchText.isEmpty {
            return suggestions
        } else {
            return suggestions.filter { suggestion in
                suggestion.name.localizedCaseInsensitiveContains(searchText) ||
                suggestion.email.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var groupedSuggestions: [String: [UserSuggestion]] {
        Dictionary(grouping: filteredSuggestions) { suggestion in
            if suggestion.groupContext != nil {
                return "Group Members"
            } else {
                return "Recently Active"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                SearchBar(text: $searchText, placeholder: "Search by name or email")
                    .padding()
                
                if isLoading {
                    Spacer()
                    ProgressView("Loading suggestions...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if suggestions.isEmpty {
                    Spacer()
                    EmptySuggestionsView()
                } else {
                    List {
                        // Selected Members Section
                        if !selectedMembers.isEmpty {
                            Section("Selected Members") {
                                ForEach(Array(selectedMembers), id: \.self) { memberId in
                                    if let suggestion = suggestions.first(where: { $0.userId == memberId }) {
                                        SelectedMemberRow(suggestion: suggestion) {
                                            selectedMembers.remove(memberId)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Suggestions Sections
                        ForEach(Array(groupedSuggestions.keys.sorted()), id: \.self) { sectionTitle in
                            Section(sectionTitle) {
                                ForEach(groupedSuggestions[sectionTitle] ?? [], id: \.id) { suggestion in
                                    SuggestionRow(
                                        suggestion: suggestion,
                                        isSelected: selectedMembers.contains(suggestion.userId)
                                    ) {
                                        if selectedMembers.contains(suggestion.userId) {
                                            selectedMembers.remove(suggestion.userId)
                                        } else {
                                            selectedMembers.insert(suggestion.userId)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
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
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            loadSuggestions()
        }
    }
    
    private func loadSuggestions() {
        guard let currentUserId = authViewModel.currentUser?.id else { return }
        
        isLoading = true
        Task {
            let userSuggestions = await dataManager.getActiveUsersForSuggestions(currentUserId: currentUserId)
            
            await MainActor.run {
                self.suggestions = userSuggestions
                self.isLoading = false
            }
        }
    }
}

// MARK: - Supporting Views

struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct EmptySuggestionsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("No Suggestions Available")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Start by creating groups or connecting with other users to see member suggestions")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
}

struct SuggestionRow: View {
    let suggestion: UserSuggestion
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Avatar
                AsyncImage(url: URL(string: suggestion.avatar ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.blue)
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                
                // User Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(suggestion.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(suggestion.email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text(suggestion.suggestionReason)
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                        
                        if let groupContext = suggestion.groupContext {
                            Text("• \(groupContext)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Selection Indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .secondary)
                    .font(.title2)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SelectedMemberRow: View {
    let suggestion: UserSuggestion
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            AsyncImage(url: URL(string: suggestion.avatar ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.blue)
            }
            .frame(width: 32, height: 32)
            .clipShape(Circle())
            
            // User Info
            VStack(alignment: .leading, spacing: 2) {
                Text(suggestion.name)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Text(suggestion.email)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Remove Button
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .font(.title3)
            }
        }
    }
}

struct GoalPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedGoalIds: Set<String>
    
    var body: some View {
        NavigationView {
            List {
                Text("Goal picker implementation")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Link Goals")
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

struct TaskPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTaskIds: Set<String>
    
    var body: some View {
        NavigationView {
            List {
                Text("Task picker implementation")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Link Tasks")
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

struct EventPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedEventIds: Set<String>
    
    var body: some View {
        NavigationView {
            List {
                Text("Event picker implementation")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Link Events")
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

// MARK: - Extensions

extension GroupType {
    var displayName: String {
        switch self {
        case .district: return "District"
        case .companionship: return "Companionship"
        }
    }
    
    var icon: String {
        switch self {
        case .district: return "building.2"
        case .companionship: return "person.2"
        }
    }
} 