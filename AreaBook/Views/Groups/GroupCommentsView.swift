import SwiftUI

struct GroupCommentsView: View {
    let targetType: CommentTargetType
    let targetId: String
    let groupId: String
    
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var collaborationManager = CollaborationManager.shared
    @State private var newCommentText = ""
    @State private var isLoading = false
    @State private var replyingToComment: GroupComment?
    @State private var showingReactionPicker: GroupComment?
    
    var comments: [GroupComment] {
        collaborationManager.groupComments[targetId] ?? []
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: iconForTargetType(targetType))
                    .foregroundColor(.blue)
                Text("Comments & Feedback")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(comments.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            
            // Comments List
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(comments) { comment in
                        CommentRowView(
                            comment: comment,
                            onReply: { replyingToComment = comment },
                            onReaction: { showingReactionPicker = comment }
                        )
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        
                        Divider()
                    }
                }
            }
            
            // Input Section
            VStack(spacing: 12) {
                if let replyingTo = replyingToComment {
                    HStack {
                        Text("Replying to \(replyingTo.authorId)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("Cancel") {
                            replyingToComment = nil
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    .padding(.horizontal)
                }
                
                HStack {
                    TextField("Add a comment...", text: $newCommentText, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(1...4)
                    
                    Button(action: sendComment) {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    .disabled(newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 12)
            .background(Color(.systemGray6))
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .onAppear {
            loadComments()
        }
        .sheet(item: $showingReactionPicker) { comment in
            ReactionPickerView(comment: comment, groupId: groupId)
        }
    }
    
    private func iconForTargetType(_ type: CommentTargetType) -> String {
        switch type {
        case .goal: return "target"
        case .event: return "calendar"
        case .task: return "checkmark.square"
        case .keyIndicator: return "chart.bar"
        }
    }
    
    private func loadComments() {
        Task {
            try await collaborationManager.loadComments(for: targetId, groupId: groupId)
        }
    }
    
    private func sendComment() {
        guard !newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let userId = authViewModel.currentUser?.id else { return }
        
        isLoading = true
        
        Task {
            do {
                try await collaborationManager.addComment(
                    to: targetType,
                    targetId: targetId,
                    content: newCommentText.trimmingCharacters(in: .whitespacesAndNewlines),
                    groupId: groupId,
                    authorId: userId,
                    parentCommentId: replyingToComment?.id
                )
                
                await MainActor.run {
                    newCommentText = ""
                    replyingToComment = nil
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

struct CommentRowView: View {
    let comment: GroupComment
    let onReply: () -> Void
    let onReaction: () -> Void
    
    private var isReply: Bool {
        comment.parentCommentId != nil
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if isReply {
                Rectangle()
                    .fill(Color(.systemGray4))
                    .frame(width: 2)
                    .padding(.leading, 20)
            }
            
            // Avatar placeholder
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 36, height: 36)
                .overlay(
                    Text(comment.authorId.prefix(1).uppercased())
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                )
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(comment.authorId)
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text(comment.createdAt, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Text(comment.content)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Reactions
                if !comment.reactions.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(ReactionType.allCases, id: \.self) { type in
                                let count = comment.reactions.filter { $0.type == type }.count
                                if count > 0 {
                                    Button(action: onReaction) {
                                        HStack(spacing: 4) {
                                            Text(reactionIcon(for: type))
                                                .font(.caption)
                                            Text("\(count)")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color(.systemGray5))
                                        .cornerRadius(12)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Action buttons
                HStack(spacing: 16) {
                    Button(action: onReply) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrowshape.turn.up.left")
                            Text("Reply")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    
                    Button(action: onReaction) {
                        HStack(spacing: 4) {
                            Image(systemName: "heart")
                            Text("React")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
        }
    }
    
    private func reactionIcon(for type: ReactionType) -> String {
        switch type {
        case .thumbsUp: return "👍"
        case .heart: return "❤️"
        case .celebrate: return "🎉"
        case .pray: return "🙏"
        case .support: return "💪"
        }
    }
}

struct ReactionPickerView: View {
    let comment: GroupComment
    let groupId: String
    
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var collaborationManager = CollaborationManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            Text("React to Comment")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                ForEach(ReactionType.allCases, id: \.self) { type in
                    Button(action: { addReaction(type) }) {
                        VStack(spacing: 8) {
                            Text(reactionIcon(for: type))
                                .font(.largeTitle)
                            Text(reactionLabel(for: type))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
            }
            
            Button("Cancel") {
                dismiss()
            }
            .font(.body)
            .foregroundColor(.secondary)
        }
        .padding()
        .presentationDetents([.medium])
    }
    
    private func reactionIcon(for type: ReactionType) -> String {
        switch type {
        case .thumbsUp: return "👍"
        case .heart: return "❤️"
        case .celebrate: return "🎉"
        case .pray: return "🙏"
        case .support: return "💪"
        }
    }
    
    private func reactionLabel(for type: ReactionType) -> String {
        switch type {
        case .thumbsUp: return "Like"
        case .heart: return "Love"
        case .celebrate: return "Celebrate"
        case .pray: return "Pray"
        case .support: return "Support"
        }
    }
    
    private func addReaction(_ type: ReactionType) {
        guard let userId = authViewModel.currentUser?.id else { return }
        
        Task {
            try await collaborationManager.addReactionToComment(
                commentId: comment.id,
                groupId: groupId,
                userId: userId,
                reactionType: type
            )
            
            await MainActor.run {
                dismiss()
            }
        }
    }
}

#Preview {
    GroupCommentsView(
        targetType: .goal,
        targetId: "test-goal-id",
        groupId: "test-group-id"
    )
    .environmentObject(AuthViewModel())
}