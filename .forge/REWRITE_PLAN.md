# Septica Rewrite: 14-Day Sprint Plan

**Version:** 1.0
**Created:** 2026-02-02
**Sprint Duration:** 14 days
**Team:** Solo developer with AI assistance

---

## Executive Summary

This sprint transforms the Septica codebase from a monolithic vanilla JS frontend (2,436 lines) to a modern React 19 + TypeScript architecture while consolidating dual backend engines into a single Authentic Engine.

### Goals
1. **Frontend:** Migrate `game-ui.js` (2,436 lines) to 10 React modules
2. **Backend:** Delete legacy `engine.go` (471 lines), use only `authentic_engine.go` (746 lines)
3. **Test Coverage:** Achieve 80% unit test coverage, 100% WebSocket protocol coverage
4. **Deployment:** Production-ready PWA with offline support

---

## Architecture Decisions

### ADR-001: React 19 + TypeScript for Frontend

**Status:** Accepted
**Context:** Current `game-ui.js` is a 2,436-line monolithic class mixing state, rendering, and networking.
**Decision:** Use React 19 with TypeScript, Zustand for state, and native WebSocket client.
**Rationale:**
- React 19 provides concurrent rendering for smooth card animations
- TypeScript catches type errors at compile time (critical for card game logic)
- Zustand offers minimal boilerplate with excellent DevTools support
- Scaffold already created at `frontend-v2/` with dependencies installed

**Consequences:**
- (+) Type-safe WebSocket message handling
- (+) Component-level testing with React Testing Library
- (+) Hot module replacement during development
- (-) Learning curve for Three.js integration with React

### ADR-002: Single Authentic Engine Backend

**Status:** Accepted
**Context:** Two parallel game engines exist - legacy (471 lines) and authentic (746 lines).
**Decision:** Delete `engine.go`, use only `authentic_engine.go`.
**Rationale:**
- Authentic engine supports 2-4 players vs only 2 in legacy
- Full objection workflow implementation
- Database persistence with GORM
- Team play support for 4-player mode
- 97% test coverage already exists

**Consequences:**
- (+) Single source of truth for game rules
- (+) Database-backed game history
- (+) Supports all planned game modes
- (-) Must verify all WebSocket handlers work with Authentic engine

### ADR-003: WebSocket Protocol Preservation

**Status:** Accepted
**Context:** WebSocket protocol is stable and documented in `CODEBASE_ANALYSIS.md`.
**Decision:** Preserve existing message formats; add TypeScript types only.
**Rationale:**
- Backend handlers already tested
- Protocol documentation is complete
- Breaking changes would require backend modifications

**Consequences:**
- (+) Zero backend changes for frontend rewrite
- (+) Existing tests remain valid
- (-) Some message shapes are not optimal (legacy compatibility)

### ADR-004: Zustand for State Management

**Status:** Accepted
**Context:** Need reactive state for game state, connection status, and UI state.
**Decision:** Use Zustand with separate stores for game, connection, and UI.
**Rationale:**
- Already installed in `frontend-v2/package.json` (v5.0.11)
- Simpler than Redux, more structured than useState
- DevTools support for debugging game state
- Works well with WebSocket updates

**Consequences:**
- (+) Minimal boilerplate
- (+) TypeScript inference
- (+) Testable stores
- (-) Less ecosystem than Redux

### ADR-005: Incremental Migration Strategy

**Status:** Accepted
**Context:** Cannot do a big-bang rewrite; need to maintain playability.
**Decision:** Extract modules incrementally, maintain parallel frontends during transition.
**Rationale:**
- Old frontend (`frontend/`) remains functional during sprint
- New frontend (`frontend-v2/`) can be tested independently
- Can compare behavior between implementations

**Consequences:**
- (+) Lower risk of breaking existing functionality
- (+) Can demo progress incrementally
- (-) Temporary duplication of some code

---

## Module Architecture

### Frontend Modules (10 total)

| Module | Location | Lines (est.) | Responsibility |
|--------|----------|--------------|----------------|
| **GameStore** | `stores/gameStore.ts` | ~150 | Game state, cards, scores |
| **ConnectionStore** | `stores/connectionStore.ts` | ~100 | WebSocket status, latency |
| **WebSocketClient** | `services/WebSocketClient.ts` | ~200 | Connection, heartbeat, reconnect |
| **RomanianRules** | `services/romanianRules.ts` | ~100 | Move validation, point calculation |
| **GameBoard** | `components/Game/GameBoard.tsx` | ~150 | Main game container |
| **CardHand** | `components/Game/CardHand.tsx` | ~200 | Player's card display |
| **TableArea** | `components/Game/TableArea.tsx` | ~150 | Cards on table |
| **ObjectionPanel** | `components/Game/ObjectionPanel.tsx` | ~100 | Object/pass buttons |
| **ScoreBoard** | `components/UI/ScoreBoard.tsx` | ~80 | Score display |
| **ConnectionStatus** | `components/UI/ConnectionStatus.tsx` | ~60 | Connection indicator |

