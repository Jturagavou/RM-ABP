import SwiftUI

struct ConflictResolutionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var conflictService = ConflictResolutionService.shared
    
    @State private var selectedConflict: DataConflict?
    @State private var showingConflictDetail = false
    @State private var isResolving = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if conflictService.activeConflicts.isEmpty {
                    // No Conflicts State
                    ConflictsEmptyState()
                } else {
                    // Conflicts List
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Active Conflicts Header
                            HStack {
                                Text("Active Conflicts")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                Text("\(conflictService.activeConflicts.count)")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.orange)
                                    .foregroundColor(.white)
                                    .cornerRadius(6)
                            }
                            .padding(.horizontal)
                            
                            // Conflicts List
                            ForEach(conflictService.activeConflicts) { conflict in
                                ConflictCard(
                                    conflict: conflict,
                                    onTap: {
                                        selectedConflict = conflict
                                        showingConflictDetail = true
                                    },
                                    onQuickResolve: { strategy in
                                        resolveConflict(conflict, strategy: strategy)
                                    }
                                )
                            }
                            
                            // Auto-Resolve Section
                            if conflictService.activeConflicts.count > 1 {
                                AutoResolveSection {
                                    autoResolveAllConflicts()
                                }
                            }
                            
                            // Resolved Conflicts Section
                            if !conflictService.resolvedConflicts.isEmpty {
                                ResolvedConflictsSection(
                                    resolvedConflicts: conflictService.resolvedConflicts
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Conflict Resolution")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if !conflictService.activeConflicts.isEmpty {
                        Button("Auto-Resolve") {
                            autoResolveAllConflicts()
                        }
                        .disabled(isResolving)
                    }
                    
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingConflictDetail) {
                if let conflict = selectedConflict {
                    ConflictDetailView(
                        conflict: conflict,
                        onResolve: { strategy in
                            resolveConflict(conflict, strategy: strategy)
                            showingConflictDetail = false
                        }
                    )
                }
            }
            .overlay {
                if isResolving {
                    ResolvingOverlay()
                }
            }
        }
    }
    
    // MARK: - Conflict Resolution
    
    private func resolveConflict(_ conflict: DataConflict, strategy: ConflictResolutionStrategy) {
        guard let userId = authViewModel.currentUser?.id else { return }
        
        isResolving = true
        
        Task {
            do {
                try await conflictService.resolveConflict(conflict, strategy: strategy, userId: userId)
            } catch {
                print("Failed to resolve conflict: \(error)")
            }
            
            await MainActor.run {
                isResolving = false
            }
        }
    }
    
    private func autoResolveAllConflicts() {
        guard let userId = authViewModel.currentUser?.id else { return }
        
        isResolving = true
        
        Task {
            await conflictService.autoResolveConflicts(userId: userId)
            
            await MainActor.run {
                isResolving = false
            }
        }
    }
}

// MARK: - Supporting Views

