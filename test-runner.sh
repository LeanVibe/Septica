#!/bin/bash

# ROMANIAN SEPTICA AUTO-MATCHMAKING TEST RUNNER
# ==============================================
# 
# Comprehensive test execution script for the Romanian Septica 
# auto-matchmaking system. Validates the complete workflow:
# "Both tabs click Play → Auto-paired → Complete Romanian Septica game"
#
# Usage:
#   ./test-runner.sh [options]
#
# Options:
#   --quick         Run quick tests only
#   --rules         Run only Romanian rule validation
#   --websocket     Run only WebSocket flow tests
#   --e2e           Run only E2E Playwright tests
#   --performance   Run only performance tests
#   --all           Run all comprehensive tests (default)
#   --help          Show this help message

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
TEST_RESULTS_DIR="$SCRIPT_DIR/test-results"
BACKEND_URL="http://localhost:8080"
FRONTEND_URL="http://localhost:3000"
WEBSOCKET_URL="ws://localhost:8080/ws/connect"

# Test files
TEST_FILES=(
    "test-websocket-matchmaking-flow.js"
    "test-romanian-septica-rules.js"
    "test-auto-matchmaking-e2e.js"
    "run-comprehensive-e2e-tests.js"
)

# Create results directory
mkdir -p "$TEST_RESULTS_DIR"

print_header() {
    echo -e "${BLUE}================================================================${NC}"
    echo -e "${CYAN}🏛️  ROMANIAN SEPTICA AUTO-MATCHMAKING TEST SUITE${NC}"
    echo -e "${BLUE}================================================================${NC}"
    echo -e "${YELLOW}🎮 Testing: Complete auto-matchmaking → full game workflow${NC}"
    echo -e "${YELLOW}🇷🇴 Validating: Authentic Romanian Septica rules & gameplay${NC}"
    echo -e "${BLUE}================================================================${NC}"
    echo ""
}

print_help() {
    echo "Romanian Septica Auto-Matchmaking Test Runner"
    echo ""
    echo "USAGE:"
    echo "  ./test-runner.sh [options]"
    echo ""
    echo "OPTIONS:"
    echo "  --quick         Quick validation tests only"
    echo "  --rules         Romanian Septica rule validation"
    echo "  --websocket     WebSocket message flow validation"
    echo "  --e2e           End-to-end Playwright browser tests"
    echo "  --performance   Performance and stress testing"
    echo "  --all           Complete comprehensive test suite (default)"
    echo "  --help          Show this help message"
    echo ""
    echo "EXAMPLES:"
    echo "  ./test-runner.sh --rules        # Test Romanian game rules only"
    echo "  ./test-runner.sh --e2e          # Test two-tab auto-matchmaking"
    echo "  ./test-runner.sh --all          # Run complete test suite"
    echo ""
    echo "REQUIREMENTS:"
    echo "  - Backend server running on port 8080"
    echo "  - Frontend server running on port 3000"
    echo "  - Node.js with Playwright installed"
    echo "  - PostgreSQL database available"
    echo ""
}

