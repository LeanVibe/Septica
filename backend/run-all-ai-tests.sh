#!/bin/bash

# Romanian Septica AI Test Suite Master Runner
# This script executes all AI tests and generates comprehensive reports

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
BACKEND_PORT=8085
FRONTEND_PORT=3000
TEST_TIMEOUT=300  # 5 minutes per test suite
REPORT_DIR="./test-reports"
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")

echo -e "${CYAN}🎯 Romanian Septica AI Comprehensive Test Suite Runner${NC}"
echo -e "${CYAN}=========================================================${NC}"
echo
echo -e "${BLUE}Configuration:${NC}"
echo -e "  Backend Port: ${BACKEND_PORT}"
echo -e "  Frontend Port: ${FRONTEND_PORT}"
echo -e "  Test Timeout: ${TEST_TIMEOUT}s per suite"
echo -e "  Report Directory: ${REPORT_DIR}"
echo -e "  Timestamp: ${TIMESTAMP}"
echo

# Create report directory
mkdir -p "${REPORT_DIR}"

# Initialize summary variables
declare -A test_results
declare -A test_durations
total_suites=0
passed_suites=0
failed_suites=0
start_time=$(date +%s)

# Function to run a single test suite
run_test_suite() {
    local suite_name="$1"
    local command="$2"
    local description="$3"

    echo -e "${YELLOW}🚀 Running: ${suite_name}${NC}"
    echo -e "${BLUE}   Description: ${description}${NC}"
    echo -e "${BLUE}   Command: ${command}${NC}"
    echo

    local suite_start=$(date +%s)
    local log_file="${REPORT_DIR}/${suite_name}-${TIMESTAMP}.log"

    # Run the test with timeout
    if timeout "${TEST_TIMEOUT}" bash -c "${command}" > "${log_file}" 2>&1; then
        local suite_end=$(date +%s)
        local duration=$((suite_end - suite_start))

        test_results["${suite_name}"]="PASS"
        test_durations["${suite_name}"]="${duration}"
        ((passed_suites++))

        echo -e "${GREEN}✅ ${suite_name} PASSED${NC} (${duration}s)"
        echo -e "${GREEN}   Log: ${log_file}${NC}"
    else
        local suite_end=$(date +%s)
        local duration=$((suite_end - suite_start))

        test_results["${suite_name}"]="FAIL"
        test_durations["${suite_name}"]="${duration}"
        ((failed_suites++))

        echo -e "${RED}❌ ${suite_name} FAILED${NC} (${duration}s)"
        echo -e "${RED}   Log: ${log_file}${NC}"
        echo -e "${YELLOW}   Showing last 10 lines of error log:${NC}"
        tail -10 "${log_file}" | sed 's/^/   /'
    fi

    ((total_suites++))
    echo
}

# Function to check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}🔍 Checking Prerequisites...${NC}"

    # Check if Go is installed
    if ! command -v go &> /dev/null; then
        echo -e "${RED}❌ Go is not installed or not in PATH${NC}"
        exit 1
    fi

    echo -e "${GREEN}✅ Go $(go version | cut -d' ' -f3) detected${NC}"

    # Check if Node.js is installed (for E2E tests)
    if ! command -v node &> /dev/null; then
        echo -e "${YELLOW}⚠️  Node.js not found - E2E tests may fail${NC}"
    else
        echo -e "${GREEN}✅ Node.js $(node --version) detected${NC}"
    fi

    # Check if backend server is running
    if curl -s "http://localhost:${BACKEND_PORT}/health" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Backend server running on port ${BACKEND_PORT}${NC}"
    else
        echo -e "${YELLOW}⚠️  Backend server not detected on port ${BACKEND_PORT}${NC}"
        echo -e "${YELLOW}   Some tests may fail without running backend${NC}"
    fi

    # Check if frontend is running
    if curl -s "http://localhost:${FRONTEND_PORT}" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Frontend server running on port ${FRONTEND_PORT}${NC}"
    else
        echo -e "${YELLOW}⚠️  Frontend server not detected on port ${FRONTEND_PORT}${NC}"
        echo -e "${YELLOW}   E2E tests may fail without running frontend${NC}"
    fi

    echo
}

