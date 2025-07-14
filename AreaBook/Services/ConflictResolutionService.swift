import Foundation
import Firebase
import Combine

class ConflictResolutionService: ObservableObject {
    static let shared = ConflictResolutionService()
    
    @Published var activeConflicts: [DataConflict] = []
    @Published var resolvedConflicts: [DataConflict] = []
    @Published var isProcessing = false
    @Published var errorMessage = ""
    @Published var showError = false
    
    private let db = Firestore.firestore()
    private var listeners: [ListenerRegistration] = []
    private var cancellables = Set<AnyCancellable>()
    
    // Conflict resolution strategies
    private var defaultStrategies: [String: ConflictResolutionStrategy] = [
        "Goal": .merge,
        "Task": .useLocal,
        "CalendarEvent": .useLocal,
        "KeyIndicator": .merge,
        "Note": .merge,
        "AccountabilityGroup": .manual
    ]
    
    private init() {
        setupConflictListeners()
    }
    
    // MARK: - Conflict Detection
    
    func detectConflicts(localData: [String: Any], serverData: [String: Any], entityType: String, entityId: String) -> DataConflict? {
        // Check timestamps
        let localTimestamp = localData["updatedAt"] as? Timestamp
        let serverTimestamp = serverData["updatedAt"] as? Timestamp
        
        guard let localTS = localTimestamp, let serverTS = serverTimestamp else {
            return nil
        }
        
        // If server is newer and different, we have a conflict
        if serverTS.seconds > localTS.seconds {
            let conflictType = determineConflictType(localData: localData, serverData: serverData)
            
            return DataConflict(
                entityType: entityType,
                entityId: entityId,
                localVersion: localData,
                serverVersion: serverData,
                conflictType: conflictType
            )
        }
        
        return nil
    }
    
    private func determineConflictType(localData: [String: Any], serverData: [String: Any]) -> ConflictType {
        // Check for deletions
        let localDeleted = localData["deleted"] as? Bool ?? false
        let serverDeleted = serverData["deleted"] as? Bool ?? false
        
        if localDeleted != serverDeleted {
            return .delete
        }
        
        // Check for creation conflicts
        let localCreated = localData["createdAt"] as? Timestamp
        let serverCreated = serverData["createdAt"] as? Timestamp
        
        if localCreated?.seconds != serverCreated?.seconds {
            return .create
        }
        
        // Default to update conflict
        return .update
    }
    
    // MARK: - Conflict Resolution
    
    func resolveConflict(_ conflict: DataConflict, strategy: ConflictResolutionStrategy, userId: String) async throws {
        isProcessing = true
        
        do {
            switch strategy {
            case .useLocal:
                try await resolveWithLocalVersion(conflict, userId: userId)
            case .useServer:
                try await resolveWithServerVersion(conflict, userId: userId)
            case .merge:
                try await resolveWithMerge(conflict, userId: userId)
            case .manual:
                // Manual resolution requires user intervention
                break
            }
            
            // Update conflict status
            var resolvedConflict = conflict
            resolvedConflict.resolvedAt = Date()
            resolvedConflict.resolutionStrategy = strategy
            resolvedConflict.resolvedBy = userId
            
            await updateConflictStatus(resolvedConflict)
            
        } catch {
            showError("Failed to resolve conflict: \(error.localizedDescription)")
            throw error
        }
        
        isProcessing = false
    }
    
    private func resolveWithLocalVersion(_ conflict: DataConflict, userId: String) async throws {
        // Use local version - overwrite server
        let entityRef = getEntityReference(conflict.entityType, entityId: conflict.entityId, userId: userId)
        
        try await entityRef.setData(conflict.localVersion, merge: false)
        
        // Log resolution
        try await logConflictResolution(conflict, strategy: .useLocal, userId: userId)
    }
    
    private func resolveWithServerVersion(_ conflict: DataConflict, userId: String) async throws {
        // Use server version - update local
        let entityRef = getEntityReference(conflict.entityType, entityId: conflict.entityId, userId: userId)
        
        try await entityRef.setData(conflict.serverVersion, merge: false)
        
        // Update local cache/state
        await updateLocalData(conflict.entityType, entityId: conflict.entityId, data: conflict.serverVersion)
        
        // Log resolution
        try await logConflictResolution(conflict, strategy: .useServer, userId: userId)
    }
    
