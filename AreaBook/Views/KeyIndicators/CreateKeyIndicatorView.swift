import SwiftUI

struct CreateKeyIndicatorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var name = ""
    @State private var weeklyTarget = ""
    @State private var unit = ""
    @State private var selectedColor = "#3B82F6"
    @State private var showingColorPicker = false
    @State private var currentProgress = ""
    
    let keyIndicatorToEdit: KeyIndicator?
    
    private let predefinedColors = [
        "#3B82F6", "#10B981", "#8B5CF6", "#F59E0B",
        "#EF4444", "#06B6D4", "#84CC16", "#F97316",
        "#EC4899", "#6366F1", "#14B8A6", "#F59E0B"
    ]
    
    private let commonKIs = [
        ("Exercise", "sessions", "#84CC16"),
        ("Reading", "books", "#3B82F6"),
        ("Water Intake", "glasses", "#06B6D4"),
        ("Sleep Hours", "hours", "#8B5CF6"),
        ("Meditation", "minutes", "#10B981"),
        ("Learning", "hours", "#F59E0B"),
        ("Social Time", "hours", "#EC4899"),
        ("Creative Work", "hours", "#F97316")
    ]
    
    init(keyIndicatorToEdit: KeyIndicator? = nil) {
        self.keyIndicatorToEdit = keyIndicatorToEdit
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Quick Templates
                    if keyIndicatorToEdit == nil {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Quick Templates")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                                ForEach(commonKIs, id: \.0) { kiTemplate in
                                    Button(action: {
                                        name = kiTemplate.0
                                        unit = kiTemplate.1
                                        selectedColor = kiTemplate.2
                                        weeklyTarget = "7" // Default target
                                    }) {
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack {
                                                Circle()
                                                    .fill(Color(hex: kiTemplate.2) ?? .blue)
                                                    .frame(width: 12, height: 12)
                                                Text(kiTemplate.0)
                                                    .font(.subheadline)
                                                    .fontWeight(.medium)
                                                    .lineLimit(1)
                                                Spacer()
                                            }
                                            Text(kiTemplate.1)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(12)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }
                    
                    // Custom KI Form
                    VStack(alignment: .leading, spacing: 16) {
                        Text(keyIndicatorToEdit == nil ? "Create Custom KI" : "Edit Key Indicator")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 16) {
                            // Name Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Name")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                TextField("e.g., Scripture Study", text: $name)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            // Weekly Target Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Weekly Target")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                TextField("e.g., 7", text: $weeklyTarget)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.numberPad)
                            }
                            
                            // Unit Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Unit")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                TextField("e.g., sessions, times, hours", text: $unit)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            // Current Progress (for editing)
                            if keyIndicatorToEdit != nil {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Current Week Progress")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    TextField("Current progress", text: $currentProgress)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .keyboardType(.numberPad)
                                }
                            }
                            
                            // Color Selection
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Color")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                                    ForEach(predefinedColors, id: \.self) { colorHex in
                                        Circle()
                                            .fill(Color(hex: colorHex) ?? .blue)
                                            .frame(width: 40, height: 40)
                                            .overlay(
                                                Circle()
                                                    .stroke(selectedColor == colorHex ? Color.black : Color.clear, lineWidth: 3)
                                            )
                                            .onTapGesture {
                                                selectedColor = colorHex
                                            }
                                    }
                                }
                                
                                Button("Custom Color") {
                                    showingColorPicker = true
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    // Preview Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Preview")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if !name.isEmpty && !weeklyTarget.isEmpty && !unit.isEmpty {
                            KIPreviewCard(
                                name: name,
                                weeklyTarget: Int(weeklyTarget) ?? 0,
                                currentProgress: Int(currentProgress) ?? 0,
                                unit: unit,
                                color: selectedColor
                            )
                        } else {
                            Text("Fill in the fields above to see a preview")
                                .font(.subheadline)
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
            .navigationTitle(keyIndicatorToEdit == nil ? "New Key Indicator" : "Edit Key Indicator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveKeyIndicator()
                    }
                    .disabled(!isFormValid)
                }
            }
            .onAppear {
                loadKeyIndicatorData()
            }
            .sheet(isPresented: $showingColorPicker) {
                ColorPickerView(selectedColor: $selectedColor)
            }
        }
    }
    
    private var isFormValid: Bool {
        !name.isEmpty && 
        !weeklyTarget.isEmpty && 
        Int(weeklyTarget) != nil && 
        Int(weeklyTarget)! > 0 && 
        !unit.isEmpty
    }
    
    private func loadKeyIndicatorData() {
        guard let ki = keyIndicatorToEdit else { return }
        name = ki.name
        weeklyTarget = String(ki.weeklyTarget)
        unit = ki.unit
        selectedColor = ki.color
        currentProgress = String(ki.currentWeekProgress)
    }
    
    private func saveKeyIndicator() {
        guard let userId = authViewModel.currentUser?.id else { return }
        
        let targetValue = Int(weeklyTarget) ?? 0
        let progressValue = Int(currentProgress) ?? 0
        
        let keyIndicator: KeyIndicator
        if let existingKI = keyIndicatorToEdit {
            keyIndicator = KeyIndicator(
                id: existingKI.id,
                name: name,
                weeklyTarget: targetValue,
                currentWeekProgress: progressValue,
                unit: unit,
                color: selectedColor,
                createdAt: existingKI.createdAt,
                updatedAt: Date()
            )
        } else {
            keyIndicator = KeyIndicator(
                name: name,
                weeklyTarget: targetValue,
                unit: unit,
                color: selectedColor
            )
        }
        
        if keyIndicatorToEdit != nil {
            dataManager.updateKeyIndicator(keyIndicator, userId: userId)
        } else {
            dataManager.createKeyIndicator(keyIndicator, userId: userId)
        }
        
        dismiss()
    }
}

