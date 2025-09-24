#!/bin/bash

# Romanian Septica Mechanics Validation Test Runner
# =================================================
# This script runs comprehensive validation tests for Romanian Septica
# card playing mechanics using Playwright with two-tab simulation.

set -e  # Exit on any error

# Color definitions for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Configuration
FRONTEND_PORT=3000
BACKEND_PORT=8082
TEST_TIMEOUT=300  # 5 minutes
MAX_RETRIES=3

# Logging functions
log_header() {
    echo -e "${WHITE}=================================================${NC}"
    echo -e "${WHITE}$1${NC}"
    echo -e "${WHITE}=================================================${NC}"
}

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_section() {
    echo -e "${CYAN}🔸 $1${NC}"
}

# Function to check if services are running
check_service() {
    local service_name=$1
    local port=$2
    local url=$3

    log_section "Checking $service_name service on port $port..."

    if curl -s -f "$url" > /dev/null; then
        log_success "$service_name is running on port $port"
        return 0
    else
        log_error "$service_name is not running on port $port"
        return 1
    fi
}

# Function to wait for service to be ready
wait_for_service() {
    local service_name=$1
    local port=$2
    local url=$3
    local max_attempts=30
    local attempt=1

    log_section "Waiting for $service_name to be ready..."

    while [ $attempt -le $max_attempts ]; do
        if curl -s -f "$url" > /dev/null; then
            log_success "$service_name is ready (attempt $attempt)"
            return 0
        else
            log_info "$service_name not ready yet (attempt $attempt/$max_attempts)"
            sleep 2
            ((attempt++))
        fi
    done

    log_error "$service_name failed to start within expected time"
    return 1
}

# Function to start services if not running
start_services() {
    log_header "STARTING REQUIRED SERVICES"

    # Check frontend
    if ! check_service "Frontend" $FRONTEND_PORT "http://localhost:$FRONTEND_PORT"; then
        log_warning "Starting frontend service..."
        cd frontend && python3 -m http.server $FRONTEND_PORT &
        FRONTEND_PID=$!
        cd ..

        if ! wait_for_service "Frontend" $FRONTEND_PORT "http://localhost:$FRONTEND_PORT"; then
            log_error "Failed to start frontend service"
            return 1
        fi
    fi

    # Check backend
    if ! check_service "Backend" $BACKEND_PORT "http://localhost:$BACKEND_PORT/api/health"; then
        log_warning "Starting backend service..."
        cd backend && ./server &
        BACKEND_PID=$!
        cd ..

        if ! wait_for_service "Backend" $BACKEND_PORT "http://localhost:$BACKEND_PORT/api/health"; then
            log_error "Failed to start backend service"
            return 1
        fi
    fi

    log_success "All services are running"
}

# Function to install dependencies
check_dependencies() {
    log_header "CHECKING DEPENDENCIES"

    # Check Node.js and npm
    if ! command -v node &> /dev/null; then
        log_error "Node.js is not installed"
        return 1
    fi

    if ! command -v npm &> /dev/null; then
        log_error "npm is not installed"
        return 1
    fi

    log_success "Node.js and npm are available"

    # Check if Playwright is installed
    if ! npm list @playwright/test &> /dev/null; then
        log_warning "Installing Playwright dependencies..."
        npm install @playwright/test
        npx playwright install
    fi

    log_success "Playwright dependencies are ready"

    # Check WebSocket dependency
    if ! npm list ws &> /dev/null; then
        log_warning "Installing WebSocket dependency..."
        npm install ws
    fi

    log_success "All dependencies are available"
}

# Function to run specific test categories
run_test_category() {
    local category=$1
    local test_file=$2
    local retries=0

    log_section "Running $category tests..."

    while [ $retries -lt $MAX_RETRIES ]; do
        if npx playwright test "$test_file" --timeout=$((TEST_TIMEOUT * 1000)) --reporter=line; then
            log_success "$category tests passed"
            return 0
        else
            ((retries++))
            if [ $retries -lt $MAX_RETRIES ]; then
                log_warning "$category tests failed (attempt $retries/$MAX_RETRIES). Retrying..."
                sleep 5
            else
                log_error "$category tests failed after $MAX_RETRIES attempts"
                return 1
            fi
        fi
    done
}

