# Septica Românească - Complete Game Rules

## 🃏 Game Overview

Septica Românească is a traditional Romanian card game of the Sedma group (similar to Hungarian Zsíros) for 2-4 players. The goal is to collect the most point cards (10s and Aces) using an objection-based system where players can challenge each other's plays. This game represents an important part of Romanian cultural heritage and social gaming tradition.

## 🎴 Card Setup

### Deck Composition
- **For 2-4 Players:** 32 cards (7, 8, 9, 10, Jack, Queen, King, Ace) from standard deck
- **For 3 Players:** 30 cards (remove 2 eights, keeping only 2 eights in deck)
- **4 Suits:** Hearts (♥️), Diamonds (♦️), Clubs (♣️), Spades (♠️)
- **Card Values:** 7 = 7, 8 = 8, 9 = 9, 10 = 10, Jack = 11, Queen = 12, King = 13, Ace = 14

### Wild Cards (Tăieturi)
- **7s:** Always wild cards (can beat any card)
- **8s (3 players only):** The remaining 2 eights become wild cards
- **Wild Card Priority:** When multiple wild cards are played, standard suit priority applies

### Point Cards
- **10s:** Each worth 1 point (4 total in deck)
- **Aces:** Each worth 1 point (4 total in deck)
- **Total Points Available:** 8 points per game
- **Victory Condition:** Player/team with most points wins
- **Double Victory:** If opponent gets zero 10s/Aces, winner gets double victory

### Initial Deal & Card Management
- Each player receives **4 cards** initially
- After each round, players receive new cards to maintain 4 cards in hand
- Game continues until all cards are played

## 🎯 Authentic Romanian Septica Game Flow

### 1. Player Configuration

#### 2 Players (Individual Play)
- Each player plays for themselves
- Direct objection-based gameplay

#### 3 Players (Individual Play)
- Each player plays for themselves
- Remove 2 eights from deck (30 cards total)
- Remaining 2 eights become wild cards (along with 7s)

#### 4 Players (Team Play)
- **Team 1:** Player 1 + Player 3
- **Team 2:** Player 2 + Player 4
- Teams share points regardless of which team member captured them
- Players alternate: P1 → P2 → P3 → P4

### 2. Core Gameplay - The Objection System

#### Round Structure
Each round follows this simple pattern:

1. **First Player's Turn**
   - First player puts down any card from their hand

2. **Second Player's Decision**
   - **OBJECT:** Play a wild card (7, or 8 in 3-player) OR same rank card
   - **DON'T OBJECT:** Do nothing, let the first player take the cards

3. **Card Collection**
   - **If NO objection:** First player takes all table cards
   - **If objection made:** Objecting player takes all table cards

#### Objection Rules (Tăiere)
You can object by playing:
- **7 (always):** Can beat any card - most powerful
- **Same rank:** K♥️ can beat K♠️, 10♣️ can beat 10♦️
- **8 (3-player only):** The remaining 2 eights act as wild cards

#### Strategic Decision Making
The key to Romanian Septica is deciding WHEN to object:
- **Don't object** when few/no point cards are on table
- **Object** when valuable cards (10s, Aces) are at stake
- **Save wild cards** for crucial moments with many points

## 📊 Scoring System

### Point Calculation
```
10s = 1 point each (♥️10, ♦️10, ♣️10, ♠️10) = 4 points total
Aces = 1 point each (♥️A, ♦️A, ♣️A, ♠️A) = 4 points total
All other cards = 0 points
MAXIMUM POSSIBLE: 8 points per game
```

### Victory Conditions

#### Individual Play (2-3 players)
- **Regular Win:** Player with most points (5-7 points typically wins)
- **Double Victory:** If opponent gets zero 10s/Aces, winner gets double victory
- **Draw:** Equal points (rare, replay the game)

#### Team Play (4 players)
- **Team Win:** Team with most combined points wins
- **Double Victory:** If opposing team gets zero 10s/Aces, winning team gets double victory
- Points are shared between teammates regardless of who captured them

### Tournament/Match Scoring
- **Regular Win:** +1 match point
- **Double Victory:** +2 match points
- **Tournament:** First to agreed number of match points (typically 5-11)

## 🤖 Romanian Septica Strategy

### Traditional Strategy Tips (Ponturi de joc)

#### Opening Play Strategy
- **Start with duplicates:** If you have multiple cards of same rank (e.g., K♥️, K♠️), start with one - the duplicate becomes a "wild card" for objections
- **Example:** Hand contains K♥️, Q♦️, K♠️, A♣️ → Start with K♥️, now K♠️ can beat any King played

#### Objection Decision Making
- **Object when:** Point cards (10s, Aces) are at stake
- **Don't object when:** Only low-value cards on table
- **Save wild cards (7s):** For crucial moments with many points
- **Memory is key:** Track which point cards have been played

#### Team Play Strategy (4 players)
- **DON'T cut teammates:** If teammate plays 10♥️ and next opponent plays 9♠️, don't object with 9♦️ - let your teammate collect the points
- **Support teammates:** Help collect point cards for your team
- **Communication:** Use card choices to signal to teammate

