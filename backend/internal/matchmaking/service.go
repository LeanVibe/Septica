package matchmaking

import (
	"errors"
	"sync"
	"time"

	"septica-backend/internal/database"
	"septica-backend/internal/game"
	"septica-backend/internal/metrics"
	"septica-backend/internal/websocket"
	"septica-backend/pkg/logger"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// Errors
var (
	ErrPlayerAlreadyInQueue = errors.New("player already in matchmaking queue")
	ErrPlayerNotInQueue     = errors.New("player not in matchmaking queue")
	ErrInvalidQueueType     = errors.New("invalid queue type")
	ErrPlayerNotFound       = errors.New("player not found")
	ErrDatabaseError        = errors.New("database error")
)

// MatchmakingConfig holds configuration for the matchmaking system
type MatchmakingConfig struct {
	InitialSearchRange     int           // ±100 rating
	RangeExpansionInterval time.Duration // 30 seconds
	RangeExpansionAmount   int           // +50 rating
	MaxSearchRange         int           // ±400 rating
	MaxWaitTime           time.Duration  // 5 minutes
	ProcessInterval       time.Duration  // 5 seconds
	UpdateInterval        time.Duration  // 15 seconds
	CleanupInterval       time.Duration  // 1 hour - automated queue cleanup
}

// DefaultConfig returns default matchmaking configuration
func DefaultConfig() *MatchmakingConfig {
	return &MatchmakingConfig{
		InitialSearchRange:     100,
		RangeExpansionInterval: 30 * time.Second,
		RangeExpansionAmount:   50,
		MaxSearchRange:         400,
		MaxWaitTime:           5 * time.Minute,
		ProcessInterval:       5 * time.Second,
		UpdateInterval:        15 * time.Second,
		CleanupInterval:       1 * time.Hour, // Run cleanup every hour
	}
}

// QueueEntry represents a player waiting in the matchmaking queue
type QueueEntry struct {
	PlayerID     uuid.UUID     `json:"player_id"`
	Rating       int           `json:"rating"`
	QueuedAt     time.Time     `json:"queued_at"`
	SearchRange  int           `json:"search_range"`
	MaxWaitTime  time.Duration `json:"max_wait_time"`
	GameMode     string        `json:"game_mode"`
	QueueType    string        `json:"queue_type"`
	LastUpdate   time.Time     `json:"last_update"`
}

// GetCurrentSearchRange calculates the current search range based on wait time
func (e *QueueEntry) GetCurrentSearchRange(config *MatchmakingConfig) int {
	waitTime := time.Since(e.QueuedAt)
	expansions := int(waitTime / config.RangeExpansionInterval)
	currentRange := config.InitialSearchRange + (expansions * config.RangeExpansionAmount)
	
	if currentRange > config.MaxSearchRange {
		return config.MaxSearchRange
	}
	return currentRange
}

// IsExpired checks if the queue entry has exceeded maximum wait time
func (e *QueueEntry) IsExpired(config *MatchmakingConfig) bool {
	return time.Since(e.QueuedAt) > config.MaxWaitTime
}

// MatchmakingQueue represents a queue for a specific game mode
type MatchmakingQueue struct {
	Type     string        `json:"type"`
	Entries  []*QueueEntry `json:"entries"`
	Mutex    sync.RWMutex  `json:"-"`
}

// Add adds a player to the queue
func (q *MatchmakingQueue) Add(entry *QueueEntry) {
	q.Mutex.Lock()
	defer q.Mutex.Unlock()
	q.Entries = append(q.Entries, entry)
}

// Remove removes a player from the queue
func (q *MatchmakingQueue) Remove(playerID uuid.UUID) bool {
	q.Mutex.Lock()
	defer q.Mutex.Unlock()
	
	for i, entry := range q.Entries {
		if entry.PlayerID == playerID {
			q.Entries = append(q.Entries[:i], q.Entries[i+1:]...)
			return true
		}
	}
	return false
}

// Find finds a player entry in the queue
func (q *MatchmakingQueue) Find(playerID uuid.UUID) *QueueEntry {
	q.Mutex.RLock()
	defer q.Mutex.RUnlock()
	
	for _, entry := range q.Entries {
		if entry.PlayerID == playerID {
			return entry
		}
	}
	return nil
}

// GetAll returns a copy of all entries
func (q *MatchmakingQueue) GetAll() []*QueueEntry {
	q.Mutex.RLock()
	defer q.Mutex.RUnlock()
	
	entries := make([]*QueueEntry, len(q.Entries))
	copy(entries, q.Entries)
	return entries
}

// Size returns the number of players in the queue
func (q *MatchmakingQueue) Size() int {
	q.Mutex.RLock()
	defer q.Mutex.RUnlock()
	return len(q.Entries)
}

// MatchmakingService manages player matchmaking queues
type MatchmakingService struct {
	hub               *websocket.Hub
	gameEngine        *game.Engine
	authenticEngine   *game.AuthenticEngine
	db               *gorm.DB
	logger           *logger.Logger
	config           *MatchmakingConfig
	
	// In-memory queue management
	queues     map[string]*MatchmakingQueue // key: queue_type
	queueMutex sync.RWMutex
	
	// Queue processor control
	processorTicker *time.Ticker
	updateTicker    *time.Ticker
	stopChan       chan bool
	running        bool
}

// NewMatchmakingService creates a new matchmaking service
func NewMatchmakingService(hub *websocket.Hub, gameEngine *game.Engine, authenticEngine *game.AuthenticEngine, db *gorm.DB, logger *logger.Logger, config *MatchmakingConfig) *MatchmakingService {
	if config == nil {
		config = DefaultConfig()
	}

	service := &MatchmakingService{
		hub:               hub,
		gameEngine:        gameEngine,
		authenticEngine:   authenticEngine,
		db:               db,
		logger:           logger,
		config:           config,
		queues:           make(map[string]*MatchmakingQueue),
		stopChan:         make(chan bool),
		running:          false,
	}
	
	// Initialize queues for different game modes
	service.queues["ranked"] = &MatchmakingQueue{Type: "ranked", Entries: []*QueueEntry{}}
	service.queues["casual"] = &MatchmakingQueue{Type: "casual", Entries: []*QueueEntry{}}
	service.queues["tournament"] = &MatchmakingQueue{Type: "tournament", Entries: []*QueueEntry{}}
	
	return service
}

// Start begins the matchmaking service
func (s *MatchmakingService) Start() error {
	if s.running {
		return errors.New("matchmaking service already running")
	}

	s.logger.Info("Starting matchmaking service")

	// Load existing queue entries from database
	if err := s.loadQueuesFromDatabase(); err != nil {
		s.logger.Error("Failed to load queues from database", "error", err)
		return err
	}

	// Start queue processors
	s.processorTicker = time.NewTicker(s.config.ProcessInterval)
	s.updateTicker = time.NewTicker(s.config.UpdateInterval)
	s.running = true

	go s.runQueueProcessor()
	go s.runQueueUpdater()
	go s.runCleanupLoop()

	s.logger.Info("Matchmaking service started successfully")
	return nil
}

// Stop stops the matchmaking service
func (s *MatchmakingService) Stop() {
	if !s.running {
		return
	}
	
	s.logger.Info("Stopping matchmaking service")
	
	s.running = false
	close(s.stopChan)
	
	if s.processorTicker != nil {
		s.processorTicker.Stop()
	}
	if s.updateTicker != nil {
		s.updateTicker.Stop()
	}
	
	// Save current queues to database
	s.saveQueuesToDatabase()
	
	s.logger.Info("Matchmaking service stopped")
}

// JoinQueue adds a player to the matchmaking queue
func (s *MatchmakingService) JoinQueue(playerID uuid.UUID, queueType, gameMode string) error {
	s.queueMutex.Lock()
	defer s.queueMutex.Unlock()
	
	// Validate queue type
	queue, exists := s.queues[queueType]
	if !exists {
		return ErrInvalidQueueType
	}
	
	// Check if player is already in any queue
	for _, q := range s.queues {
		if q.Find(playerID) != nil {
			return ErrPlayerAlreadyInQueue
		}
	}
	
	// Get player rating from database
	var player database.Player
	if err := s.db.Where("user_id = ?", playerID).First(&player).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return ErrPlayerNotFound
		}
		return ErrDatabaseError
	}
	
	// Create queue entry
	entry := &QueueEntry{
		PlayerID:    playerID,
		Rating:      player.Rating,
		QueuedAt:    time.Now(),
		SearchRange: s.config.InitialSearchRange,
		MaxWaitTime: s.config.MaxWaitTime,
		GameMode:    gameMode,
		QueueType:   queueType,
		LastUpdate:  time.Now(),
	}
	
	// Add to in-memory queue
	queue.Add(entry)

	// Update queue size metrics
	metrics.QueueSize.WithLabelValues(queueType).Set(float64(queue.Size()))

	// Save to database
	// CRITICAL FIX: Use actual Player.ID for foreign key, not UserID
	dbEntry := &database.MatchmakingQueue{
		PlayerID:    player.ID, // Use Player.ID from database, not UserID
		QueueType:   queueType,
		Rating:      player.Rating,
		QueuedAt:    entry.QueuedAt,
		SearchRange: entry.SearchRange,
		MaxWaitTime: int(entry.MaxWaitTime.Seconds()),
		IsActive:    true,
	}
	
	if err := s.db.Create(dbEntry).Error; err != nil {
		s.logger.Error("Failed to save queue entry to database", "error", err, "player_id", playerID)
		// Continue anyway, as we have it in memory
	}
	
	s.logger.Info("Player joined matchmaking queue", "player_id", playerID, "queue_type", queueType, "rating", player.Rating)
	
	// Send confirmation to player
	s.sendMatchmakingJoined(playerID, queueType)
	
	return nil
}

