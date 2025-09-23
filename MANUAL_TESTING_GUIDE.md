# Romanian Septica Manual Testing Guide

## Overview

This comprehensive manual testing guide provides step-by-step procedures for validating the Romanian Septica two-tab multiplayer system. Use this guide to perform thorough manual testing that complements automated tests.

## Prerequisites

### System Requirements
- Two browser tabs/windows (or ideally two separate devices)
- Local development environment running:
  - Frontend server: http://localhost:3000
  - Backend server: http://localhost:8080
- Stable internet connection
- Modern web browser (Chrome, Firefox, Safari, Edge)

### Test Environment Setup
1. Start backend server: `./backend/server`
2. Start frontend server: `cd frontend && python3 -m http.server 3000`
3. Verify both services are running
4. Open two browser tabs to http://localhost:3000

## Test Suite 1: Connection and Setup Validation

### ✅ Test 1.1: Basic Page Load
**Objective**: Verify both tabs load the game interface correctly

**Steps**:
1. Open first browser tab to http://localhost:3000
2. Open second browser tab to http://localhost:3000
3. Wait for complete page load

**Expected Results**:
- [ ] Both pages load without errors
- [ ] Game interface is visible and properly rendered
- [ ] No JavaScript console errors
- [ ] Page title shows "Romanian Septica"

**Pass Criteria**: All expected results achieved within 10 seconds

---

### ✅ Test 1.2: WebSocket Connection Establishment
**Objective**: Verify WebSocket connections establish properly

**Steps**:
1. On both tabs, observe the connection indicator
2. Wait for connection status to update

**Expected Results**:
- [ ] Connection dot turns green on both tabs
- [ ] Connection text shows "Connected" on both tabs
- [ ] Connection establishes within 5 seconds
- [ ] No connection errors in console

**Pass Criteria**: Both tabs show "Connected" status with green indicators

---

### ✅ Test 1.3: UI Elements Visibility
**Objective**: Verify all critical UI elements are present and visible

**Elements to Check on Both Tabs**:
- [ ] Connection status indicator
- [ ] Play button (enabled)
- [ ] Game status area
- [ ] Player score display (showing "0")
- [ ] Opponent score display (showing "0")
- [ ] Trick number display (showing "1")
- [ ] Move number display (showing "1")
- [ ] Player cards area
- [ ] Table cards area
- [ ] Leave game button (disabled initially)

**Pass Criteria**: All elements visible and in correct initial state

## Test Suite 2: Matchmaking Flow Validation

### ✅ Test 2.1: Matchmaking Initiation
**Objective**: Verify matchmaking process starts correctly

**Steps**:
1. Player 1: Click "Play" button
2. Observe matchmaking overlay appears
3. Player 2: Click "Play" button (within 10 seconds)
4. Observe both players enter matchmaking

**Expected Results**:
- [ ] Play buttons become disabled after clicking
- [ ] Matchmaking overlay appears on both tabs
- [ ] Queue position indicators show (if implemented)
- [ ] Status updates to indicate matchmaking in progress

**Pass Criteria**: Both players successfully enter matchmaking queue

---

### ✅ Test 2.2: Auto-Pairing Process
**Objective**: Verify players are automatically paired

**Steps**:
1. Continue from Test 2.1
2. Wait for auto-pairing to complete
3. Observe matchmaking completion

**Expected Results**:
- [ ] Matchmaking overlay disappears on both tabs
- [ ] Players are paired within 15 seconds
- [ ] Game status updates to indicate match found
- [ ] Leave game buttons become enabled

**Pass Criteria**: Successful pairing within time limit with proper status updates

---

### ✅ Test 2.3: Matchmaking Cancellation
**Objective**: Verify matchmaking can be cancelled

**Steps**:
1. Player 1: Click "Play" button
2. Wait 3 seconds
3. Player 1: Click "Cancel" button
4. Observe cancellation results

**Expected Results**:
- [ ] Matchmaking overlay disappears
- [ ] Play button becomes enabled again
- [ ] Status returns to ready state
- [ ] No ongoing matchmaking process