### Card Value Priority for Strategy
1. **7s:** Ultimate wild cards - save for valuable collections
2. **10s and Aces:** Point cards - collect or protect from opponents
3. **Duplicate ranks:** Create objection opportunities
4. **8s (3-player):** Wild cards in 3-player variant
5. **Face cards:** Neutral value, good for testing opponents
6. **Low cards (9s):** Least valuable, safe to sacrifice

## 🎮 Digital Implementation - Authentic Romanian Rules

### Turn Management
- **Time Limit:** 30 seconds per decision (play card or pass)
- **Auto-pass:** If no objection made within time limit
- **No Undo:** Cards cannot be taken back once played

### Objection System Implementation
```go
type GameAction struct {
    Type     string // "PLAY_CARD" or "PASS"
    Card     *Card  // nil for pass
    PlayerID string
}

func CanObjectToCard(playedCard Card, objectionCard Card, gameMode GameMode) bool {
    // 7s always can object (wild cards)
    if objectionCard.Value == 7 {
        return true
    }

    // Same rank can object
    if objectionCard.Value == playedCard.Value {
        return true
    }

    // For 3-player: remaining 8s are wild
    if gameMode == ThreePlayer && objectionCard.Value == 8 {
        return true
    }

    return false
}
```

### Round Resolution
```go
func ResolveRound(tableCards []Card, lastPlayer Player) (winner Player, points int) {
    // Count point cards (10s and Aces)
    points = 0
    for _, card := range tableCards {
        if card.Value == 10 || card.Value == 14 { // Ace = 14
            points++
        }
    }

    // Winner is the last player who played (either initial or objector)
    winner = lastPlayer
    return winner, points
}
```

### Game State Management
```go
type GameState struct {
    Players      []Player
    TableCards   []Card
    CurrentTurn  int
    WaitingForObjection bool
    LastPlayedCard *Card
    Scores       map[string]int
}
```

## 🏆 Game Variants (Future Expansions)

### Tournament Mode
- **Best of 3 matches**
- **Swiss system tournaments**
- **Elimination brackets**

### Speed Septica
- **15 second move timer**
- **3 cards per hand instead of 4**
- **Faster, more intense gameplay**

### Team Septica
- **2v2 gameplay**
- **Partners sit across from each other**
- **Communication through emotes only**

## 📚 Strategy Tips

### For Beginners
1. **Count Points:** Always track how many points (10s and Aces) have been played
2. **Save 7s:** Don't waste 7s on worthless tricks
3. **Watch Patterns:** Learn to predict when 8s can beat

### For Advanced Players
1. **Card Counting:** Track all played cards to predict opponent's hand
2. **Bluffing:** Sometimes pass even when you can beat
3. **Timing:** Know when to continue tricks vs. when to stop

### Common Mistakes
- Playing 7s too early when no points are at stake
- Forgetting the 8-beating rule conditions
- Not counting remaining point cards
- Starting tricks with point cards unnecessarily

## 🔍 Rules Validation

### Edge Cases
- **Empty Deck:** Game continues until all cards are played
- **No Valid Moves:** Player must pass (extremely rare)
- **Simultaneous Timing:** Server timestamp determines order

### Cheating Prevention
- **Server Validation:** All moves validated server-side
- **Card Tracking:** Ensure no duplicate cards or invalid hands
- **Time Enforcement:** Strict timing controls prevent stalling

## 🎯 Cultural Heritage & Authenticity

### Sedma Family of Games
Romanian Septica belongs to the **Sedma group** of card games, which includes:
- **Septica Românească** (Romania) - this variant
- **Sedma** (Czech Republic, Slovakia)
- **Sedmice/Šuster** (Bosnia, Herzegovina, Serbia, Croatia)
- **Zsíros** (Hungary) - possibly the earliest recorded (1930)
- **Ristikontra** (Finland)
- **Hola** (Poland/Ukraine)

All share the characteristic **objection-based mechanic** and **7s as wild cards**.

### Key Romanian Cultural Elements
- **Family gatherings:** Traditional game for Romanian family entertainment
- **Social bonding:** Encourages interaction and friendly competition
- **Memory training:** Develops attention and memorization skills
- **Strategic thinking:** Balances luck with tactical decision-making
- **Regional variations:** Slight rule differences across Romanian regions

## ⚠️ CRITICAL CORRECTION NOTICE

**PREVIOUS RULE ERRORS FIXED:**
The original documentation contained **fundamental errors** that described a completely different game style:

❌ **WRONG:** Complex "trick-taking" with continuing tricks and beating phases
✅ **CORRECT:** Simple objection-based system (object or don't object)

❌ **WRONG:** 8s beat "when table cards % 3 == 0"
✅ **CORRECT:** 8s are wild ONLY in 3-player variant (when 2 eights removed)

❌ **WRONG:** Only 2-player rules documented
✅ **CORRECT:** Full support for 2-4 players with team play

❌ **WRONG:** Missing double victory condition
✅ **CORRECT:** Double victory when opponent gets zero points

---

## 📚 Reference Implementation

This document now serves as the **definitive authentic Romanian Septica rules reference** for both human players learning the traditional game and AI systems implementing the logic. All digital implementations must follow these corrected rules exactly to preserve Romanian cultural gaming heritage.

**Cultural Preservation Goal:** Maintain authentic Romanian Septica gameplay while enabling modern digital multiplayer experiences for Romanian diaspora worldwide.