import SwiftUI

struct FullSyncManagementView: View {
    let groupId: String
    
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var collaborationManager = CollaborationManager.shared
    @State private var showingCreateSync = false
    @State private var selectedMember: GroupMember?
    @State private var syncPermissions = SyncPermissions()
    @State private var expirationDate: Date?
    @State private var hasExpiration = false
    @State private var isLoading = false
    
    var activeShares: [FullSyncShare] {
        collaborationManager.fullSyncShares.filter { $0.isActive }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "eye.fill")
                            .foregroundColor(.blue)
                        Text("Full Sync Management")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                        Button("Share New") {
                            showingCreateSync = true
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    
                    Text("Grant selected users full read-only access to your planner")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color(.systemGray6))
                
                // Active Shares List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(activeShares) { share in
                            FullSyncShareRow(share: share, onRevoke: {
                                revokeShare(share)
                            })
                        }
                        
                        if activeShares.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "eye.slash")
                                    .font(.system(size: 48))
                                    .foregroundColor(.gray)
                                
                                Text("No Active Shares")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                Text("Share your planner with group members to provide accountability and support")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                
                                Button("Create First Share") {
                                    showingCreateSync = true
                                }
                                .font(.body)
                                .foregroundColor(.blue)
                            }
                            .padding(.vertical, 40)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Full Sync")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadShares()
            }
            .sheet(isPresented: $showingCreateSync) {
                CreateFullSyncView(groupId: groupId)
            }
        }
    }
    
    private func loadShares() {
        guard let userId = authViewModel.currentUser?.id else { return }
        
        Task {
            try await collaborationManager.loadFullSyncShares(for: userId)
        }
    }
    
    private func revokeShare(_ share: FullSyncShare) {
        Task {
            try await collaborationManager.revokeFullSyncShare(shareId: share.id)
        }
    }
}

struct FullSyncShareRow: View {
    let share: FullSyncShare
    let onRevoke: () -> Void
    
    private var isExpired: Bool {
        guard let expiresAt = share.expiresAt else { return false }
        return Date() > expiresAt
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Shared with: \(share.sharedWithUserId)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("Created: \(share.createdAt, style: .date)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isExpired {
                    Text("EXPIRED")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                } else {
                    Text("ACTIVE")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            // Permissions Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                PermissionBadge(title: "Goals", isEnabled: share.permissions.canViewGoals)
                PermissionBadge(title: "Events", isEnabled: share.permissions.canViewEvents)
                PermissionBadge(title: "Tasks", isEnabled: share.permissions.canViewTasks)
                PermissionBadge(title: "Notes", isEnabled: share.permissions.canViewNotes)
                PermissionBadge(title: "KIs", isEnabled: share.permissions.canViewKIs)
                PermissionBadge(title: "Dashboard", isEnabled: share.permissions.canViewDashboard)
            }
            
            if let expiresAt = share.expiresAt {
                Text("Expires: \(expiresAt, style: .date)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Spacer()
                Button("Revoke Access") {
                    onRevoke()
                }
                .font(.caption)
                .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct CreateFullSyncView: View {
    let groupId: String
    
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var collaborationManager = CollaborationManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedMember: GroupMember?
    @State private var syncPermissions = SyncPermissions()
    @State private var hasExpiration = false
    @State private var expirationDate = Date().addingTimeInterval(30 * 24 * 3600) // 30 days
    @State private var isLoading = false
    
    var availableMembers: [GroupMember] {
        guard let currentUserId = authViewModel.currentUser?.id else { return [] }
        return collaborationManager.currentUserGroups
            .first { $0.id == groupId }?
            .members
            .filter { $0.userId != currentUserId } ?? []
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Member Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Select Member")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(availableMembers) { member in
                                Button(action: { selectedMember = member }) {
                                    HStack {
                                        Circle()
                                            .fill(selectedMember?.id == member.id ? Color.blue : Color.gray.opacity(0.3))
                                            .frame(width: 20, height: 20)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.blue, lineWidth: 2)
                                            )
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(member.userId)
                                                .font(.body)
                                                .fontWeight(.medium)
                                            Text(member.role.rawValue.capitalized)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                    }
                                    .padding(.vertical, 8)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .frame(maxHeight: 150)
                }
                
                // Permissions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Sync Permissions")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 8) {
                        PermissionToggle(title: "Goals", isEnabled: $syncPermissions.canViewGoals)
                        PermissionToggle(title: "Events", isEnabled: $syncPermissions.canViewEvents)
                        PermissionToggle(title: "Tasks", isEnabled: $syncPermissions.canViewTasks)
                        PermissionToggle(title: "Notes", isEnabled: $syncPermissions.canViewNotes)
                        PermissionToggle(title: "Key Indicators", isEnabled: $syncPermissions.canViewKIs)
                        PermissionToggle(title: "Dashboard", isEnabled: $syncPermissions.canViewDashboard)
                    }
                }
                
                // Expiration
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Set Expiration Date", isOn: $hasExpiration)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if hasExpiration {
                        DatePicker("Expires on", selection: $expirationDate, displayedComponents: .date)
                            .datePickerStyle(CompactDatePickerStyle())
                    }
                }
                
                Spacer()
                
                // Create Button
                Button(action: createSync) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Create Sync Share")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(selectedMember != nil ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(selectedMember == nil || isLoading)
            }
            .padding()
            .navigationTitle("Create Full Sync")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() }
            )
        }
    }
    
    private func createSync() {
        guard let selectedMember = selectedMember,
              let currentUserId = authViewModel.currentUser?.id else { return }
        
        isLoading = true
        
        Task {
            do {
                try await collaborationManager.createFullSyncShare(
                    ownerId: currentUserId,
                    groupId: groupId,
                    sharedWithUserId: selectedMember.userId,
                    permissions: syncPermissions,
                    expiresAt: hasExpiration ? expirationDate : nil
                )
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

struct PermissionBadge: View {
    let title: String
    let isEnabled: Bool
    
    var body: some View {
        Text(title)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(isEnabled ? .white : .secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isEnabled ? Color.blue : Color.gray.opacity(0.3))
            .cornerRadius(8)
    }
}

struct PermissionToggle: View {
    let title: String
    @Binding var isEnabled: Bool
    
    var body: some View {
        Toggle(title, isOn: $isEnabled)
            .font(.body)
    }
}

#Preview {
    FullSyncManagementView(groupId: "test-group-id")
        .environmentObject(AuthViewModel())
}