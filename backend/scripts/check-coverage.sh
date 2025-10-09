#!/bin/bash
# Coverage Threshold Check - Romanian Septica Backend
# Validates that test coverage meets minimum threshold

set -e

# Configuration
THRESHOLD=${COVERAGE_THRESHOLD:-70}
COVERAGE_FILE="coverage.out"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Coverage Threshold Check ===${NC}"
echo -e "${BLUE}Minimum required: ${THRESHOLD}%${NC}"
echo ""

# Run tests with coverage
echo -e "${BLUE}Running tests with coverage...${NC}"
go test ./... -coverprofile=${COVERAGE_FILE} -covermode=atomic > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Tests failed${NC}"
    exit 1
fi

# Extract coverage percentage
COVERAGE=$(go tool cover -func=${COVERAGE_FILE} | grep total | awk '{print $3}' | sed 's/%//')

# Handle decimal coverage (convert to integer for comparison)
COVERAGE_INT=${COVERAGE%.*}

echo -e "${BLUE}Current coverage: ${COVERAGE}%${NC}"
echo ""

# Compare coverage with threshold
if [ -z "$COVERAGE_INT" ]; then
    echo -e "${RED}✗ Failed to extract coverage percentage${NC}"
    exit 1
fi

if (( $(echo "$COVERAGE_INT < $THRESHOLD" | bc -l 2>/dev/null || [ $COVERAGE_INT -lt $THRESHOLD ] && echo 1 || echo 0) )); then
    echo -e "${RED}✗ Coverage ${COVERAGE}% is below threshold ${THRESHOLD}%${NC}"
    echo ""
    echo -e "${YELLOW}Files with low coverage:${NC}"
    go tool cover -func=${COVERAGE_FILE} | awk -v threshold=$THRESHOLD '$3 < threshold && $3 != "total:" {print "  " $1 " - " $3}'
    echo ""
    echo -e "${YELLOW}Suggestions:${NC}"
    echo "  1. Add unit tests for untested functions"
    echo "  2. Add integration tests for critical paths"
    echo "  3. Focus on files with < 50% coverage first"
    echo ""
    exit 1
else
    echo -e "${GREEN}✓ Coverage ${COVERAGE}% meets threshold ${THRESHOLD}%${NC}"
    echo ""

    # Show breakdown by package
    echo -e "${BLUE}Package Coverage:${NC}"
    go test ./... -coverprofile=${COVERAGE_FILE} -covermode=atomic 2>&1 | grep -E "coverage:|ok" | grep -v "no test files" | while read line; do
        if [[ $line == *"coverage:"* ]]; then
            PKG=$(echo "$line" | awk '{print $2}')
            COV=$(echo "$line" | awk '{print $5}')
            echo -e "  ${GREEN}${COV}${NC} - ${PKG}"
        fi
    done
    echo ""

    # Show top contributors to coverage
    echo -e "${BLUE}Well-tested files (>80% coverage):${NC}"
    go tool cover -func=${COVERAGE_FILE} | awk '$3 > 80.0 && $3 != "total:" {print "  " $1 " - " $3}' | head -10
    echo ""

    exit 0
fi
