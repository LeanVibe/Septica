package database

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// Base model with UUID and timestamps
type BaseModel struct {
	ID        uuid.UUID `gorm:"type:uuid;primary_key" json:"id"`
	CreatedAt time.Time `gorm:"autoCreateTime" json:"created_at"`
	UpdatedAt time.Time `gorm:"autoUpdateTime" json:"updated_at"`
}

// User represents a registered user account
type User struct {
	BaseModel
	Username     string     `gorm:"uniqueIndex;not null" json:"username"`
	Email        string     `gorm:"uniqueIndex;not null" json:"email"`
	PasswordHash string     `gorm:"not null" json:"-"`
	IsActive     bool       `gorm:"default:true" json:"is_active"`
	LastLoginAt  *time.Time `json:"last_login_at"`

	// Relationships
	Player *Player `gorm:"foreignKey:UserID;constraint:OnUpdate:CASCADE,OnDelete:SET NULL;" json:"player,omitempty"`
}

// Player represents a game player profile
type Player struct {
	BaseModel
	UserID   uuid.UUID `gorm:"type:uuid;uniqueIndex" json:"user_id"`
	Username string    `gorm:"not null" json:"username"`
	Level    int       `gorm:"default:1" json:"level"`
	XP       int       `gorm:"default:0" json:"xp"`
	Rating   int       `gorm:"default:1200" json:"rating"`
	Arena    int       `gorm:"default:1" json:"arena"`
	Coins    int       `gorm:"default:1000" json:"coins"`
	Gems     int       `gorm:"default:0" json:"gems"`

	// Cosmetic preferences
	SelectedCardBack   string `gorm:"default:default" json:"selected_card_back"`
	SelectedTableTheme string `gorm:"default:default" json:"selected_table_theme"`
	SelectedAvatar     string `gorm:"default:default" json:"selected_avatar"`

	// Relationships
	User         *User  `gorm:"foreignKey:UserID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"user,omitempty"`
	GamesPlayer1 []Game `gorm:"foreignKey:Player1ID" json:"-"`
	GamesPlayer2 []Game `gorm:"foreignKey:Player2ID" json:"-"`
}

// PlayerStatistics holds game statistics for a player
type PlayerStatistics struct {
	BaseModel
	PlayerID             uuid.UUID `gorm:"type:uuid;uniqueIndex" json:"player_id"`
	GamesPlayed          int       `gorm:"default:0" json:"games_played"`
	GamesWon             int       `gorm:"default:0" json:"games_won"`
	GamesLost            int       `gorm:"default:0" json:"games_lost"`
	GamesDrawn           int       `gorm:"default:0" json:"games_drawn"`
	TotalPointsCollected int       `gorm:"default:0" json:"total_points_collected"`
	MarsWins             int       `gorm:"default:0" json:"mars_wins"`
	BestWinStreak        int       `gorm:"default:0" json:"best_win_streak"`
	CurrentWinStreak     int       `gorm:"default:0" json:"current_win_streak"`
	AverageGameDuration  float64   `gorm:"default:0" json:"average_game_duration"`

	// Card-specific statistics
	SevensPlayed  int `gorm:"default:0" json:"sevens_played"`
	EightsPlayed  int `gorm:"default:0" json:"eights_played"`
	PointCardsWon int `gorm:"default:0" json:"point_cards_won"`
	TricksWon     int `gorm:"default:0" json:"tricks_won"`
}

