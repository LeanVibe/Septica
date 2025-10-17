package load

import (
	"context"
	"fmt"
	"sync"
	"sync/atomic"
	"time"

	"septica-backend/internal/database"
	"septica-backend/pkg/logger"

	"github.com/google/uuid"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

// SimpleLoadTest runs basic concurrent operations to validate production readiness
type SimpleLoadTest struct {
	db     *gorm.DB
	logger *logger.Logger

	successCount atomic.Int64
	failureCount atomic.Int64
	totalOps     atomic.Int64
}

// NewSimpleLoadTest creates a new load tester
func NewSimpleLoadTest(dbURL string) (*SimpleLoadTest, error) {
	db, err := gorm.Open(postgres.Open(dbURL), &gorm.Config{})
	if err != nil {
		return nil, fmt.Errorf("failed to connect to database: %w", err)
	}

	log := logger.New("info")

	return &SimpleLoadTest{
		db:     db,
		logger: log,
	}, nil
}

// RunConcurrentUserCreation tests concurrent user creation (validates Phase 3 fix)
func (t *SimpleLoadTest) RunConcurrentUserCreation(ctx context.Context, users int) *LoadTestResults {
	results := NewLoadTestResults("Concurrent User Creation", users)

	var wg sync.WaitGroup
	startTime := time.Now()

	for i := 0; i < users; i++ {
		wg.Add(1)
		go func(index int) {
			defer wg.Done()

			username := fmt.Sprintf("load_test_user_%d_%d", startTime.Unix(), index)
			user := &database.User{
				BaseModel:    database.BaseModel{ID: uuid.New()},
				Username:     username,
				Email:        fmt.Sprintf("%s@loadtest.com", username),
				PasswordHash: "test_hash",
				IsActive:     true,
			}

			if err := t.db.Create(user).Error; err != nil {
				t.failureCount.Add(1)
				results.Errors = append(results.Errors, fmt.Sprintf("User %d creation failed: %v", index, err))
			} else {
				t.successCount.Add(1)
			}
			t.totalOps.Add(1)
		}(i)
	}

	wg.Wait()
	results.Complete()

	results.SuccessCount = int(t.successCount.Load())
	results.FailureCount = int(t.failureCount.Load())

	return results
}

// RunConcurrentMatchmaking tests matchmaking queue under load
func (t *SimpleLoadTest) RunConcurrentMatchmaking(ctx context.Context, entries int) *LoadTestResults {
	results := NewLoadTestResults("Concurrent Matchmaking", entries)

	// Reset counters
	t.successCount.Store(0)
	t.failureCount.Store(0)

	var wg sync.WaitGroup
	startTimes := make([]time.Time, entries)

	for i := 0; i < entries; i++ {
		wg.Add(1)
		go func(index int) {
			defer wg.Done()

			startTimes[index] = time.Now()

			entry := &database.MatchmakingQueue{
				BaseModel:   database.BaseModel{ID: uuid.New()},
				PlayerID:    uuid.New(),
				QueueType:   "ranked",
				Rating:      1200 + (index % 400), // Spread ratings
				QueuedAt:    time.Now(),
				SearchRange: 100,
				MaxWaitTime: 300,
				IsActive:    true,
			}

			if err := t.db.Create(entry).Error; err != nil {
				t.failureCount.Add(1)
			} else {
				t.successCount.Add(1)
			}
		}(i)
	}

	wg.Wait()
	results.Complete()

	results.SuccessCount = int(t.successCount.Load())
	results.FailureCount = int(t.failureCount.Load())

	// Calculate latency metrics
	var totalDuration time.Duration
	for _, startTime := range startTimes {
		if !startTime.IsZero() {
			totalDuration += time.Since(startTime)
		}
	}

	if results.SuccessCount > 0 {
		results.Metrics.QueueWaitTime.Mean = totalDuration / time.Duration(results.SuccessCount)
	}

	return results
}

// Cleanup removes test data
func (t *SimpleLoadTest) Cleanup() error {
	// Delete test users
	if err := t.db.Where("email LIKE ?", "%@loadtest.com").Delete(&database.User{}).Error; err != nil {
		return err
	}

	// Delete orphaned queue entries (those with non-existent players)
	orphanedQuery := `DELETE FROM matchmaking_queues WHERE player_id NOT IN (SELECT id FROM players)`
	if err := t.db.Exec(orphanedQuery).Error; err != nil {
		return err
	}

	return nil
}

// ValidateProductionReadiness runs essential validation tests
func (t *SimpleLoadTest) ValidateProductionReadiness(ctx context.Context) (*TestReport, error) {
	report := &TestReport{
		PassedChecks:    make([]string, 0),
		FailedChecks:    make([]string, 0),
		Recommendations: make([]string, 0),
	}

	// Test 1: Concurrent user creation (100 users)
	t.logger.Info("Running concurrent user creation test (100 users)")
	userTest := t.RunConcurrentUserCreation(ctx, 100)

	if userTest.SuccessRate() >= 99.0 {
		report.PassedChecks = append(report.PassedChecks,
			fmt.Sprintf("✅ Concurrent user creation: %.1f%% success rate (target: 99%%)", userTest.SuccessRate()))
	} else {
		report.FailedChecks = append(report.FailedChecks,
			fmt.Sprintf("❌ Concurrent user creation: %.1f%% success rate (target: 99%%)", userTest.SuccessRate()))
	}

	// Test 2: Concurrent matchmaking (500 entries)
	t.logger.Info("Running concurrent matchmaking test (500 entries)")
	matchTest := t.RunConcurrentMatchmaking(ctx, 500)

	if matchTest.SuccessRate() >= 99.0 {
		report.PassedChecks = append(report.PassedChecks,
			fmt.Sprintf("✅ Concurrent matchmaking: %.1f%% success rate (target: 99%%)", matchTest.SuccessRate()))
	} else {
		report.FailedChecks = append(report.FailedChecks,
			fmt.Sprintf("❌ Concurrent matchmaking: %.1f%% success rate (target: 99%%)", matchTest.SuccessRate()))
	}

	// Test 3: Performance check
	if userTest.Duration < 5*time.Second {
		report.PassedChecks = append(report.PassedChecks,
			fmt.Sprintf("✅ User creation performance: %v (target: <5s)", userTest.Duration))
	} else {
		report.Recommendations = append(report.Recommendations,
			fmt.Sprintf("⚠️ User creation took %v, consider optimization", userTest.Duration))
	}

	// Cleanup
	if err := t.Cleanup(); err != nil {
		t.logger.Error("Cleanup failed", "error", err)
	}

	return report, nil
}
