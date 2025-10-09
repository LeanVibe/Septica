#!/bin/bash
# Test Coverage Script - Romanian Septica Backend
# Generates comprehensive coverage reports with summary statistics

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Romanian Septica - Test Coverage Report ===${NC}"
echo ""

# Run tests with coverage
echo -e "${BLUE}Running tests with coverage...${NC}"
go test ./... -coverprofile=coverage.out -covermode=atomic

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Tests failed${NC}"
    exit 1
fi

# Generate HTML coverage report
echo ""
echo -e "${BLUE}Generating HTML coverage report...${NC}"
go tool cover -html=coverage.out -o coverage.html

# Extract coverage summary
echo ""
echo -e "${BLUE}Coverage Summary:${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Get total coverage
TOTAL_COV=$(go tool cover -func=coverage.out | grep total | awk '{print $3}')
echo -e "${GREEN}Total Coverage: ${TOTAL_COV}${NC}"

echo ""
echo -e "${BLUE}Top 10 Files by Coverage:${NC}"
go tool cover -func=coverage.out | sort -k3 -nr | head -10 | while read line; do
    FILE=$(echo "$line" | awk '{print $1}' | sed 's/.*\///')
    FUNC=$(echo "$line" | awk '{print $2}')
    COV=$(echo "$line" | awk '{print $3}')

    if [ "$COV" != "total:" ]; then
        echo -e "  ${GREEN}${COV}${NC} - ${FILE}:${FUNC}"
    fi
done

echo ""
echo -e "${BLUE}Bottom 10 Files by Coverage:${NC}"
go tool cover -func=coverage.out | grep -v total | sort -k3 -n | head -10 | while read line; do
    FILE=$(echo "$line" | awk '{print $1}' | sed 's/.*\///')
    FUNC=$(echo "$line" | awk '{print $2}')
    COV=$(echo "$line" | awk '{print $3}')

    echo -e "  ${YELLOW}${COV}${NC} - ${FILE}:${FUNC}"
done

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ Coverage report generated: coverage.html${NC}"
echo -e "${BLUE}  Open with: open coverage.html${NC}"
echo ""

# Package-level coverage summary
echo -e "${BLUE}Package Coverage Breakdown:${NC}"
go test ./... -coverprofile=coverage.out -covermode=atomic 2>&1 | grep -E "coverage:|ok" | grep -v "no test files" | while read line; do
    if [[ $line == *"coverage:"* ]]; then
        PKG=$(echo "$line" | awk '{print $2}')
        COV=$(echo "$line" | awk '{print $5}')
        echo -e "  ${GREEN}${COV}${NC} - ${PKG}"
    fi
done

echo ""
echo -e "${GREEN}✓ Test coverage analysis complete${NC}"
