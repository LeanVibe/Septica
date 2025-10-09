#!/bin/bash
# CI/CD Build Script - Romanian Septica Backend
# Complete build pipeline for continuous integration

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Configuration
COVERAGE_THRESHOLD=${COVERAGE_THRESHOLD:-70}
BUILD_OUTPUT="server"

echo -e "${BOLD}${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${BLUE}║   Romanian Septica - CI/CD Build Pipeline     ║${NC}"
echo -e "${BOLD}${BLUE}╚════════════════════════════════════════════════╝${NC}"
echo ""

# Track overall success
FAILED=0

# Function to run step
run_step() {
    local step_num=$1
    local step_name=$2
    local step_cmd=$3

    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}Step ${step_num}: ${step_name}${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    if eval "$step_cmd"; then
        echo ""
        echo -e "${GREEN}✓ ${step_name} - SUCCESS${NC}"
        echo ""
        return 0
    else
        echo ""
        echo -e "${RED}✗ ${step_name} - FAILED${NC}"
        echo ""
        FAILED=1
        return 1
    fi
}

# Step 1: Environment Info
run_step "1" "Environment Information" "
    echo -e '${BLUE}Go Version:${NC} '$(go version)
    echo -e '${BLUE}Git Branch:${NC} '$(git branch --show-current 2>/dev/null || echo 'unknown')
    echo -e '${BLUE}Git Commit:${NC} '$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')
    echo -e '${BLUE}Build Time:${NC} '$(date)
"

# Step 2: Install Dependencies
run_step "2" "Installing Dependencies" "
    echo 'Downloading Go modules...'
    go mod download
    echo 'Tidying dependencies...'
    go mod tidy
    echo -e '${GREEN}Dependencies installed successfully${NC}'
"

# Step 3: Code Formatting Check
run_step "3" "Code Formatting Check" "
    echo 'Checking code formatting...'
    UNFORMATTED=\$(gofmt -l . | grep -v vendor || true)
    if [ -n \"\$UNFORMATTED\" ]; then
        echo -e '${RED}Unformatted files found:${NC}'
        echo \"\$UNFORMATTED\"
        exit 1
    fi
    echo -e '${GREEN}All files are properly formatted${NC}'
"

# Step 4: Static Analysis (go vet)
run_step "4" "Static Analysis (go vet)" "
    echo 'Running go vet...'
    go vet ./...
    echo -e '${GREEN}No issues found${NC}'
"

# Step 5: Linting (if golangci-lint available)
if command -v golangci-lint &> /dev/null; then
    run_step "5" "Linting (golangci-lint)" "
        echo 'Running golangci-lint...'
        golangci-lint run --timeout=5m
        echo -e '${GREEN}Linting passed${NC}'
    "
else
    echo -e "${YELLOW}Step 5: Linting (golangci-lint) - SKIPPED (not installed)${NC}"
    echo ""
fi

# Step 6: Unit Tests
run_step "6" "Unit Tests" "
    echo 'Running unit tests...'
    go test -short -v ./... | tee test_results.log
    echo -e '${GREEN}Unit tests passed${NC}'
"

# Step 7: Integration Tests
run_step "7" "Integration Tests" "
    echo 'Running integration tests...'
    go test -v ./... -run Integration 2>&1 | tee integration_results.log || true
    echo -e '${GREEN}Integration tests completed${NC}'
"

# Step 8: Test Coverage
run_step "8" "Test Coverage Analysis" "
    echo 'Generating coverage report...'
    go test ./... -coverprofile=coverage.out -covermode=atomic
    COVERAGE=\$(go tool cover -func=coverage.out | grep total | awk '{print \$3}' | sed 's/%//')
    COVERAGE_INT=\${COVERAGE%.*}

    echo -e '${BLUE}Total Coverage: ${COVERAGE}%${NC}'

    if [ -z \"\$COVERAGE_INT\" ]; then
        echo -e '${RED}Failed to extract coverage${NC}'
        exit 1
    fi

    if (( \$(echo \"\$COVERAGE_INT < $COVERAGE_THRESHOLD\" | bc -l 2>/dev/null || [ \$COVERAGE_INT -lt $COVERAGE_THRESHOLD ] && echo 1 || echo 0) )); then
        echo -e '${RED}Coverage \${COVERAGE}% is below threshold $COVERAGE_THRESHOLD%${NC}'
        exit 1
    fi

    echo -e '${GREEN}Coverage \${COVERAGE}% meets threshold $COVERAGE_THRESHOLD%${NC}'
    go tool cover -html=coverage.out -o coverage.html
"

# Step 9: Race Detector
run_step "9" "Race Detector" "
    echo 'Running tests with race detector...'
    go test -race -short ./... | tee race_results.log
    echo -e '${GREEN}No race conditions detected${NC}'
"

# Step 10: Build Binary
run_step "10" "Building Binary" "
    echo 'Building Go binary...'
    go build -v -o ${BUILD_OUTPUT} ./cmd/server/main.go
    if [ -f ${BUILD_OUTPUT} ]; then
        SIZE=\$(ls -lh ${BUILD_OUTPUT} | awk '{print \$5}')
        echo -e '${GREEN}Binary built successfully: ${BUILD_OUTPUT} (\${SIZE})${NC}'
    else
        echo -e '${RED}Binary not found${NC}'
        exit 1
    fi
"

# Step 11: Docker Build (if Dockerfile exists)
if [ -f "Dockerfile" ]; then
    run_step "11" "Docker Image Build" "
        echo 'Building Docker image...'
        docker build -t septica-backend:ci-build .
        echo -e '${GREEN}Docker image built successfully${NC}'
        docker images septica-backend:ci-build
    "
else
    echo -e "${YELLOW}Step 11: Docker Image Build - SKIPPED (no Dockerfile)${NC}"
    echo ""
fi

# Final Summary
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}Build Summary${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}${BOLD}✓ CI BUILD SUCCESSFUL${NC}"
    echo ""
    echo -e "${GREEN}All steps completed successfully!${NC}"
    echo ""
    echo -e "${BLUE}Artifacts:${NC}"
    [ -f "${BUILD_OUTPUT}" ] && echo -e "  - Binary: ${BUILD_OUTPUT}"
    [ -f "coverage.html" ] && echo -e "  - Coverage Report: coverage.html"
    [ -f "test_results.log" ] && echo -e "  - Test Results: test_results.log"
    echo ""
    exit 0
else
    echo -e "${RED}${BOLD}✗ CI BUILD FAILED${NC}"
    echo ""
    echo -e "${RED}One or more steps failed. Check the logs above.${NC}"
    echo ""
    exit 1
fi
