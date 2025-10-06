#!/bin/bash
# Romanian Septica - Comprehensive Health Check Script
# Monitors all services, performance metrics, and automated alerts

set -euo pipefail

# Configuration
ENVIRONMENT=${1:-dev}
ALERT_MODE=${2:-report}  # report, slack, email, pagerduty

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Service URLs
BACKEND_URL_DEV="http://localhost:8082"
BACKEND_URL_STAGING="https://staging.septica.ro/api"
BACKEND_URL_PROD="https://septica.ro/api"

FRONTEND_URL_DEV="http://localhost:3000"
FRONTEND_URL_STAGING="https://staging.septica.ro"
FRONTEND_URL_PROD="https://septica.ro"

# Health check thresholds
MAX_RESPONSE_TIME=2000  # milliseconds
MIN_MEMORY_FREE=512     # MB
MAX_CPU_USAGE=80        # percentage
MAX_ERROR_RATE=1        # percentage

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Romanian cultural elements
ROMANIAN_FLAG="🇷🇴"
HEALTH_ICON="🏥"

# Logging functions
log_info() { echo -e "${BLUE}${HEALTH_ICON} INFO: $1${NC}"; }
log_success() { echo -e "${GREEN}✅ SUCCESS: $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  WARNING: $1${NC}"; }
log_error() { echo -e "${RED}❌ ERROR: $1${NC}"; }

# Global health status
OVERALL_STATUS="healthy"
HEALTH_ISSUES=()

# Get service URLs
get_backend_url() {
    case $ENVIRONMENT in
        dev) echo "$BACKEND_URL_DEV" ;;
        staging) echo "$BACKEND_URL_STAGING" ;;
        prod) echo "$BACKEND_URL_PROD" ;;
        *) echo "$BACKEND_URL_DEV" ;;
    esac
}

get_frontend_url() {
    case $ENVIRONMENT in
        dev) echo "$FRONTEND_URL_DEV" ;;
        staging) echo "$FRONTEND_URL_STAGING" ;;
        prod) echo "$FRONTEND_URL_PROD" ;;
        *) echo "$FRONTEND_URL_DEV" ;;
    esac
}

# Check backend health
check_backend_health() {
    log_info "Checking backend health..."

    local backend_url=$(get_backend_url)
    local health_endpoint="$backend_url/health"

    # Check if backend is reachable
    local response_code
    local response_time
    local start_time=$(date +%s%3N)

    response_code=$(curl -s -o /dev/null -w "%{http_code}" "$health_endpoint" 2>/dev/null || echo "000")

    local end_time=$(date +%s%3N)
    response_time=$((end_time - start_time))

    if [ "$response_code" = "200" ]; then
        log_success "Backend is healthy (${response_time}ms)"

        # Check response time
        if [ "$response_time" -gt "$MAX_RESPONSE_TIME" ]; then
            log_warning "Backend response time is slow: ${response_time}ms (threshold: ${MAX_RESPONSE_TIME}ms)"
            HEALTH_ISSUES+=("Backend response time: ${response_time}ms")
            OVERALL_STATUS="degraded"
        fi

        # Parse health response
        local health_data=$(curl -s "$health_endpoint")

        if echo "$health_data" | jq . > /dev/null 2>&1; then
            local db_status=$(echo "$health_data" | jq -r '.database // "unknown"')
            local websocket_status=$(echo "$health_data" | jq -r '.websocket // "unknown"')

            log_info "Database: $db_status"
            log_info "WebSocket: $websocket_status"

            if [ "$db_status" != "healthy" ]; then
                log_error "Database is unhealthy"
                HEALTH_ISSUES+=("Database unhealthy")
                OVERALL_STATUS="unhealthy"
            fi

            if [ "$websocket_status" != "healthy" ]; then
                log_warning "WebSocket is unhealthy"
                HEALTH_ISSUES+=("WebSocket unhealthy")
                OVERALL_STATUS="degraded"
            fi
        fi
    else
        log_error "Backend is down (HTTP $response_code)"
        HEALTH_ISSUES+=("Backend down (HTTP $response_code)")
        OVERALL_STATUS="unhealthy"
        return 1
    fi

    return 0
}

