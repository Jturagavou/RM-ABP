import Foundation
import UniformTypeIdentifiers

// MARK: - Data Export Service
class DataExportService {
    static let shared = DataExportService()
    
    private init() {}
    
    // MARK: - Export Functions
    
    func exportAllData(for userId: String, dataManager: DataManager) throws -> URL {
        let exportData = ExportData(
            exportDate: Date(),
            version: "1.0",
            keyIndicators: dataManager.keyIndicators,
            goals: dataManager.goals,
            tasks: dataManager.tasks,
            events: dataManager.events,
            notes: dataManager.notes
        )
        
        let jsonData = try JSONEncoder().encode(exportData)
        return try saveToFile(data: jsonData, filename: "AreaBook_Export_\(Date().exportFilename).json")
    }
    
    func exportGoals(goals: [Goal]) throws -> URL {
        let jsonData = try JSONEncoder().encode(goals)
        return try saveToFile(data: jsonData, filename: "Goals_Export_\(Date().exportFilename).json")
    }
    
    func exportTasks(tasks: [Task]) throws -> URL {
        let jsonData = try JSONEncoder().encode(tasks)
        return try saveToFile(data: jsonData, filename: "Tasks_Export_\(Date().exportFilename).json")
    }
    
    func exportNotes(notes: [Note]) throws -> URL {
        let jsonData = try JSONEncoder().encode(notes)
        return try saveToFile(data: jsonData, filename: "Notes_Export_\(Date().exportFilename).json")
    }
    
    func exportKeyIndicators(keyIndicators: [KeyIndicator]) throws -> URL {
        let jsonData = try JSONEncoder().encode(keyIndicators)
        return try saveToFile(data: jsonData, filename: "KeyIndicators_Export_\(Date().exportFilename).json")
    }
    
    // MARK: - Export to CSV
    
    func exportTasksToCSV(tasks: [Task]) throws -> URL {
        var csvString = "Title,Description,Status,Priority,Due Date,Completed At,Created At\n"
        
        for task in tasks {
            let description = task.description ?? ""
            let dueDate = task.dueDate?.formatted() ?? ""
            let completedAt = task.completedAt?.formatted() ?? ""
            let createdAt = task.createdAt.formatted()
            
            csvString += "\"\(task.title)\",\"\(description)\",\"\(task.status.rawValue)\",\"\(task.priority.rawValue)\",\"\(dueDate)\",\"\(completedAt)\",\"\(createdAt)\"\n"
        }
        
        let data = csvString.data(using: .utf8)!
        return try saveToFile(data: data, filename: "Tasks_Export_\(Date().exportFilename).csv")
    }
    
    func exportGoalsToCSV(goals: [Goal]) throws -> URL {
        var csvString = "Title,Description,Progress,Status,Target Date,Created At\n"
        
        for goal in goals {
            let targetDate = goal.targetDate?.formatted() ?? ""
            let createdAt = goal.createdAt.formatted()
            
            csvString += "\"\(goal.title)\",\"\(goal.description)\",\"\(goal.progress)%\",\"\(goal.status.rawValue)\",\"\(targetDate)\",\"\(createdAt)\"\n"
        }
        
        let data = csvString.data(using: .utf8)!
        return try saveToFile(data: data, filename: "Goals_Export_\(Date().exportFilename).csv")
    }
    
    // MARK: - Import Functions
    
    func importData(from url: URL) throws -> ExportData {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode(ExportData.self, from: data)
    }
    
    func importGoals(from url: URL) throws -> [Goal] {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode([Goal].self, from: data)
    }
    
    func importTasks(from url: URL) throws -> [Task] {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode([Task].self, from: data)
    }
    
    func importNotes(from url: URL) throws -> [Note] {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode([Note].self, from: data)
    }
    
    // MARK: - Export Summary
    
    func generateExportSummary(dataManager: DataManager) -> ExportSummary {
        return ExportSummary(
            totalKeyIndicators: dataManager.keyIndicators.count,
            totalGoals: dataManager.goals.count,
            activeGoals: dataManager.goals.filter { $0.status == .active }.count,
            completedGoals: dataManager.goals.filter { $0.status == .completed }.count,
            totalTasks: dataManager.tasks.count,
            completedTasks: dataManager.tasks.filter { $0.status == .completed }.count,
            totalEvents: dataManager.events.count,
            totalNotes: dataManager.notes.count,
            exportDate: Date()
        )
    }
    
