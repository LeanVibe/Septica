package handlers

import (
	"net/http"

	"septica-backend/internal/auth"
	"septica-backend/internal/middleware"
	"septica-backend/pkg/logger"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// AuthHandler handles authentication-related HTTP requests
type AuthHandler struct {
	authService *auth.Service
	db          *gorm.DB
	logger      *logger.Logger
}

// NewAuthHandler creates a new authentication handler
func NewAuthHandler(authService *auth.Service, db *gorm.DB, logger *logger.Logger) *AuthHandler {
	return &AuthHandler{
		authService: authService,
		db:          db,
		logger:      logger,
	}
}

// RegisterRequest represents the registration request payload
type RegisterRequest struct {
	Username string `json:"username" binding:"required,min=3,max=20"`
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required,min=8"`
}

// LoginRequest represents the login request payload
type LoginRequest struct {
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required"`
}

// Register creates a new user account
// POST /api/v1/auth/register
func (h *AuthHandler) Register(c *gin.Context) {
	var req RegisterRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		h.logger.Warn("Invalid registration request", "error", err)
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Invalid request format",
			"details": err.Error(),
		})
		return
	}

	// Create user via auth service
	user, err := h.authService.Register(req.Username, req.Email, req.Password)
	if err != nil {
		if err == auth.ErrUserAlreadyExists {
			h.logger.Warn("Registration failed - user exists", "username", req.Username, "email", req.Email)
			c.JSON(http.StatusConflict, gin.H{
				"error": "username or email already exists",
			})
			return
		}

		h.logger.Error("Registration failed", "error", err, "username", req.Username)
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "failed to create user account",
		})
		return
	}

	// Generate JWT token
	token, err := h.authService.GenerateToken(user.ID, user.Username)
	if err != nil {
		h.logger.Error("Token generation failed", "error", err, "user_id", user.ID)
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "failed to generate authentication token",
		})
		return
	}

	h.logger.Info("User registered successfully", "user_id", user.ID, "username", user.Username)

	c.JSON(http.StatusCreated, gin.H{
		"user": gin.H{
			"id":       user.ID,
			"username": user.Username,
			"email":    user.Email,
		},
		"token":   token,
		"message": "account created successfully",
	})
}

// Login authenticates an existing user
// POST /api/v1/auth/login
func (h *AuthHandler) Login(c *gin.Context) {
	var req LoginRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		h.logger.Warn("Invalid login request", "error", err)
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Invalid request format",
			"details": err.Error(),
		})
		return
	}

	// Authenticate user
	user, err := h.authService.Login(req.Username, req.Password)
	if err != nil {
		if err == auth.ErrInvalidCredentials {
			h.logger.Warn("Login failed - invalid credentials", "username", req.Username)
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": "invalid username or password",
			})
			return
		}

		h.logger.Error("Login failed", "error", err, "username", req.Username)
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "authentication failed",
		})
		return
	}

	// Generate JWT token
	token, err := h.authService.GenerateToken(user.ID, user.Username)
	if err != nil {
		h.logger.Error("Token generation failed", "error", err, "user_id", user.ID)
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "failed to generate authentication token",
		})
		return
	}

	h.logger.Info("User logged in successfully", "user_id", user.ID, "username", user.Username)

	c.JSON(http.StatusOK, gin.H{
		"user": gin.H{
			"id":       user.ID,
			"username": user.Username,
			"email":    user.Email,
		},
		"token":   token,
		"message": "login successful",
	})
}

// RefreshToken generates a new token from a valid existing token
// POST /api/v1/auth/refresh (requires authentication)
func (h *AuthHandler) RefreshToken(c *gin.Context) {
	// Get user from context (set by auth middleware)
	userID, exists := middleware.GetUserID(c)
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "user not authenticated",
		})
		return
	}

	username, _ := middleware.GetUsername(c)

	// Generate new token
	token, err := h.authService.GenerateToken(userID, username)
	if err != nil {
		h.logger.Error("Token refresh failed", "error", err, "user_id", userID)
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "failed to refresh token",
		})
		return
	}

	h.logger.Debug("Token refreshed", "user_id", userID, "username", username)

	c.JSON(http.StatusOK, gin.H{
		"token":   token,
		"message": "token refreshed successfully",
	})
}

// GetMe returns the currently authenticated user's information
// GET /api/v1/auth/me (requires authentication)
func (h *AuthHandler) GetMe(c *gin.Context) {
	// Get user from context (set by auth middleware)
	userID, exists := middleware.GetUserID(c)
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "user not authenticated",
		})
		return
	}

	// Fetch full user details from database
	user, err := h.authService.GetUserByID(userID)
	if err != nil {
		h.logger.Error("Failed to get user details", "error", err, "user_id", userID)
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "failed to retrieve user information",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"user": gin.H{
			"id":            user.ID,
			"username":      user.Username,
			"email":         user.Email,
			"is_active":     user.IsActive,
			"last_login_at": user.LastLoginAt,
			"created_at":    user.CreatedAt,
		},
	})
}

// Logout invalidates the current session
// POST /api/v1/auth/logout (requires authentication)
// Note: With JWT tokens, logout is typically handled client-side by removing the token
// This endpoint is provided for logging purposes and future token blacklist implementation
func (h *AuthHandler) Logout(c *gin.Context) {
	userID, exists := middleware.GetUserID(c)
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "user not authenticated",
		})
		return
	}

	username, _ := middleware.GetUsername(c)

	h.logger.Info("User logged out", "user_id", userID, "username", username)

	c.JSON(http.StatusOK, gin.H{
		"message": "logout successful",
	})
}

// RegisterAuthRoutes registers all authentication routes
func RegisterAuthRoutes(router *gin.RouterGroup, authService *auth.Service, db *gorm.DB, logger *logger.Logger) {
	handler := NewAuthHandler(authService, db, logger)

	// Public routes (no authentication required)
	router.POST("/auth/register", handler.Register)
	router.POST("/auth/login", handler.Login)

	// Protected routes (require authentication)
	protected := router.Group("/auth")
	protected.Use(middleware.AuthMiddleware(authService, logger))
	{
		protected.POST("/refresh", handler.RefreshToken)
		protected.GET("/me", handler.GetMe)
		protected.POST("/logout", handler.Logout)
	}
}
