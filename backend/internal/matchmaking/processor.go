package matchmaking

import (
	"math"
	"sort"
	"time"

	"septica-backend/internal/database"
	"septica-backend/internal/websocket"

	"github.com/google/uuid"
)

// runQueueProcessor is the main queue processing loop
func (s *MatchmakingService) runQueueProcessor() {
	s.logger.Info("Starting queue processor")
	
	for {
		select {
		case <-s.processorTicker.C:
			s.processAllQueues()
		case <-s.stopChan:
			s.logger.Info("Queue processor stopped")
			return
		}
	}
}

// runQueueUpdater sends periodic updates to players in queue
func (s *MatchmakingService) runQueueUpdater() {
	s.logger.Info("Starting queue updater")
	
	for {
		select {
		case <-s.updateTicker.C:
			s.sendQueueUpdates()
		case <-s.stopChan:
			s.logger.Info("Queue updater stopped")
			return
		}
	}
}

// processAllQueues processes each queue for potential matches
func (s *MatchmakingService) processAllQueues() {
	s.queueMutex.RLock()
	defer s.queueMutex.RUnlock()
	
	for queueType, queue := range s.queues {
		s.processQueue(queueType, queue)
	}
	
	// Clean up expired entries
	s.cleanupExpiredEntries()
}

// processQueue processes a specific queue for matches
func (s *MatchmakingService) processQueue(queueType string, queue *MatchmakingQueue) {
	entries := queue.GetAll()
	if len(entries) < 2 {
		return // Need at least 2 players to make a match
	}
	
	// Sort entries by queue time (oldest first for fairness)
	sort.Slice(entries, func(i, j int) bool {
		return entries[i].QueuedAt.Before(entries[j].QueuedAt)
	})
	
	// Try to find matches
	for i := 0; i < len(entries); i++ {
		entry1 := entries[i]
		
		// Skip if already processed
		if queue.Find(entry1.PlayerID) == nil {
			continue
		}
		
		// Find best match for this player
		bestMatch := s.findBestMatch(entry1, entries[i+1:])
		if bestMatch == nil {
			continue
		}
		
		// Create the match
		if err := s.createMatch(entry1, bestMatch, queueType); err != nil {
			s.logger.Error("Failed to create match", "error", err,
				"player1_id", entry1.PlayerID, "player2_id", bestMatch.PlayerID)
			continue
		}
		
		// Remove both players from queue
		queue.Remove(entry1.PlayerID)
		queue.Remove(bestMatch.PlayerID)
		
		s.logger.Info("Match created successfully",
			"player1_id", entry1.PlayerID,
			"player2_id", bestMatch.PlayerID,
			"queue_type", queueType,
			"rating_diff", abs(entry1.Rating-bestMatch.Rating))
	}
}

// findBestMatch finds the best match for a player from available candidates
func (s *MatchmakingService) findBestMatch(player *QueueEntry, candidates []*QueueEntry) *QueueEntry {
	currentRange := player.GetCurrentSearchRange(s.config)
	var bestMatch *QueueEntry
	bestRatingDiff := math.MaxInt32
	
	for _, candidate := range candidates {
		// Check if ratings are within search range
		ratingDiff := abs(player.Rating - candidate.Rating)
		if ratingDiff > currentRange {
			continue
		}
		
		// Check if this is a better match (closer rating)
		if ratingDiff < bestRatingDiff {
			bestMatch = candidate
			bestRatingDiff = ratingDiff
		}
	}
	
	return bestMatch
}

// createMatch creates a game between two matched players
func (s *MatchmakingService) createMatch(player1, player2 *QueueEntry, queueType string) error {
	// Create game using existing game engine
	gameState := s.gameEngine.CreateGame(player1.PlayerID, player2.PlayerID)
	
	// Calculate wait times
	player1WaitTime := time.Since(player1.QueuedAt)
	player2WaitTime := time.Since(player2.QueuedAt)
	
	// Get player information from database
	player1Info, err := s.getPlayerInfo(player1.PlayerID)
	if err != nil {
		return err
	}
	
	player2Info, err := s.getPlayerInfo(player2.PlayerID)
	if err != nil {
		return err
	}
	
	// Send match found messages to both players
	s.sendMatchFound(player1.PlayerID, gameState.ID, player2.PlayerID, player2.Rating, player2Info.Username, player1WaitTime)
	s.sendMatchFound(player2.PlayerID, gameState.ID, player1.PlayerID, player1.Rating, player1Info.Username, player2WaitTime)
	
	// Auto-join both players to the game via WebSocket hub
	if err := s.hub.JoinGame(player1.PlayerID, gameState.ID); err != nil {
		s.logger.Error("Failed to auto-join player1 to game", "error", err, "player_id", player1.PlayerID, "game_id", gameState.ID)
	}
	
	if err := s.hub.JoinGame(player2.PlayerID, gameState.ID); err != nil {
		s.logger.Error("Failed to auto-join player2 to game", "error", err, "player_id", player2.PlayerID, "game_id", gameState.ID)
	}
	
	// Update database queue entries as matched
	s.db.Where("player_id IN (?, ?) AND is_active = true", player1.PlayerID, player2.PlayerID).
		Update("is_active", false)
	
	// Create game record in database with matchmaking context
	dbGame := &database.Game{
		Player1ID:            player1.PlayerID,
		Player2ID:            player2.PlayerID,
		Status:               "in_progress",
		GameMode:             queueType,
		Player1RatingBefore:  player1.Rating,
		Player2RatingBefore:  player2.Rating,
		StartedAt:            &gameState.CreatedAt,
	}
	
	// Set the game ID to match the engine's game ID
	dbGame.ID = gameState.ID
	if err := s.db.Create(dbGame).Error; err != nil {
		s.logger.Error("Failed to create game record in database", "error", err, "game_id", gameState.ID)
		// Continue anyway, as the game exists in the engine
	}
	
	s.logger.Info("Match created and players auto-joined",
		"game_id", gameState.ID,
		"player1_id", player1.PlayerID,
		"player2_id", player2.PlayerID,
		"queue_type", queueType)
	
	return nil
}

