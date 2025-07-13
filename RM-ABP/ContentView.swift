import SwiftUI

struct ContentView: View {
    @EnvironmentObject var agentManager: AgentManager
    @EnvironmentObject var resourceManager: ResourceManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Main Workspace Tab
            NavigationView {
                HSplitView {
                    // Sidebar
                    VStack(spacing: 20) {
                        // Agents Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "person.3.fill")
                                    .foregroundColor(.blue)
                                Text("Agents")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Spacer()
                                Text("\(agentManager.agents.count)")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(8)
                            }
                            
                            ScrollView {
                                LazyVStack(spacing: 8) {
                                    ForEach(agentManager.agents) { agent in
                                        AgentListItem(agent: agent)
                                            .onTapGesture {
                                                agentManager.selectedAgent = agent
                                            }
                                    }
                                }
                            }
                            .frame(maxHeight: 200)
                            
                            Button(action: {
                                agentManager.showingAddAgent = true
                            }) {
                                Label("Add Agent", systemImage: "plus.circle.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        // Resources Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "server.rack")
                                    .foregroundColor(.green)
                                Text("Resources")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Spacer()
                                Text("\(resourceManager.resources.count)")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.green.opacity(0.2))
                                    .cornerRadius(8)
                            }
                            
                            ScrollView {
                                LazyVStack(spacing: 8) {
                                    ForEach(resourceManager.resources) { resource in
                                        ResourceListItem(resource: resource)
                                    }
                                }
                            }
                            .frame(maxHeight: 200)
                            
                            Button(action: {
                                resourceManager.showingAddResource = true
                            }) {
                                Label("Add Resource", systemImage: "plus.circle.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        Spacer()
                    }
                    .frame(minWidth: 280, maxWidth: 320)
                    .padding()
                    
                    // Main Content Area
                    VStack {
                        AgentWorkspaceCanvas()
                    }
                }
                .navigationTitle("RM-ABP")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu("Actions") {
                            Button("Clear All Agents") {
                                agentManager.agents.removeAll()
                            }
                            Button("Reset Resources") {
                                resourceManager.resources.removeAll()
                                resourceManager.addSampleResources()
                            }
                            Button("Start Monitoring") {
                                resourceManager.startResourceMonitoring()
                            }
                        }
                    }
                }
            }
            .tabItem {
                Label("Workspace", systemImage: "rectangle.3.group")
            }
            .tag(0)
            
            // Analytics Tab
            AnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar.fill")
                }
                .tag(1)
        }
        .sheet(isPresented: $agentManager.showingAddAgent) {
            AddAgentView()
        }
        .sheet(isPresented: $resourceManager.showingAddResource) {
            AddResourceView()
        }
    }
}

// MARK: - Agent List Item
struct AgentListItem: View {
    let agent: Agent
    
    var body: some View {
        HStack {
            Image(systemName: agent.type.icon)
                .foregroundColor(agent.type.color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(agent.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(agent.type.rawValue)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Circle()
                .fill(agent.status.color)
                .frame(width: 8, height: 8)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Resource List Item
struct ResourceListItem: View {
    let resource: Resource
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: resource.type.icon)
                    .foregroundColor(resource.type.color)
                    .frame(width: 20)
                
                Text(resource.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Circle()
                    .fill(resource.status.color)
                    .frame(width: 8, height: 8)
            }
            
            ProgressView(value: resource.currentLoad, total: resource.capacity)
                .progressViewStyle(LinearProgressViewStyle(tint: resource.type.color))
            
            HStack {
                Text("\(Int(resource.currentLoad))/\(Int(resource.capacity)) \(resource.type.unit)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(resource.utilizationPercentage))%")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(resource.utilizationPercentage > 80 ? .red : .primary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Analytics View
struct AnalyticsView: View {
    @EnvironmentObject var agentManager: AgentManager
    @EnvironmentObject var resourceManager: ResourceManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // System Overview
                    VStack(alignment: .leading, spacing: 12) {
                        Text("System Overview")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        HStack(spacing: 20) {
                            MetricCard(
                                title: "Total Agents",
                                value: "\(agentManager.agents.count)",
                                icon: "person.3.fill",
                                color: .blue
                            )
                            
                            MetricCard(
                                title: "Active Agents",
                                value: "\(agentManager.getAgentsByStatus(.active).count)",
                                icon: "bolt.fill",
                                color: .green
                            )
                            
                            MetricCard(
                                title: "Resources",
                                value: "\(resourceManager.resources.count)",
                                icon: "server.rack",
                                color: .orange
                            )
                            
                            MetricCard(
                                title: "Utilization",
                                value: "\(Int(resourceManager.getOverallUtilization()))%",
                                icon: "chart.bar.fill",
                                color: .purple
                            )
                        }
                    }
                    .padding()
                    
                    // Resource Breakdown
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Resource Breakdown")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        ForEach(Resource.ResourceType.allCases, id: \.self) { type in
                            ResourceTypeBreakdown(type: type)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Analytics")
        }
    }
}

// MARK: - Metric Card
struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Resource Type Breakdown
struct ResourceTypeBreakdown: View {
    @EnvironmentObject var resourceManager: ResourceManager
    let type: Resource.ResourceType
    
    var body: some View {
        let totalCapacity = resourceManager.getTotalCapacity(for: type)
        let totalUsage = resourceManager.getTotalUsage(for: type)
        let utilization = totalCapacity > 0 ? (totalUsage / totalCapacity) * 100 : 0
        
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: type.icon)
                    .foregroundColor(type.color)
                
                Text(type.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(Int(utilization))%")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            
            ProgressView(value: totalUsage, total: totalCapacity)
                .progressViewStyle(LinearProgressViewStyle(tint: type.color))
            
            Text("\(Int(totalUsage))/\(Int(totalCapacity)) \(type.unit)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Add Resource View
struct AddResourceView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var resourceManager: ResourceManager
    @State private var resourceName = ""
    @State private var selectedType: Resource.ResourceType = .computational
    @State private var capacity: Double = 100
    
    var body: some View {
        NavigationView {
            Form {
                Section("Resource Details") {
                    TextField("Resource Name", text: $resourceName)
                    
                    Picker("Type", selection: $selectedType) {
                        ForEach(Resource.ResourceType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Capacity: \(Int(capacity)) \(selectedType.unit)")
                        Slider(value: $capacity, in: 10...1000, step: 10)
                    }
                }
            }
            .navigationTitle("Add Resource")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        resourceManager.addResource(
                            name: resourceName.isEmpty ? "\(selectedType.rawValue)-\(resourceManager.resources.count + 1)" : resourceName,
                            type: selectedType,
                            capacity: capacity
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
    ContentView()
        .environmentObject(AgentManager())
        .environmentObject(ResourceManager())
}