// Game represents a game session between players (2-4 players supported)
type Game struct {
	BaseModel
	Player1ID uuid.UUID  `gorm:"type:uuid;not null" json:"player1_id"`
	Player2ID uuid.UUID  `gorm:"type:uuid;not null" json:"player2_id"`
	Player3ID *uuid.UUID `gorm:"type:uuid" json:"player3_id,omitempty"` // For 3-4 player games
	Player4ID *uuid.UUID `gorm:"type:uuid" json:"player4_id,omitempty"` // For 4 player games

	// Tournament context
	TournamentID        *uuid.UUID `gorm:"type:uuid" json:"tournament_id"`
	TournamentBracketID *uuid.UUID `gorm:"type:uuid" json:"tournament_bracket_id"`
	TournamentRound     *int       `json:"tournament_round"`
	IsPlayoffGame       bool       `gorm:"default:false" json:"is_playoff_game"`

	// Game state
	Status       string     `gorm:"default:waiting" json:"status"` // waiting, in_progress, completed, abandoned
	WinnerID     *uuid.UUID `gorm:"type:uuid" json:"winner_id"`
	WinningTeam  *string    `json:"winning_team,omitempty"` // "team1", "team2" for 4-player games
	Player1Score int        `gorm:"default:0" json:"player1_score"`
	Player2Score int        `gorm:"default:0" json:"player2_score"`
	Player3Score *int       `json:"player3_score,omitempty"` // For 3-4 player games
	Player4Score *int       `json:"player4_score,omitempty"` // For 4 player games
	Team1Score   *int       `json:"team1_score,omitempty"`   // For 4-player team mode
	Team2Score   *int       `json:"team2_score,omitempty"`   // For 4-player team mode
	IsMars       bool       `gorm:"default:false" json:"is_mars"`

	// Game metadata
	GameMode          string     `gorm:"default:ranked" json:"game_mode"` // ranked, casual, tournament, swiss
	AuthenticMode     string     `json:"authentic_mode,omitempty"`        // "2_player", "3_player", "4_player" for authentic Septica
	UseAuthenticRules bool       `gorm:"default:false" json:"use_authentic_rules"`
	StartedAt         *time.Time `json:"started_at"`
	EndedAt           *time.Time `json:"ended_at"`
	DurationMs        int64      `gorm:"default:0" json:"duration_ms"`
	MoveCount         int        `gorm:"default:0" json:"move_count"`
	TrickCount        int        `gorm:"default:0" json:"trick_count"`

	// Rating context (captured at game start)
	Player1RatingBefore int  `json:"player1_rating_before"`
	Player2RatingBefore int  `json:"player2_rating_before"`
	Player3RatingBefore *int `json:"player3_rating_before,omitempty"` // For 3-4 player games
	Player4RatingBefore *int `json:"player4_rating_before,omitempty"` // For 4 player games
	Player1RatingAfter  *int `json:"player1_rating_after"`
	Player2RatingAfter  *int `json:"player2_rating_after"`
	Player3RatingAfter  *int `json:"player3_rating_after,omitempty"`
	Player4RatingAfter  *int `json:"player4_rating_after,omitempty"`

	// Rating changes
	Player1RatingChange int  `gorm:"default:0" json:"player1_rating_change"`
	Player2RatingChange int  `gorm:"default:0" json:"player2_rating_change"`
	Player3RatingChange *int `json:"player3_rating_change,omitempty"`
	Player4RatingChange *int `json:"player4_rating_change,omitempty"`

	// Game quality metrics
	AverageTimeBetweenMoves   float64  `gorm:"default:0" json:"average_time_between_moves"`
	Player1AverageTimePerMove float64  `gorm:"default:0" json:"player1_average_time_per_move"`
	Player2AverageTimePerMove float64  `gorm:"default:0" json:"player2_average_time_per_move"`
	Player3AverageTimePerMove *float64 `json:"player3_average_time_per_move,omitempty"`
	Player4AverageTimePerMove *float64 `json:"player4_average_time_per_move,omitempty"`

	// Relationships
	Player1           Player             `gorm:"foreignKey:Player1ID;constraint:OnUpdate:CASCADE,OnDelete:RESTRICT;" json:"player1,omitempty"`
	Player2           Player             `gorm:"foreignKey:Player2ID;constraint:OnUpdate:CASCADE,OnDelete:RESTRICT;" json:"player2,omitempty"`
	Player3           *Player            `gorm:"foreignKey:Player3ID;constraint:OnUpdate:CASCADE,OnDelete:RESTRICT;" json:"player3,omitempty"`
	Player4           *Player            `gorm:"foreignKey:Player4ID;constraint:OnUpdate:CASCADE,OnDelete:RESTRICT;" json:"player4,omitempty"`
	Winner            *Player            `gorm:"foreignKey:WinnerID;constraint:OnUpdate:CASCADE,OnDelete:SET NULL;" json:"winner,omitempty"`
	Tournament        *Tournament        `gorm:"foreignKey:TournamentID;constraint:OnUpdate:CASCADE,OnDelete:SET NULL;" json:"tournament,omitempty"`
	TournamentBracket *TournamentBracket `gorm:"foreignKey:TournamentBracketID;constraint:OnUpdate:CASCADE,OnDelete:SET NULL;" json:"tournament_bracket,omitempty"`
	Moves             []GameMove         `gorm:"foreignKey:GameID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"moves,omitempty"`
}

