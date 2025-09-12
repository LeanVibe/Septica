# Septica Database Schema Design

## 🗄️ Database Overview

The Septica backend uses PostgreSQL 15+ with JSON support for flexible data storage. The schema is designed for scalability, performance, and data integrity with proper indexing and foreign key relationships.

**Database:** `septica_game`  
**Encoding:** UTF8  
**Timezone:** UTC  
**Connection Pool:** 20 connections per service  

## 📊 Schema Design Principles

1. **Normalization:** BCNF where appropriate, denormalized for performance
2. **Indexing:** Strategic B-tree and GIN indexes for query performance  
3. **Partitioning:** Time-based partitioning for large historical tables
4. **JSON Storage:** Flexible schema for game states and configurations
5. **Audit Trail:** Complete history tracking for games and transactions

## 👤 User Management Tables

### users
Core user authentication and identity
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    email_verified BOOLEAN DEFAULT FALSE,
    status VARCHAR(20) DEFAULT 'active', -- active, suspended, banned
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login TIMESTAMP WITH TIME ZONE,
    login_count INTEGER DEFAULT 0,
    
    CONSTRAINT valid_username CHECK (LENGTH(username) >= 3),
    CONSTRAINT valid_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT valid_status CHECK (status IN ('active', 'suspended', 'banned'))
);

CREATE INDEX idx_users_username ON users (username);
CREATE INDEX idx_users_email ON users (email);
CREATE INDEX idx_users_status ON users (status);
CREATE INDEX idx_users_created_at ON users (created_at);
```

### user_sessions
JWT token management and session tracking
```sql
CREATE TABLE user_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    refresh_token VARCHAR(512) NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    device_info JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_used TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT valid_expiry CHECK (expires_at > created_at)
);

CREATE INDEX idx_user_sessions_user_id ON user_sessions (user_id);
CREATE INDEX idx_user_sessions_refresh_token ON user_sessions (refresh_token);
CREATE INDEX idx_user_sessions_expires_at ON user_sessions (expires_at);
```

## 🎮 Player Profile Tables

### players
Game-specific player profiles and statistics
```sql
CREATE TABLE players (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    rating INTEGER DEFAULT 1200,
    peak_rating INTEGER DEFAULT 1200,
    level INTEGER DEFAULT 1,
    xp INTEGER DEFAULT 0,
    coins INTEGER DEFAULT 1000,
    gems INTEGER DEFAULT 50,
    current_arena INTEGER DEFAULT 1,
    highest_arena INTEGER DEFAULT 1,
    
    -- Game Statistics
    games_played INTEGER DEFAULT 0,
    games_won INTEGER DEFAULT 0,
    win_rate DECIMAL(5,4) DEFAULT 0.0000,
    current_win_streak INTEGER DEFAULT 0,
    best_win_streak INTEGER DEFAULT 0,
    current_loss_streak INTEGER DEFAULT 0,
    total_play_time INTEGER DEFAULT 0, -- seconds
    mars_wins INTEGER DEFAULT 0, -- perfect games (8-0 points)
    points_collected INTEGER DEFAULT 0,
    cards_played INTEGER DEFAULT 0,
    
    -- Seasonal Data
    season_rating INTEGER DEFAULT 1200,
    season_games INTEGER DEFAULT 0,
    season_wins INTEGER DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_game_at TIMESTAMP WITH TIME ZONE,
    last_active TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT valid_rating CHECK (rating >= 0 AND rating <= 5000),
    CONSTRAINT valid_level CHECK (level >= 1 AND level <= 100),
    CONSTRAINT valid_arena CHECK (current_arena >= 1 AND current_arena <= 15),
    CONSTRAINT valid_win_rate CHECK (win_rate >= 0.0 AND win_rate <= 1.0)
);

CREATE INDEX idx_players_user_id ON players (user_id);
CREATE INDEX idx_players_rating ON players (rating DESC);
CREATE INDEX idx_players_level ON players (level DESC);
CREATE INDEX idx_players_arena ON players (current_arena);
CREATE INDEX idx_players_last_active ON players (last_active DESC);
```

### player_cosmetics
Player-owned customization items
```sql
CREATE TABLE player_cosmetics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player_id UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
    cosmetic_type VARCHAR(50) NOT NULL, -- card_back, table_theme, avatar, emote
    cosmetic_id VARCHAR(100) NOT NULL, -- identifier for the cosmetic item
    acquired_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_equipped BOOLEAN DEFAULT FALSE,
    
    UNIQUE(player_id, cosmetic_type, cosmetic_id)
);

