# Romanian Septica Two-Tab Multiplayer - Quick Start Guide

## 🚀 5-Minute Quick Start

### What You'll Test
A complete Romanian Septica two-tab multiplayer experience where:
- Two browser tabs automatically pair for a game
- Players take turns following authentic Romanian Septica rules
- 7s beat everything, same values beat each other, 8s beat conditionally
- Only 10s and Aces count as points (max 8 total)

### Quick Test Flow
1. **Start Servers** → 2. **Open Tabs** → 3. **Play Game** → 4. **Verify Rules**

---

## Step 1: Start Backend Server (30 seconds)

```bash
cd /Users/bogdan/work/Septica/backend
./server
```

**Expected Output**:
```
WebSocket server started on :8080
Romanian Septica server ready
Health check endpoint available at /health
```

**✅ Success Indicator**: See "Romanian Septica server ready"
**❌ Troubleshooting**: If file not found, run `go build -o server .` first

---

## Step 2: Start Frontend Server (30 seconds)

```bash
cd /Users/bogdan/work/Septica/frontend
python3 serve.py
```

**Expected Output**:
```
Serving on http://localhost:3000
Static files ready
WebSocket proxy configured
```

**✅ Success Indicator**: See "Serving on http://localhost:3000"
**❌ Alternative**: Use `node serve.js` if Python not available

---

## Step 3: Open Two Browser Tabs (1 minute)

### Tab 1: Player 1
1. Open browser (Chrome/Firefox/Safari/Edge)
2. Navigate to: `http://localhost:3000`
3. Wait for page to load completely (should see "Romanian Septica")
4. Verify connection status shows "Connected" with green indicator

### Tab 2: Player 2
1. Open new tab in same browser
2. Navigate to: `http://localhost:3000`
3. Wait for page to load completely
4. Verify connection status shows "Connected" with green indicator

**✅ Both Tabs Ready**: Green "Connected" status on both tabs
**❌ Connection Issues**: Check if both servers are running

---

## Step 4: Test Matchmaking (2 minutes)

### Auto-Pairing Process
1. **Player 1**: Click "Play" button
   - Should see matchmaking overlay
   - Status: "Searching for opponent..."

2. **Player 2**: Click "Play" button (within 10 seconds)
   - Both tabs should show "Match Found!"
   - Game starts automatically

3. **Verify Game Start**:
   - Each player has exactly 4 cards
   - Scores show 0-0
   - One player has turn indicator
   - Cards show only values 7, 8, 9, 10, J, Q, K, A

**✅ Success**: Game starts with 4 cards each, authentic Romanian deck
**❌ Pairing Failed**: Refresh tabs and try again

---

## Step 5: Test Romanian Septica Rules (2 minutes)

### Basic Gameplay Test
1. **First Card**: Current player plays any card (all cards valid on empty table)
2. **Second Card**: Opponent plays a card following Romanian rules

### Romanian Rule Quick Validation

**Test 1: 7 Beats Everything**
- If table has any card, play a 7
- **Expected**: 7 should beat the table card
- **Result**: ✅ Pass / ❌ Fail

**Test 2: Same Values Beat**
- If table has a 10, play another 10
- **Expected**: Second 10 should beat first 10
- **Result**: ✅ Pass / ❌ Fail

**Test 3: Point System**
- Win a trick with a 10 or Ace
- **Expected**: Score increases by 1 point
- Win a trick with 7, 8, 9, J, Q, K only
- **Expected**: Score stays the same
- **Result**: ✅ Pass / ❌ Fail

**Test 4: Invalid Plays Prevented**
- Try to play a card that shouldn't beat (e.g., 9 against King)
- **Expected**: Invalid play should be rejected
- **Result**: ✅ Pass / ❌ Fail

---

## Expected Game Experience

### What Should Happen
1. **Smooth Connection**: Both tabs connect in <3 seconds
2. **Fast Matchmaking**: Pairing completes in <15 seconds
3. **Responsive Gameplay**: Cards play in <1 second
4. **Perfect Sync**: Both tabs show identical game state
5. **Authentic Rules**: 100% traditional Romanian Septica rules

