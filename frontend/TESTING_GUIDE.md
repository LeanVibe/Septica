# Septica WebSocket Backend Testing Guide

## Quick Start

### 1. Start the Backend Server
From the Septica root directory:
```bash
cd backend
./server
```
This should start the WebSocket server on `ws://localhost:8080/ws/connect`

### 2. Start the Frontend PWA
From the frontend directory:
```bash
cd frontend
./test-launch.sh
```
Or manually:
```bash
# Using Python
python3 serve.py

# Using Node.js  
node serve.js

# Using any static server
python3 -m http.server 8000
```

### 3. Open in Browser
Navigate to `http://localhost:8000` (or whatever port the server shows)

## Test Scenarios

### Basic Connection Testing
1. **Connect to WebSocket**
   - Click "Connect" button
   - Verify connection status turns green
   - Check that Player ID and Session ID appear
   - Verify heartbeat interval is set

2. **Test Ping/Pong**
   - Click "Send Ping" button
   - Check message log for ping/pong exchange
   - Verify heartbeat is working automatically

3. **Connection Resilience**
   - Disconnect and reconnect
   - Test auto-reconnection by stopping/starting backend
   - Verify error handling for connection failures

### Game Flow Testing
1. **Join Game**
   - Select game mode (casual/ranked/custom)
   - Click "Join Game"
   - Wait for game state or matchmaking response
   - Verify Game ID appears when joined

2. **Game State Management**
   - Click "Get Game State" to request current state
   - Verify game info panel updates correctly
   - Check that your cards appear in hand section
   - Verify table cards and valid moves display

3. **Card Playing**
   - Use clickable cards in hand (if valid moves available)
   - Or use Quick Play dropdown to select suit/value
   - Click "Play Card" button
   - Verify move result appears in log
   - Check game state updates after valid moves

4. **Game Completion**
   - Play through a complete game
   - Verify end game handling
   - Check score display
   - Test leaving game mid-play

### Message Protocol Testing
1. **Message Format Validation**
   - Check message log for proper JSON structure
   - Verify all messages have required fields:
     - type, id, timestamp
     - player_id (for outbound)
     - game_id (when in game)
     - payload (when applicable)

2. **Error Handling**
   - Try invalid moves (wrong suit/value)
   - Attempt actions when not in game
   - Test with malformed requests
   - Verify error messages are user-friendly

3. **Message Types Coverage**
   Test all client→server messages:
   - ✅ ping
   - ✅ join_game  
   - ✅ leave_game
   - ✅ play_card
   - ✅ get_game_state
   - ✅ chat_message (if implemented)

   Verify all server→client messages:
   - ✅ pong
   - ✅ connection_ack
   - ✅ game_state
   - ✅ move_result
   - ✅ player_joined
   - ✅ player_left
   - ✅ game_end
   - ✅ heartbeat
   - ✅ error

### Romanian Septica Rules Testing
1. **Card Values**
   - Verify cards 7-14 (7,8,9,10,J,Q,K,A) are supported
   - Check suit representation (hearts,diamonds,clubs,spades)
   - Test special rules for 7s and 8s

2. **Game Logic**
   - Test valid move detection
   - Verify trick completion logic
   - Check point calculation
   - Test game end conditions

3. **Two-Player Gameplay**
   - Open PWA in two browser tabs/windows
   - Connect both to same backend
   - Join same game from both clients
   - Take turns playing cards
   - Verify real-time state synchronization

### PWA Features Testing
1. **Installation**
   - Wait for install banner (appears after 5 seconds)
   - Click "Install" button
   - Verify app installs as standalone PWA
   - Test offline functionality

2. **Service Worker**
   - Check service worker registration in dev tools
   - Test offline page loading
   - Verify caching is working
   - Test update handling

3. **Responsive Design**
   - Test on different screen sizes
   - Verify mobile layout
   - Check tablet landscape/portrait
   - Test touch interactions