CREATE INDEX idx_player_cosmetics_player ON player_cosmetics (player_id);
CREATE INDEX idx_player_cosmetics_type ON player_cosmetics (cosmetic_type);
CREATE INDEX idx_player_cosmetics_equipped ON player_cosmetics (player_id, is_equipped) WHERE is_equipped = TRUE;
```

### player_achievements
Achievement tracking and completion
```sql
CREATE TABLE achievements (
    id VARCHAR(100) PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    category VARCHAR(50) NOT NULL, -- gameplay, social, progression, special
    difficulty VARCHAR(20) NOT NULL, -- common, rare, epic, legendary
    reward_type VARCHAR(50), -- coins, gems, cosmetic, title
    reward_amount INTEGER,
    reward_id VARCHAR(100),
    is_hidden BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE player_achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player_id UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
    achievement_id VARCHAR(100) NOT NULL REFERENCES achievements(id),
    progress INTEGER DEFAULT 0,
    max_progress INTEGER NOT NULL,
    is_completed BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMP WITH TIME ZONE,
    
    UNIQUE(player_id, achievement_id)
);

CREATE INDEX idx_player_achievements_player ON player_achievements (player_id);
CREATE INDEX idx_player_achievements_completed ON player_achievements (is_completed, completed_at);
```

## 🎯 Game Data Tables

### games
Core game records and outcomes
```sql
CREATE TABLE games (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    game_mode VARCHAR(50) NOT NULL, -- ranked, casual, tournament, friend_challenge
    
    -- Players
    player1_id UUID NOT NULL REFERENCES players(id),
    player2_id UUID NOT NULL REFERENCES players(id),
    winner_id UUID REFERENCES players(id),
    
    -- Game Details
    status VARCHAR(20) DEFAULT 'active', -- active, completed, abandoned, forfeit
    initial_state JSONB NOT NULL, -- Starting hands, deck state
    final_state JSONB, -- Final scores, card positions
    move_count INTEGER DEFAULT 0,
    duration INTEGER, -- seconds
    
    -- Ratings (at time of game)
    player1_rating_before INTEGER NOT NULL,
    player2_rating_before INTEGER NOT NULL,
    player1_rating_after INTEGER,
    player2_rating_after INTEGER,
    rating_change INTEGER, -- absolute change for winner
    
    -- Scores
    player1_score INTEGER DEFAULT 0,
    player2_score INTEGER DEFAULT 0,
    
    -- Tournament Reference
    tournament_id UUID REFERENCES tournaments(id),
    tournament_round INTEGER,
    
    -- Metadata
    server_region VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    started_at TIMESTAMP WITH TIME ZONE,
    ended_at TIMESTAMP WITH TIME ZONE,
    
    CONSTRAINT valid_players CHECK (player1_id != player2_id),
    CONSTRAINT valid_winner CHECK (winner_id IN (player1_id, player2_id) OR winner_id IS NULL),
    CONSTRAINT valid_status CHECK (status IN ('active', 'completed', 'abandoned', 'forfeit')),
    CONSTRAINT valid_scores CHECK (player1_score >= 0 AND player2_score >= 0 AND player1_score + player2_score <= 8)
);

-- Partition by month for performance
CREATE TABLE games_y2024m01 PARTITION OF games 
FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