// LeaveQueue removes a player from the matchmaking queue
func (s *MatchmakingService) LeaveQueue(playerID uuid.UUID) error {
	s.queueMutex.Lock()
	defer s.queueMutex.Unlock()
	
	// Find and remove from in-memory queues
	found := false
	for queueType, queue := range s.queues {
		if queue.Remove(playerID) {
			found = true
			// Update queue size metrics
			metrics.QueueSize.WithLabelValues(queueType).Set(float64(queue.Size()))
			s.logger.Info("Player left matchmaking queue", "player_id", playerID, "queue_type", queueType)
			break
		}
	}

	if !found {
		return ErrPlayerNotInQueue
	}
	
	// Remove from database - need to get Player.ID for the UserID
	var player database.Player
	if err := s.db.Where("user_id = ?", playerID).First(&player).Error; err == nil {
		if err := s.db.Where("player_id = ? AND is_active = true", player.ID).
			Update("is_active", false).Error; err != nil {
			s.logger.Error("Failed to update queue entry in database", "error", err, "player_id", player.ID)
		}
	}
	
	// Send confirmation to player
	s.sendMatchmakingLeft(playerID)
	
	return nil
}

// GetQueueStatus returns the current status of a player in the queue
func (s *MatchmakingService) GetQueueStatus(playerID uuid.UUID) (map[string]interface{}, error) {
	s.queueMutex.RLock()
	defer s.queueMutex.RUnlock()
	
	for queueType, queue := range s.queues {
		if entry := queue.Find(playerID); entry != nil {
			position := s.getQueuePosition(queue, playerID)
			estimatedWait := s.calculateEstimatedWaitTime(queue, entry)
			
			return map[string]interface{}{
				"in_queue":           true,
				"queue_type":         queueType,
				"queue_position":     position,
				"estimated_wait":     int(estimatedWait.Seconds()),
				"current_search_range": entry.GetCurrentSearchRange(s.config),
				"players_in_queue":   queue.Size(),
				"wait_time":          int(time.Since(entry.QueuedAt).Seconds()),
			}, nil
		}
	}
	
	return map[string]interface{}{
		"in_queue": false,
	}, nil
}

