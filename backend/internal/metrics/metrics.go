package metrics

import (
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
)

var (
	// Game metrics
	ConcurrentGames = promauto.NewGauge(prometheus.GaugeOpts{
		Name: "septica_concurrent_games",
		Help: "Number of games currently in progress",
	})

	TotalGames = promauto.NewCounterVec(prometheus.CounterOpts{
		Name: "septica_games_total",
		Help: "Total number of games created",
	}, []string{"mode"}) // labels: two_players, three_players, four_players

	GameDuration = promauto.NewHistogramVec(prometheus.HistogramOpts{
		Name:    "septica_game_duration_seconds",
		Help:    "Duration of completed games in seconds",
		Buckets: []float64{60, 300, 600, 1200, 1800, 3600}, // 1m, 5m, 10m, 20m, 30m, 1h
	}, []string{"mode"})

	GameErrors = promauto.NewCounterVec(prometheus.CounterOpts{
		Name: "septica_game_errors_total",
		Help: "Total number of game errors",
	}, []string{"type"}) // labels: invalid_move, not_player_turn, game_not_found

	// WebSocket metrics
	WebSocketConnections = promauto.NewGauge(prometheus.GaugeOpts{
		Name: "septica_websocket_connections",
		Help: "Number of active WebSocket connections",
	})

	WebSocketMessages = promauto.NewCounterVec(prometheus.CounterOpts{
		Name: "septica_websocket_messages_total",
		Help: "Total number of WebSocket messages",
	}, []string{"type", "direction"}) // type: game_state, player_move, etc. direction: inbound, outbound

	WebSocketErrors = promauto.NewCounterVec(prometheus.CounterOpts{
		Name: "septica_websocket_errors_total",
		Help: "Total number of WebSocket errors",
	}, []string{"type"}) // labels: connection_failed, message_parse_error, send_failed

	// Matchmaking metrics
	QueueSize = promauto.NewGaugeVec(prometheus.GaugeOpts{
		Name: "septica_queue_size",
		Help: "Number of players waiting in matchmaking queue",
	}, []string{"queue_type"}) // labels: ranked, casual, tournament

	QueueWaitTime = promauto.NewHistogramVec(prometheus.HistogramOpts{
		Name:    "septica_queue_wait_time_seconds",
		Help:    "Time players spend waiting in queue",
		Buckets: []float64{1, 5, 10, 30, 60, 120, 300}, // 1s, 5s, 10s, 30s, 1m, 2m, 5m
	}, []string{"queue_type"})

	MatchmakingSuccess = promauto.NewCounterVec(prometheus.CounterOpts{
		Name: "septica_matchmaking_success_total",
		Help: "Total number of successful matches",
	}, []string{"queue_type"})

	MatchmakingFailures = promauto.NewCounterVec(prometheus.CounterOpts{
		Name: "septica_matchmaking_failures_total",
		Help: "Total number of matchmaking failures",
	}, []string{"reason"}) // labels: no_opponents, timeout, error

	// AI opponent metrics
	AIOpponentsActive = promauto.NewGauge(prometheus.GaugeOpts{
		Name: "septica_ai_opponents_active",
		Help: "Number of active AI opponents",
	})

	AIMoveDuration = promauto.NewHistogramVec(prometheus.HistogramOpts{
		Name:    "septica_ai_move_duration_seconds",
		Help:    "Time taken for AI to make a move",
		Buckets: []float64{0.1, 0.5, 1, 2, 5}, // 100ms, 500ms, 1s, 2s, 5s
	}, []string{"difficulty"}) // labels: easy, medium, hard

	AIDeployments = promauto.NewCounterVec(prometheus.CounterOpts{
		Name: "septica_ai_deployments_total",
		Help: "Total number of AI opponents deployed",
	}, []string{"difficulty"})

	AIDeploymentFailures = promauto.NewCounterVec(prometheus.CounterOpts{
		Name: "septica_ai_deployment_failures_total",
		Help: "Total number of AI deployment failures",
	}, []string{"reason"}) // labels: duplicate_user, connection_failed, database_error, max_concurrent_reached

	// Queue cleanup metrics
	QueueCleanupTotal = promauto.NewCounterVec(prometheus.CounterOpts{
		Name: "septica_queue_cleanup_total",
		Help: "Total number of queue entries cleaned up",
	}, []string{"type"}) // labels: orphaned, stale, completed_game

	// Rate limiting metrics
	RateLimitExceeded = promauto.NewCounterVec(prometheus.CounterOpts{
		Name: "septica_rate_limit_exceeded_total",
		Help: "Total number of rate limit violations",
	}, []string{"ip", "path"})

	// HTTP API metrics (automatically collected by prometheus middleware)
	HTTPRequestDuration = promauto.NewHistogramVec(prometheus.HistogramOpts{
		Name:    "septica_http_request_duration_seconds",
		Help:    "HTTP request latency",
		Buckets: prometheus.DefBuckets,
	}, []string{"method", "path", "status"})

	HTTPRequestsTotal = promauto.NewCounterVec(prometheus.CounterOpts{
		Name: "septica_http_requests_total",
		Help: "Total number of HTTP requests",
	}, []string{"method", "path", "status"})
)