# Check frontend health
check_frontend_health() {
    log_info "Checking frontend health..."

    local frontend_url=$(get_frontend_url)

    # Check if frontend is reachable
    local response_code
    local response_time
    local start_time=$(date +%s%3N)

    response_code=$(curl -s -o /dev/null -w "%{http_code}" "$frontend_url" 2>/dev/null || echo "000")

    local end_time=$(date +%s%3N)
    response_time=$((end_time - start_time))

    if [ "$response_code" = "200" ]; then
        log_success "Frontend is healthy (${response_time}ms)"

        # Check Service Worker
        local sw_response=$(curl -s -o /dev/null -w "%{http_code}" "$frontend_url/service-worker.js" 2>/dev/null || echo "000")
        if [ "$sw_response" = "200" ]; then
            log_success "Service Worker is available"
        else
            log_warning "Service Worker not available (HTTP $sw_response)"
            HEALTH_ISSUES+=("Service Worker unavailable")
            OVERALL_STATUS="degraded"
        fi

        # Check PWA Manifest
        local manifest_response=$(curl -s -o /dev/null -w "%{http_code}" "$frontend_url/manifest.json" 2>/dev/null || echo "000")
        if [ "$manifest_response" = "200" ]; then
            log_success "PWA Manifest is available"
        else
            log_warning "PWA Manifest not available (HTTP $manifest_response)"
            HEALTH_ISSUES+=("PWA Manifest unavailable")
            OVERALL_STATUS="degraded"
        fi
    else
        log_error "Frontend is down (HTTP $response_code)"
        HEALTH_ISSUES+=("Frontend down (HTTP $response_code)")
        OVERALL_STATUS="unhealthy"
        return 1
    fi

    return 0
}

# Check database health
check_database_health() {
    log_info "Checking database health..."

    case $ENVIRONMENT in
        dev)
            # Check local Docker database
            if docker ps | grep -q "septica-postgres"; then
                if docker exec septica-postgres pg_isready -U septica > /dev/null 2>&1; then
                    log_success "Database is healthy"

                    # Check connection count
                    local conn_count=$(docker exec septica-postgres psql -U septica -t -c "SELECT count(*) FROM pg_stat_activity WHERE datname='septica';" | tr -d ' ')
                    log_info "Active connections: $conn_count"

                    # Check database size
                    local db_size=$(docker exec septica-postgres psql -U septica -t -c "SELECT pg_size_pretty(pg_database_size('septica'));" | tr -d ' ')
                    log_info "Database size: $db_size"
                else
                    log_error "Database is not ready"
                    HEALTH_ISSUES+=("Database not ready")
                    OVERALL_STATUS="unhealthy"
                    return 1
                fi
            else
                log_error "Database container not running"
                HEALTH_ISSUES+=("Database container down")
                OVERALL_STATUS="unhealthy"
                return 1
            fi
            ;;
        staging|prod)
            # Check Kubernetes database pod
            local namespace
            if [ "$ENVIRONMENT" = "staging" ]; then
                namespace="septica-staging"
            else
                namespace="septica"
            fi

            if kubectl get pod -n "$namespace" -l app=postgres | grep -q "Running"; then
                log_success "Database pod is running"
            else
                log_error "Database pod is not running"
                HEALTH_ISSUES+=("Database pod down")
                OVERALL_STATUS="unhealthy"
                return 1
            fi
            ;;
    esac

    return 0
}

# Check system resources
check_system_resources() {
    log_info "Checking system resources..."

    case $ENVIRONMENT in
        dev)
            # Check Docker container resources
            log_info "Docker container resources:"

            # Backend container
            if docker ps | grep -q "septica-backend"; then
                local backend_stats=$(docker stats septica-backend --no-stream --format "{{.CPUPerc}},{{.MemUsage}}")
                local cpu=$(echo "$backend_stats" | cut -d',' -f1 | sed 's/%//')
                local mem=$(echo "$backend_stats" | cut -d',' -f2)

                log_info "Backend CPU: ${cpu}%, Memory: $mem"

                # Check CPU threshold
                if (( $(echo "$cpu > $MAX_CPU_USAGE" | bc -l) )); then
                    log_warning "Backend CPU usage high: ${cpu}%"
                    HEALTH_ISSUES+=("Backend CPU high: ${cpu}%")
                    OVERALL_STATUS="degraded"
                fi
            fi

            # Frontend container
            if docker ps | grep -q "septica-frontend"; then
                local frontend_stats=$(docker stats septica-frontend --no-stream --format "{{.CPUPerc}},{{.MemUsage}}")
                local cpu=$(echo "$frontend_stats" | cut -d',' -f1 | sed 's/%//')
                local mem=$(echo "$frontend_stats" | cut -d',' -f2)

                log_info "Frontend CPU: ${cpu}%, Memory: $mem"
            fi
            ;;
        staging|prod)
            # Check Kubernetes pod resources
            local namespace
            if [ "$ENVIRONMENT" = "staging" ]; then
                namespace="septica-staging"
            else
                namespace="septica"
            fi

            log_info "Kubernetes pod resources in namespace: $namespace"
            kubectl top pods -n "$namespace" 2>/dev/null || log_warning "Metrics server not available"
            ;;
    esac
}

