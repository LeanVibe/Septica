package logger

import (
	"encoding/json"
	"fmt"
	"log"
	"os"
	"runtime"
	"time"

	"github.com/gin-gonic/gin"
)

// MobileGameLogger provides enhanced logging for mobile game development
type MobileGameLogger struct {
	*log.Logger
	startTime time.Time
	metrics   *PerformanceMetrics
}

type PerformanceMetrics struct {
	ActiveConnections    int           `json:"active_connections"`
	GameSessions         int           `json:"game_sessions"`
	AverageResponseTime  time.Duration `json:"average_response_time"`
	CardPlaysPerSecond   float64       `json:"card_plays_per_second"`
	DatabaseQueryTime    time.Duration `json:"database_query_time"`
	MemoryUsageMB        float64       `json:"memory_usage_mb"`
	GoroutineCount       int           `json:"goroutine_count"`
	LastHealthCheck      time.Time     `json:"last_health_check"`
}

type GameEvent struct {
	Timestamp   time.Time   `json:"timestamp"`
	PlayerID    string      `json:"player_id"`
	GameID      string      `json:"game_id"`
	EventType   string      `json:"event_type"`
	CardPlayed  *Card       `json:"card_played,omitempty"`
	TableState  []Card      `json:"table_state,omitempty"`
	IsValidPlay bool        `json:"is_valid_play"`
	Points      int         `json:"points"`
	RuleChecked string      `json:"rule_checked,omitempty"`
	ResponseTime time.Duration `json:"response_time"`
}

type Card struct {
	Value int    `json:"value"`
	Suit  string `json:"suit"`
}

type LogLevel string

const (
	DEBUG    LogLevel = "DEBUG"
	INFO     LogLevel = "INFO"
	SUCCESS  LogLevel = "SUCCESS"
	WARN     LogLevel = "WARN"
	ERROR    LogLevel = "ERROR"
	CRITICAL LogLevel = "CRITICAL"
)

var MobileLogger *MobileGameLogger

func init() {
	MobileLogger = NewMobileGameLogger()
}

func NewMobileGameLogger() *MobileGameLogger {
	logger := &MobileGameLogger{
		Logger:    log.New(os.Stdout, "", 0),
		startTime: time.Now(),
		metrics: &PerformanceMetrics{
			LastHealthCheck: time.Now(),
		},
	}

	logger.Success("MOBILE_LOGGER", "Mobile game development logger initialized", map[string]interface{}{
		"start_time": logger.startTime,
		"go_version": runtime.Version(),
		"goroutines": runtime.NumGoroutine(),
	})

	return logger
}

// ===== ROMANIAN SEPTICA GAME LOGGING =====

func (l *MobileGameLogger) LogCardPlay(playerID, gameID string, card Card, tableState []Card, isValid bool, points int, responseTime time.Duration) {
	event := GameEvent{
		Timestamp:   time.Now(),
		PlayerID:    playerID,
		GameID:      gameID,
		EventType:   "CARD_PLAY",
		CardPlayed:  &card,
		TableState:  tableState,
		IsValidPlay: isValid,
		Points:      points,
		ResponseTime: responseTime,
	}

	if isValid {
		l.Info("GAME_PLAY", fmt.Sprintf("Player %s played %d%s → %d points (%v)",
			playerID[:8], card.Value, card.Suit, points, responseTime), event)

		// Validate Romanian Septica rules
		l.validateRomanianRules(card, tableState, isValid, event)
	} else {
		l.Warn("INVALID_PLAY", fmt.Sprintf("Player %s invalid play: %d%s",
			playerID[:8], card.Value, card.Suit), event)
	}

	// Performance warning for slow card processing
	if responseTime > 200*time.Millisecond {
		l.Warn("PERFORMANCE", fmt.Sprintf("Slow card processing: %v", responseTime), map[string]interface{}{
			"player_id": playerID[:8],
			"response_time": responseTime,
			"target_time": "< 200ms",
		})
	}
}

func (l *MobileGameLogger) validateRomanianRules(card Card, tableState []Card, wasValid bool, event GameEvent) {
	// Rule: 7s always beat
	if card.Value == 7 {
		event.RuleChecked = "7_beats_all"
		if !wasValid {
			l.Error("RULE_VIOLATION", "7 should always beat but was rejected!", event)
		} else {
			l.Debug("RULE_CHECK", "7 beats all - valid", event)
		}
	}

	// Rule: Same values beat each other
	for _, tableCard := range tableState {
		if tableCard.Value == card.Value {
			event.RuleChecked = "same_value_beats"
			l.Debug("RULE_CHECK", fmt.Sprintf("%d beats %d - same value", card.Value, tableCard.Value), event)
			break
		}
	}

	// Rule: 8s beat when table cards count % 3 == 0
	if card.Value == 8 {
		if len(tableState)%3 == 0 {
			event.RuleChecked = "8_conditional_beat"
			l.Debug("RULE_CHECK", "8 beats (table count % 3 == 0)", event)
		} else {
			event.RuleChecked = "8_conditional_no_beat"
			l.Debug("RULE_CHECK", "8 doesn't beat (table count % 3 != 0)", event)
		}
	}

	// Log point cards (10s and Aces)
	if card.Value == 10 || card.Value == 14 { // Ace = 14
		pointType := "10 (1pt)"
		if card.Value == 14 {
			pointType = "Ace (1pt)"
		}
		l.Info("POINTS", fmt.Sprintf("Point card played: %s", pointType), map[string]interface{}{
			"card": fmt.Sprintf("%d%s", card.Value, card.Suit),
			"player_id": event.PlayerID[:8],
			"total_possible": 8,
		})
	}
}

