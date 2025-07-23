import SwiftUI
import UniformTypeIdentifiers

struct DashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var dataManager: DataManager
    @Binding var externalEditMode: Bool
    @State private var showingProfile = false
    @State private var showingWidgetCustomization = false
    @State private var showingAddWidget = false
    @State private var draggedWidget: DashboardWidget?
    @State private var showingEditModeTutorial = false
    @State private var showingTestOptions = false
    
    // Computed property to sync internal and external edit mode
    private var isEditMode: Bool {
        get { externalEditMode }
        set {
            externalEditMode = newValue
            // Trigger any additional actions when edit mode changes
            if newValue && !UserDefaults.standard.bool(forKey: "edit_mode_tutorial_shown") {
                showingEditModeTutorial = true
                UserDefaults.standard.set(true, forKey: "edit_mode_tutorial_shown")
            }
        }
    }
    
    // Get user's custom dashboard layout
    private var userDashboardLayout: DashboardLayout {
        authViewModel.currentUser?.settings.dashboardLayout ?? DashboardLayout.default
    }
    
    // Get user's enabled features
    private var enabledFeatures: Set<AppFeature> {
        authViewModel.currentUser?.settings.enabledFeatures ?? Set(AppFeature.defaultFeatures)
    }
    
    var body: some View {
        NavigationView {
            dashboardContent
        }
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.large)
        .onTapGesture(count: 5) {
            handleFiveTapGesture()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                dashboardToolbar
            }
        }
        .confirmationDialog("Test Options", isPresented: $showingTestOptions) {
            testOptionsDialog
        }
        .onAppear {
            refreshDashboard()
        }
        .sheet(isPresented: $showingProfile) {
            profileSheet
        }
        .sheet(isPresented: $showingAddWidget) {
            addWidgetSheet
        }
        .sheet(isPresented: $showingEditModeTutorial) {
            EditModeTutorialView()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            handleBackgroundTap()
        }
    }
    
    private var dashboardContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header with greeting and edit button
                DashboardHeader(
                    userName: authViewModel.currentUser?.name ?? "Friend",
                    isEditMode: $externalEditMode,
                    onEditModeToggle: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            externalEditMode.toggle()
                        }
                    }
                )
                
                // Customizable dashboard grid with loading state
                Group {
                    if dataManager.isLoading {
                        // DashboardSkeletonView()
                    } else {
                        EnhancedDashboardGrid(
                            widgets: userDashboardLayout.widgets,
                            enabledFeatures: enabledFeatures,
                            dataManager: dataManager,
                            isEditMode: isEditMode,
                            draggedWidget: $draggedWidget,
                            onWidgetMove: moveWidget,
                            onWidgetRemove: removeWidget,
                            onWidgetCustomize: customizeWidget,
                            onWidgetResize: resizeWidget
                        )
                    }
                }
                .transition(.opacity.combined(with: .scale))
                
                // Add widget button when in edit mode
                if isEditMode {
                    AddWidgetButton {
                        showingAddWidget = true
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                
                // Empty state when no widgets
                if userDashboardLayout.widgets.isEmpty && !isEditMode && !dataManager.isLoading {
                    EmptyDashboardView {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            externalEditMode = true
                        }
                    }
                    .transition(.opacity.combined(with: .scale))
                }
            }
            .padding()
        }
    }
    
    private var dashboardToolbar: some View {
        HStack(spacing: 12) {
            // Edit mode toggle
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    externalEditMode.toggle()
                }
            } label: {
                Image(systemName: isEditMode ? "checkmark.circle.fill" : "pencil.circle")
                    .foregroundColor(isEditMode ? .green : .blue)
                    .font(.title2)
            }
            
            // Profile button
            Button {
                showingProfile = true
            } label: {
                AsyncImage(url: URL(string: authViewModel.currentUser?.avatar ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.blue)
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())
            }
            
            // Debug button for widget testing
            Button {
                showingTestOptions = true
            } label: {
                Image(systemName: "hammer.circle.fill")
                    .foregroundColor(.orange)
                    .font(.title2)
            }
        }
    }
    
    private var testOptionsDialog: some View {
        Group {
            Button("Create Sample Data") {
                WidgetDataService.shared.createSampleDataForTesting()
            }
            Button("Test Widget Sync") {
                WidgetDataService.shared.syncDataForWidgets()
            }
            Button("Clear Widget Data") {
                WidgetDataUtilities.clearAllWidgetData()
            }
            Button("Cancel", role: .cancel) { }
        }
    }
    
    private var profileSheet: some View {
        NavigationView {
            VStack {
                Text("Profile")
                    .font(.title)
                Text("Profile settings coming soon")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingProfile = false
                    }
                }
            }
        }
    }
    
    private var addWidgetSheet: some View {
        AddWidgetSheet(
            enabledFeatures: enabledFeatures,
            onWidgetAdded: addWidget
        )
    }
    
    private func handleFiveTapGesture() {
        // Hidden developer feature: tap title 5 times to create sample widget data
#if DEBUG
        WidgetDataService.shared.createSampleDataForTesting()
#endif
    }
    
    private func handleBackgroundTap() {
        if isEditMode {
            withAnimation(.easeInOut(duration: 0.3)) {
                externalEditMode = false
            }
        }
    }
    
    func refreshDashboard() {
        // Refresh data for all widgets
        // await dataManager.refreshAllData()
    }
    
    func moveWidget(from source: IndexSet, to destination: Int) {
        guard let _ = authViewModel.currentUser?.id else { return }
        
        // HapticManager.shared.dragEnd()
        
        var updatedWidgets = userDashboardLayout.widgets
        updatedWidgets.move(fromOffsets: source, toOffset: destination)
        
        // Update positions based on new order
        for (index, _) in updatedWidgets.enumerated() {
            updatedWidgets[index].position = (row: index / 2, col: index % 2)
        }
        
        // Save updated layout
        saveDashboardLayout(updatedWidgets)
    }
    
    func addWidget(_ widget: DashboardWidget) {
        guard let _ = authViewModel.currentUser?.id else { return }
        
        // HapticManager.shared.widgetAdded()
        
        var updatedWidgets = userDashboardLayout.widgets
        
        // Find next available position
        let nextPosition = findNextAvailablePosition(in: updatedWidgets)
        var newWidget = widget
        newWidget.position = nextPosition
        updatedWidgets.append(newWidget)
        
        // Save updated layout
        saveDashboardLayout(updatedWidgets)
    }
    
    func removeWidget(_ widget: DashboardWidget) {
        guard let _ = authViewModel.currentUser?.id else { return }
        
        // HapticManager.shared.widgetRemoved()
        
        var updatedWidgets = userDashboardLayout.widgets
        updatedWidgets.removeAll(where: { $0.id == widget.id })
        
        // Recalculate positions
        for (index, _) in updatedWidgets.enumerated() {
            updatedWidgets[index].position = (row: index / 2, col: index % 2)
        }
        
        // Save updated layout
        saveDashboardLayout(updatedWidgets)
    }
    
    func customizeWidget(_ widget: DashboardWidget) {
        showingWidgetCustomization = true
    }
    
    func resizeWidget(_ widget: DashboardWidget, _ newSize: DashboardWidgetSize, _ newOrientation: WidgetOrientation) {
        guard let _ = authViewModel.currentUser?.id else { return }
        
        var updatedWidgets = userDashboardLayout.widgets
        if let index = updatedWidgets.firstIndex(where: { $0.id == widget.id }) {
            updatedWidgets[index].size = newSize
            updatedWidgets[index].orientation = newOrientation
            updatedWidgets[index].position = (row: index / 2, col: index % 2) // Recalculate position
        }
        
        // Save updated layout
        saveDashboardLayout(updatedWidgets)
        
        // Haptic feedback
    }
    
    func findNextAvailablePosition(in widgets: [DashboardWidget]) -> (row: Int, col: Int) {
        var position = (row: 0, col: 0)
        let maxRows = 6 // Increased maximum rows
        
        for row in 0..<maxRows {
            for col in 0..<2 {
                position = (row: row, col: col)
                if !widgets.contains(where: { $0.position == position }) {
                    return position
                }
            }
        }
        
        // If all positions are taken, add to the end
        return (row: widgets.count / 2, col: widgets.count % 2)
    }
    
    func saveDashboardLayout(_ widgets: [DashboardWidget]) {
        guard let userId = authViewModel.currentUser?.id else { return }
        
        let newLayout = DashboardLayout(
            widgets: widgets,
            gridRows: max(2, (widgets.count + 1) / 2),
            gridCols: 2
        )
        
        // Update user settings
        var updatedUser = authViewModel.currentUser!
        updatedUser.settings.dashboardLayout = newLayout
        updatedUser.settings.customWidgets = widgets
        
        // Save to Firestore
        dataManager.updateUser(updatedUser, userId: userId) { success in
            if success {
                print("✅ Dashboard: Layout saved successfully")
                DispatchQueue.main.async {
                    self.authViewModel.currentUser = updatedUser
                }
            } else {
                print("❌ Dashboard: Failed to save layout")
            }
        }
        
        // Save to UserDefaults for immediate access
        if let layoutData = try? JSONEncoder().encode(newLayout) {
            UserDefaults.standard.set(layoutData, forKey: "dashboard_layout")
        }
        if let widgetsData = try? JSONEncoder().encode(widgets) {
            UserDefaults.standard.set(widgetsData, forKey: "custom_widgets")
        }
    }
    
    // MARK: - Dashboard Header
    struct DashboardHeader: View {
        let userName: String
        @Binding var isEditMode: Bool
        let onEditModeToggle: () -> Void
        
        var body: some View {
            VStack(spacing: 16) {
                // Greeting
                VStack(spacing: 8) {
                    Text("Hello, \(userName)!")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text(getGreetingMessage())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Edit mode indicator
                if isEditMode {
                    HStack {
                        Image(systemName: "pencil.circle.fill")
                            .foregroundColor(.blue)
                        Text("Edit Mode - Drag to reorder, tap to customize")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        
        func getGreetingMessage() -> String {
            let hour = Calendar.current.component(.hour, from: Date())
            switch hour {
            case 5..<12: return "Good morning! Ready to tackle today's goals?"
            case 12..<17: return "Good afternoon! How's your day going?"
            case 17..<22: return "Good evening! Time to reflect on today's progress."
            default: return "Good night! Don't forget to plan for tomorrow."
            }
        }
    }
    
    // MARK: - Enhanced Dashboard Grid
    struct EnhancedDashboardGrid: View {
        let widgets: [DashboardWidget]
        let enabledFeatures: Set<AppFeature>
        let dataManager: DataManager
        let isEditMode: Bool
        @Binding var draggedWidget: DashboardWidget?
        let onWidgetMove: (IndexSet, Int) -> Void
        let onWidgetRemove: (DashboardWidget) -> Void
        let onWidgetCustomize: (DashboardWidget) -> Void
        let onWidgetResize: (DashboardWidget, DashboardWidgetSize, WidgetOrientation) -> Void
        
        private let gridSpacing: CGFloat = 12
        
        var body: some View {
            VStack(spacing: gridSpacing) {
                ForEach(getGridRows(), id: \.self) { rowIndex in
                    HStack(spacing: gridSpacing) {
                        ForEach(getWidgetsForRow(rowIndex), id: \.id) { widget in
                            EnhancedDashboardWidgetView(
                                widget: widget,
                                enabledFeatures: enabledFeatures,
                                dataManager: dataManager,
                                isEditMode: isEditMode,
                                onRemove: { onWidgetRemove(widget) },
                                onCustomize: { onWidgetCustomize(widget) },
                                onResize: { newSize, newOrientation in
                                    onWidgetResize(widget, newSize, newOrientation)
                                }
                            )
                            .frame(width: getWidgetWidth(for: widget))
                            .onDrag {
                                draggedWidget = widget
                                return NSItemProvider(object: widget.id as NSString)
                            }
                            .onDrop(of: [UTType.text], delegate: WidgetDropDelegate(
                                widget: widget,
                                draggedWidget: $draggedWidget,
                                onWidgetMove: onWidgetMove
                            ))
                            .scaleEffect(draggedWidget?.id == widget.id ? 1.05 : 1.0)
                            .animation(Animation.easeInOut(duration: 0.2), value: draggedWidget?.id == widget.id)
                        }
                        
                        // Fill remaining space if needed
                        if getWidgetsForRow(rowIndex).count == 1 && getWidgetsForRow(rowIndex).first?.gridSize.cols == 1 {
                            Spacer()
                        }
                    }
                }
            }
        }
        
        func getGridRows() -> [Int] {
            guard !widgets.isEmpty else { return [] }
            
            var maxRow = 0
            for widget in widgets {
                let endRow = widget.position.row + widget.gridSize.rows - 1
                maxRow = max(maxRow, endRow)
            }
            return Array(0...maxRow)
        }
        
        func getWidgetsForRow(_ rowIndex: Int) -> [DashboardWidget] {
            return widgets.filter { widget in
                let startRow = widget.position.row
                let endRow = widget.position.row + widget.gridSize.rows - 1
                return rowIndex >= startRow && rowIndex <= endRow
            }.sorted { $0.position.col < $1.position.col }
        }
        
        func getWidgetWidth(for widget: DashboardWidget) -> CGFloat? {
            let screenWidth = UIScreen.main.bounds.width
            let totalPadding: CGFloat = 40 // 20 padding on each side
            let availableWidth = screenWidth - totalPadding - gridSpacing
            
            switch widget.gridSize.cols {
            case 1:
                return (availableWidth - gridSpacing) / 2 // Half width minus spacing
            case 2:
                return availableWidth // Full width
            default:
                return availableWidth / 2
            }
        }
    }
    
    // MARK: - Enhanced Dashboard Widget View
    struct EnhancedDashboardWidgetView: View {
        let widget: DashboardWidget
        let enabledFeatures: Set<AppFeature>
        let dataManager: DataManager
        let isEditMode: Bool
        let onRemove: () -> Void
        let onCustomize: () -> Void
        let onResize: (DashboardWidgetSize, WidgetOrientation) -> Void
        
        @State private var showingCustomization = false
        @State private var showingResizeOptions = false
        @State private var longPressTimer: Timer?
        @State private var isLongPressed = false
        
        var body: some View {
            VStack {
                // Widget content based on type
                switch widget.type {
                case .keyIndicators:
                    KeyIndicatorsWidget(dataManager: dataManager)
                case .tasks:
                    TasksWidget(dataManager: dataManager)
                case .events:
                    EventsWidget(dataManager: dataManager)
                case .goals:
                    GoalsDashboardWidget(dataManager: dataManager)
                case .quote:
                    QuoteWidget()
                case .aiSuggestions:
                    AISuggestionsWidget()
                case .notes:
                    NotesWidget(dataManager: dataManager)
                case .groupActivity:
                    GroupActivityWidget(dataManager: dataManager)
                case .quickActions:
                    QuickActionsWidget()
                case .weather:
                    WeatherWidget()
                case .custom:
                    CustomWidget(config: widget.config)
                case .aiAssistant:
                    // Placeholder for AI Assistant widget
                    Text("AI Assistant Widget")
                }
            }
            .frame(height: getWidgetHeight())
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .overlay(
                // Size indicator (only in edit mode)
                Group {
                    if isEditMode {
                        VStack {
                            HStack {
                                // Size indicator
                                Text(widget.size.displayName)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.8))
                                    .cornerRadius(4)
                                
                                Spacer()
                                
                                // Resize button
                                Button(action: { showingResizeOptions = true }) {
                                    Image(systemName: "arrow.clockwise.circle.fill")
                                        .foregroundColor(.blue)
                                        .font(.title2)
                                        .background(Color.white)
                                        .clipShape(Circle())
                                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                                }
                                
                                Button(action: onRemove) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                        .font(.title2)
                                        .background(Color.white)
                                        .clipShape(Circle())
                                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                                }
                            }
                            Spacer()
                        }
                        .padding(8)
                    }
                }
            )
            .onTapGesture {
                if isEditMode {
                    onCustomize()
                }
            }
            .onLongPressGesture(minimumDuration: 0.5) {
                if !isEditMode {
                    // Enter edit mode on long press
                    onCustomize()
                }
            }
            .sheet(isPresented: $showingCustomization) {
                WidgetCustomizationSheet(widget: widget)
            }
            .actionSheet(isPresented: $showingResizeOptions) {
                ActionSheet(
                    title: Text("Widget Size"),
                    message: Text("Choose the size for this widget"),
                    buttons: [
                        .default(Text("Standard (1x1)")) {
                            onResize(.standard, .horizontal)
                        },
                        .default(Text("Medium (2x1)")) {
                            onResize(.medium, .horizontal)
                        },
                        .default(Text("Large (2x2)")) {
                            onResize(.large, .horizontal)
                        },
                        .cancel()
                    ]
                )
            }
        }
        
        func getWidgetHeight() -> CGFloat {
            let baseHeight: CGFloat = 140
            
            switch widget.size {
            case .standard:
                return baseHeight // 1x1 widget
            case .medium:
                return baseHeight // 2x1 widget (same height, but 2 columns wide)
            case .large:
                return baseHeight * 2 + 12 // 2x2 widget (2 rows tall, 2 columns wide) - double height plus spacing
            }
        }
    }
    
    // MARK: - Widget Drop Delegate
    struct WidgetDropDelegate: DropDelegate {
        let widget: DashboardWidget
        @Binding var draggedWidget: DashboardWidget?
        let onWidgetMove: (IndexSet, Int) -> Void
        
        func performDrop(info: DropInfo) -> Bool {
            guard let _ = draggedWidget else { return false }
            
            // Find the indices for the move operation
            // This is a simplified implementation - in a real app you'd want more sophisticated logic
            // For now, we'll just clear the dragged widget
            self.draggedWidget = nil
            return true
        }
        
        func dropUpdated(info: DropInfo) -> DropProposal? {
            return DropProposal(operation: .move)
        }
        
        func validateDrop(info: DropInfo) -> Bool {
            return draggedWidget != nil
        }
        
        func dropEntered(info: DropInfo) {
            // Handle drop entered
        }
        
        func dropExited(info: DropInfo) {
            // Handle drop exited
        }
    }
    
    // MARK: - Add Widget Button
    struct AddWidgetButton: View {
        let onTap: () -> Void
        
        var body: some View {
            Button(action: onTap) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                    Text("Add Widget")
                        .font(.headline)
                }
                .foregroundColor(.blue)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
            .transition(.scale.combined(with: .opacity))
        }
    }
    
    // MARK: - Empty Dashboard View
    struct EmptyDashboardView: View {
        let onAddWidget: () -> Void
        
        var body: some View {
            VStack(spacing: 20) {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                
                Text("Your Dashboard is Empty")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Add widgets to personalize your dashboard and track what matters most to you")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button(action: onAddWidget) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add Your First Widget")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
            }
            .padding(.top, 60)
        }
    }
    
    // MARK: - Edit Mode Tutorial View
    struct EditModeTutorialView: View {
        @Environment(\.dismiss) private var dismiss
        
        var body: some View {
            NavigationView {
                VStack(spacing: 24) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("Edit Mode")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        TutorialStep(
                            icon: "hand.draw",
                            title: "Drag to Reorder",
                            description: "Long press and drag widgets to rearrange them"
                        )
                        
                        TutorialStep(
                            icon: "xmark.circle",
                            title: "Remove Widgets",
                            description: "Tap the X button to remove unwanted widgets"
                        )
                        
                        TutorialStep(
                            icon: "plus.circle",
                            title: "Add New Widgets",
                            description: "Use the Add Widget button to add new widgets"
                        )
                        
                        TutorialStep(
                            icon: "slider.horizontal.3",
                            title: "Customize Widgets",
                            description: "Tap any widget to customize its settings"
                        )
                    }
                    
                    Spacer()
                    
                    Button("Got it!") {
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .padding()
                .navigationTitle("Dashboard Tutorial")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Skip") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
    
    struct TutorialStep: View {
        let icon: String
        let title: String
        let description: String
        
        var body: some View {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Add Widget Sheet
    struct AddWidgetSheet: View {
        let enabledFeatures: Set<AppFeature>
        let onWidgetAdded: (DashboardWidget) -> Void
        @Environment(\.dismiss) private var dismiss
        @State private var selectedType: DashboardWidgetType = .keyIndicators
        @State private var selectedSize: DashboardWidgetSize = .medium
        
        var body: some View {
            NavigationView {
                VStack(spacing: 20) {
                    // Widget type selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Widget Type")
                            .font(.headline)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                            ForEach(DashboardWidgetType.allCases, id: \.self) { type in
                                WidgetTypeCard(
                                    type: type,
                                    isSelected: selectedType == type
                                ) {
                                    selectedType = type
                                }
                            }
                        }
                    }
                    
                    // Widget size selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Widget Size")
                            .font(.headline)
                        
                        HStack(spacing: 12) {
                            ForEach(DashboardWidgetSize.allCases, id: \.self) { size in
                                WidgetSizeCard(
                                    size: size,
                                    isSelected: selectedSize == size
                                ) {
                                    selectedSize = size
                                }
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding()
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
                                position: (0, 0)
                            )
                            onWidgetAdded(newWidget)
                            dismiss()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Widget Type Card
    struct WidgetTypeCard: View {
        let type: DashboardWidgetType
        let isSelected: Bool
        let onTap: () -> Void
        
        var body: some View {
            Button(action: onTap) {
                VStack(spacing: 8) {
                    Image(systemName: type.icon)
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? .white : .blue)
                    
                    Text(type.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .white : .primary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isSelected ? Color.blue : Color(.secondarySystemBackground))
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Widget Size Card
    struct WidgetSizeCard: View {
        let size: DashboardWidgetSize
        let isSelected: Bool
        let onTap: () -> Void
        
        var body: some View {
            Button(action: onTap) {
                VStack(spacing: 8) {
                    Text(size.rawValue.capitalized)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(getSizeDescription())
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isSelected ? Color.blue : Color(.secondarySystemBackground))
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
        
        func getSizeDescription() -> String {
            switch size {
            case .standard: return "Compact"
            case .medium: return "Standard"
            case .large: return "Large"
            }
        }
    }
    
    // MARK: - Widget Customization Sheet
    struct WidgetCustomizationSheet: View {
        let widget: DashboardWidget
        @Environment(\.dismiss) private var dismiss
        
        var body: some View {
            NavigationView {
                VStack(spacing: 20) {
                    Text("Customize \(widget.type.displayName)")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    // Add customization options here based on widget type
                    VStack(alignment: .leading, spacing: 16) {
                        CustomizationOption(
                            title: "Widget Size",
                            description: "Change the size of this widget",
                            icon: "arrow.up.and.down"
                        )
                        
                        CustomizationOption(
                            title: "Refresh Rate",
                            description: "How often to update the data",
                            icon: "clock"
                        )
                        
                        CustomizationOption(
                            title: "Display Options",
                            description: "Customize what information to show",
                            icon: "eye"
                        )
                    }
                    
                    Spacer()
                    
                    Text("More customization options coming soon!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .navigationTitle("Customize Widget")
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
    }
    
    struct CustomizationOption: View {
        let title: String
        let description: String
        let icon: String
        
        var body: some View {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(8)
        }
    }
    
    // MARK: - Enhanced Widget Content Views
    struct KeyIndicatorsWidget: View {
        let dataManager: DataManager
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(.blue)
                    Text("Key Indicators")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                }
                
                let keyIndicatorGoals = dataManager.goals.filter { $0.isKeyIndicator }
                
                if keyIndicatorGoals.isEmpty {
                    Text("No key indicators yet")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    VStack(spacing: 4) {
                        let indicators = Array(keyIndicatorGoals.prefix(2))
                        if indicators.count > 0 {
                            HStack {
                                Text(indicators[0].title)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Text("\(Int(indicators[0].keyIndicatorProgressPercentage))%")
                                    .font(.caption)
                                    .foregroundColor(progressColor(for: indicators[0].keyIndicatorProgressPercentage))
                                    .fontWeight(.medium)
                            }
                        }
                        if indicators.count > 1 {
                            HStack {
                                Text(indicators[1].title)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Text("\(Int(indicators[1].keyIndicatorProgressPercentage))%")
                                    .font(.caption)
                                    .foregroundColor(progressColor(for: indicators[1].keyIndicatorProgressPercentage))
                                    .fontWeight(.medium)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        
        func progressColor(for percentage: Double) -> Color {
            if percentage >= 80 {
                return .green
            } else if percentage >= 50 {
                return .orange
            } else {
                return .red
            }
        }
    }
    
    struct TasksWidget: View {
        let dataManager: DataManager
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.green)
                    Text("Today's Tasks")
                        .font(.headline)
                    Spacer()
                    Text("\(dataManager.tasks.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                let todayTasks = dataManager.tasks.filter { task in
                    guard let dueDate = task.dueDate else { return false }
                    return Calendar.current.isDate(dueDate, inSameDayAs: Date())
                }
                
                if todayTasks.isEmpty {
                    Text("No tasks for today")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    VStack(spacing: 4) {
                        let tasks = Array(todayTasks.prefix(2))
                        ForEach(tasks) { task in
                            HStack {
                                Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(task.status == .completed ? .green : .gray)
                                    .font(.caption)
                                
                                Text(task.title)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                
                                Spacer()
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    struct EventsWidget: View {
        let dataManager: DataManager
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.orange)
                    Text("Upcoming Events")
                        .font(.headline)
                    Spacer()
                    Text("\(dataManager.events.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                let upcomingEvents = dataManager.events.filter { event in
                    event.startTime > Date()
                }.sorted { $0.startTime < $1.startTime }
                
                if upcomingEvents.isEmpty {
                    Text("No upcoming events")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    VStack(spacing: 4) {
                        let events = Array(upcomingEvents.prefix(2))
                        ForEach(events) { event in
                            HStack {
                                Text(event.title)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Text(event.startTime, style: .time)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    struct GoalsDashboardWidget: View {
        let dataManager: DataManager
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "target")
                        .foregroundColor(.purple)
                    Text("Goal Progress")
                        .font(.headline)
                    Spacer()
                    Text("\(dataManager.goals.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if dataManager.goals.isEmpty {
                    Text("No goals yet")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    VStack(spacing: 4) {
                        let goals = Array(dataManager.goals.prefix(2))
                        ForEach(goals) { goal in
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(goal.title)
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                    
                                    Spacer()
                                    
                                    Text("\(Int(goal.calculatedProgress))%")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                                
                                let progressValue = Double(goal.calculatedProgress) / 100.0
                                ProgressView(value: progressValue)
                                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                                    .scaleEffect(y: 0.5)
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    struct QuoteWidget: View {
        let quotes = [
            "The only way to do great work is to love what you do.",
            "Success is not final, failure is not fatal: it is the courage to continue that counts.",
            "The future belongs to those who believe in the beauty of their dreams.",
            "Don't watch the clock; do what it does. Keep going.",
            "The only limit to our realization of tomorrow is our doubts of today."
        ]
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "quote.bubble")
                        .foregroundColor(.pink)
                    Text("Daily Quote")
                        .font(.headline)
                    Spacer()
                }
                
                Text(quotes.randomElement() ?? quotes[0])
                    .font(.caption)
                    .foregroundColor(.primary)
                    .italic()
                    .lineLimit(3)
            }
            .padding()
        }
    }
    
    struct AISuggestionsWidget: View {
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.indigo)
                    Text("AI Suggestions")
                        .font(.headline)
                    Spacer()
                }
                
                Text("Based on your patterns, try focusing on your most important task first today.")
                    .font(.caption)
                    .foregroundColor(.primary)
                    .lineLimit(3)
            }
            .padding()
        }
    }
    
    struct NotesWidget: View {
        let dataManager: DataManager
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "note.text")
                        .foregroundColor(.brown)
                    Text("Recent Notes")
                        .font(.headline)
                    Spacer()
                    Text("\(dataManager.notes.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if dataManager.notes.isEmpty {
                    Text("No notes yet")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    VStack(spacing: 4) {
                        let notes = Array(dataManager.notes.prefix(2))
                        ForEach(notes) { note in
                            HStack {
                                Text(note.title)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Text(note.createdAt, style: .relative)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    struct GroupActivityWidget: View {
        let dataManager: DataManager
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "person.3")
                        .foregroundColor(.teal)
                    Text("Group Activity")
                        .font(.headline)
                    Spacer()
                }
                
                Text("No recent group activity")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
    
    struct QuickActionsWidget: View {
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "bolt")
                        .foregroundColor(.yellow)
                    Text("Quick Actions")
                        .font(.headline)
                    Spacer()
                }
                
                HStack(spacing: 12) {
                    QuickActionButton(icon: "plus", label: "Add Task")
                    QuickActionButton(icon: "calendar", label: "Add Event")
                    QuickActionButton(icon: "flag", label: "Add Goal")
                }
            }
            .padding()
        }
    }
    
    struct QuickActionButton: View {
        let icon: String
        let label: String
        
        var body: some View {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(6)
        }
    }
    
    struct WeatherWidget: View {
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "cloud.sun")
                        .foregroundColor(.orange)
                    Text("Weather")
                        .font(.headline)
                    Spacer()
                }
                
                HStack {
                    Text("72°")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Sunny")
                            .font(.caption)
                            .foregroundColor(.primary)
                        
                        Text("San Francisco")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
        }
    }
    
    struct CustomWidget: View {
        let config: [String: String]
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "star")
                        .foregroundColor(.purple)
                    Text("Custom Widget")
                        .font(.headline)
                    Spacer()
                }
                
                Text("Your custom content")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
}

// MARK: - Extensions
extension DashboardWidgetSize {
    var name: String {
        switch self {
        case .standard: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        }
    }
}

#Preview {
    DashboardView(externalEditMode: .constant(false))
        .environmentObject(AuthViewModel.shared)
        .environmentObject(DataManager.shared)
}

