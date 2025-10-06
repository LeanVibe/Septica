#!/bin/bash
# Romanian Septica - Database Backup Script
# Automated PostgreSQL backups with compression, encryption, and cloud storage

set -euo pipefail

# Configuration
BACKUP_DIR=${1:-./backups}
ENVIRONMENT=${2:-dev}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Database configuration
DB_CONTAINER="septica-postgres"
DB_USER="septica"
DB_NAME="septica"
DB_PORT="5433"

# Backup settings
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="septica_backup_${ENVIRONMENT}_${TIMESTAMP}.sql.gz"
RETENTION_DAYS=30

# S3 configuration (optional)
S3_BUCKET=${S3_BUCKET:-septica-backups}
S3_PREFIX=${S3_PREFIX:-database-backups}

# Encryption settings (optional)
ENCRYPT_BACKUP=${ENCRYPT_BACKUP:-false}
GPG_RECIPIENT=${GPG_RECIPIENT:-admin@septica.ro}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Romanian cultural elements
ROMANIAN_FLAG="🇷🇴"
BACKUP_ICON="💾"

# Logging functions
log_info() { echo -e "${BLUE}${BACKUP_ICON} INFO: $1${NC}"; }
log_success() { echo -e "${GREEN}✅ SUCCESS: $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  WARNING: $1${NC}"; }
log_error() { echo -e "${RED}❌ ERROR: $1${NC}"; }

# Create backup directory
create_backup_directory() {
    log_info "Creating backup directory: $BACKUP_DIR"

    mkdir -p "$BACKUP_DIR"

    # Set secure permissions
    chmod 700 "$BACKUP_DIR"

    log_success "Backup directory ready"
}

# Check database connectivity
check_database_connection() {
    log_info "Checking database connection..."

    case $ENVIRONMENT in
        dev)
            # Check local Docker container
            if ! docker ps | grep -q "$DB_CONTAINER"; then
                log_error "Database container not running: $DB_CONTAINER"
                log_info "Start it with: docker-compose up -d postgres"
                exit 1
            fi

            # Test connection
            if docker exec "$DB_CONTAINER" pg_isready -U "$DB_USER" > /dev/null 2>&1; then
                log_success "Database connection verified"
            else
                log_error "Cannot connect to database"
                exit 1
            fi
            ;;
        staging|prod)
            # Check Kubernetes pod
            local namespace
            if [ "$ENVIRONMENT" = "staging" ]; then
                namespace="septica-staging"
            else
                namespace="septica"
            fi

            if ! kubectl get pod -n "$namespace" -l app=postgres | grep -q "Running"; then
                log_error "Database pod not running in namespace: $namespace"
                exit 1
            fi

            log_success "Database pod is running"
            ;;
    esac
}

# Create database backup
create_backup() {
    log_info "Creating database backup for $ENVIRONMENT environment..."

    case $ENVIRONMENT in
        dev)
            # Local Docker backup
            log_info "Backing up from Docker container: $DB_CONTAINER"

            docker exec "$DB_CONTAINER" pg_dump \
                -U "$DB_USER" \
                -d "$DB_NAME" \
                --clean \
                --if-exists \
                --create \
                --verbose \
                | gzip -9 > "$BACKUP_DIR/$BACKUP_FILE"
            ;;
        staging|prod)
            # Kubernetes pod backup
            local namespace
            if [ "$ENVIRONMENT" = "staging" ]; then
                namespace="septica-staging"
            else
                namespace="septica"
            fi

            log_info "Backing up from Kubernetes pod in namespace: $namespace"

            kubectl exec deployment/postgres -n "$namespace" -- \
                pg_dump \
                -U "$DB_USER" \
                -d "$DB_NAME" \
                --clean \
                --if-exists \
                --create \
                --verbose \
                | gzip -9 > "$BACKUP_DIR/$BACKUP_FILE"
            ;;
    esac

    # Verify backup file was created
    if [ ! -f "$BACKUP_DIR/$BACKUP_FILE" ]; then
        log_error "Backup file was not created"
        exit 1
    fi

    # Check backup file is not empty
    if [ ! -s "$BACKUP_DIR/$BACKUP_FILE" ]; then
        log_error "Backup file is empty"
        rm -f "$BACKUP_DIR/$BACKUP_FILE"
        exit 1
    fi

    log_success "Database backup created: $BACKUP_FILE"
}

# Encrypt backup (optional)
encrypt_backup() {
    if [ "$ENCRYPT_BACKUP" != "true" ]; then
        log_info "Backup encryption disabled (set ENCRYPT_BACKUP=true to enable)"
        return 0
    fi

    log_info "Encrypting backup with GPG..."

    # Check if GPG is available
    if ! command -v gpg &> /dev/null; then
        log_warning "GPG not found - skipping encryption"
        return 0
    fi

    # Encrypt backup file
    gpg --encrypt \
        --recipient "$GPG_RECIPIENT" \
        --output "$BACKUP_DIR/$BACKUP_FILE.gpg" \
        "$BACKUP_DIR/$BACKUP_FILE"

    # Remove unencrypted backup
    if [ -f "$BACKUP_DIR/$BACKUP_FILE.gpg" ]; then
        rm -f "$BACKUP_DIR/$BACKUP_FILE"
        BACKUP_FILE="$BACKUP_FILE.gpg"
        log_success "Backup encrypted successfully"
    else
        log_error "Backup encryption failed"
        exit 1
    fi
}

