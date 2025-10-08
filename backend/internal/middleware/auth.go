package middleware

import (
	"net/http"
	"strings"

	"septica-backend/internal/auth"
	"septica-backend/pkg/logger"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// AuthMiddleware validates JWT tokens and sets user context
// This middleware enforces authentication on all routes it's applied to
func AuthMiddleware(authService *auth.Service, logger *logger.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Extract token from Authorization header
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			logger.Warn("Missing authorization header", "path", c.Request.URL.Path, "ip", c.ClientIP())
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": "missing authorization header",
			})
			c.Abort()
			return
		}

		// Remove "Bearer " prefix
		tokenString := strings.TrimPrefix(authHeader, "Bearer ")
		if tokenString == authHeader {
			logger.Warn("Invalid authorization format", "path", c.Request.URL.Path)
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": "invalid authorization format, expected 'Bearer <token>'",
			})
			c.Abort()
			return
		}

		// Validate token
		claims, err := authService.ValidateToken(tokenString)
		if err != nil {
			logger.Warn("Token validation failed", "error", err, "path", c.Request.URL.Path)
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": "invalid or expired token",
			})
			c.Abort()
			return
		}

		// Set user context for downstream handlers
		c.Set("user_id", claims.UserID)
		c.Set("username", claims.Username)

		logger.Debug("User authenticated", "user_id", claims.UserID, "username", claims.Username, "path", c.Request.URL.Path)

		c.Next()
	}
}

// OptionalAuthMiddleware validates tokens but doesn't block if missing
// This is useful for endpoints that have different behavior for authenticated vs anonymous users
func OptionalAuthMiddleware(authService *auth.Service, logger *logger.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			// No token provided, continue without authentication
			c.Next()
			return
		}

		tokenString := strings.TrimPrefix(authHeader, "Bearer ")
		if tokenString == authHeader {
			// Invalid format, but don't block the request
			logger.Debug("Invalid authorization format in optional auth", "path", c.Request.URL.Path)
			c.Next()
			return
		}

		// Try to validate token
		claims, err := authService.ValidateToken(tokenString)
		if err == nil {
			// Valid token, set context
			c.Set("user_id", claims.UserID)
			c.Set("username", claims.Username)
			logger.Debug("Optional auth: user authenticated", "user_id", claims.UserID, "username", claims.Username)
		} else {
			// Invalid token, but don't block
			logger.Debug("Optional auth: token validation failed", "error", err)
		}

		c.Next()
	}
}

// GetUserID extracts the authenticated user ID from the context
// Returns the user ID and true if authenticated, uuid.Nil and false otherwise
func GetUserID(c *gin.Context) (uuid.UUID, bool) {
	userID, exists := c.Get("user_id")
	if !exists {
		return uuid.Nil, false
	}

	uid, ok := userID.(uuid.UUID)
	if !ok {
		return uuid.Nil, false
	}

	return uid, true
}

// GetUsername extracts the authenticated username from the context
// Returns the username and true if authenticated, empty string and false otherwise
func GetUsername(c *gin.Context) (string, bool) {
	username, exists := c.Get("username")
	if !exists {
		return "", false
	}

	uname, ok := username.(string)
	if !ok {
		return "", false
	}

	return uname, true
}

// RequireAuth is a helper that can be used in handlers to ensure authentication
// Usage: if !middleware.RequireAuth(c, logger) { return }
func RequireAuth(c *gin.Context, logger *logger.Logger) bool {
	userID, exists := GetUserID(c)
	if !exists || userID == uuid.Nil {
		logger.Warn("Authentication required but user not authenticated", "path", c.Request.URL.Path)
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "authentication required",
		})
		c.Abort()
		return false
	}
	return true
}
