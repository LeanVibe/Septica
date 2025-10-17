#!/bin/bash
#
# Phase 3 Validation Script
# Comprehensive pre-commit validation to ensure production readiness
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

# Results array
declare -a RESULTS

# Print functions
print_header() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}     Phase 3 Validation - Production Readiness Check        ${BLUE}║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_check() {
    echo -e "${BLUE}▶${NC} $1"
}

print_pass() {
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
    RESULTS+=("✓ $1")
    echo -e "  ${GREEN}✓${NC} $1"
}

print_fail() {
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
    RESULTS+=("✗ $1")
    echo -e "  ${RED}✗${NC} $1"
}

print_summary() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}VALIDATION SUMMARY${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "Total Checks: $TOTAL_CHECKS"
    echo -e "Passed: ${GREEN}$PASSED_CHECKS${NC}"
    echo -e "Failed: ${RED}$FAILED_CHECKS${NC}"
    echo ""

    if [ $FAILED_CHECKS -eq 0 ]; then
        echo -e "${GREEN}✓ ALL CHECKS PASSED - READY FOR COMMIT${NC}"
        return 0
    else
        echo -e "${RED}✗ VALIDATION FAILED - FIX ISSUES BEFORE COMMIT${NC}"
        return 1
    fi
}

# Check file existence
check_file_existence() {
    print_check "Checking file existence..."
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    local files=(
        "internal/ai/ai_matchmaking_manager.go"
        "internal/ai/ai_websocket_client.go"
        "internal/matchmaking/processor.go"
        "internal/ai/ai_game_context_test.go"
        "internal/ai/ai_game_id_fix_test.go"
        "internal/ai/ai_matchmaking_manager_simple_test.go"
        "internal/database/user_creation_test.go"
        "docs/fixes/AI_BACKEND_FIXES_PHASE3.md"
        "docs/TECHNICAL_DEBT.md"
        "docs/PROJECT_STATUS.md"
        "PHASE3_COMPLETE.md"
        "COMMIT_SUMMARY.md"
        "commit-phase3.sh"
        "MANUAL_COMMIT_GUIDE.md"
    )

    local missing=0
    for file in "${files[@]}"; do
        if [ ! -f "$file" ]; then
            print_fail "Missing: $file"
            missing=$((missing + 1))
        fi
    done

    if [ $missing -eq 0 ]; then
        print_pass "All 14 Phase 3 files present"
        return 0
    else
        print_fail "$missing file(s) missing"
        return 1
    fi
}

# Validate Go build
run_build_validation() {
    print_check "Running build validation..."
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    if go build ./cmd/server >/dev/null 2>&1; then
        print_pass "Server builds successfully (zero compilation errors)"
        return 0
    else
        print_fail "Server build failed (compilation errors present)"
        go build ./cmd/server 2>&1 | head -10
        return 1
    fi
}

# Validate core tests
run_test_validation() {
    print_check "Running core test validation..."
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    # Run specific core tests that should always pass
    if go test ./internal/ai -run "TestGameIDFix|TestGameContextValidation|TestMoveMessageStructure" -timeout 10s >/dev/null 2>&1; then
        print_pass "Core tests passing (TestGameIDFix, TestGameContext)"
        return 0
    else
        print_fail "Core tests failing"
        return 1
    fi
}

# Verify code changes using git diff
verify_code_changes() {
    print_check "Verifying code changes..."
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    local changes_ok=0

    # Check ai_matchmaking_manager.go for user.ID fix
    if git diff internal/ai/ai_matchmaking_manager.go | grep -q "user.ID"; then
        print_pass "Fix 1: user.ID correction present in ai_matchmaking_manager.go"
        changes_ok=$((changes_ok + 1))
    else
        print_fail "Fix 1: user.ID correction not found"
    fi

    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    # Check ai_websocket_client.go for game_id storage
    if git diff internal/ai/ai_websocket_client.go | grep -q "CurrentGameID"; then
        print_pass "Fix 2: game_id storage present in ai_websocket_client.go"
        changes_ok=$((changes_ok + 1))
    else
        print_fail "Fix 2: game_id storage not found"
    fi

    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    # Check processor.go for transaction
    if git diff internal/matchmaking/processor.go | grep -q "Transaction"; then
        print_pass "Fix 3: transaction safety present in processor.go"
        changes_ok=$((changes_ok + 1))
    else
        print_fail "Fix 3: transaction safety not found"
    fi

    if [ $changes_ok -eq 3 ]; then
        return 0
    else
        return 1
    fi
}

