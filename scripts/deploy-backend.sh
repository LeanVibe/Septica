#!/bin/bash
# Romanian Septica - Backend Deployment Script
# Deploys Go backend with database migration handling and health checks

set -euo pipefail

# Configuration
ENVIRONMENT=${1:-dev}
VERSION=${2:-latest}
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
BACKEND_ICON="⚙️"

# Logging functions
log_info() { echo -e "${BLUE}${BACKEND_ICON} INFO: $1${NC}"; }
log_success() { echo -e "${GREEN}✅ SUCCESS: $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  WARNING: $1${NC}"; }
log_error() { echo -e "${RED}❌ ERROR: $1${NC}"; }

# Validation
validate_environment() {
    case $ENVIRONMENT in
        dev|staging|prod) ;;
        *)
            log_error "Invalid environment: $ENVIRONMENT (must be dev, staging, or prod)"
            exit 1
            ;;
    esac
}

# Database migration check
check_database_migrations() {
    log_info "Checking database migration requirements..."

    # Check if GORM migration issue is resolved
    if [ "$ENVIRONMENT" = "prod" ]; then
        log_warning "CRITICAL: Verify GORM migration issue is resolved before production deployment"
        log_info "Current workaround: SKIP_MIGRATIONS=true (NOT safe for production)"

        read -p "Have you verified database migrations work correctly? (yes/no): " -r
        if [[ ! $REPLY =~ ^yes$ ]]; then
            log_error "Production deployment cancelled - resolve GORM migration issue first"
            exit 1
        fi
    fi
}

# Build backend Docker image
build_backend_image() {
    log_info "Building Romanian Septica backend image (version: $VERSION)..."

    cd "$PROJECT_ROOT/backend"

    # Ensure Go dependencies are up-to-date
    log_info "Updating Go dependencies..."
    go mod download
    go mod verify

    # Run tests before building
    log_info "Running Romanian Septica game engine tests..."
    if ! go test ./internal/game/...; then
        log_error "Backend tests failed - aborting deployment"
        exit 1
    fi
    log_success "Backend tests passed"

    # Build Docker image
    docker build \
        -t septica-backend:$VERSION \
        -f Dockerfile \
        --build-arg VERSION=$VERSION \
        --build-arg BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
        .

    log_success "Backend image built: septica-backend:$VERSION"
}

# Run database migrations
run_database_migrations() {
    log_info "Running database migrations for $ENVIRONMENT..."

    case $ENVIRONMENT in
        dev)
            # Development: Run migrations with auto-creation
            docker run --rm \
                --network host \
                -e DATABASE_URL="postgres://septica:septica@localhost:5433/septica?sslmode=disable" \
                -e SKIP_MIGRATIONS=false \
                septica-backend:$VERSION \
                /app/migrate up
            ;;
        staging)
            # Staging: Run migrations with verification
            docker run --rm \
                -e DATABASE_URL="${STAGING_DATABASE_URL}" \
                septica-backend:$VERSION \
                /app/migrate up
            ;;
        prod)
            # Production: Manual confirmation required
            log_warning "Production database migration requires manual confirmation"
            log_info "Migration command: docker run --rm -e DATABASE_URL=\$PROD_DB_URL septica-backend:$VERSION /app/migrate up"

            read -p "Run production migrations now? (yes/no): " -r
            if [[ $REPLY =~ ^yes$ ]]; then
                docker run --rm \
                    -e DATABASE_URL="${PRODUCTION_DATABASE_URL}" \
                    septica-backend:$VERSION \
                    /app/migrate up
            else
                log_warning "Migrations skipped - ensure they are run manually before deployment"
            fi
            ;;
    esac

    log_success "Database migrations completed"
}

# Deploy backend service
deploy_backend_service() {
    log_info "Deploying backend to $ENVIRONMENT environment..."

    case $ENVIRONMENT in
        dev)
            # Development: Simple Docker Compose deployment
            cd "$PROJECT_ROOT"

            # Update docker-compose with new image version
            export BACKEND_VERSION=$VERSION

            # Stop old container
            docker-compose stop backend || true
            docker-compose rm -f backend || true

            # Start new container
            docker-compose up -d backend
            ;;
        staging|prod)
            # Staging/Production: Kubernetes blue-green deployment
            local namespace
            if [ "$ENVIRONMENT" = "staging" ]; then
                namespace="septica-staging"
            else
                namespace="septica"
            fi

            # Update image tag in Kubernetes
            kubectl set image deployment/septica-backend \
                backend=septica-backend:$VERSION \
                -n $namespace

            # Wait for rollout
            log_info "Waiting for backend rollout to complete..."
            kubectl rollout status deployment/septica-backend \
                -n $namespace \
                --timeout=600s
            ;;
    esac

    log_success "Backend deployed successfully"
}

# Health check verification
verify_backend_health() {
    log_info "Verifying backend health..."

    local health_url
    case $ENVIRONMENT in
        dev) health_url="http://localhost:8082/health" ;;
        staging) health_url="http://staging.septica.ro/api/health" ;;
        prod) health_url="http://septica.ro/api/health" ;;
    esac

    # Wait for backend to be ready (max 60 seconds)
    local max_attempts=30
    local attempt=0

    while [ $attempt -lt $max_attempts ]; do
        if curl -sf "$health_url" > /dev/null 2>&1; then
            log_success "Backend health check passed"

            # Detailed health check
            log_info "Backend health status:"
            curl -s "$health_url" | jq '.'
            return 0
        fi

        attempt=$((attempt + 1))
        log_info "Waiting for backend... ($attempt/$max_attempts)"
        sleep 2
    done

    log_error "Backend health check failed after $max_attempts attempts"
    return 1
}

# Rollback function
rollback_backend() {
    log_warning "Rolling back backend deployment..."

    case $ENVIRONMENT in
        dev)
            docker-compose stop backend
            docker-compose up -d backend
            ;;
        staging|prod)
            local namespace
            if [ "$ENVIRONMENT" = "staging" ]; then
                namespace="septica-staging"
            else
                namespace="septica"
            fi

            kubectl rollout undo deployment/septica-backend -n $namespace
            kubectl rollout status deployment/septica-backend -n $namespace --timeout=300s
            ;;
    esac

    log_success "Backend rolled back successfully"
}

# Main deployment flow
main() {
    echo ""
    echo -e "${BLUE}${ROMANIAN_FLAG} Romanian Septica Backend Deployment ${BACKEND_ICON}${NC}"
    echo -e "${BLUE}Environment: ${YELLOW}$ENVIRONMENT${NC}"
    echo -e "${BLUE}Version: ${YELLOW}$VERSION${NC}"
    echo ""

    # Validate environment
    validate_environment

    # Check database migrations
    check_database_migrations

    # Build backend image
    build_backend_image

    # Run database migrations
    if [ "${SKIP_MIGRATIONS:-false}" != "true" ]; then
        run_database_migrations
    else
        log_warning "Database migrations skipped (SKIP_MIGRATIONS=true)"
    fi

    # Deploy backend service
    deploy_backend_service

    # Verify health
    if verify_backend_health; then
        log_success "Backend deployment completed successfully!"
    else
        log_error "Backend health check failed - initiating rollback"
        rollback_backend
        exit 1
    fi

    echo ""
    log_success "${ROMANIAN_FLAG} Romanian Septica backend is live! ${BACKEND_ICON}"
    echo ""
}

# Handle script interruption
trap 'log_error "Deployment interrupted"; exit 1' INT TERM

# Execute main function
main "$@"
