# Septica - Complete Game Rules

## 🃏 Game Overview

Septica is a traditional Romanian trick-taking card game for 2 players. The goal is to collect the most point cards (10s and Aces) during the course of the game. Each game consists of multiple tricks, where players continue adding cards to the table until no one can beat the current cards.

## 🎴 Card Setup

### Deck Composition
- **32 Cards Total:** Standard deck with cards 7, 8, 9, 10, Jack, Queen, King, Ace
- **4 Suits:** Hearts (♥️), Diamonds (♦️), Clubs (♣️), Spades (♠️)
- **Card Values:** 7 = 7, 8 = 8, 9 = 9, 10 = 10, Jack = 11, Queen = 12, King = 13, Ace = 14

### Point Cards (CORRECTED)
- **10s:** Each worth 1 point (4 total in deck)
- **Aces:** Each worth 1 point (4 total in deck)
- **Total Points Available:** 8 points per game
- **Winner:** Player who collects the most points (minimum 5 to win)

### Initial Deal
- Each player receives **4 cards**
- Remaining **24 cards** stay in the deck
- Players draw new cards after each trick until deck is empty

## 🎯 Game Flow

### 1. Starting a Game
- Player 1 starts the first trick
- Starting player alternates between games
- Players must play exactly 4 cards per trick initially

### 2. Trick Phases

#### Phase A: Starting a Trick
- Current player plays any card from their hand
- This becomes the "atu" (trump) card for the trick
- Play continues clockwise

#### Phase B: Beating Cards
- Next player must either:
  - **Beat** the current table card(s) with a valid card
  - **Pass** if they cannot or choose not to beat
- If a player beats, they become the active player
- If a player passes, the previous active player continues

#### Phase C: Continuing or Ending
- Active player can choose to:
  - **Continue:** Play another card to extend the trick
  - **Stop:** End the trick and collect all table cards
- Other player then gets their turn

### 3. Card Beating Rules

A card can "beat" the current table card if:

#### Rule 1: Same Value
- Any card with the same value beats the current card
- Example: 9♥️ beats 9♠️

#### Rule 2: Seven (Wild Card)
- Any 7 always beats any other card
- 7s are the most powerful cards in the game
- Example: 7♣️ beats Ace♠️

#### Rule 3: Eight (Conditional)
- An 8 beats any card when: `(number of table cards) % 3 == 0`
- This means 8s can beat when there are 0, 3, 6, 9, etc. cards on the table
- Example: 8♦️ beats King♥️ if there are exactly 3 cards on the table

#### Invalid Beats
- Higher values DO NOT automatically beat lower values
- Suits have no hierarchy
- Example: King♠️ cannot beat 9♥️ (unless it's another King)

## 📊 Scoring System

### Point Calculation
```
10s = 1 point each (♥️10, ♦️10, ♣️10, ♠️10)
Aces = 1 point each (♥️A, ♦️A, ♣️A, ♠️A)
All other cards = 0 points
```

### Game Results
- **Regular Win:** Player with 5-7 points wins
- **Mars (Sweep):** Player collects all 8 points (special victory)
- **Draw:** Both players have 4 points (rare, replay the game)

### Match Scoring
- **Regular Win:** +1 game point
- **Mars Win:** +3 game points  
- **First to 11 game points wins the match**

## 🤖 AI Strategy Guidelines

### Defensive Play
- Avoid giving away point cards (10s and Aces)
- Use non-point cards to test opponent's hand
- Save 7s for crucial moments

### Offensive Play
- Try to collect point cards when possible
- Use 7s to steal valuable tricks
- Count cards to predict opponent's remaining cards

### Card Value Priority (for AI decisions)
1. **7s:** Most valuable for beating any card
2. **10s and Aces:** Point cards, collect or protect
3. **8s:** Conditionally powerful, use strategically
4. **Face Cards:** Good for starting tricks
5. **9s:** Least valuable, use to test opponent

## 🎮 Digital Implementation Rules

### Turn Management
- **Time Limit:** 30 seconds per move
- **Auto-play:** Random legal move if time expires
- **Undo:** Not allowed once card is played

### Valid Move Detection
```swift
func canPlay(card: Card, againstTable table: [Card]) -> Bool {
    guard let atu = table.first else { return true } // First card of trick
    
    return card.value == atu.value ||  // Same value
           card.value == 7 ||          // Seven always beats
           (card.value == 8 && table.count % 3 == 0) // Eight conditional
}
```

### Trick Resolution
```swift
func resolveTrick(tableCards: [Card]) -> (winner: Player, points: Int) {
    let points = tableCards.filter { $0.value == 10 || $0.value == 14 }.count
    let winner = determineWinner(from: tableCards)
    return (winner, points)
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

---

This document serves as the definitive rules reference for both human players learning the game and AI systems implementing the logic. All digital implementations must follow these rules exactly to ensure authentic Septica gameplay.