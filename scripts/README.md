# Romanian Septica - Deployment Scripts

This directory contains automated deployment scripts for the Romanian Septica multiplayer card game platform.

## Overview

The deployment automation suite provides comprehensive tools for deploying, monitoring, and maintaining the Romanian Septica platform across multiple environments (development, staging, production).

### Platform Architecture
- **Backend**: Go server with PostgreSQL database and WebSocket multiplayer
- **Frontend**: Premium Three.js PWA with Romanian cultural assets
- **iOS**: Native iOS app for App Store distribution
- **Infrastructure**: Kubernetes orchestration with Docker containers

## Scripts

### 1. Backend Deployment (`deploy-backend.sh`)

Deploys the Go backend with database migration handling and health verification.

**Usage:**
```bash
./scripts/deploy-backend.sh [environment] [version]
```

**Examples:**
```bash
# Deploy to development
./scripts/deploy-backend.sh dev latest

# Deploy to staging with specific version
./scripts/deploy-backend.sh staging v1.2.0

# Deploy to production
./scripts/deploy-backend.sh prod v1.2.0
```

**Features:**
- Romanian Septica game engine testing
- Database migration handling (with GORM workaround)
- Docker image building
- Health check verification
- Automatic rollback on failure

**Environment Variables:**
- `SKIP_MIGRATIONS`: Skip database migrations (default: false)
- `STAGING_DATABASE_URL`: Staging database connection string
- `PRODUCTION_DATABASE_URL`: Production database connection string

### 2. Frontend Deployment (`deploy-frontend.sh`)

Deploys the premium PWA frontend with asset optimization and CDN upload.

**Usage:**
```bash
./scripts/deploy-frontend.sh [environment] [cdn_bucket]
```

**Examples:**
```bash
# Deploy to development
./scripts/deploy-frontend.sh dev

# Deploy to staging with CDN
./scripts/deploy-frontend.sh staging septica-staging-cdn

# Deploy to production
./scripts/deploy-frontend.sh prod septica-cdn
```

**Features:**
- JavaScript/CSS minification (requires terser, csso)
- Image optimization (requires imageoptim)
- Service Worker version bumping
- PWA manifest configuration
- Gzip compression for CDN
- S3/CloudFront upload and cache invalidation

**Environment Variables:**
- `CDN_BUCKET`: S3 bucket name for CDN assets
- `CLOUDFRONT_DISTRIBUTION_ID`: CloudFront distribution for cache invalidation
- `AWS_ACCESS_KEY_ID`: AWS access key
- `AWS_SECRET_ACCESS_KEY`: AWS secret key

### 3. Database Backup (`backup-database.sh`)

Automated PostgreSQL backups with compression, encryption, and cloud storage.

**Usage:**
```bash
./scripts/backup-database.sh [backup_dir] [environment]
```

**Examples:**
```bash
# Backup development database
./scripts/backup-database.sh ./backups dev

# Backup production with S3 upload
S3_BUCKET=septica-backups ./scripts/backup-database.sh ./backups prod

# Backup with encryption
ENCRYPT_BACKUP=true GPG_RECIPIENT=admin@septica.ro ./scripts/backup-database.sh ./backups prod
```

**Features:**
- PostgreSQL dump with compression (gzip -9)
- Optional GPG encryption
- S3 upload with lifecycle policies
- Automatic cleanup (30-day retention)
- Backup integrity verification

**Environment Variables:**
- `S3_BUCKET`: S3 bucket for backup storage (default: septica-backups)
- `S3_PREFIX`: S3 prefix for backups (default: database-backups)
- `ENCRYPT_BACKUP`: Enable GPG encryption (default: false)
- `GPG_RECIPIENT`: GPG recipient for encryption
- `RETENTION_DAYS`: Backup retention in days (default: 30)

### 4. iOS Build & Upload (`deploy-ios.sh`)

Automated Xcode archiving and App Store Connect upload.

**Usage:**
```bash
./scripts/deploy-ios.sh [version] [build_number] [environment]
```

**Examples:**
```bash
# Build for TestFlight
./scripts/deploy-ios.sh 1.0.0 20251007 testflight

# Build for production
APP_STORE_PASSWORD=@keychain:AC_PASSWORD ./scripts/deploy-ios.sh 1.0.0 20251007 production

# Build without upload
SKIP_UPLOAD=true ./scripts/deploy-ios.sh 1.0.0 20251007 production
```

**Features:**
- Xcode project/workspace detection
- Version and build number management
- Unit test execution
- Archive creation and IPA export
- App Store Connect validation
- TestFlight/App Store upload

**Environment Variables:**
- `APP_STORE_EMAIL`: App Store Connect email
- `APP_STORE_PASSWORD`: App Store Connect password (use keychain)
- `APP_STORE_TEAM_ID`: Apple Developer Team ID
- `SKIP_TESTS`: Skip unit tests (default: false)
- `SKIP_UPLOAD`: Skip upload to App Store Connect (default: false)

