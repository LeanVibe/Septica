# Romanian Septica - Premium PWA Frontend

A premium Progressive Web App implementation of the traditional Romanian Septica card game, featuring ShuffleCats-quality Three.js rendering, authentic Romanian cultural elements, and real-time multiplayer gameplay.

## 🎨 Premium Features (ShuffleCats Quality)

### Three.js 3D Rendering
- **60 FPS Performance**: Optimized WebGL2 rendering with mobile LOD system
- **Physical-Based Materials**: Authentic card textures with Romanian cultural patterns  
- **Romanian Ambient Lighting**: Golden hour café atmosphere with traditional candle lighting
- **Smooth Animations**: Folk dance inspired motion (Hora, Brău, Călușari timing)
- **Glass Morphism UI**: Modern design with Romanian heritage color palette

### Romanian Cultural Authenticity  
- **Regional Variations**: Moldova, Transilvania, Wallachia, Traditional settings
- **Time-of-Day Atmosphere**: Morning, Afternoon, Evening, Night lighting moods
- **Cultural Color Palette**: Authentic Romanian blue, yellow, red heritage colors
- **Traditional Elements**: Candle flickering, fireplace glow, window lighting effects
- **Folk Animation Timing**: Animations based on traditional Romanian dance rhythms

### Cross-Platform Excellence
- **Mobile-First Design**: Touch-optimized with haptic feedback and gesture controls
- **Responsive Performance**: Automatic quality adjustment for device capabilities  
- **Progressive Enhancement**: WebGL2 with graceful fallbacks for older devices
- **PWA Capabilities**: Offline support, installable, native app experience

### Premium Demo Experience
- **Complete Game Demo**: `premium-demo.html` showcasing all features
- **Interactive Controls**: Q-quality, R-region, D-deal, P-play, C-stats shortcuts
- **Real-time Performance**: FPS monitoring and quality adjustment
- **Cultural Settings**: Live switching between Romanian regions and time periods

## Features

### WebSocket Integration
- **Real-time Connection**: Connect to `ws://localhost:8080/ws/connect` endpoint
- **Message Protocol**: Implements exact backend message types and payload structures
- **Auto-reconnection**: Automatic reconnection with exponential backoff
- **Heartbeat System**: Maintains connection with server heartbeat protocol

### Game Testing Functionality
- **Connection Management**: Connect, disconnect, ping server
- **Game Controls**: Join game, leave game, get game state
- **Card Playing**: Interactive card selection and play functionality
- **Game State Display**: Real-time visualization of game state updates

### User Interface
- **Connection Status**: Visual indicator of WebSocket connection state
- **Game Board**: Display table cards, player hand, and valid moves
- **Message Log**: Complete message history with export functionality
- **Responsive Design**: Works on desktop, tablet, and mobile devices

### Progressive Web App Features
- **Offline Support**: Service worker for offline functionality
- **Installable**: Can be installed as standalone app
- **Cross-platform**: Works on all modern browsers and devices
- **Performance**: Fast loading with caching strategies

## Quick Start

### 1. Start the Backend Server
```bash
# Start PostgreSQL database
docker-compose up -d

# Start Go backend server  
cd backend && DATABASE_URL="postgres://septica:septica@localhost:5433/septica?sslmode=disable" go run ./server
```

### 2. Serve the Premium Frontend
```bash
cd frontend && python3 -m http.server 3002
```

### 3. Experience the Premium Demo ⭐
Navigate to `http://localhost:3002/premium-demo.html` for the **ShuffleCats-quality experience**:
- ✨ Three.js 3D rendering at 60 FPS
- 🇷🇴 Authentic Romanian cultural elements  
- 🎮 Interactive controls (Q-quality, R-region, D-deal, P-play, C-stats)
- 🎨 Glass morphism UI with heritage colors
- ⚙️ Real-time performance monitoring

### Alternative: Basic Tester Interface
For basic WebSocket testing, navigate to `http://localhost:3002/index.html`

### Alternative Servers
```bash
# Using Node.js serve (if available)
npx serve . --port 3002

# Using any other static file server on port 3002
```

### 4. Test the Connection
1. Click "Connect" to establish WebSocket connection
2. Join a game using the game mode selector
3. Play cards using the interactive interface
4. Monitor all messages in the debug log

## Usage Guide

### Connection Panel
- **Server URL**: Configure WebSocket endpoint (default: `ws://localhost:8080/ws/connect`)
- **Connect/Disconnect**: Establish or close WebSocket connection
- **Ping**: Send heartbeat to test connection
- **Connection Info**: View player ID, session ID, server time, heartbeat interval

### Game Controls
- **Game Mode**: Select casual, ranked, or custom game mode
- **Join Game**: Enter matchmaking to find or create a game
- **Leave Game**: Exit current game
- **Get Game State**: Request current game state from server

### Game Board
- **Table Cards**: Cards currently played on the table
- **Your Hand**: Your current cards (click to play)
- **Valid Moves**: Highlight cards you can legally play
- **Quick Play**: Manual card selection using dropdowns

### Message Log
- **Real-time Messages**: All WebSocket messages sent and received
- **Message Types**: Color-coded by direction (sent/received/system/error)
- **Export Log**: Download message history for debugging
- **Auto-scroll**: Automatically scroll to latest messages

