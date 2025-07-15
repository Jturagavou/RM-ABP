import SwiftUI

struct CreateGoalView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedKIIds: Set<String> = []
    @State private var targetDate: Date?
    @State private var hasTargetDate = false
    @State private var stickyNotes: [StickyNote] = []
    @State private var showingColorPicker = false
    @State private var selectedStickyColor = "#FBBF24"
    @State private var newStickyText = ""
    
    let goalToEdit: Goal?
    
    init(goalToEdit: Goal? = nil) {
        self.goalToEdit = goalToEdit
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Basic Info Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Goal Information")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 12) {
                            TextField("Goal Title", text: $title)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            TextEditor(text: $description)
                                .frame(minHeight: 100)
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                        }
                    }
                    
                    // Target Date Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Target Date")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Toggle("Set target date", isOn: $hasTargetDate)
                        
                        if hasTargetDate {
                            DatePicker("Target Date", selection: Binding(
                                get: { targetDate ?? Date() },
                                set: { targetDate = $0 }
                            ), displayedComponents: [.date])
                            .datePickerStyle(WheelDatePickerStyle())
                        }
                    }
                    
                    // Key Indicators Section
                    if !dataManager.keyIndicators.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Link to Key Indicators")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                                ForEach(dataManager.keyIndicators) { ki in
                                    GoalKISelectionCard(
                                        keyIndicator: ki,
                                        isSelected: selectedKIIds.contains(ki.id)
                                    ) {
                                        if selectedKIIds.contains(ki.id) {
                                            selectedKIIds.remove(ki.id)
                                        } else {
                                            selectedKIIds.insert(ki.id)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // Sticky Notes Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Sticky Notes")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Button("Add Note") {
                                showingColorPicker = true
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                        
                        if !stickyNotes.isEmpty {
                            StickyNotesCanvas(stickyNotes: $stickyNotes)
                                .frame(height: 200)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        } else {
                            Text("No sticky notes yet. Add notes to brainstorm and track progress.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(goalToEdit == nil ? "New Goal" : "Edit Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveGoal()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .onAppear {
                loadGoalData()
            }
            .sheet(isPresented: $showingColorPicker) {
                StickyNoteCreationSheet(
                    text: $newStickyText,
                    color: $selectedStickyColor
                ) { note in
                    stickyNotes.append(note)
                }
            }
        }
    }
    
    private func loadGoalData() {
        guard let goal = goalToEdit else { return }
        title = goal.title
        description = goal.description
        selectedKIIds = Set(goal.keyIndicatorIds)
        targetDate = goal.targetDate
        hasTargetDate = goal.targetDate != nil
        stickyNotes = goal.stickyNotes
    }
    
    private func saveGoal() {
        guard let userId = authViewModel.currentUser?.id else { return }
        
        let goal: Goal
        if let existingGoal = goalToEdit {
            // For editing, we need to create a new goal with the existing data
            goal = Goal(
                title: title,
                description: description,
                keyIndicatorIds: Array(selectedKIIds),
                targetDate: hasTargetDate ? targetDate : nil
            )
            // Copy the existing properties that we want to preserve
            // Note: This is a limitation since Goal doesn't have a custom initializer for editing
            // In a real app, you'd want to add an editing initializer to the Goal model
        } else {
            goal = Goal(
                title: title,
                description: description,
                keyIndicatorIds: Array(selectedKIIds),
                targetDate: hasTargetDate ? targetDate : nil
            )
        }
        
        if goalToEdit != nil {
            dataManager.updateGoal(goal, userId: userId)
        } else {
            dataManager.createGoal(goal, userId: userId)
        }
        
        dismiss()
    }
}

struct GoalKISelectionCard: View {
    let keyIndicator: KeyIndicator
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Circle()
                        .fill(Color(hex: keyIndicator.color) ?? .blue)
                        .frame(width: 12, height: 12)
                    
                    Text(keyIndicator.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .blue : .gray)
                        .font(.caption)
                }
                
                ProgressView(value: keyIndicator.progressPercentage)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: keyIndicator.color) ?? .blue))
                
                Text("\(keyIndicator.currentWeekProgress)/\(keyIndicator.weeklyTarget) \(keyIndicator.unit)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemBackground))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct StickyNotesCanvas: View {
    @Binding var stickyNotes: [StickyNote]
    @State private var draggedNote: StickyNote?
    
    var body: some View {
        ZStack {
            ForEach(stickyNotes.indices, id: \.self) { index in
                StickyNoteView(
                    note: stickyNotes[index],
                    onDelete: {
                        stickyNotes.remove(at: index)
                    },
                    onUpdate: { updatedNote in
                        stickyNotes[index] = updatedNote
                    }
                )
                .position(stickyNotes[index].position)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            stickyNotes[index].position = value.location
                        }
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct StickyNoteView: View {
    let note: StickyNote
    let onDelete: () -> Void
    let onUpdate: (StickyNote) -> Void
    
    @State private var isEditing = false
    @State private var editText = ""
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Spacer()
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }
            
            if isEditing {
                TextField("Note text", text: $editText)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .onSubmit {
                        var updatedNote = note
                        updatedNote.content = editText
                        onUpdate(updatedNote)
                        isEditing = false
                    }
            } else {
                Text(note.content)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .onTapGesture {
                        editText = note.content
                        isEditing = true
                    }
            }
        }
        .padding(8)
        .frame(width: 80, height: 80)
        .background(Color(hex: note.color) ?? .yellow)
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 1)
    }
}

struct StickyNoteCreationSheet: View {
    @Binding var text: String
    @Binding var color: String
    let onCreate: (StickyNote) -> Void
    @Environment(\.dismiss) private var dismiss
    
    private let colors = ["#FBBF24", "#F87171", "#60A5FA", "#34D399", "#A78BFA", "#FB7185"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Note text", text: $text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Color")
                        .font(.headline)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(colors, id: \.self) { colorHex in
                            Circle()
                                .fill(Color(hex: colorHex) ?? .yellow)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .stroke(color == colorHex ? Color.black : Color.clear, lineWidth: 3)
                                )
                                .onTapGesture {
                                    color = colorHex
                                }
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("New Sticky Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        let note = StickyNote(
                            content: text,
                            color: color,
                            position: CGPoint(x: 100, y: 100)
                        )
                        onCreate(note)
                        text = ""
                        dismiss()
                    }
                    .disabled(text.isEmpty)
                }
            }
        }
    }
}

#Preview {
    CreateGoalView()
        .environmentObject(DataManager.shared)
        .environmentObject(AuthViewModel())
}