// cleanupExpiredEntries removes players who have exceeded maximum wait time
func (s *MatchmakingService) cleanupExpiredEntries() {
	for queueType, queue := range s.queues {
		entries := queue.GetAll()
		for _, entry := range entries {
			if entry.IsExpired(s.config) {
				// Remove from queue
				queue.Remove(entry.PlayerID)
				
				// Update database
				s.db.Where("player_id = ? AND is_active = true", entry.PlayerID).
					Update("is_active", false)
				
				// Send timeout message to player
				s.sendMatchmakingTimeout(entry.PlayerID)
				
				s.logger.Info("Removed expired queue entry",
					"player_id", entry.PlayerID,
					"queue_type", queueType,
					"wait_time", time.Since(entry.QueuedAt))
			}
		}
	}
}

// sendQueueUpdates sends periodic status updates to all players in queues
func (s *MatchmakingService) sendQueueUpdates() {
	s.queueMutex.RLock()
	defer s.queueMutex.RUnlock()
	
	for queueType, queue := range s.queues {
		entries := queue.GetAll()
		for _, entry := range entries {
			// Only send updates if enough time has passed since last update
			if time.Since(entry.LastUpdate) >= s.config.UpdateInterval {
				s.sendMatchmakingUpdate(entry, queueType, queue)
				entry.LastUpdate = time.Now()
			}
		}
	}
}

// Helper functions for WebSocket messaging
func (s *MatchmakingService) sendMatchmakingJoined(playerID uuid.UUID, queueType string) {
	message := websocket.Message{
		Type:      "matchmaking_joined",
		ID:        uuid.New().String(),
		PlayerID:  playerID,
		Timestamp: time.Now(),
		Payload: map[string]interface{}{
			"queue_type": queueType,
			"message":    "Successfully joined matchmaking queue",
		},
	}
	
	s.sendToPlayer(playerID, message)
}

func (s *MatchmakingService) sendMatchmakingLeft(playerID uuid.UUID) {
	message := websocket.Message{
		Type:      "matchmaking_left",
		ID:        uuid.New().String(),
		PlayerID:  playerID,
		Timestamp: time.Now(),
		Payload: map[string]interface{}{
			"message": "Successfully left matchmaking queue",
		},
	}
	
	s.sendToPlayer(playerID, message)
}

func (s *MatchmakingService) sendMatchFound(playerID, gameID, opponentID uuid.UUID, opponentRating int, opponentName string, waitTime time.Duration) {
	message := websocket.Message{
		Type:      "match_found",
		ID:        uuid.New().String(),
		PlayerID:  playerID,
		GameID:    &gameID,
		Timestamp: time.Now(),
		Payload: map[string]interface{}{
			"game_id":          gameID,
			"opponent_id":      opponentID,
			"opponent_rating":  opponentRating,
			"opponent_name":    opponentName,
			"wait_time_ms":     waitTime.Milliseconds(),
			"message":          "Match found! Joining game...",
		},
	}
	
	s.sendToPlayer(playerID, message)
}

func (s *MatchmakingService) sendMatchmakingUpdate(entry *QueueEntry, queueType string, queue *MatchmakingQueue) {
	position := s.getQueuePosition(queue, entry.PlayerID)
	estimatedWait := s.calculateEstimatedWaitTime(queue, entry)
	currentRange := entry.GetCurrentSearchRange(s.config)
	
	message := websocket.Message{
		Type:      "matchmaking_update",
		ID:        uuid.New().String(),
		PlayerID:  entry.PlayerID,
		Timestamp: time.Now(),
		Payload: map[string]interface{}{
			"queue_position":      position,
			"estimated_wait_time": int(estimatedWait.Seconds()),
			"search_range":        currentRange,
			"players_in_queue":    queue.Size(),
			"wait_time":           int(time.Since(entry.QueuedAt).Seconds()),
		},
	}
	
	s.sendToPlayer(entry.PlayerID, message)
}

