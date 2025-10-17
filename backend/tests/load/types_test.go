package load

import (
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
)

func TestNewLoadTestResults(t *testing.T) {
	results := NewLoadTestResults("Test Run", 100)

	assert.Equal(t, "Test Run", results.TestName)
	assert.Equal(t, 100, results.TotalUsers)
	assert.NotNil(t, results.Metrics)
	assert.NotNil(t, results.Errors)
	assert.Empty(t, results.Errors)
	assert.False(t, results.StartTime.IsZero())
}

func TestLoadTestResults_Complete(t *testing.T) {
	results := NewLoadTestResults("Test", 10)
	startTime := results.StartTime

	// Wait a brief moment
	time.Sleep(10 * time.Millisecond)

	results.Complete()

	assert.False(t, results.EndTime.IsZero())
	assert.True(t, results.EndTime.After(startTime))
	assert.True(t, results.Duration > 0)
	assert.True(t, results.Duration >= 10*time.Millisecond)
}

func TestLoadTestResults_SuccessRate(t *testing.T) {
	tests := []struct {
		name         string
		successCount int
		failureCount int
		expectedRate float64
	}{
		{"All successful", 100, 0, 100.0},
		{"All failed", 0, 100, 0.0},
		{"Half successful", 50, 50, 50.0},
		{"75% successful", 75, 25, 75.0},
		{"No operations", 0, 0, 0.0},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			results := NewLoadTestResults("Test", 10)
			results.SuccessCount = tt.successCount
			results.FailureCount = tt.failureCount

			rate := results.SuccessRate()
			assert.Equal(t, tt.expectedRate, rate)
		})
	}
}

func TestNewPerformanceMetrics(t *testing.T) {
	metrics := NewPerformanceMetrics()

	// Verify all nested metrics are initialized
	assert.NotNil(t, metrics.MatchmakingLatency)
	assert.NotNil(t, metrics.QueueWaitTime)
	assert.NotNil(t, metrics.AIDeploymentLatency)
	assert.NotNil(t, metrics.AIMoveGenerationTime)
	assert.NotNil(t, metrics.DatabaseQueryTime)
	assert.NotNil(t, metrics.ConnectionPoolUsage)
	assert.NotNil(t, metrics.WSConnectionTime)
	assert.NotNil(t, metrics.WSMessageLatency)
	assert.NotNil(t, metrics.MemoryUsageMB)
	assert.NotNil(t, metrics.CPUUsagePercent)
	assert.NotNil(t, metrics.ActiveGoroutines)
}

func TestLatencyMetrics_Initialization(t *testing.T) {
	latency := &LatencyMetrics{}

	// All values should be zero-initialized
	assert.Equal(t, time.Duration(0), latency.Min)
	assert.Equal(t, time.Duration(0), latency.Max)
	assert.Equal(t, time.Duration(0), latency.Mean)
	assert.Equal(t, time.Duration(0), latency.P50)
	assert.Equal(t, time.Duration(0), latency.P95)
	assert.Equal(t, time.Duration(0), latency.P99)
	assert.Equal(t, 0, latency.SampleSize)
}

func TestResourceMetrics_Initialization(t *testing.T) {
	resource := &ResourceMetrics{}

	// All values should be zero-initialized
	assert.Equal(t, 0.0, resource.Min)
	assert.Equal(t, 0.0, resource.Max)
	assert.Equal(t, 0.0, resource.Mean)
	assert.Equal(t, 0.0, resource.Current)
}

func TestLoadScenario_Structure(t *testing.T) {
	scenario := &LoadScenario{
		Name:            "Test Scenario",
		ConcurrentUsers: 100,
		Duration:        1 * time.Minute,
		RampUpTime:      10 * time.Second,
		Operations:      []Operation{},
	}

	assert.Equal(t, "Test Scenario", scenario.Name)
	assert.Equal(t, 100, scenario.ConcurrentUsers)
	assert.Equal(t, 1*time.Minute, scenario.Duration)
	assert.Equal(t, 10*time.Second, scenario.RampUpTime)
	assert.NotNil(t, scenario.Operations)
}

func TestOperation_Execution(t *testing.T) {
	executed := false

	op := Operation{
		Name:   "Test Operation",
		Weight: 10,
		Execute: func() error {
			executed = true
			return nil
		},
	}

	assert.Equal(t, "Test Operation", op.Name)
	assert.Equal(t, 10, op.Weight)
	assert.NotNil(t, op.Execute)

	err := op.Execute()
	assert.NoError(t, err)
	assert.True(t, executed)
}