### Backend Changes

| Action | File | Description |
|--------|------|-------------|
| **DELETE** | `engine.go` | Legacy 2-player engine (471 lines) |
| **DELETE** | `engine_test.go` | Legacy engine tests |
| **KEEP** | `authentic_engine.go` | Primary engine (746 lines) |
| **KEEP** | `authentic_engine_test.go` | Engine tests |
| **UPDATE** | WebSocket handlers | Point to Authentic engine only |

---

## Day-by-Day Plan

### Week 1: Foundation and Core Components

#### Day 1 (Setup and Types)
**Goal:** Establish TypeScript foundation and WebSocket types

- [ ] Extend `types/game.ts` with complete GameState interface
- [ ] Create `types/websocket.ts` with all message types
- [ ] Create `types/player.ts` for multiplayer support
- [ ] Set up Tailwind CSS configuration
- [ ] Configure path aliases in `tsconfig.json`

**Deliverables:**
```
frontend-v2/src/types/
  game.ts        # Card, GameState, RoundResult
  websocket.ts   # All WS message types
  player.ts      # Player, Team interfaces
  index.ts       # Barrel export
```

**Acceptance Criteria:**
- All types compile without errors
- Types match `CODEBASE_ANALYSIS.md` protocol spec

---

#### Day 2 (WebSocket Client)
**Goal:** Implement type-safe WebSocket client

- [ ] Create `WebSocketClient.ts` with connection management
- [ ] Implement heartbeat/ping-pong
- [ ] Add automatic reconnection with exponential backoff
- [ ] Create event emitter for message routing
- [ ] Add connection state tracking

**Deliverables:**
```
frontend-v2/src/services/
  WebSocketClient.ts    # Core WS client class
  messageHandlers.ts    # Message routing
```

**Acceptance Criteria:**
- Connects to `ws://localhost:8082/ws/connect`
- Handles disconnect/reconnect gracefully
- Emits typed events for all message types

---

#### Day 3 (State Management)
**Goal:** Implement Zustand stores

- [ ] Create `gameStore.ts` for game state
- [ ] Create `connectionStore.ts` for WS status
- [ ] Create `uiStore.ts` for UI state (modals, toasts)
- [ ] Wire WebSocket events to store updates
- [ ] Add DevTools middleware

**Deliverables:**
```
frontend-v2/src/stores/
  gameStore.ts         # Game state + actions
  connectionStore.ts   # Connection state
  uiStore.ts           # UI state
  index.ts             # Barrel export
```

**Acceptance Criteria:**
- Stores update correctly from WS messages
- DevTools show state changes
- Actions are typed correctly

---

#### Day 4 (Romanian Rules Engine)
**Goal:** Port Romanian Septica rules to TypeScript

- [ ] Create `romanianRules.ts` with move validation
- [ ] Implement point calculation (10s, Aces)
- [ ] Add wild card logic (7s, 8s in 3-player)
- [ ] Create `canBeat()` function for valid moves
- [ ] Add unit tests for all rules

**Deliverables:**
```
frontend-v2/src/services/
  romanianRules.ts     # Rule engine
  romanianRules.test.ts # Unit tests
```

**Acceptance Criteria:**
- All rule tests pass
- Matches backend `authentic_engine.go` logic
- 100% coverage on rule functions

---

#### Day 5 (Card Component)
**Goal:** Create reusable Card component

- [ ] Design Card component with suit/rank display
- [ ] Add hover and selection states
- [ ] Implement card flip animation (CSS)
- [ ] Create card back design
- [ ] Add accessibility attributes

**Deliverables:**
```
frontend-v2/src/components/
  Card/
    Card.tsx           # Card component
    Card.css           # Card styles
    cardAssets.ts      # Suit/rank mappings
```

**Acceptance Criteria:**
- Card renders correctly for all 32 cards
- Smooth flip animation
- Keyboard accessible (Enter/Space to select)

---

#### Day 6 (CardHand Component)
**Goal:** Render player's hand with interactions

- [ ] Create CardHand layout component
- [ ] Add card selection handling
- [ ] Show valid moves highlighting
- [ ] Implement card play animation
- [ ] Handle hand updates from server

**Deliverables:**
```
frontend-v2/src/components/Game/
  CardHand.tsx         # Hand display
  CardHand.test.tsx    # Component tests
```

**Acceptance Criteria:**
- Displays 1-8 cards correctly
- Highlights valid moves
- Click to select, double-click to play

---

#### Day 7 (TableArea and Integration)
**Goal:** Complete table display and wire up game flow

