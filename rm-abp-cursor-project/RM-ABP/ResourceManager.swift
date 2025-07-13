import SwiftUI
import Foundation

// MARK: - Resource Model
struct Resource: Identifiable, Codable {
    let id = UUID()
    var name: String
    var type: ResourceType
    var status: ResourceStatus
    var capacity: Double
    var currentLoad: Double
    var allocatedTo: [UUID] = [] // Agent IDs
    let createdAt: Date = Date()
    
    var utilizationPercentage: Double {
        guard capacity > 0 else { return 0 }
        return (currentLoad / capacity) * 100
    }
    
    var availableCapacity: Double {
        return max(0, capacity - currentLoad)
    }
    
    enum ResourceType: String, CaseIterable, Codable {
        case computational = "Computational"
        case storage = "Storage"
        case network = "Network"
        case memory = "Memory"
        
        var icon: String {
            switch self {
            case .computational: return "cpu"
            case .storage: return "externaldrive"
            case .network: return "wifi"
            case .memory: return "memorychip"
            }
        }
        
        var color: Color {
            switch self {
            case .computational: return .blue
            case .storage: return .green
            case .network: return .orange
            case .memory: return .purple
            }
        }
        
        var unit: String {
            switch self {
            case .computational: return "GHz"
            case .storage: return "GB"
            case .network: return "Mbps"
            case .memory: return "GB"
            }
        }
    }
    
    enum ResourceStatus: String, CaseIterable, Codable {
        case available = "Available"
        case busy = "Busy"
        case maintenance = "Maintenance"
        case offline = "Offline"
        
        var color: Color {
            switch self {
            case .available: return .green
            case .busy: return .yellow
            case .maintenance: return .orange
            case .offline: return .red
            }
        }
    }
}

// MARK: - Resource Manager
class ResourceManager: ObservableObject {
    @Published var resources: [Resource] = []
    @Published var selectedResource: Resource?
    @Published var showingAddResource = false
    
    init() {
        // Initialize with sample resources
        addSampleResources()
    }
    
    func addSampleResources() {
        let sampleResources = [
            Resource(
                name: "CPU Cluster A",
                type: .computational,
                status: .available,
                capacity: 100.0,
                currentLoad: 25.0
            ),
            Resource(
                name: "Storage Node 1",
                type: .storage,
                status: .available,
                capacity: 1000.0,
                currentLoad: 450.0
            ),
            Resource(
                name: "Memory Bank 1",
                type: .memory,
                status: .busy,
                capacity: 64.0,
                currentLoad: 48.0
            ),
            Resource(
                name: "Network Switch",
                type: .network,
                status: .available,
                capacity: 1000.0,
                currentLoad: 120.0
            )
        ]
        
        resources.append(contentsOf: sampleResources)
    }
    
    func addResource(name: String, type: Resource.ResourceType, capacity: Double) {
        let newResource = Resource(
            name: name,
            type: type,
            status: .available,
            capacity: capacity,
            currentLoad: 0.0
        )
        resources.append(newResource)
    }
    
    func removeResource(_ resource: Resource) {
        resources.removeAll { $0.id == resource.id }
        if selectedResource?.id == resource.id {
            selectedResource = nil
        }
    }
    
    func updateResourceLoad(_ resource: Resource, load: Double) {
        if let index = resources.firstIndex(where: { $0.id == resource.id }) {
            resources[index].currentLoad = min(load, resource.capacity)
            updateResourceStatus(resources[index])
        }
    }
    
    func updateResourceStatus(_ resource: Resource, status: Resource.ResourceStatus) {
        if let index = resources.firstIndex(where: { $0.id == resource.id }) {
            resources[index].status = status
        }
    }
    
    private func updateResourceStatus(_ resource: Resource) {
        if let index = resources.firstIndex(where: { $0.id == resource.id }) {
            let utilization = resource.utilizationPercentage
            
            if utilization >= 90 {
                resources[index].status = .busy
            } else if utilization >= 0 {
                resources[index].status = .available
            }
        }
    }
    
    func allocateResource(_ resource: Resource, to agentId: UUID, amount: Double) -> Bool {
        if let index = resources.firstIndex(where: { $0.id == resource.id }) {
            let availableCapacity = resources[index].availableCapacity
            
            if availableCapacity >= amount {
                resources[index].currentLoad += amount
                resources[index].allocatedTo.append(agentId)
                updateResourceStatus(resources[index])
                return true
            }
        }
        return false
    }
    
    func deallocateResource(_ resource: Resource, from agentId: UUID, amount: Double) {
        if let index = resources.firstIndex(where: { $0.id == resource.id }) {
            resources[index].currentLoad = max(0, resources[index].currentLoad - amount)
            resources[index].allocatedTo.removeAll { $0 == agentId }
            updateResourceStatus(resources[index])
        }
    }
    
    func getResourcesByType(_ type: Resource.ResourceType) -> [Resource] {
        return resources.filter { $0.type == type }
    }
    
    func getResourcesByStatus(_ status: Resource.ResourceStatus) -> [Resource] {
        return resources.filter { $0.status == status }
    }
    
    func getAvailableResources() -> [Resource] {
        return resources.filter { $0.status == .available && $0.availableCapacity > 0 }
    }
    
    func getResourcesForAgent(_ agentId: UUID) -> [Resource] {
        return resources.filter { $0.allocatedTo.contains(agentId) }
    }
    
    func getTotalCapacity(for type: Resource.ResourceType) -> Double {
        return getResourcesByType(type).reduce(0) { $0 + $1.capacity }
    }
    
    func getTotalUsage(for type: Resource.ResourceType) -> Double {
        return getResourcesByType(type).reduce(0) { $0 + $1.currentLoad }
    }
    
    func getOverallUtilization() -> Double {
        let totalCapacity = resources.reduce(0) { $0 + $1.capacity }
        let totalUsage = resources.reduce(0) { $0 + $1.currentLoad }
        
        guard totalCapacity > 0 else { return 0 }
        return (totalUsage / totalCapacity) * 100
    }
    
    // MARK: - Simulation Methods
    func simulateResourceUsage() {
        for index in resources.indices {
            // Simulate random fluctuations in resource usage
            let fluctuation = Double.random(in: -5...10)
            let newLoad = max(0, min(resources[index].capacity, resources[index].currentLoad + fluctuation))
            resources[index].currentLoad = newLoad
            updateResourceStatus(resources[index])
        }
    }
    
    func startResourceMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            DispatchQueue.main.async {
                self.simulateResourceUsage()
            }
        }
    }
}