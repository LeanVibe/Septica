#!/bin/bash

# Romanian Septica Comprehensive Playwright E2E Test Runner
# Executes the complete test suite with detailed reporting

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test configuration
PROJECT_DIR="$(pwd)"
TEST_DIR="e2e-tests"
RESULTS_DIR="test-results"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Default values
BROWSER="chromium"
HEADED=false
VERBOSE=false
PARALLEL=true
WORKERS=4
CATEGORY=""
TIMEOUT=45000

# Function to print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to print banner
print_banner() {
    echo
    print_color $CYAN "================================================================="
    print_color $CYAN "🇷🇴 ROMANIAN SEPTICA COMPREHENSIVE E2E TEST SUITE 🇷🇴"
    print_color $CYAN "================================================================="
    echo
}

# Function to print usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -h, --help              Show this help message"
    echo "  -b, --browser BROWSER   Browser to use (chromium, firefox, webkit) [default: chromium]"
    echo "  -H, --headed            Run tests in headed mode (visible browser)"
    echo "  -v, --verbose           Enable verbose output"
    echo "  -s, --sequential        Run tests sequentially (not parallel)"
    echo "  -w, --workers NUM       Number of parallel workers [default: 4]"
    echo "  -c, --category CAT      Run specific test category:"
    echo "                          infrastructure, matchmaking, rules, performance, resilience"
    echo "  -t, --timeout MS        Test timeout in milliseconds [default: 45000]"
    echo "  --debug                 Enable debug mode with additional logging"
    echo "  --smoke                 Run only smoke tests (quick validation)"
    echo "  --all                   Run complete comprehensive suite (default)"
    echo
    echo "Examples:"
    echo "  $0                                    # Run all tests with default settings"
    echo "  $0 --browser firefox --headed        # Run in Firefox with visible browser"
    echo "  $0 --category matchmaking            # Run only matchmaking tests"
    echo "  $0 --smoke                           # Run quick smoke tests"
    echo "  $0 --sequential --verbose            # Run sequentially with verbose output"
    echo
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -b|--browser)
            BROWSER="$2"
            shift 2
            ;;
        -H|--headed)
            HEADED=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -s|--sequential)
            PARALLEL=false
            shift
            ;;
        -w|--workers)
            WORKERS="$2"
            shift 2
            ;;
        -c|--category)
            CATEGORY="$2"
            shift 2
            ;;
        -t|--timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        --debug)
            VERBOSE=true
            export DEBUG=pw:*
            shift
            ;;
        --smoke)
            CATEGORY="smoke"
            shift
            ;;
        --all)
            CATEGORY=""
            shift
            ;;
        *)
            print_color $RED "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Validate browser choice
case $BROWSER in
    chromium|firefox|webkit)
        ;;
    *)
        print_color $RED "Invalid browser: $BROWSER. Must be chromium, firefox, or webkit."
        exit 1
        ;;
esac

# Function to check prerequisites
check_prerequisites() {
    print_color $BLUE "🔍 Checking prerequisites..."
    
    # Check if Node.js is installed
    if ! command -v node &> /dev/null; then
        print_color $RED "❌ Node.js is not installed. Please install Node.js to run Playwright tests."
        exit 1
    fi
    
    # Check if npm is installed
    if ! command -v npm &> /dev/null; then
        print_color $RED "❌ npm is not installed. Please install npm to manage dependencies."
        exit 1
    fi
    
    # Check if Playwright is installed
    if [ ! -f "node_modules/.bin/playwright" ] && ! command -v playwright &> /dev/null; then
        print_color $YELLOW "⚠️ Playwright not found. Installing..."
        npm install playwright
    fi
    
    # Check if test directory exists
    if [ ! -d "$TEST_DIR" ]; then
        print_color $RED "❌ Test directory '$TEST_DIR' not found!"
        exit 1
    fi
    
    # Create results directory
    mkdir -p "$RESULTS_DIR"
    
    print_color $GREEN "✅ Prerequisites check completed"
}