struct ConflictsEmptyState: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 64))
                .foregroundColor(.green)
            
            VStack(spacing: 12) {
                Text("No Conflicts")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("All your data is synchronized and there are no conflicts to resolve.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Data integrity maintained")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Image(systemName: "icloud.and.arrow.up")
                        .foregroundColor(.blue)
                    Text("All changes synchronized")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct ConflictCard: View {
    let conflict: DataConflict
    let onTap: () -> Void
    let onQuickResolve: (ConflictResolutionStrategy) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: iconForEntityType(conflict.entityType))
                            .font(.title3)
                            .foregroundColor(colorForConflictType(conflict.conflictType))
                        
                        Text(conflict.entityType)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        ConflictTypeBadge(type: conflict.conflictType)
                    }
                    
                    Text("Detected \(timeAgoString(from: conflict.detectedAt))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Conflict Description
            Text(conflictDescription)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            // Quick Resolution Buttons
            HStack {
                Button(action: { onQuickResolve(.useLocal) }) {
                    QuickResolveButton(
                        title: "Use Local",
                        subtitle: "Keep my version",
                        icon: "iphone",
                        color: .blue
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: { onQuickResolve(.useServer) }) {
                    QuickResolveButton(
                        title: "Use Server",
                        subtitle: "Use cloud version",
                        icon: "icloud",
                        color: .green
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                if canMerge {
                    Button(action: { onQuickResolve(.merge) }) {
                        QuickResolveButton(
                            title: "Merge",
                            subtitle: "Combine both",
                            icon: "arrow.triangle.merge",
                            color: .purple
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // View Details Button
            Button(action: onTap) {
                HStack {
                    Text("View Details")
                        .font(.caption)
                        .fontWeight(.medium)
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                }
                .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(colorForConflictType(conflict.conflictType).opacity(0.3), lineWidth: 1)
        )
    }
    
    private var conflictDescription: String {
        switch conflict.conflictType {
        case .update:
            return "This item was modified both locally and on the server. Choose which version to keep or merge the changes."
        case .delete:
            return "This item was deleted in one location but modified in another. Decide whether to keep or remove it."
        case .create:
            return "This item was created in multiple locations with different data. Choose which version to use."
        case .permission:
            return "There's a permission conflict for this item. Administrative action may be required."
        }
    }
    
    private var canMerge: Bool {
        conflict.conflictType == .update && conflict.entityType != "CalendarEvent"
    }
    
    private func iconForEntityType(_ entityType: String) -> String {
        switch entityType {
        case "Goal": return "target"
        case "Task": return "checkmark.circle"
        case "CalendarEvent": return "calendar"
        case "KeyIndicator": return "chart.bar"
        case "Note": return "note.text"
        case "AccountabilityGroup": return "person.3"
        default: return "doc"
        }
    }
    
    private func colorForConflictType(_ type: ConflictType) -> Color {
        switch type {
        case .update: return .orange
        case .delete: return .red
        case .create: return .blue
        case .permission: return .purple
        }
    }
}

struct ConflictTypeBadge: View {
    let type: ConflictType
    
    var body: some View {
        Text(type.rawValue.capitalized)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(backgroundColorForType(type))
            .foregroundColor(.white)
            .cornerRadius(4)
    }
    
    private func backgroundColorForType(_ type: ConflictType) -> Color {
        switch type {
        case .update: return .orange
        case .delete: return .red
        case .create: return .blue
        case .permission: return .purple
        }
    }
}

struct QuickResolveButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(6)
    }
}

struct AutoResolveSection: View {
    let onAutoResolve: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Batch Resolution")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Automatically resolve all conflicts using default strategies. This will use the most appropriate resolution method for each conflict type.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button(action: onAutoResolve) {
                HStack {
                    Image(systemName: "wand.and.stars")
                        .font(.title3)
                    Text("Auto-Resolve All Conflicts")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct ResolvedConflictsSection: View {
    let resolvedConflicts: [DataConflict]
    @State private var showingAll = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recently Resolved")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if resolvedConflicts.count > 3 {
                    Button(showingAll ? "Show Less" : "Show All") {
                        showingAll.toggle()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            
            let displayedConflicts = showingAll ? resolvedConflicts : Array(resolvedConflicts.prefix(3))
            
            ForEach(displayedConflicts) { conflict in
                ResolvedConflictRow(conflict: conflict)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct ResolvedConflictRow: View {
    let conflict: DataConflict
    
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(conflict.entityType)
                    .font(.caption)
                    .fontWeight(.medium)
                
                if let strategy = conflict.resolutionStrategy {
                    Text("Resolved using \(strategy.rawValue)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if let resolvedAt = conflict.resolvedAt {
                Text(timeAgoString(from: resolvedAt))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ConflictDetailView: View {
    let conflict: DataConflict
    let onResolve: (ConflictResolutionStrategy) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Conflict Overview
                    ConflictOverviewCard(conflict: conflict)
                    
                    // Data Comparison
                    DataComparisonSection(conflict: conflict)
                    
                    // Resolution Options
                    ResolutionOptionsSection(
                        conflict: conflict,
                        onResolve: onResolve
                    )
                }
                .padding()
            }
            .navigationTitle("Conflict Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ConflictOverviewCard: View {
    let conflict: DataConflict
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: iconForEntityType(conflict.entityType))
                    .font(.title2)
                    .foregroundColor(colorForConflictType(conflict.conflictType))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(conflict.entityType)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Conflict Type: \(conflict.conflictType.rawValue.capitalized)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(
                    title: "Detected",
                    value: DateFormatter.medium.string(from: conflict.detectedAt)
                )
                
                InfoRow(
                    title: "Entity ID",
                    value: String(conflict.entityId.prefix(8)) + "..."
                )
                
                InfoRow(
                    title: "Conflict Reason",
                    value: conflictReason
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var conflictReason: String {
        switch conflict.conflictType {
        case .update: return "Simultaneous modifications"
        case .delete: return "Delete vs modify conflict"
        case .create: return "Duplicate creation"
        case .permission: return "Access rights mismatch"
        }
    }
    
    private func iconForEntityType(_ entityType: String) -> String {
        switch entityType {
        case "Goal": return "target"
        case "Task": return "checkmark.circle"
        case "CalendarEvent": return "calendar"
        case "KeyIndicator": return "chart.bar"
        case "Note": return "note.text"
        case "AccountabilityGroup": return "person.3"
        default: return "doc"
        }
    }
    
    private func colorForConflictType(_ type: ConflictType) -> Color {
        switch type {
        case .update: return .orange
        case .delete: return .red
        case .create: return .blue
        case .permission: return .purple
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

struct DataComparisonSection: View {
    let conflict: DataConflict
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Data Comparison")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(alignment: .top, spacing: 16) {
                // Local Version
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "iphone")
                            .foregroundColor(.blue)
                        Text("Local Version")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    DataVersionCard(data: conflict.localVersion, isLocal: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Server Version
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "icloud")
                            .foregroundColor(.green)
                        Text("Server Version")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    DataVersionCard(data: conflict.serverVersion, isLocal: false)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct DataVersionCard: View {
    let data: [String: Any]
    let isLocal: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(data.keys.prefix(5).sorted()), id: \.self) { key in
                if let value = data[key] {
                    DataFieldRow(key: key, value: "\(value)")
                }
            }
            
            if data.keys.count > 5 {
                Text("+ \(data.keys.count - 5) more fields")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isLocal ? Color.blue.opacity(0.3) : Color.green.opacity(0.3), lineWidth: 1)
        )
    }
}

struct DataFieldRow: View {
    let key: String
    let value: String
    
    var body: some View {
        HStack {
            Text(key)
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)
            
            Text(value)
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }
}

struct ResolutionOptionsSection: View {
    let conflict: DataConflict
    let onResolve: (ConflictResolutionStrategy) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Resolution Options")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ResolutionOptionCard(
                    strategy: .useLocal,
                    title: "Use Local Version",
                    description: "Keep the version on this device and discard the server version.",
                    icon: "iphone",
                    color: .blue,
                    onSelect: { onResolve(.useLocal) }
                )
                
                ResolutionOptionCard(
                    strategy: .useServer,
                    title: "Use Server Version",
                    description: "Use the version from the server and discard local changes.",
                    icon: "icloud",
                    color: .green,
                    onSelect: { onResolve(.useServer) }
                )
                
                if conflict.conflictType == .update {
                    ResolutionOptionCard(
                        strategy: .merge,
                        title: "Merge Versions",
                        description: "Intelligently combine both versions when possible.",
                        icon: "arrow.triangle.merge",
                        color: .purple,
                        onSelect: { onResolve(.merge) }
                    )
                }
                
                ResolutionOptionCard(
                    strategy: .manual,
                    title: "Manual Resolution",
                    description: "Manually edit the data to resolve the conflict.",
                    icon: "pencil",
                    color: .orange,
                    onSelect: { onResolve(.manual) }
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct ResolutionOptionCard: View {
    let strategy: ConflictResolutionStrategy
    let title: String
    let description: String
    let icon: String
    let color: Color
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ResolvingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                
                Text("Resolving Conflicts...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(Color.black.opacity(0.8))
            .cornerRadius(16)
        }
    }
}

// MARK: - Helper Functions

private func timeAgoString(from date: Date) -> String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .abbreviated
    return formatter.localizedString(for: date, relativeTo: Date())
}

extension DateFormatter {
    static let medium: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

#Preview {
    ConflictResolutionView()
        .environmentObject(AuthViewModel())
}