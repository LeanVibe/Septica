# Septica Matchmaking & Rating System

## 🎯 Overview

The Septica matchmaking system implements a sophisticated ELO-based rating system with arena progression, similar to Clash Royale and Hearthstone. It ensures fair matches, prevents win trading, and provides clear progression paths for players of all skill levels.

## ⚖️ ELO Rating System

### Core Rating Formula

We use a modified ELO system optimized for 1v1 card games:

```
New Rating = Old Rating + K * (Actual Score - Expected Score)

Where:
- K = K-Factor (varies by player level and rating)
- Actual Score = 1 for win, 0 for loss
- Expected Score = 1 / (1 + 10^((Opponent Rating - Player Rating) / 400))
```

### K-Factor Calculation
```go
func calculateKFactor(rating int, gamesPlayed int, isProvisional bool) int {
    if isProvisional && gamesPlayed < 20 {
        return 40 // High volatility for new players
    }
    
    switch {
    case rating < 1200:
        return 32 // Bronze/Silver players learn faster
    case rating < 1600:
        return 24 // Gold players
    case rating < 2000:
        return 20 // Diamond players
    case rating < 2400:
        return 16 // Master players
    default:
        return 12 // Grandmaster stability
    }
}
```

### Rating Boundaries & Floors
```go
type Arena struct {
    ID          int    `json:"id"`
    Name        string `json:"name"`
    MinRating   int    `json:"min_rating"`
    MaxRating   int    `json:"max_rating"`
    Floor       int    `json:"floor"`        // Cannot drop below this
    Theme       string `json:"theme"`
    Rewards     []Reward `json:"rewards"`
}

var Arenas = []Arena{
    {1, "Training Grounds", 0, 399, 0, "tutorial", nil},
    {2, "Village Square", 400, 599, 300, "village", bronzeRewards},
    {3, "Town Market", 600, 799, 500, "market", bronzeRewards},
    {4, "Castle Courtyard", 800, 999, 700, "castle", silverRewards},
    {5, "Royal Gardens", 1000, 1199, 900, "gardens", silverRewards},
    {6, "Monastery Halls", 1200, 1399, 1100, "monastery", goldRewards},
    {7, "Mountain Pass", 1400, 1599, 1300, "mountains", goldRewards},
    {8, "Dragon's Lair", 1600, 1799, 1500, "dragon", diamondRewards},
    {9, "Wizard's Tower", 1800, 1999, 1700, "wizard", diamondRewards},
    {10, "Titan's Forge", 2000, 2199, 1900, "titan", masterRewards},
    {11, "Celestial Realm", 2200, 2399, 2100, "celestial", masterRewards},
    {12, "Void Dimension", 2400, 2599, 2300, "void", grandmasterRewards},
    {13, "Infinity Gates", 2600, 2799, 2500, "infinity", grandmasterRewards},
    {14, "Champion's Hall", 2800, 2999, 2700, "champion", legendaryRewards},
    {15, "Ultimate Arena", 3000, 9999, 2900, "ultimate", legendaryRewards},
}
```

## 🔍 Matchmaking Algorithm

### Primary Matching Criteria

#### 1. Rating-Based Matching
```go
type MatchmakingCriteria struct {
    BaseRating         int     `json:"base_rating"`
    InitialRange       int     `json:"initial_range"`       // ±50 initially
    MaxRange           int     `json:"max_range"`           // ±200 maximum
    RangeExpansion     int     `json:"range_expansion"`     // +25 every 10 seconds
    TimeInQueue        int     `json:"time_in_queue"`       // seconds
    PreferredLatency   int     `json:"preferred_latency"`   // ms
}

func (c *MatchmakingCriteria) GetCurrentRange() int {
    expansion := (c.TimeInQueue / 10) * c.RangeExpansion
    currentRange := c.InitialRange + expansion
    
    if currentRange > c.MaxRange {
        currentRange = c.MaxRange
    }
    
    return currentRange
}

func (c *MatchmakingCriteria) IsValidOpponent(opponentRating int) bool {
    diff := abs(c.BaseRating - opponentRating)
    return diff <= c.GetCurrentRange()
}
```

#### 2. Connection Quality Matching
```go
type ConnectionQuality struct {
    Region     string `json:"region"`      // NA-WEST, EU-CENTRAL, etc.
    Latency    int    `json:"latency"`     // ms to game servers
    PacketLoss float64 `json:"packet_loss"` // 0.0 to 1.0
    Jitter     int    `json:"jitter"`      // ms variation
}

func calculateConnectionScore(p1, p2 ConnectionQuality) float64 {
    // Prefer same region
    regionBonus := 0.0
    if p1.Region == p2.Region {
        regionBonus = 0.3
    }
    
    // Penalty for high combined latency
    avgLatency := float64(p1.Latency + p2.Latency) / 2
    latencyPenalty := avgLatency / 1000.0 // 0-1 scale
    
    return regionBonus - latencyPenalty
}
```