- [ ] Create TableArea component for played cards
- [ ] Show last played card prominently
- [ ] Add card collection animation
- [ ] Wire up gameStore to components
- [ ] Test full game state flow

**Deliverables:**
```
frontend-v2/src/components/Game/
  TableArea.tsx        # Table display
  GameBoard.tsx        # Main game container
```

**Acceptance Criteria:**
- Cards on table display correctly
- Game state flows from WS -> store -> UI
- Can play a card (end-to-end)

---

### Week 2: Features and Polish

#### Day 8 (Objection System)
**Goal:** Implement Romanian Septica objection UI

- [ ] Create ObjectionPanel component
- [ ] Add Object/Pass buttons
- [ ] Implement objection timer (10s)
- [ ] Show valid objection cards
- [ ] Handle objection phase state

**Deliverables:**
```
frontend-v2/src/components/Game/
  ObjectionPanel.tsx   # Objection UI
  ObjectionTimer.tsx   # Countdown timer
```

**Acceptance Criteria:**
- Objection panel appears when `waiting_for_objection`
- Timer counts down from 10s
- Auto-pass on timeout

---

#### Day 9 (Multiplayer UI)
**Goal:** Support 2-4 player display

- [ ] Create PlayerBadge component
- [ ] Implement 2/3/4 player layouts
- [ ] Show opponent card backs with count
- [ ] Add turn indicator
- [ ] Display team colors (4-player mode)

**Deliverables:**
```
frontend-v2/src/components/Game/
  PlayerBadge.tsx      # Player info
  TurnIndicator.tsx    # Turn display
  OpponentHand.tsx     # Opponent card backs
```

**Acceptance Criteria:**
- Layouts work for 2, 3, 4 players
- Current player clearly indicated
- Team affiliations visible in 4-player

---

#### Day 10 (Scoring and Game End)
**Goal:** Complete scoring UI and game end flow

- [ ] Create ScoreBoard component
- [ ] Add round complete overlay
- [ ] Implement game end screen
- [ ] Show winner announcement
- [ ] Add "Play Again" flow

**Deliverables:**
```
frontend-v2/src/components/UI/
  ScoreBoard.tsx       # Live scores
  RoundComplete.tsx    # Round overlay
  GameEnd.tsx          # Game over screen
```

**Acceptance Criteria:**
- Scores update in real-time
- Round complete shows points awarded
- Game end shows final scores and winner

---

#### Day 11 (Connection and Error Handling)
**Goal:** Robust connection handling and error states

- [ ] Create ConnectionStatus component
- [ ] Add reconnection UI
- [ ] Implement error toast system
- [ ] Handle all error types from server
- [ ] Add offline detection

**Deliverables:**
```
frontend-v2/src/components/UI/
  ConnectionStatus.tsx # Connection indicator
  ErrorToast.tsx       # Error messages
  ReconnectOverlay.tsx # Reconnecting UI
```

**Acceptance Criteria:**
- Shows connection state (connected/reconnecting/offline)
- Errors display as toasts
- Graceful degradation when offline

---

#### Day 12 (Backend Cleanup)
**Goal:** Remove legacy engine, verify Authentic engine

- [ ] Delete `backend/internal/game/engine.go`
- [ ] Delete `backend/internal/game/engine_test.go`
- [ ] Update all imports to use Authentic engine
- [ ] Run full test suite
- [ ] Verify WebSocket handlers work

**Deliverables:**
- Removed legacy engine files
- All tests pass
- Backend serves only Authentic engine

**Acceptance Criteria:**
- `go test ./...` passes
- No references to legacy engine
- WebSocket handlers work with new frontend

---

#### Day 13 (Testing and QA)
**Goal:** Comprehensive testing

- [ ] Write integration tests for WebSocket client
- [ ] Write component tests for all Game components
- [ ] Write E2E test for complete game flow
- [ ] Test 2-player, 3-player, 4-player modes
- [ ] Test reconnection scenarios

**Deliverables:**
```
frontend-v2/src/
  __tests__/
    integration/
      WebSocketClient.test.ts
    components/
      GameBoard.test.tsx
      CardHand.test.tsx
    e2e/
      gameFlow.test.ts
```

**Acceptance Criteria:**
- Unit test coverage >= 80%
- All E2E tests pass
- Manual QA checklist complete

---

#### Day 14 (Polish and Deployment)
**Goal:** Production readiness

- [ ] Add PWA manifest and service worker
- [ ] Configure production build
- [ ] Optimize bundle size
- [ ] Add loading states and skeleton UI
- [ ] Create deployment script
- [ ] Update documentation

**Deliverables:**
- Production-ready build
- Deployment documentation
- Updated CLAUDE.md

**Acceptance Criteria:**
- Build size < 200KB (gzipped)
- Lighthouse PWA score >= 90
- Works offline (view last game state)