    private func resolveWithMerge(_ conflict: DataConflict, userId: String) async throws {
        // Merge strategies based on entity type
        let mergedData = try await performMerge(conflict)
        
        let entityRef = getEntityReference(conflict.entityType, entityId: conflict.entityId, userId: userId)
        
        try await entityRef.setData(mergedData, merge: false)
        
        // Update local cache/state
        await updateLocalData(conflict.entityType, entityId: conflict.entityId, data: mergedData)
        
        // Log resolution
        try await logConflictResolution(conflict, strategy: .merge, userId: userId)
    }
    
    private func performMerge(_ conflict: DataConflict) async throws -> [String: Any] {
        var mergedData = conflict.serverVersion
        
        switch conflict.entityType {
        case "Goal":
            mergedData = try await mergeGoalData(conflict.localVersion, conflict.serverVersion)
        case "Task":
            mergedData = try await mergeTaskData(conflict.localVersion, conflict.serverVersion)
        case "KeyIndicator":
            mergedData = try await mergeKeyIndicatorData(conflict.localVersion, conflict.serverVersion)
        case "Note":
            mergedData = try await mergeNoteData(conflict.localVersion, conflict.serverVersion)
        case "CalendarEvent":
            mergedData = try await mergeEventData(conflict.localVersion, conflict.serverVersion)
        default:
            // Default merge - use server version with local timestamps
            mergedData["updatedAt"] = conflict.localVersion["updatedAt"]
        }
        
        return mergedData
    }
    
    // MARK: - Entity-Specific Merge Strategies
    
    private func mergeGoalData(_ localData: [String: Any], _ serverData: [String: Any]) async throws -> [String: Any] {
        var merged = serverData
        
        // Merge sticky notes (combine both versions)
        let localStickyNotes = localData["stickyNotes"] as? [[String: Any]] ?? []
        let serverStickyNotes = serverData["stickyNotes"] as? [[String: Any]] ?? []
        
        var combinedStickyNotes = serverStickyNotes
        for localNote in localStickyNotes {
            let noteId = localNote["id"] as? String ?? ""
            let exists = serverStickyNotes.contains { ($0["id"] as? String) == noteId }
            if !exists {
                combinedStickyNotes.append(localNote)
            }
        }
        
        merged["stickyNotes"] = combinedStickyNotes
        
        // Merge progress - use higher value
        let localProgress = localData["progress"] as? Int ?? 0
        let serverProgress = serverData["progress"] as? Int ?? 0
        merged["progress"] = max(localProgress, serverProgress)
        
        // Merge key indicator IDs
        let localKIIds = localData["keyIndicatorIds"] as? [String] ?? []
        let serverKIIds = serverData["keyIndicatorIds"] as? [String] ?? []
        let combinedKIIds = Array(Set(localKIIds + serverKIIds))
        merged["keyIndicatorIds"] = combinedKIIds
        
        return merged
    }
    
    private func mergeTaskData(_ localData: [String: Any], _ serverData: [String: Any]) async throws -> [String: Any] {
        var merged = serverData
        
        // Merge subtasks
        let localSubtasks = localData["subtasks"] as? [[String: Any]] ?? []
        let serverSubtasks = serverData["subtasks"] as? [[String: Any]] ?? []
        
        var combinedSubtasks = serverSubtasks
        for localSubtask in localSubtasks {
            let subtaskId = localSubtask["id"] as? String ?? ""
            let exists = serverSubtasks.contains { ($0["id"] as? String) == subtaskId }
            if !exists {
                combinedSubtasks.append(localSubtask)
            }
        }
        
        merged["subtasks"] = combinedSubtasks
        
        // Status resolution - prioritize completed status
        let localStatus = localData["status"] as? String ?? "pending"
        let serverStatus = serverData["status"] as? String ?? "pending"
        
        if localStatus == "completed" || serverStatus == "completed" {
            merged["status"] = "completed"
            merged["completedAt"] = localData["completedAt"] ?? serverData["completedAt"] ?? Date()
        } else {
            merged["status"] = serverStatus
        }
        
        return merged
    }
    