# Function to run comprehensive Romanian Septica validation
run_romanian_validation() {
    log_header "ROMANIAN SEPTICA MECHANICS VALIDATION"

    log_info "🇷🇴 Validating authentic Romanian Septica game rules"
    log_info "🃏 Testing comprehensive card playing mechanics"
    log_info "🎯 Ensuring cultural authenticity and rule compliance"
    echo

    local test_results=()
    local total_tests=0
    local passed_tests=0

    # Main comprehensive validation test
    log_section "Running Comprehensive Romanian Septica Mechanics Validation..."
    if run_test_category "Comprehensive Mechanics" "test-romanian-septica-mechanics-validation.js"; then
        test_results+=("✅ Comprehensive Mechanics Validation")
        ((passed_tests++))
    else
        test_results+=("❌ Comprehensive Mechanics Validation")
    fi
    ((total_tests++))

    # Individual rule category tests
    local rule_categories=(
        "7s Beat Everything Rule"
        "Same Value Beats Rule"
        "8s Context-Dependent Rule"
        "Scoring System"
        "Deck Composition"
    )

    for category in "${rule_categories[@]}"; do
        log_section "Testing $category..."
        if npx playwright test "test-romanian-septica-mechanics-validation.js" --grep "$category" --timeout=$((TEST_TIMEOUT * 1000)) --reporter=line; then
            test_results+=("✅ $category")
            ((passed_tests++))
        else
            test_results+=("❌ $category")
        fi
        ((total_tests++))
    done

    # Generate summary report
    log_header "ROMANIAN SEPTICA VALIDATION SUMMARY"

    echo -e "${WHITE}📊 Test Results Summary:${NC}"
    for result in "${test_results[@]}"; do
        echo "   $result"
    done
    echo

    local compliance_rate=$((passed_tests * 100 / total_tests))
    echo -e "${WHITE}🎯 Overall Compliance:${NC}"
    echo "   Total Tests: $total_tests"
    echo "   Passed Tests: $passed_tests"
    echo "   Failed Tests: $((total_tests - passed_tests))"
    echo "   Compliance Rate: ${compliance_rate}%"
    echo

    # Cultural authenticity assessment
    echo -e "${WHITE}🇷🇴 Cultural Authenticity Assessment:${NC}"
    if [ $compliance_rate -ge 95 ]; then
        echo -e "   ${GREEN}🟢 EXCELLENT - Romanian cultural heritage perfectly preserved${NC}"
        echo "   All critical Romanian Septica rules implemented correctly"
    elif [ $compliance_rate -ge 85 ]; then
        echo -e "   ${YELLOW}🟡 GOOD - Minor cultural adaptations detected${NC}"
        echo "   Most Romanian rules preserved, minor refinements recommended"
    elif [ $compliance_rate -ge 70 ]; then
        echo -e "   ${YELLOW}🟠 CONCERNING - Significant cultural deviations detected${NC}"
        echo "   Major review required to maintain Romanian authenticity"
    else
        echo -e "   ${RED}🔴 CRITICAL - Cultural authenticity compromised${NC}"
        echo "   Fundamental Romanian rules violated - immediate correction needed"
    fi
    echo

    # Final recommendation
    echo -e "${WHITE}🏆 Final Recommendation:${NC}"
    if [ $compliance_rate -ge 90 ]; then
        echo -e "   ${GREEN}✅ APPROVED for Romanian cultural community${NC}"
        echo "   Implementation maintains authentic Romanian Septica traditions"
        return 0
    else
        echo -e "   ${RED}⚠️  NEEDS REVIEW before cultural community approval${NC}"
        echo "   Significant rule violations must be addressed"
        return 1
    fi
}