---

## Migration Strategy

### Phase 1: Parallel Development (Days 1-11)

```
frontend/         # Existing vanilla JS (operational)
frontend-v2/      # New React app (in development)
```

- Both frontends connect to same backend
- Test new frontend against production backend
- No breaking changes to backend

### Phase 2: Backend Consolidation (Day 12)

```bash
# Before
backend/internal/game/
  engine.go              # Legacy (DELETE)
  engine_test.go         # Legacy (DELETE)
  authentic_engine.go    # Keep
  authentic_engine_*.go  # Keep

# After
backend/internal/game/
  engine.go              # Renamed from authentic_engine.go
  engine_test.go         # Renamed from authentic_engine_test.go
```

### Phase 3: Frontend Cutover (Day 14)

```bash
# Rename directories
mv frontend frontend-legacy
mv frontend-v2 frontend

# Update deployment scripts
```

### Rollback Plan

If critical issues found:
1. Revert directory rename
2. Restore legacy engine from git
3. Continue using `frontend-legacy/`

---

## Test Coverage Targets

### Unit Tests

| Module | Target | Current |
|--------|--------|---------|
| romanianRules.ts | 100% | 0% |
| WebSocketClient.ts | 90% | 0% |
| gameStore.ts | 90% | 0% |
| Card.tsx | 80% | 0% |
| CardHand.tsx | 80% | 0% |
| ObjectionPanel.tsx | 90% | 0% |

### Integration Tests

| Flow | Target |
|------|--------|
| WebSocket connect/disconnect | 100% |
| Game join/leave | 100% |
| Card play | 100% |
| Objection flow | 100% |

### E2E Tests

| Scenario | Target |
|----------|--------|
| Complete 2-player game | Pass |
| Complete 3-player game | Pass |
| Complete 4-player team game | Pass |
| Reconnection mid-game | Pass |
| Offline mode | Pass |

---

## Deployment Checklist

### Pre-Deployment

- [ ] All tests pass (`npm run test`)
- [ ] Build succeeds (`npm run build`)
- [ ] Bundle size under 200KB gzipped
- [ ] No console errors in production build
- [ ] PWA manifest valid
- [ ] Service worker registers
- [ ] Lighthouse audit >= 90 (PWA, Performance, A11y)

### Environment Variables

```env
VITE_WS_URL=wss://septica.leanvibe.dev/ws/connect
VITE_API_URL=https://septica.leanvibe.dev/api
VITE_ENV=production
```

### Deployment Steps

```bash
# 1. Build production bundle
cd frontend-v2
npm run build

# 2. Test production build locally
npm run preview

# 3. Deploy to CDN/hosting
# (Railway, Cloudflare Pages, etc.)

# 4. Verify WebSocket connection
curl -i -N -H "Connection: Upgrade" \
  -H "Upgrade: websocket" \
  -H "Sec-WebSocket-Key: test" \
  -H "Sec-WebSocket-Version: 13" \
  https://septica.leanvibe.dev/ws/connect
```

### Post-Deployment

- [ ] Verify game creation works
- [ ] Verify multiplayer connection works
- [ ] Test on mobile devices
- [ ] Monitor error logs (Sentry)
- [ ] Check WebSocket connection stability

---

## Risk Register

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| WebSocket protocol mismatch | High | Medium | Freeze protocol spec; test against running backend |
| React 19 breaking changes | Medium | Low | Lock dependency versions; test thoroughly |
| Three.js integration issues | Medium | Medium | Phase 2 scope (after MVP); use 2D fallback |
| Zustand performance | Low | Low | Profile early; can switch to Jotai if needed |
| Mobile performance | Medium | Medium | Test on real devices; add LOD system |
| Team play bugs | High | Medium | Extensive testing of 4-player mode |

---

## Success Criteria

### Sprint Complete When:

1. **Frontend:**
   - All 10 modules implemented
   - 80% unit test coverage
   - Production build < 200KB
   - PWA score >= 90

2. **Backend:**
   - Legacy engine deleted
   - All tests pass
   - Single engine source of truth

3. **Functionality:**
   - 2-player game works end-to-end
   - 3-player game works end-to-end
   - 4-player team game works end-to-end
   - Objection system works correctly

4. **Quality:**
   - No console errors
   - Responsive on mobile
   - Works offline (read-only)

---

## References

- **Codebase Analysis:** `.forge/CODEBASE_ANALYSIS.md`
- **Game Rules:** `docs/game-rules.md`
- **WebSocket Protocol:** Section 4 of CODEBASE_ANALYSIS.md
- **Romanian Septica Rules:** Section 5 of CODEBASE_ANALYSIS.md

---

**Plan Status:** READY FOR EXECUTION
**Last Updated:** 2026-02-02