func (l *MobileGameLogger) LogMatchmaking(playerID, status string, waitTime time.Duration) {
	data := map[string]interface{}{
		"player_id": playerID[:8],
		"status":    status,
		"wait_time": waitTime,
		"timestamp": time.Now(),
	}

	switch status {
	case "queued":
		l.Info("MATCHMAKING", fmt.Sprintf("Player %s joined queue", playerID[:8]), data)
	case "matched":
		l.Success("MATCHMAKING", fmt.Sprintf("Match found in %v", waitTime), data)
		l.updateMetric("matchmaking_success", 1)
	case "timeout":
		l.Warn("MATCHMAKING", fmt.Sprintf("Queue timeout after %v", waitTime), data)
	default:
		l.Info("MATCHMAKING", fmt.Sprintf("Status: %s", status), data)
	}
}

func (l *MobileGameLogger) LogGameSession(gameID string, event string, playerCount int) {
	data := map[string]interface{}{
		"game_id":      gameID,
		"event":        event,
		"player_count": playerCount,
		"timestamp":    time.Now(),
	}

	switch event {
	case "created":
		l.Success("GAME_SESSION", fmt.Sprintf("Game %s created with %d players", gameID[:8], playerCount), data)
		l.metrics.GameSessions++
	case "ended":
		l.Info("GAME_SESSION", fmt.Sprintf("Game %s ended", gameID[:8]), data)
		l.metrics.GameSessions--
	case "player_joined":
		l.Info("GAME_SESSION", fmt.Sprintf("Player joined game %s (%d total)", gameID[:8], playerCount), data)
	case "player_left":
		l.Warn("GAME_SESSION", fmt.Sprintf("Player left game %s (%d remaining)", gameID[:8], playerCount), data)
	}
}

// ===== WEBSOCKET/CONNECTION LOGGING =====

func (l *MobileGameLogger) LogWebSocketEvent(playerID, event string, latency time.Duration, error error) {
	data := map[string]interface{}{
		"player_id": playerID[:8],
		"event":     event,
		"latency":   latency,
		"timestamp": time.Now(),
	}

	if error != nil {
		data["error"] = error.Error()
	}

	switch event {
	case "connect":
		l.Success("WEBSOCKET", fmt.Sprintf("Player %s connected", playerID[:8]), data)
		l.metrics.ActiveConnections++
	case "disconnect":
		l.Info("WEBSOCKET", fmt.Sprintf("Player %s disconnected", playerID[:8]), data)
		l.metrics.ActiveConnections--
	case "reconnect":
		l.Info("WEBSOCKET", fmt.Sprintf("Player %s reconnected (%v)", playerID[:8], latency), data)
	case "message":
		if latency > 500*time.Millisecond {
			l.Warn("WEBSOCKET", fmt.Sprintf("High latency: %v", latency), data)
		} else {
			l.Debug("WEBSOCKET", fmt.Sprintf("Message processed (%v)", latency), data)
		}
	case "error":
		l.Error("WEBSOCKET", fmt.Sprintf("Connection error for %s", playerID[:8]), data)
	}
}

// ===== PERFORMANCE MONITORING =====

func (l *MobileGameLogger) UpdatePerformanceMetrics() {
	var m runtime.MemStats
	runtime.ReadMemStats(&m)

	l.metrics.MemoryUsageMB = float64(m.Alloc) / 1024 / 1024
	l.metrics.GoroutineCount = runtime.NumGoroutine()
	l.metrics.LastHealthCheck = time.Now()

	// Log performance warnings
	if l.metrics.MemoryUsageMB > 100 {
		l.Warn("PERFORMANCE", fmt.Sprintf("High memory usage: %.2f MB", l.metrics.MemoryUsageMB), l.metrics)
	}

	if l.metrics.GoroutineCount > 1000 {
		l.Warn("PERFORMANCE", fmt.Sprintf("High goroutine count: %d", l.metrics.GoroutineCount), l.metrics)
	}

	if l.metrics.ActiveConnections > 50 {
		l.Info("SCALE", fmt.Sprintf("High player count: %d active connections", l.metrics.ActiveConnections), l.metrics)
	}
}

func (l *MobileGameLogger) LogDatabaseQuery(query string, duration time.Duration, error error) {
	data := map[string]interface{}{
		"query":    query,
		"duration": duration,
		"timestamp": time.Now(),
	}

	l.metrics.DatabaseQueryTime = duration

	if error != nil {
		data["error"] = error.Error()
		l.Error("DATABASE", fmt.Sprintf("Query failed: %s", query), data)
	} else if duration > 100*time.Millisecond {
		l.Warn("DATABASE", fmt.Sprintf("Slow query (%v): %s", duration, query), data)
	} else {
		l.Debug("DATABASE", fmt.Sprintf("Query completed (%v)", duration), data)
	}
}