// GetQueueStats returns overall queue statistics
func (s *MatchmakingService) GetQueueStats() map[string]interface{} {
	s.queueMutex.RLock()
	defer s.queueMutex.RUnlock()

	stats := map[string]interface{}{
		"total_players": 0,
		"queues":        make(map[string]interface{}),
	}

	totalPlayers := 0
	for queueType, queue := range s.queues {
		entries := queue.GetAll()
		size := len(entries)
		totalPlayers += size

		if size == 0 {
			continue
		}

		avgWaitTime := s.calculateAverageWaitTime(queue)

		// Calculate longest wait time for AI activation
		var longestWait time.Duration
		for _, entry := range entries {
			waitTime := time.Since(entry.QueuedAt)
			if waitTime > longestWait {
				longestWait = waitTime
			}
		}

		stats["queues"].(map[string]interface{})[queueType] = map[string]interface{}{
			"players":              size,
			"average_wait_time":    int(avgWaitTime.Seconds()),
			"longest_wait_seconds": longestWait.Seconds(),
			"players_waiting":      size,
		}
	}

	stats["total_players"] = totalPlayers
	return stats
}

// IsPlayerInQueue checks if a player is currently in any queue
func (s *MatchmakingService) IsPlayerInQueue(playerID uuid.UUID) bool {
	s.queueMutex.RLock()
	defer s.queueMutex.RUnlock()

	for _, queue := range s.queues {
		if queue.Find(playerID) != nil {
			return true
		}
	}
	return false
}

