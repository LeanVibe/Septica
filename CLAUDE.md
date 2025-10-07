# CLAUDE.md - Romanian Septica PWA Project Navigation Guide

This file provides guidance to Claude Code (claude.ai/code) when working with the Romanian Septica multiplayer card game - a **Go backend + Premium PWA frontend** implementation.

## 🚀 SESSION CONTEXT MANAGEMENT - READ THIS FIRST

### **CURRENT PROJECT STATUS (October 2025)**
```
✅ Phase 1: Go Backend Implementation - COMPLETE (Romanian Septica rules verified)
✅ Phase 2: WebSocket Multiplayer Protocol - COMPLETE (Real-time sync operational)
✅ Phase 3: Premium PWA/Three.js Frontend - COMPLETE (ShuffleCats quality achieved)
✅ Phase 4: Documentation Cleanup - COMPLETE (iOS confusion resolved)
✅ Phase 5: Database Migration Fix - COMPLETE (automatic migrations operational)
🔴 CRITICAL: AI Matchmaking Issues (3 bugs - duplicate users, missing game IDs, auto-join failures)
🎯 CURRENT FOCUS: AI matchmaking reliability, data integrity, production readiness
```

### **CRITICAL CONTEXT FILES TO READ ON SESSION START:**
1. **docs/PROJECT_STATUS.md** - Current consolidated project status (AUTHORITATIVE)
2. **docs/TECHNICAL_DEBT.md** - Known issues and workarounds
3. **docs/game-rules.md** - Romanian Septica rules implementation
4. **PROJECT_INDEX.json** - Complete project structure and codebase overview

### **IMMEDIATE NEXT PRIORITIES:**
1. **AI Matchmaking Duplicate User Fix** - Implement GetOrCreateUser logic (CRITICAL)
2. **AI Moves Missing Game ID Fix** - Pass game context to AI engine (CRITICAL)
3. **Auto-Join Timing Fix** - Add transaction safety and retry logic (CRITICAL)
4. **Automated Queue Cleanup** - Prevent orphaned entry accumulation
5. **End-to-End AI Testing** - Validate complete AI opponent gameplay flow

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
# Start Go backend server (database migrations automatic)
cd backend && PORT=8082 go run cmd/server/main.go

# Start PostgreSQL database
docker-compose up -d

# Backend tests
cd backend && go test ./...
```

### **Frontend Commands**
```bash
# Start premium frontend server
cd frontend && python3 -m http.server 3000

# Test premium demo
open http://localhost:3000/premium-demo.html

# Test three.js demo
open http://localhost:3000/three-js-demo.html
```

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
└── *.html              # Various demo and game interfaces
```

## 🌐 MULTIPLAYER ARCHITECTURE

### **WebSocket Protocol**
- **Connection**: `ws://localhost:8082/ws/connect` (current running port)
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
cd backend && go build ./cmd/server

# Frontend validation
cd frontend && python3 -m http.server 3000 &
# Test premium demo in browser
# Verify 60 FPS performance

# E2E Testing
./run-comprehensive-enterprise-e2e.sh
```

### **Performance Targets**
- **Rendering**: 60 FPS on mobile devices (iPhone 11+, Android flagship)
- **Memory**: <100MB total usage for premium frontend
- **Network**: <50ms WebSocket latency for game moves
- **Startup**: <2 seconds to premium demo load

## 📚 KEY DOCUMENTATION FILES

### **Essential Documentation**
- **docs/PROJECT_STATUS.md** - Complete project status and architecture (START HERE)
- **docs/TECHNICAL_DEBT.md** - Known issues, workarounds, and fixes needed
- **docs/game-rules.md** - Romanian Septica complete rules

### **Architecture Documentation**
- **docs/backend-api.md** - REST API documentation
- **docs/multiplayer-protocol.md** - WebSocket protocol specification
- **docs/database-schema.md** - PostgreSQL schema design

### **Archived Documentation**
- **docs/archive/ios-confusion/** - Outdated iOS-focused documentation (DO NOT USE)

## 🐛 COMMON ISSUES & SOLUTIONS

### **Backend Issues**
- **AI Matchmaking Bugs**: 3 critical issues affecting AI opponent gameplay
  - Duplicate user creation errors (database constraint violations)
  - AI moves missing game_id (moves fail to persist)
  - Auto-join timing failures (players stuck in queue)
- **Database Connection**: Ensure PostgreSQL running on port 5433
- **WebSocket Failures**: Check Go server on port 8082, verify CORS
- **Game Logic**: Validate Romanian rules in `backend/internal/game/engine.go`
- **Queue Data**: Orphaned entries accumulating (automated cleanup needed)

### **Frontend Issues**
- **Three.js Errors**: Check WebGL support, update graphics drivers
- **Performance Problems**: Use mobile LOD system, adjust quality settings
- **Cultural Elements**: Verify regional settings and lighting configurations

## 🎯 PROJECT GOALS & VISION

**Romanian Septica** aims to be the definitive digital implementation of the traditional Romanian card game, featuring:

- **Cultural Authenticity**: Preserving Romanian gaming heritage with regional variations
- **Premium Quality**: ShuffleCats-level visual excellence and smooth gameplay
- **Cross-Platform Access**: Available to global Romanian diaspora on all devices
- **Competitive Play**: Tournament system with ELO ratings and cultural achievements
- **Educational Value**: Teaching traditional Romanian card game to new generations

## 📊 CURRENT RUNNING SERVICES

Based on background processes:
- **Backend Server**: Running on port 8082 (Go server)
- **Frontend Server**: Running on port 3000 (Python HTTP server)
- **Database**: PostgreSQL available via Docker
- **E2E Tests**: Comprehensive test suite available

Remember: This is a **premium cultural preservation project** that bridges traditional Romanian gaming with modern web technology. Focus on performance, cultural authenticity, and cross-platform accessibility.