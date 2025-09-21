package handlers

import (
	"net/http"
	"strconv"
	"time"

	"septica-backend/internal/database"
	"septica-backend/internal/rating"
	"septica-backend/internal/tournament"
	"septica-backend/pkg/logger"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

// TournamentHandlers handles tournament-related HTTP requests
type TournamentHandlers struct {
	tournamentService *tournament.Service
	ratingService     *rating.Service
	logger            *logger.Logger
}

// NewTournamentHandlers creates new tournament handlers
func NewTournamentHandlers(db *gorm.DB, logger *logger.Logger) *TournamentHandlers {
	return &TournamentHandlers{
		tournamentService: tournament.NewService(db, logger),
		ratingService:     rating.NewService(db, nil, logger),
		logger:            logger,
	}
}

// CreateTournament creates a new tournament
// POST /api/v1/tournaments
func (h *TournamentHandlers) CreateTournament(c *gin.Context) {
	var req tournament.CreateTournamentRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		h.logger.Warn("Invalid tournament creation request", "error", err)
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Invalid request format",
			"details": err.Error(),
		})
		return
	}

	// Validate creator player ID
	creatorID, err := uuid.Parse(c.GetHeader("X-Player-ID"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Invalid or missing player ID in header",
		})
		return
	}
	req.CreatorPlayerID = creatorID

	// Create tournament
	newTournament, err := h.tournamentService.CreateTournament(c.Request.Context(), &req)
	if err != nil {
		h.logger.Error("Failed to create tournament", "error", err, "creator", creatorID)
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Failed to create tournament",
			"details": err.Error(),
		})
		return
	}

	h.logger.Info("Tournament created successfully", 
		"tournament_id", newTournament.ID,
		"name", newTournament.Name,
		"creator", creatorID)

	c.JSON(http.StatusCreated, gin.H{
		"tournament": newTournament,
		"message":    "Tournament created successfully",
	})
}

// GetTournament gets a tournament by ID
// GET /api/v1/tournaments/:id
func (h *TournamentHandlers) GetTournament(c *gin.Context) {
	tournamentID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Invalid tournament ID",
		})
		return
	}

	// Check if detailed view is requested
	includeDetails := c.Query("details") == "true"

	tournament, err := h.tournamentService.GetTournament(c.Request.Context(), tournamentID, includeDetails)
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			c.JSON(http.StatusNotFound, gin.H{
				"error": "Tournament not found",
			})
			return
		}

		h.logger.Error("Failed to get tournament", "error", err, "tournament_id", tournamentID)
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to retrieve tournament",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"tournament": tournament,
	})
}

// ListTournaments lists tournaments with filtering
// GET /api/v1/tournaments
func (h *TournamentHandlers) ListTournaments(c *gin.Context) {
	filter := &tournament.TournamentFilter{}

	// Parse query parameters
	if status := c.Query("status"); status != "" {
		filter.Status = status
	}
	if tournamentType := c.Query("type"); tournamentType != "" {
		filter.Type = tournamentType
	}
	if ranked := c.Query("ranked"); ranked != "" {
		isRanked := ranked == "true"
		filter.IsRanked = &isRanked
	}
	if minRating := c.Query("min_rating"); minRating != "" {
		if rating, err := strconv.Atoi(minRating); err == nil {
			filter.MinRating = rating
		}
	}
	if maxRating := c.Query("max_rating"); maxRating != "" {
		if rating, err := strconv.Atoi(maxRating); err == nil {
			filter.MaxRating = rating
		}
	}
	
	filter.IncludePrivate = c.Query("include_private") == "true"
	filter.IncludeFull = c.Query("include_full") == "true"
	filter.OrderBy = c.DefaultQuery("order_by", "tournament_start")

	// Parse pagination
	if limit := c.Query("limit"); limit != "" {
		if l, err := strconv.Atoi(limit); err == nil && l > 0 {
			filter.Limit = l
		}
	}
	if offset := c.Query("offset"); offset != "" {
		if o, err := strconv.Atoi(offset); err == nil && o >= 0 {
			filter.Offset = o
		}
	}

	tournaments, err := h.tournamentService.ListTournaments(c.Request.Context(), filter)
	if err != nil {
		h.logger.Error("Failed to list tournaments", "error", err)
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to retrieve tournaments",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"tournaments": tournaments,
		"count":       len(tournaments),
		"filter":      filter,
	})
}