#### 3. Anti-Abuse Measures
```go
type MatchmakingHistory struct {
    RecentOpponents    []string    `json:"recent_opponents"`     // Last 10 opponents
    WinLossStreak      int         `json:"win_loss_streak"`      // Current streak
    SuspiciousActivity bool        `json:"suspicious_activity"`  // Flagged account
    LastGameTime       time.Time   `json:"last_game_time"`       // Prevent rapid requeueing
}

func isValidMatch(player1, player2 *Player) bool {
    // Prevent rematches
    if contains(player1.History.RecentOpponents, player2.ID) {
        return false
    }
    
    // Prevent win trading (same players repeatedly)
    if countRecentMatches(player1.ID, player2.ID) >= 3 {
        return false
    }
    
    // Rate limiting
    if time.Since(player1.History.LastGameTime) < time.Minute*2 {
        return false
    }
    
    return true
}
```

### Matchmaking Queue Implementation

```go
type MatchmakingService struct {
    queues          map[string]*Queue        // Separate queues by game mode
    activeMatches   map[string]*Match        // Track ongoing matches
    playerSessions  map[string]*PlayerSession
    mutex           sync.RWMutex
    matchmaker      *MatchmakerEngine
}

type Queue struct {
    Players        []*QueuedPlayer    `json:"players"`
    LastProcessed  time.Time         `json:"last_processed"`
    ProcessInterval time.Duration     `json:"process_interval"` // 2 seconds
}

type QueuedPlayer struct {
    Player        *Player           `json:"player"`
    JoinTime      time.Time         `json:"join_time"`
    Criteria      MatchmakingCriteria `json:"criteria"`
    Preferences   MatchPreferences  `json:"preferences"`
}

type MatchPreferences struct {
    MaxLatency        int    `json:"max_latency"`         // 150ms default
    AvoidRecentOpponents bool `json:"avoid_recent"`       // true default
    PreferSimilarLevel   bool `json:"prefer_similar_level"` // false default
}
```

### Matching Algorithm Flow

```go
func (s *MatchmakingService) ProcessQueue(gameMode string) {
    queue := s.queues[gameMode]
    
    for i, player1 := range queue.Players {
        for j, player2 := range queue.Players[i+1:] {
            if s.evaluateMatch(player1, player2) {
                match := s.createMatch(player1, player2)
                s.removeFromQueue(player1, player2, gameMode)
                s.startMatch(match)
                return // Process one match per cycle
            }
        }
    }
}

func (s *MatchmakingService) evaluateMatch(p1, p2 *QueuedPlayer) bool {
    // 1. Rating compatibility
    if !p1.Criteria.IsValidOpponent(p2.Player.Rating) {
        return false
    }
    
    // 2. Connection quality
    connectionScore := calculateConnectionScore(p1.Player.Connection, p2.Player.Connection)
    if connectionScore < 0.2 {
        return false
    }
    
    // 3. Anti-abuse checks
    if !isValidMatch(p1.Player, p2.Player) {
        return false
    }
    
    // 4. Preference matching
    if !matchesPreferences(p1, p2) {
        return false
    }
    
    return true
}
```

## 🏆 Seasonal System

### Season Structure
```go
type Season struct {
    ID             string    `json:"id"`              // "2024_q1"
    Name           string    `json:"name"`            // "Spring Championship"
    StartDate      time.Time `json:"start_date"`
    EndDate        time.Time `json:"end_date"`
    Duration       int       `json:"duration"`        // Days (typically 60-90)
    Status         string    `json:"status"`          // active, ended
    ResetRules     ResetRules `json:"reset_rules"`
    Rewards        []SeasonReward `json:"rewards"`
}

type ResetRules struct {
    ResetDate      time.Time `json:"reset_date"`
    ResetFormula   string    `json:"reset_formula"`   // "soft", "hard", "none"
    MinRating      int       `json:"min_rating"`      // Floor for reset
    ResetAmount    float64   `json:"reset_amount"`    // Percentage to reset
}

func (s *Season) CalculateResetRating(currentRating int) int {
    switch s.ResetRules.ResetFormula {
    case "soft":
        // Compress ratings towards 1200 (starting rating)
        return int(1200 + float64(currentRating-1200)*0.75)
    case "hard":
        // Reset everyone to starting rating
        return 1200
    case "none":
        // No reset
        return currentRating
    default:
        return currentRating
    }
}
```

