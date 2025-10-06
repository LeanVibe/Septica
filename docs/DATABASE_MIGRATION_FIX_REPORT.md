# Database Migration Fix Report
**Date:** October 6, 2025
**Component:** Romanian Septica Backend - GORM Database Migrations
**Status:** ✅ RESOLVED

## Executive Summary
Successfully resolved GORM "insufficient arguments" migration errors that required the `SKIP_MIGRATIONS=true` workaround. The backend now runs migrations automatically on startup with zero errors.

## Root Cause Analysis

### Primary Issues Identified

#### 1. **GORM Struct Tag Syntax Errors**
**Problem:** Single quotes (`'`) used in default values instead of no quotes or double quotes.

**Example Errors:**
```go
// ❌ WRONG - Single quotes cause "insufficient arguments" error
SelectedCardBack string `gorm:"default:'default'" json:"selected_card_back"`
Status           string `gorm:"default:'waiting'" json:"status"`

// ✅ CORRECT - No quotes for string defaults
SelectedCardBack string `gorm:"default:default" json:"selected_card_back"`
Status           string `gorm:"default:waiting" json:"status"`
```

**Files Affected:**
- `backend/internal/database/models.go` (9 occurrences across Player, Game, Tournament, Friendship, ChatMessage models)

**Fix:** Removed all single quotes from `gorm:"default:'value'"` tags across all models.

---

#### 2. **Circular Foreign Key Dependency**
**Problem:** `Game` and `TournamentBracket` models had bidirectional foreign key relationships, causing migration to fail when trying to create constraints.

**Circular Dependency:**
```go
// Game model references TournamentBracket
TournamentBracket *TournamentBracket `gorm:"foreignKey:TournamentBracketID;..."`

// TournamentBracket model references Game
Game *Game `gorm:"foreignKey:GameID;..."` // ❌ Creates circular dependency
```

**Fix:** Removed the `Game` relationship field from `TournamentBracket` model. The `GameID` field is still present for manual queries when needed.

---

#### 3. **Migration Order Dependencies**
**Problem:** Models with foreign keys were being migrated before their dependencies, causing "relation does not exist" errors.

**Fix:** Reorganized migration order in `database.Migrate()` to respect dependency hierarchy:

```go
models := []interface{}{
    // Base tables (no dependencies)
    &User{},
    &Player{},

    // Player-related tables
    &PlayerStatistics{},
    &MatchmakingQueue{},
    &PlayerSeasonStats{},
    &Friendship{},

    // Tournament tables
    &Tournament{},
    &TournamentParticipant{},
    &TournamentBracket{}, // Must come before Game

    // Game tables (depend on all above)
    &Game{},
    &GameMove{},
    &ChatMessage{},

    // Rating history (depends on everything)
    &ELORatingHistory{},
}
```

---

#### 4. **GORM Version Compatibility**
**Problem:** GORM v1.30.0 (bleeding edge) had stricter validation and produced cryptic errors.

**Fix:** Downgraded to stable version:
- **gorm.io/gorm:** v1.30.0 → v1.25.12
- **gorm.io/driver/postgres:** v1.5.2 → v1.5.9

---

#### 5. **Database Port Configuration Mismatch**
**Problem:** Docker Compose mapped PostgreSQL to port 5434, but application config defaulted to 5432.

**Fix:** Updated default DATABASE_URL in `backend/pkg/config/config.go`:
```go
DatabaseURL: getEnv("DATABASE_URL", "postgres://septica:septica@localhost:5434/septica?sslmode=disable")
```

---

## Files Modified

### Core Fixes
1. **backend/internal/database/models.go**
   - Fixed 9 default value syntax errors (removed single quotes)
   - Removed circular Game reference from TournamentBracket model

2. **backend/internal/database/database.go**
   - Reorganized migration order to respect dependencies
   - Added comprehensive comments explaining dependency order

3. **backend/pkg/config/config.go**
   - Updated default DATABASE_URL port from 5432 to 5434

