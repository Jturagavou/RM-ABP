import Foundation
import SwiftUI

// MARK: - Data Export Service
class DataExportService: ObservableObject {
    static let shared = DataExportService()
    
    private init() {}
    
    // MARK: - Export Methods
    func exportAllData(from dataManager: DataManager, userId: String) async throws -> ExportData {
        let exportData = ExportData(
            userId: userId,
            exportDate: Date(),
            keyIndicators: dataManager.keyIndicators,
            goals: dataManager.goals,
            tasks: dataManager.tasks,
            events: dataManager.events,
            notes: dataManager.notes,
            groups: dataManager.accountabilityGroups
        )
        
        return exportData
    }
    
    func exportToJSON(data: ExportData) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        return try encoder.encode(data)
    }
    
    func exportToCSV(data: ExportData) throws -> [String: Data] {
        var csvFiles: [String: Data] = [:]
        
        // Key Indicators CSV
        csvFiles["key_indicators.csv"] = try createKeyIndicatorsCSV(data.keyIndicators)
        
        // Goals CSV
        csvFiles["goals.csv"] = try createGoalsCSV(data.goals)
        
        // Events CSV
        csvFiles["events.csv"] = try createEventsCSV(data.events)
        
        // Tasks CSV
        csvFiles["tasks.csv"] = try createTasksCSV(data.tasks)
        
        // Notes CSV
        csvFiles["notes.csv"] = try createNotesCSV(data.notes)
        
        return csvFiles
    }
    
    // MARK: - Import Methods
    func importFromJSON(data: Data) throws -> ExportData {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ExportData.self, from: data)
    }
    
    func importData(_ importData: ExportData, to dataManager: DataManager, userId: String) async throws {
        // Import Key Indicators
        for ki in importData.keyIndicators {
            dataManager.createKeyIndicator(ki, userId: userId)
        }
        
        // Import Goals
        for goal in importData.goals {
            dataManager.createGoal(goal, userId: userId)
        }
        
        // Import Events
        for event in importData.events {
            dataManager.createEvent(event, userId: userId)
        }
        
        // Import Tasks
        for task in importData.tasks {
            dataManager.createTask(task, userId: userId)
        }
        
        // Import Notes
        for note in importData.notes {
            dataManager.createNote(note, userId: userId)
        }
        
        // Import Accountability Groups
        for group in importData.groups {
            dataManager.createAccountabilityGroup(group)
        }
    }
    
    // MARK: - CSV Creation Methods
    private func createKeyIndicatorsCSV(_ keyIndicators: [KeyIndicator]) throws -> Data {
        var csvContent = "Name,Weekly Target,Current Progress,Unit,Color,Created Date,Updated Date\n"
        
        for ki in keyIndicators {
            let row = "\"\(ki.name)\",\(ki.weeklyTarget),\(ki.currentWeekProgress),\"\(ki.unit)\",\"\(ki.color)\",\(ki.createdAt.iso8601String),\(ki.updatedAt.iso8601String)\n"
            csvContent += row
        }
        
        return csvContent.data(using: .utf8) ?? Data()
    }
    
    private func createGoalsCSV(_ goals: [Goal]) throws -> Data {
        var csvContent = "Title,Description,Status,Progress,Target Date,Created Date,Updated Date\n"
        
        for goal in goals {
            let targetDateString = goal.targetDate?.iso8601String ?? ""
            let row = "\"\(goal.title)\",\"\(goal.description)\",\"\(goal.status.rawValue)\",\(goal.progress),\"\(targetDateString)\",\(goal.createdAt.iso8601String),\(goal.updatedAt.iso8601String)\n"
            csvContent += row
        }
        
        return csvContent.data(using: .utf8) ?? Data()
    }
    
    private func createEventsCSV(_ events: [CalendarEvent]) throws -> Data {
        var csvContent = "Title,Description,Category,Start Time,End Time,Is Recurring,Created Date,Updated Date\n"
        
        for event in events {
            let row = "\"\(event.title)\",\"\(event.description)\",\"\(event.category)\",\(event.startTime.iso8601String),\(event.endTime.iso8601String),\(event.isRecurring),\(event.createdAt.iso8601String),\(event.updatedAt.iso8601String)\n"
            csvContent += row
        }
        
        return csvContent.data(using: .utf8) ?? Data()
    }
    
    private func createTasksCSV(_ tasks: [AppTask]) throws -> Data {
        var csvContent = "Title,Description,Status,Priority,Due Date,Created Date,Updated Date,Completed Date\n"
        
        for task in tasks {
            let description = task.description ?? ""
            let dueDateString = task.dueDate?.iso8601String ?? ""
            let completedDateString = task.completedAt?.iso8601String ?? ""
            let row = "\"\(task.title)\",\"\(description)\",\"\(task.status.rawValue)\",\"\(task.priority.rawValue)\",\"\(dueDateString)\",\(task.createdAt.iso8601String),\(task.updatedAt.iso8601String),\"\(completedDateString)\"\n"
            csvContent += row
        }
        
        return csvContent.data(using: .utf8) ?? Data()
    }
    
    private func createNotesCSV(_ notes: [Note]) throws -> Data {
        var csvContent = "Title,Content,Tags,Created Date,Updated Date\n"
        
        for note in notes {
            let tags = note.tags.joined(separator: ";")
            let content = note.content.replacingOccurrences(of: "\n", with: "\\n")
            let row = "\"\(note.title)\",\"\(content)\",\"\(tags)\",\(note.createdAt.iso8601String),\(note.updatedAt.iso8601String)\n"
            csvContent += row
        }
        
        return csvContent.data(using: .utf8) ?? Data()
    }
    
    // MARK: - File Management
    func saveExportedData(_ data: Data, filename: String) throws -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(filename)
        
        try data.write(to: fileURL)
        return fileURL
    }
    
    func saveExportedCSVs(_ csvFiles: [String: Data]) throws -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let timestamp = Date().formatted(.iso8601.day().month().year())
        let folderName = "AreaBook_Export_\(timestamp)"
        let folderURL = documentsPath.appendingPathComponent(folderName)
        
        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        
        for (filename, data) in csvFiles {
            let fileURL = folderURL.appendingPathComponent(filename)
            try data.write(to: fileURL)
        }
        
        return folderURL
    }
}

