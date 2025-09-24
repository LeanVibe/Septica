# Romanian Septica - Mobile Game Development Logging Guide

## 🎮 **OPTIMIZED FOR MOBILE GAME DEVELOPERS**

This logging system is specifically designed for mobile game development, providing real-time performance monitoring, Romanian Septica rule validation, and comprehensive debugging information.

---

## 🚀 **QUICK START - ENHANCED LOGGING**

### **Frontend Integration**
```javascript
// The mobile logger is automatically initialized
// Access via: window.MobileGameLogger

// Example usage in your game:
window.MobileGameLogger.logCardPlay('Player1', {value: 7, suit: 'Hearts'}, tableCards, true, 2);
window.MobileGameLogger.logMatchmaking('matched', 'player-123', 3000);
window.MobileGameLogger.logWebSocketEvent('connect', null, 150);
```

### **Backend Integration**
```go
// Import the mobile game logger
import "your-project/internal/logger"

// Use throughout your Go code:
logger.MobileLogger.LogCardPlay(playerID, gameID, card, tableState, true, points, responseTime)
logger.MobileLogger.LogMatchmaking(playerID, "matched", waitTime)
logger.MobileLogger.LogWebSocketEvent(playerID, "connect", latency, nil)
```

---

## 📊 **MOBILE GAME PERFORMANCE MONITORING**

### **Real-Time Metrics Tracked**

#### **Frontend Performance**
- ✅ **FPS Monitoring**: Target 60 FPS, alerts below 30 FPS
- ✅ **Memory Usage**: Detects memory leaks above 2x baseline
- ✅ **Touch Latency**: Input response time monitoring
- ✅ **WebSocket Latency**: Network performance tracking
- ✅ **Three.js Render Time**: 3D graphics performance

#### **Backend Performance**
- ✅ **Response Time**: <200ms target for card plays
- ✅ **Database Queries**: Slow query detection (>100ms)
- ✅ **Memory Monitoring**: Go runtime memory usage
- ✅ **Goroutine Count**: Concurrent connection tracking
- ✅ **Active Connections**: Real-time player count

### **Mobile Device Capabilities Detection**
```javascript
// Automatically logs on page load:
{
  userAgent: "Mozilla/5.0...",
  devicePixelRatio: 2,
  screenSize: "1920x1080",
  viewportSize: "375x812",
  connection: "4g",
  memory: "8GB",
  cores: 8,
  webgl: "WebGL2",
  online: true
}
```

---

## 🎯 **ROMANIAN SEPTICA GAME LOGGING**

### **Card Play Validation**
```javascript
// Frontend logging with rule validation
MobileGameLogger.logCardPlay('Player1',
  {value: 7, suit: 'Spades'},
  [{value: 10, suit: 'Hearts'}, {value: 8, suit: 'Diamonds'}],
  true,    // Valid play
  1        // Points earned
);

// Output example:
// [14:23:15.432] [INFO] [GAME_PLAY] Player1 played 7♠ → 1 points
// [14:23:15.433] [DEBUG] [RULE_CHECK] 7 beats all - valid
```

### **Romanian Rules Validation**
The system automatically validates Romanian Septica rules:

#### **Rule 1: 7s Always Beat**
```javascript
// Logs error if 7 is rejected
if (card.value === 7 && !isValid) {
  logger.error('RULE_VIOLATION', '7 should always beat but was rejected!');
}
```

#### **Rule 2: Same Values Beat**
```javascript
// Detects when same values should beat each other
if (tableCard.value === playedCard.value) {
  logger.debug('RULE_CHECK', '10 beats 10 - same value');
}
```

#### **Rule 3: 8s Conditional**
```javascript
// Validates 8 beating when table count % 3 == 0
if (card.value === 8 && tableCards.length % 3 === 0) {
  logger.debug('RULE_CHECK', '8 beats (table count % 3 == 0)');
}
```

#### **Point Cards Tracking**
```javascript
// Automatically logs point cards (10s and Aces)
// [INFO] [POINTS] Point card played: 10 (1pt) - Total possible: 8
```

---

## 🌐 **MULTIPLAYER/WEBSOCKET MONITORING**

### **Connection Status**
```javascript
// Frontend WebSocket logging
MobileGameLogger.logWebSocketEvent('connect', null, 150);  // 150ms latency
MobileGameLogger.logWebSocketEvent('message', gameData, 45); // 45ms response

// Automatic latency warnings:
// [WARN] [WEBSOCKET] High latency: 520ms
```

### **Matchmaking Tracking**
```javascript
// Complete matchmaking flow logging
MobileGameLogger.logMatchmaking('queued', 'player-123');
MobileGameLogger.logMatchmaking('matched', 'player-123', 3500); // 3.5s wait

// Backend equivalent:
logger.MobileLogger.LogMatchmaking(playerID, "matched", 3500*time.Millisecond)
```

---

## 📱 **MOBILE-SPECIFIC LOGGING**

### **Touch Event Monitoring**
```javascript
// Automatically tracks touch responsiveness
document.addEventListener('touchstart', (e) => {
  const responseTime = measureResponseTime();
  MobileGameLogger.logTouchEvent('touchstart', {
    x: e.touches[0].clientX,
    y: e.touches[0].clientY
  }, responseTime);
});

// Alerts for slow responses:
// [WARN] [INPUT_LAG] Slow touch response: 120ms
```

### **Device Performance Health Checks**
```javascript
// Automatic health monitoring every 30 seconds
MobileGameLogger.checkMobileGameHealth();

// Example output:
// [WARN] [HEALTH_CHECK] Mobile game performance issues detected
// Issues: ["Low FPS: 25", "High memory: 120MB", "Input lag: 110ms"]
// Recommendations: ["Reduce Three.js quality", "Enable mobile LOD"]
```