### Trophy Road Rewards
```go
type TrophyMilestone struct {
    Trophies    int          `json:"trophies"`
    Rewards     []Reward     `json:"rewards"`
    ChestType   string       `json:"chest_type"`
    IsArenaGate bool         `json:"is_arena_gate"`
}

var TrophyRoad = []TrophyMilestone{
    {400, []Reward{{Type: "coins", Amount: 100}}, "silver_chest", true},
    {450, []Reward{{Type: "cards", Amount: 3}}, "card_pack", false},
    {500, []Reward{{Type: "coins", Amount: 150}}, "silver_chest", false},
    {600, []Reward{{Type: "card_back", ID: "bronze_ornate"}}, "cosmetic_chest", true},
    // ... continues to 3000+
}
```

## 📊 Player Progression

### Experience & Leveling
```go
type PlayerProgression struct {
    Level               int       `json:"level"`
    Experience          int       `json:"experience"`
    ExperienceToNext    int       `json:"experience_to_next"`
    Rating              int       `json:"rating"`
    PeakRating          int       `json:"peak_rating"`
    CurrentArena        int       `json:"current_arena"`
    HighestArena        int       `json:"highest_arena"`
    GamesPlayed         int       `json:"games_played"`
    GamesWon            int       `json:"games_won"`
    WinRate             float64   `json:"win_rate"`
    CurrentStreak       int       `json:"current_streak"`
    BestStreak          int       `json:"best_streak"`
    TotalPlayTime       int       `json:"total_play_time"`
    LastPlayDate        time.Time `json:"last_play_date"`
}

func calculateExperienceRequired(level int) int {
    // Exponential growth with diminishing returns
    baseXP := 100
    return baseXP * level * level / 10
}

func awardExperience(player *Player, gameResult GameResult) {
    baseXP := 25 // Base XP for playing
    
    if gameResult.Won {
        baseXP += 15 // Win bonus
    }
    
    // Performance bonuses
    if gameResult.GameDuration < 180 { // Fast win
        baseXP += 10
    }
    
    if gameResult.Points >= 6 { // High score
        baseXP += 5
    }
    
    // Level difference bonus/penalty
    levelDiff := gameResult.OpponentLevel - player.Level
    if levelDiff > 0 {
        baseXP += levelDiff * 2 // Bonus for beating higher level
    }
    
    player.AddExperience(baseXP)
}
```

### Win Streak System
```go
type StreakSystem struct {
    WinStreak      int     `json:"win_streak"`
    LossStreak     int     `json:"loss_streak"`
    StreakBonus    float64 `json:"streak_bonus"`
    MaxBonus       float64 `json:"max_bonus"`
}

func (s *StreakSystem) UpdateStreak(won bool) {
    if won {
        s.WinStreak++
        s.LossStreak = 0
        
        // Bonus XP and coins for win streaks
        switch s.WinStreak {
        case 3:
            s.StreakBonus = 1.1
        case 5:
            s.StreakBonus = 1.2
        case 10:
            s.StreakBonus = 1.5
        }
    } else {
        s.LossStreak++
        s.WinStreak = 0
        s.StreakBonus = 1.0
        
        // Loss protection for new players
        if s.LossStreak >= 3 {
            // Implement easier matchmaking or rating protection
        }
    }
}
```

## 🎮 Game Mode Variations

### Ranked Mode
- **Standard ELO rating**
- **Arena progression**
- **Seasonal rewards**
- **Full matchmaking criteria**

### Casual Mode
```go
type CasualMatchmaking struct {
    RatingRange    int  `json:"rating_range"`    // ±300 (wider than ranked)
    SkillMatching  bool `json:"skill_matching"`  // Loose skill matching
    QuickMatch     bool `json:"quick_match"`     // Prioritize speed over fairness
    HiddenRating   int  `json:"hidden_rating"`   // Separate from ranked rating
}
```

