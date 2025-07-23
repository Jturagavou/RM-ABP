import SwiftUI
import WidgetKit

struct WidgetSettingsView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedWidgetSize: WidgetSize = .medium
    @State private var selectedTheme: WidgetTheme = .system
    @State private var showKeyIndicators = true
    @State private var showTasks = true
    @State private var showEvents = true
    @State private var refreshInterval: RefreshInterval = .hourly
    @State private var showingAddWidget = false
    @State private var showingRemoveWidget = false
    @State private var selectedWidget: DashboardWidget?
    
    var body: some View {
            List {
            Section("Widget Configuration") {
                    VStack(alignment: .leading, spacing: 12) {
                    Text("Current Widgets")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                    
                    if let user = authViewModel.currentUser {
                        ForEach(user.settings.customWidgets) { widget in
                            WidgetConfigurationCard(
                                widget: widget,
                                onEdit: { selectedWidget = widget },
                                onRemove: { showingRemoveWidget = true }
                            )
                        }
                        
                        if user.settings.customWidgets.isEmpty {
                            Text("No custom widgets configured")
                            .foregroundColor(.secondary)
                                .italic()
                        }
                    }
                    
                    Button(action: { showingAddWidget = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                            Text("Add New Widget")
                                .fontWeight(.medium)
                        }
                    }
                    .padding(.top, 8)
                }
            }
            
            Section("Default Widget Settings") {
                Picker("Widget Size", selection: $selectedWidgetSize) {
                    ForEach(WidgetSize.allCases, id: \.self) { size in
                        Text(size.displayName).tag(size)
                    }
                        }
                
                Picker("Theme", selection: $selectedTheme) {
                    ForEach(WidgetTheme.allCases, id: \.self) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
                
                Picker("Refresh Interval", selection: $refreshInterval) {
                    ForEach(RefreshInterval.allCases, id: \.self) { interval in
                        Text(interval.displayName).tag(interval)
                        }
                    }
            }
            
            Section("Data Display") {
                Toggle("Show Key Indicators", isOn: $showKeyIndicators)
                Toggle("Show Tasks", isOn: $showTasks)
                Toggle("Show Events", isOn: $showEvents)
            }
            
            Section("Widget Preview") {
                WidgetPreviewCard(
                    size: selectedWidgetSize,
                    theme: selectedTheme,
                    showKeyIndicators: showKeyIndicators,
                    showTasks: showTasks,
                    showEvents: showEvents
                )
                        }
            
            Section("Instructions") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("How to Add Widgets")
                        .font(.headline)
                    .fontWeight(.semibold)
                    
                    Text("1. Long press on your home screen")
                    Text("2. Tap the '+' button in the top left")
                    Text("3. Search for 'AreaBook'")
                    Text("4. Choose your preferred widget size")
                    Text("5. Tap 'Add Widget'")
                    
                    Text("Widgets will automatically update based on your settings.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                    }
                }
            }
            .navigationTitle("Widget Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadWidgetSettings()
        }
        .onChange(of: selectedWidgetSize) { _ in saveWidgetSettings() }
        .onChange(of: selectedTheme) { _ in saveWidgetSettings() }
        .onChange(of: refreshInterval) { _ in saveWidgetSettings() }
        .onChange(of: showKeyIndicators) { _ in saveWidgetSettings() }
        .onChange(of: showTasks) { _ in saveWidgetSettings() }
        .onChange(of: showEvents) { _ in saveWidgetSettings() }
        .sheet(isPresented: $showingAddWidget) {
            AddWidgetView { newWidget in
                addCustomWidget(newWidget)
        }
    }
        .alert("Remove Widget", isPresented: $showingRemoveWidget) {
            Button("Remove", role: .destructive) {
                if let widget = selectedWidget {
                    removeCustomWidget(widget)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to remove this widget? This will also remove it from your home screen.")
        }
    }
    
    private func loadWidgetSettings() {
        guard let user = authViewModel.currentUser else { return }
        
        // Load settings from user preferences
        selectedWidgetSize = user.settings.widgetSize ?? .medium
        selectedTheme = user.settings.widgetTheme ?? .system
        refreshInterval = user.settings.widgetRefreshInterval ?? .hourly
        showKeyIndicators = user.settings.widgetShowKeyIndicators ?? true
        showTasks = user.settings.widgetShowTasks ?? true
        showEvents = user.settings.widgetShowEvents ?? true
    }
    
    private func saveWidgetSettings() {
        guard let user = authViewModel.currentUser else { return }
        
        var updatedUser = user
        updatedUser.settings.widgetSize = selectedWidgetSize
        updatedUser.settings.widgetTheme = selectedTheme
        updatedUser.settings.widgetRefreshInterval = refreshInterval
        updatedUser.settings.widgetShowKeyIndicators = showKeyIndicators
        updatedUser.settings.widgetShowTasks = showTasks
        updatedUser.settings.widgetShowEvents = showEvents
        
        dataManager.updateUser(updatedUser, userId: user.id) { success in
            if success {
                // Update widget data in UserDefaults for immediate widget updates
                updateWidgetData()
            }
        }
    }
    
    private func addCustomWidget(_ widget: DashboardWidget) {
        guard let user = authViewModel.currentUser else { return }
        
        var updatedUser = user
        updatedUser.settings.customWidgets.append(widget)
        
        dataManager.updateUser(updatedUser, userId: user.id) { success in
            if success {
                updateWidgetData()
            }
        }
    }
    
    private func removeCustomWidget(_ widget: DashboardWidget) {
        guard let user = authViewModel.currentUser else { return }
        
        var updatedUser = user
        updatedUser.settings.customWidgets.removeAll { $0.id == widget.id }
        
        dataManager.updateUser(updatedUser, userId: user.id) { success in
            if success {
                updateWidgetData()
            }
        }
    }
    
    private func updateWidgetData() {
        // Update UserDefaults with current widget data for immediate widget updates
        let defaults = UserDefaults(suiteName: "group.com.areabook.app")
        
        // Save current data for widgets
        let widgetData: [String: Any] = [
            "keyIndicators": dataManager.keyIndicators.map { ki in
                [
                    "id": ki.id,
                    "name": ki.name,
                    "progress": ki.progress,
                    "weeklyTarget": ki.weeklyTarget,
                    "color": ki.color
                ]
            },
            "tasks": dataManager.tasks.filter { !$0.isCompleted }.count,
            "events": dataManager.events.filter { Calendar.current.isDate($0.date, inSameDayAs: Date()) }.count,
            "lastUpdated": Date().timeIntervalSince1970
        ]
        
        defaults?.set(widgetData, forKey: "widget_data")
        
        // Reload widgets
        WidgetCenter.shared.reloadAllTimelines()
    }
}

// MARK: - Supporting Views

struct WidgetConfigurationCard: View {
    let widget: DashboardWidget
    let onEdit: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(widget.type.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("\(widget.size.displayName) • \(widget.orientation.displayName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: onRemove) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
            
            // Widget preview
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
                .frame(height: 60)
                .overlay(
            HStack {
                        Image(systemName: widget.type.icon)
                            .foregroundColor(.blue)
                        Text(widget.type.displayName)
                    .font(.caption)
                Spacer()
            }
                    .padding(.horizontal, 12)
                )
        }
        .padding(.vertical, 4)
    }
}

struct WidgetPreviewCard: View {
    let size: WidgetSize
    let theme: WidgetTheme
    let showKeyIndicators: Bool
    let showTasks: Bool
    let showEvents: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preview")
                .font(.headline)
                .fontWeight(.semibold)
            
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.backgroundColor)
                .frame(height: previewHeight)
                .overlay(
                    VStack(spacing: 8) {
                        HStack {
                            Text("AreaBook")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(theme.textColor)
                            Spacer()
                            Text("Today")
                                .font(.caption2)
                                .foregroundColor(theme.secondaryTextColor)
                        }
                        
                        if showKeyIndicators {
                            HStack {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 8, height: 8)
                                Text("KI Progress")
                                    .font(.caption2)
                                    .foregroundColor(theme.textColor)
                                Spacer()
                                Text("75%")
                                    .font(.caption2)
                                    .foregroundColor(theme.secondaryTextColor)
                            }
                        }
                        
                        if showTasks {
                            HStack {
                                Image(systemName: "checkmark.square")
                                    .font(.caption2)
                                    .foregroundColor(theme.textColor)
                                Text("3 tasks")
                                    .font(.caption2)
                                    .foregroundColor(theme.textColor)
                                Spacer()
                            }
                        }
                        
                        if showEvents {
                            HStack {
                                Image(systemName: "calendar")
                                    .font(.caption2)
                                    .foregroundColor(theme.textColor)
                                Text("2 events")
                                    .font(.caption2)
                                    .foregroundColor(theme.textColor)
                                Spacer()
                            }
                        }
                    }
                    .padding(12)
                )
        }
    }
    
    private var previewHeight: CGFloat {
        switch size {
        case .small: return 80
        case .medium: return 120
        case .large: return 160
        }
    }
}

