#!/bin/bash
# Romanian Septica Production Deployment Script
# This script automates the deployment of the complete Romanian Septica platform

set -euo pipefail

# Configuration
NAMESPACE="septica"
MONITORING_NAMESPACE="monitoring"
STAGING_NAMESPACE="septica-staging"
REGISTRY="ghcr.io/bogdan/septica"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Romanian flag emoji and cultural elements
ROMANIAN_FLAG="🇷🇴"
CARD_GAME="🎮"
CROWN="👑"
TROPHY="🏆"

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  INFO: $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ SUCCESS: $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  WARNING: $1${NC}"
}

log_error() {
    echo -e "${RED}❌ ERROR: $1${NC}"
}

log_romanian() {
    echo -e "${PURPLE}${ROMANIAN_FLAG} ROMANIAN SEPTICA: $1${NC}"
}

# Help function
show_help() {
    cat << EOF
${ROMANIAN_FLAG} Romanian Septica Deployment Script ${CARD_GAME}

USAGE:
    $0 [COMMAND] [OPTIONS]

COMMANDS:
    dev         Deploy to development environment (local)
    staging     Deploy to staging environment
    production  Deploy to production environment
    monitor     Deploy monitoring stack only
    health      Check deployment health
    clean       Clean up resources
    backup      Create database backup
    restore     Restore from backup
    rollback    Rollback to previous version

OPTIONS:
    --dry-run           Show what would be deployed without executing
    --skip-tests        Skip pre-deployment tests
    --force             Force deployment even if health checks fail
    --image-tag TAG     Use specific image tag (default: latest)
    --help              Show this help message

EXAMPLES:
    $0 staging                          # Deploy to staging
    $0 production --image-tag v1.2.0    # Deploy specific version to production
    $0 health                           # Check current deployment health
    $0 monitor                          # Deploy monitoring stack

${ROMANIAN_FLAG} For the authentic Romanian card gaming experience! ${CROWN}
EOF
}

# Prerequisites check
check_prerequisites() {
    log_info "Checking deployment prerequisites..."
    
    local tools=("kubectl" "kustomize" "docker")
    local missing_tools=()
    
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        log_info "Please install the missing tools and try again"
        exit 1
    fi
    
    # Check kubectl connectivity
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot connect to Kubernetes cluster"
        log_info "Please configure kubectl and try again"
        exit 1
    fi
    
    log_success "All prerequisites satisfied"
}

# Namespace management
create_namespaces() {
    local env=$1
    log_info "Creating namespaces for $env environment..."
    
    case $env in
        "staging")
            kubectl create namespace "$STAGING_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
            kubectl label namespace "$STAGING_NAMESPACE" name="$STAGING_NAMESPACE" --overwrite
            ;;
        "production")
            kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
            kubectl label namespace "$NAMESPACE" name="$NAMESPACE" --overwrite
            ;;
        "monitor")
            kubectl create namespace "$MONITORING_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
            kubectl label namespace "$MONITORING_NAMESPACE" name="$MONITORING_NAMESPACE" --overwrite
            ;;
    esac
    
    log_success "Namespaces created successfully"
}

# Secret management
create_secrets() {
    local env=$1
    local namespace=$2
    
    log_info "Creating secrets for $env environment..."
    
    # Check if secrets already exist
    if kubectl get secret septica-secrets -n "$namespace" &> /dev/null; then
        log_warning "Secrets already exist in $namespace"
        return 0
    fi
    
    case $env in
        "staging"|"development")
            # Development/staging secrets (not for production use)
            kubectl create secret generic septica-secrets \
                --from-literal=DATABASE_URL="postgres://septica_staging:staging_password@postgres:5432/septica_staging?sslmode=require" \
                --from-literal=JWT_SECRET="staging-jwt-secret-key-not-for-production" \
                --from-literal=GAME_ENCRYPTION_KEY="staging-game-key-32-characters" \
                --from-literal=SESSION_SECRET="staging-session-secret-key" \
                -n "$namespace" \
                --dry-run=client -o yaml | kubectl apply -f -
            ;;
        "production")
            log_error "Production secrets must be created manually with secure values!"
            log_info "Please create production secrets before deploying:"
            log_info "kubectl create secret generic septica-secrets \\"
            log_info "  --from-literal=DATABASE_URL=\"postgres://septica_prod:SECURE_PASSWORD@postgres:5432/septica_prod?sslmode=require\" \\"
            log_info "  --from-literal=JWT_SECRET=\"YOUR_64_CHAR_JWT_SECRET\" \\"
            log_info "  --from-literal=GAME_ENCRYPTION_KEY=\"YOUR_32_CHAR_GAME_KEY\" \\"
            log_info "  --from-literal=SESSION_SECRET=\"YOUR_SESSION_SECRET\" \\"
            log_info "  -n $namespace"
            exit 1
            ;;
    esac
    
    log_success "Secrets created for $env"
}

