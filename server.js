const express = require('express');
const cors = require('cors');
const WebSocket = require('ws');
const { v4: uuidv4 } = require('uuid');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static('public'));

// In-memory storage for agents and resources
const agents = new Map();
const resources = new Map();
const cursors = new Map();

// Sample initial resources
resources.set('resource-1', {
  id: 'resource-1',
  name: 'Data Processing Unit',
  type: 'computational',
  status: 'available',
  capacity: 100,
  current_load: 0
});

resources.set('resource-2', {
  id: 'resource-2',
  name: 'Storage Node',
  type: 'storage',
  status: 'available',
  capacity: 1000,
  current_load: 250
});

// API Routes
app.get('/api/agents', (req, res) => {
  res.json(Array.from(agents.values()));
});

app.get('/api/resources', (req, res) => {
  res.json(Array.from(resources.values()));
});

app.post('/api/agents', (req, res) => {
  const agent = {
    id: uuidv4(),
    name: req.body.name || 'Unnamed Agent',
    type: req.body.type || 'generic',
    status: 'active',
    created_at: new Date().toISOString(),
    cursor_position: { x: Math.random() * 800, y: Math.random() * 600 }
  };
  
  agents.set(agent.id, agent);
  res.json(agent);
});

app.put('/api/agents/:id/cursor', (req, res) => {
  const agent = agents.get(req.params.id);
  if (!agent) {
    return res.status(404).json({ error: 'Agent not found' });
  }
  
  agent.cursor_position = req.body.position;
  agents.set(agent.id, agent);
  
  // Broadcast cursor update to all connected clients
  wss.clients.forEach(client => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(JSON.stringify({
        type: 'cursor_update',
        agent_id: agent.id,
        position: agent.cursor_position
      }));
    }
  });
  
  res.json(agent);
});

// Serve the main page
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Start HTTP server
const server = app.listen(PORT, () => {
  console.log(`RM-ABP Server running on port ${PORT}`);
});

// WebSocket server for real-time updates
const wss = new WebSocket.Server({ server });

wss.on('connection', (ws) => {
  console.log('New WebSocket connection');
  
  ws.on('message', (message) => {
    try {
      const data = JSON.parse(message);
      
      if (data.type === 'cursor_move') {
        // Broadcast cursor movement to all other clients
        wss.clients.forEach(client => {
          if (client !== ws && client.readyState === WebSocket.OPEN) {
            client.send(JSON.stringify(data));
          }
        });
      }
    } catch (error) {
      console.error('Error processing WebSocket message:', error);
    }
  });
  
  ws.on('close', () => {
    console.log('WebSocket connection closed');
  });
});