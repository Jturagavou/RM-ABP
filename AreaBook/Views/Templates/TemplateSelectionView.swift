import SwiftUI

struct TemplateSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var dataManager: DataManager
    @StateObject private var templateManager = TemplateManager.shared
    
    @State private var selectedTab: TemplateTab = .goals
    @State private var searchText = ""
    @State private var selectedCategory: String = "All"
    @State private var showingCreateTemplate = false
    @State private var showingTemplateDetail = false
    @State private var selectedTemplate: Any?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Template Type Tabs
                TemplateTypeTabs(selectedTab: $selectedTab)
                
                // Search and Filters
                TemplateSearchHeader(
                    searchText: $searchText,
                    selectedCategory: $selectedCategory,
                    categories: categoriesForCurrentTab
                )
                
                // Template Grid
                ScrollView {
                    LazyVStack(spacing: 16) {
                        switch selectedTab {
                        case .goals:
                            GoalTemplatesGrid(
                                templates: filteredGoalTemplates,
                                onTemplateSelected: { template in
                                    selectedTemplate = template
                                    showingTemplateDetail = true
                                },
                                onTemplateUsed: { template in
                                    useGoalTemplate(template)
                                }
                            )
                            
                        case .tasks:
                            TaskTemplatesGrid(
                                templates: filteredTaskTemplates,
                                onTemplateSelected: { template in
                                    selectedTemplate = template
                                    showingTemplateDetail = true
                                },
                                onTemplateUsed: { template in
                                    useTaskTemplate(template)
                                }
                            )
                            
                        case .events:
                            EventTemplatesGrid(
                                templates: filteredEventTemplates,
                                onTemplateSelected: { template in
                                    selectedTemplate = template
                                    showingTemplateDetail = true
                                },
                                onTemplateUsed: { template in
                                    useEventTemplate(template)
                                }
                            )
                        }
                        
                        // Empty State
                        if hasNoResults {
                            TemplateEmptyState(
                                selectedTab: selectedTab,
                                searchText: searchText,
                                onCreateTemplate: { showingCreateTemplate = true }
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Templates")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateTemplate = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(.blue)
                    }
                    
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            guard let userId = authViewModel.currentUser?.id else { return }
            templateManager.loadUserTemplates(userId: userId)
        }
        .sheet(isPresented: $showingCreateTemplate) {
            CreateTemplateView(templateType: selectedTab)
        }
        .sheet(isPresented: $showingTemplateDetail) {
            if let template = selectedTemplate {
                TemplateDetailView(template: template, templateType: selectedTab)
            }
        }
    }
    
    // MARK: - Template Usage
    
    private func useGoalTemplate(_ template: GoalTemplate) {
        guard let userId = authViewModel.currentUser?.id else { return }
        
        Task {
            do {
                let goal = try await templateManager.useGoalTemplate(template, userId: userId)
                await MainActor.run {
                    dataManager.createGoal(goal, userId: userId)
                    dismiss()
                }
            } catch {
                print("Failed to use goal template: \(error)")
            }
        }
    }
    
    private func useTaskTemplate(_ template: TaskTemplate) {
        guard let userId = authViewModel.currentUser?.id else { return }
        
        Task {
            do {
                let task = try await templateManager.useTaskTemplate(template, userId: userId)
                await MainActor.run {
                    dataManager.createTask(task, userId: userId)
                    dismiss()
                }
            } catch {
                print("Failed to use task template: \(error)")
            }
        }
    }
    
    private func useEventTemplate(_ template: EventTemplate) {
        guard let userId = authViewModel.currentUser?.id else { return }
        
        Task {
            do {
                let event = try await templateManager.useEventTemplate(template, userId: userId)
                await MainActor.run {
                    dataManager.createEvent(event, userId: userId)
                    dismiss()
                }
            } catch {
                print("Failed to use event template: \(error)")
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var categoriesForCurrentTab: [String] {
        switch selectedTab {
        case .goals:
            let categories = Set(templateManager.goalTemplates.map { $0.category })
            return ["All"] + Array(categories).sorted()
        case .tasks:
            let categories = Set(templateManager.taskTemplates.map { $0.category })
            return ["All"] + Array(categories).sorted()
        case .events:
            let categories = Set(templateManager.eventTemplates.map { $0.category })
            return ["All"] + Array(categories).sorted()
        }
    }
    
    private var filteredGoalTemplates: [GoalTemplate] {
        var templates = templateManager.goalTemplates
        
        if !searchText.isEmpty {
            templates = templates.filter { template in
                template.name.localizedCaseInsensitiveContains(searchText) ||
                template.description.localizedCaseInsensitiveContains(searchText) ||
                template.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        if selectedCategory != "All" {
            templates = templates.filter { $0.category == selectedCategory }
        }
        
        return templates.sorted { $0.usage > $1.usage }
    }
    
    private var filteredTaskTemplates: [TaskTemplate] {
        var templates = templateManager.taskTemplates
        
        if !searchText.isEmpty {
            templates = templates.filter { template in
                template.name.localizedCaseInsensitiveContains(searchText) ||
                template.description.localizedCaseInsensitiveContains(searchText) ||
                template.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        if selectedCategory != "All" {
            templates = templates.filter { $0.category == selectedCategory }
        }
        
        return templates.sorted { $0.usage > $1.usage }
    }
    
    private var filteredEventTemplates: [EventTemplate] {
        var templates = templateManager.eventTemplates
        
        if !searchText.isEmpty {
            templates = templates.filter { template in
                template.name.localizedCaseInsensitiveContains(searchText) ||
                template.description.localizedCaseInsensitiveContains(searchText) ||
                template.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        if selectedCategory != "All" {
            templates = templates.filter { $0.category == selectedCategory }
        }
        
        return templates.sorted { $0.usage > $1.usage }
    }
    
    private var hasNoResults: Bool {
        switch selectedTab {
        case .goals: return filteredGoalTemplates.isEmpty
        case .tasks: return filteredTaskTemplates.isEmpty
        case .events: return filteredEventTemplates.isEmpty
        }
    }
}

// MARK: - Supporting Views

struct TemplateTypeTabs: View {
    @Binding var selectedTab: TemplateTab
    
    var body: some View {
        HStack {
            ForEach(TemplateTab.allCases, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.title3)
                        Text(tab.title)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(selectedTab == tab ? .blue : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(selectedTab == tab ? Color.blue.opacity(0.1) : Color.clear)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
    }
}

struct TemplateSearchHeader: View {
    @Binding var searchText: String
    @Binding var selectedCategory: String
    let categories: [String]
    
    var body: some View {
        VStack(spacing: 12) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search templates...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            // Category Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(categories, id: \.self) { category in
                        Button(action: { selectedCategory = category }) {
                            Text(category)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedCategory == category ? Color.blue : Color(.systemGray5))
                                .foregroundColor(selectedCategory == category ? .white : .primary)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}

struct GoalTemplatesGrid: View {
    let templates: [GoalTemplate]
    let onTemplateSelected: (GoalTemplate) -> Void
    let onTemplateUsed: (GoalTemplate) -> Void
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            ForEach(templates) { template in
                GoalTemplateCard(
                    template: template,
                    onTap: { onTemplateSelected(template) },
                    onUse: { onTemplateUsed(template) }
                )
            }
        }
    }
}

struct GoalTemplateCard: View {
    let template: GoalTemplate
    let onTap: () -> Void
    let onUse: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(template.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                    
                    Text(template.category)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                DifficultyBadge(difficulty: template.difficulty)
            }
            
            // Description
            Text(template.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            // Tags
            if !template.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(template.tags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(.systemGray6))
                                .cornerRadius(4)
                        }
                    }
                }
            }
            
            // Footer
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(template.estimatedDuration) days")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.caption2)
                            .foregroundColor(.red)
                        Text("\(template.usage)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: onUse) {
                    Text("Use")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .onTapGesture {
            onTap()
        }
    }
}

struct TaskTemplatesGrid: View {
    let templates: [TaskTemplate]
    let onTemplateSelected: (TaskTemplate) -> Void
    let onTemplateUsed: (TaskTemplate) -> Void
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            ForEach(templates) { template in
                TaskTemplateCard(
                    template: template,
                    onTap: { onTemplateSelected(template) },
                    onUse: { onTemplateUsed(template) }
                )
            }
        }
    }
}

struct TaskTemplateCard: View {
    let template: TaskTemplate
    let onTap: () -> Void
    let onUse: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(template.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                    
                    Text(template.category)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                PriorityBadge(priority: template.defaultPriority)
            }
            
            // Description
            Text(template.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            // Tags
            if !template.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(template.tags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(.systemGray6))
                                .cornerRadius(4)
                        }
                    }
                }
            }
            
            // Footer
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(template.estimatedTime) min")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.caption2)
                            .foregroundColor(.red)
                        Text("\(template.usage)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: onUse) {
                    Text("Use")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .onTapGesture {
            onTap()
        }
    }
}

struct EventTemplatesGrid: View {
    let templates: [EventTemplate]
    let onTemplateSelected: (EventTemplate) -> Void
    let onTemplateUsed: (EventTemplate) -> Void
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            ForEach(templates) { template in
                EventTemplateCard(
                    template: template,
                    onTap: { onTemplateSelected(template) },
                    onUse: { onTemplateUsed(template) }
                )
            }
        }
    }
}