# Pre-deployment tests
run_tests() {
    if [ "${SKIP_TESTS:-false}" = "true" ]; then
        log_warning "Skipping pre-deployment tests"
        return 0
    fi
    
    log_info "Running Romanian Septica pre-deployment tests..."
    
    # Romanian game rule validation
    log_romanian "Validating Romanian Septica game rules..."
    cd "$PROJECT_ROOT/backend"
    
    if go test -v ./internal/game/... | grep -q "PASS"; then
        log_success "Romanian game rules validation passed"
    else
        log_error "Romanian game rules validation failed"
        return 1
    fi
    
    # PWA functionality test
    log_romanian "Testing PWA functionality..."
    cd "$PROJECT_ROOT/frontend"
    
    if [ -f "manifest.json" ]; then
        if node -e "JSON.parse(require('fs').readFileSync('manifest.json', 'utf8'))" 2>/dev/null; then
            log_success "PWA manifest is valid"
        else
            log_error "PWA manifest is invalid"
            return 1
        fi
    fi
    
    cd "$PROJECT_ROOT"
    log_success "All pre-deployment tests passed"
}

# Build and push images
build_images() {
    local image_tag=${1:-latest}
    
    log_info "Building Romanian Septica container images..."
    
    # Build backend image
    log_romanian "Building backend game engine..."
    docker build -t "$REGISTRY/backend:$image_tag" ./backend/
    
    # Build frontend image
    log_romanian "Building PWA frontend with Romanian cultural assets..."
    docker build -t "$REGISTRY/frontend:$image_tag" ./frontend/
    
    if [ "${DRY_RUN:-false}" = "false" ]; then
        log_info "Pushing images to registry..."
        docker push "$REGISTRY/backend:$image_tag"
        docker push "$REGISTRY/frontend:$image_tag"
    fi
    
    log_success "Images built and pushed successfully"
}

# Deploy monitoring stack
deploy_monitoring() {
    log_info "Deploying monitoring stack for Romanian Septica..."
    
    create_namespaces "monitor"
    
    # Deploy Prometheus
    log_info "Deploying Prometheus with Romanian Septica metrics..."
    kubectl apply -f "$PROJECT_ROOT/k8s/monitoring/prometheus.yaml"
    
    # Deploy Grafana with Romanian game dashboards
    log_info "Deploying Grafana with Romanian cultural dashboards..."
    kubectl apply -f "$PROJECT_ROOT/k8s/monitoring/grafana.yaml"
    
    # Wait for monitoring to be ready
    log_info "Waiting for monitoring stack to be ready..."
    kubectl wait --for=condition=ready pod -l app=prometheus -n "$MONITORING_NAMESPACE" --timeout=300s
    kubectl wait --for=condition=ready pod -l app=grafana -n "$MONITORING_NAMESPACE" --timeout=300s
    
    log_success "Monitoring stack deployed successfully"
    log_romanian "Access Grafana at: kubectl port-forward svc/grafana 3000:3000 -n $MONITORING_NAMESPACE"
}

# Deploy application
deploy_app() {
    local env=$1
    local image_tag=${2:-latest}
    local namespace
    
    case $env in
        "staging")
            namespace="$STAGING_NAMESPACE"
            ;;
        "production")
            namespace="$NAMESPACE"
            ;;
        "development")
            namespace="septica-dev"
            ;;
    esac
    
    log_romanian "Deploying Romanian Septica to $env environment..."
    
    # Create namespace and secrets
    create_namespaces "$env"
    create_secrets "$env" "$namespace"
    
    # Update image tags in kustomization
    if [ "$image_tag" != "latest" ]; then
        log_info "Updating image tags to $image_tag..."
        # Update kustomization files with specific image tag
        sed -i.bak "s|newTag: latest|newTag: $image_tag|g" "$PROJECT_ROOT/k8s/overlays/$env/kustomization.yaml"
    fi
    
    # Deploy using Kustomize
    log_info "Applying Kubernetes manifests..."
    if [ "${DRY_RUN:-false}" = "true" ]; then
        kubectl kustomize "$PROJECT_ROOT/k8s/overlays/$env/"
    else
        kubectl apply -k "$PROJECT_ROOT/k8s/overlays/$env/"
    fi
    
    # Restore kustomization file if we modified it
    if [ "$image_tag" != "latest" ] && [ -f "$PROJECT_ROOT/k8s/overlays/$env/kustomization.yaml.bak" ]; then
        mv "$PROJECT_ROOT/k8s/overlays/$env/kustomization.yaml.bak" "$PROJECT_ROOT/k8s/overlays/$env/kustomization.yaml"
    fi
    
    if [ "${DRY_RUN:-false}" = "false" ]; then
        # Wait for deployment to complete
        log_info "Waiting for Romanian Septica deployment to complete..."
        kubectl rollout status deployment/septica-backend -n "$namespace" --timeout=600s
        kubectl rollout status deployment/septica-frontend -n "$namespace" --timeout=300s
        
        log_success "Romanian Septica deployed successfully to $env!"
        
        # Show deployment status
        show_status "$namespace"
    fi
}