CREATE INDEX idx_games_player1 ON games (player1_id);
CREATE INDEX idx_games_player2 ON games (player2_id);
CREATE INDEX idx_games_winner ON games (winner_id);
CREATE INDEX idx_games_mode ON games (game_mode);
CREATE INDEX idx_games_status ON games (status);
CREATE INDEX idx_games_created_at ON games (created_at DESC);
CREATE INDEX idx_games_tournament ON games (tournament_id) WHERE tournament_id IS NOT NULL;
```

### game_moves
Detailed move history for analysis and replay
```sql
CREATE TABLE game_moves (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    game_id UUID NOT NULL REFERENCES games(id) ON DELETE CASCADE,
    player_id UUID NOT NULL REFERENCES players(id),
    move_number INTEGER NOT NULL,
    move_type VARCHAR(50) NOT NULL, -- play_card, continue_trick, pass
    
    -- Move Details
    card_played JSONB, -- {suit: "hearts", value: 7, id: "card_1"}
    table_state_before JSONB NOT NULL,
    table_state_after JSONB,
    valid_moves JSONB, -- Available moves at time of play
    
    -- Timing
    time_taken INTEGER NOT NULL, -- milliseconds
    player_time_remaining INTEGER, -- total time left for player
    
    -- Analysis
    move_quality DECIMAL(3,2), -- AI evaluation: 0.0-1.0
    was_optimal BOOLEAN,
    
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT valid_move_number CHECK (move_number > 0),
    CONSTRAINT valid_time_taken CHECK (time_taken > 0 AND time_taken <= 30000)
);

CREATE INDEX idx_game_moves_game_id ON game_moves (game_id, move_number);
CREATE INDEX idx_game_moves_player ON game_moves (player_id);
CREATE INDEX idx_game_moves_timestamp ON game_moves (timestamp);
```

## 🏆 Competitive Systems

### seasons
Season definitions and configurations
```sql
CREATE TABLE seasons (
    id VARCHAR(50) PRIMARY KEY, -- "2024_q1"
    name VARCHAR(200) NOT NULL,
    description TEXT,
    
    -- Timing
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE NOT NULL,
    registration_start TIMESTAMP WITH TIME ZONE,
    registration_end TIMESTAMP WITH TIME ZONE,
    
    -- Rules
    reset_type VARCHAR(20) NOT NULL, -- soft, hard, none
    reset_amount DECIMAL(3,2) DEFAULT 0.75, -- percentage for soft reset
    min_rating_after_reset INTEGER DEFAULT 800,
    
    -- Rewards
    reward_config JSONB NOT NULL,
    
    -- Status
    status VARCHAR(20) DEFAULT 'upcoming', -- upcoming, active, ended
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT valid_dates CHECK (end_date > start_date),
    CONSTRAINT valid_status CHECK (status IN ('upcoming', 'active', 'ended'))
);
```

### leaderboards
Historical leaderboard snapshots
```sql
CREATE TABLE leaderboards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    season_id VARCHAR(50) NOT NULL REFERENCES seasons(id),
    leaderboard_type VARCHAR(50) NOT NULL, -- global, friends, arena
    snapshot_date TIMESTAMP WITH TIME ZONE NOT NULL,
    
    -- Snapshot data
    entries JSONB NOT NULL, -- Array of player rankings
    total_players INTEGER NOT NULL,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(season_id, leaderboard_type, snapshot_date)
);

CREATE INDEX idx_leaderboards_season ON leaderboards (season_id);
CREATE INDEX idx_leaderboards_type ON leaderboards (leaderboard_type);
CREATE INDEX idx_leaderboards_date ON leaderboards (snapshot_date DESC);
```

### tournaments
Tournament definitions and state
```sql
CREATE TABLE tournaments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(200) NOT NULL,
    description TEXT,
    type VARCHAR(50) NOT NULL, -- single_elimination, swiss, round_robin
    
    -- Configuration
    max_participants INTEGER NOT NULL,
    entry_fee_coins INTEGER DEFAULT 0,
    entry_fee_gems INTEGER DEFAULT 0,
    prize_pool JSONB NOT NULL,
    
    -- Scheduling
    registration_start TIMESTAMP WITH TIME ZONE NOT NULL,
    registration_end TIMESTAMP WITH TIME ZONE NOT NULL,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE,
    
    -- Status
    status VARCHAR(20) DEFAULT 'upcoming', -- upcoming, registration, active, completed, cancelled
    current_round INTEGER DEFAULT 0,
    total_rounds INTEGER,
    
    -- Results
    winner_id UUID REFERENCES players(id),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT valid_participants CHECK (max_participants > 0),
    CONSTRAINT valid_schedule CHECK (start_time > registration_end),
    CONSTRAINT valid_status CHECK (status IN ('upcoming', 'registration', 'active', 'completed', 'cancelled'))
);