check_system_requirements() {
    echo -e "${CYAN}🔧 Checking system requirements...${NC}"
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        echo -e "${RED}❌ Node.js not found. Please install Node.js${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Node.js: $(node --version)${NC}"
    
    # Check if test files exist
    local missing_files=()
    for file in "${TEST_FILES[@]}"; do
        if [[ ! -f "$SCRIPT_DIR/$file" ]]; then
            missing_files+=("$file")
        fi
    done
    
    if [[ ${#missing_files[@]} -gt 0 ]]; then
        echo -e "${YELLOW}⚠️  Missing test files:${NC}"
        for file in "${missing_files[@]}"; do
            echo -e "${YELLOW}   - $file${NC}"
        done
        echo -e "${BLUE}ℹ️  Some tests will be skipped${NC}"
    fi
    
    echo ""
}

check_services() {
    echo -e "${CYAN}🏥 Checking service availability...${NC}"
    
    # Check backend
    if curl -s "$BACKEND_URL/health" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Backend server: Available at $BACKEND_URL${NC}"
    else
        echo -e "${YELLOW}⚠️  Backend server: Not available at $BACKEND_URL${NC}"
        echo -e "${YELLOW}   Start backend with: DATABASE_URL='...' ./backend/server${NC}"
    fi
    
    # Check frontend
    if curl -s "$FRONTEND_URL" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Frontend server: Available at $FRONTEND_URL${NC}"
    else
        echo -e "${YELLOW}⚠️  Frontend server: Not available at $FRONTEND_URL${NC}"
        echo -e "${YELLOW}   Start frontend with: cd frontend && python3 -m http.server 3000${NC}"
    fi
    
    echo ""
}

run_test() {
    local test_file="$1"
    local test_name="$2"
    local description="$3"
    
    echo -e "${PURPLE}🧪 Running: $test_name${NC}"
    echo -e "${CYAN}   $description${NC}"
    
    if [[ ! -f "$SCRIPT_DIR/$test_file" ]]; then
        echo -e "${YELLOW}⚠️  Test file not found: $test_file${NC}"
        return 1
    fi
    
    local start_time=$(date +%s)
    local log_file="$TEST_RESULTS_DIR/$(basename "$test_file" .js).log"
    
    # Run the test and capture output
    if node "$SCRIPT_DIR/$test_file" > "$log_file" 2>&1; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        echo -e "${GREEN}✅ PASSED: $test_name (${duration}s)${NC}"
        return 0
    else
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        echo -e "${RED}❌ FAILED: $test_name (${duration}s)${NC}"
        echo -e "${YELLOW}📄 Log saved to: $log_file${NC}"
        return 1
    fi
}

run_websocket_tests() {
    echo -e "${BLUE}🔌 WEBSOCKET MESSAGE FLOW VALIDATION${NC}"
    echo -e "${BLUE}======================================${NC}"
    
    run_test "test-websocket-matchmaking-flow.js" \
             "WebSocket Message Flow" \
             "Validates real-time communication protocol for auto-matchmaking"
    
    return $?
}

run_rule_tests() {
    echo -e "${BLUE}🇷🇴 ROMANIAN SEPTICA RULE VALIDATION${NC}"
    echo -e "${BLUE}=====================================${NC}"
    
    run_test "test-romanian-septica-rules.js" \
             "Romanian Rules Compliance" \
             "Validates cultural authenticity and game rule accuracy"
    
    return $?
}

run_e2e_tests() {
    echo -e "${BLUE}🎮 END-TO-END AUTO-MATCHMAKING TESTS${NC}"
    echo -e "${BLUE}=====================================${NC}"
    
    run_test "test-auto-matchmaking-e2e.js" \
             "Auto-Matchmaking E2E" \
             "Two-tab browser workflow: Play button → Auto-paired → Full game"
    
    return $?
}

run_performance_tests() {
    echo -e "${BLUE}📊 PERFORMANCE & STRESS TESTING${NC}"
    echo -e "${BLUE}================================${NC}"
    
    if [[ -f "$SCRIPT_DIR/test-performance-stress.js" ]]; then
        run_test "test-performance-stress.js" \
                 "Performance & Stress" \
                 "Load testing and performance validation"
    else
        echo -e "${YELLOW}⚠️  Performance tests not available${NC}"
        return 1
    fi
}

run_comprehensive_tests() {
    echo -e "${BLUE}🏛️  COMPREHENSIVE TEST SUITE${NC}"
    echo -e "${BLUE}=============================${NC}"
    
    run_test "run-comprehensive-e2e-tests.js" \
             "Comprehensive E2E Suite" \
             "Complete orchestrated test execution with detailed reporting"
    
    return $?
}

run_quick_tests() {
    echo -e "${CYAN}⚡ Running quick validation tests...${NC}"
    echo ""
    
    local passed=0
    local total=2
    
    # Quick rule validation
    if run_rule_tests; then
        ((passed++))
    fi
    
    echo ""
    
    # Quick WebSocket test
    if run_websocket_tests; then
        ((passed++))
    fi
    
    echo ""
    echo -e "${BLUE}⚡ Quick Test Summary: $passed/$total tests passed${NC}"
    
    if [[ $passed -eq $total ]]; then
        return 0
    else
        return 1
    fi
}

generate_summary_report() {
    local passed_tests="$1"
    local total_tests="$2"
    local start_time="$3"
    
    local end_time=$(date +%s)
    local total_duration=$((end_time - start_time))
    local pass_rate=$(( passed_tests * 100 / total_tests ))
    
    echo ""
    echo -e "${BLUE}================================================================${NC}"
    echo -e "${CYAN}📊 ROMANIAN SEPTICA TEST EXECUTION SUMMARY${NC}"
    echo -e "${BLUE}================================================================${NC}"
    echo ""
    echo -e "${CYAN}🎯 Test Results:${NC}"
    echo -e "   📋 Total Tests: $total_tests"
    echo -e "   ✅ Passed: $passed_tests"
    echo -e "   ❌ Failed: $((total_tests - passed_tests))"
    echo -e "   📈 Pass Rate: $pass_rate%"
    echo -e "   ⏱️  Duration: ${total_duration}s"
    echo ""
    
    echo -e "${CYAN}📂 Test Results Directory:${NC}"
    echo -e "   📁 $TEST_RESULTS_DIR"
    echo ""
    
    if [[ -d "$TEST_RESULTS_DIR" ]] && [[ $(ls -A "$TEST_RESULTS_DIR" 2>/dev/null | wc -l) -gt 0 ]]; then
        echo -e "${CYAN}📄 Generated Files:${NC}"
        for file in "$TEST_RESULTS_DIR"/*; do
            if [[ -f "$file" ]]; then
                echo -e "   📄 $(basename "$file")"
            fi
        done
        echo ""
    fi
    
    # Production readiness assessment
    echo -e "${CYAN}🚀 Production Readiness Assessment:${NC}"
    if [[ $pass_rate -ge 90 ]]; then
        echo -e "   🟢 ${GREEN}EXCELLENT${NC} - System ready for production deployment"
        echo -e "   ✅ All critical components validated"
        echo -e "   🎮 Romanian Septica auto-matchmaking fully functional"
    elif [[ $pass_rate -ge 70 ]]; then
        echo -e "   🟡 ${YELLOW}GOOD${NC} - System approaching production readiness"
        echo -e "   ⚠️  Address remaining issues before deployment"
        echo -e "   📋 Focus on failed test categories"
    else
        echo -e "   🔴 ${RED}NEEDS WORK${NC} - System requires significant improvements"
        echo -e "   🛠️  Major issues must be resolved"
        echo -e "   ⏱️  Delay production deployment"
    fi
    echo ""
    
    echo -e "${CYAN}🎮 Auto-Matchmaking Feature Status:${NC}"
    echo -e "   🔌 WebSocket Communication: $(test_status_from_logs 'WebSocket')"
    echo -e "   🇷🇴 Romanian Rule Compliance: $(test_status_from_logs 'Romanian')"
    echo -e "   🎯 Auto-Pairing Mechanism: $(test_status_from_logs 'Auto-Pairing')"
    echo -e "   🎮 Complete Game Workflow: $(test_status_from_logs 'E2E')"
    echo ""
    
    echo -e "${BLUE}================================================================${NC}"
    
    if [[ $pass_rate -ge 70 ]]; then
        echo -e "${GREEN}🏁 ROMANIAN SEPTICA AUTO-MATCHMAKING VALIDATION COMPLETE!${NC}"
        return 0
    else
        echo -e "${RED}🏁 ROMANIAN SEPTICA AUTO-MATCHMAKING VALIDATION FAILED!${NC}"
        return 1
    fi
}

test_status_from_logs() {
    local keyword="$1"
    
    # Check log files for test results
    if grep -q "PASS.*$keyword" "$TEST_RESULTS_DIR"/*.log 2>/dev/null; then
        echo -e "${GREEN}✅ WORKING${NC}"
    elif grep -q "FAIL.*$keyword" "$TEST_RESULTS_DIR"/*.log 2>/dev/null; then
        echo -e "${RED}❌ ISSUES${NC}"
    else
        echo -e "${YELLOW}⚪ NOT TESTED${NC}"
    fi
}

main() {
    local start_time=$(date +%s)
    
    print_header
    
    # Parse command line arguments
    local run_mode="all"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --quick)
                run_mode="quick"
                shift
                ;;
            --rules)
                run_mode="rules"
                shift
                ;;
            --websocket)
                run_mode="websocket"
                shift
                ;;
            --e2e)
                run_mode="e2e"
                shift
                ;;
            --performance)
                run_mode="performance"
                shift
                ;;
            --all)
                run_mode="all"
                shift
                ;;
            --help)
                print_help
                exit 0
                ;;
            *)
                echo -e "${RED}Unknown option: $1${NC}"
                print_help
                exit 1
                ;;
        esac
    done
    
    check_system_requirements
    check_services
    
    local passed_tests=0
    local total_tests=0
    
    case $run_mode in
        quick)
            total_tests=2
            if run_quick_tests; then
                passed_tests=2
            fi
            ;;
        rules)
            total_tests=1
            if run_rule_tests; then
                passed_tests=1
            fi
            ;;
        websocket)
            total_tests=1
            if run_websocket_tests; then
                passed_tests=1
            fi
            ;;
        e2e)
            total_tests=1
            if run_e2e_tests; then
                passed_tests=1
            fi
            ;;
        performance)
            total_tests=1
            if run_performance_tests; then
                passed_tests=1
            fi
            ;;
        all)
            echo -e "${CYAN}🏛️  Running comprehensive test suite...${NC}"
            echo ""
            
            total_tests=4
            
            if run_rule_tests; then
                ((passed_tests++))
            fi
            echo ""
            
            if run_websocket_tests; then
                ((passed_tests++))
            fi
            echo ""
            
            if run_e2e_tests; then
                ((passed_tests++))
            fi
            echo ""
            
            if run_comprehensive_tests; then
                ((passed_tests++))
            fi
            ;;
    esac
    
    generate_summary_report "$passed_tests" "$total_tests" "$start_time"
    
    # Exit with appropriate code
    if [[ $passed_tests -eq $total_tests ]]; then
        exit 0
    else
        exit 1
    fi
}

# Run main function with all arguments
main "$@"