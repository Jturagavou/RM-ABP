import SwiftUI
import Firebase
import FirebaseFirestore

struct NotesView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                SearchBar(text: $searchText)
                
                // Notes List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        let filteredNotes = getFilteredNotes()
                        
                        if filteredNotes.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray)
                                
                                Text("No Notes")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                Text(searchText.isEmpty ? "Create your first note to capture thoughts and ideas" : "No notes found matching your search")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, 100)
                        } else {
                            ForEach(filteredNotes) { note in
                                NoteCard(note: note)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Notes")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private func getFilteredNotes() -> [Note] {
        let notes = dataManager.notes
        
        if searchText.isEmpty {
            return notes.sorted { $0.updatedAt > $1.updatedAt }
        } else {
            return notes.filter { note in
                note.title.localizedCaseInsensitiveContains(searchText) ||
                note.content.localizedCaseInsensitiveContains(searchText) ||
                note.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }.sorted { $0.updatedAt > $1.updatedAt }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search notes...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button("Clear") {
                    text = ""
                }
                .foregroundColor(.blue)
                .font(.caption)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

struct NoteCard: View {
    let note: Note
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(note.title.isEmpty ? "Untitled Note" : note.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                Spacer()
                
                Text(note.updatedAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if !note.content.isEmpty {
                Text(note.content)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            
            if !note.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(note.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(6)
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
            
            if !note.linkedGoalIds.isEmpty || !note.linkedTaskIds.isEmpty {
                HStack {
                    if !note.linkedGoalIds.isEmpty {
                        Label("\(note.linkedGoalIds.count) Goals", systemImage: "flag")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    
                    if !note.linkedTaskIds.isEmpty {
                        Label("\(note.linkedTaskIds.count) Tasks", systemImage: "checkmark.square")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    NotesView()
        .environmentObject(DataManager.shared)
        .environmentObject(AuthViewModel())
}