# Health check
check_health() {
    local namespace=${1:-$NAMESPACE}
    
    log_info "Checking Romanian Septica health in $namespace..."
    
    # Check pods
    log_info "Pod status:"
    kubectl get pods -n "$namespace" -o wide
    
    # Check services
    log_info "Service status:"
    kubectl get svc -n "$namespace"
    
    # Check ingress
    log_info "Ingress status:"
    kubectl get ingress -n "$namespace" 2>/dev/null || log_warning "No ingress found"
    
    # Test health endpoints
    log_info "Testing health endpoints..."
    
    # Port forward and test backend health
    kubectl port-forward svc/septica-backend 8080:8080 -n "$namespace" &
    local pf_pid=$!
    sleep 5
    
    if curl -f http://localhost:8080/health &> /dev/null; then
        log_success "Backend health check passed"
    else
        log_error "Backend health check failed"
    fi
    
    kill $pf_pid 2>/dev/null || true
    
    # Check Romanian-specific metrics
    log_romanian "Checking Romanian Septica game metrics..."
    kubectl exec deployment/septica-backend -n "$namespace" -- curl -s http://localhost:8080/metrics | grep -E "septica_.*|websocket_.*|game_.*" | head -10 || log_warning "No metrics available"
}

# Show deployment status
show_status() {
    local namespace=${1:-$NAMESPACE}
    
    echo ""
    log_romanian "Romanian Septica Deployment Status"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Show pod status with colors
    echo -e "${BLUE}Pods:${NC}"
    kubectl get pods -n "$namespace" -o custom-columns="NAME:.metadata.name,STATUS:.status.phase,READY:.status.containerStatuses[*].ready,RESTARTS:.status.containerStatuses[*].restartCount,AGE:.metadata.creationTimestamp" | while read -r line; do
        if echo "$line" | grep -q "Running.*true"; then
            echo -e "${GREEN}✅ $line${NC}"
        elif echo "$line" | grep -q "Pending\|ContainerCreating"; then
            echo -e "${YELLOW}⏳ $line${NC}"
        else
            echo -e "${RED}❌ $line${NC}"
        fi
    done
    
    echo ""
    echo -e "${BLUE}Services:${NC}"
    kubectl get svc -n "$namespace"
    
    echo ""
    if kubectl get ingress -n "$namespace" &> /dev/null; then
        echo -e "${BLUE}Ingress:${NC}"
        kubectl get ingress -n "$namespace"
        echo ""
        log_romanian "Access Romanian Septica at: https://septica.ro"
    fi
    
    echo ""
    log_success "Deployment status displayed"
}

# Backup database
backup_database() {
    local namespace=${1:-$NAMESPACE}
    local backup_file="septica_backup_$(date +%Y%m%d_%H%M%S).sql"
    
    log_info "Creating database backup: $backup_file"
    
    kubectl exec deployment/postgres -n "$namespace" -- pg_dump -U septica_prod septica_prod > "$backup_file"
    
    log_success "Database backup created: $backup_file"
    log_info "Backup size: $(du -h "$backup_file" | cut -f1)"
}

# Restore database
restore_database() {
    local backup_file=$1
    local namespace=${2:-$NAMESPACE}
    
    if [ ! -f "$backup_file" ]; then
        log_error "Backup file not found: $backup_file"
        exit 1
    fi
    
    log_warning "This will restore the database from $backup_file"
    read -p "Are you sure? (yes/no): " -r
    if [[ ! $REPLY =~ ^yes$ ]]; then
        log_info "Database restore cancelled"
        exit 0
    fi
    
    log_info "Restoring database from $backup_file..."
    kubectl exec -i deployment/postgres -n "$namespace" -- psql -U septica_prod -d septica_prod < "$backup_file"
    
    log_success "Database restored successfully"
}

