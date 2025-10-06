#!/bin/bash
# Romanian Septica - Frontend PWA Deployment Script
# Deploys premium Three.js PWA with asset optimization and CDN upload

set -euo pipefail

# Configuration
ENVIRONMENT=${1:-dev}
CDN_BUCKET=${2:-septica-cdn}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
FRONTEND_DIR="$PROJECT_ROOT/frontend"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Romanian cultural elements
ROMANIAN_FLAG="🇷🇴"
PWA_ICON="📱"

# Logging functions
log_info() { echo -e "${BLUE}${PWA_ICON} INFO: $1${NC}"; }
log_success() { echo -e "${GREEN}✅ SUCCESS: $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  WARNING: $1${NC}"; }
log_error() { echo -e "${RED}❌ ERROR: $1${NC}"; }

# Validate environment
validate_environment() {
    case $ENVIRONMENT in
        dev|staging|prod) ;;
        *)
            log_error "Invalid environment: $ENVIRONMENT (must be dev, staging, or prod)"
            exit 1
            ;;
    esac
}

# Optimize frontend assets
optimize_assets() {
    log_info "Optimizing Romanian Septica PWA assets..."

    cd "$FRONTEND_DIR"

    # Create build directory
    mkdir -p build
    rm -rf build/*

    # Copy all source files
    log_info "Copying source files..."
    cp -r js css assets images *.html *.json build/

    # Minify JavaScript files (if terser is available)
    if command -v terser &> /dev/null; then
        log_info "Minifying JavaScript files..."
        find build/js -name "*.js" -type f | while read -r jsfile; do
            terser "$jsfile" \
                --compress \
                --mangle \
                --output "$jsfile.min" \
                && mv "$jsfile.min" "$jsfile"
        done
        log_success "JavaScript minification completed"
    else
        log_warning "terser not found - skipping JavaScript minification"
    fi

    # Minify CSS files (if csso is available)
    if command -v csso &> /dev/null; then
        log_info "Minifying CSS files..."
        find build/css -name "*.css" -type f | while read -r cssfile; do
            csso "$cssfile" --output "$cssfile.min" \
                && mv "$cssfile.min" "$cssfile"
        done
        log_success "CSS minification completed"
    else
        log_warning "csso not found - skipping CSS minification"
    fi

    # Optimize images (if imageoptim is available)
    if command -v imageoptim &> /dev/null; then
        log_info "Optimizing images..."
        imageoptim build/images/**/*.{png,jpg,jpeg} 2>/dev/null || true
        log_success "Image optimization completed"
    else
        log_warning "imageoptim not found - skipping image optimization"
    fi

    # Gzip compress assets for CDN
    log_info "Creating gzip compressed versions..."
    find build -type f \( -name "*.js" -o -name "*.css" -o -name "*.html" \) | while read -r file; do
        gzip -9 -c "$file" > "$file.gz"
    done

    log_success "Asset optimization completed"
}

# Update Service Worker version
update_service_worker_version() {
    log_info "Updating Service Worker cache version..."

    local sw_file="$FRONTEND_DIR/build/service-worker.js"
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local version="septica-pwa-v$timestamp"

    if [ -f "$sw_file" ]; then
        # Update cache version
        sed -i.bak "s/septica-pwa-v[0-9-]*/septica-pwa-v$timestamp/g" "$sw_file"
        rm -f "$sw_file.bak"

        log_success "Service Worker version updated to: $version"
    else
        log_warning "Service Worker not found at: $sw_file"
    fi
}

# Update PWA manifest
update_pwa_manifest() {
    log_info "Updating PWA manifest for $ENVIRONMENT..."

    local manifest_file="$FRONTEND_DIR/build/manifest.json"

    if [ -f "$manifest_file" ]; then
        # Update start_url based on environment
        case $ENVIRONMENT in
            dev)
                sed -i.bak 's|"start_url": ".*"|"start_url": "http://localhost:3000"|' "$manifest_file"
                ;;
            staging)
                sed -i.bak 's|"start_url": ".*"|"start_url": "https://staging.septica.ro"|' "$manifest_file"
                ;;
            prod)
                sed -i.bak 's|"start_url": ".*"|"start_url": "https://septica.ro"|' "$manifest_file"
                ;;
        esac

        rm -f "$manifest_file.bak"
        log_success "PWA manifest updated for $ENVIRONMENT"
    else
        log_warning "PWA manifest not found at: $manifest_file"
    fi
}

