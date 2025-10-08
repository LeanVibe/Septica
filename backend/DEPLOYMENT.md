# Romanian Septica Backend - Docker Deployment Guide

## Overview

Production-ready Docker deployment infrastructure for the Romanian Septica multiplayer card game backend. This guide covers containerized deployment using Docker and docker-compose for local development, staging, and production environments.

## Performance Metrics

### Docker Image Optimization
- **Final Image Size**: 33.9MB (multi-stage build optimization)
- **Build Time**: ~8.4 seconds (excluding dependency download)
- **Layer Breakdown**:
  - Base Alpine Linux: 7.67MB
  - Runtime dependencies (ca-certificates, tzdata, curl, wget): 7.04MB
  - Go binary (statically compiled): 19.2MB
  - User/directory setup: ~5KB

### Runtime Performance
- **Memory Usage**:
  - Backend container: ~23MB at idle
  - PostgreSQL container: ~28MB at idle
  - Total system footprint: <60MB
- **CPU Usage**: <0.05% at idle
- **Startup Time**: ~10-15 seconds to healthy state
- **Health Check**: 30-second intervals, 40-second start period

### Database Metrics
- **Migrations**: Automatic on startup (13 tables created)
- **Connection Pool**: Configured via GORM defaults
- **Schema Tables**:
  - users, players, games, game_moves
  - matchmaking_queues, tournaments, tournament_participants
  - tournament_brackets, elo_rating_histories
  - player_statistics, player_season_stats
  - friendships, chat_messages

## Quick Start

### Prerequisites
- Docker 20.10+ (or OrbStack on macOS)
- docker-compose 2.0+ (or Docker Compose V2)
- Minimum 1GB RAM, 1GB disk space

### Local Development Setup

```bash
# 1. Navigate to backend directory
cd /Users/bogdan/work/Septica/backend

# 2. Copy environment template
cp .env.example .env

# 3. (Optional) Customize environment variables
nano .env

# 4. Start all services
docker-compose up -d

# 5. Verify deployment
curl http://localhost:8082/health

# 6. Check logs
docker-compose logs -f backend

# 7. Stop services
docker-compose down

# 8. Clean up (including volumes)
docker-compose down -v
```

## Architecture

### Multi-Stage Docker Build

The Dockerfile uses a two-stage build process:

**Stage 1: Builder (golang:1.23-alpine)**
- Installs build dependencies (git, ca-certificates, tzdata)
- Downloads Go module dependencies
- Compiles static binary with optimization flags:
  - `CGO_ENABLED=0` - Static binary, no C dependencies
  - `-ldflags='-w -s'` - Strip debug symbols
  - `GOARCH=amd64` - x86-64 architecture

**Stage 2: Runtime (alpine:3.18)**
- Minimal base image (7.67MB)
- Runtime dependencies only (curl, wget for health checks)
- Non-root user (appuser:appgroup, UID/GID 1001)
- Romanian timezone (Europe/Bucharest)
- Health check every 30s

### Service Configuration

**Backend Service:**
- Port: 8082 (HTTP + WebSocket)
- Health endpoint: `/health`
- Prometheus metrics: `/metrics`
- Auto-restart: unless-stopped
- Logging: JSON format, 10MB max, 3 files rotation

**PostgreSQL Service:**
- Port: 5435 (mapped from 5432)
- Database: septica
- User: septica_user
- Persistent volume: septica_postgres_data
- Auto-migrations on startup
- Health check: pg_isready

## Environment Variables

### Required Configuration

```bash
# Server
PORT=8082                    # HTTP server port
ENVIRONMENT=development      # development|staging|production

# Database
DATABASE_URL=postgresql://septica_user:password@postgres:5432/septica?sslmode=disable
DB_PASSWORD=your_secure_password

# Authentication
JWT_SECRET=minimum_32_character_secret_key
JWT_EXPIRATION=24h
```

### Optional Configuration