// GameMove represents a single move in a game
type GameMove struct {
	BaseModel
	GameID         uuid.UUID `gorm:"type:uuid;not null" json:"game_id"`
	PlayerID       uuid.UUID `gorm:"type:uuid;not null" json:"player_id"`
	MoveNumber     int       `gorm:"not null" json:"move_number"`
	CardSuit       string    `json:"card_suit,omitempty"`  // Nullable for PASS moves
	CardValue      int       `json:"card_value,omitempty"` // Nullable for PASS moves
	TableCardCount int       `gorm:"not null" json:"table_card_count"`
	TrickNumber    int       `gorm:"not null" json:"trick_number"`
	IsWinningMove  bool      `gorm:"default:false" json:"is_winning_move"`
	TimeTakenMs    int64     `gorm:"default:0" json:"time_taken_ms"`

	// Authentic Septica specific fields
	MoveType          string  `gorm:"default:PLAY_CARD" json:"move_type"`  // "PLAY_CARD", "PASS"
	IsObjection       bool    `gorm:"default:false" json:"is_objection"`   // Was this an objection move
	ObjectedCardSuit  *string `json:"objected_card_suit,omitempty"`        // Card being objected to
	ObjectedCardValue *int    `json:"objected_card_value,omitempty"`       // Card being objected to
	RoundComplete     bool    `gorm:"default:false" json:"round_complete"` // Did this move complete the round
	PointsAwarded     int     `gorm:"default:0" json:"points_awarded"`     // Points gained from this move

	// Relationships
	Game   Game   `gorm:"foreignKey:GameID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"game,omitempty"`
	Player Player `gorm:"foreignKey:PlayerID;constraint:OnUpdate:CASCADE,OnDelete:RESTRICT;" json:"player,omitempty"`
}

