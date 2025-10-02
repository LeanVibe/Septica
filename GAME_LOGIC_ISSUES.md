# Romanian Septica - Game Logic Issues & Fixes

**Date**: October 2, 2025
**Priority**: CRITICAL - Fundamental gameplay mechanics incorrect

---

## 🔴 Critical Issue: Incorrect Game Flow Implementation

### **Problem Summary**
Both iOS and Go backend implementations treat Romanian Septica as an **automatic trick-taking game**, but it's actually an **objection-based game** where players can CHOOSE to pass.

### **Current (INCORRECT) Implementation**
```
Player 1 plays card → Player 2 MUST beat if able → Automatic trick resolution
```

### **Correct Romanian Septica Rules**
```
Player 1 plays card → Player 2 CHOOSES:
  - OBJECT (play beating card)
  - OR PASS (do nothing, Player 1 takes cards)
```

---

## 📋 Specific Discrepancies

### 1. **Missing PASS Action** ❌
**Affected**: iOS + Go Backend

**Current Behavior**:
- Players automatically beat cards if they have valid moves
- No option to pass/decline objection
- Trick automatically completes when opponent can't beat

**Required Behavior**:
- Player explicitly chooses "OBJECT" or "PASS"
- If PASS: Player who last played card takes all table cards
- If OBJECT: Objecting player plays card and becomes current player
- Strategic decision: Pass when few/no point cards on table

**Impact**: GAME-BREAKING - Changes fundamental strategy

---

### 2. **8-Beats Rule in 2-Player Games** ❌
**Affected**: iOS + Go Backend

**Current Implementation**:
```swift
// iOS (GameRules.swift:77)
if attackingCard.value == 8 && tableCardsCount % 3 == 0 {
    return true
}

// Go (engine.go:292)
if card.Value == 8 && len(tableCards) > 0 && len(tableCards)%3 == 0 {
    return true
}
```

**Problem**:
- 8s are NOT wild cards in 2-player Septica
- 8s are ONLY wild in 3-player games (with reduced deck)
- The "% 3 == 0" rule is not part of official Romanian Septica

**From game-rules.md**:
```
### Wild Cards (Tăieturi)
- **7s:** Always wild cards (can beat any card)
- **8s (3 players only):** The remaining 2 eights become wild cards
```

**Required Fix**:
- Remove 8-beating rule from 2-player mode
- Only allow 8s as wild in 3-player mode (with 30-card deck)

**Impact**: HIGH - Changes game balance, affects AI strategy

---

### 3. **Suit Priority for 7s** ⚠️
**Affected**: Go Backend (iOS missing)

**Go Implementation** (engine.go:284-288):
```go
// If both are 7s, check suit priority (spades > hearts > diamonds > clubs)
if card.Value == 7 {
    return getSuitPriority(card.Suit) > getSuitPriority(topCard.Suit)
}
```

**iOS Implementation**:
```swift
// Missing - any 7 beats any 7
if attackingCard.value == targetCard.value {
    return true
}
```

**From game-rules.md**:
> "When multiple wild cards are played, standard suit priority applies"

**Status**: UNCLEAR - game-rules.md mentions suit priority but doesn't specify order

**Required**:
- Clarify exact suit priority order for Romanian Septica
- Apply consistently across both platforms

**Impact**: MEDIUM - Only matters when both players play 7s (rare)

---

## 🎯 Required Implementation Changes

### **Phase 1: Add PASS/OBJECT Choice System**

#### iOS Changes (GameState.swift)
```swift
enum PlayerAction {
    case playCard(Card)
    case pass
}

struct TurnState {
    let canObject: Bool           // Can player beat current card?
    let validCards: [Card]        // Cards that can beat
    let pointsAtStake: Int        // Points on table
    let waitingForObjection: Bool // Is it objection decision time?
}
```

#### Go Backend Changes (engine.go)
```go
type PlayerAction struct {
    Type     string // "PLAY_CARD" or "PASS"
    Card     *Card  // nil for PASS
    PlayerID uuid.UUID
}

type GameState struct {
    // ... existing fields ...
    WaitingForObjection bool
    LastPlayedCard      *Card
    ObjectionDeadline   *time.Time // 30 second timer
}
```

### **Phase 2: Update Game Flow Logic**