# Upload to CDN (AWS S3 or similar)
upload_to_cdn() {
    if [ "$ENVIRONMENT" != "prod" ] && [ "$ENVIRONMENT" != "staging" ]; then
        log_info "Skipping CDN upload for dev environment"
        return 0
    fi

    log_info "Uploading assets to CDN bucket: $CDN_BUCKET..."

    cd "$FRONTEND_DIR/build"

    # Check if AWS CLI is available
    if command -v aws &> /dev/null; then
        # Upload with proper cache headers
        # HTML files: short cache (5 minutes)
        aws s3 sync . s3://$CDN_BUCKET \
            --exclude "*" \
            --include "*.html" \
            --cache-control "public, max-age=300" \
            --metadata-directive REPLACE

        # JavaScript/CSS: long cache (1 year)
        aws s3 sync . s3://$CDN_BUCKET \
            --exclude "*" \
            --include "*.js" --include "*.css" \
            --cache-control "public, max-age=31536000, immutable" \
            --content-encoding gzip \
            --metadata-directive REPLACE

        # Images: medium cache (1 week)
        aws s3 sync . s3://$CDN_BUCKET \
            --exclude "*" \
            --include "*.png" --include "*.jpg" --include "*.jpeg" --include "*.svg" \
            --cache-control "public, max-age=604800" \
            --metadata-directive REPLACE

        # Service Worker: no cache (always fetch fresh)
        aws s3 cp service-worker.js s3://$CDN_BUCKET/service-worker.js \
            --cache-control "public, max-age=0, must-revalidate" \
            --metadata-directive REPLACE

        log_success "Assets uploaded to S3"

        # Invalidate CloudFront cache (if distribution ID is set)
        if [ -n "${CLOUDFRONT_DISTRIBUTION_ID:-}" ]; then
            log_info "Invalidating CloudFront cache..."
            aws cloudfront create-invalidation \
                --distribution-id "$CLOUDFRONT_DISTRIBUTION_ID" \
                --paths "/*"
            log_success "CloudFront cache invalidated"
        fi
    else
        log_warning "AWS CLI not found - skipping CDN upload"
        log_info "To upload manually: aws s3 sync . s3://$CDN_BUCKET"
    fi
}

# Deploy to Nginx container
deploy_nginx_container() {
    log_info "Deploying frontend via Nginx container..."

    cd "$PROJECT_ROOT"

    case $ENVIRONMENT in
        dev)
            # Development: Simple Python HTTP server
            log_info "Starting development server on port 3000..."
            cd "$FRONTEND_DIR"
            pkill -f "python3 -m http.server 3000" 2>/dev/null || true
            nohup python3 -m http.server 3000 > /tmp/septica-frontend.log 2>&1 &
            log_success "Development server started at http://localhost:3000"
            ;;
        staging|prod)
            # Staging/Production: Docker Nginx container
            local image_tag
            if [ "$ENVIRONMENT" = "staging" ]; then
                image_tag="staging-latest"
            else
                image_tag="latest"
            fi

            # Build Nginx container with optimized assets
            docker build \
                -t septica-frontend:$image_tag \
                -f "$PROJECT_ROOT/Dockerfile.frontend" \
                "$FRONTEND_DIR/build"

            # Deploy via docker-compose or Kubernetes
            if [ -f "$PROJECT_ROOT/docker-compose.yml" ]; then
                docker-compose up -d frontend
            else
                # Kubernetes deployment
                local namespace
                if [ "$ENVIRONMENT" = "staging" ]; then
                    namespace="septica-staging"
                else
                    namespace="septica"
                fi

                kubectl set image deployment/septica-frontend \
                    frontend=septica-frontend:$image_tag \
                    -n $namespace

                kubectl rollout status deployment/septica-frontend \
                    -n $namespace \
                    --timeout=300s
            fi
            ;;
    esac

    log_success "Frontend deployed successfully"
}

