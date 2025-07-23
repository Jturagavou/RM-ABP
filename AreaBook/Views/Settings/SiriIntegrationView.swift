import SwiftUI
import Intents

struct SiriIntegrationView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var siriManager = SiriShortcutsManager.shared
    @State private var showingAddShortcut = false
    @State private var selectedShortcut: SiriShortcut?
    @State private var showingShortcutDetail = false
    @State private var isSiriEnabled = false
    
    var body: some View {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                        Image(systemName: "mic.circle.fill")
                            .font(.title)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Siri Integration")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            
                            Text("Use voice commands to interact with AreaBook")
                                .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        
                        Spacer()
                        
                        Toggle("", isOn: $isSiriEnabled)
                            .onChange(of: isSiriEnabled) { newValue in
                                toggleSiriIntegration(enabled: newValue)
                            }
                    }
                    
                    if isSiriEnabled {
                        Text("Siri is enabled. You can now use voice commands to interact with AreaBook.")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Text("Enable Siri to use voice commands with AreaBook.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if isSiriEnabled {
                Section("Available Commands") {
                    ForEach(SiriCommand.allCases, id: \.self) { command in
                        SiriCommandCard(
                            command: command,
                            isEnabled: siriManager.isShortcutEnabled(for: command),
                            onToggle: { enabled in
                                toggleShortcut(command: command, enabled: enabled)
                            }
                        )
                    }
                }
                
                Section("My Shortcuts") {
                    ForEach(siriManager.userShortcuts, id: \.self) { shortcut in
                        UserShortcutCard(
                            shortcut: shortcut,
                            onTap: {
                                selectedShortcut = shortcut
                                showingShortcutDetail = true
                            },
                            onDelete: {
                                deleteUserShortcut(shortcut)
                        }
                        )
                    }
                    
                    if siriManager.userShortcuts.isEmpty {
                        Text("No custom shortcuts created yet")
                            .foregroundColor(.secondary)
                            .italic()
                    }
                    
                    Button(action: { showingAddShortcut = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.blue)
                            Text("Create Custom Shortcut")
                                .fontWeight(.medium)
                        }
                    }
                    .padding(.top, 8)
                }
                
                Section("Quick Actions") {
                    QuickActionCard(
                        title: "Add Task",
                        subtitle: "Quickly add a new task",
                        icon: "plus.square",
                        action: {
                            donateShortcut(for: .addTask)
                        }
                    )
                    
                    QuickActionCard(
                        title: "Log Progress",
                        subtitle: "Update your life tracker",
                        icon: "chart.bar.fill",
                        action: {
                            donateShortcut(for: .logProgress)
                        }
                    )
                    
                    QuickActionCard(
                        title: "Today's Schedule",
                        subtitle: "Check your daily schedule",
                        icon: "calendar",
                        action: {
                            donateShortcut(for: .todaySchedule)
                        }
                    )
                }
                
                Section("Voice Commands Guide") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Try saying:")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            VoiceCommandExample(
                                phrase: "Hey Siri, add task to AreaBook",
                                description: "Opens task creation"
                            )
                            
                            VoiceCommandExample(
                                phrase: "Hey Siri, log task success",
                                description: "Marks a task as complete"
                            )
                            
                            VoiceCommandExample(
                                phrase: "Hey Siri, update my progress",
                                description: "Updates life tracker progress"
                            )
                            
                            VoiceCommandExample(
                                phrase: "Hey Siri, what's my schedule today",
                                description: "Shows today's events"
                            )
                            
                            VoiceCommandExample(
                                phrase: "Hey Siri, review my life trackers",
                                description: "Shows weekly progress"
                            )
                        }
                    }
                }
                
                Section("Tips") {
                    VStack(alignment: .leading, spacing: 8) {
                        TipCard(
                            icon: "mic.fill",
                            title: "Clear Speech",
                            description: "Speak clearly and at a normal pace for best recognition"
                        )
                        
                        TipCard(
                            icon: "gear",
                            title: "Customize Phrases",
                            description: "Create custom shortcuts with your preferred phrases"
                        )
                        
                        TipCard(
                            icon: "hand.raised.fill",
                            title: "Privacy",
                            description: "Voice commands are processed locally and securely"
                        )
                    }
                }
                }
            }
            .navigationTitle("Siri Integration")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checkSiriStatus()
        }
        .sheet(isPresented: $showingAddShortcut) {
            CreateShortcutView { shortcut in
                createCustomShortcut(shortcut)
            }
            }
        .sheet(isPresented: $showingShortcutDetail) {
            if let shortcut = selectedShortcut {
                ShortcutDetailView(shortcut: shortcut)
                }
            }
    }
    
    private func checkSiriStatus() {
        // Check if Siri is available and enabled
        isSiriEnabled = siriManager.isSiriAvailable()
    }
    
    private func toggleSiriIntegration(enabled: Bool) {
        if enabled {
            siriManager.requestSiriPermission { granted in
                DispatchQueue.main.async {
                    isSiriEnabled = granted
                }
            }
        }
    }
    
    private func toggleShortcut(command: SiriCommand, enabled: Bool) {
        if enabled {
            siriManager.enableShortcut(for: command)
        } else {
            siriManager.disableShortcut(for: command)
        }
    }
    
    private func donateShortcut(for command: SiriCommand) {
        siriManager.donateShortcut(for: command)
    }
    
    private func createCustomShortcut(_ shortcut: SiriShortcut) {
        siriManager.createCustomShortcut(shortcut)
    }
    
    private func deleteUserShortcut(_ shortcut: SiriShortcut) {
        siriManager.deleteCustomShortcut(shortcut)
    }
}