---

## 🔍 **DEBUGGING WORKFLOW**

### **Performance Dashboard**
```javascript
// View real-time performance stats
MobileGameLogger.showPerformanceStats();

// Console table output:
┌─────────────────┬─────────┐
│ fps             │ 58      │
│ memory          │ 67      │
│ touchLatency    │ 45      │
│ wsLatency       │ 120     │
│ gameTime        │ 234567  │
│ touchEvents     │ 8       │
└─────────────────┴─────────┘
```

### **Error Tracking**
```javascript
// Automatic error logging with context
window.addEventListener('error', (event) => {
  MobileGameLogger.logError(event.error, {
    filename: event.filename,
    line: event.lineno,
    performance: MobileGameLogger.performanceMetrics
  });
});

// Output includes game state for debugging:
// [ERROR] [GAME_ERROR] TypeError: Cannot read property 'suit' of null
// Context: { performance: {...}, gameState: {...} }
```

---

## 🎯 **LOG CATEGORIES FOR MOBILE GAME DEV**

### **Performance Logs**
- `[PERFORMANCE]` - FPS, memory, latency issues
- `[INPUT_LAG]` - Touch response time problems
- `[MEMORY]` - Memory leak detection
- `[HEALTH_CHECK]` - Overall system health

### **Game Logic Logs**
- `[GAME_PLAY]` - Card plays and rule validation
- `[RULE_CHECK]` - Romanian Septica rule compliance
- `[POINTS]` - Point card tracking (10s and Aces)
- `[RULE_VIOLATION]` - Game rule errors

### **Multiplayer Logs**
- `[WEBSOCKET]` - Connection status and latency
- `[MATCHMAKING]` - Player pairing and queue times
- `[GAME_SESSION]` - Game creation and management

### **System Logs**
- `[DEVICE]` - Mobile device capabilities
- `[DATABASE]` - Backend query performance
- `[HTTP]` - API request tracking

---

## 🔥 **MOBILE GAME DEVELOPMENT BEST PRACTICES**

### **Performance Targets**
- **FPS**: 60 FPS (minimum 30 FPS)
- **Memory**: <100MB total usage
- **Touch Response**: <100ms input latency
- **Network**: <200ms WebSocket response
- **Card Play**: <200ms backend processing

### **Debugging Priorities**
1. **Frame Rate**: Monitor FPS drops during gameplay
2. **Memory Leaks**: Watch for increasing memory usage
3. **Input Lag**: Ensure responsive touch controls
4. **Network Issues**: Track WebSocket connectivity
5. **Rule Validation**: Verify Romanian Septica rules

### **Production Monitoring**
```javascript
// Health check alerts for production
if (fps < 30) alert("Performance degradation detected");
if (memory > 150) alert("Memory leak possible");
if (wsLatency > 500) alert("Network issues detected");
```

---

## 📋 **COMMON MOBILE GAME ISSUES & SOLUTIONS**

### **Problem: Low FPS**
```
[WARN] [PERFORMANCE] Low FPS: 25 (Target: 60)
```
**Solutions:**
- Enable mobile LOD system
- Reduce Three.js quality settings
- Disable expensive visual effects

### **Problem: Memory Leaks**
```
[ERROR] [MEMORY] Memory leak detected: 180MB (baseline: 65MB)
```
**Solutions:**
- Check for undisposed Three.js objects
- Clear card animation resources
- Monitor WebSocket message accumulation

### **Problem: Input Lag**
```
[WARN] [INPUT_LAG] Slow touch response: 150ms
```
**Solutions:**
- Optimize event handlers
- Reduce DOM manipulation
- Use requestAnimationFrame for animations

### **Problem: Network Issues**
```
[ERROR] [WEBSOCKET] Connection error for player-123
```
**Solutions:**
- Implement reconnection logic
- Add connection status indicator
- Cache game state locally

---

## 🎮 **INTEGRATION EXAMPLES**

### **Add to Existing Game Loop**
```javascript
// In your game's render loop
function gameLoop() {
  // Your existing game logic...

  // Performance monitoring (automatic)
  requestAnimationFrame(gameLoop);
}

// The logger automatically tracks FPS in this loop
```

### **Add to WebSocket Client**
```javascript
// Enhance existing WebSocket code
ws.onopen = () => {
  MobileGameLogger.logWebSocketEvent('connect', null, Date.now() - connectStart);
};

ws.onmessage = (event) => {
  const responseTime = Date.now() - messageSentTime;
  MobileGameLogger.logWebSocketEvent('message', JSON.parse(event.data), responseTime);
};
```

### **Add to Card Play Handler**
```javascript
function playCard(card, tableState) {
  const startTime = performance.now();

  // Your existing card play logic...
  const isValid = validatePlay(card, tableState);
  const points = calculatePoints(card, tableState);

  const responseTime = performance.now() - startTime;

  // Enhanced logging
  MobileGameLogger.logCardPlay(currentPlayer, card, tableState, isValid, points);
}
```

---

## 🚀 **NEXT STEPS**

1. **Integrate Logging**: Add the mobile game logger to your existing code
2. **Monitor Performance**: Watch for FPS drops and memory issues
3. **Validate Rules**: Ensure Romanian Septica rules are working correctly
4. **Test on Devices**: Verify performance on actual mobile devices
5. **Production Deploy**: Use health checks for live monitoring

**Your Romanian Septica game is now optimized for professional mobile game development! 🎮**