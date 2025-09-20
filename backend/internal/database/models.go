package database

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// Base model with UUID and timestamps
type BaseModel struct {
	ID        uuid.UUID `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	CreatedAt time.Time `gorm:"autoCreateTime" json:"created_at"`
	UpdatedAt time.Time `gorm:"autoUpdateTime" json:"updated_at"`
}

// User represents a registered user account
type User struct {
	BaseModel
	Username     string    `gorm:"uniqueIndex;not null" json:"username"`
	Email        string    `gorm:"uniqueIndex;not null" json:"email"`
	PasswordHash string    `gorm:"not null" json:"-"`
	IsActive     bool      `gorm:"default:true" json:"is_active"`
	LastLoginAt  *time.Time `json:"last_login_at"`
	
	// Relationships
	Player *Player `gorm:"constraint:OnUpdate:CASCADE,OnDelete:SET NULL;" json:"player,omitempty"`
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
	SelectedCardBack   string `gorm:"default:'default'" json:"selected_card_back"`
	SelectedTableTheme string `gorm:"default:'default'" json:"selected_table_theme"`
	SelectedAvatar     string `gorm:"default:'default'" json:"selected_avatar"`
	
	// Relationships
	User        User              `gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"user,omitempty"`
	Statistics  PlayerStatistics  `gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"statistics,omitempty"`
	GamesPlayer1 []Game           `gorm:"foreignKey:Player1ID" json:"-"`
	GamesPlayer2 []Game           `gorm:"foreignKey:Player2ID" json:"-"`
}

// PlayerStatistics holds game statistics for a player
type PlayerStatistics struct {
	BaseModel
	PlayerID            uuid.UUID `gorm:"type:uuid;uniqueIndex" json:"player_id"`
	GamesPlayed         int       `gorm:"default:0" json:"games_played"`
	GamesWon            int       `gorm:"default:0" json:"games_won"`
	GamesLost           int       `gorm:"default:0" json:"games_lost"`
	GamesDrawn          int       `gorm:"default:0" json:"games_drawn"`
	TotalPointsCollected int      `gorm:"default:0" json:"total_points_collected"`
	MarsWins            int       `gorm:"default:0" json:"mars_wins"`
	BestWinStreak       int       `gorm:"default:0" json:"best_win_streak"`
	CurrentWinStreak    int       `gorm:"default:0" json:"current_win_streak"`
	AverageGameDuration float64   `gorm:"default:0" json:"average_game_duration"`
	
	// Card-specific statistics
	SevensPlayed    int `gorm:"default:0" json:"sevens_played"`
	EightsPlayed    int `gorm:"default:0" json:"eights_played"`
	PointCardsWon   int `gorm:"default:0" json:"point_cards_won"`
	TricksWon       int `gorm:"default:0" json:"tricks_won"`
	
	// Relationships
	Player Player `gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"player,omitempty"`
}

// Game represents a game session between two players
type Game struct {
	BaseModel
	Player1ID uuid.UUID `gorm:"type:uuid;not null" json:"player1_id"`
	Player2ID uuid.UUID `gorm:"type:uuid;not null" json:"player2_id"`
	
	// Game state
	Status       string    `gorm:"default:'waiting'" json:"status"` // waiting, in_progress, completed, abandoned
	WinnerID     *uuid.UUID `gorm:"type:uuid" json:"winner_id"`
	Player1Score int       `gorm:"default:0" json:"player1_score"`
	Player2Score int       `gorm:"default:0" json:"player2_score"`
	IsMars       bool      `gorm:"default:false" json:"is_mars"`
	
	// Game metadata
	GameMode      string     `gorm:"default:'ranked'" json:"game_mode"` // ranked, casual, tournament
	StartedAt     *time.Time `json:"started_at"`
	EndedAt       *time.Time `json:"ended_at"`
	DurationMs    int64      `gorm:"default:0" json:"duration_ms"`
	MoveCount     int        `gorm:"default:0" json:"move_count"`
	TrickCount    int        `gorm:"default:0" json:"trick_count"`
	
	// Rating changes
	Player1RatingChange int `gorm:"default:0" json:"player1_rating_change"`
	Player2RatingChange int `gorm:"default:0" json:"player2_rating_change"`
	
	// Relationships
	Player1 Player     `gorm:"foreignKey:Player1ID;constraint:OnUpdate:CASCADE,OnDelete:RESTRICT;" json:"player1,omitempty"`
	Player2 Player     `gorm:"foreignKey:Player2ID;constraint:OnUpdate:CASCADE,OnDelete:RESTRICT;" json:"player2,omitempty"`
	Winner  *Player    `gorm:"foreignKey:WinnerID;constraint:OnUpdate:CASCADE,OnDelete:SET NULL;" json:"winner,omitempty"`
	Moves   []GameMove `gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"moves,omitempty"`
}

// GameMove represents a single move in a game
type GameMove struct {
	BaseModel
	GameID         uuid.UUID `gorm:"type:uuid;not null" json:"game_id"`
	PlayerID       uuid.UUID `gorm:"type:uuid;not null" json:"player_id"`
	MoveNumber     int       `gorm:"not null" json:"move_number"`
	CardSuit       string    `gorm:"not null" json:"card_suit"`
	CardValue      int       `gorm:"not null" json:"card_value"`
	TableCardCount int       `gorm:"not null" json:"table_card_count"`
	TrickNumber    int       `gorm:"not null" json:"trick_number"`
	IsWinningMove  bool      `gorm:"default:false" json:"is_winning_move"`
	TimeTakenMs    int64     `gorm:"default:0" json:"time_taken_ms"`
	
	// Relationships
	Game   Game   `gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"game,omitempty"`
	Player Player `gorm:"foreignKey:PlayerID;constraint:OnUpdate:CASCADE,OnDelete:RESTRICT;" json:"player,omitempty"`
}

// Tournament represents a tournament structure
type Tournament struct {
	BaseModel
	Name        string    `gorm:"not null" json:"name"`
	Description string    `json:"description"`
	Type        string    `gorm:"not null" json:"type"` // single_elimination, double_elimination, round_robin
	Status      string    `gorm:"default:'registration'" json:"status"` // registration, in_progress, completed
	
	// Tournament settings
	MaxParticipants int       `gorm:"not null" json:"max_participants"`
	EntryFeeCoins   int       `gorm:"default:0" json:"entry_fee_coins"`
	EntryFeeGems    int       `gorm:"default:0" json:"entry_fee_gems"`
	
	// Prize pool
	PrizePoolCoins int `gorm:"default:0" json:"prize_pool_coins"`
	PrizePoolGems  int `gorm:"default:0" json:"prize_pool_gems"`
	
	// Timing
	RegistrationStart time.Time  `gorm:"not null" json:"registration_start"`
	RegistrationEnd   time.Time  `gorm:"not null" json:"registration_end"`
	TournamentStart   time.Time  `gorm:"not null" json:"tournament_start"`
	TournamentEnd     *time.Time `json:"tournament_end"`
	
	// Relationships
	Participants []TournamentParticipant `gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"participants,omitempty"`
}

// TournamentParticipant represents a player's participation in a tournament
type TournamentParticipant struct {
	BaseModel
	TournamentID uuid.UUID `gorm:"type:uuid;not null" json:"tournament_id"`
	PlayerID     uuid.UUID `gorm:"type:uuid;not null" json:"player_id"`
	
	// Tournament progress
	BracketPosition int  `json:"bracket_position"`
	IsEliminated    bool `gorm:"default:false" json:"is_eliminated"`
	FinalRank       *int `json:"final_rank"`
	
	// Prizes awarded
	PrizeCoins int `gorm:"default:0" json:"prize_coins"`
	PrizeGems  int `gorm:"default:0" json:"prize_gems"`
	
	// Relationships
	Tournament Tournament `gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"tournament,omitempty"`
	Player     Player     `gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"player,omitempty"`
}

// Friendship represents a friendship between two players
type Friendship struct {
	BaseModel
	RequesterID uuid.UUID `gorm:"type:uuid;not null" json:"requester_id"`
	AddresseeID uuid.UUID `gorm:"type:uuid;not null" json:"addressee_id"`
	Status      string    `gorm:"default:'pending'" json:"status"` // pending, accepted, blocked
	
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
	Type     string    `gorm:"default:'text'" json:"type"` // text, emote, system
	
	// Relationships
	Game   Game   `gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"game,omitempty"`
	Player Player `gorm:"foreignKey:PlayerID;constraint:OnUpdate:CASCADE,OnDelete:RESTRICT;" json:"player,omitempty"`
}

// BeforeCreate hook for all models to ensure UUID is set
func (base *BaseModel) BeforeCreate(tx *gorm.DB) error {
	if base.ID == uuid.Nil {
		base.ID = uuid.New()
	}
	return nil
}