CREATE INDEX idx_tournaments_status ON tournaments (status);
CREATE INDEX idx_tournaments_start_time ON tournaments (start_time);
```

### tournament_participants
Player entries in tournaments
```sql
CREATE TABLE tournament_participants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
    player_id UUID NOT NULL REFERENCES players(id),
    
    -- Entry Details
    seed_rating INTEGER NOT NULL,
    registration_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    entry_fee_paid JSONB, -- {coins: 100, gems: 0}
    
    -- Tournament Progress
    current_round INTEGER DEFAULT 0,
    wins INTEGER DEFAULT 0,
    losses INTEGER DEFAULT 0,
    is_eliminated BOOLEAN DEFAULT FALSE,
    final_position INTEGER,
    
    -- Rewards
    rewards_earned JSONB, -- {coins: 500, cosmetics: ["gold_trophy"]}
    
    UNIQUE(tournament_id, player_id)
);

CREATE INDEX idx_tournament_participants_tournament ON tournament_participants (tournament_id);
CREATE INDEX idx_tournament_participants_player ON tournament_participants (player_id);
CREATE INDEX idx_tournament_participants_active ON tournament_participants (tournament_id, is_eliminated) WHERE is_eliminated = FALSE;
```

## 💰 Economy Tables

### shop_items
Available items for purchase
```sql
CREATE TABLE shop_items (
    id VARCHAR(100) PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    category VARCHAR(50) NOT NULL, -- card_backs, table_themes, avatars, bundles
    subcategory VARCHAR(50),
    
    -- Pricing
    price_coins INTEGER,
    price_gems INTEGER,
    original_price_coins INTEGER,
    original_price_gems INTEGER,
    
    -- Rarity and Availability
    rarity VARCHAR(20) NOT NULL, -- common, rare, epic, legendary
    is_available BOOLEAN DEFAULT TRUE,
    is_featured BOOLEAN DEFAULT FALSE,
    availability_start TIMESTAMP WITH TIME ZONE,
    availability_end TIMESTAMP WITH TIME ZONE,
    
    -- Metadata
    preview_image_url TEXT,
    tags TEXT[],
    sort_order INTEGER DEFAULT 0,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT valid_pricing CHECK (price_coins > 0 OR price_gems > 0),
    CONSTRAINT valid_rarity CHECK (rarity IN ('common', 'rare', 'epic', 'legendary'))
);

CREATE INDEX idx_shop_items_category ON shop_items (category);
CREATE INDEX idx_shop_items_available ON shop_items (is_available) WHERE is_available = TRUE;
CREATE INDEX idx_shop_items_featured ON shop_items (is_featured) WHERE is_featured = TRUE;
CREATE INDEX idx_shop_items_rarity ON shop_items (rarity);
```

### transactions
Purchase and currency transaction history
```sql
CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player_id UUID NOT NULL REFERENCES players(id),
    transaction_type VARCHAR(50) NOT NULL, -- purchase, reward, refund, admin
    
    -- Transaction Details
    item_id VARCHAR(100) REFERENCES shop_items(id),
    currency_type VARCHAR(20) NOT NULL, -- coins, gems
    amount INTEGER NOT NULL, -- positive for gains, negative for spending
    balance_before INTEGER NOT NULL,
    balance_after INTEGER NOT NULL,
    
    -- Context
    source VARCHAR(100), -- shop, game_reward, achievement, daily_bonus
    reference_id UUID, -- game_id, achievement_id, etc.
    description TEXT,
    
    -- Status
    status VARCHAR(20) DEFAULT 'completed', -- pending, completed, failed, refunded
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    processed_at TIMESTAMP WITH TIME ZONE,
    
    CONSTRAINT valid_currency CHECK (currency_type IN ('coins', 'gems')),
    CONSTRAINT valid_status CHECK (status IN ('pending', 'completed', 'failed', 'refunded'))
);

