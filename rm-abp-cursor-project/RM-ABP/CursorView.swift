import SwiftUI

// MARK: - Cursor View
struct CursorView: View {
    @EnvironmentObject var agentManager: AgentManager
    @State private var currentPosition: CGPoint = .zero
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background grid
                GridBackground()
                
                // Agent connections
                ForEach(agentManager.agents) { agent in
                    ForEach(agentManager.getConnectedAgents(for: agent), id: \.id) { connectedAgent in
                        ConnectionLine(
                            from: agent.position,
                            to: connectedAgent.position
                        )
                    }
                }
                
                // Agents
                ForEach(agentManager.agents) { agent in
                    AgentNode(agent: agent)
                        .position(agent.position)
                        .scaleEffect(agentManager.selectedAgent?.id == agent.id ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: agentManager.selectedAgent?.id)
                        .onTapGesture {
                            agentManager.selectedAgent = agent
                        }
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    agentManager.startDragging(agent)
                                    let newPosition = CGPoint(
                                        x: max(20, min(geometry.size.width - 20, value.location.x)),
                                        y: max(20, min(geometry.size.height - 20, value.location.y))
                                    )
                                    agentManager.updateAgentPosition(agent, to: newPosition)
                                }
                                .onEnded { _ in
                                    agentManager.endDragging()
                                }
                        )
                }
                
                // Cursor indicator
                CursorIndicator(position: currentPosition)
                    .opacity(0.7)
            }
            .background(Color(.systemGray6))
            .onAppear {
                agentManager.updateCursorPosition(currentPosition)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        currentPosition = value.location
                        agentManager.updateCursorPosition(currentPosition)
                    }
            )
        }
    }
}

// MARK: - Grid Background
struct GridBackground: View {
    let gridSpacing: CGFloat = 30
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                // Vertical lines
                for x in stride(from: 0, through: geometry.size.width, by: gridSpacing) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geometry.size.height))
                }
                
                // Horizontal lines
                for y in stride(from: 0, through: geometry.size.height, by: gridSpacing) {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                }
            }
            .stroke(Color(.systemGray4), lineWidth: 0.5)
        }
    }
}

// MARK: - Agent Node
struct AgentNode: View {
    let agent: Agent
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(agent.type.color.gradient)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .stroke(agent.status.color, lineWidth: 3)
                    )
                    .shadow(color: agent.type.color.opacity(0.3), radius: 5)
                
                Image(systemName: agent.type.icon)
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .bold))
            }
            .scaleEffect(isAnimating ? 1.1 : 1.0)
            .animation(
                Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                if agent.status == .active {
                    isAnimating = true
                }
            }
            .onChange(of: agent.status) { _, newStatus in
                isAnimating = newStatus == .active
            }
            
            Text(agent.name)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color(.systemBackground).opacity(0.9))
                .cornerRadius(8)
        }
    }
}

// MARK: - Connection Line
struct ConnectionLine: View {
    let from: CGPoint
    let to: CGPoint
    
    var body: some View {
        Path { path in
            path.move(to: from)
            path.addLine(to: to)
        }
        .stroke(
            LinearGradient(
                colors: [Color.blue.opacity(0.6), Color.blue.opacity(0.2)],
                startPoint: .leading,
                endPoint: .trailing
            ),
            style: StrokeStyle(lineWidth: 2, dash: [5, 3])
        )
        .animation(.easeInOut(duration: 0.3), value: from)
        .animation(.easeInOut(duration: 0.3), value: to)
    }
}

// MARK: - Cursor Indicator
struct CursorIndicator: View {
    let position: CGPoint
    @State private var pulseAnimation = false
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 20, height: 20)
                .scaleEffect(pulseAnimation ? 1.5 : 1.0)
                .opacity(pulseAnimation ? 0.0 : 1.0)
                .animation(
                    Animation.easeOut(duration: 1.0).repeatForever(autoreverses: false),
                    value: pulseAnimation
                )
            
            Circle()
                .fill(Color.blue)
                .frame(width: 8, height: 8)
            
            Circle()
                .stroke(Color.white, lineWidth: 2)
                .frame(width: 8, height: 8)
        }
        .position(position)
        .onAppear {
            pulseAnimation = true
        }
    }
}

// MARK: - Agent Workspace Canvas
struct AgentWorkspaceCanvas: View {
    @EnvironmentObject var agentManager: AgentManager
    @State private var showingAddAgent = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Text("Agent Workspace")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                    showingAddAgent = true
                }) {
                    Label("Add Agent", systemImage: "plus.circle.fill")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                
                Button(action: {
                    agentManager.selectedAgent = nil
                }) {
                    Label("Clear Selection", systemImage: "xmark.circle")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            
            // Canvas
            CursorView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .sheet(isPresented: $showingAddAgent) {
            AddAgentView()
        }
    }
}

// MARK: - Add Agent View
struct AddAgentView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var agentManager: AgentManager
    @State private var agentName = ""
    @State private var selectedType: Agent.AgentType = .worker
    
    var body: some View {
        NavigationView {
            Form {
                Section("Agent Details") {
                    TextField("Agent Name", text: $agentName)
                    
                    Picker("Type", selection: $selectedType) {
                        ForEach(Agent.AgentType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                }
                
                Section("Preview") {
                    HStack {
                        Image(systemName: selectedType.icon)
                            .foregroundColor(selectedType.color)
                            .font(.title2)
                        
                        VStack(alignment: .leading) {
                            Text(agentName.isEmpty ? "New Agent" : agentName)
                                .font(.headline)
                            Text(selectedType.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
            .navigationTitle("Add Agent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        agentManager.addAgent(
                            name: agentName.isEmpty ? "Agent-\(agentManager.agents.count + 1)" : agentName,
                            type: selectedType
                        )
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    CursorView()
        .environmentObject(AgentManager())
}