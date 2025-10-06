#!/bin/bash
# Romanian Septica - Rollback Script
# Quick rollback to previous version with database restoration support

set -euo pipefail

# Configuration
COMPONENT=${1:-all}
ENVIRONMENT=${2:-prod}
PREVIOUS_VERSION=${3:-previous}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Romanian cultural elements
ROMANIAN_FLAG="🇷🇴"
ROLLBACK_ICON="⏪"

# Logging functions
log_info() { echo -e "${BLUE}${ROLLBACK_ICON} INFO: $1${NC}"; }
log_success() { echo -e "${GREEN}✅ SUCCESS: $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  WARNING: $1${NC}"; }
log_error() { echo -e "${RED}❌ ERROR: $1${NC}"; }

# Show rollback confirmation
confirm_rollback() {
    echo ""
    log_warning "⚠️  ROLLBACK CONFIRMATION ⚠️"
    echo -e "${YELLOW}Component: $COMPONENT${NC}"
    echo -e "${YELLOW}Environment: $ENVIRONMENT${NC}"
    echo -e "${YELLOW}Target version: $PREVIOUS_VERSION${NC}"
    echo ""

    if [ "$ENVIRONMENT" = "prod" ]; then
        log_error "PRODUCTION ROLLBACK - This will affect live users!"
        read -p "Type 'ROLLBACK PRODUCTION' to confirm: " -r
        if [[ $REPLY != "ROLLBACK PRODUCTION" ]]; then
            log_info "Rollback cancelled"
            exit 0
        fi
    else
        read -p "Are you sure you want to rollback? (yes/no): " -r
        if [[ ! $REPLY =~ ^yes$ ]]; then
            log_info "Rollback cancelled"
            exit 0
        fi
    fi

    log_info "Rollback confirmed - proceeding..."
}

# Get Kubernetes namespace
get_namespace() {
    case $ENVIRONMENT in
        dev) echo "septica-dev" ;;
        staging) echo "septica-staging" ;;
        prod) echo "septica" ;;
        *) echo "septica" ;;
    esac
}

# Rollback backend
rollback_backend() {
    log_info "Rolling back backend deployment..."

    case $ENVIRONMENT in
        dev)
            # Docker Compose rollback
            cd "$PROJECT_ROOT"

            # Stop current backend
            docker-compose stop backend

            # Tag previous version as latest
            if docker images | grep -q "septica-backend:$PREVIOUS_VERSION"; then
                docker tag septica-backend:$PREVIOUS_VERSION septica-backend:latest
                log_success "Backend image tagged as latest"
            else
                log_error "Previous backend version not found: $PREVIOUS_VERSION"
                exit 1
            fi

            # Restart backend with previous version
            docker-compose up -d backend
            ;;
        staging|prod)
            # Kubernetes rollback
            local namespace=$(get_namespace)

            log_info "Rolling back backend in namespace: $namespace"

            if [ "$PREVIOUS_VERSION" = "previous" ]; then
                # Use built-in Kubernetes rollback
                kubectl rollout undo deployment/septica-backend -n "$namespace"
            else
                # Rollback to specific version
                kubectl set image deployment/septica-backend \
                    backend=septica-backend:$PREVIOUS_VERSION \
                    -n "$namespace"
            fi

            # Wait for rollback to complete
            kubectl rollout status deployment/septica-backend \
                -n "$namespace" \
                --timeout=300s
            ;;
    esac

    log_success "Backend rollback completed"
}

