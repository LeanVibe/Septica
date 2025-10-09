package game

import (
	"os"
	"strconv"
	"time"
)

// GameConfig holds configuration for both legacy and authentic game engines
type GameConfig struct {
	// Feature flags for gradual migration
	UseAuthenticRules    bool `json:"use_authentic_rules"`
	EnableLegacyFallback bool `json:"enable_legacy_fallback"`
	DefaultToAuthentic   bool `json:"default_to_authentic"`

	// Authentic engine specific config
	AuthenticConfig AuthenticEngineConfig `json:"authentic_config"`

	// Legacy engine config (existing)
	LegacyEnabled bool `json:"legacy_enabled"`

	// General game settings
	MaxConcurrentGames  int           `json:"max_concurrent_games"`
	GameTimeoutDuration time.Duration `json:"game_timeout_duration"`
	PlayerActionTimeout time.Duration `json:"player_action_timeout"`

	// Performance settings
	EnableGameStateLogging bool `json:"enable_game_state_logging"`
	MaxHistoryPerGame      int  `json:"max_history_per_game"`
}

// LoadConfigFromEnv loads game configuration from environment variables
func LoadConfigFromEnv() *GameConfig {
	config := &GameConfig{
		// Feature flags - default to supporting both systems
		UseAuthenticRules:    getBoolEnv("USE_AUTHENTIC_RULES", true),
		EnableLegacyFallback: getBoolEnv("ENABLE_LEGACY_FALLBACK", true),
		DefaultToAuthentic:   getBoolEnv("DEFAULT_TO_AUTHENTIC", false), // Gradual rollout

		// Legacy support
		LegacyEnabled: getBoolEnv("LEGACY_ENGINE_ENABLED", true),

		// General settings
		MaxConcurrentGames:  getIntEnv("MAX_CONCURRENT_GAMES", 10000),
		GameTimeoutDuration: getDurationEnv("GAME_TIMEOUT_DURATION", 30*time.Minute),
		PlayerActionTimeout: getDurationEnv("PLAYER_ACTION_TIMEOUT", 30*time.Second),

		// Performance
		EnableGameStateLogging: getBoolEnv("ENABLE_GAME_STATE_LOGGING", true),
		MaxHistoryPerGame:      getIntEnv("MAX_HISTORY_PER_GAME", 1000),

		// Authentic engine config
		AuthenticConfig: AuthenticEngineConfig{
			UseAuthenticRules: getBoolEnv("USE_AUTHENTIC_RULES", true),
			DefaultGameMode:   getAuthenticGameModeEnv("DEFAULT_GAME_MODE", ModeTwoPlayer),
			MaxGameDuration:   getDurationEnv("MAX_GAME_DURATION", 30*time.Minute),
			ObjectionTimeout:  getDurationEnv("OBJECTION_TIMEOUT", 30*time.Second),
		},
	}

	return config
}

// GetDefaultConfig returns a default configuration for development
func GetDefaultConfig() *GameConfig {
	return &GameConfig{
		// Feature flags - authentic rules preferred but legacy fallback enabled
		UseAuthenticRules:    true,
		EnableLegacyFallback: true,
		DefaultToAuthentic:   true,

		// Legacy support during transition
		LegacyEnabled: true,

		// General settings
		MaxConcurrentGames:  1000,
		GameTimeoutDuration: 30 * time.Minute,
		PlayerActionTimeout: 30 * time.Second,

		// Performance
		EnableGameStateLogging: true,
		MaxHistoryPerGame:      500,

		// Authentic engine config
		AuthenticConfig: AuthenticEngineConfig{
			UseAuthenticRules: true,
			DefaultGameMode:   ModeTwoPlayer,
			MaxGameDuration:   30 * time.Minute,
			ObjectionTimeout:  30 * time.Second,
		},
	}
}

// GameEngineType represents which engine to use for a game
type GameEngineType string

const (
	EngineTypeLegacy    GameEngineType = "legacy"
	EngineTypeAuthentic GameEngineType = "authentic"
)

