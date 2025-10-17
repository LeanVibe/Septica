package load

import (
	"time"
)

// LoadTestResults contains aggregated results from a load test run
type LoadTestResults struct {
	TestName      string
	StartTime     time.Time
	EndTime       time.Time
	Duration      time.Duration
	TotalUsers    int
	SuccessCount  int
	FailureCount  int
	Metrics       *PerformanceMetrics
	Errors        []string
}

// PerformanceMetrics tracks key performance indicators
type PerformanceMetrics struct {
	// Matchmaking metrics
	MatchmakingLatency *LatencyMetrics
	QueueWaitTime      *LatencyMetrics
	MatchSuccessRate   float64

	// AI metrics
	AIDeploymentLatency   *LatencyMetrics
	AIDeploymentSuccess   float64
	AIMoveGenerationTime  *LatencyMetrics

	// Database metrics
	DatabaseQueryTime     *LatencyMetrics
	ConnectionPoolUsage   *ResourceMetrics
	TransactionSuccessRate float64

	// WebSocket metrics
	WSConnectionTime    *LatencyMetrics
	WSMessageLatency    *LatencyMetrics
	WSConnectionSuccess float64

	// System metrics
	MemoryUsageMB    *ResourceMetrics
	CPUUsagePercent  *ResourceMetrics
	ActiveGoroutines *ResourceMetrics
}

// LatencyMetrics contains latency distribution statistics
type LatencyMetrics struct {
	Min        time.Duration
	Max        time.Duration
	Mean       time.Duration
	P50        time.Duration // Median
	P95        time.Duration
	P99        time.Duration
	SampleSize int
}

// ResourceMetrics tracks resource usage over time
type ResourceMetrics struct {
	Min     float64
	Max     float64
	Mean    float64
	Current float64
}

// LoadScenario defines a load test configuration
type LoadScenario struct {
	Name           string
	ConcurrentUsers int
	Duration       time.Duration
	RampUpTime     time.Duration
	Operations     []Operation
}

// Operation represents an action users perform in the scenario
type Operation struct {
	Name       string
	Weight     int           // Relative frequency (higher = more frequent)
	MinDelay   time.Duration // Minimum delay before next operation
	MaxDelay   time.Duration // Maximum delay before next operation
	Execute    func() error  // Function to execute
}

// TestReport contains formatted test results for output
type TestReport struct {
	Results      *LoadTestResults
	PassedChecks []string
	FailedChecks []string
	Recommendations []string
}

// NewLoadTestResults creates an initialized LoadTestResults
func NewLoadTestResults(testName string, totalUsers int) *LoadTestResults {
	return &LoadTestResults{
		TestName:   testName,
		StartTime:  time.Now(),
		TotalUsers: totalUsers,
		Metrics:    NewPerformanceMetrics(),
		Errors:     make([]string, 0),
	}
}

// NewPerformanceMetrics creates an initialized PerformanceMetrics
func NewPerformanceMetrics() *PerformanceMetrics {
	return &PerformanceMetrics{
		MatchmakingLatency:    &LatencyMetrics{},
		QueueWaitTime:         &LatencyMetrics{},
		AIDeploymentLatency:   &LatencyMetrics{},
		AIMoveGenerationTime:  &LatencyMetrics{},
		DatabaseQueryTime:     &LatencyMetrics{},
		ConnectionPoolUsage:   &ResourceMetrics{},
		WSConnectionTime:      &LatencyMetrics{},
		WSMessageLatency:      &LatencyMetrics{},
		MemoryUsageMB:         &ResourceMetrics{},
		CPUUsagePercent:       &ResourceMetrics{},
		ActiveGoroutines:      &ResourceMetrics{},
	}
}

// Complete marks the test as finished and calculates duration
func (r *LoadTestResults) Complete() {
	r.EndTime = time.Now()
	r.Duration = r.EndTime.Sub(r.StartTime)
}

// SuccessRate calculates the overall success rate
func (r *LoadTestResults) SuccessRate() float64 {
	total := r.SuccessCount + r.FailureCount
	if total == 0 {
		return 0.0
	}
	return float64(r.SuccessCount) / float64(total) * 100.0
}
