import SwiftUI
import Foundation

// MARK: - Agent Model
struct Agent: Identifiable, Codable {
    let id = UUID()
    var name: String
    var type: AgentType
    var status: AgentStatus
    var position: CGPoint
    var connections: [UUID] = []
    let createdAt: Date = Date()
    
    enum AgentType: String, CaseIterable, Codable {
        case worker = "Worker"
        case coordinator = "Coordinator"
        case monitor = "Monitor"
        case analyzer = "Analyzer"
        
        var color: Color {
            switch self {
            case .worker: return .blue
            case .coordinator: return .green
            case .monitor: return .orange
            case .analyzer: return .purple
            }
        }
        
        var icon: String {
            switch self {
            case .worker: return "gear"
            case .coordinator: return "network"
            case .monitor: return "eye"
            case .analyzer: return "chart.bar"
            }
        }
    }
    
    enum AgentStatus: String, CaseIterable, Codable {
        case active = "Active"
        case idle = "Idle"
        case busy = "Busy"
        case offline = "Offline"
        
        var color: Color {
            switch self {
            case .active: return .green
            case .idle: return .yellow
            case .busy: return .red
            case .offline: return .gray
            }
        }
    }
}

// MARK: - Agent Manager
class AgentManager: ObservableObject {
    @Published var agents: [Agent] = []
    @Published var selectedAgent: Agent?
    @Published var cursorPosition: CGPoint = .zero
    @Published var showingAddAgent = false
    
    private var draggedAgent: Agent?
    
    init() {
        // Initialize with some sample agents
        addSampleAgents()
    }
    
    func addSampleAgents() {
        let sampleAgents = [
            Agent(name: "Worker-01", type: .worker, status: .active, position: CGPoint(x: 100, y: 100)),
            Agent(name: "Coordinator-Alpha", type: .coordinator, status: .active, position: CGPoint(x: 200, y: 150)),
            Agent(name: "Monitor-Beta", type: .monitor, status: .idle, position: CGPoint(x: 150, y: 200))
        ]
        
        agents.append(contentsOf: sampleAgents)
    }
    
    func addAgent(name: String, type: Agent.AgentType) {
        let newAgent = Agent(
            name: name,
            type: type,
            status: .active,
            position: CGPoint(
                x: Double.random(in: 50...300),
                y: Double.random(in: 50...300)
            )
        )
        agents.append(newAgent)
    }
    
    func removeAgent(_ agent: Agent) {
        agents.removeAll { $0.id == agent.id }
        if selectedAgent?.id == agent.id {
            selectedAgent = nil
        }
    }
    
    func updateAgentPosition(_ agent: Agent, to position: CGPoint) {
        if let index = agents.firstIndex(where: { $0.id == agent.id }) {
            agents[index].position = position
            updateConnections(for: agents[index])
        }
    }
    
    func updateAgentStatus(_ agent: Agent, status: Agent.AgentStatus) {
        if let index = agents.firstIndex(where: { $0.id == agent.id }) {
            agents[index].status = status
        }
    }
    
    private func updateConnections(for agent: Agent) {
        // Update connections based on proximity
        if let agentIndex = agents.firstIndex(where: { $0.id == agent.id }) {
            var newConnections: [UUID] = []
            
            for otherAgent in agents {
                if otherAgent.id != agent.id {
                    let distance = distanceBetween(agent.position, otherAgent.position)
                    if distance < 100 { // Connection threshold
                        newConnections.append(otherAgent.id)
                    }
                }
            }
            
            agents[agentIndex].connections = newConnections
        }
    }
    
    func updateCursorPosition(_ position: CGPoint) {
        cursorPosition = position
    }
    
    func getConnectedAgents(for agent: Agent) -> [Agent] {
        return agents.filter { agent.connections.contains($0.id) }
    }
    
    func distanceBetween(_ point1: CGPoint, _ point2: CGPoint) -> Double {
        let dx = point1.x - point2.x
        let dy = point1.y - point2.y
        return sqrt(dx * dx + dy * dy)
    }
    
    func getAgentsByType(_ type: Agent.AgentType) -> [Agent] {
        return agents.filter { $0.type == type }
    }
    
    func getAgentsByStatus(_ status: Agent.AgentStatus) -> [Agent] {
        return agents.filter { $0.status == status }
    }
    
    // MARK: - Drag and Drop Support
    func startDragging(_ agent: Agent) {
        draggedAgent = agent
    }
    
    func endDragging() {
        draggedAgent = nil
    }
    
    func isDragging(_ agent: Agent) -> Bool {
        return draggedAgent?.id == agent.id
    }
}