# Check Romanian Septica game metrics
check_game_metrics() {
    log_info "Checking Romanian Septica game metrics..."

    local backend_url=$(get_backend_url)
    local metrics_endpoint="$backend_url/metrics"

    # Fetch Prometheus metrics
    local metrics=$(curl -s "$metrics_endpoint" 2>/dev/null || echo "")

    if [ -n "$metrics" ]; then
        # Parse key game metrics
        local active_games=$(echo "$metrics" | grep "septica_active_games" | awk '{print $2}' || echo "0")
        local total_players=$(echo "$metrics" | grep "septica_total_players" | awk '{print $2}' || echo "0")
        local websocket_connections=$(echo "$metrics" | grep "websocket_connections" | awk '{print $2}' || echo "0")

        log_info "Active games: $active_games"
        log_info "Total players: $total_players"
        log_info "WebSocket connections: $websocket_connections"

        # Check for anomalies
        if [ "$active_games" -gt 1000 ]; then
            log_warning "Unusually high number of active games: $active_games"
            HEALTH_ISSUES+=("High active games: $active_games")
            OVERALL_STATUS="degraded"
        fi
    else
        log_warning "Game metrics not available"
    fi
}

# Check error logs
check_error_logs() {
    log_info "Checking error logs..."

    case $ENVIRONMENT in
        dev)
            # Check Docker logs for errors
            if docker ps | grep -q "septica-backend"; then
                local error_count=$(docker logs septica-backend --since 5m 2>&1 | grep -i "error\|fatal\|panic" | wc -l)

                if [ "$error_count" -gt 0 ]; then
                    log_warning "Found $error_count errors in backend logs (last 5 minutes)"
                    HEALTH_ISSUES+=("Backend errors: $error_count")
                    OVERALL_STATUS="degraded"

                    # Show recent errors
                    log_info "Recent errors:"
                    docker logs septica-backend --since 5m 2>&1 | grep -i "error\|fatal\|panic" | tail -5
                else
                    log_success "No errors found in backend logs"
                fi
            fi
            ;;
        staging|prod)
            # Check Kubernetes pod logs
            local namespace
            if [ "$ENVIRONMENT" = "staging" ]; then
                namespace="septica-staging"
            else
                namespace="septica"
            fi

            local error_count=$(kubectl logs deployment/septica-backend -n "$namespace" --since=5m 2>&1 | grep -i "error\|fatal\|panic" | wc -l)

            if [ "$error_count" -gt 0 ]; then
                log_warning "Found $error_count errors in backend logs (last 5 minutes)"
                HEALTH_ISSUES+=("Backend errors: $error_count")
                OVERALL_STATUS="degraded"
            else
                log_success "No errors found in backend logs"
            fi
            ;;
    esac
}