# Upload to S3 (optional)
upload_to_s3() {
    if [ -z "${AWS_ACCESS_KEY_ID:-}" ]; then
        log_info "AWS credentials not set - skipping S3 upload"
        log_info "To enable S3 upload, set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY"
        return 0
    fi

    log_info "Uploading backup to S3: s3://$S3_BUCKET/$S3_PREFIX/"

    # Check if AWS CLI is available
    if ! command -v aws &> /dev/null; then
        log_warning "AWS CLI not found - skipping S3 upload"
        return 0
    fi

    # Upload to S3 with encryption at rest
    aws s3 cp "$BACKUP_DIR/$BACKUP_FILE" \
        "s3://$S3_BUCKET/$S3_PREFIX/$BACKUP_FILE" \
        --server-side-encryption AES256 \
        --storage-class STANDARD_IA

    log_success "Backup uploaded to S3"

    # Create lifecycle policy for automatic cleanup (if not exists)
    if ! aws s3api get-bucket-lifecycle-configuration --bucket "$S3_BUCKET" &> /dev/null; then
        log_info "Creating S3 lifecycle policy for automatic cleanup..."

        cat > /tmp/lifecycle-policy.json << EOF
{
  "Rules": [
    {
      "Id": "DeleteOldBackups",
      "Status": "Enabled",
      "Prefix": "$S3_PREFIX/",
      "Expiration": {
        "Days": $RETENTION_DAYS
      }
    }
  ]
}
EOF

        aws s3api put-bucket-lifecycle-configuration \
            --bucket "$S3_BUCKET" \
            --lifecycle-configuration file:///tmp/lifecycle-policy.json

        rm -f /tmp/lifecycle-policy.json
        log_success "S3 lifecycle policy created (${RETENTION_DAYS}-day retention)"
    fi
}

# Clean old backups
clean_old_backups() {
    log_info "Cleaning backups older than $RETENTION_DAYS days..."

    # Find and delete old backups
    local deleted_count=0
    find "$BACKUP_DIR" -name "septica_backup_*.sql.gz*" -type f -mtime +$RETENTION_DAYS | while read -r old_backup; do
        log_info "Deleting old backup: $(basename "$old_backup")"
        rm -f "$old_backup"
        deleted_count=$((deleted_count + 1))
    done

    if [ $deleted_count -gt 0 ]; then
        log_success "Deleted $deleted_count old backup(s)"
    else
        log_info "No old backups to delete"
    fi
}

# Verify backup integrity
verify_backup_integrity() {
    log_info "Verifying backup integrity..."

    # Test gzip integrity
    if echo "$BACKUP_FILE" | grep -q ".gz$"; then
        if gzip -t "$BACKUP_DIR/$BACKUP_FILE" 2>/dev/null; then
            log_success "Backup file compression is valid"
        else
            log_error "Backup file is corrupted"
            exit 1
        fi
    fi

    # Test SQL content (basic check)
    if echo "$BACKUP_FILE" | grep -q ".gpg$"; then
        log_info "Backup is encrypted - skipping SQL validation"
    else
        if zcat "$BACKUP_DIR/$BACKUP_FILE" | head -100 | grep -q "PostgreSQL database dump"; then
            log_success "Backup SQL content is valid"
        else
            log_error "Backup does not contain valid SQL"
            exit 1
        fi
    fi
}

# Generate backup report
generate_backup_report() {
    log_info "Generating backup report..."

    local backup_size=$(du -h "$BACKUP_DIR/$BACKUP_FILE" | cut -f1)
    local backup_count=$(find "$BACKUP_DIR" -name "septica_backup_*.sql.gz*" -type f | wc -l)

    cat << EOF

${ROMANIAN_FLAG} Romanian Septica Database Backup Report ${BACKUP_ICON}
===========================================================
Environment: $ENVIRONMENT
Timestamp: $(date)

Backup Details:
- Filename: $BACKUP_FILE
- Size: $backup_size
- Location: $BACKUP_DIR
- Encrypted: $([ "$ENCRYPT_BACKUP" = "true" ] && echo "Yes (GPG)" || echo "No")

Storage:
- Local backups: $backup_count files
- Retention policy: $RETENTION_DAYS days
- S3 upload: $([ -n "${AWS_ACCESS_KEY_ID:-}" ] && echo "Enabled" || echo "Disabled")

Database:
- Name: $DB_NAME
- User: $DB_USER
- Environment: $ENVIRONMENT

Status: ✅ SUCCESS

Next scheduled backup: $(date -d "+1 day" 2>/dev/null || date -v+1d)
===========================================================
EOF
}

# Main backup flow
main() {
    echo ""
    echo -e "${BLUE}${ROMANIAN_FLAG} Romanian Septica Database Backup ${BACKUP_ICON}${NC}"
    echo -e "${BLUE}Environment: ${YELLOW}$ENVIRONMENT${NC}"
    echo -e "${BLUE}Backup Directory: ${YELLOW}$BACKUP_DIR${NC}"
    echo ""

    # Create backup directory
    create_backup_directory

    # Check database connection
    check_database_connection

    # Create backup
    create_backup

    # Verify backup integrity
    verify_backup_integrity

    # Encrypt backup (optional)
    encrypt_backup

    # Upload to S3 (optional)
    upload_to_s3

    # Clean old backups
    clean_old_backups

    # Generate report
    generate_backup_report

    echo ""
    log_success "${ROMANIAN_FLAG} Database backup completed successfully! ${BACKUP_ICON}"
    echo ""
}

# Handle script interruption
trap 'log_error "Backup interrupted"; exit 1' INT TERM

# Execute main function
main "$@"
