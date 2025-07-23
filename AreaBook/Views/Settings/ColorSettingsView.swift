import SwiftUI

struct ColorSettingsView: View {
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingColorPicker = false
    @State private var selectedColorType: ColorType = .primary
    @State private var showingAddCategory = false
    
    enum ColorType {
        case primary, secondary, accent, background, cardBackground, text
        
        var title: String {
            switch self {
            case .primary: return "Primary Color"
            case .secondary: return "Secondary Color"
            case .accent: return "Accent Color"
            case .background: return "Background Color"
            case .cardBackground: return "Card Background"
            case .text: return "Text Color"
            }
        }
        
        var description: String {
            switch self {
            case .primary: return "Main app color for buttons and highlights"
            case .secondary: return "Secondary elements and backgrounds"
            case .accent: return "Accent color for special elements"
            case .background: return "Main app background color"
            case .cardBackground: return "Background for cards and content areas"
            case .text: return "Primary text color throughout the app"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: true) {
                mainContent
            }
            .navigationTitle("Color Settings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(false)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
        .sheet(isPresented: $showingColorPicker) {
            ThemeColorPickerView(
                colorType: selectedColorType,
                currentColor: getCurrentColor(),
                onColorSelected: { newColor in
                    updateColor(newColor)
                }
            )
        }
        .sheet(isPresented: $showingAddCategory) {
            AddCategoryView { newCategory in
                // TODO: Implement category addition when ColorThemeManager supports it
                print("Category added: \(newCategory.name)")
            }
        }
    }
    
    private var mainContent: some View {
        VStack(spacing: 24) {
            // App Colors Section
            VStack(alignment: .leading, spacing: 16) {
                Text("App Colors")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                colorGrid
                    .padding(.horizontal)
            }
            
            // Event Categories Section
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Event Categories")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                    Button("Add Category") {
                        showingAddCategory = true
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)
                
                LazyVStack(spacing: 8) {
                    // TODO: Add event categories when ColorThemeManager supports them
                    Text("No event categories yet")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                }
                .padding(.horizontal)
            }
            
            // Reset Button
            Button("Reset to Default Theme") {
                // Reset functionality
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .padding()
        }
        .padding(.vertical)
    }
    
    private var colorGrid: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ColorSettingCard(
                    title: "Primary",
                    description: "Main app color",
                    color: .blue,
                    hexValue: "#3B82F6"
                ) {
                    selectedColorType = .primary
                    showingColorPicker = true
                }
                
                ColorSettingCard(
                    title: "Secondary",
                    description: "Secondary elements",
                    color: .orange,
                    hexValue: "#F59E0B"
                ) {
                    selectedColorType = .secondary
                    showingColorPicker = true
                }
            }
            
            HStack(spacing: 12) {
                ColorSettingCard(
                    title: "Accent",
                    description: "Special elements",
                    color: .purple,
                    hexValue: "#8B5CF6"
                ) {
                    selectedColorType = .accent
                    showingColorPicker = true
                }
                
                ColorSettingCard(
                    title: "Background",
                    description: "App background",
                    color: Color(.systemBackground),
                    hexValue: "#FFFFFF"
                ) {
                    selectedColorType = .background
                    showingColorPicker = true
                }
            }
            
            HStack(spacing: 12) {
                ColorSettingCard(
                    title: "Card Background",
                    description: "Content areas",
                    color: Color(.secondarySystemBackground),
                    hexValue: "#F2F2F7"
                ) {
                    selectedColorType = .cardBackground
                    showingColorPicker = true
                }
                
                ColorSettingCard(
                    title: "Text",
                    description: "Primary text",
                    color: Color(.label),
                    hexValue: "#000000"
                ) {
                    selectedColorType = .text
                    showingColorPicker = true
                }
            }
        }
    }
    
    private func getCurrentColor() -> Color {
        switch selectedColorType {
        case .primary: return .blue
        case .secondary: return .orange
        case .accent: return .purple
        case .background: return Color(.systemBackground)
        case .cardBackground: return Color(.secondarySystemBackground)
        case .text: return Color(.label)
        }
    }
    
    private func updateColor(_ color: Color) {
        // Implementation would update the theme
    }
}

struct ColorSettingCard: View {
    let title: String
    let description: String
    let color: Color
    let hexValue: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Circle()
                        .fill(color)
                        .frame(width: 20, height: 20)
                    
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(hexValue)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CategoryRow: View {
    let category: EventCategory
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color(hex: category.color) ?? .blue)
                .frame(width: 16, height: 16)
            
            Text(category.name)
                .font(.body)
            
            Spacer()
            
            Button("Edit") {
                onEdit()
            }
            .font(.caption)
            .foregroundColor(.blue)
            
            Button("Delete") {
                onDelete()
            }
            .font(.caption)
            .foregroundColor(.red)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
    }
}

struct ThemeColorPickerView: View {
    let colorType: ColorSettingsView.ColorType
    let currentColor: Color
    let onColorSelected: (Color) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedColor: Color
    
    init(colorType: ColorSettingsView.ColorType, currentColor: Color, onColorSelected: @escaping (Color) -> Void) {
        self.colorType = colorType
        self.currentColor = currentColor
        self.onColorSelected = onColorSelected
        self._selectedColor = State(initialValue: currentColor)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text(colorType.title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(colorType.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                ColorPicker("Select Color", selection: $selectedColor)
                    .labelsHidden()
                    .scaleEffect(1.5)
                
                // Preview
                VStack(spacing: 8) {
                    Text("Preview")
                        .font(.headline)
                    
                    RoundedRectangle(cornerRadius: 12)
                        .fill(selectedColor)
                        .frame(height: 60)
                        .overlay(
                            Text("Sample Text")
                                .foregroundColor(.white)
                                .font(.headline)
                        )
                }
                .padding()
                
                Spacer()
            }
            .padding()
            .navigationTitle("Color Picker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        onColorSelected(selectedColor)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AddCategoryView: View {
    let onSave: (EventCategory) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var selectedColor = Color.blue
    
    var body: some View {
        NavigationView {
            Form {
                Section("Category Details") {
                    TextField("Category Name", text: $name)
                    
                    ColorPicker("Category Color", selection: $selectedColor)
                }
                
                Section("Preview") {
                    HStack {
                        Circle()
                            .fill(selectedColor)
                            .frame(width: 16, height: 16)
                        Text(name.isEmpty ? "Category Name" : name)
                            .foregroundColor(.primary)
                    }
                }
            }
            .navigationTitle("Add Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let newCategory = EventCategory(
                            name: name,
                            color: "#0000FF",
                            icon: "circle"
                        )
                        onSave(newCategory)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

struct EditCategoryView: View {
    let category: EventCategory
    let onSave: (EventCategory) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var selectedColor: Color
    
    init(category: EventCategory, onSave: @escaping (EventCategory) -> Void) {
        self.category = category
        self.onSave = onSave
        self._name = State(initialValue: category.name)
        self._selectedColor = State(initialValue: Color(hex: category.color) ?? .blue)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Category Details") {
                    TextField("Category Name", text: $name)
                    
                    ColorPicker("Category Color", selection: $selectedColor)
                }
                
                Section("Preview") {
                    HStack {
                        Circle()
                            .fill(selectedColor)
                            .frame(width: 16, height: 16)
                        Text(name.isEmpty ? "Category Name" : name)
                            .foregroundColor(.primary)
                    }
                }
            }
            .navigationTitle("Edit Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let updatedCategory = EventCategory(
                            name: name,
                            color: "#0000FF",
                            icon: category.icon
                        )
                        onSave(updatedCategory)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
} 