# Function to check service status
check_services() {
    print_color $BLUE "🔍 Checking required services..."
    
    local services_ok=true
    
    # Check backend
    if curl -s http://localhost:8080/health &>/dev/null; then
        print_color $GREEN "✅ Backend server (port 8080) is running"
    else
        print_color $YELLOW "⚠️ Backend server (port 8080) is not responding"
        print_color $YELLOW "   Start with: DATABASE_URL=\"postgres://septica:septica@localhost:5433/septica?sslmode=disable\" ./backend/server"
        services_ok=false
    fi
    
    # Check frontend
    if curl -s http://localhost:3000 &>/dev/null; then
        print_color $GREEN "✅ Frontend server (port 3000) is running"
    else
        print_color $YELLOW "⚠️ Frontend server (port 3000) is not responding"
        print_color $YELLOW "   Start with: cd frontend && python3 -m http.server 3000"
        services_ok=false
    fi
    
    # Check WebSocket (basic test)
    if timeout 5 bash -c "</dev/tcp/localhost/8080" &>/dev/null; then
        print_color $GREEN "✅ WebSocket endpoint (port 8080) is reachable"
    else
        print_color $YELLOW "⚠️ WebSocket endpoint (port 8080) may not be available"
        services_ok=false
    fi
    
    if [ "$services_ok" = false ]; then
        print_color $YELLOW "⚠️ Some services are not running. Tests may fail or run in degraded mode."
        echo
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_color $RED "Exiting. Please start the required services and try again."
            exit 1
        fi
    fi
    
    echo
}

# Function to build Playwright command
build_playwright_command() {
    local cmd="npx playwright test"
    
    # Browser selection
    cmd="$cmd --project=$BROWSER-desktop"
    
    # Headed/headless mode
    if [ "$HEADED" = true ]; then
        cmd="$cmd --headed"
    fi
    
    # Parallel execution
    if [ "$PARALLEL" = false ]; then
        cmd="$cmd --workers=1"
    else
        cmd="$cmd --workers=$WORKERS"
    fi
    
    # Timeout
    cmd="$cmd --timeout=$TIMEOUT"
    
    # Category filtering
    case $CATEGORY in
        "infrastructure")
            cmd="$cmd e2e-tests/infrastructure/"
            ;;
        "matchmaking")
            cmd="$cmd e2e-tests/matchmaking/"
            ;;
        "rules")
            cmd="$cmd e2e-tests/rules/"
            ;;
        "performance")
            cmd="$cmd e2e-tests/performance/"
            ;;
        "resilience")
            cmd="$cmd e2e-tests/resilience/"
            ;;
        "smoke")
            # Run subset of critical tests for smoke testing
            cmd="$cmd e2e-tests/infrastructure/connectivity.spec.js e2e-tests/matchmaking/two-tab-auto-matchmaking.spec.js"
            ;;
        "")
            # Run all tests
            cmd="$cmd e2e-tests/"
            ;;
        *)
            print_color $RED "Invalid category: $CATEGORY"
            exit 1
            ;;
    esac
    
    # Verbose output
    if [ "$VERBOSE" = true ]; then
        cmd="$cmd --reporter=line"
    fi
    
    echo "$cmd"
}

# Function to run tests
run_tests() {
    local start_time=$(date +%s)
    
    print_color $BLUE "🚀 Starting Romanian Septica E2E Tests..."
    print_color $BLUE "Configuration:"
    print_color $BLUE "  Browser: $BROWSER"
    print_color $BLUE "  Mode: $([ "$HEADED" = true ] && echo "Headed" || echo "Headless")"
    print_color $BLUE "  Execution: $([ "$PARALLEL" = true ] && echo "Parallel ($WORKERS workers)" || echo "Sequential")"
    print_color $BLUE "  Category: $([ -n "$CATEGORY" ] && echo "$CATEGORY" || echo "All")"
    print_color $BLUE "  Timeout: ${TIMEOUT}ms"
    echo
    
    # Build and execute Playwright command
    local playwright_cmd=$(build_playwright_command)
    
    if [ "$VERBOSE" = true ]; then
        print_color $CYAN "Executing: $playwright_cmd"
        echo
    fi
    
    # Execute tests
    local exit_code=0
    if eval "$playwright_cmd"; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        print_color $GREEN "✅ Tests completed successfully in ${duration}s"
    else
        exit_code=$?
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        print_color $RED "❌ Tests failed after ${duration}s (exit code: $exit_code)"
    fi
    
    return $exit_code
}