// MARK: - Supporting Views

struct SiriCommandCard: View {
    let command: SiriCommand
    let isEnabled: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(command.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(command.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            
                Text("Voice phrase: \"\(command.voicePhrase)\"")
                .font(.caption)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { isEnabled },
                set: { onToggle($0) }
            ))
        }
        .padding(.vertical, 4)
    }
}

struct UserShortcutCard: View {
    let shortcut: SiriShortcut
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(shortcut.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(shortcut.voicePhrase)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Created \(shortcut.createdAt, style: .relative)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .padding(.vertical, 4)
    }
}

struct QuickActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.vertical, 4)
    }
}

struct VoiceCommandExample: View {
    let phrase: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(phrase)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.blue)
            
            Text(description)
                            .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}

struct TipCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                .font(.subheadline)
                    .fontWeight(.semibold)
            
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct CreateShortcutView: View {
    @Environment(\.dismiss) private var dismiss
    let onCreate: (SiriShortcut) -> Void
    
    @State private var title = ""
    @State private var voicePhrase = ""
    @State private var actionType: ShortcutActionType = .addTask
    @State private var customParameters: [String: String] = [:]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Shortcut Details") {
                    TextField("Title", text: $title)
                    TextField("Voice Phrase", text: $voicePhrase)
                }
                
                Section("Action Type") {
                    Picker("Action", selection: $actionType) {
                        ForEach(ShortcutActionType.allCases, id: \.self) { action in
                            Text(action.displayName).tag(action)
                }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                if actionType == .custom {
                    Section("Custom Parameters") {
                        ForEach(Array(customParameters.keys), id: \.self) { key in
                            HStack {
                                Text(key)
                                Spacer()
                                Text(customParameters[key] ?? "")
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Button("Add Parameter") {
                            // Add parameter logic
                        }
                    }
                }
                
                Section("Preview") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Voice Command:")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Hey Siri, \(voicePhrase)")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        
                        Text("Action: \(actionType.displayName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Create Shortcut")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        let shortcut = SiriShortcut(
                            id: UUID().uuidString,
                            title: title,
                            voicePhrase: voicePhrase,
                            actionType: actionType,
                            parameters: customParameters,
                            createdAt: Date()
                        )
                        onCreate(shortcut)
                        dismiss()
                    }
                    .disabled(title.isEmpty || voicePhrase.isEmpty)
                }
            }
        }
    }
}

struct ShortcutDetailView: View {
    let shortcut: SiriShortcut
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Shortcut Information") {
                    DetailRow(title: "Title", value: shortcut.title)
                    DetailRow(title: "Voice Phrase", value: shortcut.voicePhrase)
                    DetailRow(title: "Action", value: shortcut.actionType.displayName)
                    DetailRow(title: "Created", value: shortcut.createdAt, style: .date)
                }
                
                if !shortcut.parameters.isEmpty {
                    Section("Parameters") {
                        ForEach(Array(shortcut.parameters.keys), id: \.self) { key in
                            DetailRow(title: key, value: shortcut.parameters[key] ?? "")
                }
                    }
                }
                
                Section("Usage") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("To use this shortcut:")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                        Text("1. Say \"Hey Siri, \(shortcut.voicePhrase)\"")
                        Text("2. Siri will execute the \(shortcut.actionType.displayName) action")
                        Text("3. You can also find it in the Shortcuts app")
            }
                }
            }
            .navigationTitle("Shortcut Details")
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

struct DetailRow: View {
    let title: String
    let value: String
    var style: DateFormatter.Style = .none
    
    init(title: String, value: String, style: DateFormatter.Style = .none) {
        self.title = title
        self.value = value
        self.style = style
    }
    
    init(title: String, value: Date, style: DateFormatter.Style = .none) {
        self.title = title
        self.value = value.formatted(date: style, time: style)
        self.style = style
    }
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Supporting Models

struct SiriShortcut: Identifiable, Hashable {
    let id: String
    let title: String
    let voicePhrase: String
    let actionType: ShortcutActionType
    let parameters: [String: String]
    let createdAt: Date
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: SiriShortcut, rhs: SiriShortcut) -> Bool {
        lhs.id == rhs.id
    }
}

enum ShortcutActionType: String, CaseIterable {
    case addTask, logProgress, checkSchedule, reviewProgress, custom
    
    var displayName: String {
        switch self {
        case .addTask: return "Add Task"
        case .logProgress: return "Log Progress"
        case .checkSchedule: return "Check Schedule"
        case .reviewProgress: return "Review Progress"
        case .custom: return "Custom Action"
        }
    }
}

enum SiriCommand: String, CaseIterable {
    case addTask, logProgress, checkSchedule, reviewProgress
    
    var title: String {
        switch self {
        case .addTask: return "Add Task"
        case .logProgress: return "Log Progress"
        case .checkSchedule: return "Check Schedule"
        case .reviewProgress: return "Review Progress"
        }
    }
    
    var description: String {
        switch self {
        case .addTask: return "Quickly add a new task"
        case .logProgress: return "Update your life tracker progress"
        case .checkSchedule: return "View today's schedule"
        case .reviewProgress: return "Review weekly progress"
        }
    }
    
    var voicePhrase: String {
        switch self {
        case .addTask: return "add task to AreaBook"
        case .logProgress: return "log task success"
        case .checkSchedule: return "what's my schedule today"
        case .reviewProgress: return "review my life trackers"
        }
    }
} 