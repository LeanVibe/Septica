package auth

import (
	"errors"
	"time"

	"septica-backend/internal/database"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

var (
	ErrInvalidToken       = errors.New("invalid token")
	ErrExpiredToken       = errors.New("token has expired")
	ErrInvalidPassword    = errors.New("invalid password")
	ErrUserAlreadyExists  = errors.New("username or email already exists")
	ErrUserNotFound       = errors.New("user not found")
	ErrInvalidCredentials = errors.New("invalid credentials")
)

// Claims represents the JWT claims structure
type Claims struct {
	UserID   uuid.UUID `json:"user_id"`
	Username string    `json:"username"`
	jwt.RegisteredClaims
}

// Service provides authentication functionality
type Service struct {
	jwtSecret []byte
	jwtExpiry time.Duration
	db        *gorm.DB
}

// NewService creates a new authentication service
func NewService(jwtSecret string, jwtExpiry time.Duration, db *gorm.DB) *Service {
	return &Service{
		jwtSecret: []byte(jwtSecret),
		jwtExpiry: jwtExpiry,
		db:        db,
	}
}

// HashPassword creates a bcrypt hash of the password
func (s *Service) HashPassword(password string) (string, error) {
	bytes, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	return string(bytes), err
}

// CheckPassword verifies a password against its hash
func (s *Service) CheckPassword(password, hash string) error {
	return bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
}

// GenerateToken creates a new JWT token for a user
func (s *Service) GenerateToken(userID uuid.UUID, username string) (string, error) {
	claims := &Claims{
		UserID:   userID,
		Username: username,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(s.jwtExpiry)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			NotBefore: jwt.NewNumericDate(time.Now()),
			Issuer:    "septica-backend",
			Subject:   userID.String(),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(s.jwtSecret)
}

// ValidateToken parses and validates a JWT token
func (s *Service) ValidateToken(tokenString string) (*Claims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
		// Verify the signing method
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, errors.New("unexpected signing method")
		}
		return s.jwtSecret, nil
	})

	if err != nil {
		if errors.Is(err, jwt.ErrTokenExpired) {
			return nil, ErrExpiredToken
		}
		return nil, ErrInvalidToken
	}

	claims, ok := token.Claims.(*Claims)
	if !ok || !token.Valid {
		return nil, ErrInvalidToken
	}

	return claims, nil
}

// RefreshToken generates a new token from an existing valid token
func (s *Service) RefreshToken(tokenString string) (string, error) {
	claims, err := s.ValidateToken(tokenString)
	if err != nil {
		return "", err
	}

	// Generate a new token with the same user information
	return s.GenerateToken(claims.UserID, claims.Username)
}

// ExtractUserID extracts the user ID from a token without full validation
// This is useful for WebSocket connections where we need the user ID quickly
func (s *Service) ExtractUserID(tokenString string) (uuid.UUID, error) {
	token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
		return s.jwtSecret, nil
	})

	if err != nil {
		return uuid.Nil, err
	}

	claims, ok := token.Claims.(*Claims)
	if !ok {
		return uuid.Nil, ErrInvalidToken
	}

	return claims.UserID, nil
}

// Register creates a new user account and associated player profile
func (s *Service) Register(username, email, password string) (*database.User, error) {
	// Check if user already exists
	var existingUser database.User
	if err := s.db.Where("username = ? OR email = ?", username, email).First(&existingUser).Error; err == nil {
		return nil, ErrUserAlreadyExists
	} else if err != gorm.ErrRecordNotFound {
		return nil, err
	}

	// Hash the password
	passwordHash, err := s.HashPassword(password)
	if err != nil {
		return nil, err
	}

	// Create user
	user := &database.User{
		BaseModel: database.BaseModel{
			ID: uuid.New(),
		},
		Username:     username,
		Email:        email,
		PasswordHash: passwordHash,
		IsActive:     true,
	}

	// Start transaction to create both user and player
	tx := s.db.Begin()
	if tx.Error != nil {
		return nil, tx.Error
	}

	// Create user
	if err := tx.Create(user).Error; err != nil {
		tx.Rollback()
		return nil, err
	}

	// Create associated player profile
	player := &database.Player{
		BaseModel: database.BaseModel{
			ID: uuid.New(),
		},
		UserID:             user.ID,
		Username:           username,
		Level:              1,
		XP:                 0,
		Rating:             1200,
		Arena:              1,
		Coins:              1000,
		Gems:               0,
		SelectedCardBack:   "default",
		SelectedTableTheme: "default",
		SelectedAvatar:     "default",
	}

	if err := tx.Create(player).Error; err != nil {
		tx.Rollback()
		return nil, err
	}

	// Commit transaction
	if err := tx.Commit().Error; err != nil {
		return nil, err
	}

	return user, nil
}

// Login authenticates a user by username and password
func (s *Service) Login(username, password string) (*database.User, error) {
	var user database.User

	// Find user by username
	if err := s.db.Where("username = ?", username).First(&user).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, ErrInvalidCredentials
		}
		return nil, err
	}

	// Check if user is active
	if !user.IsActive {
		return nil, ErrInvalidCredentials
	}

	// Verify password
	if err := s.CheckPassword(password, user.PasswordHash); err != nil {
		return nil, ErrInvalidCredentials
	}

	// Update last login time
	now := time.Now()
	user.LastLoginAt = &now
	if err := s.db.Model(&user).Update("last_login_at", now).Error; err != nil {
		// Don't fail login if we can't update last login time
		// Just log the error in production
	}

	return &user, nil
}

// GetUserByID retrieves a user by their ID
func (s *Service) GetUserByID(userID uuid.UUID) (*database.User, error) {
	var user database.User
	if err := s.db.First(&user, "id = ?", userID).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, ErrUserNotFound
		}
		return nil, err
	}
	return &user, nil
}