### Tournament Mode
```go
type TournamentBracket struct {
    ID                 string              `json:"id"`
    Type               string              `json:"type"`           // "single_elimination", "swiss"
    MaxParticipants    int                 `json:"max_participants"`
    CurrentRound       int                 `json:"current_round"`
    Participants       []TournamentPlayer  `json:"participants"`
    Matches            []TournamentMatch   `json:"matches"`
    PrizePool          []Reward            `json:"prize_pool"`
    EntryFee          Currency             `json:"entry_fee"`
    Status            string               `json:"status"`
}

type TournamentPlayer struct {
    PlayerID     string  `json:"player_id"`
    SeedRating   int     `json:"seed_rating"`     // Rating at tournament start
    CurrentRound int     `json:"current_round"`
    Eliminated   bool    `json:"eliminated"`
    Wins         int     `json:"wins"`
    Losses       int     `json:"losses"`
}
```

## 🔧 Anti-Cheat & Fair Play

### Statistical Analysis
```go
type PlayerStats struct {
    AverageGameTime    float64 `json:"avg_game_time"`
    WinRateByRating    map[int]float64 `json:"win_rate_by_rating"`
    MoveTimingPattern  []float64 `json:"move_timing_pattern"`
    CardPlayPattern    map[string]float64 `json:"card_play_pattern"`
    SuspicionScore     float64 `json:"suspicion_score"`
}

func analyzePlayerBehavior(player *Player) {
    stats := player.Stats
    
    // Detect abnormally fast decisions
    if stats.AverageGameTime < 30 && player.GamesPlayed > 50 {
        stats.SuspicionScore += 0.2
    }
    
    // Detect unnatural win rates
    expectedWinRate := calculateExpectedWinRate(player.Rating, player.OpponentRatings)
    if stats.WinRate > expectedWinRate + 0.15 {
        stats.SuspicionScore += 0.3
    }
    
    // Detect robotic play patterns
    if hasRoboticPattern(stats.MoveTimingPattern) {
        stats.SuspicionScore += 0.5
    }
    
    if stats.SuspicionScore > 0.8 {
        flagForReview(player)
    }
}
```

### Win Trading Prevention
```go
func detectWinTrading(player1, player2 *Player) bool {
    // Check for alternating wins
    recentMatches := getRecentMatches(player1.ID, player2.ID, 10)
    
    if len(recentMatches) < 6 {
        return false
    }
    
    // Pattern: WLWLWL or LWLWLW
    alternatingPattern := true
    for i := 1; i < len(recentMatches); i++ {
        if recentMatches[i].Winner == recentMatches[i-1].Winner {
            alternatingPattern = false
            break
        }
    }
    
    // Check for unusual game durations
    avgDuration := calculateAverageDuration(recentMatches)
    if alternatingPattern && avgDuration < 60 { // Suspiciously short games
        return true
    }
    
    return false
}
```

## 📈 Matchmaking Analytics

### Queue Health Metrics
```go
type QueueMetrics struct {
    AverageWaitTime    float64 `json:"avg_wait_time"`
    MedianWaitTime     float64 `json:"median_wait_time"`
    PlayersInQueue     int     `json:"players_in_queue"`
    MatchesPerMinute   float64 `json:"matches_per_minute"`
    QueueAbandonRate   float64 `json:"queue_abandon_rate"`
    RatingDistribution map[int]int `json:"rating_distribution"`
}

func (m *QueueMetrics) IsHealthy() bool {
    return m.AverageWaitTime < 60 && // Less than 1 minute average
           m.QueueAbandonRate < 0.1 && // Less than 10% abandon rate
           m.MatchesPerMinute > 10 // At least 10 matches per minute
}
```

### Match Quality Assessment
```go
type MatchQuality struct {
    RatingDifference   int     `json:"rating_difference"`
    PredictedOutcome   float64 `json:"predicted_outcome"`
    ActualOutcome      float64 `json:"actual_outcome"`
    GameDuration       int     `json:"game_duration"`
    ConnectionQuality  float64 `json:"connection_quality"`
    PlayerSatisfaction float64 `json:"player_satisfaction"`
}

func assessMatchQuality(match *Match) MatchQuality {
    quality := MatchQuality{}
    
    quality.RatingDifference = abs(match.Player1.Rating - match.Player2.Rating)
    quality.PredictedOutcome = calculateExpectedScore(match.Player1.Rating, match.Player2.Rating)
    
    // Good matches should be close to 50/50 prediction
    if quality.PredictedOutcome > 0.4 && quality.PredictedOutcome < 0.6 {
        quality.PlayerSatisfaction += 0.3
    }
    
    // Games should last reasonable time (indicates competitiveness)
    if quality.GameDuration > 120 && quality.GameDuration < 300 {
        quality.PlayerSatisfaction += 0.2
    }
    
    return quality
}
```

This comprehensive matchmaking system ensures fair, competitive, and engaging gameplay while preventing abuse and maintaining healthy queue times across all skill levels.