// DetermineEngineType determines which engine to use based on config and request
func (c *GameConfig) DetermineEngineType(requestedAuthentic bool) GameEngineType {
	// If authentic rules are disabled, use legacy
	if !c.UseAuthenticRules {
		return EngineTypeLegacy
	}

	// If client specifically requests authentic and it's enabled
	if requestedAuthentic {
		return EngineTypeAuthentic
	}

	// If client doesn't specify, use default
	if c.DefaultToAuthentic {
		return EngineTypeAuthentic
	}

	return EngineTypeLegacy
}

// ShouldEnableLegacyFallback determines if legacy fallback should be used
func (c *GameConfig) ShouldEnableLegacyFallback() bool {
	return c.EnableLegacyFallback && c.LegacyEnabled
}

// ValidationConfig returns validation settings for games
type ValidationConfig struct {
	StrictRuleValidation    bool `json:"strict_rule_validation"`
	EnableCheatingDetection bool `json:"enable_cheating_detection"`
	LogInvalidMoves         bool `json:"log_invalid_moves"`
}

// GetValidationConfig returns validation configuration
func (c *GameConfig) GetValidationConfig() ValidationConfig {
	return ValidationConfig{
		StrictRuleValidation:    c.UseAuthenticRules, // Stricter validation for authentic rules
		EnableCheatingDetection: true,
		LogInvalidMoves:         c.EnableGameStateLogging,
	}
}

// Helper functions to parse environment variables

func getBoolEnv(key string, defaultVal bool) bool {
	if val := os.Getenv(key); val != "" {
		if parsed, err := strconv.ParseBool(val); err == nil {
			return parsed
		}
	}
	return defaultVal
}

func getIntEnv(key string, defaultVal int) int {
	if val := os.Getenv(key); val != "" {
		if parsed, err := strconv.Atoi(val); err == nil {
			return parsed
		}
	}
	return defaultVal
}

func getDurationEnv(key string, defaultVal time.Duration) time.Duration {
	if val := os.Getenv(key); val != "" {
		if parsed, err := time.ParseDuration(val); err == nil {
			return parsed
		}
	}
	return defaultVal
}

func getAuthenticGameModeEnv(key string, defaultVal AuthenticGameMode) AuthenticGameMode {
	if val := os.Getenv(key); val != "" {
		switch val {
		case "2_player":
			return ModeTwoPlayer
		case "3_player":
			return ModeThreePlayer
		case "4_player":
			return ModeFourPlayer
		}
	}
	return defaultVal
}

// Migration helpers for gradual rollout

// MigrationStrategy defines how to migrate from legacy to authentic
type MigrationStrategy struct {
	Phase               string   `json:"phase"`                // "testing", "gradual", "full"
	AuthenticPercentage int      `json:"authentic_percentage"` // 0-100% of new games use authentic
	EnableABTesting     bool     `json:"enable_ab_testing"`
	UserWhitelist       []string `json:"user_whitelist"` // Always use authentic for these users
	UserBlacklist       []string `json:"user_blacklist"` // Never use authentic for these users
}

// GetMigrationStrategy returns current migration strategy
func (c *GameConfig) GetMigrationStrategy() MigrationStrategy {
	return MigrationStrategy{
		Phase:               getBoolToStringEnv("MIGRATION_PHASE", "testing"),
		AuthenticPercentage: getIntEnv("AUTHENTIC_PERCENTAGE", 10), // Start with 10% rollout
		EnableABTesting:     getBoolEnv("ENABLE_AB_TESTING", true),
		UserWhitelist:       getStringSliceEnv("AUTHENTIC_WHITELIST", []string{}),
		UserBlacklist:       getStringSliceEnv("AUTHENTIC_BLACKLIST", []string{}),
	}
}

func getBoolToStringEnv(key, defaultVal string) string {
	if val := os.Getenv(key); val != "" {
		return val
	}
	return defaultVal
}

func getStringSliceEnv(key string, defaultVal []string) []string {
	// Simple implementation - could be enhanced to parse comma-separated values
	if val := os.Getenv(key); val != "" {
		// For now, return single value as slice
		return []string{val}
	}
	return defaultVal
}