// Tournament represents a tournament structure
type Tournament struct {
	BaseModel
	Name        string `gorm:"not null" json:"name"`
	Description string `json:"description"`
	Type        string `gorm:"not null" json:"type"`               // single_elimination, double_elimination, swiss_system, round_robin
	Status      string `gorm:"default:registration" json:"status"` // registration, in_progress, completed, cancelled

	// Tournament settings
	MaxParticipants    int  `gorm:"not null" json:"max_participants"`
	MinParticipants    int  `gorm:"default:2" json:"min_participants"`
	EntryFeeCoins      int  `gorm:"default:0" json:"entry_fee_coins"`
	EntryFeeGems       int  `gorm:"default:0" json:"entry_fee_gems"`
	IsRankedTournament bool `gorm:"default:true" json:"is_ranked_tournament"`

	// Prize pool and distribution
	PrizePoolCoins          int    `gorm:"default:0" json:"prize_pool_coins"`
	PrizePoolGems           int    `gorm:"default:0" json:"prize_pool_gems"`
	PrizeDistributionType   string `gorm:"default:percentage" json:"prize_distribution_type"` // percentage, fixed, winner_takes_all
	FirstPlacePrizePercent  int    `gorm:"default:50" json:"first_place_prize_percent"`
	SecondPlacePrizePercent int    `gorm:"default:30" json:"second_place_prize_percent"`
	ThirdPlacePrizePercent  int    `gorm:"default:20" json:"third_place_prize_percent"`

	// Tournament progression settings (for Swiss system)
	SwissRounds       int `gorm:"default:0" json:"swiss_rounds"`
	CurrentSwissRound int `gorm:"default:0" json:"current_swiss_round"`
	SwissPointsToWin  int `gorm:"default:3" json:"swiss_points_to_win"`

	// ELO rating requirements
	MinRatingRequired int `gorm:"default:0" json:"min_rating_required"`
	MaxRatingAllowed  int `gorm:"default:3000" json:"max_rating_allowed"`

	// Timing
	RegistrationStart time.Time  `gorm:"not null" json:"registration_start"`
	RegistrationEnd   time.Time  `gorm:"not null" json:"registration_end"`
	TournamentStart   time.Time  `gorm:"not null" json:"tournament_start"`
	TournamentEnd     *time.Time `json:"tournament_end"`

	// Metadata
	CreatorPlayerID uuid.UUID `gorm:"type:uuid" json:"creator_player_id"`
	IsPrivate       bool      `gorm:"default:false" json:"is_private"`
	InviteCode      string    `gorm:"uniqueIndex" json:"invite_code,omitempty"`

	// Relationships
	Creator      *Player                 `gorm:"foreignKey:CreatorPlayerID;constraint:OnUpdate:CASCADE,OnDelete:SET NULL;" json:"creator,omitempty"`
	Participants []TournamentParticipant `gorm:"foreignKey:TournamentID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"participants,omitempty"`
	Brackets     []TournamentBracket     `gorm:"foreignKey:TournamentID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"brackets,omitempty"`
	Games        []Game                  `gorm:"foreignKey:TournamentID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"games,omitempty"`
}

// TournamentParticipant represents a player's participation in a tournament
type TournamentParticipant struct {
	BaseModel
	TournamentID uuid.UUID `gorm:"type:uuid;not null;uniqueIndex:idx_tournament_player" json:"tournament_id"`
	PlayerID     uuid.UUID `gorm:"type:uuid;not null;uniqueIndex:idx_tournament_player" json:"player_id"`

	// Tournament progress
	BracketPosition  int  `json:"bracket_position"`
	SeedPosition     int  `json:"seed_position"`
	IsEliminated     bool `gorm:"default:false" json:"is_eliminated"`
	EliminationRound *int `json:"elimination_round"`
	FinalRank        *int `json:"final_rank"`

	// Swiss system specific
	SwissPoints        int     `gorm:"default:0" json:"swiss_points"`
	SwissWins          int     `gorm:"default:0" json:"swiss_wins"`
	SwissLosses        int     `gorm:"default:0" json:"swiss_losses"`
	SwissDraws         int     `gorm:"default:0" json:"swiss_draws"`
	SwissBuchholzScore float64 `gorm:"default:0" json:"swiss_buchholz_score"`

	// Performance metrics
	GamesWon          int     `gorm:"default:0" json:"games_won"`
	GamesLost         int     `gorm:"default:0" json:"games_lost"`
	TotalPointsScored int     `gorm:"default:0" json:"total_points_scored"`
	AverageGameTime   float64 `gorm:"default:0" json:"average_game_time"`

	// Rating changes
	StartingRating int  `json:"starting_rating"`
	EndingRating   *int `json:"ending_rating"`
	RatingChange   int  `gorm:"default:0" json:"rating_change"`

	// Prizes awarded
	PrizeCoins int `gorm:"default:0" json:"prize_coins"`
	PrizeGems  int `gorm:"default:0" json:"prize_gems"`

	// Registration info
	RegistrationDate time.Time `gorm:"autoCreateTime" json:"registration_date"`

	// Relationships
	Tournament Tournament `gorm:"foreignKey:TournamentID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"tournament,omitempty"`
	Player     Player     `gorm:"foreignKey:PlayerID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"player,omitempty"`
}