**Pass Criteria**: Clean cancellation with system reset to ready state

## Test Suite 3: Romanian Septica Game Rules Validation

### ✅ Test 3.1: Initial Game Setup
**Objective**: Verify proper Romanian Septica game initialization

**Steps**:
1. Complete matchmaking (Tests 2.1-2.2)
2. Observe initial game state

**Expected Results**:
- [ ] Each player has exactly 4 cards
- [ ] Initial scores are 0-0
- [ ] Trick number starts at 1
- [ ] Move number starts at 1
- [ ] One player has turn indicator
- [ ] Table is empty initially
- [ ] Cards show Romanian values (7-14)

**Pass Criteria**: All Romanian Septica setup rules followed correctly

---

### ✅ Test 3.2: Turn System Validation
**Objective**: Verify turn-based gameplay works correctly

**Steps**:
1. Identify which player has the current turn
2. Current player: Attempt to play a card
3. Other player: Attempt to play a card (should be prevented)
4. Observe turn switching

**Expected Results**:
- [ ] Only current player can play cards
- [ ] Out-of-turn plays are prevented
- [ ] Turn indicator switches after card play
- [ ] Move number increments correctly

**Pass Criteria**: Turn system enforces proper Romanian Septica gameplay

---

### ✅ Test 3.3: Card Play Mechanics
**Objective**: Verify card playing follows Romanian rules

**Steps**:
1. Current player: Play any card (first move - any card valid)
2. Observe card moves to table
3. Wait for opponent's turn
4. Opponent: Attempt to play valid/invalid cards

**Expected Results**:
- [ ] First card play always succeeds (empty table)
- [ ] Card appears on table
- [ ] Player's hand reduces by one card
- [ ] Turn switches to opponent
- [ ] Opponent can only play valid cards per Romanian rules

**Romanian Rule Validation**:
- [ ] 7s can beat any card
- [ ] Same values beat each other (10 beats 10, etc.)
- [ ] 8s beat when table cards % 3 = 0
- [ ] Invalid plays are rejected

**Pass Criteria**: All card plays follow authentic Romanian Septica rules

---

### ✅ Test 3.4: Point System Validation
**Objective**: Verify only 10s and Aces count as points

**Steps**:
1. Play through several cards including 10s and Aces
2. Observe point scoring
3. Complete tricks with point cards

**Expected Results**:
- [ ] Only 10s award 1 point each
- [ ] Only Aces award 1 point each
- [ ] Other cards (7,8,9,J,Q,K) award 0 points
- [ ] Maximum possible score is 8 points total
- [ ] Scores update correctly after tricks

**Pass Criteria**: Point system matches authentic Romanian Septica rules

---

### ✅ Test 3.5: Deck Composition Validation
**Objective**: Verify authentic Romanian 32-card deck

**Steps**:
1. Observe cards throughout gameplay
2. Note card values and suits appearing
3. Verify no invalid cards appear

**Expected Results**:
- [ ] Only values 7, 8, 9, 10, J, Q, K, A appear
- [ ] All four suits present: Hearts, Diamonds, Clubs, Spades
- [ ] No cards below 7 or above Ace
- [ ] Total deck composition suggests 32 cards (8 values × 4 suits)

**Pass Criteria**: Only authentic Romanian deck cards (32 total) appear

## Test Suite 4: Real-Time Synchronization

### ✅ Test 4.1: Game State Synchronization
**Objective**: Verify both players see identical game state

**Steps**:
1. After each card play, check both tabs
2. Compare all visible game information

**Synchronization Checklist**:
- [ ] Trick number identical on both tabs
- [ ] Move number identical on both tabs
- [ ] Table cards identical on both tabs
- [ ] Scores identical on both tabs
- [ ] Turn indicator consistent across tabs
- [ ] Game status messages consistent

**Pass Criteria**: Perfect synchronization with <2 second delay

---

### ✅ Test 4.2: Real-Time Updates
**Objective**: Verify updates propagate in real-time

