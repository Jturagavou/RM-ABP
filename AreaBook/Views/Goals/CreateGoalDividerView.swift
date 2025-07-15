import SwiftUI

struct CreateGoalDividerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var name = ""
    @State private var selectedColor = "#3B82F6"
    @State private var selectedIcon = "folder.fill"
    
    let dividerToEdit: GoalDivider?
    
    private let availableColors = [
        "#3B82F6", "#10B981", "#F59E0B", "#EF4444",
        "#8B5CF6", "#EC4899", "#06B6D4", "#84CC16",
        "#F97316", "#6366F1", "#14B8A6", "#F43F5E"
    ]
    
    private let availableIcons = [
        "folder.fill", "star.fill", "heart.fill", "flag.fill",
        "target", "chart.bar.fill", "book.fill", "house.fill",
        "person.fill", "briefcase.fill", "gamecontroller.fill", "car.fill",
        "leaf.fill", "lightbulb.fill", "music.note", "camera.fill"
    ]
    
    init(dividerToEdit: GoalDivider? = nil) {
        self.dividerToEdit = dividerToEdit
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Category Details") {
                    TextField("Category Name", text: $name)
                        .textInputAutocapitalization(.words)
                }
                
                Section("Appearance") {
                    // Color Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Color")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                            ForEach(availableColors, id: \.self) { color in
                                Button(action: {
                                    selectedColor = color
                                }) {
                                    Circle()
                                        .fill(Color(hex: color))
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.primary, lineWidth: selectedColor == color ? 2 : 0)
                                        )
                                        .overlay(
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.white)
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .opacity(selectedColor == color ? 1 : 0)
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    
                    // Icon Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Icon")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
                            ForEach(availableIcons, id: \.self) { icon in
                                Button(action: {
                                    selectedIcon = icon
                                }) {
                                    Image(systemName: icon)
                                        .font(.title2)
                                        .foregroundColor(selectedIcon == icon ? Color(hex: selectedColor) : .secondary)
                                        .frame(width: 40, height: 40)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(selectedIcon == icon ? Color(hex: selectedColor).opacity(0.2) : Color.clear)
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
                
                Section("Preview") {
                    HStack {
                        Image(systemName: selectedIcon)
                            .foregroundColor(Color(hex: selectedColor))
                            .font(.title2)
                        
                        Text(name.isEmpty ? "Category Name" : name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: selectedColor))
                        
                        Spacer()
                        
                        Text("0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray5))
                            .cornerRadius(8)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                }
            }
            .navigationTitle(dividerToEdit == nil ? "New Category" : "Edit Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveDivider()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                loadDividerData()
            }
        }
    }
    
    private func loadDividerData() {
        guard let divider = dividerToEdit else { return }
        name = divider.name
        selectedColor = divider.color
        selectedIcon = divider.icon
    }
    
    private func saveDivider() {
        guard let userId = authViewModel.currentUser?.id else { return }
        
        let divider: GoalDivider
        if let existingDivider = dividerToEdit {
            divider = GoalDivider(
                id: existingDivider.id,
                name: name,
                color: selectedColor,
                icon: selectedIcon,
                sortOrder: existingDivider.sortOrder,
                createdAt: existingDivider.createdAt,
                updatedAt: Date()
            )
        } else {
            divider = GoalDivider(
                name: name,
                color: selectedColor,
                icon: selectedIcon
            )
            divider.sortOrder = dataManager.goalDividers.count
        }
        
        if dividerToEdit != nil {
            dataManager.updateGoalDivider(divider, userId: userId)
        } else {
            dataManager.createGoalDivider(divider, userId: userId)
        }
        
        dismiss()
    }
}

// Extension for GoalDivider to support custom init
extension GoalDivider {
    init(id: String, name: String, color: String, icon: String, sortOrder: Int, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.name = name
        self.color = color
        self.icon = icon
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

#Preview {
    CreateGoalDividerView()
        .environmentObject(DataManager.shared)
        .environmentObject(AuthViewModel())
}