# Function to check if Puppeteer is available
check_puppeteer() {
    if command -v npm &> /dev/null; then
        if [ ! -d "node_modules/puppeteer" ]; then
            echo -e "${YELLOW}📦 Installing Puppeteer for E2E tests...${NC}"
            npm install puppeteer --no-audit --no-fund
        fi
    fi
}

# Function to generate master report
generate_master_report() {
    local end_time=$(date +%s)
    local total_duration=$((end_time - start_time))
    local pass_rate=0

    if [ $total_suites -gt 0 ]; then
        pass_rate=$(( (passed_suites * 100) / total_suites ))
    fi

    local master_report="${REPORT_DIR}/master-ai-test-report-${TIMESTAMP}.json"
    local master_summary="${REPORT_DIR}/master-ai-test-summary-${TIMESTAMP}.txt"

    echo -e "${CYAN}📊 Generating Master Test Report...${NC}"

    # Generate JSON report
    cat > "${master_report}" << EOF
{
  "test_run": {
    "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "duration_seconds": ${total_duration},
    "backend_port": ${BACKEND_PORT},
    "frontend_port": ${FRONTEND_PORT}
  },
  "summary": {
    "total_suites": ${total_suites},
    "passed_suites": ${passed_suites},
    "failed_suites": ${failed_suites},
    "pass_rate_percent": ${pass_rate}
  },
  "suite_results": {
EOF

    # Add individual suite results
    local first=true
    for suite in "${!test_results[@]}"; do
        if [ "$first" = false ]; then
            echo "," >> "${master_report}"
        fi
        echo "    \"${suite}\": {" >> "${master_report}"
        echo "      \"result\": \"${test_results[$suite]}\"," >> "${master_report}"
        echo "      \"duration_seconds\": ${test_durations[$suite]}" >> "${master_report}"
        echo -n "    }" >> "${master_report}"
        first=false
    done

    cat >> "${master_report}" << EOF

  },
  "recommendations": [
EOF

    # Generate recommendations based on results
    local recs=()

    if [ $failed_suites -gt 0 ]; then
        recs+=("\"Review failed test logs for critical issues\"")
        recs+=("\"Fix failing tests before production deployment\"")
    fi

    if [ $pass_rate -lt 80 ]; then
        recs+=("\"Pass rate below 80% - significant issues detected\"")
    fi

    # Add recommendations to JSON
    local first_rec=true
    for rec in "${recs[@]}"; do
        if [ "$first_rec" = false ]; then
            echo "," >> "${master_report}"
        fi
        echo -n "    ${rec}" >> "${master_report}"
        first_rec=false
    done

    cat >> "${master_report}" << EOF

  ]
}
EOF

    # Generate text summary
    cat > "${master_summary}" << EOF
🎯 Romanian Septica AI Test Suite - Master Summary
==================================================

Test Run Information:
  Timestamp: $(date)
  Total Duration: ${total_duration} seconds
  Backend Port: ${BACKEND_PORT}
  Frontend Port: ${FRONTEND_PORT}

Summary:
  Total Test Suites: ${total_suites}
  Passed: ${passed_suites}
  Failed: ${failed_suites}
  Pass Rate: ${pass_rate}%

Individual Suite Results:
EOF

    # Add individual results to summary
    for suite in "${!test_results[@]}"; do
        local status_icon="✅"
        if [ "${test_results[$suite]}" = "FAIL" ]; then
            status_icon="❌"
        fi
        echo "  ${status_icon} ${suite}: ${test_results[$suite]} (${test_durations[$suite]}s)" >> "${master_summary}"
    done

    echo >> "${master_summary}"
    echo "Files Generated:" >> "${master_summary}"
    echo "  📄 JSON Report: ${master_report}" >> "${master_summary}"
    echo "  📋 Summary: ${master_summary}" >> "${master_summary}"
    echo "  📁 All Logs: ${REPORT_DIR}/" >> "${master_summary}"

    echo -e "${GREEN}📄 Master report saved: ${master_report}${NC}"
    echo -e "${GREEN}📋 Summary saved: ${master_summary}${NC}"
}

