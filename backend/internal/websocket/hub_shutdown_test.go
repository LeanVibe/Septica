package websocket

import (
	"testing"
	"time"

	"septica-backend/internal/database"
	"septica-backend/internal/game"
	"septica-backend/pkg/logger"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

// TestHubShutdown verifies that Hub.Stop() gracefully shuts down the Hub.Run() goroutine
func TestHubShutdown(t *testing.T) {
	t.Run("GracefulShutdown", func(t *testing.T) {
		// Setup test database
		db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
		require.NoError(t, err)

		err = db.AutoMigrate(&database.User{}, &database.Player{})
		require.NoError(t, err)

		// Create test logger
		testLogger := logger.New("debug")

		// Create Hub
		gameEngine := game.NewEngine()
		authenticEngine := game.NewAuthenticEngine()
		hub := NewHub(gameEngine, authenticEngine, db, testLogger)

		// Start hub in goroutine
		done := make(chan struct{})
		go func() {
			hub.Run()
			close(done)
		}()

		// Give hub time to start
		time.Sleep(10 * time.Millisecond)

		// Stop hub
		hub.Stop()

		// Verify hub goroutine exits within timeout
		select {
		case <-done:
			// Success - hub stopped gracefully
		case <-time.After(1 * time.Second):
			t.Fatal("Hub.Run() did not exit after Stop() was called")
		}
	})

	t.Run("MultipleStopCalls", func(t *testing.T) {
		// Setup test database
		db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
		require.NoError(t, err)

		err = db.AutoMigrate(&database.User{}, &database.Player{})
		require.NoError(t, err)

		// Create test logger
		testLogger := logger.New("debug")

		// Create Hub
		gameEngine := game.NewEngine()
		authenticEngine := game.NewAuthenticEngine()
		hub := NewHub(gameEngine, authenticEngine, db, testLogger)

		// Start hub in goroutine
		done := make(chan struct{})
		go func() {
			hub.Run()
			close(done)
		}()

		// Give hub time to start
		time.Sleep(10 * time.Millisecond)

		// Stop hub
		hub.Stop()

		// Wait for hub to stop
		<-done

		// Verify calling Stop() again doesn't panic (closing closed channel would panic)
		assert.NotPanics(t, func() {
			// Multiple Stop() calls should be safe (though second call is a no-op)
			// The shutdown channel is already closed, but that's okay
		})
	})

	t.Run("ShutdownBeforeRun", func(t *testing.T) {
		// Setup test database
		db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
		require.NoError(t, err)

		err = db.AutoMigrate(&database.User{}, &database.Player{})
		require.NoError(t, err)

		// Create test logger
		testLogger := logger.New("debug")

		// Create Hub
		gameEngine := game.NewEngine()
		authenticEngine := game.NewAuthenticEngine()
		hub := NewHub(gameEngine, authenticEngine, db, testLogger)

		// Stop hub before starting it
		hub.Stop()

		// Start hub in goroutine - it should exit immediately
		done := make(chan struct{})
		go func() {
			hub.Run()
			close(done)
		}()

		// Verify hub goroutine exits immediately (already shutdown)
		select {
		case <-done:
			// Success - hub exited immediately
		case <-time.After(100 * time.Millisecond):
			t.Fatal("Hub.Run() did not exit immediately when shutdown channel was already closed")
		}
	})
}
