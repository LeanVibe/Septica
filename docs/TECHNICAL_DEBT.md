# Technical Debt - Romanian Septica PWA

**Last Updated**: October 1, 2025

## 🔴 Critical Issues

### Database Migration Failure (GORM)
**Status**: Blocked - Requires investigation
**Impact**: Cannot properly initialize database schema
**Workaround**: Running backend with `SKIP_MIGRATIONS=true`

#### Problem
GORM AutoMigrate fails with "insufficient arguments" error when attempting to migrate User model:
```
Failed to run database migrations error=failed to migrate *database.User: insufficient arguments
```

#### Attempted Fixes
- ✅ Removed `default:gen_random_uuid()` from BaseModel (PostgreSQL function syntax)
- ✅ Added explicit `foreignKey` tags to all relationships
- ✅ Fixed circular reference: Changed `User User` to `User *User` in Player model
- ❌ Issue persists - deeper GORM/PostgreSQL compatibility problem

#### Root Cause Investigation Needed
- Possible GORM version incompatibility with PostgreSQL 14
- UUID handling may require PostgreSQL extensions (uuid-ossp, pgcrypto)
- Relationship constraints may have syntax issues

#### Temporary Workaround
```bash
SKIP_MIGRATIONS=true PORT=8082 go run cmd/server/main.go
```

#### Files Affected
- `backend/internal/database/models.go` - All model definitions
- `backend/internal/database/database.go` - Migration logic

---

## 🟡 High Priority Issues

### Stale Matchmaking Queue Data
**Status**: Needs cleanup
**Impact**: 1006 orphaned queue entries causing "record not found" errors

#### Problem
Database contains 1006 matchmaking queue entries referencing non-existent player records:
```
2025/10/01 16:56:45 [ERROR] Failed to create match error=record not found player1_id=xxx player2_id=xxx
```

#### Solution
```sql
-- Clean up orphaned matchmaking queue entries
DELETE FROM matchmaking_queues WHERE player_id NOT IN (SELECT id FROM players);
```

---

## 🟢 Documentation Issues

### Hybrid Architecture Documentation Clarity
**Status**: Resolved - October 2, 2025
**Impact**: Documentation now accurately reflects dual-platform implementation

#### Actual Architecture (VERIFIED)
This is a **HYBRID DUAL-PLATFORM** implementation:

**Platform 1: iOS Native App (PRIMARY)**
- ✅ 166 Swift source files, fully implemented
- ✅ Xcode project: `Septica.xcodeproj`
- ✅ Tech: Swift 6.0 + SwiftUI + Metal GPU rendering
- ✅ Platforms: iPad & iPhone (iOS 18+)
- ✅ Build Status: Successful compilation (verified October 2, 2025)
- ✅ Features: 3D rendering, Romanian cultural authenticity, AI opponents, CloudKit multiplayer

**Platform 2: Progressive Web App (SECONDARY)**
- ✅ Backend: Go + Gin framework + PostgreSQL + WebSocket
- ✅ Frontend: Premium PWA (Three.js + HTML/CSS/JS)
- ⚠️ Database: Running with `SKIP_MIGRATIONS=true` workaround (see Critical Issues)
- ✅ Features: Cross-platform web access, real-time multiplayer

#### Shared Components
- Game rules implementation (Romanian Septica 32-card deck)
- Multiplayer infrastructure (CloudKit for iOS, WebSocket for PWA)
- Romanian cultural elements (regional variations, traditional AI behavior)

#### Documentation Status
- ✅ `docs/PROJECT_STATUS.md` - Describes PWA architecture accurately
- ✅ `docs/CLAUDE.md` - PWA-focused guidance (should note iOS app exists)
- ℹ️ iOS-specific docs (PLAN.md, TODO.md, etc.) - Valid for iOS platform
- ✅ This file - Now accurately documents hybrid architecture

---

## 🔵 Future Improvements

### Database Schema Optimization
- Add proper indexes for frequently queried fields
- Implement database connection pooling optimization
- Add database backup and restore procedures

### WebSocket Performance
- Implement connection throttling
- Add reconnection backoff strategy
- Optimize message serialization

### Frontend PWA Features
- Service worker for offline gameplay
- IndexedDB for local game state persistence
- Push notifications for multiplayer matches

---

## 📋 Resolved Technical Debt

### Fixed Database Model Issues
- ✅ UUID generation removed from GORM tags
- ✅ Foreign key relationships explicitly defined
- ✅ Circular reference between User and Player models resolved
- ✅ One-by-one migration logic for better error reporting