// TournamentBracket represents a bracket structure for elimination tournaments
type TournamentBracket struct {
	BaseModel
	TournamentID      uuid.UUID  `gorm:"type:uuid;not null" json:"tournament_id"`
	BracketType       string     `gorm:"not null" json:"bracket_type"` // winners, losers
	Round             int        `gorm:"not null" json:"round"`
	Position          int        `gorm:"not null" json:"position"`
	Player1ID         *uuid.UUID `gorm:"type:uuid" json:"player1_id"`
	Player2ID         *uuid.UUID `gorm:"type:uuid" json:"player2_id"`
	WinnerID          *uuid.UUID `gorm:"type:uuid" json:"winner_id"`
	GameID            *uuid.UUID `gorm:"type:uuid" json:"game_id"`
	AdvancesToBracket *uuid.UUID `gorm:"type:uuid" json:"advances_to_bracket"`
	IsComplete        bool       `gorm:"default:false" json:"is_complete"`
	IsBye             bool       `gorm:"default:false" json:"is_bye"`

	// Relationships
	Tournament Tournament `gorm:"foreignKey:TournamentID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"tournament,omitempty"`
	Player1    *Player    `gorm:"foreignKey:Player1ID;constraint:OnUpdate:CASCADE,OnDelete:SET NULL;" json:"player1,omitempty"`
	Player2    *Player    `gorm:"foreignKey:Player2ID;constraint:OnUpdate:CASCADE,OnDelete:SET NULL;" json:"player2,omitempty"`
	Winner     *Player    `gorm:"foreignKey:WinnerID;constraint:OnUpdate:CASCADE,OnDelete:SET NULL;" json:"winner,omitempty"`
	// Game relationship removed to avoid circular dependency during migration
	// Game can be loaded manually using GameID field when needed
	// Game       *Game      `gorm:"foreignKey:GameID;constraint:OnUpdate:CASCADE,OnDelete:SET NULL;" json:"game,omitempty"`
}

// ELORatingHistory tracks rating changes over time
type ELORatingHistory struct {
	BaseModel
	PlayerID     uuid.UUID  `gorm:"type:uuid;not null" json:"player_id"`
	GameID       *uuid.UUID `gorm:"type:uuid" json:"game_id"`
	TournamentID *uuid.UUID `gorm:"type:uuid" json:"tournament_id"`

	// Rating changes
	OldRating    int `gorm:"not null" json:"old_rating"`
	NewRating    int `gorm:"not null" json:"new_rating"`
	RatingChange int `gorm:"not null" json:"rating_change"`
	KFactor      int `gorm:"not null" json:"k_factor"`

	// Context
	ChangeReason   string     `gorm:"not null" json:"change_reason"` // game_win, game_loss, tournament_completion, manual_adjustment
	OpponentID     *uuid.UUID `gorm:"type:uuid" json:"opponent_id"`
	OpponentRating *int       `json:"opponent_rating"`

	// Game result context
	GameResult      *string `json:"game_result"` // win, loss, draw
	ScoreDifference *int    `json:"score_difference"`

	// Relationships
	Player     Player      `gorm:"foreignKey:PlayerID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"player,omitempty"`
	Game       *Game       `gorm:"foreignKey:GameID;constraint:OnUpdate:CASCADE,OnDelete:SET NULL;" json:"game,omitempty"`
	Tournament *Tournament `gorm:"foreignKey:TournamentID;constraint:OnUpdate:CASCADE,OnDelete:SET NULL;" json:"tournament,omitempty"`
	Opponent   *Player     `gorm:"foreignKey:OpponentID;constraint:OnUpdate:CASCADE,OnDelete:SET NULL;" json:"opponent,omitempty"`
}

