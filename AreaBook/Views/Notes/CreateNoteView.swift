import SwiftUI

struct CreateNoteView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var title = ""
    @State private var content = ""
    @State private var tags: [String] = []
    @State private var newTag = ""
    @State private var selectedGoalIds: Set<String> = []
    @State private var selectedTaskIds: Set<String> = []
    @State private var linkedNoteIds: Set<String> = []
    @State private var showingMarkdownPreview = false
    @State private var isMarkdownMode = false
    
    let noteToEdit: Note?
    
    init(noteToEdit: Note? = nil) {
        self.noteToEdit = noteToEdit
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Toolbar
                HStack {
                    Button(isMarkdownMode ? "Rich Text" : "Markdown") {
                        isMarkdownMode.toggle()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Button("Preview") {
                        showingMarkdownPreview = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .disabled(content.isEmpty)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Title Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Title")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            TextField("Note title", text: $title)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        // Content Section
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Content")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                if isMarkdownMode {
                                    Text("Markdown Mode")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(4)
                                }
                            }
                            
                            TextEditor(text: $content)
                                .frame(minHeight: 200)
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                        }
                        
                        // Tags Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Tags")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            // Add new tag
                            HStack {
                                TextField("Add tag", text: $newTag)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .onSubmit {
                                        addTag()
                                    }
                                
                                Button("Add") {
                                    addTag()
                                }
                                .disabled(newTag.isEmpty)
                            }
                            
                            // Existing tags
                            if !tags.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack {
                                        ForEach(tags, id: \.self) { tag in
                                            TagChip(tag: tag) {
                                                tags.removeAll { $0 == tag }
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 1)
                                }
                            }
                        }
                        
                        // Link to Goals Section
                        if !dataManager.goals.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Link to Goals")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                                    ForEach(dataManager.goals.filter { $0.status == .active }) { goal in
                                        LinkableItemCard(
                                            title: goal.title,
                                            subtitle: "Goal",
                                            icon: "flag",
                                            color: .blue,
                                            isSelected: selectedGoalIds.contains(goal.id)
                                        ) {
                                            toggleSelection(id: goal.id, in: &selectedGoalIds)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Link to Tasks Section
                        if !dataManager.tasks.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Link to Tasks")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                                    ForEach(dataManager.tasks.filter { $0.status != .completed }) { task in
                                        LinkableItemCard(
                                            title: task.title,
                                            subtitle: "Task",
                                            icon: "checkmark.square",
                                            color: .green,
                                            isSelected: selectedTaskIds.contains(task.id)
                                        ) {
                                            toggleSelection(id: task.id, in: &selectedTaskIds)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Link to Other Notes Section
                        let otherNotes = dataManager.notes.filter { $0.id != noteToEdit?.id }
                        if !otherNotes.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Link to Other Notes")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                                    ForEach(otherNotes) { note in
                                        LinkableItemCard(
                                            title: note.title.isEmpty ? "Untitled Note" : note.title,
                                            subtitle: "Note",
                                            icon: "doc.text",
                                            color: .purple,
                                            isSelected: linkedNoteIds.contains(note.id)
                                        ) {
                                            toggleSelection(id: note.id, in: &linkedNoteIds)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(noteToEdit == nil ? "New Note" : "Edit Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveNote()
                    }
                    .disabled(title.isEmpty && content.isEmpty)
                }
            }
            .onAppear {
                loadNoteData()
            }
            .sheet(isPresented: $showingMarkdownPreview) {
                MarkdownPreviewView(content: content, title: title)
            }
        }
    }
    
    private func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTag.isEmpty && !tags.contains(trimmedTag) {
            tags.append(trimmedTag)
            newTag = ""
        }
    }
    
    private func toggleSelection(id: String, in set: inout Set<String>) {
        if set.contains(id) {
            set.remove(id)
        } else {
            set.insert(id)
        }
    }
    
    private func loadNoteData() {
        guard let note = noteToEdit else { return }
        title = note.title
        content = note.content
        tags = note.tags
        selectedGoalIds = Set(note.linkedGoalIds)
        selectedTaskIds = Set(note.linkedTaskIds)
        linkedNoteIds = Set(note.linkedNoteIds)
    }
    
    private func saveNote() {
        guard let userId = authViewModel.currentUser?.id else { return }
        
        let note: Note
        if let existingNote = noteToEdit {
            note = Note(
                id: existingNote.id,
                title: title,
                content: content,
                tags: tags,
                linkedGoalIds: Array(selectedGoalIds),
                linkedTaskIds: Array(selectedTaskIds),
                linkedNoteIds: Array(linkedNoteIds),
                createdAt: existingNote.createdAt,
                updatedAt: Date()
            )
        } else {
            note = Note(
                title: title,
                content: content,
                tags: tags,
                linkedGoalIds: Array(selectedGoalIds),
                linkedTaskIds: Array(selectedTaskIds),
                linkedNoteIds: Array(linkedNoteIds)
            )
        }
        
        if noteToEdit != nil {
            dataManager.updateNote(note, userId: userId)
        } else {
            dataManager.createNote(note, userId: userId)
        }
        
        // Log note creation/update to linked goals
        for goalId in selectedGoalIds {
            dataManager.logNoteAdded(note: note, goalId: goalId, userId: userId)
        }
        
        dismiss()
    }
}

struct TagChip: View {
    let tag: String
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text("#\(tag)")
                .font(.caption)
                .foregroundColor(.blue)
            
            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(6)
    }
}

struct LinkableItemCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.caption)
                    
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .green : .gray)
                        .font(.caption)
                }
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.primary)
            }
            .padding(8)
            .background(isSelected ? color.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MarkdownPreviewView: View {
    let content: String
    let title: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if !title.isEmpty {
                        Text(title)
                            .font(.title)
                            .fontWeight(.bold)
                    }
                    
                    // Simple markdown rendering
                    Text(renderMarkdown(content))
                        .font(.body)
                }
                .padding()
            }
            .navigationTitle("Preview")
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
    
    private func renderMarkdown(_ text: String) -> String {
        // Simple markdown rendering - you can enhance this with a proper markdown library
        var rendered = text
        
        // Bold text
        rendered = rendered.replacingOccurrences(of: "**", with: "")
        
        // Italic text
        rendered = rendered.replacingOccurrences(of: "*", with: "")
        
        // Headers
        rendered = rendered.replacingOccurrences(of: "# ", with: "")
        rendered = rendered.replacingOccurrences(of: "## ", with: "")
        rendered = rendered.replacingOccurrences(of: "### ", with: "")
        
        return rendered
    }
}

#Preview {
    CreateNoteView()
        .environmentObject(DataManager.shared)
        .environmentObject(AuthViewModel())
}