# Rollback deployment
rollback_deployment() {
    local namespace=${1:-$NAMESPACE}
    
    log_warning "Rolling back Romanian Septica deployment..."
    
    kubectl rollout undo deployment/septica-backend -n "$namespace"
    kubectl rollout undo deployment/septica-frontend -n "$namespace"
    
    # Wait for rollback to complete
    kubectl rollout status deployment/septica-backend -n "$namespace" --timeout=300s
    kubectl rollout status deployment/septica-frontend -n "$namespace" --timeout=300s
    
    log_success "Rollback completed successfully"
}

# Clean up resources
cleanup() {
    local env=${1:-"all"}
    
    log_warning "Cleaning up Romanian Septica resources..."
    
    case $env in
        "staging")
            kubectl delete namespace "$STAGING_NAMESPACE" --ignore-not-found=true
            ;;
        "production")
            log_error "Production cleanup must be done manually for safety"
            log_info "To cleanup production: kubectl delete namespace $NAMESPACE"
            exit 1
            ;;
        "monitor")
            kubectl delete namespace "$MONITORING_NAMESPACE" --ignore-not-found=true
            ;;
        "all")
            kubectl delete namespace "$STAGING_NAMESPACE" --ignore-not-found=true
            kubectl delete namespace "$MONITORING_NAMESPACE" --ignore-not-found=true
            log_warning "Production namespace not deleted (manual action required)"
            ;;
    esac
    
    log_success "Cleanup completed"
}

# Main function
main() {
    local command=${1:-""}
    local env=""
    local image_tag="latest"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help)
                show_help
                exit 0
                ;;
            --dry-run)
                export DRY_RUN=true
                log_info "Dry run mode enabled"
                ;;
            --skip-tests)
                export SKIP_TESTS=true
                ;;
            --force)
                export FORCE=true
                ;;
            --image-tag)
                image_tag="$2"
                shift
                ;;
            dev|development)
                command="deploy"
                env="development"
                ;;
            staging)
                command="deploy"
                env="staging"
                ;;
            production)
                command="deploy"
                env="production"
                ;;
            monitor)
                command="monitor"
                ;;
            health)
                command="health"
                ;;
            clean)
                command="clean"
                ;;
            backup)
                command="backup"
                ;;
            restore)
                command="restore"
                ;;
            rollback)
                command="rollback"
                ;;
            *)
                if [ -z "$command" ]; then
                    command="$1"
                fi
                ;;
        esac
        shift
    done
    
    # Show header
    echo ""
    echo -e "${PURPLE}${ROMANIAN_FLAG}${ROMANIAN_FLAG}${ROMANIAN_FLAG} ROMANIAN SEPTICA DEPLOYMENT ${ROMANIAN_FLAG}${ROMANIAN_FLAG}${ROMANIAN_FLAG}${NC}"
    echo -e "${BLUE}Authentic Romanian Card Game Platform${NC}"
    echo -e "${YELLOW}Bringing traditional Romanian gaming to the world! ${CARD_GAME}${NC}"
    echo ""
    
    # Check prerequisites
    check_prerequisites
    
    # Execute command
    case $command in
        deploy)
            if [ -z "$env" ]; then
                log_error "Environment not specified"
                show_help
                exit 1
            fi
            
            run_tests
            if [ "$env" = "production" ] || [ "$env" = "staging" ]; then
                build_images "$image_tag"
            fi
            deploy_app "$env" "$image_tag"
            ;;
        monitor)
            deploy_monitoring
            ;;
        health)
            check_health
            ;;
        backup)
            backup_database
            ;;
        restore)
            if [ $# -eq 0 ]; then
                log_error "Backup file not specified"
                log_info "Usage: $0 restore <backup_file>"
                exit 1
            fi
            restore_database "$1"
            ;;
        rollback)
            rollback_deployment
            ;;
        clean)
            cleanup "$env"
            ;;
        "")
            log_error "No command specified"
            show_help
            exit 1
            ;;
        *)
            log_error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
    
    echo ""
    log_romanian "Romanian Septica deployment operation completed! ${TROPHY}"
    echo -e "${YELLOW}May the best Romanian card player win! ${CROWN}${NC}"
    echo ""
}

# Execute main function with all arguments
main "$@"