struct EventTemplateCard: View {
    let template: EventTemplate
    let onTap: () -> Void
    let onUse: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(template.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                    
                    Text(template.category)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "calendar")
                    .font(.title3)
                    .foregroundColor(.orange)
            }
            
            // Description
            Text(template.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            // Tags
            if !template.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(template.tags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(.systemGray6))
                                .cornerRadius(4)
                        }
                    }
                }
            }
            
            // Footer
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(template.defaultDuration) min")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.caption2)
                            .foregroundColor(.red)
                        Text("\(template.usage)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: onUse) {
                    Text("Use")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .onTapGesture {
            onTap()
        }
    }
}

struct DifficultyBadge: View {
    let difficulty: GoalDifficulty
    
    var body: some View {
        Text(difficulty.rawValue.capitalized)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color(hex: difficulty.color) ?? .gray)
            .foregroundColor(.white)
            .cornerRadius(4)
    }
}

struct PriorityBadge: View {
    let priority: TaskPriority
    
    var body: some View {
        Text(priority.rawValue.capitalized)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(priority.color)
            .foregroundColor(.white)
            .cornerRadius(4)
    }
}

struct TemplateEmptyState: View {
    let selectedTab: TemplateTab
    let searchText: String
    let onCreateTemplate: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: selectedTab.icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text(emptyStateTitle)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(emptyStateMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if searchText.isEmpty {
                Button(action: onCreateTemplate) {
                    Text("Create Template")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }
    
    private var emptyStateTitle: String {
        if !searchText.isEmpty {
            return "No Results Found"
        }
        
        switch selectedTab {
        case .goals: return "No Goal Templates"
        case .tasks: return "No Task Templates"
        case .events: return "No Event Templates"
        }
    }
    
    private var emptyStateMessage: String {
        if !searchText.isEmpty {
            return "Try adjusting your search or filters to find what you're looking for."
        }
        
        switch selectedTab {
        case .goals: return "Create your first goal template to speed up goal creation in the future."
        case .tasks: return "Create your first task template to quickly add common tasks."
        case .events: return "Create your first event template for recurring events."
        }
    }
}

// MARK: - Supporting Types

enum TemplateTab: CaseIterable {
    case goals, tasks, events
    
    var title: String {
        switch self {
        case .goals: return "Goals"
        case .tasks: return "Tasks"
        case .events: return "Events"
        }
    }
    
    var icon: String {
        switch self {
        case .goals: return "target"
        case .tasks: return "checkmark.circle"
        case .events: return "calendar"
        }
    }
}

// MARK: - Placeholder Views (to be implemented)

struct CreateTemplateView: View {
    let templateType: TemplateTab
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Create \(templateType.title) Template")
                    .font(.headline)
                Text("Template creation UI would go here")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("New Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { dismiss() }
                }
            }
        }
    }
}

struct TemplateDetailView: View {
    let template: Any
    let templateType: TemplateTab
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("\(templateType.title) Template Details")
                    .font(.headline)
                Text("Template detail UI would go here")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Template Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Color Extension

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        self.init(
            red: Double((rgb & 0xFF0000) >> 16) / 255.0,
            green: Double((rgb & 0x00FF00) >> 8) / 255.0,
            blue: Double(rgb & 0x0000FF) / 255.0
        )
    }
}

#Preview {
    TemplateSelectionView()
        .environmentObject(AuthViewModel())
        .environmentObject(DataManager.shared)
}