**Prerequisites:**
- macOS with Xcode installed
- Xcode Command Line Tools
- Valid Apple Developer account
- App-specific password in keychain

### 5. Rollback (`rollback.sh`)

Quick rollback to previous version with database restoration support.

**Usage:**
```bash
./scripts/rollback.sh [component] [environment] [previous_version]
```

**Examples:**
```bash
# Rollback backend only
./scripts/rollback.sh backend prod previous

# Rollback frontend to specific version
./scripts/rollback.sh frontend staging v1.1.0

# Rollback everything
./scripts/rollback.sh all prod previous

# Rollback database (requires confirmation)
./scripts/rollback.sh database prod
```

**Features:**
- Component-specific rollback (backend, frontend, database)
- Kubernetes deployment rollback
- Docker image version tagging
- Database restoration from backup
- Health verification after rollback
- Production safety confirmations

**Safety Features:**
- Production rollback requires typing "ROLLBACK PRODUCTION"
- Database rollback requires typing "RESTORE DATABASE"
- Automatic health checks post-rollback
- Rollback report generation

### 6. Health Check (`health-check.sh`)

Comprehensive health monitoring for all services with automated alerts.

**Usage:**
```bash
./scripts/health-check.sh [environment] [alert_mode]
```

**Examples:**
```bash
# Basic health check
./scripts/health-check.sh dev

# Health check with Slack alerts
SLACK_WEBHOOK_URL=https://hooks.slack.com/... ./scripts/health-check.sh prod slack

# Health check with email alerts
./scripts/health-check.sh staging email
```

**Features:**
- Backend health endpoint monitoring
- Frontend availability checks
- Database connectivity verification
- Service Worker and PWA manifest validation
- System resource monitoring (CPU, memory)
- Romanian Septica game metrics
- Error log analysis
- Performance threshold checks

**Alert Modes:**
- `report`: Generate report only (default)
- `slack`: Send Slack notifications
- `email`: Send email notifications
- `pagerduty`: Send PagerDuty alerts (not implemented)

**Environment Variables:**
- `SLACK_WEBHOOK_URL`: Slack webhook for alerts
- `ALERT_EMAIL`: Email address for alerts (default: admin@septica.ro)
- `PAGERDUTY_KEY`: PagerDuty integration key

**Health Thresholds:**
- Max response time: 2000ms
- Max CPU usage: 80%
- Max error rate: 1%

**Exit Codes:**
- `0`: All systems healthy
- `1`: Degraded performance
- `2`: Unhealthy systems

### 7. Master Deployment Script (`deploy.sh`)

Comprehensive deployment orchestration for all components.

**Usage:**
```bash
./scripts/deploy.sh [command] [options]
```

**Commands:**
- `dev`: Deploy to development
- `staging`: Deploy to staging
- `production`: Deploy to production
- `monitor`: Deploy monitoring stack
- `health`: Check deployment health
- `backup`: Create database backup
- `rollback`: Rollback deployment
- `clean`: Clean up resources

**Examples:**
```bash
# Deploy to staging
./scripts/deploy.sh staging

# Deploy to production with specific version
./scripts/deploy.sh production --image-tag v1.2.0

# Deploy monitoring stack
./scripts/deploy.sh monitor

# Dry run (preview changes)
./scripts/deploy.sh staging --dry-run

# Skip tests
./scripts/deploy.sh staging --skip-tests
```

**Options:**
- `--dry-run`: Show what would be deployed without executing
- `--skip-tests`: Skip pre-deployment tests
- `--force`: Force deployment even if health checks fail
- `--image-tag TAG`: Use specific image tag (default: latest)
- `--help`: Show help message

## CI/CD GitHub Actions

The `.github/workflows/deploy.yml` workflow automates deployment on:
- **Tag push** (`v*`): Deploy to production
- **Main branch push**: Deploy to staging
- **Pull requests**: Run tests only

### Workflow Jobs

1. **Backend Tests**: Romanian Septica game rules validation
2. **Frontend Tests**: PWA manifest and Service Worker validation
3. **Build & Push**: Docker image building and registry upload
4. **Deploy Staging**: Automatic staging deployment
5. **Deploy Production**: Production deployment on version tags
6. **Deploy iOS**: iOS build and App Store upload
7. **Security Scan**: Vulnerability scanning with Trivy
8. **Performance Tests**: Load testing and response time validation

### Required Secrets

Configure these secrets in GitHub repository settings:

**Kubernetes:**
- `KUBECONFIG_STAGING`: Base64-encoded kubeconfig for staging
- `KUBECONFIG_PRODUCTION`: Base64-encoded kubeconfig for production

