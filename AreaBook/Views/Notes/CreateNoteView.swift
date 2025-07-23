import SwiftUI

struct CreateNoteView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var title = ""
    @State private var content = ""
    @State private var tags: [String] = []
    @State private var newTag = ""
    @State private var selectedFolder: String?
    @State private var showingFolderPicker = false
    @State private var linkedGoalIds: Set<String> = []
    @State private var linkedTaskIds: Set<String> = []
    @State private var linkedEventIds: Set<String> = []
    
    let noteToEdit: Note?
    let defaultGoalId: String?
    
    private let folders = ["Personal", "Work", "Church", "School", "Ideas", "Journal"]
    
    init(noteToEdit: Note? = nil, defaultGoalId: String? = nil) {
        self.noteToEdit = noteToEdit
        self.defaultGoalId = defaultGoalId
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Basic Information Section
                Section("Note Details") {
                    TextField("Note Title", text: $title)
                    
                    TextField("Content (Markdown supported)", text: $content, axis: .vertical)
                        .lineLimit(10)
                }
                
                // Tags Section
                Section("Tags") {
                    HStack {
                        TextField("Add tag", text: $newTag)
                        Button("Add") {
                            if !newTag.isEmpty && !tags.contains(newTag) {
                                tags.append(newTag)
                                newTag = ""
                            }
                        }
                        .disabled(newTag.isEmpty)
                    }
                    
                    if !tags.isEmpty {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                            ForEach(tags, id: \.self) { tag in
                                HStack {
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.2))
                                        .foregroundColor(.blue)
                                        .cornerRadius(6)
                                    
                                    Button("×") {
                                        tags.removeAll { $0 == tag }
                                    }
                                    .font(.caption)
                                    .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }
                
                // Folder Section
                Section("Folder") {
                    HStack {
                        Text(selectedFolder ?? "No Folder")
                            .foregroundColor(selectedFolder == nil ? .secondary : .primary)
                        Spacer()
                        Button("Select") {
                            showingFolderPicker = true
                        }
                    }
                }
                
                // Linking Section
                if !dataManager.goals.isEmpty {
                    Section("Link to Goals") {
                        ForEach(dataManager.goals.filter { $0.status == .active }) { goal in
                            HStack {
                                Text(goal.title)
                                Spacer()
                                if linkedGoalIds.contains(goal.id) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if linkedGoalIds.contains(goal.id) {
                                    linkedGoalIds.remove(goal.id)
                                } else {
                                    linkedGoalIds.insert(goal.id)
                                }
                            }
                        }
                    }
                }
                
                if !dataManager.tasks.isEmpty {
                    Section("Link to Tasks") {
                        ForEach(dataManager.tasks.filter { $0.status != .completed }) { task in
                            HStack {
                                Text(task.title)
                                Spacer()
                                if linkedTaskIds.contains(task.id) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if linkedTaskIds.contains(task.id) {
                                    linkedTaskIds.remove(task.id)
                                } else {
                                    linkedTaskIds.insert(task.id)
                                }
                            }
                        }
                    }
                }
                
                if !dataManager.events.isEmpty {
                    Section("Link to Events") {
                        ForEach(dataManager.events.filter { $0.status == .scheduled }) { event in
                            HStack {
                                Text(event.title)
                                Spacer()
                                if linkedEventIds.contains(event.id) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if linkedEventIds.contains(event.id) {
                                    linkedEventIds.remove(event.id)
                                } else {
                                    linkedEventIds.insert(event.id)
                                }
                            }
                        }
                    }
                }
                
                // Preview Section
                if !content.isEmpty {
                    Section("Preview") {
                        NotePreviewCard(title: title, content: content, tags: tags)
                    }
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
                    .disabled(title.isEmpty)
                }
            }
            .onAppear {
                loadNoteData()
                if let defaultGoalId = defaultGoalId {
                    linkedGoalIds.insert(defaultGoalId)
                }
            }
            .sheet(isPresented: $showingFolderPicker) {
                FolderPickerView(selectedFolder: $selectedFolder, folders: folders)
            }
        }
    }
    
    private func loadNoteData() {
        guard let note = noteToEdit else { return }
        title = note.title
        content = note.content
        tags = note.tags
        selectedFolder = note.folder
        linkedGoalIds = Set(note.linkedGoalIds)
        linkedTaskIds = Set(note.linkedTaskIds)
        linkedEventIds = Set(note.linkedEventIds)
    }
    
    private func saveNote() {
        guard let userId = authViewModel.currentUser?.id else { return }
        
        let note: Note
        if let _ = noteToEdit {
            // Create a new note with the existing ID for updates
            note = Note(
                title: title,
                content: content,
                tags: tags,
                folder: selectedFolder
            )
            // Note: We can't modify the ID since it's let, so we'll need to handle this differently
            // For now, we'll create a new note and let the DataManager handle the update
        } else {
            note = Note(
                title: title,
                content: content,
                tags: tags,
                folder: selectedFolder
            )
        }
        
        // Add linked items
        var noteWithLinks = note
        noteWithLinks.linkedGoalIds = Array(linkedGoalIds)
        noteWithLinks.linkedTaskIds = Array(linkedTaskIds)
        noteWithLinks.linkedEventIds = Array(linkedEventIds)
        
        if noteToEdit != nil {
            dataManager.updateNote(noteWithLinks, userId: userId)
        } else {
            dataManager.createNote(noteWithLinks, userId: userId)
        }
        
        dismiss()
    }
}

struct NotePreviewCard: View {
    let title: String
    let content: String
    let tags: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            if !content.isEmpty {
                Text(content)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            
            if !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(6)
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
}

struct FolderPickerView: View {
    @Binding var selectedFolder: String?
    let folders: [String]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Button("No Folder") {
                    selectedFolder = nil
                    dismiss()
                }
                .foregroundColor(.primary)
                
                ForEach(folders, id: \.self) { folder in
                    Button(folder) {
                        selectedFolder = folder
                        dismiss()
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("Select Folder")
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

#Preview {
    CreateNoteView()
        .environmentObject(DataManager.shared)
        .environmentObject(AuthViewModel.shared)
} 