### What Success Looks Like
- ✅ Two tabs seamlessly become a multiplayer game
- ✅ Romanian deck (32 cards, values 7-14) displays correctly
- ✅ Traditional beating rules work perfectly
- ✅ Only 10s and Aces award points
- ✅ Real-time synchronization between players
- ✅ Smooth, responsive user experience

---

## Performance Expectations

### Response Time Targets
| Action | Expected Time | Status |
|--------|---------------|---------|
| Page Load | <5 seconds | ✅ / ❌ |
| WebSocket Connection | <3 seconds | ✅ / ❌ |
| Matchmaking | <15 seconds | ✅ / ❌ |
| Card Play | <1 second | ✅ / ❌ |
| Synchronization | <2 seconds | ✅ / ❌ |

### Quality Indicators
- **Memory Usage**: <100MB per browser tab
- **CPU Usage**: Minimal, no browser slowdown
- **Visual Quality**: Smooth 60 FPS rendering
- **Network Efficiency**: Minimal bandwidth usage

---

## Quick Troubleshooting

### Common Issues & Instant Fixes

**Issue**: "Connection Failed"
**Fix**:
```bash
# Check if backend is running
curl http://localhost:8080/health
# Should return: {"status":"ok","service":"romanian-septica"}
```

**Issue**: "Page Not Loading"
**Fix**:
```bash
# Check if frontend is running
curl http://localhost:3000
# Should return HTML content
```

**Issue**: "Tabs Won't Pair"
**Fix**:
1. Refresh both tabs
2. Ensure both show "Connected" status
3. Try matchmaking again

**Issue**: "Cards Won't Play"
**Fix**:
1. Check turn indicator (only current player can play)
2. Verify card follows Romanian rules
3. Check WebSocket connection status

**Issue**: "Wrong Scores"
**Fix**:
1. Remember: Only 10s and Aces count as points
2. Other cards (7,8,9,J,Q,K) give 0 points
3. Maximum possible score is 8 points total

---

## 30-Second Health Check

If you need to quickly verify the system is working:

```bash
# Backend Health
curl http://localhost:8080/health
# Should return: {"status":"ok"}

# Frontend Health
curl http://localhost:3000
# Should return: HTML content with "Romanian Septica"

# WebSocket Test
# Open browser console on http://localhost:3000
# Should see: "WebSocket connected" in console
```

---

## Quick Decision Points

### ✅ PASS Criteria
- Both servers start successfully
- Two tabs connect and show green status
- Matchmaking works (auto-pairing in <15 seconds)
- Cards play following Romanian rules
- Real-time synchronization works
- Performance feels smooth and responsive

### ❌ FAIL Criteria
- Servers won't start or crash
- Tabs can't connect (red status)
- Matchmaking fails or times out
- Romanian rules work incorrectly
- Major synchronization issues
- Poor performance or frequent errors

### 🔧 INVESTIGATE Criteria
- Minor UI glitches (but gameplay works)
- Occasional slow responses (but within thresholds)
- One browser works but another doesn't
- Intermittent connection issues

---

## Complete Game Flow Test (5 minutes)

If you want to test a full game:

1. **Start**: Complete matchmaking as above
2. **Play**: Take turns playing all 4 cards each
3. **Rules**: Verify Romanian rules work for each play
4. **Points**: Check only 10s and Aces award points
5. **End**: Game should complete and show winner
6. **Reset**: Should be able to start new game immediately

**Expected Outcome**: Complete traditional Romanian Septica game experience

---

## Next Steps After Quick Start

### If Everything Works (✅ PASS)
- System is ready for production deployment
- Consider advanced testing with USER_TESTING_GUIDE.md
- Review PRODUCTION_READINESS_ASSESSMENT.md
- Proceed with deployment planning

### If Issues Found (❌ FAIL or 🔧 INVESTIGATE)
- Document specific issues encountered
- Check detailed troubleshooting in USER_TESTING_GUIDE.md
- Review system logs for error details
- Consider fixes before production deployment

### For Development/Debugging
- Check backend logs: `tail -f /Users/bogdan/work/Septica/backend/server.log`
- Check frontend logs in browser console (F12)
- Review TECHNICAL_IMPLEMENTATION_SUMMARY.md for architecture details

---

**Quick Start Guide Version**: 1.0
**Estimated Completion Time**: 5 minutes
**Romanian Septica**: Ready for immediate testing! 🚀