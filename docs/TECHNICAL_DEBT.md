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

### Incorrect Project Architecture Documentation
**Status**: In progress
**Impact**: Confusion about project technology stack

#### Problem
Multiple documentation files incorrectly describe this as an iOS Swift/SwiftUI project:
- `docs/PLAN.md` - References "Romanian Septica iOS App"
- `docs/TODO.md` - Describes iOS development phases with CloudKit
- `docs/ENHANCEMENT_ROADMAP.md` - Contains Swift/SwiftUI code examples
- `docs/PROGRESS_SUMMARY.md` - Claims iOS app achievements

#### Actual Architecture
- **Backend**: Go + Gin framework + PostgreSQL + WebSocket
- **Frontend**: Premium PWA (HTML/CSS/JS + Three.js)
- **No iOS codebase exists**

#### Resolution Plan
1. Archive incorrect docs to `docs/archive/ios-confusion/`
2. Update `docs/CLAUDE.md` as single source of truth (already accurate)
3. Create new consolidated `docs/PROJECT_STATUS.md` for PWA architecture
4. Update `PROJECT_INDEX.json` to reflect reality

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