struct KIPreviewCard: View {
    let name: String
    let weeklyTarget: Int
    let currentProgress: Int
    let unit: String
    let color: String
    
    private var progressPercentage: Double {
        guard weeklyTarget > 0 else { return 0 }
        return min(Double(currentProgress) / Double(weeklyTarget), 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(Color(hex: color) ?? .blue)
                    .frame(width: 12, height: 12)
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(currentProgress)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("/ \(weeklyTarget)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(progressPercentage * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Color(hex: color) ?? .blue)
                }
                
                ProgressView(value: progressPercentage)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: color) ?? .blue))
                
                Text("\(unit) this week")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
}

struct ColorPickerView: View {
    @Binding var selectedColor: String
    @Environment(\.dismiss) private var dismiss
    @State private var customColor = Color.blue
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                ColorPicker("Choose Custom Color", selection: $customColor)
                    .onChange(of: customColor) { newColor in
                        selectedColor = newColor.toHex()
                    }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Custom Color")
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
                }
            }
        }
    }
}

// MARK: - Key Indicators Management View
struct KeyIndicatorsManagementView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingCreateKI = false
    @State private var kiToEdit: KeyIndicator?
    @State private var showingDeleteAlert = false
    @State private var kiToDelete: KeyIndicator?
    
    var body: some View {
        NavigationView {
            List {
                if dataManager.keyIndicators.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "chart.bar")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Key Indicators")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Create your first Key Indicator to start tracking your spiritual progress")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Create Key Indicator") {
                            showingCreateKI = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 50)
                    .listRowBackground(Color.clear)
                } else {
                    Section("Current Key Indicators") {
                        ForEach(dataManager.keyIndicators) { ki in
                            KeyIndicatorRow(
                                keyIndicator: ki,
                                onEdit: {
                                    kiToEdit = ki
                                },
                                onDelete: {
                                    kiToDelete = ki
                                    showingDeleteAlert = true
                                },
                                onProgressUpdate: { newProgress in
                                    updateKIProgress(ki, newProgress: newProgress)
                                }
                            )
                        }
                    }
                    
                    Section("Quick Actions") {
                        Button(action: {
                            resetAllProgress()
                        }) {
                            Label("Reset Weekly Progress", systemImage: "arrow.clockwise")
                                .foregroundColor(.orange)
                        }
                        
                        Button(action: {
                            showingCreateKI = true
                        }) {
                            Label("Add New Key Indicator", systemImage: "plus.circle")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Key Indicators")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        showingCreateKI = true
                    }
                }
            }
            .sheet(isPresented: $showingCreateKI) {
                CreateKeyIndicatorView()
            }
            .sheet(item: $kiToEdit) { ki in
                CreateKeyIndicatorView(keyIndicatorToEdit: ki)
            }
            .alert("Delete Key Indicator", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    if let ki = kiToDelete {
                        deleteKeyIndicator(ki)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This action cannot be undone. All linked goals will be updated.")
            }
        }
    }
    
    private func updateKIProgress(_ ki: KeyIndicator, newProgress: Int) {
        guard let userId = authViewModel.currentUser?.id else { return }
        
        var updatedKI = ki
        updatedKI.currentWeekProgress = newProgress
        updatedKI.updatedAt = Date()
        
        dataManager.updateKeyIndicator(updatedKI, userId: userId)
    }
    
    private func deleteKeyIndicator(_ ki: KeyIndicator) {
        guard let userId = authViewModel.currentUser?.id else { return }
        dataManager.deleteKeyIndicator(ki, userId: userId)
    }
    
    private func resetAllProgress() {
        guard let userId = authViewModel.currentUser?.id else { return }
        
        for ki in dataManager.keyIndicators {
            var resetKI = ki
            resetKI.currentWeekProgress = 0
            resetKI.updatedAt = Date()
            dataManager.updateKeyIndicator(resetKI, userId: userId)
        }
    }
}