// JoinTournament allows a player to join a tournament
// POST /api/v1/tournaments/:id/join
func (h *TournamentHandlers) JoinTournament(c *gin.Context) {
	tournamentID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Invalid tournament ID",
		})
		return
	}

	playerID, err := uuid.Parse(c.GetHeader("X-Player-ID"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Invalid or missing player ID in header",
		})
		return
	}

	// Parse request body for invite code
	var req struct {
		InviteCode string `json:"invite_code"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		// Invite code is optional for public tournaments
		req.InviteCode = ""
	}

	// Join tournament
	if err := h.tournamentService.JoinTournament(c.Request.Context(), tournamentID, playerID, req.InviteCode); err != nil {
		h.logger.Warn("Failed to join tournament", 
			"error", err, 
			"tournament_id", tournamentID, 
			"player_id", playerID)

		// Return appropriate error code based on error type
		statusCode := http.StatusInternalServerError
		if err.Error() == "tournament not found" {
			statusCode = http.StatusNotFound
		} else if err.Error() == "tournament registration is closed" ||
			err.Error() == "tournament is full" ||
			err.Error() == "player already joined tournament" {
			statusCode = http.StatusBadRequest
		} else if err.Error() == "invalid invite code" {
			statusCode = http.StatusForbidden
		}

		c.JSON(statusCode, gin.H{
			"error": err.Error(),
		})
		return
	}

	h.logger.Info("Player joined tournament", 
		"tournament_id", tournamentID, 
		"player_id", playerID)

	c.JSON(http.StatusOK, gin.H{
		"message": "Successfully joined tournament",
	})
}

// StartTournament starts a tournament
// POST /api/v1/tournaments/:id/start
func (h *TournamentHandlers) StartTournament(c *gin.Context) {
	tournamentID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Invalid tournament ID",
		})
		return
	}

	// TODO: Add authorization check - only tournament creator or admin should be able to start
	
	if err := h.tournamentService.StartTournament(c.Request.Context(), tournamentID); err != nil {
		h.logger.Error("Failed to start tournament", "error", err, "tournament_id", tournamentID)

		statusCode := http.StatusInternalServerError
		if err.Error() == "tournament not found" {
			statusCode = http.StatusNotFound
		} else if err.Error() == "tournament is not in registration status" ||
			err.Error() == "not enough participants" {
			statusCode = http.StatusBadRequest
		}

		c.JSON(statusCode, gin.H{
			"error": err.Error(),
		})
		return
	}

	h.logger.Info("Tournament started", "tournament_id", tournamentID)

	c.JSON(http.StatusOK, gin.H{
		"message": "Tournament started successfully",
	})
}

// GetTournamentBracket gets tournament bracket information
// GET /api/v1/tournaments/:id/bracket
func (h *TournamentHandlers) GetTournamentBracket(c *gin.Context) {
	tournamentID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Invalid tournament ID",
		})
		return
	}

	// Get tournament with bracket details
	tournament, err := h.tournamentService.GetTournament(c.Request.Context(), tournamentID, true)
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			c.JSON(http.StatusNotFound, gin.H{
				"error": "Tournament not found",
			})
			return
		}

		h.logger.Error("Failed to get tournament bracket", "error", err, "tournament_id", tournamentID)
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to retrieve tournament bracket",
		})
		return
	}

	// Format bracket data based on tournament type
	bracketData := h.formatBracketData(tournament)

	c.JSON(http.StatusOK, gin.H{
		"tournament_id": tournamentID,
		"tournament_type": tournament.Type,
		"status": tournament.Status,
		"bracket": bracketData,
	})
}

// GetLeaderboard gets the player leaderboard
// GET /api/v1/leaderboard
func (h *TournamentHandlers) GetLeaderboard(c *gin.Context) {
	// Parse parameters
	limit := 50 // default
	if l := c.Query("limit"); l != "" {
		if parsed, err := strconv.Atoi(l); err == nil && parsed > 0 && parsed <= 200 {
			limit = parsed
		}
	}

	season := c.Query("season") // optional season filter

	leaderboard, err := h.ratingService.GetLeaderboard(c.Request.Context(), limit, season)
	if err != nil {
		h.logger.Error("Failed to get leaderboard", "error", err)
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to retrieve leaderboard",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"leaderboard": leaderboard,
		"limit":       limit,
		"season":      season,
		"updated_at":  time.Now(),
	})
}

// GetPlayerRatingHistory gets a player's rating history
// GET /api/v1/players/:id/rating-history
func (h *TournamentHandlers) GetPlayerRatingHistory(c *gin.Context) {
	playerID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Invalid player ID",
		})
		return
	}

	limit := 50 // default
	if l := c.Query("limit"); l != "" {
		if parsed, err := strconv.Atoi(l); err == nil && parsed > 0 && parsed <= 200 {
			limit = parsed
		}
	}

	history, err := h.ratingService.GetPlayerRatingHistory(c.Request.Context(), playerID, limit)
	if err != nil {
		h.logger.Error("Failed to get rating history", "error", err, "player_id", playerID)
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to retrieve rating history",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"player_id": playerID,
		"history":   history,
		"limit":     limit,
	})
}

// GetRatingDistribution gets rating distribution statistics
// GET /api/v1/rating-distribution
func (h *TournamentHandlers) GetRatingDistribution(c *gin.Context) {
	distribution, err := h.ratingService.GetRatingDistribution(c.Request.Context())
	if err != nil {
		h.logger.Error("Failed to get rating distribution", "error", err)
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to retrieve rating distribution",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"distribution": distribution,
		"updated_at":   time.Now(),
	})
}

// Helper methods

func (h *TournamentHandlers) formatBracketData(tournament *database.Tournament) interface{} {
	switch tournament.Type {
	case "single_elimination":
		return h.formatSingleEliminationBracket(tournament.Brackets)
	case "double_elimination":
		return h.formatDoubleEliminationBracket(tournament.Brackets)
	case "swiss_system":
		return h.formatSwissBracket(tournament.Brackets)
	case "round_robin":
		return h.formatRoundRobinBracket(tournament.Brackets)
	default:
		return tournament.Brackets
	}
}

func (h *TournamentHandlers) formatSingleEliminationBracket(brackets []database.TournamentBracket) map[string]interface{} {
	rounds := make(map[int][]database.TournamentBracket)
	maxRound := 0

	for _, bracket := range brackets {
		rounds[bracket.Round] = append(rounds[bracket.Round], bracket)
		if bracket.Round > maxRound {
			maxRound = bracket.Round
		}
	}

	return map[string]interface{}{
		"type":       "single_elimination",
		"rounds":     rounds,
		"max_round":  maxRound,
		"total_rounds": maxRound,
	}
}

func (h *TournamentHandlers) formatDoubleEliminationBracket(brackets []database.TournamentBracket) map[string]interface{} {
	winners := make(map[int][]database.TournamentBracket)
	losers := make(map[int][]database.TournamentBracket)

	for _, bracket := range brackets {
		if bracket.BracketType == "winners" {
			winners[bracket.Round] = append(winners[bracket.Round], bracket)
		} else if bracket.BracketType == "losers" {
			losers[bracket.Round] = append(losers[bracket.Round], bracket)
		}
	}

	return map[string]interface{}{
		"type":           "double_elimination",
		"winners_bracket": winners,
		"losers_bracket":  losers,
	}
}

func (h *TournamentHandlers) formatSwissBracket(brackets []database.TournamentBracket) map[string]interface{} {
	rounds := make(map[int][]database.TournamentBracket)
	maxRound := 0

	for _, bracket := range brackets {
		rounds[bracket.Round] = append(rounds[bracket.Round], bracket)
		if bracket.Round > maxRound {
			maxRound = bracket.Round
		}
	}

	return map[string]interface{}{
		"type":         "swiss_system",
		"rounds":       rounds,
		"current_round": maxRound,
	}
}

func (h *TournamentHandlers) formatRoundRobinBracket(brackets []database.TournamentBracket) map[string]interface{} {
	rounds := make(map[int][]database.TournamentBracket)
	maxRound := 0

	for _, bracket := range brackets {
		rounds[bracket.Round] = append(rounds[bracket.Round], bracket)
		if bracket.Round > maxRound {
			maxRound = bracket.Round
		}
	}

	return map[string]interface{}{
		"type":         "round_robin",
		"rounds":       rounds,
		"total_rounds": maxRound,
	}
}

// RegisterTournamentRoutes registers all tournament routes
func RegisterTournamentRoutes(router *gin.RouterGroup, db *gorm.DB, logger *logger.Logger) {
	handlers := NewTournamentHandlers(db, logger)

	// Tournament management
	router.POST("/tournaments", handlers.CreateTournament)
	router.GET("/tournaments", handlers.ListTournaments)
	router.GET("/tournaments/:id", handlers.GetTournament)
	router.POST("/tournaments/:id/join", handlers.JoinTournament)
	router.POST("/tournaments/:id/start", handlers.StartTournament)
	router.GET("/tournaments/:id/bracket", handlers.GetTournamentBracket)

	// Rating and leaderboards
	router.GET("/leaderboard", handlers.GetLeaderboard)
	router.GET("/players/:id/rating-history", handlers.GetPlayerRatingHistory)
	router.GET("/rating-distribution", handlers.GetRatingDistribution)
}