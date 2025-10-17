// +build integration

package load_test

import (
	"context"
	"fmt"
	"os"
	"testing"
	"time"

	"septica-backend/tests/load"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestProductionReadiness validates system under concurrent load
// This test requires PostgreSQL (set DATABASE_URL environment variable)
//
// Usage:
//   export DATABASE_URL="postgresql://user:pass@localhost:5432/septica_test?sslmode=disable"
//   go test -v -tags=integration ./tests/load -run TestProductionReadiness
func TestProductionReadiness(t *testing.T) {
	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		t.Skip("Skipping load test: DATABASE_URL not set")
	}

	loadTest, err := load.NewSimpleLoadTest(dbURL)
	require.NoError(t, err, "Failed to create load test")

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
	defer cancel()

	// Run production readiness validation
	report, err := loadTest.ValidateProductionReadiness(ctx)
	require.NoError(t, err, "Production readiness validation failed")

	// Print results
	fmt.Println("\n" + "="*70)
	fmt.Println("PRODUCTION READINESS VALIDATION RESULTS")
	fmt.Println("="*70)

	fmt.Println("\n✅ PASSED CHECKS:")
	for _, check := range report.PassedChecks {
		fmt.Println("  ", check)
	}

	if len(report.FailedChecks) > 0 {
		fmt.Println("\n❌ FAILED CHECKS:")
		for _, check := range report.FailedChecks {
			fmt.Println("  ", check)
		}
	}

	if len(report.Recommendations) > 0 {
		fmt.Println("\n⚠️  RECOMMENDATIONS:")
		for _, rec := range report.Recommendations {
			fmt.Println("  ", rec)
		}
	}

	fmt.Println("\n" + "="*70)

	// Assert all checks passed
	assert.Empty(t, report.FailedChecks, "Some production readiness checks failed")

	if len(report.FailedChecks) == 0 {
		fmt.Println("\n🎉 PRODUCTION READY: All checks passed!")
		fmt.Println("System validated for concurrent load and production deployment.")
	}

	fmt.Println()
}

// BenchmarkConcurrentUserCreation benchmarks user creation performance
func BenchmarkConcurrentUserCreation(b *testing.B) {
	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		b.Skip("Skipping benchmark: DATABASE_URL not set")
	}

	loadTest, err := load.NewSimpleLoadTest(dbURL)
	if err != nil {
		b.Fatalf("Failed to create load test: %v", err)
	}

	ctx := context.Background()

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		results := loadTest.RunConcurrentUserCreation(ctx, 10)
		if results.SuccessRate() < 99.0 {
			b.Errorf("Low success rate: %.1f%%", results.SuccessRate())
		}
	}
}

// BenchmarkConcurrentMatchmaking benchmarks matchmaking queue performance
func BenchmarkConcurrentMatchmaking(b *testing.B) {
	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		b.Skip("Skipping benchmark: DATABASE_URL not set")
	}

	loadTest, err := load.NewSimpleLoadTest(dbURL)
	if err != nil {
		b.Fatalf("Failed to create load test: %v", err)
	}

	ctx := context.Background()

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		results := loadTest.RunConcurrentMatchmaking(ctx, 50)
		if results.SuccessRate() < 99.0 {
			b.Errorf("Low success rate: %.1f%%", results.SuccessRate())
		}
	}
}
