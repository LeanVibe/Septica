package ai

import (
	"fmt"
	"sync"
	"time"

	"septica-backend/internal/database"
	"septica-backend/internal/metrics"
	"septica-backend/internal/websocket"
	"septica-backend/pkg/logger"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// QueueStats represents statistics about a matchmaking queue
type QueueStats struct {
	TotalPlayers    int              `json:"total_players"`
	LongestWaitTime time.Duration    `json:"longest_wait_time"`
	AverageWaitTime time.Duration    `json:"average_wait_time"`
	PlayersWaiting  []PlayerWaitInfo `json:"players_waiting"`
}

// PlayerWaitInfo represents a player waiting in queue
type PlayerWaitInfo struct {
	PlayerID uuid.UUID     `json:"player_id"`
	Rating   int           `json:"rating"`
	WaitTime time.Duration `json:"wait_time"`
}

// AIMatchmakingConfig holds configuration for AI matchmaking integration
type AIMatchmakingConfig struct {
	Enabled                bool               `json:"enabled"`                 // Enable/disable AI matchmaking
	ActivationTimeout      time.Duration      `json:"activation_timeout"`      // 30-40 seconds
	MaxConcurrentAI        int                `json:"max_concurrent_ai"`       // Max AI players active at once
	DifficultyDistribution map[string]float64 `json:"difficulty_distribution"` // % of each difficulty
	RatingRange            struct {
		Min int `json:"min"`
		Max int `json:"max"`
	} `json:"rating_range"`
}

// DefaultAIMatchmakingConfig returns default AI matchmaking configuration
func DefaultAIMatchmakingConfig() *AIMatchmakingConfig {
	config := &AIMatchmakingConfig{
		Enabled:           true,
		ActivationTimeout: 10 * time.Second, // 10 seconds for testing
		MaxConcurrentAI:   10,               // Allow up to 10 AI players
		DifficultyDistribution: map[string]float64{
			"easy":   0.4, // 40% easy AI
			"medium": 0.4, // 40% medium AI
			"hard":   0.2, // 20% hard AI
		},
	}
	config.RatingRange.Min = 800
	config.RatingRange.Max = 1600

	return config
}

// AIMatchmakingManager handles AI player integration with matchmaking
type AIMatchmakingManager struct {
	config *AIMatchmakingConfig `json:"config"`
	hub    *websocket.Hub       `json:"-"`
	db     *gorm.DB             `json:"-"`
	logger *logger.Logger       `json:"-"`

	// Active AI players
	activeAI map[uuid.UUID]*AIWebSocketClient `json:"-"`
	aiMutex  sync.RWMutex                     `json:"-"`

	// Monitoring
	queueMonitorTicker *time.Ticker `json:"-"`
	stopChan           chan bool    `json:"-"`
	isRunning          bool         `json:"is_running"`
}

// NewAIMatchmakingManager creates a new AI matchmaking manager
func NewAIMatchmakingManager(hub *websocket.Hub, db *gorm.DB, logger *logger.Logger) *AIMatchmakingManager {
	manager := &AIMatchmakingManager{
		config:   DefaultAIMatchmakingConfig(),
		hub:      hub,
		db:       db,
		logger:   logger,
		activeAI: make(map[uuid.UUID]*AIWebSocketClient),
		stopChan: make(chan bool),
	}

	logger.Info("Created AI matchmaking manager",
		"activation_timeout", manager.config.ActivationTimeout,
		"max_concurrent", manager.config.MaxConcurrentAI)

	return manager
}

// Start begins the AI matchmaking monitoring
func (m *AIMatchmakingManager) Start() error {
	if !m.config.Enabled {
		m.logger.Info("AI matchmaking disabled")
		return nil
	}

	if m.isRunning {
		return nil
	}

	m.isRunning = true

	// Monitor matchmaking queues every 10 seconds
	m.queueMonitorTicker = time.NewTicker(10 * time.Second)

	go m.runQueueMonitoring()

	m.logger.Info("AI matchmaking manager started")
	return nil
}

// Stop stops the AI matchmaking manager
func (m *AIMatchmakingManager) Stop() {
	if !m.isRunning {
		return
	}

	m.isRunning = false

	if m.queueMonitorTicker != nil {
		m.queueMonitorTicker.Stop()
	}

	close(m.stopChan)

	// Disconnect all active AI players
	m.aiMutex.Lock()
	for _, aiClient := range m.activeAI {
		aiClient.Disconnect()
	}
	m.activeAI = make(map[uuid.UUID]*AIWebSocketClient)
	m.aiMutex.Unlock()

	m.logger.Info("AI matchmaking manager stopped")
}

// runQueueMonitoring monitors matchmaking queues and activates AI when needed
func (m *AIMatchmakingManager) runQueueMonitoring() {
	m.logger.Info("AI matchmaking queue monitoring started")

	for {
		select {
		case <-m.queueMonitorTicker.C:
			m.checkQueuesForAIActivation()
		case <-m.stopChan:
			m.logger.Info("AI matchmaking queue monitoring stopped")
			return
		}
	}
}

// checkQueuesForAIActivation analyzes matchmaking queues and creates AI players as needed
func (m *AIMatchmakingManager) checkQueuesForAIActivation() {
	m.logger.Debug("Checking queues for AI activation")

	// Get current queue statistics from the hub
	allStats := m.hub.GetMatchmakingQueueStats()

	// Check if we have any queues data
	queuesInterface, hasQueues := allStats["queues"]
	if !hasQueues {
		m.logger.Debug("No queues data available, skipping AI activation check")
		return
	}

	queues, ok := queuesInterface.(map[string]interface{})
	if !ok {
		m.logger.Error("Invalid queues data format")
		return
	}

	// Process each queue type
	for queueType, queueDataInterface := range queues {
		queueData, ok := queueDataInterface.(map[string]interface{})
		if !ok {
			m.logger.Warn("Invalid queue data format", "queue_type", queueType)
			continue
		}

		// Extract queue statistics
		longestWaitSeconds, _ := queueData["longest_wait_seconds"].(float64)
		playersWaiting, _ := queueData["players_waiting"].(int)

		m.logger.Debug("Queue stats retrieved",
			"queue_type", queueType,
			"longest_wait_seconds", longestWaitSeconds,
			"players_waiting", playersWaiting,
			"activation_timeout", m.config.ActivationTimeout.Seconds())

		// Check if AI should be deployed
		if longestWaitSeconds > m.config.ActivationTimeout.Seconds() && playersWaiting > 0 {
			// Check if we've already reached max concurrent AI
			m.aiMutex.RLock()
			currentAICount := len(m.activeAI)
			m.aiMutex.RUnlock()

			if currentAICount >= m.config.MaxConcurrentAI {
				metrics.AIDeploymentFailures.WithLabelValues("max_concurrent_reached").Inc()
				m.logger.Debug("Max concurrent AI players reached",
					"current", currentAICount,
					"max", m.config.MaxConcurrentAI)
				continue
			}

			m.logger.Info("Deploying AI due to long wait time",
				"queue_type", queueType,
				"wait_time", longestWaitSeconds,
				"players_waiting", playersWaiting,
				"threshold", m.config.ActivationTimeout.Seconds())

			// Use default rating of 1200 for AI deployment
			// The wait time is converted from seconds back to duration
			waitTime := time.Duration(longestWaitSeconds * float64(time.Second))
			m.deployAIPlayer(queueType, 1200, waitTime)
		}
	}
}

// deployAIPlayer creates and deploys an AI player to help with matchmaking
func (m *AIMatchmakingManager) deployAIPlayer(queueType string, humanRating int, humanWaitTime time.Duration) {
	// Choose AI difficulty based on distribution
	difficulty := m.chooseDifficulty()

	// Generate appropriate rating for the AI (close to human player's rating)
	aiRating := m.generateAIRating(humanRating)

	// Create AI player
	ai := NewAIPlayer(difficulty, aiRating, m.logger)

	// Create AI WebSocket client
	aiClient := NewAIWebSocketClient(ai, m.hub, m.logger)

	// Connect AI client
	err := aiClient.Connect()
	if err != nil {
		metrics.AIDeploymentFailures.WithLabelValues("connection_failed").Inc()
		m.logger.Error("Failed to connect AI player",
			"error", err,
			"ai_id", ai.ID,
			"difficulty", difficulty)
		return
	}

	// Store active AI
	m.aiMutex.Lock()
	m.activeAI[ai.ID] = aiClient
	m.aiMutex.Unlock()

	// Update AI metrics
	metrics.AIOpponentsActive.Inc()
	metrics.AIDeployments.WithLabelValues(string(difficulty)).Inc()

	// Create player record in database for AI
	err = m.createAIPlayerRecord(ai)
	if err != nil {
		m.logger.Error("Failed to create AI player database record",
			"error", err,
			"ai_id", ai.ID)
		// Continue anyway - game will still work
	}

	m.logger.Info("AI player deployed to matchmaking",
		"ai_id", ai.ID,
		"username", ai.Username,
		"difficulty", difficulty,
		"rating", aiRating,
		"queue_type", queueType,
		"human_wait_time", humanWaitTime)

	// Join matchmaking queue
	err = aiClient.JoinMatchmaking(queueType)
	if err != nil {
		m.logger.Error("AI failed to join matchmaking",
			"error", err,
			"ai_id", ai.ID,
			"queue_type", queueType)

		// Clean up failed AI
		m.aiMutex.Lock()
		delete(m.activeAI, ai.ID)
		m.aiMutex.Unlock()
		metrics.AIOpponentsActive.Dec()
		aiClient.Disconnect()
		return
	}

	// Set up cleanup after game completion
	go m.scheduleAICleanup(ai.ID, 10*time.Minute) // Clean up after 10 minutes max
}

// chooseDifficulty selects AI difficulty based on configured distribution
func (m *AIMatchmakingManager) chooseDifficulty() string {
	roll := m.hub.GetRandomFloat64() // Use hub's random for consistency

	cumulative := 0.0
	for difficulty, probability := range m.config.DifficultyDistribution {
		cumulative += probability
		if roll <= cumulative {
			return difficulty
		}
	}

	return "medium" // Default fallback
}

// generateAIRating creates an appropriate rating for AI based on human player's rating
func (m *AIMatchmakingManager) generateAIRating(humanRating int) int {
	// Generate rating within ±100 of human rating, but within AI rating bounds
	variance := 100
	minRating := humanRating - variance
	maxRating := humanRating + variance

	if minRating < m.config.RatingRange.Min {
		minRating = m.config.RatingRange.Min
	}
	if maxRating > m.config.RatingRange.Max {
		maxRating = m.config.RatingRange.Max
	}

	// Random rating in the calculated range
	ratingRange := maxRating - minRating
	if ratingRange <= 0 {
		return humanRating
	}

	randomOffset := int(m.hub.GetRandomFloat64() * float64(ratingRange))
	return minRating + randomOffset
}

// createAIPlayerRecord creates database records for AI player
func (m *AIMatchmakingManager) createAIPlayerRecord(ai *AIPlayer) error {
	// Use GetOrCreateUser to handle race conditions properly
	dbService := database.NewDatabase(m.db)
	user, err := dbService.GetOrCreateUser(
		ai.ID,
		ai.Username,
		fmt.Sprintf("%s@ai.septica.game", ai.ID.String()),
		"ai_player_no_password",
	)
	if err != nil {
		metrics.AIDeploymentFailures.WithLabelValues("database_error").Inc()
		return fmt.Errorf("failed to create/retrieve AI user: %w", err)
	}

	m.logger.Debug("AI user ready", "ai_id", ai.ID, "username", user.Username)

	// Check if player already exists
	var existingPlayer database.Player
	err = m.db.Where("user_id = ?", ai.ID).First(&existingPlayer).Error
	if err == nil {
		// Player already exists
		m.logger.Debug("AI player already exists, skipping player creation", "ai_id", ai.ID)
		return nil
	}

	// Create player record
	player := ai.GetPlayerInfo()
	err = m.db.Create(player).Error
	if err != nil {
		metrics.AIDeploymentFailures.WithLabelValues("database_error").Inc()
		return fmt.Errorf("failed to create AI player: %w", err)
	}

	return nil
}

// scheduleAICleanup sets up automatic cleanup of AI player after specified time
func (m *AIMatchmakingManager) scheduleAICleanup(aiID uuid.UUID, timeout time.Duration) {
	time.Sleep(timeout)
	m.cleanupAIPlayer(aiID)
}

// cleanupAIPlayer removes an AI player and cleans up resources
func (m *AIMatchmakingManager) cleanupAIPlayer(aiID uuid.UUID) {
	m.aiMutex.Lock()
	aiClient, exists := m.activeAI[aiID]
	if !exists {
		m.aiMutex.Unlock()
		return
	}

	delete(m.activeAI, aiID)
	m.aiMutex.Unlock()

	// Update AI metrics
	metrics.AIOpponentsActive.Dec()

	// Disconnect AI client
	aiClient.Disconnect()

	m.logger.Info("AI player cleaned up", "ai_id", aiID)
}

// GetActiveAICount returns the number of currently active AI players
func (m *AIMatchmakingManager) GetActiveAICount() int {
	m.aiMutex.RLock()
	defer m.aiMutex.RUnlock()
	return len(m.activeAI)
}

// GetConfig returns the current AI matchmaking configuration
func (m *AIMatchmakingManager) GetConfig() *AIMatchmakingConfig {
	return m.config
}

// UpdateConfig updates the AI matchmaking configuration
func (m *AIMatchmakingManager) UpdateConfig(config *AIMatchmakingConfig) {
	m.config = config
	m.logger.Info("AI matchmaking configuration updated",
		"activation_timeout", config.ActivationTimeout,
		"max_concurrent", config.MaxConcurrentAI)
}