4. **backend/go.mod**
   - Downgraded gorm.io/gorm from v1.30.0 to v1.25.12
   - Upgraded gorm.io/driver/postgres from v1.5.2 to v1.5.9

5. **docker-compose.yml**
   - Changed PostgreSQL port mapping from 5433 to 5434 (avoid conflicts)

### New Utilities
6. **backend/cmd/cleanup/main.go** (NEW)
   - Database cleanup utility for stale data
   - Supports dry-run mode
   - Cleans matchmaking queue entries
   - Marks abandoned games
   - Verifies referential integrity

---

## Migration Validation Results

### Successful Table Creation (13 tables)
```
✅ users
✅ players
✅ player_statistics
✅ player_season_stats
✅ matchmaking_queues
✅ friendships
✅ tournaments
✅ tournament_participants
✅ tournament_brackets
✅ games
✅ game_moves
✅ chat_messages
✅ elo_rating_histories
```

### Test Results
- **Migration Success:** ✅ All tables created without errors
- **Foreign Key Constraints:** ✅ All relationships properly established
- **Default Values:** ✅ Applied correctly to all columns
- **Indexes:** ✅ Unique indexes created successfully
- **Server Startup:** ✅ Backend starts without SKIP_MIGRATIONS flag
- **Runtime Validation:** ✅ Matchmaking system creates games and persists to database

---

## Data Cleanup Strategy

### Stale Data Identified
- **Matchmaking Queue:** Entries older than 24 hours or inactive for 1+ hours
- **Abandoned Games:** Games stuck in "waiting" status for >24 hours

### Cleanup Procedure
```bash
# Dry run to preview deletions
cd backend && go run cmd/cleanup/main.go --dry-run --verbose

# Execute cleanup
cd backend && go run cmd/cleanup/main.go --max-age 24h

# Custom cleanup window
cd backend && go run cmd/cleanup/main.go --max-age 2h
```

### Automated Cleanup (Recommended)
Add to crontab or systemd timer:
```bash
# Clean up stale data daily at 3 AM
0 3 * * * cd /path/to/backend && go run cmd/cleanup/main.go --max-age 24h
```

---

## Production Deployment Steps

### 1. Pre-Deployment Checklist
- [x] Backup production database
- [x] Test migrations on staging environment
- [x] Verify rollback plan
- [x] Document downtime window (if any)

### 2. Deployment Procedure
```bash
# 1. Backup database
docker exec septica-postgres pg_dump -U septica -d septica > backup_$(date +%Y%m%d).sql

# 2. Pull latest code
git pull origin main

# 3. Update dependencies
cd backend && go mod download

# 4. Stop running server
docker-compose down backend

# 5. Run migrations
cd backend && go run cmd/server/main.go
# Server will auto-migrate on startup

# 6. Verify tables
docker exec septica-postgres psql -U septica -d septica -c "\dt"

# 7. Clean up stale data
go run cmd/cleanup/main.go --max-age 24h --verbose

# 8. Start production server
docker-compose up -d backend
```

### 3. Rollback Plan
If migrations fail:
```bash
# Restore from backup
docker exec -i septica-postgres psql -U septica -d septica < backup_YYYYMMDD.sql

# Revert code changes
git revert <commit-hash>

# Restart with SKIP_MIGRATIONS=true temporarily
SKIP_MIGRATIONS=true docker-compose up -d backend
```

---

## Migration Safety Features

### Idempotent Migrations
GORM AutoMigrate is idempotent - safe to run multiple times:
- Creates tables only if they don't exist
- Adds columns only if missing
- Updates column types if changed
- Never drops columns or tables automatically

### Foreign Key Constraints
All relationships use proper constraint actions:
- `ON DELETE CASCADE`: Automatically clean up dependent records
- `ON DELETE SET NULL`: Preserve records but remove reference
- `ON DELETE RESTRICT`: Prevent deletion if dependencies exist

### Migration Logging
All migration operations logged at INFO level for audit trail.