# Function to generate summary report
generate_summary() {
    print_color $BLUE "📊 Generating test summary..."
    
    if [ -f "$RESULTS_DIR/test-results.json" ]; then
        # Parse test results if available
        local total_tests=$(node -e "
            const fs = require('fs');
            try {
                const results = JSON.parse(fs.readFileSync('$RESULTS_DIR/test-results.json', 'utf8'));
                let total = 0;
                let passed = 0;
                let failed = 0;
                let skipped = 0;
                
                if (results.suites) {
                    results.suites.forEach(suite => {
                        suite.specs.forEach(spec => {
                            spec.tests.forEach(test => {
                                total++;
                                test.results.forEach(result => {
                                    if (result.status === 'passed') passed++;
                                    else if (result.status === 'failed') failed++;
                                    else if (result.status === 'skipped') skipped++;
                                });
                            });
                        });
                    });
                }
                
                console.log(\`Total: \${total}, Passed: \${passed}, Failed: \${failed}, Skipped: \${skipped}\`);
            } catch (error) {
                console.log('Unable to parse test results');
            }
        " 2>/dev/null || echo "Results parsing failed")
        
        print_color $CYAN "Test Results: $total_tests"
    fi
    
    # List available reports
    echo
    print_color $CYAN "📁 Generated Reports:"
    if [ -f "$RESULTS_DIR/playwright-report/index.html" ]; then
        print_color $GREEN "  HTML Report: $RESULTS_DIR/playwright-report/index.html"
    fi
    if [ -f "$RESULTS_DIR/test-results.json" ]; then
        print_color $GREEN "  JSON Report: $RESULTS_DIR/test-results.json"
    fi
    if [ -f "$RESULTS_DIR/junit.xml" ]; then
        print_color $GREEN "  JUnit Report: $RESULTS_DIR/junit.xml"
    fi
    if [ -f "$RESULTS_DIR/setup-report.json" ]; then
        print_color $GREEN "  Setup Report: $RESULTS_DIR/setup-report.json"
    fi
    if [ -f "$RESULTS_DIR/comprehensive-summary.json" ]; then
        print_color $GREEN "  Summary Report: $RESULTS_DIR/comprehensive-summary.json"
    fi
}

# Function to open HTML report
open_report() {
    if [ -f "$RESULTS_DIR/playwright-report/index.html" ]; then
        print_color $BLUE "📖 Opening HTML report..."
        
        # Try to open in browser (works on macOS, Linux with GUI)
        if command -v open &> /dev/null; then
            open "$RESULTS_DIR/playwright-report/index.html"
        elif command -v xdg-open &> /dev/null; then
            xdg-open "$RESULTS_DIR/playwright-report/index.html"
        else
            print_color $YELLOW "HTML report available at: file://$(pwd)/$RESULTS_DIR/playwright-report/index.html"
        fi
    fi
}

# Main execution flow
main() {
    print_banner
    
    # Check if we're in the right directory
    if [ ! -f "playwright.config.js" ]; then
        print_color $RED "❌ playwright.config.js not found. Please run this script from the project root."
        exit 1
    fi
    
    check_prerequisites
    check_services
    
    # Run tests
    local test_exit_code=0
    if run_tests; then
        print_color $GREEN "🎉 All tests passed!"
    else
        test_exit_code=$?
        print_color $RED "💥 Some tests failed!"
    fi
    
    # Generate summary
    generate_summary
    
    # Optionally open report
    if [ "$HEADED" = true ] || [ "$VERBOSE" = true ]; then
        echo
        read -p "Open HTML report? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            open_report
        fi
    fi
    
    echo
    print_color $CYAN "================================================================="
    print_color $CYAN "🏁 Romanian Septica E2E Test Execution Complete"
    print_color $CYAN "================================================================="
    
    exit $test_exit_code
}

# Trap interrupts and cleanup
trap 'print_color $RED "\n⚠️ Test execution interrupted"; exit 130' INT TERM

# Run main function
main "$@"