**iOS:**
- `APP_STORE_PASSWORD`: App Store Connect app-specific password
- `APP_STORE_EMAIL`: App Store Connect email
- `APP_STORE_TEAM_ID`: Apple Developer Team ID

**Optional:**
- `SLACK_WEBHOOK_URL`: Slack webhook for deployment notifications
- `AWS_ACCESS_KEY_ID`: AWS access key for S3/CloudFront
- `AWS_SECRET_ACCESS_KEY`: AWS secret key

## Environment Configuration

### Development
- **Backend**: http://localhost:8082
- **Frontend**: http://localhost:3000
- **Database**: PostgreSQL on port 5433
- **Deployment**: Docker Compose

### Staging
- **Backend**: https://staging.septica.ro/api
- **Frontend**: https://staging.septica.ro
- **Namespace**: septica-staging
- **Deployment**: Kubernetes

### Production
- **Backend**: https://septica.ro/api
- **Frontend**: https://septica.ro
- **Namespace**: septica
- **Deployment**: Kubernetes
- **CDN**: CloudFront + S3

## Best Practices

### Pre-Deployment Checklist
1. Run tests locally: `go test ./... && npm test`
2. Verify Romanian game rules: `go test ./internal/game/...`
3. Create database backup: `./scripts/backup-database.sh`
4. Run health check: `./scripts/health-check.sh dev`
5. Review deployment diff: `./scripts/deploy.sh staging --dry-run`

### Production Deployment
1. **Always tag releases**: `git tag -a v1.2.0 -m "Release 1.2.0"`
2. **Create backup first**: `./scripts/backup-database.sh ./backups prod`
3. **Monitor during deployment**: Watch logs and metrics
4. **Verify health**: `./scripts/health-check.sh prod`
5. **Be ready to rollback**: `./scripts/rollback.sh all prod`

### Database Migrations
⚠️ **CRITICAL**: Current GORM migration issue requires workaround
- Use `SKIP_MIGRATIONS=true` for backend deployment
- Run migrations manually after deployment
- See `docs/TECHNICAL_DEBT.md` for details

### Rollback Procedures
1. Identify failed component (backend/frontend/database)
2. Check latest backup: `ls -lt backups/`
3. Execute rollback: `./scripts/rollback.sh [component] prod`
4. Verify health: `./scripts/health-check.sh prod`
5. Document incident and root cause

## Monitoring & Alerts

### Health Check Automation
Schedule regular health checks with cron:
```bash
# Every 5 minutes
*/5 * * * * /path/to/scripts/health-check.sh prod slack
```

### Metrics to Monitor
- Backend response time (<2s)
- Frontend load time (<2s)
- Database connection count
- WebSocket active connections
- Active Romanian Septica games
- Error rate (<1%)

### Alert Thresholds
- **Critical**: Backend down, database unreachable
- **Warning**: Slow response times, high CPU usage
- **Info**: Deployment completed, backup created

## Troubleshooting

### Backend Deployment Fails
```bash
# Check backend logs
docker logs septica-backend  # dev
kubectl logs deployment/septica-backend -n septica  # prod

# Verify database connectivity
docker exec septica-postgres pg_isready -U septica

# Rollback if needed
./scripts/rollback.sh backend prod
```

### Frontend Not Loading
```bash
# Check frontend logs
docker logs septica-frontend  # dev
kubectl logs deployment/septica-frontend -n septica  # prod

# Verify Service Worker
curl -I https://septica.ro/service-worker.js

# Clear CDN cache
aws cloudfront create-invalidation --distribution-id ID --paths "/*"
```

### Database Migration Issues
```bash
# Manual migration with GORM workaround
cd backend
SKIP_MIGRATIONS=false DATABASE_URL=postgres://... go run cmd/server/main.go

# Restore from backup if needed
./scripts/rollback.sh database prod
```

### iOS Build Failures
```bash
# Clean Xcode build
xcodebuild clean -project Septica.xcodeproj -scheme Septica

# Update provisioning profiles
fastlane match development  # if using fastlane

# Check signing certificates
security find-identity -v -p codesigning
```

## Additional Resources

- **Project Documentation**: `/docs/PROJECT_STATUS.md`
- **Technical Debt**: `/docs/TECHNICAL_DEBT.md`
- **Game Rules**: `/docs/game-rules.md`
- **API Documentation**: `/docs/backend-api.md`
- **Kubernetes Configuration**: `/k8s/`
- **Docker Configuration**: `/docker-compose.yml`

## Support

For deployment issues or questions:
1. Check logs: `./scripts/health-check.sh [environment]`
2. Review documentation in `/docs/`
3. Check GitHub Issues
4. Contact DevOps team

---

**🇷🇴 Romanian Septica** - Preserving Romanian card gaming heritage through modern technology.