CREATE INDEX idx_transactions_player ON transactions (player_id);
CREATE INDEX idx_transactions_type ON transactions (transaction_type);
CREATE INDEX idx_transactions_created_at ON transactions (created_at DESC);
CREATE INDEX idx_transactions_reference ON transactions (reference_id) WHERE reference_id IS NOT NULL;
```

## 👥 Social Features

### friendships
Player friend relationships
```sql
CREATE TABLE friendships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    requester_id UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
    addressee_id UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'pending', -- pending, accepted, blocked
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT no_self_friendship CHECK (requester_id != addressee_id),
    CONSTRAINT valid_status CHECK (status IN ('pending', 'accepted', 'blocked')),
    UNIQUE(requester_id, addressee_id)
);

CREATE INDEX idx_friendships_requester ON friendships (requester_id);
CREATE INDEX idx_friendships_addressee ON friendships (addressee_id);
CREATE INDEX idx_friendships_status ON friendships (status);

-- View for active friendships
CREATE VIEW active_friendships AS
SELECT 
    CASE WHEN requester_id < addressee_id THEN requester_id ELSE addressee_id END as player1_id,
    CASE WHEN requester_id < addressee_id THEN addressee_id ELSE requester_id END as player2_id,
    created_at,
    updated_at
FROM friendships 
WHERE status = 'accepted';
```

### friend_challenges
Direct challenges between friends
```sql
CREATE TABLE friend_challenges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    challenger_id UUID NOT NULL REFERENCES players(id),
    challenged_id UUID NOT NULL REFERENCES players(id),
    
    -- Challenge Details
    message TEXT,
    game_mode VARCHAR(50) DEFAULT 'casual',
    
    -- Status
    status VARCHAR(20) DEFAULT 'pending', -- pending, accepted, declined, expired, completed
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    
    -- Result (if completed)
    game_id UUID REFERENCES games(id),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT no_self_challenge CHECK (challenger_id != challenged_id),
    CONSTRAINT valid_expiry CHECK (expires_at > created_at),
    CONSTRAINT valid_status CHECK (status IN ('pending', 'accepted', 'declined', 'expired', 'completed'))
);

CREATE INDEX idx_friend_challenges_challenger ON friend_challenges (challenger_id);
CREATE INDEX idx_friend_challenges_challenged ON friend_challenges (challenged_id);
CREATE INDEX idx_friend_challenges_status ON friend_challenges (status);
CREATE INDEX idx_friend_challenges_expires ON friend_challenges (expires_at) WHERE status = 'pending';
```

## 📊 Analytics Tables

### player_sessions
Detailed session tracking for analytics
```sql
CREATE TABLE player_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player_id UUID NOT NULL REFERENCES players(id),
    
    -- Session Details
    start_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    end_time TIMESTAMP WITH TIME ZONE,
    duration INTEGER, -- seconds
    
    -- Device Information
    device_model VARCHAR(100),
    os_version VARCHAR(50),
    app_version VARCHAR(20),
    screen_resolution VARCHAR(20),
    
    -- Network Information
    ip_address INET,
    country_code VARCHAR(2),
    connection_type VARCHAR(20), -- wifi, cellular, unknown
    
    -- Session Activities
    games_played INTEGER DEFAULT 0,
    games_won INTEGER DEFAULT 0,
    screens_visited TEXT[],
    features_used TEXT[],
    
    -- Performance Metrics
    avg_frame_rate DECIMAL(5,2),
    crash_count INTEGER DEFAULT 0,
    error_count INTEGER DEFAULT 0,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Partition by week for analytics performance
CREATE TABLE player_sessions_y2024w01 PARTITION OF player_sessions
FOR VALUES FROM ('2024-01-01') TO ('2024-01-08');