struct AddWidgetView: View {
    @Environment(\.dismiss) private var dismiss
    let onAdd: (DashboardWidget) -> Void
    
    @State private var selectedType: DashboardWidgetType = .keyIndicators
    @State private var selectedSize: DashboardWidgetSize = .standard
    @State private var selectedOrientation: WidgetOrientation = .horizontal
    
    var body: some View {
        NavigationView {
            List {
                Section("Widget Type") {
                    Picker("Type", selection: $selectedType) {
                        ForEach(DashboardWidgetType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.displayName)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    }
                    
                Section("Widget Size") {
                    Picker("Size", selection: $selectedSize) {
                        ForEach(DashboardWidgetSize.allCases, id: \.self) { size in
                            Text(size.displayName).tag(size)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                if selectedSize == .medium {
                    Section("Orientation") {
                        Picker("Orientation", selection: $selectedOrientation) {
                            ForEach(WidgetOrientation.allCases, id: \.self) { orientation in
                                Text(orientation.displayName).tag(orientation)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }
                
                Section("Preview") {
                    WidgetPreviewCard(
                        size: .medium,
                        theme: .system,
                        showKeyIndicators: selectedType == .keyIndicators,
                        showTasks: selectedType == .tasks,
                        showEvents: selectedType == .events
                    )
                }
            }
            .navigationTitle("Add Widget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        let newWidget = DashboardWidget(
                            type: selectedType,
                            size: selectedSize,
                            position: (0, 0),
                            orientation: selectedOrientation
                        )
                        onAdd(newWidget)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Enums

// WidgetTheme extension for additional color properties
extension WidgetTheme {
    var backgroundColor: Color {
        switch self {
        case .system: return Color(.systemBackground)
        case .light: return Color.white
        case .dark: return Color.black
        case .colorful: return Color.blue.opacity(0.1)
        }
    }
    
    var textColor: Color {
        switch self {
        case .system: return Color(.label)
        case .light: return Color.black
        case .dark: return Color.white
        case .colorful: return Color.blue
    }
}

    var secondaryTextColor: Color {
        switch self {
        case .system: return Color(.secondaryLabel)
        case .light: return Color.gray
        case .dark: return Color.gray
        case .colorful: return Color.blue.opacity(0.7)
    }
    }
}

 