    // MARK: - Helper Functions
    
    private func saveToFile(data: Data, filename: String) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)
        
        try data.write(to: fileURL)
        return fileURL
    }
}

// MARK: - Export Data Models

struct ExportData: Codable {
    let exportDate: Date
    let version: String
    let keyIndicators: [KeyIndicator]
    let goals: [Goal]
    let tasks: [Task]
    let events: [CalendarEvent]
    let notes: [Note]
}

struct ExportSummary {
    let totalKeyIndicators: Int
    let totalGoals: Int
    let activeGoals: Int
    let completedGoals: Int
    let totalTasks: Int
    let completedTasks: Int
    let totalEvents: Int
    let totalNotes: Int
    let exportDate: Date
}

// MARK: - User Preferences
struct UserPreferences: Codable {
    var theme: String = "system"
    var notifications: Bool = true
    var widgetUpdateFrequency: Int = 30
    var defaultPriority: String = "medium"
    var weekStartsOn: Int = 0 // 0 = Sunday
    var timeFormat: String = "12hour"
    var dateFormat: String = "short"
    var encouragementMessages: Bool = true
    var soundEnabled: Bool = true
    var hapticFeedback: Bool = true
    
    static var current: UserPreferences {
        get {
            guard let data = UserDefaults.standard.data(forKey: "user_preferences"),
                  let preferences = try? JSONDecoder().decode(UserPreferences.self, from: data) else {
                return UserPreferences()
            }
            return preferences
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            UserDefaults.standard.set(data, forKey: "user_preferences")
        }
    }
}

// MARK: - Data Export/Import View
struct DataExportImportView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var exportService = DataExportService.shared
    
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var showingExportOptions = false
    @State private var showingImportPicker = false
    @State private var exportSummary: ExportSummary?
    @State private var exportMessage = ""
    @State private var showingShareSheet = false
    @State private var shareItems: [Any] = []
    
    var body: some View {
        NavigationView {
            List {
                // Export Section
                Section("Export Data") {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.blue)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Export All Data")
                                .font(.headline)
                            Text("Create a backup of all your spiritual progress data")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("Export") {
                            showingExportOptions = true
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isExporting)
                    }
                    .padding(.vertical, 8)
                    
                    if let summary = exportSummary {
                        ExportSummaryView(summary: summary)
                    }
                    
                    if !exportMessage.isEmpty {
                        Text(exportMessage)
                            .font(.caption)
                            .foregroundColor(.green)
                            .padding(.top, 4)
                    }
                }
                
                // Import Section
                Section("Import Data") {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                            .foregroundColor(.green)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Import Data")
                                .font(.headline)
                            Text("Restore data from a previous backup")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("Import") {
                            showingImportPicker = true
                        }
                        .buttonStyle(.bordered)
                        .disabled(isImporting)
                    }
                    .padding(.vertical, 8)
                    
                    Text("⚠️ Importing will replace your current data. Make sure to export first if you want to keep your current progress.")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.top, 4)
                }
                
                // Data Statistics
                Section("Current Data") {
                    DataStatisticsView(dataManager: dataManager)
                }
                
                // Advanced Options
                Section("Advanced") {
                    Button("Clear All Data") {
                        // Show confirmation alert
                    }
                    .foregroundColor(.red)
                    
                    Button("Reset App Settings") {
                        UserPreferences.current = UserPreferences()
                    }
                    .foregroundColor(.orange)
                }
            }
            .navigationTitle("Data Management")
            .navigationBarTitleDisplayMode(.large)
            .confirmationDialog("Export Format", isPresented: $showingExportOptions) {
                Button("JSON (Complete)") {
                    exportData(format: .json)
                }
                Button("CSV (Spreadsheet)") {
                    exportData(format: .csv)
                }
                Button("Both Formats") {
                    exportData(format: .both)
                }
                Button("Cancel", role: .cancel) { }
            }
            .fileImporter(
                isPresented: $showingImportPicker,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result: result)
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(items: shareItems)
            }
            .overlay {
                if isExporting || isImporting {
                    ProgressView(isExporting ? "Exporting..." : "Importing...")
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .shadow(radius: 4)
                }
            }
        }
    }
    
    private func exportData(format: ExportFormat) {
        Task {
            guard let userId = authViewModel.currentUser?.id else { return }
            
            isExporting = true
            exportMessage = ""
            
            do {
                let exportData = try await exportService.exportAllData(from: userId, dataManager: dataManager)
                exportSummary = exportData.summary
                
                switch format {
                case .json:
                    let jsonData = try exportService.exportToJSON(data: exportData)
                    let url = try exportService.saveToFile(data: jsonData, filename: "AreaBook_Export_\(Date().exportFilename).json")
                    shareItems = [url]
                    
                case .csv:
                    let csvFiles = try exportService.exportToCSV(data: exportData)
                    let folderURL = try exportService.saveToFile(data: csvFiles, filename: "AreaBook_Export_\(Date().exportFilename).csv")
                    shareItems = [folderURL]
                    
                case .both:
                    let jsonData = try exportService.exportToJSON(data: exportData)
                    let csvFiles = try exportService.exportToCSV(data: exportData)
                    
                    let jsonURL = try exportService.saveToFile(data: jsonData, filename: "AreaBook_Export_\(Date().exportFilename).json")
                    let csvFolderURL = try exportService.saveToFile(data: csvFiles, filename: "AreaBook_Export_\(Date().exportFilename).csv")
                    
                    shareItems = [jsonURL, csvFolderURL]
                }
                
                exportMessage = "Export completed successfully!"
                showingShareSheet = true
                
            } catch {
                exportMessage = "Export failed: \(error.localizedDescription)"
            }
            
            isExporting = false
        }
    }
    
    private func handleImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            importData(from: url)
        case .failure(let error):
            exportMessage = "Import failed: \(error.localizedDescription)"
        }
    }
    
    private func importData(from url: URL) {
        Task {
            guard let userId = authViewModel.currentUser?.id else { return }
            
            isImporting = true
            exportMessage = ""
            
            do {
                let data = try Data(contentsOf: url)
                let importData = try exportService.importFromJSON(data: data)
                
                // Clear existing data (with user confirmation in real app)
                // dataManager.clearAllData(userId: userId)
                
                try await exportService.importData(importData, to: dataManager, userId: userId)
                exportMessage = "Import completed successfully!"
                
            } catch {
                exportMessage = "Import failed: \(error.localizedDescription)"
            }
            
            isImporting = false
        }
    }
}