# Rollback frontend
rollback_frontend() {
    log_info "Rolling back frontend deployment..."

    case $ENVIRONMENT in
        dev)
            # Docker Compose rollback
            cd "$PROJECT_ROOT"

            # Stop current frontend
            docker-compose stop frontend

            # Tag previous version as latest
            if docker images | grep -q "septica-frontend:$PREVIOUS_VERSION"; then
                docker tag septica-frontend:$PREVIOUS_VERSION septica-frontend:latest
                log_success "Frontend image tagged as latest"
            else
                log_error "Previous frontend version not found: $PREVIOUS_VERSION"
                exit 1
            fi

            # Restart frontend with previous version
            docker-compose up -d frontend
            ;;
        staging|prod)
            # Kubernetes rollback
            local namespace=$(get_namespace)

            log_info "Rolling back frontend in namespace: $namespace"

            if [ "$PREVIOUS_VERSION" = "previous" ]; then
                # Use built-in Kubernetes rollback
                kubectl rollout undo deployment/septica-frontend -n "$namespace"
            else
                # Rollback to specific version
                kubectl set image deployment/septica-frontend \
                    frontend=septica-frontend:$PREVIOUS_VERSION \
                    -n "$namespace"
            fi

            # Wait for rollback to complete
            kubectl rollout status deployment/septica-frontend \
                -n "$namespace" \
                --timeout=300s
            ;;
    esac

    log_success "Frontend rollback completed"
}

# Rollback database
rollback_database() {
    log_warning "Database rollback is a destructive operation!"
    log_info "Searching for latest backup..."

    # Find latest backup
    local backup_dir="$PROJECT_ROOT/backups"
    local latest_backup

    if [ -d "$backup_dir" ]; then
        latest_backup=$(ls -t "$backup_dir"/septica_backup_*.sql.gz 2>/dev/null | head -1)

        if [ -z "$latest_backup" ]; then
            log_error "No database backups found in: $backup_dir"
            exit 1
        fi
    else
        log_error "Backup directory not found: $backup_dir"
        exit 1
    fi

    log_info "Latest backup found: $(basename "$latest_backup")"
    log_info "Backup size: $(du -h "$latest_backup" | cut -f1)"
    log_info "Backup date: $(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$latest_backup" 2>/dev/null || stat -c "%y" "$latest_backup" 2>/dev/null)"

    echo ""
    log_warning "⚠️  DATABASE RESTORATION WARNING ⚠️"
    log_warning "This will OVERWRITE current database with backup data"
    log_warning "ALL data created after backup will be LOST"
    echo ""

    read -p "Type 'RESTORE DATABASE' to confirm: " -r
    if [[ $REPLY != "RESTORE DATABASE" ]]; then
        log_info "Database rollback cancelled"
        return 0
    fi

    log_info "Restoring database from backup..."

    case $ENVIRONMENT in
        dev)
            # Restore to local Docker database
            gunzip < "$latest_backup" | docker exec -i septica-postgres \
                psql -U septica -d septica

            log_success "Database restored from backup"
            ;;
        staging|prod)
            # Restore to Kubernetes database
            local namespace=$(get_namespace)

            gunzip < "$latest_backup" | kubectl exec -i deployment/postgres -n "$namespace" -- \
                psql -U septica_prod -d septica_prod

            log_success "Database restored from backup"
            ;;
    esac
}

# Verify rollback health
verify_rollback_health() {
    log_info "Verifying rollback health..."

    local backend_url
    local frontend_url

    case $ENVIRONMENT in
        dev)
            backend_url="http://localhost:8082/health"
            frontend_url="http://localhost:3000"
            ;;
        staging)
            backend_url="https://staging.septica.ro/api/health"
            frontend_url="https://staging.septica.ro"
            ;;
        prod)
            backend_url="https://septica.ro/api/health"
            frontend_url="https://septica.ro"
            ;;
    esac

    # Wait for services to be ready
    sleep 10

    # Check backend health
    if [ "$COMPONENT" = "backend" ] || [ "$COMPONENT" = "all" ]; then
        if curl -sf "$backend_url" > /dev/null 2>&1; then
            log_success "Backend is healthy"
        else
            log_error "Backend health check failed"
            return 1
        fi
    fi

    # Check frontend health
    if [ "$COMPONENT" = "frontend" ] || [ "$COMPONENT" = "all" ]; then
        if curl -sf "$frontend_url" > /dev/null 2>&1; then
            log_success "Frontend is healthy"
        else
            log_error "Frontend health check failed"
            return 1
        fi
    fi

    log_success "Rollback verification passed"
}