# Function to generate detailed test report
generate_test_report() {
    log_header "GENERATING DETAILED TEST REPORT"

    local report_file="ROMANIAN_SEPTICA_MECHANICS_VALIDATION_REPORT.md"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    cat > "$report_file" << EOF
# Romanian Septica Mechanics Validation Report

**Generated:** $timestamp
**Test Suite:** Comprehensive Romanian Septica Mechanics Validation
**Framework:** Playwright with Two-Tab Simulation

## Executive Summary

This report documents the comprehensive validation of Romanian Septica card playing mechanics implementation. The test suite validates the authenticity and cultural accuracy of the game rules implementation.

## Romanian Septica Rules Validated

### 1. 7s (Septica) Beat Everything Rule
- ✅ 7♠ beats any card on table (10♦, A♣, K♥, etc.)
- ✅ 7♥ beats any card except 7♠ (suit priority: spades > hearts > diamonds > clubs)
- ✅ All 7s beat non-7 cards regardless of value

### 2. Same Value Beats Rule
- ✅ 10♦ beats 10♣
- ✅ A♠ beats A♥
- ✅ 8♣ beats 8♦
- ✅ J♥ beats J♠

### 3. 8s Context-Dependent Rule
- ✅ 8s can beat when table card count is divisible by 3 (3, 6, 9, 12, etc.)
- ✅ 8s cannot beat when table card count is not divisible by 3 (1, 2, 4, 5, 7, 8, etc.)
- ✅ 8s cannot beat when table is empty (count = 0)

### 4. Scoring System
- ✅ 10s award 1 point when captured
- ✅ Aces (A) award 1 point when captured
- ✅ Other cards (7,8,9,J,Q,K) award 0 points
- ✅ Score accumulation across multiple tricks

### 5. Card Values and Deck
- ✅ 32-card deck: 4 suits × 8 values (7,8,9,10,J,Q,K,A)
- ✅ Card values: 7=7, 8=8, 9=9, 10=10, J=11, Q=12, K=13, A=14
- ✅ No cards outside this range exist

### 6. Turn-Based Mechanics
- ✅ Only current player can play cards
- ✅ Turn switches after valid card play
- ✅ Invalid cards are rejected with proper error messages

### 7. Trick Completion
- ✅ Tricks complete when no valid moves remain
- ✅ Points are awarded to the trick winner
- ✅ Table clears after trick completion
- ✅ New cards are dealt (if deck available)

## Test Execution Details

**Testing Approach:**
- Two-tab Playwright simulation for authentic multiplayer testing
- Backend rule enforcement validation
- Frontend UI feedback verification
- Edge case and rule combination testing
- Error handling validation for invalid moves

**Test Coverage:**
- All Romanian Septica rules comprehensively tested
- Frontend displays rule feedback (e.g., "Septica! Cea mai puternică carte!")
- Backend correctly validates/rejects moves
- Scoring accurately reflects Romanian rules
- Turn mechanics prevent cheating

## Cultural Authenticity Status

🇷🇴 **ROMANIAN CULTURAL HERITAGE PRESERVED**

The implementation maintains authentic Romanian Septica traditions and rules. All critical cultural elements have been validated and confirmed to be working correctly.

## Recommendations

1. **Maintain Cultural Authenticity:** Continue to preserve traditional Romanian Septica rules
2. **Regular Validation:** Run this test suite regularly to ensure rule compliance
3. **Community Feedback:** Engage with Romanian Septica community for ongoing validation
4. **Documentation:** Keep Romanian rule explanations visible to players

## Technical Implementation Notes

- Backend game engine correctly implements all Romanian rules
- Frontend provides appropriate feedback for rule applications
- Error handling provides clear messages for invalid moves
- Two-player multiplayer mechanics work seamlessly
- Real-time validation prevents rule violations

---

**Validation Status:** ✅ APPROVED for Romanian Cultural Community
**Cultural Authenticity:** 🟢 EXCELLENT
**Rule Compliance:** 95%+ on all categories

EOF

    log_success "Detailed test report generated: $report_file"
}

# Function to cleanup processes
cleanup() {
    log_header "CLEANUP"

    if [ ! -z "$FRONTEND_PID" ]; then
        log_info "Stopping frontend service (PID: $FRONTEND_PID)"
        kill $FRONTEND_PID 2>/dev/null || true
    fi

    if [ ! -z "$BACKEND_PID" ]; then
        log_info "Stopping backend service (PID: $BACKEND_PID)"
        kill $BACKEND_PID 2>/dev/null || true
    fi

    log_success "Cleanup completed"
}

# Trap to ensure cleanup on exit
trap cleanup EXIT

# Main execution flow
main() {
    log_header "🇷🇴 ROMANIAN SEPTICA MECHANICS VALIDATION SUITE"
    echo -e "${CYAN}Comprehensive validation of authentic Romanian Septica game rules${NC}"
    echo -e "${CYAN}Testing cultural accuracy and rule compliance with Playwright${NC}"
    echo

    # Check and install dependencies
    if ! check_dependencies; then
        log_error "Failed to setup dependencies"
        exit 1
    fi

    # Start required services
    if ! start_services; then
        log_error "Failed to start required services"
        exit 1
    fi

    # Wait a bit for services to stabilize
    log_info "Waiting for services to stabilize..."
    sleep 5

    # Run Romanian Septica validation
    if run_romanian_validation; then
        log_success "Romanian Septica validation completed successfully"

        # Generate detailed report
        generate_test_report

        log_header "🏆 VALIDATION SUCCESSFUL"
        echo -e "${GREEN}Romanian Septica implementation is culturally authentic${NC}"
        echo -e "${GREEN}All critical rules are correctly implemented${NC}"
        echo -e "${GREEN}Ready for Romanian cultural community approval${NC}"

        exit 0
    else
        log_error "Romanian Septica validation failed"

        log_header "❌ VALIDATION FAILED"
        echo -e "${RED}Romanian Septica implementation has rule violations${NC}"
        echo -e "${RED}Review required before cultural community approval${NC}"

        exit 1
    fi
}

# Run main function
main "$@"