    private func mergeKeyIndicatorData(_ localData: [String: Any], _ serverData: [String: Any]) async throws -> [String: Any] {
        var merged = serverData
        
        // Merge progress - use higher value
        let localProgress = localData["currentWeekProgress"] as? Int ?? 0
        let serverProgress = serverData["currentWeekProgress"] as? Int ?? 0
        merged["currentWeekProgress"] = max(localProgress, serverProgress)
        
        // Use most recent target
        let localUpdated = localData["updatedAt"] as? Timestamp
        let serverUpdated = serverData["updatedAt"] as? Timestamp
        
        if let localTS = localUpdated, let serverTS = serverUpdated {
            if localTS.seconds > serverTS.seconds {
                merged["weeklyTarget"] = localData["weeklyTarget"]
            }
        }
        
        return merged
    }
    
    private func mergeNoteData(_ localData: [String: Any], _ serverData: [String: Any]) async throws -> [String: Any] {
        var merged = serverData
        
        // Merge content - use longer version (assuming more content is better)
        let localContent = localData["content"] as? String ?? ""
        let serverContent = serverData["content"] as? String ?? ""
        
        if localContent.count > serverContent.count {
            merged["content"] = localContent
        }
        
        // Merge tags
        let localTags = localData["tags"] as? [String] ?? []
        let serverTags = serverData["tags"] as? [String] ?? []
        let combinedTags = Array(Set(localTags + serverTags))
        merged["tags"] = combinedTags
        
        // Merge linked IDs
        let localLinkedGoals = localData["linkedGoalIds"] as? [String] ?? []
        let serverLinkedGoals = serverData["linkedGoalIds"] as? [String] ?? []
        merged["linkedGoalIds"] = Array(Set(localLinkedGoals + serverLinkedGoals))
        
        return merged
    }
    
    private func mergeEventData(_ localData: [String: Any], _ serverData: [String: Any]) async throws -> [String: Any] {
        var merged = serverData
        
        // Merge task IDs
        let localTaskIds = localData["taskIds"] as? [String] ?? []
        let serverTaskIds = serverData["taskIds"] as? [String] ?? []
        merged["taskIds"] = Array(Set(localTaskIds + serverTaskIds))
        
        // Use most recent time if different
        let localUpdated = localData["updatedAt"] as? Timestamp
        let serverUpdated = serverData["updatedAt"] as? Timestamp
        
        if let localTS = localUpdated, let serverTS = serverUpdated {
            if localTS.seconds > serverTS.seconds {
                merged["startTime"] = localData["startTime"]
                merged["endTime"] = localData["endTime"]
            }
        }
        
        return merged
    }
    
    // MARK: - Automatic Conflict Resolution
    