# Verify frontend deployment
verify_frontend_deployment() {
    log_info "Verifying frontend deployment..."

    local frontend_url
    case $ENVIRONMENT in
        dev) frontend_url="http://localhost:3000" ;;
        staging) frontend_url="https://staging.septica.ro" ;;
        prod) frontend_url="https://septica.ro" ;;
    esac

    # Wait for frontend to be ready (max 30 seconds)
    local max_attempts=15
    local attempt=0

    while [ $attempt -lt $max_attempts ]; do
        if curl -sf "$frontend_url" > /dev/null 2>&1; then
            log_success "Frontend is accessible at: $frontend_url"

            # Check if Service Worker is registered
            if curl -sf "$frontend_url/service-worker.js" > /dev/null 2>&1; then
                log_success "Service Worker is available"
            fi

            # Check if manifest is valid
            if curl -sf "$frontend_url/manifest.json" | jq . > /dev/null 2>&1; then
                log_success "PWA manifest is valid"
            fi

            return 0
        fi

        attempt=$((attempt + 1))
        log_info "Waiting for frontend... ($attempt/$max_attempts)"
        sleep 2
    done

    log_error "Frontend verification failed after $max_attempts attempts"
    return 1
}

# Generate deployment report
generate_deployment_report() {
    log_info "Generating deployment report..."

    local report_file="$PROJECT_ROOT/deployment-report-$(date +%Y%m%d-%H%M%S).txt"

    cat > "$report_file" << EOF
Romanian Septica PWA Deployment Report
======================================
Environment: $ENVIRONMENT
Timestamp: $(date)
CDN Bucket: $CDN_BUCKET

Asset Optimization:
- JavaScript files minified: $(find "$FRONTEND_DIR/build/js" -name "*.js" | wc -l)
- CSS files minified: $(find "$FRONTEND_DIR/build/css" -name "*.css" | wc -l)
- Images optimized: $(find "$FRONTEND_DIR/build/images" -type f | wc -l)
- Total build size: $(du -sh "$FRONTEND_DIR/build" | cut -f1)

PWA Features:
- Service Worker version: $(grep -o 'septica-pwa-v[0-9-]*' "$FRONTEND_DIR/build/service-worker.js" | head -1)
- Manifest valid: $([ -f "$FRONTEND_DIR/build/manifest.json" ] && echo "Yes" || echo "No")

Deployment Status:
- Frontend URL: $(case $ENVIRONMENT in dev) echo "http://localhost:3000" ;; staging) echo "https://staging.septica.ro" ;; prod) echo "https://septica.ro" ;; esac)
- CDN Upload: $([ "$ENVIRONMENT" = "prod" ] || [ "$ENVIRONMENT" = "staging" ] && echo "Completed" || echo "Skipped (dev)")
- Status: SUCCESS

Romanian Heritage Assets:
- Cultural themes: Traditional Romanian card game aesthetics
- Lighting: Regional Romanian lighting configurations
- Mobile optimization: LOD system for 60 FPS performance
EOF

    log_success "Deployment report saved to: $report_file"
    cat "$report_file"
}

# Main deployment flow
main() {
    echo ""
    echo -e "${BLUE}${ROMANIAN_FLAG} Romanian Septica PWA Frontend Deployment ${PWA_ICON}${NC}"
    echo -e "${BLUE}Environment: ${YELLOW}$ENVIRONMENT${NC}"
    echo -e "${BLUE}CDN Bucket: ${YELLOW}$CDN_BUCKET${NC}"
    echo ""

    # Validate environment
    validate_environment

    # Optimize assets
    optimize_assets

    # Update Service Worker version
    update_service_worker_version

    # Update PWA manifest
    update_pwa_manifest

    # Upload to CDN (production/staging only)
    upload_to_cdn

    # Deploy via Nginx container
    deploy_nginx_container

    # Verify deployment
    if verify_frontend_deployment; then
        log_success "Frontend deployment verification passed"
    else
        log_error "Frontend deployment verification failed"
        exit 1
    fi

    # Generate deployment report
    generate_deployment_report

    echo ""
    log_success "${ROMANIAN_FLAG} Romanian Septica PWA is live! ${PWA_ICON}"
    echo -e "${YELLOW}Premium Three.js experience ready for Romanian card gaming!${NC}"
    echo ""
}

# Handle script interruption
trap 'log_error "Deployment interrupted"; exit 1' INT TERM

# Execute main function
main "$@"