// MARK: - Export Summary Structure
struct ExportSummary {
    let exportDate: Date
    let keyIndicatorCount: Int
    let goalCount: Int
    let eventCount: Int
    let taskCount: Int
    let noteCount: Int
    let groupCount: Int
    
    var totalItems: Int {
        keyIndicatorCount + goalCount + eventCount + taskCount + noteCount + groupCount
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
                        // Reset settings
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
                ShareSheet(activityItems: shareItems)
            }
        }
    }
    
    private func exportData(format: ExportFormat) {
        Task {
            guard let userId = authViewModel.currentUser?.id else { return }
            
            isExporting = true
            exportMessage = ""
            
            do {
                let exportData = try await exportService.exportAllData(from: dataManager, userId: userId)
                
                // Create summary
                exportSummary = ExportSummary(
                    exportDate: exportData.exportDate,
                    keyIndicatorCount: exportData.keyIndicators.count,
                    goalCount: exportData.goals.count,
                    eventCount: exportData.events.count,
                    taskCount: exportData.tasks.count,
                    noteCount: exportData.notes.count,
                    groupCount: exportData.groups.count
                )
                
                switch format {
                case .json:
                    let jsonData = try exportService.exportToJSON(data: exportData)
                    let url = try exportService.saveExportedData(jsonData, filename: "AreaBook_Export_\(Date().formatted(.iso8601.day().month().year())).json")
                    shareItems = [url]
                    
                case .csv:
                    let csvFiles = try exportService.exportToCSV(data: exportData)
                    let folderURL = try exportService.saveExportedCSVs(csvFiles)
                    shareItems = [folderURL]
                    
                case .both:
                    let jsonData = try exportService.exportToJSON(data: exportData)
                    let csvFiles = try exportService.exportToCSV(data: exportData)
                    
                    let jsonURL = try exportService.saveExportedData(jsonData, filename: "AreaBook_Export_\(Date().formatted(.iso8601.day().month().year())).json")
                    let csvFolderURL = try exportService.saveExportedCSVs(csvFiles)
                    
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

// MARK: - Date Extension
extension Date {
    var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }
}

#Preview {
    DataExportImportView()
        .environmentObject(DataManager.shared)
        .environmentObject(AuthViewModel.shared)
}