# Show rollback status
show_rollback_status() {
    local namespace=$(get_namespace)

    echo ""
    echo -e "${BLUE}${ROMANIAN_FLAG} Rollback Status ${ROLLBACK_ICON}${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    case $ENVIRONMENT in
        dev)
            echo -e "${BLUE}Docker Containers:${NC}"
            docker ps --filter "name=septica" --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"
            ;;
        staging|prod)
            echo -e "${BLUE}Kubernetes Pods:${NC}"
            kubectl get pods -n "$namespace" -o wide
            echo ""
            echo -e "${BLUE}Deployment Revisions:${NC}"
            kubectl rollout history deployment/septica-backend -n "$namespace" | tail -5
            kubectl rollout history deployment/septica-frontend -n "$namespace" | tail -5
            ;;
    esac

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Generate rollback report
generate_rollback_report() {
    log_info "Generating rollback report..."

    local report_file="$PROJECT_ROOT/rollback-report-$(date +%Y%m%d-%H%M%S).txt"

    cat > "$report_file" << EOF
Romanian Septica Rollback Report
================================
Component: $COMPONENT
Environment: $ENVIRONMENT
Target Version: $PREVIOUS_VERSION
Timestamp: $(date)

Rollback Actions:
$([ "$COMPONENT" = "backend" ] || [ "$COMPONENT" = "all" ] && echo "- Backend rolled back to: $PREVIOUS_VERSION")
$([ "$COMPONENT" = "frontend" ] || [ "$COMPONENT" = "all" ] && echo "- Frontend rolled back to: $PREVIOUS_VERSION")
$([ "$COMPONENT" = "database" ] && echo "- Database restored from backup")

Health Status:
- Backend: $(curl -sf http://localhost:8082/health > /dev/null 2>&1 && echo "Healthy" || echo "Unhealthy")
- Frontend: $(curl -sf http://localhost:3000 > /dev/null 2>&1 && echo "Healthy" || echo "Unhealthy")

Post-Rollback Actions:
1. Monitor error logs for any issues
2. Verify game functionality
3. Check database integrity
4. Monitor user complaints/reports
5. Prepare fix for original issue

Rollback initiated by: $(whoami)
Rollback status: COMPLETED

Next Steps:
- Monitor application stability
- Investigate root cause of issue
- Prepare proper fix
- Schedule new deployment when ready
EOF

    log_success "Rollback report saved to: $report_file"
    cat "$report_file"
}

# Main rollback flow
main() {
    echo ""
    echo -e "${BLUE}${ROMANIAN_FLAG} Romanian Septica Rollback ${ROLLBACK_ICON}${NC}"
    echo -e "${BLUE}Component: ${YELLOW}$COMPONENT${NC}"
    echo -e "${BLUE}Environment: ${YELLOW}$ENVIRONMENT${NC}"
    echo -e "${BLUE}Target: ${YELLOW}$PREVIOUS_VERSION${NC}"
    echo ""

    # Confirm rollback
    confirm_rollback

    # Execute rollback based on component
    case $COMPONENT in
        backend)
            rollback_backend
            ;;
        frontend)
            rollback_frontend
            ;;
        database)
            rollback_database
            ;;
        all)
            rollback_backend
            rollback_frontend
            # Database rollback requires explicit confirmation
            read -p "Also rollback database? (yes/no): " -r
            if [[ $REPLY =~ ^yes$ ]]; then
                rollback_database
            fi
            ;;
        *)
            log_error "Invalid component: $COMPONENT"
            log_info "Valid components: backend, frontend, database, all"
            exit 1
            ;;
    esac

    # Verify rollback health
    if verify_rollback_health; then
        log_success "Rollback verification passed"
    else
        log_error "Rollback verification failed - manual intervention required"
        exit 1
    fi

    # Show rollback status
    show_rollback_status

    # Generate rollback report
    generate_rollback_report

    echo ""
    log_success "${ROMANIAN_FLAG} Rollback completed successfully! ${ROLLBACK_ICON}"
    log_warning "Monitor the application closely for any issues"
    echo ""
}

# Handle script interruption
trap 'log_error "Rollback interrupted"; exit 1' INT TERM

# Execute main function
main "$@"