```bash
# WebSocket
WS_READ_BUFFER_SIZE=1024
WS_WRITE_BUFFER_SIZE=1024
WS_MESSAGE_LIMIT=65536

# Game Settings
MAX_CONCURRENT_GAMES=10000
GAME_TIMEOUT=30m
MOVE_TIMEOUT=30s

# Rate Limiting
RATE_LIMIT_REQUESTS=120
RATE_LIMIT_WINDOW=1m

# Logging
LOG_LEVEL=info              # debug|info|warn|error|fatal

# CORS
FRONTEND_URL=http://localhost:3000

# Migrations
SKIP_MIGRATIONS=false       # Set to true to skip auto-migrations
```

See `.env.example` for comprehensive documentation of all variables.

## Production Deployment

### Security Hardening

**Before deploying to production:**

1. **Environment Variables**
   - Generate secure JWT_SECRET: `openssl rand -base64 32`
   - Use strong database passwords (20+ characters)
   - Set `ENVIRONMENT=production`
   - Set `LOG_LEVEL=info` or `warn`

2. **Database Security**
   - Enable SSL/TLS: `sslmode=require` in DATABASE_URL
   - Use managed PostgreSQL service (AWS RDS, Google Cloud SQL, etc.)
   - Implement connection pooling
   - Regular automated backups

3. **Network Security**
   - Use HTTPS/WSS for external connections
   - Configure firewall rules
   - Set proper CORS origins in `FRONTEND_URL`
   - Use reverse proxy (nginx, Traefik) for SSL termination

4. **Container Security**
   - Non-root user (already implemented)
   - Read-only filesystem where possible
   - Resource limits (CPU, memory)
   - Security scanning (Trivy, Snyk)

5. **Monitoring**
   - Enable Prometheus metrics at `/metrics`
   - Set up alerting (health check failures, high error rates)
   - Log aggregation (ELK stack, Datadog, etc.)
   - Performance monitoring (APM tools)

### Production docker-compose Example

```yaml
version: '3.8'

services:
  backend:
    image: septica-backend:v1.0.0
    restart: always
    environment:
      PORT: 8082
      ENVIRONMENT: production
      DATABASE_URL: ${DATABASE_URL}  # Managed database
      JWT_SECRET: ${JWT_SECRET}
      LOG_LEVEL: info
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 256M
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8082/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - backend-network

  # Use managed database service instead of container in production
  # postgres:
  #   External AWS RDS, Google Cloud SQL, etc.

networks:
  backend-network:
    driver: bridge
```

### Kubernetes Deployment (Advanced)

For Kubernetes deployments, create manifests based on this structure:

```yaml
# Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: septica-backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: septica-backend
  template:
    metadata:
      labels:
        app: septica-backend
    spec:
      containers:
      - name: backend
        image: septica-backend:v1.0.0
        ports:
        - containerPort: 8082
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: septica-secrets
              key: database-url
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: septica-secrets
              key: jwt-secret
        livenessProbe:
          httpGet:
            path: /health
            port: 8082
          initialDelaySeconds: 10
          periodSeconds: 30
        readinessProbe:
          httpGet:
            path: /health
            port: 8082
          initialDelaySeconds: 5
          periodSeconds: 10
        resources:
          limits:
            cpu: "2"
            memory: "512Mi"
          requests:
            cpu: "500m"
            memory: "256Mi"

---
# Service
apiVersion: v1
kind: Service
metadata:
  name: septica-backend
spec:
  selector:
    app: septica-backend
  ports:
  - protocol: TCP
    port: 8082
    targetPort: 8082
  type: LoadBalancer
```

## Monitoring & Observability

### Health Endpoints

- **Basic Health**: `GET /health`
  - Returns overall system status
  - Used by Docker health checks
  - Response includes uptime, component status

- **Prometheus Metrics**: `GET /metrics`
  - Request rates, latencies, error rates
  - WebSocket connections
  - Game statistics
  - Database query performance

### Logging

Logs are output to stdout/stderr and captured by Docker:

```bash
# View logs
docker-compose logs -f backend

# Filter by level
docker-compose logs backend | grep ERROR

# Save logs to file
docker-compose logs backend > logs/backend.log
```

### Resource Monitoring

