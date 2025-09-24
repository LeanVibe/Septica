# Romanian Septica Integration Tests Makefile

.PHONY: test test-verbose test-quick test-critical clean setup help

# Default target
help:
	@echo "🎯 Romanian Septica Integration Tests"
	@echo "====================================="
	@echo ""
	@echo "Available targets:"
	@echo "  test         - Run all integration tests"
	@echo "  test-verbose - Run tests with verbose output"
	@echo "  test-quick   - Run only critical integration tests"
	@echo "  test-critical- Run critical tests that must pass"
	@echo "  setup        - Setup test environment"
	@echo "  clean        - Clean test artifacts"
	@echo "  deps         - Install test dependencies"
	@echo "  help         - Show this help message"

# Setup test environment
setup:
	@echo "🔧 Setting up integration test environment..."
	@cd ../../ && go mod tidy
	@go mod init septica-backend/tests/integration 2>/dev/null || true
	@go mod tidy
	@echo "✅ Test environment ready"

# Install dependencies
deps: setup
	@echo "📦 Installing test dependencies..."
	@go get github.com/gorilla/websocket@latest
	@go get github.com/gin-gonic/gin@latest
	@go get github.com/stretchr/testify@latest
	@go get gorm.io/driver/sqlite@latest
	@go get gorm.io/gorm@latest
	@echo "✅ Dependencies installed"

# Run all integration tests
test: deps
	@echo "🎯 Running Romanian Septica Integration Tests..."
	@echo "=============================================="
	@go test -v ./... -timeout 30m -count=1
	@echo ""
	@echo "📊 Integration Test Summary:"
	@echo "✅ Complete authentic game flows tested"
	@echo "✅ Multi-player scenarios validated"
	@echo "✅ Error handling verified"
	@echo "✅ Romanian cultural authenticity preserved"

# Run tests with verbose output and detailed logging
test-verbose: deps
	@echo "🎯 Running Verbose Integration Tests..."
	@go test -v ./... -timeout 30m -count=1 -args -test.v=true
	@go run run_integration_tests.go run

# Run only critical tests that must pass for production
test-critical: deps
	@echo "🚨 Running Critical Integration Tests..."
	@go test -v -run "TestComplete|TestMultiPlayer|TestAuthenticRule" ./... -timeout 15m
	@echo "✅ Critical tests completed"

# Run quick smoke tests
test-quick: deps
	@echo "⚡ Running Quick Integration Tests..."
	@go test -v -run "TestCompleteAuthenticGameFlow" ./... -timeout 10m
	@echo "✅ Quick tests completed"

# Test specific scenarios
test-flow:
	@echo "🎮 Testing Game Flow Integration..."
	@go test -v -run "TestCompleteAuthenticGameFlow" ./...

test-multiplayer:
	@echo "👥 Testing Multi-Player Integration..."
	@go test -v -run "TestMultiPlayerAuthenticGameFlow" ./...

test-rules:
	@echo "📜 Testing Romanian Rules Integration..."
	@go test -v -run "TestAuthenticRuleValidationIntegration" ./...

test-errors:
	@echo "⚠️  Testing Error Scenarios..."
	@go test -v -run "TestAuthenticGameErrorScenarios" ./...

test-compatibility:
	@echo "🔄 Testing Backward Compatibility..."
	@go test -v -run "TestBackwardCompatibilityIntegration" ./...

# Performance and stress tests
test-performance:
	@echo "🚀 Running Performance Integration Tests..."
	@go test -v -run "Performance" ./... -timeout 20m
	@echo "📊 Performance tests completed"

# Run tests with coverage
test-coverage: deps
	@echo "📊 Running Integration Tests with Coverage..."
	@go test -v -coverprofile=integration_coverage.out ./...
	@go tool cover -html=integration_coverage.out -o integration_coverage.html
	@echo "✅ Coverage report generated: integration_coverage.html"

# Run tests in parallel for speed
test-parallel: deps
	@echo "⚡ Running Parallel Integration Tests..."
	@go test -v -parallel 4 ./... -timeout 20m

# Validate test environment and dependencies
validate:
	@echo "🔍 Validating test environment..."
	@go version
	@go mod verify
	@echo "✅ Environment validated"

# Clean test artifacts
clean:
	@echo "🧹 Cleaning test artifacts..."
	@rm -f integration_coverage.out integration_coverage.html
	@rm -f *.test
	@rm -rf test_results/
	@go clean -testcache
	@echo "✅ Artifacts cleaned"

# Run integration tests in Docker (if available)
test-docker:
	@echo "🐳 Running Integration Tests in Docker..."
	@if command -v docker >/dev/null 2>&1; then \
		docker run --rm -v $(PWD)/../..:/app -w /app/tests/integration golang:1.21 make test; \
	else \
		echo "⚠️  Docker not available, running locally..."; \
		make test; \
	fi

# Generate integration test report
report: test
	@echo "📋 Generating Integration Test Report..."
	@go run run_integration_tests.go run > integration_test_report.log 2>&1 || true
	@echo "✅ Report generated: integration_test_report.log"

# Continuous integration mode
ci: validate test-critical test-coverage
	@echo "🤖 CI Integration Tests completed"
	@if [ -f integration_coverage.out ]; then \
		echo "📊 Coverage:"; \
		go tool cover -func=integration_coverage.out | tail -1; \
	fi

# Development mode - watch for changes and re-run tests
watch:
	@echo "👀 Watching for changes..."
	@if command -v fswatch >/dev/null 2>&1; then \
		fswatch -o . | xargs -n1 -I{} make test-quick; \
	else \
		echo "⚠️  fswatch not available. Install with: brew install fswatch"; \
		echo "Running tests once..."; \
		make test-quick; \
	fi

# Debug mode - run tests with debugging enabled
debug: deps
	@echo "🐛 Running Integration Tests in Debug Mode..."
	@go test -v ./... -timeout 30m -count=1 -args -test.debug=true

# Benchmark integration test performance
benchmark: deps
	@echo "⏱️  Benchmarking Integration Test Performance..."
	@go test -v -bench=. -benchmem ./... -timeout 30m

# Health check - quick validation that system is working
health: deps
	@echo "🩺 Integration Test Health Check..."
	@go test -v -run "TestCompleteAuthenticGameFlow" ./... -timeout 5m
	@echo "✅ System health verified"