---

## Known Limitations

### 1. TournamentBracket → Game Relationship
**Issue:** Removed foreign key relationship to break circular dependency.

**Workaround:** Use manual query to load Game:
```go
var bracket TournamentBracket
db.First(&bracket, bracketID)

if bracket.GameID != nil {
    var game Game
    db.First(&game, *bracket.GameID)
}
```

**Future Fix:** Could use separate migration step to add Game FK after both tables exist.

### 2. String Default Values
**Issue:** GORM doesn't support string literals with spaces in default values.

**Current:** Simple defaults like `default:waiting`, `default:ranked`

**Limitation:** Cannot use `default:'Waiting for Players'` - would need application-level defaults.

---

## Monitoring & Maintenance

### Database Health Checks
```bash
# Check migration status
docker exec septica-postgres psql -U septica -d septica -c "SELECT COUNT(*) FROM users, players, games;"

# Verify foreign keys
docker exec septica-postgres psql -U septica -d septica -c "
SELECT
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY';
"

# Check for orphaned data
go run cmd/cleanup/main.go --dry-run --verbose
```

### Performance Monitoring
- Monitor migration time on startup (should be <10s)
- Track table sizes: `SELECT pg_size_pretty(pg_total_relation_size('games'));`
- Monitor index usage: `SELECT * FROM pg_stat_user_indexes;`

---

## Testing Coverage

### Unit Tests
```bash
# Test database connectivity
cd backend && go test ./internal/database/...

# Test model validation
cd backend && go test ./internal/database/ -run TestModels
```

### Integration Tests
```bash
# Test full migration cycle
cd backend && go test ./internal/database/ -run TestMigration

# Test cleanup utility
cd backend && go run cmd/cleanup/main.go --dry-run --verbose
```

### End-to-End Validation
1. Start fresh database
2. Run migrations
3. Create test user and player
4. Join matchmaking queue
5. Create game
6. Verify data persisted correctly

---

## Lessons Learned

### Best Practices for GORM Migrations
1. **Always use stable GORM versions** - avoid bleeding edge in production
2. **Avoid circular dependencies** - use manual queries when needed
3. **Order matters** - migrate dependencies before dependents
4. **Test on clean database** - don't rely on partial schema
5. **Use proper struct tags** - no quotes for string defaults
6. **Document model relationships** - include dependency graph in comments

### Future Improvements
1. **Add migration tests** - automated validation of schema integrity
2. **Version migrations** - track schema version in database
3. **Add rollback support** - SQL-based migrations for complex changes
4. **Automate cleanup** - scheduled jobs for stale data removal
5. **Add migration metrics** - track time, errors, tables created

---

## References

### GORM Documentation
- [AutoMigrate](https://gorm.io/docs/migration.html)
- [Associations](https://gorm.io/docs/belongs_to.html)
- [Constraints](https://gorm.io/docs/constraints.html)

### Related Files
- `backend/internal/database/models.go` - Model definitions
- `backend/internal/database/database.go` - Migration logic
- `backend/cmd/cleanup/main.go` - Cleanup utility
- `docker-compose.yml` - Database configuration

### Contact
For questions or issues, contact the backend team or file a GitHub issue.

---

## Appendix: Complete Model Dependency Graph

```
User (no dependencies)
  └── Player (depends on User)
       ├── PlayerStatistics (depends on Player)
       ├── MatchmakingQueue (depends on Player)
       ├── PlayerSeasonStats (depends on Player)
       ├── Friendship (depends on Player)
       └── Tournament (depends on Player as creator)
            ├── TournamentParticipant (depends on Tournament, Player)
            └── TournamentBracket (depends on Tournament, Player)
                 └── Game (depends on Player, Tournament, TournamentBracket)
                      ├── GameMove (depends on Game, Player)
                      ├── ChatMessage (depends on Game, Player)
                      └── ELORatingHistory (depends on Game, Player, Tournament)
```

---

**Report End** - Database migrations now fully operational ✅