```bash
# Real-time stats
docker stats septica-backend septica-postgres

# Inspect container
docker inspect septica-backend

# Check health
docker inspect septica-backend --format '{{.State.Health.Status}}'
```

## Troubleshooting

### Common Issues

**1. Container fails to start**
```bash
# Check logs
docker-compose logs backend

# Verify environment variables
docker-compose config

# Test database connection
docker exec septica-postgres psql -U septica_user -d septica -c "SELECT 1"
```

**2. Health check fails**
```bash
# Test health endpoint manually
curl http://localhost:8082/health

# Check container health status
docker inspect septica-backend --format '{{.State.Health}}'

# View health check logs
docker inspect septica-backend --format '{{json .State.Health}}' | jq
```

**3. Database connection errors**
```bash
# Verify PostgreSQL is running
docker-compose ps postgres

# Check database logs
docker-compose logs postgres

# Test connection from backend
docker exec septica-backend sh -c 'nc -zv postgres 5432'
```

**4. Port conflicts**
```bash
# Find process using port
lsof -i:8082
lsof -i:5435

# Change ports in docker-compose.yml
# Backend: 8082 -> 8083
# PostgreSQL: 5435 -> 5436
```

**5. Disk space issues**
```bash
# Clean up unused Docker resources
docker system prune -a

# Remove unused volumes
docker volume prune

# Check disk usage
docker system df
```

### Performance Optimization

**1. Reduce startup time**
- Use pre-built images instead of building from source
- Optimize Dockerfile layer caching
- Use smaller base images (alpine)

**2. Memory optimization**
- Set appropriate resource limits
- Monitor memory usage with `docker stats`
- Adjust Go garbage collector settings if needed

**3. Network performance**
- Use Docker networks for service communication
- Avoid port mapping overhead in production
- Use host networking for maximum performance (security trade-off)

## Maintenance

### Database Backups

```bash
# Backup database
docker exec septica-postgres pg_dump -U septica_user septica > backup.sql

# Restore database
cat backup.sql | docker exec -i septica-postgres psql -U septica_user septica

# Automated backups (cron job example)
0 2 * * * docker exec septica-postgres pg_dump -U septica_user septica | gzip > /backups/septica-$(date +\%Y\%m\%d).sql.gz
```

### Updates & Rolling Deployments

```bash
# 1. Build new image
docker build -t septica-backend:v1.1.0 .

# 2. Tag as latest
docker tag septica-backend:v1.1.0 septica-backend:latest

# 3. Update services (zero-downtime)
docker-compose up -d --no-deps --build backend

# 4. Verify health
curl http://localhost:8082/health

# 5. Rollback if needed
docker tag septica-backend:v1.0.0 septica-backend:latest
docker-compose up -d --no-deps backend
```

### Cleanup & Maintenance

```bash
# Stop all services
docker-compose down

# Remove volumes (WARNING: deletes data)
docker-compose down -v

# Clean up old images
docker image prune -a

# View disk usage
docker system df
```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Build and Deploy

on:
  push:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3

    - name: Build Docker image
      run: docker build -t septica-backend:${{ github.sha }} .

    - name: Run tests
      run: docker run septica-backend:${{ github.sha }} go test ./...

    - name: Push to registry
      run: |
        docker tag septica-backend:${{ github.sha }} registry.example.com/septica-backend:latest
        docker push registry.example.com/septica-backend:latest

    - name: Deploy to production
      run: |
        # SSH to production server and update
        ssh deploy@prod-server "cd /app && docker-compose pull && docker-compose up -d"
```

## Support & Resources

- **Project Repository**: [GitHub](https://github.com/your-org/septica)
- **Backend Documentation**: `/Users/bogdan/work/Septica/backend/docs/`
- **Game Rules**: `/Users/bogdan/work/Septica/backend/docs/game-rules.md`
- **API Documentation**: `/Users/bogdan/work/Septica/backend/docs/backend-api.md`

## License

See LICENSE file in project root.

---

**Last Updated**: October 8, 2025
**Docker Image Version**: v1.0.0
**Deployment Status**: Production-Ready ✅
