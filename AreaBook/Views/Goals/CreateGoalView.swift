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
    
    // Progress tracking fields
    @State private var targetValue: Int = 1
    @State private var progressUnit: String = "events"
    
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
                    
                    // Progress Tracking Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Progress Tracking")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 12) {
                            HStack {
                                Text("Target Value:")
                                    .font(.subheadline)
                                Spacer()
                                Stepper("\(targetValue)", value: $targetValue, in: 1...999)
                                    .labelsHidden()
                            }
                            
                            HStack {
                                Text("Progress Unit:")
                                    .font(.subheadline)
                                Spacer()
                                Menu {
                                    Button("events") { progressUnit = "events" }
                                    Button("tasks") { progressUnit = "tasks" }
                                    Button("sessions") { progressUnit = "sessions" }
                                    Button("activities") { progressUnit = "activities" }
                                    Button("milestones") { progressUnit = "milestones" }
                                } label: {
                                    HStack {
                                        Text(progressUnit)
                                        Image(systemName: "chevron.down")
                                    }
                                    .foregroundColor(.blue)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    
                    // Key Indicators Section
                    if !dataManager.keyIndicators.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Link to Key Indicators")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                                ForEach(dataManager.keyIndicators) { ki in
                                    KISelectionCard(
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
        targetValue = goal.targetValue
        progressUnit = goal.progressUnit
    }
    
    private func saveGoal() {
        guard let userId = authViewModel.currentUser?.id else { return }
        
        var goal: Goal
        if let existingGoal = goalToEdit {
            goal = Goal(
                title: title,
                description: description,
                keyIndicatorIds: Array(selectedKIIds),
                targetDate: hasTargetDate ? targetDate : nil,
                targetValue: targetValue,
                progressUnit: progressUnit
            )
            goal.id = existingGoal.id
            goal.progress = existingGoal.progress
            goal.status = existingGoal.status
            goal.currentValue = existingGoal.currentValue
            goal.createdAt = existingGoal.createdAt
            goal.updatedAt = Date()
            goal.linkedNoteIds = existingGoal.linkedNoteIds
            goal.stickyNotes = stickyNotes
        } else {
            goal = Goal(
                title: title,
                description: description,
                keyIndicatorIds: Array(selectedKIIds),
                targetDate: hasTargetDate ? targetDate : nil,
                targetValue: targetValue,
                progressUnit: progressUnit
            )
            goal.stickyNotes = stickyNotes
        }
        
        if goalToEdit != nil {
            dataManager.updateGoal(goal, userId: userId)
        } else {
            dataManager.createGoal(goal, userId: userId)
        }
        
        dismiss()
    }
}

struct KISelectionCard: View {
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