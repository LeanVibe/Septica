# CLAUDE.md - Romanian Septica PWA Project Navigation Guide

This file provides guidance to Claude Code (claude.ai/code) when working with the Romanian Septica multiplayer card game - a **Go backend + Premium PWA frontend** implementation.

## 🚀 SESSION CONTEXT MANAGEMENT - READ THIS FIRST

### **CURRENT PROJECT STATUS (September 22, 2025)**
```
✅ Phase 1: Go Backend Implementation - COMPLETE (Romanian Septica rules verified)
✅ Phase 2: WebSocket Multiplayer Protocol - COMPLETE (Real-time sync operational)  
✅ Phase 3: Premium LitPWA/Three.js Frontend - COMPLETE (ShuffleCats quality achieved)
🎯 CURRENT FOCUS: Production Deployment & Cross-Platform Testing
```

### **CRITICAL CONTEXT FILES TO READ ON SESSION START:**
1. **docs/PLAN.md** - Comprehensive project plan and implementation status
2. **docs/SHUFFLECATS_QUALITY_IMPLEMENTATION_PLAN.md** - Premium frontend quality standards
3. **docs/game-rules.md** - Romanian Septica rules implementation
4. **PROJECT_INDEX.json** - Complete project structure and codebase overview

### **IMMEDIATE NEXT PRIORITIES:**
1. **Production Deployment** - Kubernetes deployment to cloud infrastructure
2. **Cross-Platform Validation** - iOS PWA, Android, Desktop compatibility
3. **Performance Optimization** - 60 FPS maintenance across devices
4. **Multiplayer Load Testing** - Tournament system scalability

### **SESSION CONTINUATION CHECKLIST:**
- [ ] Verify Go backend status: `go run ./backend/server` (port 8080)
- [ ] Verify PostgreSQL: `docker-compose up -d` (port 5433)
- [ ] Check premium frontend: `python3 -m http.server 3002` in frontend/
- [ ] Test premium demo: `http://localhost:3002/premium-demo.html`
- [ ] Review git status and recent commits

### **CRITICAL ARCHITECTURAL CONTEXT:**
- **Backend**: Go 1.21+ with Gin framework, PostgreSQL database, WebSocket multiplayer
- **Frontend**: Premium Three.js with Romanian cultural elements, PWA capabilities  
- **Romanian Cultural Features**: Regional variations, traditional lighting, folk animations
- **Performance**: 60 FPS target, mobile-optimized LOD system, cross-platform compatibility
- **Target Platforms**: Android, Desktop (primary), iOS PWA (secondary)

## 🎨 PREMIUM FRONTEND ARCHITECTURE

### **Premium Components (Recently Completed)**
```
frontend/
├── css/premium-glass-morphism.css      # Romanian heritage UI design
├── js/premium-card-material.js         # Physical-based rendering materials
├── js/romanian-ambient-lighting.js     # Authentic café atmosphere lighting
├── js/premium-card-animations.js       # Folk dance inspired animations
├── js/premium-septica-game.js          # Main integration class
└── premium-demo.html                   # Complete demonstration app
```

### **Romanian Cultural Features Implemented**
- **Regional Variations**: Moldova, Transilvania, Wallachia, Traditional
- **Time-of-Day Atmosphere**: Morning, Afternoon, Evening, Night lighting
- **Cultural Animations**: Hora, Brău, Călușari folk dance timing
- **Heritage Color Palette**: Romanian blue, yellow, red with authenticity
- **Traditional Elements**: Candle lighting, café atmosphere, cultural patterns

### **Performance & Quality Standards**
- **60 FPS Rendering**: Achieved with mobile LOD system optimization
- **ShuffleCats Quality**: Glass morphism, premium materials, smooth animations
- **Cross-Platform**: WebGL2 with graceful fallbacks for older devices
- **Responsive Design**: Supports phones, tablets, desktops seamlessly

## 🎮 ROMANIAN SEPTICA GAME RULES

### **Critical Game Implementation**
- **Deck**: 32 cards (7, 8, 9, 10, Jack, Queen, King, Ace) × 4 suits
- **Point Cards**: 10s and Aces (1 point each) - **Total: 8 points per game**
- **Beating Rules**: 
  - 7 always beats (wild card)
  - Same value beats
  - 8 beats when (table cards count % 3 == 0)