// runCleanupLoop runs the automated cleanup job at configured interval
func (s *MatchmakingService) runCleanupLoop() {
	ticker := time.NewTicker(s.config.CleanupInterval)
	defer ticker.Stop()

	s.logger.Info("Starting automated queue cleanup loop", "interval", s.config.CleanupInterval)

	for {
		select {
		case <-ticker.C:
			if err := s.CleanupStaleEntries(); err != nil {
				s.logger.Error("Queue cleanup failed", "error", err)
			}
		case <-s.stopChan:
			s.logger.Info("Queue cleanup loop stopped")
			return
		}
	}
}

// CleanupStaleEntries removes orphaned and expired queue entries
func (s *MatchmakingService) CleanupStaleEntries() error {
	s.logger.Info("Starting matchmaking queue cleanup")

	// 1. Remove orphaned entries (player doesn't exist)
	orphanedQuery := `
		DELETE FROM matchmaking_queues
		WHERE player_id NOT IN (SELECT id FROM players)
	`
	orphanedResult := s.db.Exec(orphanedQuery)
	if orphanedResult.Error != nil {
		s.logger.Error("Failed to remove orphaned queue entries", "error", orphanedResult.Error)
	} else {
		if orphanedResult.RowsAffected > 0 {
			s.logger.Info("Removed orphaned queue entries", "count", orphanedResult.RowsAffected)
			metrics.QueueCleanupTotal.WithLabelValues("orphaned").Add(float64(orphanedResult.RowsAffected))
		}
	}

	// 2. Mark old entries as inactive (queued > 10 minutes)
	staleTime := time.Now().Add(-10 * time.Minute)
	staleResult := s.db.Model(&database.MatchmakingQueue{}).
		Where("queued_at < ? AND is_active = ?", staleTime, true).
		Update("is_active", false)
	if staleResult.Error != nil {
		s.logger.Error("Failed to mark stale entries inactive", "error", staleResult.Error)
	} else {
		if staleResult.RowsAffected > 0 {
			s.logger.Info("Marked stale entries inactive", "count", staleResult.RowsAffected)
			metrics.QueueCleanupTotal.WithLabelValues("stale").Add(float64(staleResult.RowsAffected))
		}
	}

	// 3. Remove entries from completed games (last 1 hour)
	oneHourAgo := time.Now().Add(-1 * time.Hour)
	completedQuery := `
		DELETE FROM matchmaking_queues
		WHERE player_id IN (
			SELECT DISTINCT player_id FROM games
			WHERE status IN ('completed', 'aborted')
			AND updated_at > ?
		)
	`
	completedResult := s.db.Exec(completedQuery, oneHourAgo)
	if completedResult.Error != nil {
		s.logger.Error("Failed to remove completed game entries", "error", completedResult.Error)
	} else {
		if completedResult.RowsAffected > 0 {
			s.logger.Info("Removed completed game queue entries", "count", completedResult.RowsAffected)
			metrics.QueueCleanupTotal.WithLabelValues("completed_game").Add(float64(completedResult.RowsAffected))
		}
	}

	return nil
}

// GetCleanupStats returns statistics about queue entries requiring cleanup
func (s *MatchmakingService) GetCleanupStats() map[string]int64 {
	stats := make(map[string]int64)

	// Count orphaned entries
	var orphanedCount int64
	s.db.Raw(`
		SELECT COUNT(*) FROM matchmaking_queues
		WHERE player_id NOT IN (SELECT id FROM players)
	`).Scan(&orphanedCount)
	stats["orphaned"] = orphanedCount

	// Count stale entries
	var staleCount int64
	staleTime := time.Now().Add(-10 * time.Minute)
	s.db.Model(&database.MatchmakingQueue{}).
		Where("queued_at < ? AND is_active = ?", staleTime, true).
		Count(&staleCount)
	stats["stale"] = staleCount

	// Count total active
	var activeCount int64
	s.db.Model(&database.MatchmakingQueue{}).
		Where("is_active = ?", true).
		Count(&activeCount)
	stats["active"] = activeCount

	return stats
}