4. **Keyboard Shortcuts**
   - Ctrl/Cmd+Enter: Connect/Disconnect
   - Space: Send ping
   - J: Join game
   - L: Leave game  
   - G: Get game state
   - F1 or Ctrl+H: Show help

### Performance Testing
1. **Connection Performance**
   - Measure connection establishment time
   - Test with high message frequency
   - Verify memory usage stays reasonable
   - Check for memory leaks during long sessions

2. **UI Responsiveness**
   - Test rapid clicking/interactions
   - Verify smooth animations
   - Check message log performance with many entries
   - Test card rendering performance

### Error Scenarios
1. **Network Issues**
   - Disconnect network mid-game
   - Test with slow/unstable connection
   - Verify graceful degradation
   - Check reconnection behavior

2. **Server Issues**
   - Stop backend server during active connection
   - Restart backend and test reconnection
   - Test invalid WebSocket URLs
   - Verify timeout handling

3. **Invalid Input**
   - Try playing cards not in hand
   - Attempt moves when not your turn
   - Test with invalid game modes
   - Send malformed JSON (if possible)

## Message Log Analysis

The PWA provides comprehensive message logging. Look for:

### Successful Patterns
```
[timestamp] SENT: ping
[timestamp] RECEIVED: pong
[timestamp] SENT: join_game
[timestamp] RECEIVED: game_state
```

### Error Patterns
```
[timestamp] RECEIVED: error
[timestamp] ERROR: Invalid move: not your turn
```

### Connection Patterns
```
[timestamp] SYSTEM: Connected to WebSocket server
[timestamp] RECEIVED: connection_ack
[timestamp] SYSTEM: Heartbeat started (30000ms interval)
```

## Debug Information

### Browser Console Commands
```javascript
// Get app status
window.septicaApp.getAppStatus()

// Get WebSocket status  
window.wsClient.getStatus()

// Export debug info
window.exportDebugInfo()

// Access UI instance
window.gameUI.logMessage('TEST', 'Custom debug message')
```

### Message Export
Click "Export Log" button to download complete message history as JSON for analysis.

## Common Issues & Solutions

### Connection Refused
- **Problem**: Cannot connect to WebSocket
- **Solution**: Verify Go backend is running on correct port
- **Check**: `lsof -i :8080` to see if port is listening

### Invalid Moves Rejected
- **Problem**: Cards can't be played
- **Solution**: Check valid moves in game state
- **Debug**: Use "Get Game State" to see current valid moves

### PWA Not Installing
- **Problem**: Install prompt doesn't appear
- **Solution**: Serve over HTTPS or use localhost
- **Check**: Service worker registration in dev tools

### Message Log Too Verbose
- **Problem**: Too many debug messages
- **Solution**: Use "Clear Log" button periodically
- **Note**: Log is limited to 1000 entries automatically

### Poor Performance
- **Problem**: Slow UI responses
- **Solution**: Check browser dev tools performance tab
- **Debug**: Export debug info to analyze message patterns

## Success Criteria

The backend passes testing when:

✅ **Connection Stability**
- Connects reliably to WebSocket endpoint
- Maintains connection with heartbeat
- Handles reconnection gracefully

✅ **Protocol Compliance**  
- All message types implemented correctly
- JSON structure matches specification
- Error handling provides useful feedback

✅ **Game Logic Accuracy**
- Romanian Septica rules enforced correctly
- Valid moves calculated properly
- Game state updates in real-time

✅ **Multi-player Support**
- Two clients can join same game
- State synchronization works correctly
- Player actions reflected to opponent

✅ **Performance**
- Responses within reasonable time (<2s)
- Memory usage stays stable
- No connection leaks or crashes

---

**Happy Testing! 🎮**

This PWA provides comprehensive testing capabilities for your Septica WebSocket backend. Use the message log and debug features to identify and resolve any issues with the server implementation.