struct KeyIndicatorRow: View {
    let keyIndicator: KeyIndicator
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onProgressUpdate: (Int) -> Void
    
    @State private var showingProgressSheet = false
    @State private var newProgress = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(Color(hex: keyIndicator.color) ?? .blue)
                    .frame(width: 16, height: 16)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(keyIndicator.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Target: \(keyIndicator.weeklyTarget) \(keyIndicator.unit) per week")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Menu {
                    Button("Edit", action: onEdit)
                    Button("Update Progress") {
                        newProgress = String(keyIndicator.currentWeekProgress)
                        showingProgressSheet = true
                    }
                    Button("Delete", role: .destructive, action: onDelete)
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.gray)
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("\(keyIndicator.currentWeekProgress)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("/ \(keyIndicator.weeklyTarget)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(keyIndicator.progressPercentage * 100))%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: keyIndicator.color) ?? .blue)
                }
                
                ProgressView(value: keyIndicator.progressPercentage)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: keyIndicator.color) ?? .blue))
            }
            
            // Quick increment buttons
            HStack {
                Button("+1") {
                    onProgressUpdate(keyIndicator.currentWeekProgress + 1)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button("+5") {
                    onProgressUpdate(keyIndicator.currentWeekProgress + 5)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Spacer()
                
                Text("Last updated: \(keyIndicator.updatedAt, style: .relative)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .sheet(isPresented: $showingProgressSheet) {
            ProgressUpdateSheet(
                keyIndicator: keyIndicator,
                currentProgress: $newProgress,
                onSave: { progress in
                    onProgressUpdate(progress)
                }
            )
        }
    }
}

struct ProgressUpdateSheet: View {
    let keyIndicator: KeyIndicator
    @Binding var currentProgress: String
    let onSave: (Int) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Update Progress")
                        .font(.headline)
                    
                    Text("Current progress for \(keyIndicator.name)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                TextField("Progress", text: $currentProgress)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .font(.title2)
                
                Text("Target: \(keyIndicator.weeklyTarget) \(keyIndicator.unit)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Update Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if let progress = Int(currentProgress) {
                            onSave(progress)
                        }
                        dismiss()
                    }
                    .disabled(Int(currentProgress) == nil)
                }
            }
        }
    }
}

// MARK: - Extensions
extension Color {
    func toHex() -> String {
        guard let components = cgColor?.components, components.count >= 3 else {
            return "#000000"
        }
        
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        
        return String(format: "#%02lX%02lX%02lX",
                     lroundf(r * 255),
                     lroundf(g * 255),
                     lroundf(b * 255))
    }
}

#Preview {
    CreateKeyIndicatorView()
        .environmentObject(DataManager.shared)
        .environmentObject(AuthViewModel())
}