CREATE INDEX idx_player_sessions_player ON player_sessions (player_id);
CREATE INDEX idx_player_sessions_start_time ON player_sessions (start_time DESC);
CREATE INDEX idx_player_sessions_country ON player_sessions (country_code);
```

### daily_metrics
Aggregated daily statistics
```sql
CREATE TABLE daily_metrics (
    date DATE PRIMARY KEY,
    
    -- User Metrics
    daily_active_users INTEGER DEFAULT 0,
    new_users INTEGER DEFAULT 0,
    returning_users INTEGER DEFAULT 0,
    
    -- Game Metrics
    games_played INTEGER DEFAULT 0,
    games_completed INTEGER DEFAULT 0,
    average_game_duration DECIMAL(8,2),
    
    -- Engagement Metrics
    average_session_duration DECIMAL(8,2),
    sessions_per_user DECIMAL(5,2),
    
    -- Revenue Metrics
    revenue_coins INTEGER DEFAULT 0,
    revenue_gems INTEGER DEFAULT 0,
    paying_users INTEGER DEFAULT 0,
    
    -- Performance Metrics
    crash_rate DECIMAL(5,4),
    average_fps DECIMAL(5,2),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_daily_metrics_date ON daily_metrics (date DESC);
```

## 🔧 Database Functions & Triggers

### Update Rating Function
```sql
CREATE OR REPLACE FUNCTION update_player_rating(
    p_player_id UUID,
    p_rating_change INTEGER,
    p_game_id UUID
) RETURNS VOID AS $$
BEGIN
    UPDATE players 
    SET rating = GREATEST(0, rating + p_rating_change),
        peak_rating = GREATEST(peak_rating, rating + p_rating_change),
        updated_at = NOW()
    WHERE id = p_player_id;
    
    -- Update arena based on new rating
    UPDATE players 
    SET current_arena = (
        SELECT MAX(arena_id) 
        FROM arenas 
        WHERE min_rating <= rating
    )
    WHERE id = p_player_id;
END;
$$ LANGUAGE plpgsql;
```

### Game Statistics Trigger
```sql
CREATE OR REPLACE FUNCTION update_game_statistics()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' AND OLD.status = 'active' AND NEW.status = 'completed' THEN
        -- Update player statistics
        UPDATE players 
        SET games_played = games_played + 1,
            games_won = games_won + CASE WHEN id = NEW.winner_id THEN 1 ELSE 0 END,
            total_play_time = total_play_time + COALESCE(NEW.duration, 0),
            last_game_at = NOW(),
            updated_at = NOW()
        WHERE id IN (NEW.player1_id, NEW.player2_id);
        
        -- Update win rates
        UPDATE players 
        SET win_rate = CASE 
            WHEN games_played > 0 THEN CAST(games_won AS DECIMAL) / games_played
            ELSE 0
        END
        WHERE id IN (NEW.player1_id, NEW.player2_id);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_game_statistics
    AFTER UPDATE ON games
    FOR EACH ROW
    EXECUTE FUNCTION update_game_statistics();
```

## 📈 Performance Optimization

### Key Indexes for Query Performance
```sql
-- Matchmaking queries
CREATE INDEX idx_players_rating_active ON players (rating DESC, last_active DESC) 
WHERE last_active > NOW() - INTERVAL '1 hour';

-- Leaderboard queries
CREATE INDEX idx_players_seasonal_rating ON players (season_rating DESC, season_games DESC)
WHERE season_games >= 10;

-- Game history queries
CREATE INDEX idx_games_player_recent ON games (player1_id, created_at DESC)
WHERE created_at > NOW() - INTERVAL '30 days';

-- Friend activity queries
CREATE INDEX idx_players_friends_active ON players (last_active DESC)
WHERE id IN (SELECT player1_id FROM active_friendships UNION SELECT player2_id FROM active_friendships);
```

### Materialized Views for Analytics
```sql
CREATE MATERIALIZED VIEW player_rankings AS
SELECT 
    id,
    username,
    rating,
    level,
    games_played,
    win_rate,
    RANK() OVER (ORDER BY rating DESC) as global_rank,
    DENSE_RANK() OVER (PARTITION BY current_arena ORDER BY rating DESC) as arena_rank
FROM players p
JOIN users u ON p.user_id = u.id
WHERE u.status = 'active' AND p.games_played >= 10;

CREATE UNIQUE INDEX idx_player_rankings_id ON player_rankings (id);
CREATE INDEX idx_player_rankings_global ON player_rankings (global_rank);
CREATE INDEX idx_player_rankings_arena ON player_rankings (current_arena, arena_rank);

-- Refresh every hour
SELECT cron.schedule('refresh-player-rankings', '0 * * * *', 'REFRESH MATERIALIZED VIEW CONCURRENTLY player_rankings;');
```

This comprehensive database schema supports all features of the Septica game including user management, game mechanics, competitive systems, social features, and analytics. The design prioritizes performance, data integrity, and scalability for a production gaming environment.