enum ExportFormat {
    case json
    case csv
    case both
}

// MARK: - Supporting Views
struct ExportSummaryView: View {
    let summary: ExportSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Last Export Summary")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            HStack {
                Text("Export Date:")
                Spacer()
                Text(summary.exportDate, style: .date)
            }
            .font(.caption)
            
            HStack {
                Text("Total Items:")
                Spacer()
                Text("\(summary.totalItems)")
            }
            .font(.caption)
            
            VStack(alignment: .leading, spacing: 2) {
                DataCount(label: "Key Indicators", count: summary.keyIndicatorCount)
                DataCount(label: "Goals", count: summary.goalCount)
                DataCount(label: "Events", count: summary.eventCount)
                DataCount(label: "Tasks", count: summary.taskCount)
                DataCount(label: "Notes", count: summary.noteCount)
                DataCount(label: "Groups", count: summary.groupCount)
            }
            .font(.caption2)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
}

struct DataCount: View {
    let label: String
    let count: Int
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text("\(count)")
        }
    }
}

struct DataStatisticsView: View {
    let dataManager: DataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Current Data Summary")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                StatCard(title: "Key Indicators", count: dataManager.keyIndicators.count, color: .blue)
                StatCard(title: "Goals", count: dataManager.goals.count, color: .green)
                StatCard(title: "Events", count: dataManager.events.count, color: .orange)
                StatCard(title: "Tasks", count: dataManager.tasks.count, color: .purple)
                StatCard(title: "Notes", count: dataManager.notes.count, color: .indigo)
                StatCard(title: "Groups", count: dataManager.accountabilityGroups.count, color: .pink)
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Date Extension
extension Date {
    var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }
    
    var exportFilename: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm"
        return formatter.string(from: self)
    }
}

#Preview {
    DataExportImportView()
        .environmentObject(DataManager.shared)
        .environmentObject(AuthViewModel())
}