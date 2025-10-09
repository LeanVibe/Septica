package tournament

import (
	"fmt"
	"math"
	"sort"

	"septica-backend/internal/database"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// BracketGenerator handles tournament bracket generation
type BracketGenerator struct {
	db *gorm.DB
}

// NewBracketGenerator creates a new bracket generator
func NewBracketGenerator(db *gorm.DB) *BracketGenerator {
	return &BracketGenerator{db: db}
}

// SingleEliminationBrackets generates single elimination tournament brackets
func (s *Service) generateSingleEliminationBrackets(tx *gorm.DB, tournament *database.Tournament) error {
	// Get participants sorted by seed
	participants, err := s.getSeededParticipants(tx, tournament.ID)
	if err != nil {
		return fmt.Errorf("failed to get participants: %w", err)
	}

	participantCount := len(participants)
	if participantCount < 2 {
		return fmt.Errorf("need at least 2 participants for elimination tournament")
	}

	// Calculate number of rounds needed
	totalRounds := int(math.Ceil(math.Log2(float64(participantCount))))

	// Calculate first round size (might need byes)
	firstRoundSize := int(math.Pow(2, float64(totalRounds)))
	byeCount := firstRoundSize - participantCount

	// Generate brackets for each round
	return s.generateEliminationRounds(tx, tournament, participants, totalRounds, byeCount)
}

// DoubleEliminationBrackets generates double elimination tournament brackets
func (s *Service) generateDoubleEliminationBrackets(tx *gorm.DB, tournament *database.Tournament) error {
	participants, err := s.getSeededParticipants(tx, tournament.ID)
	if err != nil {
		return fmt.Errorf("failed to get participants: %w", err)
	}

	participantCount := len(participants)
	if participantCount < 2 {
		return fmt.Errorf("need at least 2 participants for elimination tournament")
	}

	// Generate winners bracket (same as single elimination)
	totalRounds := int(math.Ceil(math.Log2(float64(participantCount))))
	firstRoundSize := int(math.Pow(2, float64(totalRounds)))
	byeCount := firstRoundSize - participantCount

	// Create winners bracket
	if err := s.generateWinnersBracket(tx, tournament, participants, totalRounds, byeCount); err != nil {
		return fmt.Errorf("failed to generate winners bracket: %w", err)
	}

	// Create losers bracket structure
	if err := s.generateLosersBracket(tx, tournament, totalRounds); err != nil {
		return fmt.Errorf("failed to generate losers bracket: %w", err)
	}

	return nil
}

// SwissSystemPairings generates Swiss system tournament pairings
func (s *Service) generateSwissSystemPairings(tx *gorm.DB, tournament *database.Tournament, round int) error {
	participants, err := s.getSwissParticipants(tx, tournament.ID)
	if err != nil {
		return fmt.Errorf("failed to get participants: %w", err)
	}

	if len(participants) < 2 {
		return fmt.Errorf("need at least 2 participants for Swiss system")
	}

	// Sort participants by Swiss points, then by rating
	sort.Slice(participants, func(i, j int) bool {
		if participants[i].SwissPoints != participants[j].SwissPoints {
			return participants[i].SwissPoints > participants[j].SwissPoints
		}
		return participants[i].Player.Rating > participants[j].Player.Rating
	})

	// Generate pairings for this round
	pairings, err := s.generateSwissPairings(tx, participants, round)
	if err != nil {
		return fmt.Errorf("failed to generate Swiss pairings: %w", err)
	}

	// Create bracket entries for pairings
	for i, pairing := range pairings {
		bracket := &database.TournamentBracket{
			TournamentID: tournament.ID,
			BracketType:  "swiss",
			Round:        round,
			Position:     i + 1,
			Player1ID:    pairing.Player1ID,
			Player2ID:    pairing.Player2ID,
			IsBye:        pairing.IsBye,
		}

		if err := tx.Create(bracket).Error; err != nil {
			return fmt.Errorf("failed to create Swiss bracket: %w", err)
		}
	}

	return nil
}

// RoundRobinSchedule generates round robin tournament schedule
func (s *Service) generateRoundRobinSchedule(tx *gorm.DB, tournament *database.Tournament) error {
	participants, err := s.getSeededParticipants(tx, tournament.ID)
	if err != nil {
		return fmt.Errorf("failed to get participants: %w", err)
	}

	participantCount := len(participants)
	if participantCount < 3 {
		return fmt.Errorf("need at least 3 participants for round robin")
	}

	// Generate all possible pairings
	var allPairings []SwissPairing
	for i := 0; i < participantCount; i++ {
		for j := i + 1; j < participantCount; j++ {
			allPairings = append(allPairings, SwissPairing{
				Player1ID: &participants[i].PlayerID,
				Player2ID: &participants[j].PlayerID,
			})
		}
	}

	// Distribute pairings across rounds to minimize conflicts
	rounds := s.distributeRoundRobinPairings(allPairings, participantCount)

	// Create bracket entries
	for roundNum, roundPairings := range rounds {
		for pos, pairing := range roundPairings {
			bracket := &database.TournamentBracket{
				TournamentID: tournament.ID,
				BracketType:  "round_robin",
				Round:        roundNum + 1,
				Position:     pos + 1,
				Player1ID:    pairing.Player1ID,
				Player2ID:    pairing.Player2ID,
			}

			if err := tx.Create(bracket).Error; err != nil {
				return fmt.Errorf("failed to create round robin bracket: %w", err)
			}
		}
	}

	return nil
}

// Helper methods

func (s *Service) getSeededParticipants(tx *gorm.DB, tournamentID uuid.UUID) ([]database.TournamentParticipant, error) {
	var participants []database.TournamentParticipant
	err := tx.Preload("Player").
		Where("tournament_id = ?", tournamentID).
		Order("seed_position ASC").
		Find(&participants).Error
	return participants, err
}

func (s *Service) getSwissParticipants(tx *gorm.DB, tournamentID uuid.UUID) ([]database.TournamentParticipant, error) {
	var participants []database.TournamentParticipant
	err := tx.Preload("Player").
		Where("tournament_id = ? AND is_eliminated = false", tournamentID).
		Find(&participants).Error
	return participants, err
}

func (s *Service) generateEliminationRounds(tx *gorm.DB, tournament *database.Tournament, participants []database.TournamentParticipant, totalRounds, byeCount int) error {
	currentRoundPlayers := make([]*uuid.UUID, len(participants))
	for i, p := range participants {
		currentRoundPlayers[i] = &p.PlayerID
	}

	// Add byes to first round
	for i := 0; i < byeCount; i++ {
		currentRoundPlayers = append(currentRoundPlayers, nil)
	}

	// Generate each round
	for round := 1; round <= totalRounds; round++ {
		roundSize := len(currentRoundPlayers) / 2
		nextRoundPlayers := make([]*uuid.UUID, roundSize)

		for i := 0; i < roundSize; i++ {
			player1Idx := i * 2
			player2Idx := i*2 + 1

			var player1ID, player2ID *uuid.UUID
			var isBye bool

			if player1Idx < len(currentRoundPlayers) {
				player1ID = currentRoundPlayers[player1Idx]
			}
			if player2Idx < len(currentRoundPlayers) {
				player2ID = currentRoundPlayers[player2Idx]
			}

			// Handle byes
			if player1ID == nil && player2ID != nil {
				nextRoundPlayers[i] = player2ID
				isBye = true
			} else if player2ID == nil && player1ID != nil {
				nextRoundPlayers[i] = player1ID
				isBye = true
			} else if player1ID != nil && player2ID != nil {
				// Normal match - winner advances (will be determined later)
				nextRoundPlayers[i] = nil // TBD
			}

			// Create bracket entry
			bracket := &database.TournamentBracket{
				TournamentID: tournament.ID,
				BracketType:  "winners",
				Round:        round,
				Position:     i + 1,
				Player1ID:    player1ID,
				Player2ID:    player2ID,
				IsBye:        isBye,
			}

			if isBye {
				bracket.WinnerID = nextRoundPlayers[i]
				bracket.IsComplete = true
			}

			if err := tx.Create(bracket).Error; err != nil {
				return fmt.Errorf("failed to create elimination bracket: %w", err)
			}
		}

		currentRoundPlayers = nextRoundPlayers
	}

	return nil
}

func (s *Service) generateWinnersBracket(tx *gorm.DB, tournament *database.Tournament, participants []database.TournamentParticipant, totalRounds, byeCount int) error {
	// Same as single elimination
	return s.generateEliminationRounds(tx, tournament, participants, totalRounds, byeCount)
}

func (s *Service) generateLosersBracket(tx *gorm.DB, tournament *database.Tournament, winnersRounds int) error {
	// Losers bracket has 2 * winnersRounds - 1 rounds
	losersRounds := 2*winnersRounds - 1

	// Create placeholder brackets for losers bracket
	// Players will be fed from winners bracket as they lose
	for round := 1; round <= losersRounds; round++ {
		// Calculate positions for this round
		var positions int
		if round <= winnersRounds {
			// Early rounds: fed from winners bracket
			positions = int(math.Pow(2, float64(winnersRounds-round)))
		} else {
			// Later rounds: internal losers bracket elimination
			roundsFromEnd := losersRounds - round
			positions = int(math.Pow(2, float64(roundsFromEnd)))
		}

		// Create bracket entries
		for pos := 1; pos <= positions; pos++ {
			bracket := &database.TournamentBracket{
				TournamentID: tournament.ID,
				BracketType:  "losers",
				Round:        round,
				Position:     pos,
				// Players will be populated as they lose from winners bracket
			}

			if err := tx.Create(bracket).Error; err != nil {
				return fmt.Errorf("failed to create losers bracket: %w", err)
			}
		}
	}

	return nil
}

func (s *Service) generateSwissPairings(tx *gorm.DB, participants []database.TournamentParticipant, round int) ([]SwissPairing, error) {
	var pairings []SwissPairing
	used := make(map[uuid.UUID]bool)

	// Get previous pairings to avoid repeats
	previousPairings, err := s.getPreviousPairings(tx, participants[0].TournamentID, participants)
	if err != nil {
		return nil, fmt.Errorf("failed to get previous pairings: %w", err)
	}

	// Pair players with similar points
	for i := 0; i < len(participants); i++ {
		if used[participants[i].PlayerID] {
			continue
		}

		player1 := participants[i]
		var player2 *database.TournamentParticipant

		// Find best opponent with same points
		for j := i + 1; j < len(participants); j++ {
			if used[participants[j].PlayerID] {
				continue
			}

			candidate := participants[j]

			// Check if they've played before
			if s.havePlayedBefore(player1.PlayerID, candidate.PlayerID, previousPairings) {
				continue
			}

			// Prefer same point total
			if player1.SwissPoints == candidate.SwissPoints {
				player2 = &candidate
				break
			}

			// If no same-points opponent, accept any available
			if player2 == nil {
				player2 = &candidate
			}
		}

		if player2 != nil {
			// Create pairing
			pairings = append(pairings, SwissPairing{
				Player1ID: &player1.PlayerID,
				Player2ID: &player2.PlayerID,
			})
			used[player1.PlayerID] = true
			used[player2.PlayerID] = true
		} else {
			// Bye round
			pairings = append(pairings, SwissPairing{
				Player1ID: &player1.PlayerID,
				IsBye:     true,
			})
			used[player1.PlayerID] = true
		}
	}

	return pairings, nil
}

func (s *Service) getPreviousPairings(tx *gorm.DB, tournamentID uuid.UUID, participants []database.TournamentParticipant) (map[string]bool, error) {
	pairings := make(map[string]bool)

	// Get all previous games in this tournament
	var games []database.Game
	err := tx.Where("tournament_id = ?", tournamentID).Find(&games).Error
	if err != nil {
		return pairings, err
	}

	// Record all previous pairings
	for _, game := range games {
		key1 := fmt.Sprintf("%s-%s", game.Player1ID, game.Player2ID)
		key2 := fmt.Sprintf("%s-%s", game.Player2ID, game.Player1ID)
		pairings[key1] = true
		pairings[key2] = true
	}

	return pairings, nil
}

func (s *Service) havePlayedBefore(player1ID, player2ID uuid.UUID, previousPairings map[string]bool) bool {
	key := fmt.Sprintf("%s-%s", player1ID, player2ID)
	return previousPairings[key]
}

func (s *Service) distributeRoundRobinPairings(allPairings []SwissPairing, participantCount int) [][]SwissPairing {
	// For round robin, each player plays each other player exactly once
	// We need to distribute these games across multiple rounds such that
	// no player plays more than one game per round

	totalRounds := participantCount - 1
	if participantCount%2 == 0 {
		totalRounds = participantCount - 1
	} else {
		totalRounds = participantCount // Odd number needs extra round for byes
	}

	rounds := make([][]SwissPairing, totalRounds)
	used := make([]map[uuid.UUID]bool, totalRounds)
	for i := range used {
		used[i] = make(map[uuid.UUID]bool)
	}

	// Distribute pairings
	for _, pairing := range allPairings {
		// Find earliest round where both players are free
		for roundIdx := 0; roundIdx < totalRounds; roundIdx++ {
			if !used[roundIdx][*pairing.Player1ID] && !used[roundIdx][*pairing.Player2ID] {
				rounds[roundIdx] = append(rounds[roundIdx], pairing)
				used[roundIdx][*pairing.Player1ID] = true
				used[roundIdx][*pairing.Player2ID] = true
				break
			}
		}
	}

	return rounds
}

// SwissPairing represents a pairing in Swiss system
type SwissPairing struct {
	Player1ID *uuid.UUID
	Player2ID *uuid.UUID
	IsBye     bool
}