**Steps**:
1. Player 1: Play a card
2. Immediately observe Player 2's tab
3. Measure update delay

**Expected Results**:
- [ ] Card appears on Player 2's table within 1 second
- [ ] Turn indicator updates on Player 2's tab
- [ ] Move counter updates simultaneously
- [ ] All UI elements reflect change immediately

**Pass Criteria**: Updates visible within 1 second across all elements

---

### ✅ Test 4.3: Connection Recovery
**Objective**: Verify system handles brief connection interruptions

**Steps**:
1. During active game, briefly disconnect one player's internet
2. Reconnect after 3-5 seconds
3. Observe recovery behavior

**Expected Results**:
- [ ] Disconnected player sees connection status change
- [ ] Connected player remains functional
- [ ] Reconnection restores game state
- [ ] Game can continue normally after recovery

**Pass Criteria**: Graceful handling of temporary disconnections

## Test Suite 5: Performance and Reliability

### ✅ Test 5.1: Page Load Performance
**Objective**: Verify acceptable loading times

**Steps**:
1. Use browser dev tools (F12)
2. Clear cache and refresh both tabs
3. Measure load times

**Performance Targets**:
- [ ] Page load completes under 5 seconds
- [ ] First contentful paint under 2 seconds
- [ ] WebSocket connection under 3 seconds
- [ ] Total time to playable state under 8 seconds

**Pass Criteria**: All performance targets met

---

### ✅ Test 5.2: Memory Usage Monitoring
**Objective**: Verify reasonable memory consumption

**Steps**:
1. Open browser dev tools → Performance tab
2. Monitor memory usage during gameplay
3. Play for 5 minutes, observe trends

**Memory Targets**:
- [ ] Initial page load under 50MB
- [ ] Steady-state usage under 100MB
- [ ] No significant memory leaks over time
- [ ] Garbage collection working properly

**Pass Criteria**: Memory usage within acceptable limits

---

### ✅ Test 5.3: Stress Testing
**Objective**: Verify system handles rapid interactions

**Steps**:
1. Rapidly hover over cards
2. Quickly click interface elements
3. Attempt rapid card plays (should be rate-limited)

**Expected Results**:
- [ ] UI remains responsive under rapid interaction
- [ ] No crashes or freezing
- [ ] Rate limiting prevents invalid rapid plays
- [ ] Performance remains smooth

**Pass Criteria**: System remains stable under stress

## Test Suite 6: Browser Compatibility

### ✅ Test 6.1: Multi-Browser Testing
**Objective**: Verify cross-browser compatibility

**Browsers to Test**:
- [ ] Chrome (latest)
- [ ] Firefox (latest)
- [ ] Safari (latest)
- [ ] Edge (latest)

**For Each Browser**:
- [ ] Complete basic matchmaking flow
- [ ] Play at least 3 cards
- [ ] Verify all UI elements display correctly
- [ ] Check console for errors

**Pass Criteria**: Consistent functionality across all tested browsers

---

### ✅ Test 6.2: Mobile Responsiveness
**Objective**: Verify mobile device compatibility

**Steps**:
1. Open game on mobile device or use browser dev tools mobile simulation
2. Test portrait and landscape orientations
3. Verify touch interactions work

**Mobile Checklist**:
- [ ] Layout adapts to mobile screen
- [ ] Touch targets are appropriately sized
- [ ] Text remains readable
- [ ] Core functionality accessible
- [ ] Performance acceptable on mobile

**Pass Criteria**: Functional and usable on mobile devices

## Test Suite 7: Error Handling and Edge Cases

### ✅ Test 7.1: Network Error Handling
**Objective**: Verify graceful handling of network issues

**Steps**:
1. Disable internet connection during various game states
2. Attempt actions while offline
3. Restore connection and observe recovery

**Test Scenarios**:
- [ ] Connection lost during matchmaking
- [ ] Connection lost during card play
- [ ] Connection lost during opponent's turn
- [ ] Extended offline period (30+ seconds)

**Pass Criteria**: Clear error messages and graceful recovery