#### Current Flow (INCORRECT)
```
1. Player plays card
2. Opponent's turn immediately
3. Check if opponent can beat
4. If no: Award trick to player
```

#### New Flow (CORRECT)
```
1. Player plays card
2. Set state: WaitingForObjection = true
3. Start 30-second timer
4. Opponent chooses: OBJECT or PASS
5a. If OBJECT: Add card to table, objector becomes current player
5b. If PASS or timeout: Original player takes all cards, starts new trick
```

---

### **Phase 3: Remove Incorrect 8-Beating Rule**

#### iOS (GameRules.swift)
```swift
// REMOVE lines 77-79:
// if attackingCard.value == 8 && tableCardsCount % 3 == 0 {
//     return true
// }

// UPDATE to:
// Rule 3: 8s are wild ONLY in 3-player mode
if gameMode == .threePlayers && attackingCard.value == 8 {
    return true
}
```

#### Go Backend (engine.go)
```go
// REMOVE lines 292-294:
// if card.Value == 8 && len(tableCards) > 0 && len(tableCards)%3 == 0 {
//     return true
// }

// UPDATE to:
// 8s are wild only in 3-player mode
if gameMode == ThreePlayer && card.Value == 8 {
    return true
}
```

---

## 🔍 Testing Requirements

### Test Scenarios

#### 1. PASS Action Test
```
Setup: Player 1 plays 9♥️ (no points), Player 2 has 9♠️
Expected: Player 2 can CHOOSE to pass (save matching card for later)
Current: Player 2 forced to play 9♠️
```

#### 2. Strategic PASS Test
```
Setup: Table has only low cards (7♦️, 9♣️), Player 2 has 7♠️
Expected: Player 2 should PASS to save 7 for higher-value cards
Current: No pass option exists
```

#### 3. 8-Beating Rule Test (2-player)
```
Setup: 2-player game, 3 cards on table, Player has 8♣️
Current (WRONG): 8♣️ can beat because 3 % 3 == 0
Expected (CORRECT): 8♣️ cannot beat (not wild in 2-player)
```

#### 4. Point Card Collection Test
```
Setup: Player 1 plays 10♥️, Player 2 has 10♠️, total 2 points on table
Expected: Player 2 OBJECTS (plays 10♠️) to collect 2 points
Current: Objection automatic (no strategic choice)
```

---

## 📊 Impact Analysis

### Gameplay Changes
- **Strategy Depth**: ++ (adds meaningful decisions)
- **Game Duration**: +20% (more cards stay on table)
- **Skill Factor**: ++ (timing objections becomes crucial)
- **AI Complexity**: ++ (must decide when to pass)

### Implementation Effort
- **iOS**: ~2-3 days (UI for PASS button, state management)
- **Go Backend**: ~1-2 days (action types, state machine)
- **Testing**: ~2 days (comprehensive scenario coverage)
- **AI Updates**: ~1 day (decision logic for passing)

### Breaking Changes
- ✅ Backward incompatible with current game states
- ✅ Requires database migration
- ✅ AI players need complete retraining
- ✅ Tutorial/onboarding updates needed

---

## 🚀 Recommended Action Plan

### Immediate (This Week)
1. ✅ Document issues (this file)
2. ⏳ Create feature branch: `fix/authentic-objection-system`
3. ⏳ Update game-rules.md with clarified PASS action mechanics
4. ⏳ Add comprehensive test suite for new rules

### Short-term (Next 2 Weeks)
1. Implement PASS action in Go backend
2. Implement PASS action in iOS app
3. Remove incorrect 8-beating rule (2-player)
4. Update AI decision logic
5. Add 30-second objection timer

### Medium-term (Next Month)
1. Clarify and implement suit priority for 7s
2. Add 3-player mode with correct 8-wild-card rules
3. Comprehensive end-to-end testing
4. Update tutorials and documentation

---

## 📖 References

- **game-rules.md**: Official Romanian Septica rules documentation
- **Septica/Models/Core/GameRules.swift**: iOS implementation (lines 65-83)
- **backend/internal/game/engine.go**: Go backend implementation (lines 268-297)

---

**Status**: DOCUMENTED - Ready for implementation
**Severity**: CRITICAL - Affects core gameplay mechanics
**Complexity**: MEDIUM-HIGH - Requires state machine refactor + UI changes
