package tournament

import (
	"context"
	"fmt"
	"math/rand"
	"time"

	"septica-backend/internal/database"
	"septica-backend/pkg/logger"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// Service provides tournament management operations
type Service struct {
	db     *gorm.DB
	logger *logger.Logger
}

// NewService creates a new tournament service
func NewService(db *gorm.DB, logger *logger.Logger) *Service {
	return &Service{
		db:     db,
		logger: logger,
	}
}

// CreateTournamentRequest represents a tournament creation request
type CreateTournamentRequest struct {
	Name                    string    `json:"name" binding:"required,min=3,max=100"`
	Description             string    `json:"description" binding:"max=500"`
	Type                    string    `json:"type" binding:"required,oneof=single_elimination double_elimination swiss_system round_robin"`
	MaxParticipants         int       `json:"max_participants" binding:"required,min=2,max=256"`
	MinParticipants         int       `json:"min_participants" binding:"min=2"`
	EntryFeeCoins           int       `json:"entry_fee_coins" binding:"min=0"`
	EntryFeeGems            int       `json:"entry_fee_gems" binding:"min=0"`
	IsRankedTournament      bool      `json:"is_ranked_tournament"`
	PrizePoolCoins          int       `json:"prize_pool_coins" binding:"min=0"`
	PrizePoolGems           int       `json:"prize_pool_gems" binding:"min=0"`
	PrizeDistributionType   string    `json:"prize_distribution_type" binding:"oneof=percentage fixed winner_takes_all"`
	FirstPlacePrizePercent  int       `json:"first_place_prize_percent" binding:"min=0,max=100"`
	SecondPlacePrizePercent int       `json:"second_place_prize_percent" binding:"min=0,max=100"`
	ThirdPlacePrizePercent  int       `json:"third_place_prize_percent" binding:"min=0,max=100"`
	SwissRounds             int       `json:"swiss_rounds" binding:"min=0"`
	SwissPointsToWin        int       `json:"swiss_points_to_win" binding:"min=1"`
	MinRatingRequired       int       `json:"min_rating_required" binding:"min=0"`
	MaxRatingAllowed        int       `json:"max_rating_allowed" binding:"min=0"`
	RegistrationStart       time.Time `json:"registration_start" binding:"required"`
	RegistrationEnd         time.Time `json:"registration_end" binding:"required"`
	TournamentStart         time.Time `json:"tournament_start" binding:"required"`
	IsPrivate               bool      `json:"is_private"`
	CreatorPlayerID         uuid.UUID `json:"creator_player_id" binding:"required"`
}

// CreateTournament creates a new tournament
func (s *Service) CreateTournament(ctx context.Context, req *CreateTournamentRequest) (*database.Tournament, error) {
	// Validate request
	if err := s.validateCreateTournamentRequest(req); err != nil {
		return nil, fmt.Errorf("validation failed: %w", err)
	}

	// Generate invite code for private tournaments
	var inviteCode string
	if req.IsPrivate {
		inviteCode = s.generateInviteCode()
	}

	// Create tournament
	tournament := &database.Tournament{
		Name:                    req.Name,
		Description:             req.Description,
		Type:                    req.Type,
		Status:                  "registration",
		MaxParticipants:         req.MaxParticipants,
		MinParticipants:         req.MinParticipants,
		EntryFeeCoins:           req.EntryFeeCoins,
		EntryFeeGems:            req.EntryFeeGems,
		IsRankedTournament:      req.IsRankedTournament,
		PrizePoolCoins:          req.PrizePoolCoins,
		PrizePoolGems:           req.PrizePoolGems,
		PrizeDistributionType:   req.PrizeDistributionType,
		FirstPlacePrizePercent:  req.FirstPlacePrizePercent,
		SecondPlacePrizePercent: req.SecondPlacePrizePercent,
		ThirdPlacePrizePercent:  req.ThirdPlacePrizePercent,
		SwissRounds:             req.SwissRounds,
		SwissPointsToWin:        req.SwissPointsToWin,
		MinRatingRequired:       req.MinRatingRequired,
		MaxRatingAllowed:        req.MaxRatingAllowed,
		RegistrationStart:       req.RegistrationStart,
		RegistrationEnd:         req.RegistrationEnd,
		TournamentStart:         req.TournamentStart,
		CreatorPlayerID:         req.CreatorPlayerID,
		IsPrivate:               req.IsPrivate,
		InviteCode:              inviteCode,
	}

	// Set default Swiss rounds if not specified
	if req.Type == "swiss_system" && req.SwissRounds == 0 {
		tournament.SwissRounds = s.calculateOptimalSwissRounds(req.MaxParticipants)
	}

	if err := s.db.WithContext(ctx).Create(tournament).Error; err != nil {
		return nil, fmt.Errorf("failed to create tournament: %w", err)
	}

	s.logger.Info("Tournament created",
		"tournament_id", tournament.ID,
		"name", tournament.Name,
		"type", tournament.Type,
		"creator", req.CreatorPlayerID,
	)

	return tournament, nil
}

// JoinTournament allows a player to join a tournament
func (s *Service) JoinTournament(ctx context.Context, tournamentID, playerID uuid.UUID, inviteCode string) error {
	tx := s.db.WithContext(ctx).Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	// Get tournament
	var tournament database.Tournament
	if err := tx.First(&tournament, tournamentID).Error; err != nil {
		tx.Rollback()
		return fmt.Errorf("tournament not found: %w", err)
	}

	// Validate join conditions
	if err := s.validateTournamentJoin(&tournament, playerID, inviteCode); err != nil {
		tx.Rollback()
		return err
	}

	// Get player info
	var player database.Player
	if err := tx.First(&player, playerID).Error; err != nil {
		tx.Rollback()
		return fmt.Errorf("player not found: %w", err)
	}

	// Check rating requirements
	if tournament.MinRatingRequired > 0 && player.Rating < tournament.MinRatingRequired {
		tx.Rollback()
		return fmt.Errorf("player rating too low: %d < %d", player.Rating, tournament.MinRatingRequired)
	}
	if tournament.MaxRatingAllowed > 0 && player.Rating > tournament.MaxRatingAllowed {
		tx.Rollback()
		return fmt.Errorf("player rating too high: %d > %d", player.Rating, tournament.MaxRatingAllowed)
	}

	// Check if player already joined
	var existingParticipant database.TournamentParticipant
	err := tx.Where("tournament_id = ? AND player_id = ?", tournamentID, playerID).First(&existingParticipant).Error
	if err == nil {
		tx.Rollback()
		return fmt.Errorf("player already joined tournament")
	} else if err != gorm.ErrRecordNotFound {
		tx.Rollback()
		return fmt.Errorf("failed to check existing participation: %w", err)
	}

	// Check entry fees and deduct if necessary
	if tournament.EntryFeeCoins > 0 && player.Coins < tournament.EntryFeeCoins {
		tx.Rollback()
		return fmt.Errorf("insufficient coins: need %d, have %d", tournament.EntryFeeCoins, player.Coins)
	}
	if tournament.EntryFeeGems > 0 && player.Gems < tournament.EntryFeeGems {
		tx.Rollback()
		return fmt.Errorf("insufficient gems: need %d, have %d", tournament.EntryFeeGems, player.Gems)
	}

	// Deduct entry fees
	if tournament.EntryFeeCoins > 0 || tournament.EntryFeeGems > 0 {
		player.Coins -= tournament.EntryFeeCoins
		player.Gems -= tournament.EntryFeeGems
		if err := tx.Save(&player).Error; err != nil {
			tx.Rollback()
			return fmt.Errorf("failed to deduct entry fees: %w", err)
		}

		// Add to prize pool
		tournament.PrizePoolCoins += tournament.EntryFeeCoins
		tournament.PrizePoolGems += tournament.EntryFeeGems
		if err := tx.Save(&tournament).Error; err != nil {
			tx.Rollback()
			return fmt.Errorf("failed to update prize pool: %w", err)
		}
	}

	// Create participant record
	participant := &database.TournamentParticipant{
		TournamentID:   tournamentID,
		PlayerID:       playerID,
		StartingRating: player.Rating,
	}

	if err := tx.Create(participant).Error; err != nil {
		tx.Rollback()
		return fmt.Errorf("failed to create participant record: %w", err)
	}

	if err := tx.Commit().Error; err != nil {
		return fmt.Errorf("failed to commit join transaction: %w", err)
	}

	s.logger.Info("Player joined tournament",
		"tournament_id", tournamentID,
		"player_id", playerID,
		"player_rating", player.Rating,
	)

	return nil
}

// StartTournament starts a tournament
func (s *Service) StartTournament(ctx context.Context, tournamentID uuid.UUID) error {
	tx := s.db.WithContext(ctx).Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	// Get tournament with participants
	var tournament database.Tournament
	if err := tx.Preload("Participants").First(&tournament, tournamentID).Error; err != nil {
		tx.Rollback()
		return fmt.Errorf("tournament not found: %w", err)
	}

	// Validate start conditions
	if tournament.Status != "registration" {
		tx.Rollback()
		return fmt.Errorf("tournament is not in registration status")
	}

	participantCount := len(tournament.Participants)
	if participantCount < tournament.MinParticipants {
		tx.Rollback()
		return fmt.Errorf("not enough participants: %d < %d", participantCount, tournament.MinParticipants)
	}

	// Generate seeding
	if err := s.generateSeeding(tx, &tournament); err != nil {
		tx.Rollback()
		return fmt.Errorf("failed to generate seeding: %w", err)
	}

	// Create brackets based on tournament type
	if err := s.generateBrackets(tx, &tournament); err != nil {
		tx.Rollback()
		return fmt.Errorf("failed to generate brackets: %w", err)
	}

	// Update tournament status
	tournament.Status = "in_progress"
	now := time.Now()
	tournament.TournamentStart = now
	if err := tx.Save(&tournament).Error; err != nil {
		tx.Rollback()
		return fmt.Errorf("failed to update tournament status: %w", err)
	}

	if err := tx.Commit().Error; err != nil {
		return fmt.Errorf("failed to commit tournament start: %w", err)
	}

	s.logger.Info("Tournament started",
		"tournament_id", tournamentID,
		"participants", participantCount,
		"type", tournament.Type,
	)

	return nil
}

// GetTournament gets a tournament by ID
func (s *Service) GetTournament(ctx context.Context, tournamentID uuid.UUID, includeDetails bool) (*database.Tournament, error) {
	query := s.db.WithContext(ctx)

	if includeDetails {
		query = query.Preload("Creator").
			Preload("Participants").
			Preload("Participants.Player").
			Preload("Brackets").
			Preload("Games")
	}

	var tournament database.Tournament
	if err := query.First(&tournament, tournamentID).Error; err != nil {
		return nil, fmt.Errorf("tournament not found: %w", err)
	}

	return &tournament, nil
}

// ListTournaments lists tournaments with filtering
func (s *Service) ListTournaments(ctx context.Context, filter *TournamentFilter) ([]database.Tournament, error) {
	query := s.db.WithContext(ctx).Preload("Creator")

	// Apply filters
	if filter.Status != "" {
		query = query.Where("status = ?", filter.Status)
	}
	if filter.Type != "" {
		query = query.Where("type = ?", filter.Type)
	}
	if filter.IsRanked != nil {
		query = query.Where("is_ranked_tournament = ?", *filter.IsRanked)
	}
	if filter.MinRating > 0 {
		query = query.Where("min_rating_required <= ?", filter.MinRating)
	}
	if filter.MaxRating > 0 {
		query = query.Where("max_rating_allowed >= ? OR max_rating_allowed = 0", filter.MaxRating)
	}
	if !filter.IncludePrivate {
		query = query.Where("is_private = false")
	}
	if !filter.IncludeFull {
		// Subquery to exclude full tournaments
		query = query.Where(`
			(SELECT COUNT(*) FROM tournament_participants 
			 WHERE tournament_id = tournaments.id) < max_participants
		`)
	}

	// Apply ordering
	switch filter.OrderBy {
	case "created_at":
		query = query.Order("created_at DESC")
	case "tournament_start":
		query = query.Order("tournament_start ASC")
	case "prize_pool":
		query = query.Order("(prize_pool_coins + prize_pool_gems) DESC")
	default:
		query = query.Order("tournament_start ASC, created_at DESC")
	}

	// Apply pagination
	if filter.Limit > 0 {
		query = query.Limit(filter.Limit)
	}
	if filter.Offset > 0 {
		query = query.Offset(filter.Offset)
	}

	var tournaments []database.Tournament
	if err := query.Find(&tournaments).Error; err != nil {
		return nil, fmt.Errorf("failed to list tournaments: %w", err)
	}

	return tournaments, nil
}

// Helper methods

func (s *Service) validateCreateTournamentRequest(req *CreateTournamentRequest) error {
	// Validate time sequence
	if req.RegistrationEnd.Before(req.RegistrationStart) {
		return fmt.Errorf("registration end must be after registration start")
	}
	if req.TournamentStart.Before(req.RegistrationEnd) {
		return fmt.Errorf("tournament start must be after registration end")
	}

	// Validate participant limits
	if req.MinParticipants > req.MaxParticipants {
		return fmt.Errorf("min participants cannot exceed max participants")
	}

	// Validate prize distribution
	if req.PrizeDistributionType == "percentage" {
		total := req.FirstPlacePrizePercent + req.SecondPlacePrizePercent + req.ThirdPlacePrizePercent
		if total > 100 {
			return fmt.Errorf("prize percentages cannot exceed 100%%")
		}
	}

	// Validate Swiss system parameters
	if req.Type == "swiss_system" {
		if req.SwissRounds == 0 {
			req.SwissRounds = s.calculateOptimalSwissRounds(req.MaxParticipants)
		}
		if req.SwissPointsToWin == 0 {
			req.SwissPointsToWin = 3
		}
	}

	// Validate rating requirements
	if req.MinRatingRequired > 0 && req.MaxRatingAllowed > 0 {
		if req.MinRatingRequired >= req.MaxRatingAllowed {
			return fmt.Errorf("min rating must be less than max rating")
		}
	}

	return nil
}

func (s *Service) validateTournamentJoin(tournament *database.Tournament, playerID uuid.UUID, inviteCode string) error {
	// Check tournament status
	if tournament.Status != "registration" {
		return fmt.Errorf("tournament registration is closed")
	}

	// Check registration period
	now := time.Now()
	if now.Before(tournament.RegistrationStart) {
		return fmt.Errorf("registration has not started yet")
	}
	if now.After(tournament.RegistrationEnd) {
		return fmt.Errorf("registration has ended")
	}

	// Check private tournament invite code
	if tournament.IsPrivate {
		if inviteCode == "" {
			return fmt.Errorf("invite code required for private tournament")
		}
		if inviteCode != tournament.InviteCode {
			return fmt.Errorf("invalid invite code")
		}
	}

	// Check participant count (will be checked again in transaction)
	var participantCount int64
	if err := s.db.Model(&database.TournamentParticipant{}).
		Where("tournament_id = ?", tournament.ID).
		Count(&participantCount).Error; err != nil {
		return fmt.Errorf("failed to check participant count: %w", err)
	}

	if int(participantCount) >= tournament.MaxParticipants {
		return fmt.Errorf("tournament is full")
	}

	return nil
}

func (s *Service) generateInviteCode() string {
	const charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	const length = 8

	b := make([]byte, length)
	for i := range b {
		b[i] = charset[rand.Intn(len(charset))]
	}
	return string(b)
}

func (s *Service) calculateOptimalSwissRounds(maxParticipants int) int {
	// Rule of thumb: log2(participants) + 1
	if maxParticipants <= 4 {
		return 3
	}
	if maxParticipants <= 8 {
		return 4
	}
	if maxParticipants <= 16 {
		return 5
	}
	if maxParticipants <= 32 {
		return 6
	}
	if maxParticipants <= 64 {
		return 7
	}
	return 8
}

func (s *Service) generateSeeding(tx *gorm.DB, tournament *database.Tournament) error {
	// Get all participants with their ratings
	var participants []database.TournamentParticipant
	if err := tx.Preload("Player").
		Where("tournament_id = ?", tournament.ID).
		Find(&participants).Error; err != nil {
		return fmt.Errorf("failed to get participants: %w", err)
	}

	// Sort by rating (highest first) for seeding
	for i := 0; i < len(participants)-1; i++ {
		for j := i + 1; j < len(participants); j++ {
			if participants[i].Player.Rating < participants[j].Player.Rating {
				participants[i], participants[j] = participants[j], participants[i]
			}
		}
	}

	// Assign seed positions
	for i, participant := range participants {
		participant.SeedPosition = i + 1
		if err := tx.Save(&participant).Error; err != nil {
			return fmt.Errorf("failed to update participant seed: %w", err)
		}
	}

	return nil
}

func (s *Service) generateBrackets(tx *gorm.DB, tournament *database.Tournament) error {
	switch tournament.Type {
	case "single_elimination":
		return s.generateSingleEliminationBrackets(tx, tournament)
	case "double_elimination":
		return s.generateDoubleEliminationBrackets(tx, tournament)
	case "swiss_system":
		return s.generateSwissSystemPairings(tx, tournament, 1) // First round
	case "round_robin":
		return s.generateRoundRobinSchedule(tx, tournament)
	default:
		return fmt.Errorf("unsupported tournament type: %s", tournament.Type)
	}
}

// Bracket generation methods are implemented in brackets.go

// TournamentFilter represents filtering options for tournament listing
type TournamentFilter struct {
	Status         string `json:"status"`         // registration, in_progress, completed
	Type           string `json:"type"`           // single_elimination, etc.
	IsRanked       *bool  `json:"is_ranked"`      // filter by ranked status
	MinRating      int    `json:"min_rating"`     // player's rating for eligibility
	MaxRating      int    `json:"max_rating"`     // player's rating for eligibility
	IncludePrivate bool   `json:"include_private"`
	IncludeFull    bool   `json:"include_full"`
	OrderBy        string `json:"order_by"`       // created_at, tournament_start, prize_pool
	Limit          int    `json:"limit"`
	Offset         int    `json:"offset"`
}