# Function to display final results
display_final_results() {
    echo -e "${CYAN}🏆 Romanian Septica AI Test Suite - Final Results${NC}"
    echo -e "${CYAN}=================================================${NC}"
    echo
    echo -e "${BLUE}📊 Summary:${NC}"
    echo -e "  Total Test Suites: ${total_suites}"
    echo -e "  Passed: ${GREEN}${passed_suites}${NC}"
    echo -e "  Failed: ${RED}${failed_suites}${NC}"

    local pass_rate=0
    if [ $total_suites -gt 0 ]; then
        pass_rate=$(( (passed_suites * 100) / total_suites ))
    fi
    echo -e "  Pass Rate: ${pass_rate}%"
    echo

    echo -e "${BLUE}📋 Individual Results:${NC}"
    for suite in "${!test_results[@]}"; do
        local status_color="${GREEN}"
        local status_icon="✅"
        if [ "${test_results[$suite]}" = "FAIL" ]; then
            status_color="${RED}"
            status_icon="❌"
        fi
        echo -e "  ${status_icon} ${suite}: ${status_color}${test_results[$suite]}${NC} (${test_durations[$suite]}s)"
    done
    echo

    # Overall assessment
    if [ $failed_suites -eq 0 ] && [ $pass_rate -ge 90 ]; then
        echo -e "${GREEN}🌟 EXCELLENT: All AI systems are functioning optimally!${NC}"
        echo -e "${GREEN}   ✅ All test suites passed${NC}"
        echo -e "${GREEN}   ✅ Romanian cultural authenticity maintained${NC}"
        echo -e "${GREEN}   ✅ Performance and quality standards met${NC}"
        echo -e "${GREEN}   🚀 System ready for production deployment${NC}"
    elif [ $pass_rate -ge 70 ]; then
        echo -e "${YELLOW}⚠️  NEEDS ATTENTION: Some issues detected${NC}"
        echo -e "${YELLOW}   🔧 Review failed tests and address issues${NC}"
        echo -e "${YELLOW}   📋 Check individual test logs for details${NC}"
        echo -e "${YELLOW}   ⏳ Consider addressing issues before production${NC}"
    else
        echo -e "${RED}🚨 CRITICAL: Major issues detected!${NC}"
        echo -e "${RED}   ❌ Multiple test suites failing${NC}"
        echo -e "${RED}   🛠️  Significant development work required${NC}"
        echo -e "${RED}   🚫 Not ready for production deployment${NC}"
    fi

    echo
    echo -e "${BLUE}📁 All reports and logs saved in: ${REPORT_DIR}${NC}"
}

# Main execution flow
main() {
    echo -e "${PURPLE}🎮 Romanian Septica AI Testing Framework${NC}"
    echo -e "${PURPLE}Cultural Gaming Preservation through Quality Assurance${NC}"
    echo

    # Check prerequisites
    check_prerequisites

    # Install dependencies if needed
    check_puppeteer

    echo -e "${CYAN}🎯 Executing Comprehensive AI Test Suite${NC}"
    echo -e "${CYAN}=====================================${NC}"
    echo

    # Test Suite 1: AI Strategic Behavior
    run_test_suite \
        "AI-Strategic-Behavior" \
        "cd backend && go run test-ai-strategic-behavior.go" \
        "Tests Romanian Septica rule compliance, cultural authenticity, and strategic intelligence"

    # Test Suite 2: AI Matchmaking Integration
    run_test_suite \
        "AI-Matchmaking-Integration" \
        "cd backend && go run test-ai-matchmaking-integration.go" \
        "Tests AI deployment, database integration, and WebSocket connectivity"

    # Test Suite 3: AI Performance & Quality
    run_test_suite \
        "AI-Performance-Quality" \
        "cd backend && go run test-ai-performance-quality.go" \
        "Tests AI performance metrics, memory usage, and decision quality"

    # Test Suite 4: End-to-End Integration
    run_test_suite \
        "E2E-AI-Integration" \
        "cd backend && node test-ai-e2e.js" \
        "Tests complete AI workflow from matchmaking to gameplay through browser"

    # Generate comprehensive reports
    generate_master_report

    # Display final results
    display_final_results

    # Return appropriate exit code
    if [ $failed_suites -gt 0 ]; then
        exit 1
    fi

    exit 0
}

# Handle script interruption
trap 'echo -e "\n${RED}❌ Test execution interrupted${NC}"; exit 130' INT TERM

# Run main function
main "$@"