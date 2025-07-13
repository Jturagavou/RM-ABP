class RMApp {
    constructor() {
        this.agents = [];
        this.resources = [];
        this.ws = null;
        this.canvas = document.getElementById('workspace-canvas');
        this.ctx = this.canvas.getContext('2d');
        this.cursorsOverlay = document.getElementById('cursors-overlay');
        
        this.init();
    }
    
    init() {
        this.setupWebSocket();
        this.setupEventListeners();
        this.loadInitialData();
        this.startCanvasAnimation();
    }
    
    setupWebSocket() {
        const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
        const wsUrl = `${protocol}//${window.location.host}`;
        
        this.ws = new WebSocket(wsUrl);
        
        this.ws.onopen = () => {
            console.log('WebSocket connected');
            document.getElementById('connection-status').style.background = '#48bb78';
        };
        
        this.ws.onmessage = (event) => {
            const data = JSON.parse(event.data);
            this.handleWebSocketMessage(data);
        };
        
        this.ws.onclose = () => {
            console.log('WebSocket disconnected');
            document.getElementById('connection-status').style.background = '#f56565';
            // Try to reconnect after 3 seconds
            setTimeout(() => this.setupWebSocket(), 3000);
        };
    }
    
    setupEventListeners() {
        // Add agent button
        document.getElementById('add-agent-btn').addEventListener('click', () => {
            this.showAgentModal();
        });
        
        // Agent form submission
        document.getElementById('agent-form').addEventListener('submit', (e) => {
            e.preventDefault();
            this.createAgent();
        });
        
        // Modal controls
        document.getElementById('cancel-agent').addEventListener('click', () => {
            this.hideAgentModal();
        });
        
        // Canvas mouse movement
        this.canvas.addEventListener('mousemove', (e) => {
            const rect = this.canvas.getBoundingClientRect();
            const x = e.clientX - rect.left;
            const y = e.clientY - rect.top;
            
            if (this.ws && this.ws.readyState === WebSocket.OPEN) {
                this.ws.send(JSON.stringify({
                    type: 'cursor_move',
                    position: { x, y },
                    timestamp: Date.now()
                }));
            }
        });
        
        // Close modal when clicking outside
        document.getElementById('agent-modal').addEventListener('click', (e) => {
            if (e.target.id === 'agent-modal') {
                this.hideAgentModal();
            }
        });
    }
    
    async loadInitialData() {
        try {
            // Load agents
            const agentsResponse = await fetch('/api/agents');
            this.agents = await agentsResponse.json();
            
            // Load resources
            const resourcesResponse = await fetch('/api/resources');
            this.resources = await resourcesResponse.json();
            
            this.updateUI();
        } catch (error) {
            console.error('Error loading initial data:', error);
        }
    }
    
    updateUI() {
        this.updateAgentsList();
        this.updateResourcesList();
        this.updateAgentCursors();
    }
    
    updateAgentsList() {
        const agentsList = document.getElementById('agents-list');
        agentsList.innerHTML = '';
        
        this.agents.forEach(agent => {
            const agentElement = document.createElement('div');
            agentElement.className = 'list-item';
            agentElement.innerHTML = `
                <h4>${agent.name}</h4>
                <p>Type: ${agent.type}</p>
                <span class="status ${agent.status}">${agent.status}</span>
            `;
            agentsList.appendChild(agentElement);
        });
    }
    
    updateResourcesList() {
        const resourcesList = document.getElementById('resources-list');
        resourcesList.innerHTML = '';
        
        this.resources.forEach(resource => {
            const resourceElement = document.createElement('div');
            resourceElement.className = 'list-item';
            resourceElement.innerHTML = `
                <h4>${resource.name}</h4>
                <p>Type: ${resource.type}</p>
                <p>Load: ${resource.current_load}/${resource.capacity}</p>
                <span class="status ${resource.status}">${resource.status}</span>
            `;
            resourcesList.appendChild(resourceElement);
        });
    }
    
    updateAgentCursors() {
        // Clear existing cursors
        this.cursorsOverlay.innerHTML = '';
        
        // Add cursor for each agent
        this.agents.forEach(agent => {
            if (agent.cursor_position) {
                this.createCursor(agent.id, agent.name, agent.cursor_position);
            }
        });
    }
    
    createCursor(agentId, agentName, position) {
        const cursor = document.createElement('div');
        cursor.className = 'cursor';
        cursor.setAttribute('data-agent', agentName);
        cursor.style.left = `${position.x}px`;
        cursor.style.top = `${position.y}px`;
        this.cursorsOverlay.appendChild(cursor);
    }
    
    startCanvasAnimation() {
        const animate = () => {
            this.drawCanvas();
            requestAnimationFrame(animate);
        };
        animate();
    }
    
    drawCanvas() {
        // Clear canvas
        this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
        
        // Draw grid
        this.drawGrid();
        
        // Draw agents as nodes
        this.drawAgents();
        
        // Draw connections between agents
        this.drawConnections();
    }
    
    drawGrid() {
        this.ctx.strokeStyle = '#e2e8f0';
        this.ctx.lineWidth = 1;
        
        // Vertical lines
        for (let x = 0; x < this.canvas.width; x += 50) {
            this.ctx.beginPath();
            this.ctx.moveTo(x, 0);
            this.ctx.lineTo(x, this.canvas.height);
            this.ctx.stroke();
        }
        
        // Horizontal lines
        for (let y = 0; y < this.canvas.height; y += 50) {
            this.ctx.beginPath();
            this.ctx.moveTo(0, y);
            this.ctx.lineTo(this.canvas.width, y);
            this.ctx.stroke();
        }
    }
    
    drawAgents() {
        this.agents.forEach(agent => {
            if (agent.cursor_position) {
                const { x, y } = agent.cursor_position;
                
                // Draw agent circle
                this.ctx.beginPath();
                this.ctx.arc(x, y, 15, 0, 2 * Math.PI);
                this.ctx.fillStyle = agent.status === 'active' ? '#667eea' : '#cbd5e0';
                this.ctx.fill();
                this.ctx.strokeStyle = '#fff';
                this.ctx.lineWidth = 3;
                this.ctx.stroke();
                
                // Draw agent label
                this.ctx.fillStyle = '#2d3748';
                this.ctx.font = '12px sans-serif';
                this.ctx.textAlign = 'center';
                this.ctx.fillText(agent.name, x, y + 35);
            }
        });
    }
    
    drawConnections() {
        // Draw simple connections between nearby agents
        for (let i = 0; i < this.agents.length; i++) {
            for (let j = i + 1; j < this.agents.length; j++) {
                const agent1 = this.agents[i];
                const agent2 = this.agents[j];
                
                if (agent1.cursor_position && agent2.cursor_position) {
                    const dist = Math.sqrt(
                        Math.pow(agent1.cursor_position.x - agent2.cursor_position.x, 2) +
                        Math.pow(agent1.cursor_position.y - agent2.cursor_position.y, 2)
                    );
                    
                    if (dist < 150) {
                        this.ctx.beginPath();
                        this.ctx.moveTo(agent1.cursor_position.x, agent1.cursor_position.y);
                        this.ctx.lineTo(agent2.cursor_position.x, agent2.cursor_position.y);
                        this.ctx.strokeStyle = `rgba(102, 126, 234, ${1 - dist / 150})`;
                        this.ctx.lineWidth = 2;
                        this.ctx.stroke();
                    }
                }
            }
        }
    }
    
    handleWebSocketMessage(data) {
        switch (data.type) {
            case 'cursor_update':
                const agent = this.agents.find(a => a.id === data.agent_id);
                if (agent) {
                    agent.cursor_position = data.position;
                    this.updateAgentCursors();
                }
                break;
            case 'cursor_move':
                // Handle real-time cursor movement from other clients
                this.showTemporaryCursor(data.position);
                break;
        }
    }
    
    showTemporaryCursor(position) {
        const tempCursor = document.createElement('div');
        tempCursor.className = 'cursor';
        tempCursor.style.left = `${position.x}px`;
        tempCursor.style.top = `${position.y}px`;
        tempCursor.style.background = 'rgba(102, 126, 234, 0.7)';
        this.cursorsOverlay.appendChild(tempCursor);
        
        // Remove after a short time
        setTimeout(() => {
            if (tempCursor.parentNode) {
                tempCursor.parentNode.removeChild(tempCursor);
            }
        }, 1000);
    }
    
    showAgentModal() {
        document.getElementById('agent-modal').style.display = 'block';
        document.getElementById('agent-name').focus();
    }
    
    hideAgentModal() {
        document.getElementById('agent-modal').style.display = 'none';
        document.getElementById('agent-form').reset();
    }
    
    async createAgent() {
        const name = document.getElementById('agent-name').value;
        const type = document.getElementById('agent-type').value;
        
        try {
            const response = await fetch('/api/agents', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ name, type }),
            });
            
            if (response.ok) {
                const newAgent = await response.json();
                this.agents.push(newAgent);
                this.updateUI();
                this.hideAgentModal();
            }
        } catch (error) {
            console.error('Error creating agent:', error);
        }
    }
}

// Initialize the application when the page loads
document.addEventListener('DOMContentLoaded', () => {
    new RMApp();
});