import SwiftUI

struct AISuggestionsView: View {
    @StateObject private var aiService = AIService.shared
    @State private var showingSuggestionDetail: AISuggestion?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.accentColor)
                
                Text("AI Suggestions")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if !aiService.currentSuggestions.isEmpty {
                    Text("\(aiService.currentSuggestions.count)")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.accentColor)
                        )
                        .foregroundColor(.white)
                }
            }
            
            // Suggestions list
            if aiService.currentSuggestions.isEmpty {
                emptyStateView
            } else {
                suggestionsList
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .sheet(item: $showingSuggestionDetail) { suggestion in
            SuggestionDetailView(suggestion: suggestion)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("No suggestions yet")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("The AI assistant will provide personalized suggestions based on your activity patterns.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 20)
    }
    
    private var suggestionsList: some View {
        VStack(spacing: 12) {
            ForEach(aiService.currentSuggestions.prefix(3)) { suggestion in
                SuggestionCard(suggestion: suggestion) {
                    showingSuggestionDetail = suggestion
                }
            }
            
            if aiService.currentSuggestions.count > 3 {
                Button("View All \(aiService.currentSuggestions.count) Suggestions") {
                    // Navigate to full suggestions list
                }
                .font(.caption)
                .foregroundColor(.accentColor)
            }
        }
    }
}

struct SuggestionCard: View {
    let suggestion: AISuggestion
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: suggestion.type.icon)
                    .font(.title2)
                    .foregroundColor(suggestion.priority.color)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(suggestion.priority.color.opacity(0.1))
                    )
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(suggestion.type.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(suggestion.message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    HStack {
                        Text(suggestion.createdAt.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        // Priority indicator
                        Circle()
                            .fill(suggestion.priority.color)
                            .frame(width: 8, height: 8)
                    }
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SuggestionDetailView: View {
    let suggestion: AISuggestion
    @Environment(\.dismiss) private var dismiss
    @StateObject private var aiService = AIService.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: suggestion.type.icon)
                            .font(.system(size: 50))
                            .foregroundColor(suggestion.priority.color)
                        
                        VStack(spacing: 8) {
                            Text(suggestion.type.displayName)
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text(suggestion.message)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(suggestion.priority.color.opacity(0.1))
                    )
                    
                    // Details
                    VStack(alignment: .leading, spacing: 16) {
                        AISuggestionDetailRow(title: "Priority", value: suggestion.priority.rawValue.capitalized, icon: "flag")
                        AISuggestionDetailRow(title: "Created", value: suggestion.createdAt.formatted(), icon: "calendar")
                        
                        if let expiresAt = suggestion.expiresAt {
                            AISuggestionDetailRow(title: "Expires", value: expiresAt.formatted(), icon: "clock")
                        }
                        
                        if let acceptedAt = suggestion.acceptedAt {
                            AISuggestionDetailRow(title: "Accepted", value: acceptedAt.formatted(), icon: "checkmark.circle")
                        }
                        
                        if let dismissedAt = suggestion.dismissedAt {
                            AISuggestionDetailRow(title: "Dismissed", value: dismissedAt.formatted(), icon: "xmark.circle")
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                    
                    // Action buttons
                    if suggestion.status == .pending {
                        VStack(spacing: 12) {
                            Button(action: acceptSuggestion) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Accept Suggestion")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.green)
                                )
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                            }
                            
                            Button(action: dismissSuggestion) {
                                HStack {
                                    Image(systemName: "xmark.circle.fill")
                                    Text("Dismiss")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.red)
                                )
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                            }
                        }
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .navigationTitle("Suggestion Details")
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
    
    private func acceptSuggestion() {
        aiService.acceptSuggestion(suggestion)
        dismiss()
    }
    
    private func dismissSuggestion() {
        aiService.dismissSuggestion(suggestion)
        dismiss()
    }
}

struct AISuggestionDetailRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Inline Suggestion Components
struct InlineSuggestionView: View {
    let suggestion: AISuggestion
    let onAccept: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: suggestion.type.icon)
                    .foregroundColor(suggestion.priority.color)
                
                Text(suggestion.type.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.accentColor)
                
                Spacer()
                
                Text("AI Suggestion")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.accentColor.opacity(0.2))
                    )
                    .foregroundColor(.accentColor)
            }
            
            Text(suggestion.message)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Button("Accept") {
                    onAccept()
                }
                .font(.caption)
                .foregroundColor(.green)
                
                Button("Dismiss") {
                    onDismiss()
                }
                .font(.caption)
                .foregroundColor(.red)
                
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.accentColor.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.accentColor.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct ContextualSuggestionButton: View {
    let suggestion: AISuggestion
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: suggestion.type.icon)
                    .font(.caption)
                
                Text("AI Help")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.accentColor.opacity(0.1))
            )
            .foregroundColor(.accentColor)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    AISuggestionsView()
        .padding()
} 