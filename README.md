# RM-ABP
**Resource Manager for Agent-Based Programming**

A real-time web application for managing agents and resources with cursor tracking functionality. Built with Node.js, Express, WebSockets, and vanilla JavaScript.

## Features

- **Agent Management**: Create and manage different types of agents (Worker, Coordinator, Monitor, Analyzer)
- **Resource Monitoring**: Track computational and storage resources with real-time capacity monitoring
- **Real-time Cursor Tracking**: See agent positions and movements in real-time across the workspace
- **Interactive Canvas**: Visual workspace with grid system and agent connections
- **WebSocket Communication**: Real-time updates and collaborative features
- **Modern UI**: Responsive design with gradient backgrounds and smooth animations

## Quick Start

1. Install dependencies:
   ```bash
   npm install
   ```

2. Start the application:
   ```bash
   npm start
   ```

3. Open your browser and navigate to `http://localhost:3000`

## API Endpoints

- `GET /api/agents` - Retrieve all agents
- `POST /api/agents` - Create a new agent
- `GET /api/resources` - Retrieve all resources
- `PUT /api/agents/:id/cursor` - Update agent cursor position

## Technology Stack

- **Backend**: Node.js, Express.js, WebSockets
- **Frontend**: HTML5, CSS3, JavaScript (ES6+)
- **Real-time**: WebSocket for live updates
- **Styling**: Modern CSS with gradients and animations

## Development

For development with auto-restart:
```bash
npm run dev
```

## Usage

1. **Add Agents**: Click "Add Agent" to create new agents with different types
2. **Monitor Resources**: View resource utilization in the sidebar
3. **Interactive Workspace**: Move your cursor over the canvas to see real-time cursor tracking
4. **Agent Visualization**: Agents appear as colored circles on the canvas with connecting lines when nearby

The application automatically connects agents that are within 150 pixels of each other, creating a dynamic network visualization. 
