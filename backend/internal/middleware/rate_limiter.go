package middleware

import (
	"net/http"
	"sync"
	"time"

	"septica-backend/internal/metrics"
	"septica-backend/pkg/logger"

	"github.com/gin-gonic/gin"
	"golang.org/x/time/rate"
)

// IPRateLimiter manages rate limiting per IP address using token bucket algorithm
type IPRateLimiter struct {
	limiters map[string]*rate.Limiter
	mu       sync.RWMutex
	rate     rate.Limit
	burst    int
	logger   *logger.Logger
}

// NewIPRateLimiter creates a new IP-based rate limiter
// requestsPerMinute: maximum number of requests allowed per minute
// logger: logger instance for tracking rate limit violations
func NewIPRateLimiter(requestsPerMinute int, logger *logger.Logger) *IPRateLimiter {
	// Convert requests per minute to rate limit (requests per second)
	r := rate.Every(time.Minute / time.Duration(requestsPerMinute))

	return &IPRateLimiter{
		limiters: make(map[string]*rate.Limiter),
		rate:     r,
		burst:    requestsPerMinute / 2, // Allow burst of half the rate for better UX
		logger:   logger,
	}
}

// GetLimiter retrieves or creates a rate limiter for the given IP address
func (i *IPRateLimiter) GetLimiter(ip string) *rate.Limiter {
	i.mu.Lock()
	defer i.mu.Unlock()

	limiter, exists := i.limiters[ip]
	if !exists {
		limiter = rate.NewLimiter(i.rate, i.burst)
		i.limiters[ip] = limiter
	}

	return limiter
}

// CleanupStale removes limiters for IPs that haven't made requests recently
// This prevents memory leaks from accumulating limiters for ephemeral IPs
func (i *IPRateLimiter) CleanupStale(maxAge time.Duration) {
	i.mu.Lock()
	defer i.mu.Unlock()

	// For simplicity, clear all limiters older than maxAge
	// In production, you might want to track last access time per limiter
	if len(i.limiters) > 10000 { // Arbitrary threshold
		i.logger.Info("Cleaning up rate limiter cache", "count", len(i.limiters))
		i.limiters = make(map[string]*rate.Limiter)
	}
}

// RateLimitMiddleware creates a Gin middleware that enforces rate limiting
func RateLimitMiddleware(rateLimiter *IPRateLimiter, logger *logger.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		ip := c.ClientIP()
		limiter := rateLimiter.GetLimiter(ip)

		if !limiter.Allow() {
			// Log the rate limit violation
			logger.Warn("Rate limit exceeded",
				"ip", ip,
				"path", c.Request.URL.Path,
				"method", c.Request.Method,
				"user_agent", c.Request.UserAgent())

			// Track metric for rate limit violations
			metrics.RateLimitExceeded.WithLabelValues(ip, c.Request.URL.Path).Inc()

			c.JSON(http.StatusTooManyRequests, gin.H{
				"error":       "rate limit exceeded",
				"message":     "Too many requests. Please try again later.",
				"retry_after": "60s",
			})
			c.Abort()
			return
		}

		c.Next()
	}
}

// StartCleanupWorker starts a background goroutine that periodically cleans up stale limiters
func (i *IPRateLimiter) StartCleanupWorker(interval time.Duration) {
	ticker := time.NewTicker(interval)
	go func() {
		for range ticker.C {
			i.CleanupStale(interval)
		}
	}()
}