// PlayerSeasonStats tracks player performance across seasons
type PlayerSeasonStats struct {
	BaseModel
	PlayerID uuid.UUID `gorm:"type:uuid;not null;uniqueIndex:idx_player_season" json:"player_id"`
	Season   string    `gorm:"not null;uniqueIndex:idx_player_season" json:"season"`

	// Tournament performance
	TournamentsPlayed  int `gorm:"default:0" json:"tournaments_played"`
	TournamentsWon     int `gorm:"default:0" json:"tournaments_won"`
	TournamentTop3     int `gorm:"default:0" json:"tournament_top3"`
	TournamentTop8     int `gorm:"default:0" json:"tournament_top8"`
	TotalPrizeCoinsWon int `gorm:"default:0" json:"total_prize_coins_won"`
	TotalPrizeGemsWon  int `gorm:"default:0" json:"total_prize_gems_won"`

	// Rating progression
	SeasonStartRating  int  `json:"season_start_rating"`
	SeasonEndRating    *int `json:"season_end_rating"`
	SeasonPeakRating   int  `json:"season_peak_rating"`
	SeasonLowestRating int  `json:"season_lowest_rating"`

	// Game performance
	RankedGamesPlayed int     `gorm:"default:0" json:"ranked_games_played"`
	RankedGamesWon    int     `gorm:"default:0" json:"ranked_games_won"`
	WinRate           float64 `gorm:"default:0" json:"win_rate"`

	// Relationships
	Player Player `gorm:"foreignKey:PlayerID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"player,omitempty"`
}

// MatchmakingQueue tracks players waiting for matches
type MatchmakingQueue struct {
	BaseModel
	PlayerID    uuid.UUID `gorm:"type:uuid;not null;uniqueIndex" json:"player_id"`
	QueueType   string    `gorm:"not null" json:"queue_type"` // ranked, casual, tournament
	Rating      int       `gorm:"not null" json:"rating"`
	QueuedAt    time.Time `gorm:"autoCreateTime" json:"queued_at"`
	SearchRange int       `gorm:"default:100" json:"search_range"`
	MaxWaitTime int       `gorm:"default:300" json:"max_wait_time"` // seconds
	IsActive    bool      `gorm:"default:true" json:"is_active"`

	// Relationships
	Player Player `gorm:"foreignKey:PlayerID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"player,omitempty"`
}

// Friendship represents a friendship between two players
type Friendship struct {
	BaseModel
	RequesterID uuid.UUID `gorm:"type:uuid;not null" json:"requester_id"`
	AddresseeID uuid.UUID `gorm:"type:uuid;not null" json:"addressee_id"`
	Status      string    `gorm:"default:pending" json:"status"` // pending, accepted, blocked

	// Relationships
	Requester Player `gorm:"foreignKey:RequesterID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"requester,omitempty"`
	Addressee Player `gorm:"foreignKey:AddresseeID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"addressee,omitempty"`
}

// ChatMessage represents a chat message in a game
type ChatMessage struct {
	BaseModel
	GameID   uuid.UUID `gorm:"type:uuid;not null" json:"game_id"`
	PlayerID uuid.UUID `gorm:"type:uuid;not null" json:"player_id"`
	Message  string    `gorm:"not null" json:"message"`
	Type     string    `gorm:"default:text" json:"type"` // text, emote, system

	// Relationships
	Game   Game   `gorm:"foreignKey:GameID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"game,omitempty"`
	Player Player `gorm:"foreignKey:PlayerID;constraint:OnUpdate:CASCADE,OnDelete:RESTRICT;" json:"player,omitempty"`
}

// BeforeCreate hook for all models to ensure UUID is set
func (base *BaseModel) BeforeCreate(tx *gorm.DB) error {
	if base.ID == uuid.Nil {
		base.ID = uuid.New()
	}
	return nil
}