### Keyboard Shortcuts
- **Ctrl/Cmd + Enter**: Connect/Disconnect
- **Space**: Send ping (when not in input field)
- **J**: Join game
- **L**: Leave game
- **G**: Get game state
- **F1 or Ctrl+H**: Show keyboard shortcuts help
- **Escape**: Close modal dialogs

## WebSocket Message Protocol

The PWA implements the exact message protocol from the Go backend:

### Client → Server Messages
- `ping` - Heartbeat to server
- `join_game` - Join a game with specified mode
- `leave_game` - Leave current game
- `play_card` - Play a card with suit/value
- `get_game_state` - Request current game state
- `chat_message` - Send chat message (if implemented)

### Server → Client Messages
- `pong` - Heartbeat response
- `connection_ack` - Connection acknowledgment with session info
- `game_state` - Complete game state update
- `move_result` - Result of card play attempt
- `player_joined` - Player joined game notification
- `player_left` - Player left game notification
- `game_end` - Game completion notification
- `heartbeat` - Server heartbeat
- `error` - Error message with details

### Message Structure
All messages follow this structure:
```json
{
  "type": "message_type",
  "id": "unique_message_id",
  "player_id": "uuid",
  "game_id": "uuid",
  "timestamp": "2023-XX-XXTXX:XX:XX.XXXZ",
  "payload": {
    // Message-specific data
  }
}
```

## Romanian Septica Game Rules

This PWA tests the Romanian variant of Septica with these rules:

### Basic Rules
- **Players**: 2 players
- **Cards**: Standard 52-card deck, values 7-14 (7, 8, 9, 10, J, Q, K, A)
- **Objective**: Score points by capturing cards with specific values

### Gameplay
1. **Deal**: Each player receives cards from the deck
2. **Play**: Players take turns playing one card
3. **Capture**: Certain card combinations capture table cards
4. **Scoring**: Points awarded based on captured cards

### Card Values & Scoring
- **7s and 8s**: Special capture rules
- **Point Cards**: Specific cards worth points when captured
- **Tricks**: Complete rounds when both players have played

### Victory Condition
Game ends when deck is exhausted and players have no cards. Player with most points wins.

## Development

### File Structure
```
frontend/
├── index.html              # Main HTML interface
├── manifest.json           # PWA manifest
├── sw.js                  # Service worker
├── css/
│   └── styles.css         # Complete responsive styling
├── js/
│   ├── app.js             # Main application entry point
│   ├── websocket-client.js # WebSocket client implementation
│   └── game-ui.js         # UI management and interactions
├── images/
│   ├── icon-192.png       # PWA icon (192x192)
│   ├── icon-512.png       # PWA icon (512x512)
│   └── ...               # Additional PWA assets
└── README.md              # This file
```

### Key Components

#### WebSocket Client (`websocket-client.js`)
- Implements exact backend message protocol
- Handles connection management and auto-reconnection
- Provides high-level methods for game actions
- Manages heartbeat and error handling

#### Game UI (`game-ui.js`)
- Manages all user interface interactions
- Displays game state and card interactions
- Handles message logging and debugging
- Implements responsive card display

#### Main App (`app.js`)
- Application initialization and lifecycle
- PWA feature integration
- Global error handling
- Keyboard shortcuts and accessibility

### Customization

To modify for different servers or protocols:

1. **Server URL**: Change default in `index.html` or via UI
2. **Message Types**: Update constants in `websocket-client.js`
3. **Game Rules**: Modify card display and validation in `game-ui.js`
4. **Styling**: Customize CSS variables in `styles.css`

### Debugging

The PWA includes comprehensive debugging features:

- **Console Commands**: Access app state via browser console
- **Message Export**: Download complete message logs
- **Error Logging**: Detailed error tracking and display
- **Status Monitoring**: Real-time connection and game status

Use `window.exportDebugInfo()` in browser console to export debug information.

## Browser Compatibility

### Supported Browsers
- **Chrome/Chromium**: 88+
- **Firefox**: 85+
- **Safari**: 14+
- **Edge**: 88+

### Required Features
- WebSocket support
- Service Workers
- ES6+ JavaScript features
- CSS Grid and Flexbox
- Local Storage

### PWA Support
- **Android Chrome**: Full PWA support including install prompt
- **iOS Safari**: Basic PWA support, manual "Add to Home Screen"
- **Desktop**: Install via browser's app install option

## Security Considerations

### WebSocket Security
- Uses standard WebSocket protocol (can be upgraded to WSS)
- No sensitive data stored in localStorage
- Message validation on both client and server

### PWA Security
- Service worker serves only cached resources
- No external resource loading
- Content Security Policy headers recommended

### Development vs Production
- This is a testing tool - not for production game deployment
- Server URL configurable for different environments
- Debug logging should be disabled in production builds

## Troubleshooting

### Connection Issues
1. **Verify server is running** on specified port
2. **Check firewall settings** for WebSocket port
3. **Review browser console** for error messages
4. **Test with different browsers** to isolate issues

### PWA Installation
1. **Serve over HTTPS** for full PWA features (except localhost)
2. **Check service worker registration** in browser dev tools
3. **Verify manifest.json** is accessible and valid
4. **Clear browser cache** if updates not appearing

### Game State Issues
1. **Check message log** for protocol errors
2. **Verify backend compatibility** with message types
3. **Test with simple ping/pong** before game actions
4. **Export debug logs** for analysis

## License

This testing PWA is part of the Septica game project. See main project license.

---

**Note**: This is a development/testing tool. For production deployment, additional security, performance, and reliability considerations should be implemented.