// ===== MOBILE GAME HEALTH MONITORING =====

func (l *MobileGameLogger) HealthCheck() map[string]interface{} {
	l.UpdatePerformanceMetrics()

	health := map[string]interface{}{
		"status":     "healthy",
		"uptime":     time.Since(l.startTime),
		"metrics":    l.metrics,
		"timestamp":  time.Now(),
		"issues":     []string{},
	}

	var issues []string

	// Check performance thresholds
	if l.metrics.MemoryUsageMB > 200 {
		issues = append(issues, fmt.Sprintf("High memory: %.2f MB", l.metrics.MemoryUsageMB))
	}

	if l.metrics.AverageResponseTime > 200*time.Millisecond {
		issues = append(issues, fmt.Sprintf("High response time: %v", l.metrics.AverageResponseTime))
	}

	if l.metrics.DatabaseQueryTime > 100*time.Millisecond {
		issues = append(issues, fmt.Sprintf("Slow database: %v", l.metrics.DatabaseQueryTime))
	}

	if len(issues) > 0 {
		health["status"] = "warning"
		health["issues"] = issues
		l.Warn("HEALTH_CHECK", fmt.Sprintf("Performance issues detected: %d", len(issues)), health)
	} else {
		l.Success("HEALTH_CHECK", "All systems optimal", health)
	}

	return health
}

// ===== STRUCTURED LOGGING METHODS =====

func (l *MobileGameLogger) Debug(category, message string, data interface{}) {
	l.log(DEBUG, category, message, data)
}

func (l *MobileGameLogger) Info(category, message string, data interface{}) {
	l.log(INFO, category, message, data)
}

func (l *MobileGameLogger) Success(category, message string, data interface{}) {
	l.log(SUCCESS, category, message, data)
}

func (l *MobileGameLogger) Warn(category, message string, data interface{}) {
	l.log(WARN, category, message, data)
}

func (l *MobileGameLogger) Error(category, message string, data interface{}) {
	l.log(ERROR, category, message, data)
}

func (l *MobileGameLogger) Critical(category, message string, data interface{}) {
	l.log(CRITICAL, category, message, data)
}

func (l *MobileGameLogger) log(level LogLevel, category, message string, data interface{}) {
	timestamp := time.Now().Format("15:04:05.000")

	logEntry := map[string]interface{}{
		"timestamp": timestamp,
		"level":     level,
		"category":  category,
		"message":   message,
		"uptime":    time.Since(l.startTime).Truncate(time.Millisecond),
	}

	if data != nil {
		logEntry["data"] = data
	}

	// Color coding for console output
	var color string
	switch level {
	case DEBUG:
		color = "\033[90m" // Gray
	case INFO:
		color = "\033[94m" // Blue
	case SUCCESS:
		color = "\033[92m" // Green
	case WARN:
		color = "\033[93m" // Yellow
	case ERROR:
		color = "\033[91m" // Red
	case CRITICAL:
		color = "\033[91;1m" // Bold Red
	}
	reset := "\033[0m"

	// Format for mobile game development
	if data != nil {
		jsonData, _ := json.Marshal(data)
		fmt.Printf("%s[%s] [%s] [%s] %s %s%s\n",
			color, timestamp, level, category, message, string(jsonData), reset)
	} else {
		fmt.Printf("%s[%s] [%s] [%s] %s%s\n",
			color, timestamp, level, category, message, reset)
	}
}

func (l *MobileGameLogger) updateMetric(metric string, value interface{}) {
	// Simple metric updates - in production would use proper metrics store
	switch metric {
	case "matchmaking_success":
		// Track successful matchmaking
	case "card_play_response":
		// Track card play response times
	}
}

// ===== GIN MIDDLEWARE FOR REQUEST LOGGING =====

func (l *MobileGameLogger) GinMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		path := c.Request.URL.Path
		raw := c.Request.URL.RawQuery

		// Process request
		c.Next()

		// Calculate response time
		latency := time.Since(start)

		// Update performance metrics
		l.metrics.AverageResponseTime = latency

		if raw != "" {
			path = path + "?" + raw
		}

		data := map[string]interface{}{
			"method":     c.Request.Method,
			"path":       path,
			"status":     c.Writer.Status(),
			"latency":    latency,
			"ip":         c.ClientIP(),
			"user_agent": c.Request.UserAgent(),
		}

		if latency > 1*time.Second {
			l.Error("HTTP_SLOW", fmt.Sprintf("%s %s took %v", c.Request.Method, path, latency), data)
		} else if c.Writer.Status() >= 400 {
			l.Warn("HTTP_ERROR", fmt.Sprintf("%s %s returned %d", c.Request.Method, path, c.Writer.Status()), data)
		} else {
			l.Debug("HTTP", fmt.Sprintf("%s %s (%v)", c.Request.Method, path, latency), data)
		}
	}
}