---

### ✅ Test 7.2: Invalid Action Handling
**Objective**: Verify system prevents and handles invalid actions

**Invalid Actions to Test**:
- [ ] Playing cards out of turn
- [ ] Playing invalid cards (if possible via console manipulation)
- [ ] Rapid clicking on disabled elements
- [ ] Attempting to join matchmaking while already in game

**Pass Criteria**: All invalid actions prevented with appropriate feedback

---

### ✅ Test 7.3: Game Completion Flow
**Objective**: Verify proper game ending and cleanup

**Steps**:
1. Play game to completion (all cards played)
2. Observe game ending
3. Check final scores and winner determination

**Expected Results**:
- [ ] Game ends when all cards played
- [ ] Final scores calculated correctly
- [ ] Winner determined by highest points
- [ ] Players return to ready state
- [ ] Can start new game immediately

**Pass Criteria**: Clean game completion with proper state reset

## Cultural Authenticity Validation

### ✅ Cultural Test 1: Romanian Terminology
**Objective**: Verify authentic Romanian game terminology

**Elements to Check**:
- [ ] Game title mentions "Romanian Septica"
- [ ] Uses traditional card game terms (tricks, points)
- [ ] Avoids non-Romanian card game terminology
- [ ] Proper numerical displays (0-8 points max)

**Pass Criteria**: Authentic Romanian card game presentation

---

### ✅ Cultural Test 2: Traditional Game Structure
**Objective**: Verify traditional 2-player Romanian Septica format

**Structure Elements**:
- [ ] Exactly 2 players per game
- [ ] Turn-based gameplay (not simultaneous)
- [ ] Trick-taking structure
- [ ] Point accumulation system
- [ ] Traditional card layout

**Pass Criteria**: Follows authentic Romanian Septica tradition

## Test Execution Checklist

### Pre-Testing Setup
- [ ] Backend server running on port 8080
- [ ] Frontend server running on port 3000
- [ ] Browser developer tools available
- [ ] Test environment stable
- [ ] Two browser tabs/devices prepared

### During Testing
- [ ] Document any failed tests with screenshots
- [ ] Note exact error messages
- [ ] Record timing measurements
- [ ] Save console logs for debugging
- [ ] Test each suite systematically

### Post-Testing
- [ ] Calculate overall pass rate
- [ ] Identify critical vs. minor issues
- [ ] Prioritize fixes based on impact
- [ ] Document test results
- [ ] Create bug reports for failures

## Test Results Summary Template

### Test Execution Summary
**Date**: _________
**Tester**: _________
**Environment**: _________

### Results by Test Suite
- **Connection & Setup**: ___/3 tests passed
- **Matchmaking Flow**: ___/3 tests passed
- **Romanian Rules**: ___/5 tests passed
- **Synchronization**: ___/3 tests passed
- **Performance**: ___/3 tests passed
- **Browser Compatibility**: ___/2 tests passed
- **Error Handling**: ___/3 tests passed
- **Cultural Authenticity**: ___/2 tests passed

### Overall Assessment
**Total Pass Rate**: ___/24 tests (___%)

**Critical Issues Found**: ___
**Minor Issues Found**: ___

**System Status**:
- [ ] ✅ Production Ready (95%+ pass rate)
- [ ] ⚠️ Needs Minor Fixes (85-94% pass rate)
- [ ] 🔴 Needs Major Work (<85% pass rate)

### Notes and Recommendations
_Record any additional observations or recommendations here_

---

## Quick Smoke Test (15 minutes)

For rapid validation, execute this abbreviated test:

1. **Connection Test** (2 min): Both tabs connect and show green status
2. **Matchmaking Test** (3 min): Quick matchmaking between two tabs
3. **Basic Gameplay** (5 min): Play 3-4 cards, verify Romanian rules
4. **Synchronization Check** (2 min): Verify both tabs show same state
5. **Performance Check** (3 min): No lag, responsive interactions

**Smoke Test Pass Criteria**: All 5 steps complete successfully without critical errors.