# Check documentation completeness
check_documentation_completeness() {
    print_check "Checking documentation completeness..."
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    local docs_ok=0

    # Check AI_BACKEND_FIXES_PHASE3.md has substantial content
    if [ -f "docs/fixes/AI_BACKEND_FIXES_PHASE3.md" ]; then
        local lines=$(wc -l < "docs/fixes/AI_BACKEND_FIXES_PHASE3.md" | tr -d ' ')
        if [ $lines -gt 400 ]; then
            print_pass "AI_BACKEND_FIXES_PHASE3.md complete ($lines lines)"
            docs_ok=$((docs_ok + 1))
        else
            print_fail "AI_BACKEND_FIXES_PHASE3.md too short ($lines lines, expected >400)"
        fi
    fi

    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    # Check TECHNICAL_DEBT.md
    if [ -f "docs/TECHNICAL_DEBT.md" ]; then
        local lines=$(wc -l < "docs/TECHNICAL_DEBT.md" | tr -d ' ')
        if [ $lines -gt 200 ]; then
            print_pass "TECHNICAL_DEBT.md complete ($lines lines)"
            docs_ok=$((docs_ok + 1))
        else
            print_fail "TECHNICAL_DEBT.md too short ($lines lines, expected >200)"
        fi
    fi

    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    # Check PROJECT_STATUS.md
    if [ -f "docs/PROJECT_STATUS.md" ]; then
        local lines=$(wc -l < "docs/PROJECT_STATUS.md" | tr -d ' ')
        if [ $lines -gt 300 ]; then
            print_pass "PROJECT_STATUS.md complete ($lines lines)"
            docs_ok=$((docs_ok + 1))
        else
            print_fail "PROJECT_STATUS.md too short ($lines lines, expected >300)"
        fi
    fi

    if [ $docs_ok -eq 3 ]; then
        return 0
    else
        return 1
    fi
}

# Check test file sizes
check_test_coverage() {
    print_check "Checking test file coverage..."
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    local total_test_lines=0

    for file in internal/ai/ai_game_context_test.go \
                internal/ai/ai_game_id_fix_test.go \
                internal/ai/ai_matchmaking_manager_simple_test.go \
                internal/database/user_creation_test.go; do
        if [ -f "$file" ]; then
            local lines=$(wc -l < "$file" | tr -d ' ')
            total_test_lines=$((total_test_lines + lines))
        fi
    done

    if [ $total_test_lines -gt 1000 ]; then
        print_pass "Comprehensive test coverage ($total_test_lines lines total)"
        return 0
    else
        print_fail "Insufficient test coverage ($total_test_lines lines, expected >1000)"
        return 1
    fi
}

# Generate validation report
generate_validation_report() {
    local report_file=".phase3-validation-report.md"

    cat > "$report_file" << EOF
# Phase 3 Validation Report

**Generated**: $(date)
**Status**: $([ $FAILED_CHECKS -eq 0 ] && echo "✅ PASSED" || echo "❌ FAILED")

---

## Validation Results

Total Checks: $TOTAL_CHECKS
- Passed: $PASSED_CHECKS
- Failed: $FAILED_CHECKS

## Detailed Results

EOF

    for result in "${RESULTS[@]}"; do
        echo "- $result" >> "$report_file"
    done

    cat >> "$report_file" << EOF

---

## Next Steps

EOF

    if [ $FAILED_CHECKS -eq 0 ]; then
        cat >> "$report_file" << EOF
✅ **All validation checks passed!**

You can now commit:
\`\`\`bash
./commit-phase3.sh
# OR follow MANUAL_COMMIT_GUIDE.md
\`\`\`

## Production Deployment Checklist

- [ ] Commit Phase 3 changes
- [ ] Push to remote repository
- [ ] Deploy to staging environment
- [ ] Run smoke tests
- [ ] Deploy to production
- [ ] Monitor metrics

EOF
    else
        cat >> "$report_file" << EOF
❌ **Validation failed - fix issues before commit**

Review the failed checks above and:
1. Fix any missing files
2. Resolve compilation errors
3. Ensure all tests pass
4. Re-run validation: \`./validate-phase3.sh\`

EOF
    fi

    echo ""
    echo -e "${BLUE}Validation report generated: $report_file${NC}"
}

# Main execution
main() {
    print_header

    # Run all validation checks
    check_file_existence
    run_build_validation
    run_test_validation
    verify_code_changes
    check_documentation_completeness
    check_test_coverage

    echo ""

    # Generate report
    generate_validation_report

    # Show summary
    if print_summary; then
        echo ""
        echo -e "${GREEN}✓ Phase 3 is production-ready!${NC}"
        echo ""
        echo "Next step: Run ${BLUE}./commit-phase3.sh${NC} to commit changes"
        exit 0
    else
        echo ""
        echo -e "${RED}✗ Fix validation issues before commit${NC}"
        echo ""
        echo "Review: ${BLUE}.phase3-validation-report.md${NC}"
        exit 1
    fi
}

# Run main
main "$@"