func (s *MatchmakingService) sendMatchmakingTimeout(playerID uuid.UUID) {
	message := websocket.Message{
		Type:      "matchmaking_error",
		ID:        uuid.New().String(),
		PlayerID:  playerID,
		Timestamp: time.Now(),
		Payload: map[string]interface{}{
			"error_type": "timeout",
			"message":    "Matchmaking timed out. Please try again.",
		},
	}
	
	s.sendToPlayer(playerID, message)
}

func (s *MatchmakingService) sendToPlayer(playerID uuid.UUID, message websocket.Message) {
	// Send message to player via WebSocket hub
	if err := s.hub.SendToPlayer(playerID, message); err != nil {
		s.logger.Warn("Failed to send matchmaking message to player",
			"player_id", playerID,
			"message_type", message.Type,
			"error", err)
	} else {
		s.logger.Debug("Sent matchmaking message to player",
			"player_id", playerID,
			"message_type", message.Type)
	}
}

// Helper utility functions
func (s *MatchmakingService) getQueuePosition(queue *MatchmakingQueue, playerID uuid.UUID) int {
	entries := queue.GetAll()
	
	// Sort by queue time to determine position
	sort.Slice(entries, func(i, j int) bool {
		return entries[i].QueuedAt.Before(entries[j].QueuedAt)
	})
	
	for i, entry := range entries {
		if entry.PlayerID == playerID {
			return i + 1 // 1-based position
		}
	}
	return -1
}

func (s *MatchmakingService) calculateEstimatedWaitTime(queue *MatchmakingQueue, entry *QueueEntry) time.Duration {
	// Simple estimation based on current queue size and historical data
	// This could be improved with more sophisticated algorithms
	
	queueSize := queue.Size()
	if queueSize <= 1 {
		return 2 * time.Minute // Base wait time for single player
	}
	
	// Estimate based on queue position and average match rate
	position := s.getQueuePosition(queue, entry.PlayerID)
	averageMatchTime := 30 * time.Second // Assume matches are made every 30 seconds on average
	
	estimatedWait := time.Duration(position/2) * averageMatchTime
	if estimatedWait < 30*time.Second {
		estimatedWait = 30 * time.Second
	}
	
	return estimatedWait
}

func (s *MatchmakingService) calculateAverageWaitTime(queue *MatchmakingQueue) time.Duration {
	entries := queue.GetAll()
	if len(entries) == 0 {
		return 0
	}
	
	totalWaitTime := time.Duration(0)
	for _, entry := range entries {
		totalWaitTime += time.Since(entry.QueuedAt)
	}
	
	return totalWaitTime / time.Duration(len(entries))
}

func (s *MatchmakingService) getPlayerInfo(playerID uuid.UUID) (*database.Player, error) {
	var player database.Player
	if err := s.db.Where("user_id = ?", playerID).First(&player).Error; err != nil {
		return nil, err
	}
	return &player, nil
}

func abs(x int) int {
	if x < 0 {
		return -x
	}
	return x
}

// Database persistence methods
func (s *MatchmakingService) loadQueuesFromDatabase() error {
	var dbEntries []database.MatchmakingQueue
	
	// Load all active queue entries
	if err := s.db.Where("is_active = true").Find(&dbEntries).Error; err != nil {
		return err
	}
	
	// Populate in-memory queues
	for _, dbEntry := range dbEntries {
		entry := &QueueEntry{
			PlayerID:    dbEntry.PlayerID,
			Rating:      dbEntry.Rating,
			QueuedAt:    dbEntry.QueuedAt,
			SearchRange: dbEntry.SearchRange,
			MaxWaitTime: time.Duration(dbEntry.MaxWaitTime) * time.Second,
			GameMode:    "septica", // Default game mode
			QueueType:   dbEntry.QueueType,
			LastUpdate:  time.Now(),
		}
		
		if queue, exists := s.queues[dbEntry.QueueType]; exists {
			queue.Add(entry)
		}
	}
	
	s.logger.Info("Loaded queue entries from database", "count", len(dbEntries))
	return nil
}

func (s *MatchmakingService) saveQueuesToDatabase() {
	// Mark all current entries as inactive (cleanup on shutdown)
	for _, queue := range s.queues {
		entries := queue.GetAll()
		for _, entry := range entries {
			s.db.Where("player_id = ? AND is_active = true", entry.PlayerID).
				Update("is_active", false)
		}
	}
	
	s.logger.Info("Saved queue state to database")
}