    func autoResolveConflicts(userId: String) async {
        let conflictsToResolve = activeConflicts.filter { conflict in
            let strategy = defaultStrategies[conflict.entityType] ?? .manual
            return strategy != .manual
        }
        
        for conflict in conflictsToResolve {
            let strategy = defaultStrategies[conflict.entityType] ?? .manual
            
            do {
                try await resolveConflict(conflict, strategy: strategy, userId: userId)
            } catch {
                print("Failed to auto-resolve conflict: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Conflict Prevention
    
    func preventConflict(entityType: String, entityId: String, userId: String) async throws {
        // Lock the entity for editing
        let lockRef = db.collection("entityLocks").document("\(entityType)_\(entityId)")
        
        try await lockRef.setData([
            "entityType": entityType,
            "entityId": entityId,
            "lockedBy": userId,
            "lockedAt": Timestamp(date: Date()),
            "expiresAt": Timestamp(date: Date().addingTimeInterval(300)) // 5 minutes
        ])
    }
    
    func releaseConflictLock(entityType: String, entityId: String, userId: String) async throws {
        let lockRef = db.collection("entityLocks").document("\(entityType)_\(entityId)")
        
        try await lockRef.delete()
    }
    
    func isEntityLocked(entityType: String, entityId: String) async throws -> Bool {
        let lockRef = db.collection("entityLocks").document("\(entityType)_\(entityId)")
        let lockDoc = try await lockRef.getDocument()
        
        guard let data = lockDoc.data() else { return false }
        
        let expiresAt = data["expiresAt"] as? Timestamp
        let now = Timestamp(date: Date())
        
        if let expiry = expiresAt, expiry.seconds > now.seconds {
            return true
        } else {
            // Lock expired, remove it
            try await lockRef.delete()
            return false
        }
    }
    
    // MARK: - Collaborative Editing
    
    func startCollaborativeEdit(entityType: String, entityId: String, userId: String) async throws {
        let sessionRef = db.collection("collaborativeSessions").document("\(entityType)_\(entityId)")
        
        let sessionData: [String: Any] = [
            "entityType": entityType,
            "entityId": entityId,
            "activeUsers": [userId],
            "startedAt": Timestamp(date: Date()),
            "lastActivity": Timestamp(date: Date())
        ]
        
        try await sessionRef.setData(sessionData, merge: true)
        
        // Update active users
        try await sessionRef.updateData([
            "activeUsers": FieldValue.arrayUnion([userId]),
            "lastActivity": Timestamp(date: Date())
        ])
    }
    
    func endCollaborativeEdit(entityType: String, entityId: String, userId: String) async throws {
        let sessionRef = db.collection("collaborativeSessions").document("\(entityType)_\(entityId)")
        
        try await sessionRef.updateData([
            "activeUsers": FieldValue.arrayRemove([userId]),
            "lastActivity": Timestamp(date: Date())
        ])
        
        // Check if session should be closed
        let sessionDoc = try await sessionRef.getDocument()
        if let data = sessionDoc.data(),
           let activeUsers = data["activeUsers"] as? [String],
           activeUsers.isEmpty {
            try await sessionRef.delete()
        }
    }
    
    // MARK: - Conflict History and Analytics
    
    func getConflictHistory(userId: String) async throws -> [DataConflict] {
        let snapshot = try await db.collection("users").document(userId)
            .collection("conflictHistory")
            .order(by: "detectedAt", descending: true)
            .limit(to: 100)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: DataConflict.self)
        }
    }
    
    func getConflictAnalytics(userId: String) async throws -> ConflictAnalytics {
        let conflicts = try await getConflictHistory(userId: userId)
        
        let totalConflicts = conflicts.count
        let resolvedConflicts = conflicts.filter { $0.resolvedAt != nil }.count
        let averageResolutionTime = conflicts.compactMap { conflict in
            guard let resolvedAt = conflict.resolvedAt else { return nil }
            return resolvedAt.timeIntervalSince(conflict.detectedAt)
        }.reduce(0, +) / Double(resolvedConflicts)
        
        let entityTypeBreakdown = Dictionary(grouping: conflicts) { $0.entityType }
            .mapValues { $0.count }
        
        let strategyBreakdown = Dictionary(grouping: conflicts.compactMap { $0.resolutionStrategy }) { $0 }
            .mapValues { $0.count }
        
        return ConflictAnalytics(
            totalConflicts: totalConflicts,
            resolvedConflicts: resolvedConflicts,
            averageResolutionTime: averageResolutionTime,
            entityTypeBreakdown: entityTypeBreakdown,
            strategyBreakdown: strategyBreakdown
        )
    }
    
    // MARK: - Helper Methods
    
    private func setupConflictListeners() {
        // Listen for conflicts in real-time
        // This would be implemented based on your specific needs
    }
    
    private func getEntityReference(_ entityType: String, entityId: String, userId: String) -> DocumentReference {
        let collectionName = entityType.lowercased() + "s"
        return db.collection("users").document(userId).collection(collectionName).document(entityId)
    }
    
    private func updateLocalData(_ entityType: String, entityId: String, data: [String: Any]) async {
        // Update local cache/state management
        // This would integrate with your existing DataManager
    }
    
    private func updateConflictStatus(_ conflict: DataConflict) async {
        // Remove from active conflicts
        activeConflicts.removeAll { $0.id == conflict.id }
        
        // Add to resolved conflicts
        resolvedConflicts.append(conflict)
    }
    
    private func logConflictResolution(_ conflict: DataConflict, strategy: ConflictResolutionStrategy, userId: String) async throws {
        let logRef = db.collection("users").document(userId).collection("conflictHistory").document(conflict.id)
        
        var logData = conflict
        logData.resolutionStrategy = strategy
        logData.resolvedAt = Date()
        logData.resolvedBy = userId
        
        try await logRef.setData(from: logData)
    }
    
    private func showError(_ message: String) {
        DispatchQueue.main.async {
            self.errorMessage = message
            self.showError = true
        }
    }
}

// MARK: - Supporting Types

struct ConflictAnalytics: Codable {
    var totalConflicts: Int
    var resolvedConflicts: Int
    var averageResolutionTime: Double
    var entityTypeBreakdown: [String: Int]
    var strategyBreakdown: [ConflictResolutionStrategy: Int]
}

enum ConflictResolutionError: Error {
    case conflictNotFound
    case strategyNotSupported
    case mergeError(String)
    case lockingError(String)
    case unauthorizedAccess
}