### **Backend Implementation Files**
- **backend/internal/game/engine.go** - Core game rules and logic
- **backend/internal/game/deck.go** - 32-card Romanian deck management  
- **backend/internal/game/player.go** - Player state and actions
- **backend/internal/websocket/** - Real-time multiplayer protocol

## 🔧 DEVELOPMENT WORKFLOW

### **Backend Commands**
```bash
# Start Go backend server
cd backend && go run ./server
# Or with database URL
DATABASE_URL="postgres://septica:septica@localhost:5433/septica?sslmode=disable" ./backend/server

# Start PostgreSQL database
docker-compose up -d

# Backend tests
cd backend && go test ./...
```

### **Frontend Commands**
```bash
# Start premium frontend server
cd frontend && python3 -m http.server 3002

# Test premium demo
open http://localhost:3002/premium-demo.html

# Mobile performance testing
npm test  # If Node.js environment available
```

### **Premium Demo Controls**
- **Q**: Toggle quality (Ultra/High/Medium/Low)
- **R**: Change Romanian region (Moldova/Transilvania/Wallachia)
- **D**: Deal cards with Romanian animations
- **P**: Play card with cultural effects
- **C**: Show performance statistics

## 📁 PROJECT STRUCTURE

### **Core Backend Directories**
```
backend/
├── cmd/server/           # Main server entry point
├── internal/
│   ├── auth/            # Authentication and sessions  
│   ├── game/            # Romanian Septica game engine
│   ├── websocket/       # Real-time multiplayer protocol
│   └── database/        # PostgreSQL data models
└── pkg/config/          # Server configuration
```

### **Premium Frontend Structure**
```
frontend/
├── js/
│   ├── premium-*.js     # Premium Three.js components
│   ├── romanian-*.js    # Cultural authenticity features
│   ├── mobile-*.js      # Mobile optimization system
│   └── game-ui.js       # Core game interface
├── css/
│   └── premium-glass-morphism.css  # Romanian heritage styling
└── premium-demo.html    # Complete premium demonstration
```

## 🌐 MULTIPLAYER ARCHITECTURE

### **WebSocket Protocol**
- **Connection**: `ws://localhost:8080/ws/connect`
- **Authentication**: Development auto-auth for testing
- **Real-time Sync**: Card plays, game state, player actions
- **Graceful Fallbacks**: Single-player mode when backend unavailable

### **Database Schema** 
- **PostgreSQL**: Production-ready with user sessions, game states
- **Docker Compose**: Easy development setup with persistent storage
- **Migrations**: Automated database schema management

## 🔍 QUALITY GATES & TESTING

### **Before Any Commit**
```bash
# Backend validation
cd backend && go test ./...
cd backend && go build ./...

# Frontend validation  
cd frontend && python3 -m http.server 3002 &
# Test premium demo in browser
# Verify 60 FPS performance

# Cross-platform testing
npm run test  # If available
```

### **Performance Targets**
- **Rendering**: 60 FPS on mobile devices (iPhone 11+, Android flagship)
- **Memory**: <100MB total usage for premium frontend
- **Network**: <50ms WebSocket latency for game moves
- **Startup**: <2 seconds to premium demo load

## 🚀 DEPLOYMENT & PRODUCTION

### **Current Deployment Status**
- **Backend**: Production-ready Go server with PostgreSQL
- **Frontend**: Premium PWA with offline capabilities
- **Infrastructure**: Kubernetes deployment configs available
- **Monitoring**: Performance monitoring and error tracking

### **Production Environment**
- **Primary Platforms**: Android, Desktop web browsers
- **Secondary Platform**: iOS PWA (Safari compatibility)
- **CDN**: Static asset delivery optimization
- **Auto-scaling**: Backend horizontal scaling for tournaments

## 📚 KEY DOCUMENTATION FILES

### **Implementation Guides**
- **docs/PLAN.md** - Complete project roadmap and status
- **docs/SHUFFLECATS_QUALITY_IMPLEMENTATION_PLAN.md** - Premium quality standards
- **frontend/README.md** - Frontend setup and testing guide
- **docs/game-rules.md** - Romanian Septica complete rules

### **Architecture Documentation**
- **docs/backend-api.md** - REST API documentation  
- **docs/multiplayer-protocol.md** - WebSocket protocol specification
- **docs/database-schema.md** - PostgreSQL schema design
- **docs/ui-design.md** - Premium UI/UX specifications

## 🐛 COMMON ISSUES & SOLUTIONS

### **Backend Issues**
- **Database Connection**: Ensure PostgreSQL running on port 5433
- **WebSocket Failures**: Check Go server on port 8080, verify CORS
- **Game Logic**: Validate Romanian rules in `backend/internal/game/engine.go`

### **Frontend Issues**  
- **Three.js Errors**: Check WebGL support, update graphics drivers
- **Performance Problems**: Use mobile LOD system, adjust quality settings
- **Cultural Elements**: Verify regional settings and lighting configurations

### **Development Tips**
- **Premium Demo**: Always test on `premium-demo.html` for latest features
- **Mobile Testing**: Use Chrome DevTools mobile simulation 
- **Cross-Platform**: Test on real iOS Safari and Android Chrome
- **Performance**: Monitor FPS counter and memory usage continuously

## 🎯 PROJECT GOALS & VISION

**Romanian Septica** aims to be the definitive digital implementation of the traditional Romanian card game, featuring:

- **Cultural Authenticity**: Preserving Romanian gaming heritage with regional variations
- **Premium Quality**: ShuffleCats-level visual excellence and smooth gameplay  
- **Cross-Platform Access**: Available to global Romanian diaspora on all devices
- **Competitive Play**: Tournament system with ELO ratings and cultural achievements
- **Educational Value**: Teaching traditional Romanian card game to new generations

Remember: This is a **premium cultural preservation project** that bridges traditional Romanian gaming with modern web technology. Focus on 60 FPS performance, cultural authenticity, and cross-platform accessibility.