# Generate health report
generate_health_report() {
    local report_file="$PROJECT_ROOT/health-report-$(date +%Y%m%d-%H%M%S).txt"

    cat > "$report_file" << EOF
Romanian Septica Health Check Report
====================================
Environment: $ENVIRONMENT
Timestamp: $(date)
Overall Status: $OVERALL_STATUS

Service Health:
- Backend: $(check_backend_health > /dev/null 2>&1 && echo "✅ Healthy" || echo "❌ Unhealthy")
- Frontend: $(check_frontend_health > /dev/null 2>&1 && echo "✅ Healthy" || echo "❌ Unhealthy")
- Database: $(check_database_health > /dev/null 2>&1 && echo "✅ Healthy" || echo "❌ Unhealthy")

Health Issues:
$([ ${#HEALTH_ISSUES[@]} -eq 0 ] && echo "None" || printf '%s\n' "${HEALTH_ISSUES[@]}")

Performance Metrics:
- Backend response time: $(curl -s -o /dev/null -w "%{time_total}s" "$(get_backend_url)/health" 2>/dev/null || echo "N/A")
- Frontend response time: $(curl -s -o /dev/null -w "%{time_total}s" "$(get_frontend_url)" 2>/dev/null || echo "N/A")

System Resources:
$(check_system_resources 2>&1 | grep -v "INFO\|SUCCESS\|WARNING\|ERROR")

Romanian Septica Metrics:
$(check_game_metrics 2>&1 | grep -v "INFO\|SUCCESS\|WARNING\|ERROR")

Recommendations:
$([ "$OVERALL_STATUS" = "healthy" ] && echo "- No issues detected")
$([ "$OVERALL_STATUS" = "degraded" ] && echo "- Monitor system closely" && echo "- Investigate performance issues")
$([ "$OVERALL_STATUS" = "unhealthy" ] && echo "- Immediate action required" && echo "- Consider rollback if issues persist")

Next health check: $(date -d "+5 minutes" 2>/dev/null || date -v+5M)
====================================
EOF

    log_info "Health report saved to: $report_file"
    cat "$report_file"
}

# Send alerts
send_alerts() {
    if [ "$OVERALL_STATUS" = "healthy" ]; then
        log_info "All systems healthy - no alerts needed"
        return 0
    fi

    log_warning "Sending health alerts..."

    case $ALERT_MODE in
        slack)
            # Send Slack notification (requires SLACK_WEBHOOK_URL)
            if [ -n "${SLACK_WEBHOOK_URL:-}" ]; then
                curl -X POST "$SLACK_WEBHOOK_URL" \
                    -H 'Content-Type: application/json' \
                    -d "{\"text\":\"${ROMANIAN_FLAG} Romanian Septica Health Alert\n\nEnvironment: $ENVIRONMENT\nStatus: $OVERALL_STATUS\nIssues: ${#HEALTH_ISSUES[@]}\n\n$(printf '%s\n' "${HEALTH_ISSUES[@]}")\"}"

                log_success "Slack alert sent"
            else
                log_warning "SLACK_WEBHOOK_URL not set - skipping Slack alert"
            fi
            ;;
        email)
            # Send email notification (requires mail command)
            if command -v mail &> /dev/null; then
                echo "Romanian Septica health issues detected. See attached report." | \
                    mail -s "Health Alert: $ENVIRONMENT - $OVERALL_STATUS" "${ALERT_EMAIL:-admin@septica.ro}"

                log_success "Email alert sent"
            else
                log_warning "mail command not available - skipping email alert"
            fi
            ;;
        pagerduty)
            # Send PagerDuty alert (requires PAGERDUTY_KEY)
            if [ -n "${PAGERDUTY_KEY:-}" ]; then
                log_info "PagerDuty integration not implemented yet"
            fi
            ;;
        report)
            log_info "Alert mode: report only (no external notifications)"
            ;;
    esac
}

# Main health check flow
main() {
    echo ""
    echo -e "${BLUE}${ROMANIAN_FLAG} Romanian Septica Health Check ${HEALTH_ICON}${NC}"
    echo -e "${BLUE}Environment: ${YELLOW}$ENVIRONMENT${NC}"
    echo -e "${BLUE}Timestamp: ${YELLOW}$(date)${NC}"
    echo ""

    # Run all health checks
    check_backend_health || true
    echo ""

    check_frontend_health || true
    echo ""

    check_database_health || true
    echo ""

    check_system_resources || true
    echo ""

    check_game_metrics || true
    echo ""

    check_error_logs || true
    echo ""

    # Show overall status
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    case $OVERALL_STATUS in
        healthy)
            log_success "Overall Status: HEALTHY ✅"
            ;;
        degraded)
            log_warning "Overall Status: DEGRADED ⚠️"
            ;;
        unhealthy)
            log_error "Overall Status: UNHEALTHY ❌"
            ;;
    esac

    if [ ${#HEALTH_ISSUES[@]} -gt 0 ]; then
        echo ""
        log_warning "Health Issues Detected (${#HEALTH_ISSUES[@]}):"
        printf '%s\n' "${HEALTH_ISSUES[@]}" | while read -r issue; do
            echo -e "${YELLOW}  - $issue${NC}"
        done
    fi
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Generate health report
    generate_health_report

    # Send alerts if needed
    send_alerts

    echo ""
    log_info "${ROMANIAN_FLAG} Health check completed"
    echo ""

    # Exit with appropriate code
    case $OVERALL_STATUS in
        healthy) exit 0 ;;
        degraded) exit 1 ;;
        unhealthy) exit 2 ;;
    esac
}

# Execute main function
main "$@"
