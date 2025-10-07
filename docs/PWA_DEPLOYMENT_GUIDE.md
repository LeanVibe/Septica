# Romanian Septica PWA - Production Deployment Guide

**Version**: 1.0.0
**Last Updated**: October 6, 2025
**Target Platforms**: Cloud Infrastructure (AWS, GCP, DigitalOcean, Heroku)

---

## Table of Contents

1. [Production Infrastructure Requirements](#1-production-infrastructure-requirements)
2. [Environment Configuration](#2-environment-configuration)
3. [Docker Production Build](#3-docker-production-build)
4. [Kubernetes Deployment](#4-kubernetes-deployment)
5. [Database Migration Strategy](#5-database-migration-strategy)
6. [HTTPS/SSL Setup](#6-httpsssl-setup)
7. [CDN Configuration](#7-cdn-configuration)
8. [Monitoring & Logging](#8-monitoring--logging)
9. [Performance Optimization](#9-performance-optimization)
10. [Backup Strategy](#10-backup-strategy)
11. [Deployment Checklist](#11-deployment-checklist)
12. [Rollback Plan](#12-rollback-plan)
13. [Security Hardening](#13-security-hardening)
14. [Cost Estimates](#14-cost-estimates)
15. [Troubleshooting](#15-troubleshooting)

---

## 1. Production Infrastructure Requirements

### 1.1 Minimum Specifications

#### Backend (Go Server)
- **CPU**: 2 cores (x86_64 or ARM64)
- **RAM**: 4GB (2GB minimum)
- **Storage**: 20GB SSD
- **Network**: 100 Mbps minimum bandwidth
- **OS**: Ubuntu 22.04 LTS, Alpine Linux, or container runtime

#### Database (PostgreSQL)
- **Version**: PostgreSQL 14+ or 15+
- **CPU**: 2 cores
- **RAM**: 2GB (4GB recommended)
- **Storage**: 50GB SSD with automatic scaling
- **Connections**: Support 100+ concurrent connections
- **Backup**: Automated daily backups with 30-day retention

#### Frontend (Static Assets + Nginx)
- **CPU**: 1 core
- **RAM**: 512MB
- **Storage**: 5GB SSD
- **CDN**: CloudFlare, AWS CloudFront, or Google Cloud CDN
- **SSL**: Let's Encrypt or cloud provider managed certificates

#### Redis (Optional - Caching Layer)
- **Version**: Redis 7+
- **RAM**: 256MB - 1GB
- **Persistence**: AOF (Append Only File) enabled
- **Use Cases**: Session storage, matchmaking queue, rate limiting

### 1.2 Recommended Cloud Providers

#### Option 1: AWS (Amazon Web Services)
**Services:**
- **Compute**: ECS Fargate or EC2 (t3.medium)
- **Database**: RDS PostgreSQL (db.t3.medium)
- **Cache**: ElastiCache Redis (cache.t3.micro)
- **Load Balancer**: Application Load Balancer (ALB)
- **CDN**: CloudFront
- **SSL**: ACM (AWS Certificate Manager)
- **Monitoring**: CloudWatch
- **Estimated Monthly Cost**: $150-$300 (low traffic), $500-$1000 (medium traffic)

**Pros:**
- Enterprise-grade reliability (99.99% SLA)
- Comprehensive managed services
- Auto-scaling capabilities
- Global infrastructure

**Cons:**
- Complex pricing structure
- Steeper learning curve
- Higher costs at scale

#### Option 2: Google Cloud Platform (GCP)
**Services:**
- **Compute**: GKE (Google Kubernetes Engine) or Cloud Run
- **Database**: Cloud SQL PostgreSQL (db-n1-standard-1)
- **Cache**: Memorystore Redis
- **Load Balancer**: Cloud Load Balancing
- **CDN**: Cloud CDN
- **SSL**: Managed SSL Certificates
- **Monitoring**: Cloud Monitoring (Stackdriver)
- **Estimated Monthly Cost**: $120-$250 (low traffic), $400-$800 (medium traffic)

**Pros:**
- Excellent Kubernetes integration
- Competitive pricing for sustained use
- Superior networking performance
- Strong AI/ML capabilities (future features)

**Cons:**
- Smaller ecosystem than AWS
- Fewer availability zones in some regions

#### Option 3: DigitalOcean (Recommended for Startups)
**Services:**
- **Compute**: App Platform or Droplets (4GB RAM, 2 vCPUs)
- **Database**: Managed PostgreSQL (4GB RAM)
- **Cache**: Redis cluster (1GB)
- **Load Balancer**: DO Load Balancer
- **CDN**: DO Spaces + CDN
- **SSL**: Let's Encrypt (automated)
- **Monitoring**: Built-in monitoring
- **Estimated Monthly Cost**: $60-$120 (low traffic), $200-$400 (medium traffic)

**Pros:**
- Simple, predictable pricing
- Excellent developer experience
- Fast deployment process
- 99.99% uptime SLA

**Cons:**
- Limited global infrastructure
- Fewer advanced features
- Less enterprise support

#### Option 4: Heroku (Fastest Deployment)
**Services:**
- **Compute**: 2x Standard-2X dynos (Go backend)
- **Database**: Heroku Postgres Standard-0
- **Cache**: Heroku Redis Premium-0
- **CDN**: Heroku CDN + CloudFlare
- **SSL**: Automated SSL certificates
- **Monitoring**: Heroku Metrics + Papertrail
- **Estimated Monthly Cost**: $100-$200 (low traffic), $300-$600 (medium traffic)

**Pros:**
- Zero infrastructure management
- Git-based deployment workflow
- Automatic scaling
- Built-in CI/CD

**Cons:**
- Higher cost per resource
- Limited control over infrastructure
- Dyno restart every 24 hours (Standard tier)

### 1.3 Traffic Estimates

| User Tier | Concurrent Users | Monthly Active Users | Database Size | Bandwidth | Recommended Plan |
|-----------|-----------------|---------------------|---------------|-----------|------------------|
| **Small** | 10-50 | 100-500 | 5GB | 100GB/month | DigitalOcean Starter |
| **Medium** | 50-500 | 500-5,000 | 20GB | 500GB/month | DigitalOcean Pro / Heroku Standard |
| **Large** | 500-2,000 | 5,000-50,000 | 100GB | 2TB/month | AWS/GCP Production |
| **Enterprise** | 2,000+ | 50,000+ | 500GB+ | 10TB+/month | AWS/GCP Enterprise |

---

## 2. Environment Configuration

### 2.1 Production Environment Variables

Create `.env.production` in project root:

```bash
# ==========================================
# SERVER CONFIGURATION
# ==========================================
PORT=8080
ENVIRONMENT=production
GIN_MODE=release

# ==========================================
# DATABASE CONFIGURATION
# ==========================================
DATABASE_URL=postgres://septica_user:CHANGE_THIS_PASSWORD@db-host:5432/septica_production?sslmode=require
DATABASE_MAX_OPEN_CONNS=25
DATABASE_MAX_IDLE_CONNS=10
DATABASE_CONN_MAX_LIFETIME=5m

# ==========================================
# REDIS CONFIGURATION (Optional)
# ==========================================
REDIS_URL=redis://redis-host:6379/0
REDIS_PASSWORD=CHANGE_THIS_PASSWORD
REDIS_MAX_RETRIES=3
REDIS_POOL_SIZE=10

# ==========================================
# SECURITY & AUTHENTICATION
# ==========================================
JWT_SECRET=CHANGE_THIS_RANDOM_64_CHAR_STRING
JWT_EXPIRATION=24h
SESSION_SECRET=CHANGE_THIS_RANDOM_64_CHAR_STRING
COOKIE_SECURE=true
COOKIE_HTTP_ONLY=true
COOKIE_SAME_SITE=strict

# ==========================================
# CORS CONFIGURATION
# ==========================================
FRONTEND_URL=https://septica.example.com
CORS_ORIGINS=https://septica.example.com,https://www.septica.example.com
CORS_ALLOWED_METHODS=GET,POST,PUT,DELETE,OPTIONS
CORS_ALLOWED_HEADERS=Content-Type,Authorization,X-Requested-With

# ==========================================
# WEBSOCKET CONFIGURATION
# ==========================================
WS_READ_BUFFER_SIZE=1024
WS_WRITE_BUFFER_SIZE=1024
WS_MESSAGE_LIMIT=65536
WS_MAX_CONNECTIONS=10000
WS_TIMEOUT=30s
WS_PING_INTERVAL=30s
WS_PONG_TIMEOUT=60s

# ==========================================
# GAME CONFIGURATION
# ==========================================
MAX_CONCURRENT_GAMES=10000
GAME_TIMEOUT=30m
MOVE_TIMEOUT=30s
MATCHMAKING_TIMEOUT=5m
TOURNAMENT_ENABLED=true

# ==========================================
# RATE LIMITING
# ==========================================
RATE_LIMIT_REQUESTS=120
RATE_LIMIT_WINDOW=1m
RATE_LIMIT_BURST=10

# ==========================================
# LOGGING & MONITORING
# ==========================================
LOG_LEVEL=info
LOG_FORMAT=json
SENTRY_DSN=https://your-sentry-dsn@sentry.io/project-id
SENTRY_ENVIRONMENT=production
SENTRY_TRACES_SAMPLE_RATE=0.1

# ==========================================
# PERFORMANCE TUNING
# ==========================================
GOMAXPROCS=0  # Use all available CPUs
GOMEMLIMIT=3GiB  # 75% of available RAM (4GB system)

# ==========================================
# FEATURE FLAGS
# ==========================================
ENABLE_ANALYTICS=true
ENABLE_TOURNAMENTS=true
ENABLE_AI_OPPONENTS=true
ENABLE_CHAT=true
```

### 2.2 Generating Secure Secrets

```bash
# Generate JWT_SECRET (64 random bytes, base64 encoded)
openssl rand -base64 64 | tr -d '\n' && echo

# Generate SESSION_SECRET
openssl rand -base64 64 | tr -d '\n' && echo

# Generate PostgreSQL password (32 alphanumeric characters)
openssl rand -base64 32 | tr -d '+=/\n' | head -c 32 && echo

# Generate Redis password
openssl rand -base64 32 | tr -d '+=/\n' | head -c 32 && echo
```

### 2.3 Frontend Environment Configuration

Create `frontend/.env.production`:

```bash
# API Configuration
VITE_API_URL=https://api.septica.example.com
VITE_WS_URL=wss://api.septica.example.com/ws

# CDN Configuration
VITE_CDN_URL=https://cdn.septica.example.com
VITE_ASSETS_URL=https://cdn.septica.example.com/assets

# Feature Flags
VITE_ENABLE_ANALYTICS=true
VITE_ENABLE_OFFLINE_MODE=true
VITE_ENABLE_PERFORMANCE_MONITORING=true

# Service Worker
VITE_SW_VERSION=1.0.0
VITE_CACHE_VERSION=v1.0.0

# Analytics (Optional)
VITE_GA_TRACKING_ID=UA-XXXXXXXXX-X
VITE_PLAUSIBLE_DOMAIN=septica.example.com
```

---

## 3. Docker Production Build

### 3.1 Backend Dockerfile (Multi-Stage Build)

Create `backend/Dockerfile.production`:

```dockerfile
# ==========================================
# Stage 1: Builder
# ==========================================
FROM golang:1.21-alpine AS builder

# Install build dependencies
RUN apk add --no-cache git ca-certificates tzdata

# Set working directory
WORKDIR /build

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build with optimizations
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags="-w -s -X main.Version=$(git describe --tags --always --dirty) -X main.BuildTime=$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    -a -installsuffix cgo \
    -o septica-server \
    ./cmd/server

# ==========================================
# Stage 2: Production Image
# ==========================================
FROM alpine:3.19

# Install runtime dependencies
RUN apk --no-cache add ca-certificates tzdata curl

# Create non-root user
RUN addgroup -g 1000 septica && \
    adduser -D -u 1000 -G septica septica

# Set working directory
WORKDIR /app

# Copy binary from builder
COPY --from=builder /build/septica-server .
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo

# Copy static assets (if any)
# COPY --from=builder /build/assets ./assets

# Set ownership
RUN chown -R septica:septica /app

# Switch to non-root user
USER septica

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

# Run the server
ENTRYPOINT ["/app/septica-server"]
```

### 3.2 Frontend Dockerfile (Nginx Production)

Create `frontend/Dockerfile.production`:

```dockerfile
# ==========================================
# Stage 1: Build Service Worker & Assets
# ==========================================
FROM node:20-alpine AS builder

WORKDIR /build

# Copy package files (if using build tools)
# COPY package*.json ./
# RUN npm ci --production

# Copy frontend assets
COPY . .

# Optimize JavaScript (minification)
# RUN npm run build  # If using build tools

# ==========================================
# Stage 2: Production Nginx Server
# ==========================================
FROM nginx:1.25-alpine

# Install dependencies for SSL and security
RUN apk add --no-cache openssl

# Remove default nginx config
RUN rm /etc/nginx/conf.d/default.conf

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf
COPY conf.d/septica.conf /etc/nginx/conf.d/

# Copy frontend assets
COPY --from=builder /build /usr/share/nginx/html

# Create cache directory
RUN mkdir -p /var/cache/nginx/septica && \
    chown -R nginx:nginx /var/cache/nginx/septica

# Security: Remove unnecessary files
RUN rm -f /usr/share/nginx/html/*.md /usr/share/nginx/html/.git*

# Expose ports
EXPOSE 80 443

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost/health || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
```

### 3.3 Nginx Configuration for PWA

Create `frontend/nginx.conf`:

```nginx
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 2048;
    use epoll;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Logging format
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    # Performance optimizations
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 10M;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript
               application/json application/javascript application/xml+rss
               application/rss+xml application/atom+xml image/svg+xml
               text/x-component text/x-cross-domain-policy;

    # Brotli compression (if available)
    # brotli on;
    # brotli_comp_level 6;
    # brotli_types text/plain text/css application/json application/javascript;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # Include server configurations
    include /etc/nginx/conf.d/*.conf;
}
```

Create `frontend/conf.d/septica.conf`:

```nginx
# Upstream backend server
upstream backend_servers {
    least_conn;
    server backend:8080 max_fails=3 fail_timeout=30s;
    keepalive 32;
}

# HTTPS redirect (if SSL enabled)
server {
    listen 80;
    server_name septica.example.com www.septica.example.com;

    # ACME challenge for Let's Encrypt
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    # Redirect all HTTP to HTTPS
    location / {
        return 301 https://$server_name$request_uri;
    }
}

# Main HTTPS server
server {
    listen 443 ssl http2;
    server_name septica.example.com www.septica.example.com;

    # SSL configuration
    ssl_certificate /etc/nginx/ssl/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384';
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # HSTS (optional, enable after testing)
    # add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;

    # Root directory for static files
    root /usr/share/nginx/html;
    index index.html;

    # Service Worker - NEVER cache
    location = /service-worker.js {
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
        add_header Service-Worker-Allowed "/";
    }

    # Manifest - short cache
    location = /manifest.json {
        add_header Cache-Control "public, max-age=3600";
    }

    # Static assets - long cache
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot|otf)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }

    # API proxy to backend
    location /api/ {
        proxy_pass http://backend_servers;
        proxy_http_version 1.1;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Timeouts
        proxy_connect_timeout 30s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;

        # Buffering
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;

        # CORS headers
        add_header Access-Control-Allow-Origin "$http_origin" always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Content-Type, Authorization" always;
        add_header Access-Control-Allow-Credentials "true" always;

        if ($request_method = 'OPTIONS') {
            return 204;
        }
    }

    # WebSocket proxy
    location /ws/ {
        proxy_pass http://backend_servers;
        proxy_http_version 1.1;

        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket timeouts
        proxy_connect_timeout 7d;
        proxy_send_timeout 7d;
        proxy_read_timeout 7d;

        # No buffering for WebSocket
        proxy_buffering off;
    }

    # SPA routing - serve index.html for all routes
    location / {
        try_files $uri $uri/ /index.html;
        add_header Cache-Control "no-cache";
    }

    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }

    # Deny access to hidden files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
}
```

### 3.4 Docker Compose Production

Create `docker-compose.production.yml`:

```yaml
version: '3.9'

services:
  # PostgreSQL Database
  postgres:
    image: postgres:15-alpine
    container_name: septica-postgres-prod
    environment:
      POSTGRES_DB: septica_production
      POSTGRES_USER: ${DB_USER:-septica}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      PGDATA: /var/lib/postgresql/data/pgdata
    volumes:
      - postgres_prod_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER:-septica} -d septica_production"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s
    restart: unless-stopped
    networks:
      - septica-network
    deploy:
      resources:
        limits:
          memory: 2G
          cpus: '2'
        reservations:
          memory: 1G
          cpus: '1'

  # Redis Cache
  redis:
    image: redis:7-alpine
    container_name: septica-redis-prod
    command: redis-server --requirepass ${REDIS_PASSWORD} --appendonly yes --maxmemory 512mb --maxmemory-policy allkeys-lru
    volumes:
      - redis_prod_data:/data
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "--raw", "incr", "ping"]
      interval: 10s
      timeout: 5s
      retries: 3
    restart: unless-stopped
    networks:
      - septica-network
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.5'

  # Go Backend
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile.production
    container_name: septica-backend-prod
    environment:
      - DATABASE_URL=postgres://${DB_USER:-septica}:${DB_PASSWORD}@postgres:5432/septica_production?sslmode=disable
      - REDIS_URL=redis://:${REDIS_PASSWORD}@redis:6379/0
      - PORT=8080
      - ENVIRONMENT=production
      - GIN_MODE=release
      - JWT_SECRET=${JWT_SECRET}
      - SESSION_SECRET=${SESSION_SECRET}
      - LOG_LEVEL=info
      - CORS_ORIGINS=${FRONTEND_URL}
    ports:
      - "8080:8080"
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    restart: unless-stopped
    networks:
      - septica-network
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: '2'
        reservations:
          memory: 512M
          cpus: '1'

  # Frontend Nginx
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile.production
    container_name: septica-frontend-prod
    volumes:
      - ./ssl:/etc/nginx/ssl:ro
    ports:
      - "80:80"
      - "443:443"
    depends_on:
      - backend
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost/health"]
      interval: 30s
      timeout: 5s
      retries: 3
    restart: unless-stopped
    networks:
      - septica-network
    deploy:
      resources:
        limits:
          memory: 256M
          cpus: '0.5'
        reservations:
          memory: 128M
          cpus: '0.25'

volumes:
  postgres_prod_data:
    driver: local
  redis_prod_data:
    driver: local

networks:
  septica-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.21.0.0/16
```

### 3.5 Build and Deploy Commands

```bash
# Build production images
docker-compose -f docker-compose.production.yml build

# Start production stack
docker-compose -f docker-compose.production.yml up -d

# View logs
docker-compose -f docker-compose.production.yml logs -f

# Stop services
docker-compose -f docker-compose.production.yml down

# Restart specific service
docker-compose -f docker-compose.production.yml restart backend

# Scale backend (if using load balancer)
docker-compose -f docker-compose.production.yml up -d --scale backend=3
```

---

## 4. Kubernetes Deployment

### 4.1 Namespace Configuration

Create `k8s/00-namespace.yaml`:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: septica-production
  labels:
    app: septica
    environment: production
```

### 4.2 ConfigMap

Create `k8s/01-configmap.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: septica-config
  namespace: septica-production
data:
  # Server Configuration
  PORT: "8080"
  ENVIRONMENT: "production"
  GIN_MODE: "release"

  # Database Configuration (non-sensitive)
  DATABASE_HOST: "postgres-service"
  DATABASE_PORT: "5432"
  DATABASE_NAME: "septica_production"
  DATABASE_MAX_OPEN_CONNS: "25"
  DATABASE_MAX_IDLE_CONNS: "10"
  DATABASE_CONN_MAX_LIFETIME: "5m"

  # Redis Configuration (non-sensitive)
  REDIS_HOST: "redis-service"
  REDIS_PORT: "6379"
  REDIS_DB: "0"

  # WebSocket Configuration
  WS_READ_BUFFER_SIZE: "1024"
  WS_WRITE_BUFFER_SIZE: "1024"
  WS_MESSAGE_LIMIT: "65536"
  WS_MAX_CONNECTIONS: "10000"
  WS_TIMEOUT: "30s"

  # Game Configuration
  MAX_CONCURRENT_GAMES: "10000"
  GAME_TIMEOUT: "30m"
  MOVE_TIMEOUT: "30s"

  # Logging
  LOG_LEVEL: "info"
  LOG_FORMAT: "json"
```

### 4.3 Secrets

Create `k8s/02-secrets.yaml`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: septica-secrets
  namespace: septica-production
type: Opaque
stringData:
  # Database credentials
  DATABASE_USER: "septica"
  DATABASE_PASSWORD: "CHANGE_THIS_PASSWORD"

  # Redis password
  REDIS_PASSWORD: "CHANGE_THIS_PASSWORD"

  # JWT & Session secrets
  JWT_SECRET: "CHANGE_THIS_RANDOM_64_CHAR_STRING"
  SESSION_SECRET: "CHANGE_THIS_RANDOM_64_CHAR_STRING"

  # Monitoring (optional)
  SENTRY_DSN: "https://your-sentry-dsn@sentry.io/project-id"
```

**Note**: Encode secrets in base64 before production deployment:
```bash
echo -n 'your-secret-value' | base64
```

### 4.4 PostgreSQL Deployment

Create `k8s/03-postgres.yaml`:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
  namespace: septica-production
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 50Gi
  storageClassName: standard  # Change based on cloud provider

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
  namespace: septica-production
  labels:
    app: postgres
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:15-alpine
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_DB
          valueFrom:
            configMapKeyRef:
              name: septica-config
              key: DATABASE_NAME
        - name: POSTGRES_USER
          valueFrom:
            secretKeyRef:
              name: septica-secrets
              key: DATABASE_USER
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: septica-secrets
              key: DATABASE_PASSWORD
        - name: PGDATA
          value: /var/lib/postgresql/data/pgdata
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
        resources:
          requests:
            memory: "1Gi"
            cpu: "1000m"
          limits:
            memory: "2Gi"
            cpu: "2000m"
        livenessProbe:
          exec:
            command:
            - pg_isready
            - -U
            - septica
            - -d
            - septica_production
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
        readinessProbe:
          exec:
            command:
            - pg_isready
            - -U
            - septica
            - -d
            - septica_production
          initialDelaySeconds: 10
          periodSeconds: 5
          timeoutSeconds: 3
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-pvc

---
apiVersion: v1
kind: Service
metadata:
  name: postgres-service
  namespace: septica-production
spec:
  selector:
    app: postgres
  ports:
  - protocol: TCP
    port: 5432
    targetPort: 5432
  type: ClusterIP
```

### 4.5 Redis Deployment

Create `k8s/04-redis.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
  namespace: septica-production
  labels:
    app: redis
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
      - name: redis
        image: redis:7-alpine
        command:
        - redis-server
        - --requirepass
        - $(REDIS_PASSWORD)
        - --appendonly
        - "yes"
        - --maxmemory
        - "512mb"
        - --maxmemory-policy
        - allkeys-lru
        ports:
        - containerPort: 6379
        env:
        - name: REDIS_PASSWORD
          valueFrom:
            secretKeyRef:
              name: septica-secrets
              key: REDIS_PASSWORD
        volumeMounts:
        - name: redis-storage
          mountPath: /data
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          exec:
            command:
            - redis-cli
            - ping
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          exec:
            command:
            - redis-cli
            - ping
          initialDelaySeconds: 5
          periodSeconds: 5
      volumes:
      - name: redis-storage
        emptyDir: {}  # Use PVC for persistent storage if needed

---
apiVersion: v1
kind: Service
metadata:
  name: redis-service
  namespace: septica-production
spec:
  selector:
    app: redis
  ports:
  - protocol: TCP
    port: 6379
    targetPort: 6379
  type: ClusterIP
```

### 4.6 Backend Deployment

Create `k8s/05-backend.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: septica-backend
  namespace: septica-production
  labels:
    app: septica-backend
spec:
  replicas: 3  # Scale based on traffic
  selector:
    matchLabels:
      app: septica-backend
  template:
    metadata:
      labels:
        app: septica-backend
    spec:
      initContainers:
      # Run database migrations before starting
      - name: migrate
        image: your-registry.com/septica-backend:latest
        command: ["/app/septica-server", "migrate"]
        env:
        - name: DATABASE_URL
          value: "postgres://$(DATABASE_USER):$(DATABASE_PASSWORD)@$(DATABASE_HOST):$(DATABASE_PORT)/$(DATABASE_NAME)?sslmode=require"
        - name: DATABASE_USER
          valueFrom:
            secretKeyRef:
              name: septica-secrets
              key: DATABASE_USER
        - name: DATABASE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: septica-secrets
              key: DATABASE_PASSWORD
        - name: DATABASE_HOST
          valueFrom:
            configMapKeyRef:
              name: septica-config
              key: DATABASE_HOST
        - name: DATABASE_PORT
          valueFrom:
            configMapKeyRef:
              name: septica-config
              key: DATABASE_PORT
        - name: DATABASE_NAME
          valueFrom:
            configMapKeyRef:
              name: septica-config
              key: DATABASE_NAME
      containers:
      - name: backend
        image: your-registry.com/septica-backend:latest
        ports:
        - containerPort: 8080
        env:
        # Build DATABASE_URL from components
        - name: DATABASE_URL
          value: "postgres://$(DATABASE_USER):$(DATABASE_PASSWORD)@$(DATABASE_HOST):$(DATABASE_PORT)/$(DATABASE_NAME)?sslmode=require"
        - name: REDIS_URL
          value: "redis://:$(REDIS_PASSWORD)@$(REDIS_HOST):$(REDIS_PORT)/$(REDIS_DB)"
        # Reference ConfigMap values
        - name: PORT
          valueFrom:
            configMapKeyRef:
              name: septica-config
              key: PORT
        - name: ENVIRONMENT
          valueFrom:
            configMapKeyRef:
              name: septica-config
              key: ENVIRONMENT
        - name: GIN_MODE
          valueFrom:
            configMapKeyRef:
              name: septica-config
              key: GIN_MODE
        - name: LOG_LEVEL
          valueFrom:
            configMapKeyRef:
              name: septica-config
              key: LOG_LEVEL
        # Reference Secret values
        - name: DATABASE_USER
          valueFrom:
            secretKeyRef:
              name: septica-secrets
              key: DATABASE_USER
        - name: DATABASE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: septica-secrets
              key: DATABASE_PASSWORD
        - name: DATABASE_HOST
          valueFrom:
            configMapKeyRef:
              name: septica-config
              key: DATABASE_HOST
        - name: DATABASE_PORT
          valueFrom:
            configMapKeyRef:
              name: septica-config
              key: DATABASE_PORT
        - name: DATABASE_NAME
          valueFrom:
            configMapKeyRef:
              name: septica-config
              key: DATABASE_NAME
        - name: REDIS_PASSWORD
          valueFrom:
            secretKeyRef:
              name: septica-secrets
              key: REDIS_PASSWORD
        - name: REDIS_HOST
          valueFrom:
            configMapKeyRef:
              name: septica-config
              key: REDIS_HOST
        - name: REDIS_PORT
          valueFrom:
            configMapKeyRef:
              name: septica-config
              key: REDIS_PORT
        - name: REDIS_DB
          valueFrom:
            configMapKeyRef:
              name: septica-config
              key: REDIS_DB
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: septica-secrets
              key: JWT_SECRET
        - name: SESSION_SECRET
          valueFrom:
            secretKeyRef:
              name: septica-secrets
              key: SESSION_SECRET
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "1Gi"
            cpu: "1000m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 60
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 2

---
apiVersion: v1
kind: Service
metadata:
  name: septica-backend-service
  namespace: septica-production
spec:
  selector:
    app: septica-backend
  ports:
  - name: http
    protocol: TCP
    port: 8080
    targetPort: 8080
  type: ClusterIP
```

### 4.7 Frontend Deployment

Create `k8s/06-frontend.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: septica-frontend
  namespace: septica-production
  labels:
    app: septica-frontend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: septica-frontend
  template:
    metadata:
      labels:
        app: septica-frontend
    spec:
      containers:
      - name: frontend
        image: your-registry.com/septica-frontend:latest
        ports:
        - containerPort: 80
        - containerPort: 443
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "250m"
        livenessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5

---
apiVersion: v1
kind: Service
metadata:
  name: septica-frontend-service
  namespace: septica-production
spec:
  selector:
    app: septica-frontend
  ports:
  - name: http
    protocol: TCP
    port: 80
    targetPort: 80
  - name: https
    protocol: TCP
    port: 443
    targetPort: 443
  type: ClusterIP
```

### 4.8 Ingress Controller

Create `k8s/07-ingress.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: septica-ingress
  namespace: septica-production
  annotations:
    # SSL/TLS configuration
    cert-manager.io/cluster-issuer: "letsencrypt-prod"

    # Nginx ingress annotations
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"

    # WebSocket support
    nginx.ingress.kubernetes.io/websocket-services: "septica-backend-service"

    # Proxy settings
    nginx.ingress.kubernetes.io/proxy-body-size: "10m"
    nginx.ingress.kubernetes.io/proxy-connect-timeout: "30"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "600"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "600"

    # Security headers
    nginx.ingress.kubernetes.io/configuration-snippet: |
      add_header X-Frame-Options "SAMEORIGIN" always;
      add_header X-Content-Type-Options "nosniff" always;
      add_header X-XSS-Protection "1; mode=block" always;
      add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # Rate limiting (optional)
    nginx.ingress.kubernetes.io/limit-rps: "20"
    nginx.ingress.kubernetes.io/limit-connections: "10"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - septica.example.com
    - www.septica.example.com
    secretName: septica-tls-cert
  rules:
  # Main domain
  - host: septica.example.com
    http:
      paths:
      # API routes to backend
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: septica-backend-service
            port:
              number: 8080
      # WebSocket routes to backend
      - path: /ws
        pathType: Prefix
        backend:
          service:
            name: septica-backend-service
            port:
              number: 8080
      # All other routes to frontend
      - path: /
        pathType: Prefix
        backend:
          service:
            name: septica-frontend-service
            port:
              number: 80
  # WWW subdomain (redirect or separate handling)
  - host: www.septica.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: septica-frontend-service
            port:
              number: 80
```

### 4.9 HorizontalPodAutoscaler

Create `k8s/08-hpa.yaml`:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: septica-backend-hpa
  namespace: septica-production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: septica-backend
  minReplicas: 3
  maxReplicas: 10
  metrics:
  # Scale based on CPU
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  # Scale based on memory
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300  # 5 minutes
      policies:
      - type: Percent
        value: 50  # Scale down max 50% at a time
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 60  # 1 minute
      policies:
      - type: Percent
        value: 100  # Scale up max 100% at a time
        periodSeconds: 60
      - type: Pods
        value: 2  # Or add 2 pods at a time
        periodSeconds: 60
      selectPolicy: Max  # Use whichever policy scales faster

---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: septica-frontend-hpa
  namespace: septica-production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: septica-frontend
  minReplicas: 2
  maxReplicas: 5
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

### 4.10 Deployment Commands

```bash
# Apply all Kubernetes manifests
kubectl apply -f k8s/

# Check deployment status
kubectl get all -n septica-production

# View logs
kubectl logs -n septica-production -l app=septica-backend --tail=100 -f

# Scale manually
kubectl scale deployment septica-backend -n septica-production --replicas=5

# Rollout status
kubectl rollout status deployment/septica-backend -n septica-production

# Rollback deployment
kubectl rollout undo deployment/septica-backend -n septica-production

# Update image
kubectl set image deployment/septica-backend backend=your-registry.com/septica-backend:v2.0.0 -n septica-production

# Delete all resources
kubectl delete namespace septica-production
```

---

## 5. Database Migration Strategy

### 5.1 Migration Tool Setup

The backend uses GORM for migrations. Ensure migrations run **before** the server starts.

### 5.2 Pre-Deployment Migration

```bash
# Run migrations manually before deployment
docker exec -it septica-backend /app/septica-server migrate

# Or via kubectl (Kubernetes)
kubectl exec -it deployment/septica-backend -n septica-production -- /app/septica-server migrate
```

### 5.3 Automated Migration in Docker

✅ **PRODUCTION READY** - Database migrations run automatically on server startup.

Already configured in `backend/cmd/server/main.go`:
```go
// Run database migrations automatically (GORM v1.25.12)
if os.Getenv("SKIP_MIGRATIONS") != "true" {
    if err := database.Migrate(db); err != nil {
        logger.Fatal("Failed to run database migrations", "error", err)
    }
    logger.Info("Database migrations completed")
}
```

**Status**: Migrations are stable and automatic. The `SKIP_MIGRATIONS` check remains for emergency override only.
**Migration Time**: Typically <1 second for schema updates.
**GORM Version**: v1.25.12 (stable, production-tested)

### 5.4 Migration Rollback

```bash
# If migrations fail, rollback manually
docker exec -it septica-postgres psql -U septica -d septica_production

# Inside psql:
# Drop problematic tables or restore from backup
\dt  # List tables
DROP TABLE IF EXISTS schema_migrations;
```

### 5.5 Zero-Downtime Migrations

**Strategy:**
1. Deploy new version with backward-compatible schema changes
2. Run migrations
3. Deploy application code
4. Remove deprecated columns/tables in next release

**Example:**
- **Release 1**: Add new column (nullable)
- **Release 2**: Migrate data to new column
- **Release 3**: Make column non-nullable
- **Release 4**: Remove old column

---

## 6. HTTPS/SSL Setup

### 6.1 Let's Encrypt with Certbot (Docker)

Create `ssl/certbot-setup.sh`:

```bash
#!/bin/bash
# Let's Encrypt SSL certificate setup with Certbot

DOMAIN="septica.example.com"
EMAIL="admin@septica.example.com"

# Install certbot
docker run -it --rm \
  -v $(pwd)/ssl:/etc/letsencrypt \
  -v $(pwd)/frontend:/var/www/certbot \
  certbot/certbot certonly \
  --webroot \
  --webroot-path=/var/www/certbot \
  --email $EMAIL \
  --agree-tos \
  --no-eff-email \
  -d $DOMAIN \
  -d www.$DOMAIN

# Copy certificates to nginx directory
cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem ssl/
cp /etc/letsencrypt/live/$DOMAIN/privkey.pem ssl/

echo "SSL certificates installed successfully!"
```

### 6.2 Auto-Renewal with Cron

```bash
# Add to crontab (runs every 12 hours)
0 0,12 * * * docker run --rm -v $(pwd)/ssl:/etc/letsencrypt -v $(pwd)/frontend:/var/www/certbot certbot/certbot renew --quiet && docker exec septica-frontend-prod nginx -s reload
```

### 6.3 Cert-Manager (Kubernetes)

Install cert-manager:
```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
```

Create `k8s/09-cert-manager.yaml`:

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@septica.example.com
    privateKeySecretRef:
      name: letsencrypt-prod-private-key
    solvers:
    - http01:
        ingress:
          class: nginx
```

### 6.4 CloudFlare SSL (Recommended for CDN)

**Setup:**
1. Add domain to CloudFlare
2. Update nameservers
3. Enable "Full (Strict)" SSL mode
4. Enable "Always Use HTTPS"
5. Enable "Automatic HTTPS Rewrites"

**Benefits:**
- Free SSL certificates
- DDoS protection
- CDN caching
- WAF (Web Application Firewall)

---

## 7. CDN Configuration

### 7.1 CloudFlare CDN Setup

**Steps:**
1. Add domain to CloudFlare account
2. Update DNS records:
   ```
   A    septica.example.com      → <your-server-ip>  (Proxied)
   A    www.septica.example.com  → <your-server-ip>  (Proxied)
   CNAME api.septica.example.com → septica.example.com (Proxied)
   ```
3. Enable caching rules:
   - Cache Level: Standard
   - Browser Cache TTL: 4 hours
   - Always Online: Enabled

**Cache Rules:**
```
# Cache static assets aggressively
*.js, *.css, *.png, *.jpg, *.svg, *.woff2
Cache-Control: public, max-age=31536000, immutable

# Don't cache Service Worker
/service-worker.js
Cache-Control: no-cache, no-store, must-revalidate

# Don't cache API requests
/api/*, /ws/*
Cache-Control: no-cache
```

### 7.2 AWS CloudFront Setup

Create CloudFront distribution:
```bash
aws cloudfront create-distribution \
  --origin-domain-name septica.example.com \
  --default-root-object index.html \
  --viewer-protocol-policy redirect-to-https \
  --price-class PriceClass_100 \
  --enabled
```

**Cache Behaviors:**
- **Default**: `/` → Cache all static assets
- **API**: `/api/*` → No caching
- **WebSocket**: `/ws/*` → No caching, upgrade connection

### 7.3 Nginx Cache Configuration

Add to `frontend/conf.d/septica.conf`:

```nginx
# Cache configuration
proxy_cache_path /var/cache/nginx/septica
                 levels=1:2
                 keys_zone=septica_cache:10m
                 max_size=1g
                 inactive=7d
                 use_temp_path=off;

# In server block
location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {
    proxy_cache septica_cache;
    proxy_cache_valid 200 7d;
    proxy_cache_valid 404 1h;
    proxy_cache_use_stale error timeout updating http_500 http_502 http_503 http_504;
    proxy_cache_lock on;

    add_header X-Cache-Status $upstream_cache_status;
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

---

## 8. Monitoring & Logging

### 8.1 Health Check Endpoints

Backend health check at `/health`:
```go
router.GET("/health", func(c *gin.Context) {
    c.JSON(http.StatusOK, gin.H{
        "status":    "healthy",
        "timestamp": time.Now(),
        "version":   "1.0.0",
        "service":   "septica-backend",
    })
})
```

### 8.2 Prometheus Metrics

Add Prometheus exporter to Go backend:

```go
import (
    "github.com/prometheus/client_golang/prometheus"
    "github.com/prometheus/client_golang/prometheus/promhttp"
)

// Metrics
var (
    activeGames = prometheus.NewGauge(prometheus.GaugeOpts{
        Name: "septica_active_games",
        Help: "Number of active Septica games",
    })

    wsConnections = prometheus.NewGauge(prometheus.GaugeOpts{
        Name: "septica_websocket_connections",
        Help: "Number of active WebSocket connections",
    })

    httpRequestDuration = prometheus.NewHistogramVec(prometheus.HistogramOpts{
        Name: "septica_http_request_duration_seconds",
        Help: "HTTP request duration in seconds",
    }, []string{"method", "endpoint", "status"})
)

func init() {
    prometheus.MustRegister(activeGames, wsConnections, httpRequestDuration)
}

// Expose metrics endpoint
router.GET("/metrics", gin.WrapH(promhttp.Handler()))
```

### 8.3 Grafana Dashboard

Install Prometheus + Grafana:
```bash
# Using docker-compose
docker-compose -f monitoring-stack.yml up -d
```

Create `monitoring-stack.yml`:
```yaml
version: '3.9'

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    ports:
      - "9090:9090"
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=30d'
    restart: unless-stopped

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/dashboards:/etc/grafana/provisioning/dashboards
      - ./grafana/datasources:/etc/grafana/provisioning/datasources
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=changeme
      - GF_USERS_ALLOW_SIGN_UP=false
    depends_on:
      - prometheus
    restart: unless-stopped

volumes:
  prometheus_data:
  grafana_data:
```

Create `prometheus/prometheus.yml`:
```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'septica-backend'
    static_configs:
      - targets: ['backend:8080']
    metrics_path: '/metrics'

  - job_name: 'postgres'
    static_configs:
      - targets: ['postgres-exporter:9187']

  - job_name: 'redis'
    static_configs:
      - targets: ['redis-exporter:9121']
```

### 8.4 Logging with ELK Stack (Optional)

**Elasticsearch + Logstash + Kibana** for centralized logging.

Or use **Loki + Promtail** (lightweight alternative):

```bash
# Add to docker-compose
loki:
  image: grafana/loki:latest
  ports:
    - "3100:3100"
  volumes:
    - ./loki-config.yml:/etc/loki/local-config.yml
  command: -config.file=/etc/loki/local-config.yml

promtail:
  image: grafana/promtail:latest
  volumes:
    - /var/log:/var/log
    - ./promtail-config.yml:/etc/promtail/config.yml
  command: -config.file=/etc/promtail/config.yml
```

### 8.5 Error Tracking with Sentry

Add Sentry to Go backend:
```bash
go get github.com/getsentry/sentry-go
```

```go
import "github.com/getsentry/sentry-go"

func init() {
    err := sentry.Init(sentry.ClientOptions{
        Dsn: os.Getenv("SENTRY_DSN"),
        Environment: os.Getenv("ENVIRONMENT"),
        TracesSampleRate: 0.1,
    })
    if err != nil {
        log.Fatal("Sentry initialization failed:", err)
    }
}
```

---

## 9. Performance Optimization

### 9.1 Database Connection Pooling

Configure in `backend/pkg/config/config.go`:
```go
db.SetMaxOpenConns(25)        // Max open connections
db.SetMaxIdleConns(10)        // Max idle connections
db.SetConnMaxLifetime(5 * time.Minute)
```

### 9.2 Redis Caching Strategy

Cache frequently accessed data:
```go
// Cache game state
func (s *GameService) GetGame(gameID string) (*Game, error) {
    // Try cache first
    cacheKey := fmt.Sprintf("game:%s", gameID)
    if cached, err := s.redis.Get(cacheKey).Result(); err == nil {
        var game Game
        json.Unmarshal([]byte(cached), &game)
        return &game, nil
    }

    // Cache miss - fetch from database
    game, err := s.db.FindGame(gameID)
    if err != nil {
        return nil, err
    }

    // Store in cache (5 minute TTL)
    gameJSON, _ := json.Marshal(game)
    s.redis.Set(cacheKey, gameJSON, 5*time.Minute)

    return game, nil
}
```

### 9.3 WebSocket Optimization

```go
// Increase buffer sizes for high traffic
wsHub := websocket.NewHub(gameEngine, authenticEngine, db, logger)
wsHub.ReadBufferSize = 2048
wsHub.WriteBufferSize = 2048
```

### 9.4 Database Indexes

Ensure proper indexes in `backend/internal/database/migrations.go`:
```go
// Index on frequently queried columns
db.Exec("CREATE INDEX IF NOT EXISTS idx_games_status ON games(status)")
db.Exec("CREATE INDEX IF NOT EXISTS idx_games_created_at ON games(created_at)")
db.Exec("CREATE INDEX IF NOT EXISTS idx_matchmaking_rating ON matchmaking_queue(rating)")
db.Exec("CREATE INDEX IF NOT EXISTS idx_users_username ON users(username)")
```

### 9.5 Gzip/Brotli Compression

Already configured in Nginx (see Section 3.3).

---

## 10. Backup Strategy

### 10.1 Automated PostgreSQL Backups

Create `scripts/backup-postgres.sh`:
```bash
#!/bin/bash
# Automated PostgreSQL backup script

BACKUP_DIR="/backups/postgres"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/septica_backup_$DATE.sql.gz"
RETENTION_DAYS=30

# Create backup directory
mkdir -p $BACKUP_DIR

# Dump database
docker exec septica-postgres-prod pg_dump -U septica septica_production | gzip > $BACKUP_FILE

# Upload to S3 (optional)
aws s3 cp $BACKUP_FILE s3://septica-backups/postgres/

# Delete old backups
find $BACKUP_DIR -name "septica_backup_*.sql.gz" -mtime +$RETENTION_DAYS -delete

echo "Backup completed: $BACKUP_FILE"
```

### 10.2 Kubernetes CronJob for Backups

Create `k8s/10-backup-cronjob.yaml`:
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: postgres-backup
  namespace: septica-production
spec:
  schedule: "0 2 * * *"  # 2 AM daily
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: postgres:15-alpine
            env:
            - name: PGHOST
              value: postgres-service
            - name: PGDATABASE
              value: septica_production
            - name: PGUSER
              valueFrom:
                secretKeyRef:
                  name: septica-secrets
                  key: DATABASE_USER
            - name: PGPASSWORD
              valueFrom:
                secretKeyRef:
                  name: septica-secrets
                  key: DATABASE_PASSWORD
            command:
            - /bin/sh
            - -c
            - |
              BACKUP_FILE="/backups/septica_backup_$(date +%Y%m%d_%H%M%S).sql.gz"
              pg_dump | gzip > $BACKUP_FILE
              echo "Backup completed: $BACKUP_FILE"
              # Upload to cloud storage here
            volumeMounts:
            - name: backup-storage
              mountPath: /backups
          restartPolicy: OnFailure
          volumes:
          - name: backup-storage
            persistentVolumeClaim:
              claimName: backup-pvc
```

### 10.3 Backup Restoration

```bash
# Restore from backup
gunzip -c septica_backup_20250101_020000.sql.gz | docker exec -i septica-postgres-prod psql -U septica septica_production

# Or with kubectl
gunzip -c backup.sql.gz | kubectl exec -i postgres-0 -n septica-production -- psql -U septica septica_production
```

---

## 11. Deployment Checklist

### Pre-Deployment
- [ ] Environment variables configured (`.env.production`)
- [ ] Secrets generated (JWT, session, database passwords)
- [ ] SSL certificates obtained (Let's Encrypt or cloud provider)
- [ ] Database migrations tested in staging
- [ ] CDN configured for static assets
- [ ] DNS records updated and propagated
- [ ] Monitoring dashboards set up (Grafana/Prometheus)
- [ ] Error tracking configured (Sentry)
- [ ] Backup automation in place

### Deployment
- [ ] Build Docker images with production optimizations
- [ ] Push images to container registry
- [ ] Deploy database first (PostgreSQL, Redis)
- [ ] Run database migrations
- [ ] Deploy backend services (3+ replicas)
- [ ] Deploy frontend services (2+ replicas)
- [ ] Configure ingress/load balancer
- [ ] Enable HTTPS redirect
- [ ] Test health check endpoints

### Post-Deployment
- [ ] Verify Service Worker registration
- [ ] Test WebSocket connections
- [ ] Smoke test: Create game, play cards, complete game
- [ ] Load test: 100 concurrent users
- [ ] Monitor error rates and latency
- [ ] Verify backups running successfully
- [ ] Check SSL certificate expiry (90 days for Let's Encrypt)
- [ ] Update documentation with production URLs
- [ ] Notify users of new deployment

### Performance Validation
- [ ] Frontend loads in <2 seconds
- [ ] API response time <200ms (95th percentile)
- [ ] WebSocket latency <50ms
- [ ] Database queries <100ms
- [ ] Memory usage <80% of allocated
- [ ] CPU usage <70% under load
- [ ] Zero downtime during deployment

---

## 12. Rollback Plan

### 12.1 Docker Rollback

```bash
# Tag previous working version as "stable"
docker tag your-registry.com/septica-backend:v1.5.0 your-registry.com/septica-backend:stable

# Rollback to stable version
docker-compose -f docker-compose.production.yml down
docker-compose -f docker-compose.production.yml pull
docker-compose -f docker-compose.production.yml up -d
```

### 12.2 Kubernetes Rollback

```bash
# View rollout history
kubectl rollout history deployment/septica-backend -n septica-production

# Rollback to previous version
kubectl rollout undo deployment/septica-backend -n septica-production

# Rollback to specific revision
kubectl rollout undo deployment/septica-backend -n septica-production --to-revision=3

# Monitor rollback status
kubectl rollout status deployment/septica-backend -n septica-production
```

### 12.3 Blue-Green Deployment

**Strategy:**
1. Deploy new version (green) alongside current (blue)
2. Route 10% traffic to green
3. Monitor for errors/performance degradation
4. Gradually increase to 100% over 2 hours
5. Keep blue running for 24 hours
6. Shutdown blue if no issues

**Implementation with Kubernetes:**
```bash
# Deploy green version
kubectl apply -f k8s/backend-green.yaml

# Update service selector to route traffic
kubectl patch service septica-backend-service -n septica-production -p '{"spec":{"selector":{"version":"green"}}}'

# Rollback if needed
kubectl patch service septica-backend-service -n septica-production -p '{"spec":{"selector":{"version":"blue"}}}'
```

---

## 13. Security Hardening

### 13.1 Network Security

**Firewall Rules (iptables):**
```bash
# Allow SSH (22), HTTP (80), HTTPS (443)
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Block direct access to database and Redis
sudo ufw deny 5432/tcp
sudo ufw deny 6379/tcp

# Enable firewall
sudo ufw enable
```

### 13.2 Database Security

```sql
-- Create read-only user for reporting
CREATE USER septica_readonly WITH PASSWORD 'readonly_password';
GRANT CONNECT ON DATABASE septica_production TO septica_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO septica_readonly;

-- Revoke unnecessary privileges
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON DATABASE septica_production FROM PUBLIC;
```

### 13.3 Rate Limiting

Add to Nginx configuration:
```nginx
# Rate limiting zones
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=auth_limit:10m rate=5r/m;

# In server block
location /api/ {
    limit_req zone=api_limit burst=20 nodelay;
    limit_req_status 429;

    proxy_pass http://backend_servers;
}

location /api/auth/ {
    limit_req zone=auth_limit burst=5 nodelay;
    limit_req_status 429;

    proxy_pass http://backend_servers;
}
```

### 13.4 SQL Injection Prevention

Already handled by GORM parameterized queries:
```go
// SAFE: Parameterized query
db.Where("username = ?", userInput).First(&user)

// UNSAFE: String interpolation (DON'T DO THIS)
// db.Where("username = '" + userInput + "'").First(&user)
```

### 13.5 XSS Protection

**CSP Headers** in Nginx:
```nginx
add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' https://unpkg.com https://cdnjs.cloudflare.com; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; connect-src 'self' wss://*.septica.example.com; font-src 'self' data:; object-src 'none'; base-uri 'self'; form-action 'self'; frame-ancestors 'self';" always;
```

### 13.6 Dependency Security

```bash
# Scan Go dependencies for vulnerabilities
go install golang.org/x/vuln/cmd/govulncheck@latest
govulncheck ./...

# Update dependencies
go get -u ./...
go mod tidy
```

### 13.7 Regular Security Audits

- [ ] Update dependencies monthly
- [ ] Run security scans weekly
- [ ] Review access logs for suspicious activity
- [ ] Rotate secrets every 90 days
- [ ] Penetration testing quarterly
- [ ] Monitor CVE databases for critical vulnerabilities

---

## 14. Cost Estimates

### 14.1 DigitalOcean (Recommended for Startups)

| Component | Specification | Monthly Cost |
|-----------|--------------|--------------|
| **Backend Droplet** | 4GB RAM, 2 vCPUs, 80GB SSD | $24/month |
| **Database** | Managed PostgreSQL, 4GB RAM | $60/month |
| **Redis** | Managed Redis, 1GB RAM | $15/month |
| **Load Balancer** | High availability | $12/month |
| **Spaces CDN** | 250GB storage + 1TB bandwidth | $5/month |
| **Backups** | Daily automated backups | $5/month |
| **Monitoring** | Built-in monitoring | Free |
| **SSL Certificate** | Let's Encrypt | Free |
| **Total (Low Traffic)** | | **$121/month** |

**Medium Traffic (Scale up):**
- Backend: 3x Standard Droplets ($72/month)
- Database: 8GB plan ($120/month)
- Redis: 2GB plan ($30/month)
- **Total: ~$250/month**

### 14.2 AWS (Enterprise Grade)

| Component | Specification | Monthly Cost |
|-----------|--------------|--------------|
| **ECS Fargate** | 2 vCPU, 4GB RAM, 3 tasks | $90/month |
| **RDS PostgreSQL** | db.t3.medium, 50GB storage | $80/month |
| **ElastiCache Redis** | cache.t3.micro | $12/month |
| **Application Load Balancer** | | $18/month |
| **CloudFront CDN** | 1TB bandwidth | $85/month |
| **Route 53** | Hosted zone + queries | $1/month |
| **Certificate Manager** | SSL certificates | Free |
| **CloudWatch** | Logs + metrics | $10/month |
| **S3 Backups** | 100GB | $2/month |
| **Total (Low Traffic)** | | **$298/month** |

**Medium Traffic (Scale up):**
- ECS: 5 tasks ($150/month)
- RDS: db.t3.large ($160/month)
- ElastiCache: cache.t3.small ($35/month)
- **Total: ~$550/month**

### 14.3 Google Cloud Platform

| Component | Specification | Monthly Cost |
|-----------|--------------|--------------|
| **Cloud Run** | 2 vCPU, 4GB RAM, 3 instances | $70/month |
| **Cloud SQL PostgreSQL** | db-n1-standard-1, 50GB | $75/month |
| **Memorystore Redis** | 1GB | $25/month |
| **Cloud Load Balancing** | | $18/month |
| **Cloud CDN** | 1TB bandwidth | $65/month |
| **Cloud DNS** | | $0.40/month |
| **Managed SSL** | | Free |
| **Cloud Monitoring** | | $8/month |
| **Total (Low Traffic)** | | **$261/month** |

### 14.4 Heroku (Fastest Setup)

| Component | Specification | Monthly Cost |
|-----------|--------------|--------------|
| **Dynos** | 2x Standard-2X (Go backend) | $100/month |
| **Heroku Postgres** | Standard-0 (64GB) | $50/month |
| **Heroku Redis** | Premium-0 (100MB) | $15/month |
| **Heroku CDN** | CloudFlare integration | Free |
| **SSL Certificate** | Automated SSL | Free |
| **Monitoring** | Heroku Metrics + Papertrail | $10/month |
| **Total (Low Traffic)** | | **$175/month** |

---

## 15. Troubleshooting

### 15.1 Common Issues

#### Backend won't start
```bash
# Check logs
docker logs septica-backend-prod

# Common issues:
# - Database connection failed
# - Environment variables missing
# - Port already in use

# Verify database connectivity
docker exec septica-backend-prod curl -f http://localhost:8080/health
```

#### Database migration errors
```bash
# ✅ Migrations now automatic (GORM v1.25.12 stable)
# Only use SKIP_MIGRATIONS for emergency debugging:
SKIP_MIGRATIONS=true docker-compose up -d backend

# Verify migration status in logs
docker logs septica-backend-prod | grep -i migration

# Manual migration (emergency use only)
docker exec septica-backend-prod /app/septica-server migrate

# Reset database (DANGEROUS - production data loss)
docker exec septica-postgres-prod psql -U septica -c "DROP DATABASE septica_production;"
docker exec septica-postgres-prod psql -U septica -c "CREATE DATABASE septica_production;"
```

#### WebSocket connections failing
```bash
# Check CORS configuration
curl -H "Origin: https://septica.example.com" \
     -H "Access-Control-Request-Method: GET" \
     -H "Access-Control-Request-Headers: X-Requested-With" \
     -X OPTIONS \
     https://api.septica.example.com/ws/connect

# Verify WebSocket upgrade headers in Nginx
docker exec septica-frontend-prod cat /var/log/nginx/error.log | grep websocket
```

#### Service Worker not registering
```bash
# Clear browser cache
# Verify HTTPS is enabled (Service Workers require HTTPS)

# Check Service Worker cache status
# In browser console:
navigator.serviceWorker.getRegistrations().then(registrations => {
    console.log(registrations);
});
```

#### High memory usage
```bash
# Check container memory
docker stats

# Limit memory in docker-compose.yml
deploy:
  resources:
    limits:
      memory: 512M

# Profile Go application
go tool pprof http://localhost:8080/debug/pprof/heap
```

#### SSL certificate expired
```bash
# Renew Let's Encrypt certificate
docker run --rm -v $(pwd)/ssl:/etc/letsencrypt certbot/certbot renew

# Reload Nginx
docker exec septica-frontend-prod nginx -s reload

# Check expiry date
openssl x509 -in ssl/fullchain.pem -noout -enddate
```

### 15.2 Performance Debugging

```bash
# Check database slow queries
docker exec septica-postgres-prod psql -U septica -d septica_production -c "SELECT query, mean_exec_time, calls FROM pg_stat_statements ORDER BY mean_exec_time DESC LIMIT 10;"

# Monitor WebSocket connections
curl http://localhost:8080/api/v1/info

# Profile Go application
go tool pprof -http=:6060 http://localhost:8080/debug/pprof/profile?seconds=30
```

### 15.3 Emergency Procedures

#### Complete service outage
1. Check server status: `ping septica.example.com`
2. Check DNS: `nslookup septica.example.com`
3. Check SSL: `curl -I https://septica.example.com`
4. Check containers: `docker ps -a`
5. Restart services: `docker-compose restart`
6. Restore from backup if database corrupted

#### Database corruption
```bash
# Stop all connections
docker stop septica-backend-prod

# Restore from latest backup
gunzip -c /backups/postgres/septica_backup_latest.sql.gz | docker exec -i septica-postgres-prod psql -U septica septica_production

# Restart services
docker start septica-backend-prod
```

---

## Appendix A: Infrastructure Diagrams

### Production Architecture
```
                                 Internet
                                    |
                         [CloudFlare CDN / SSL]
                                    |
                      ┌─────────────┴─────────────┐
                      │                           │
               [Load Balancer]            [Load Balancer]
                      │                           │
         ┌────────────┴────────────┐       ┌─────┴──────┐
         │                         │       │            │
    [Frontend 1]            [Frontend 2]  [Backend 1] [Backend 2] [Backend 3]
         │                         │       │            │            │
         └─────────────┬───────────┘       └─────┬──────┴────────────┘
                       │                         │
                       │                    ┌────┴────┐
                       │                    │         │
                       │              [PostgreSQL] [Redis]
                       │                    │         │
                       │              [Backup Storage]
                       │
                  [Static Assets]
                  [Service Worker]
```

### Kubernetes Deployment
```
┌──────────────────────────────────────────────────────────┐
│                    Ingress Controller                     │
│                    (nginx / traefik)                      │
└──────────────────┬───────────────────────────────────────┘
                   │
        ┌──────────┴──────────┐
        │                     │
   [Frontend Svc]      [Backend Svc]
        │                     │
   ┌────┴─────┐       ┌──────┴──────┬──────┐
   │          │       │             │      │
[Frontend] [Frontend] [Backend]  [Backend] [Backend]
   Pod       Pod       Pod         Pod      Pod
                       │             │       │
                       └──────┬──────┴───────┘
                              │
                    ┌─────────┴─────────┐
                    │                   │
              [Postgres Svc]      [Redis Svc]
                    │                   │
              [Postgres Pod]      [Redis Pod]
                    │                   │
                   [PVC]               [PVC]
```

---

## Appendix B: Quick Reference Commands

```bash
# ==========================================
# Docker Commands
# ==========================================
# Build and start production stack
docker-compose -f docker-compose.production.yml up -d --build

# View logs
docker-compose -f docker-compose.production.yml logs -f backend

# Restart specific service
docker-compose -f docker-compose.production.yml restart backend

# Execute command in container
docker exec -it septica-backend-prod /bin/sh

# ==========================================
# Kubernetes Commands
# ==========================================
# Apply all manifests
kubectl apply -f k8s/

# Check deployment status
kubectl get all -n septica-production

# View logs
kubectl logs -n septica-production -l app=septica-backend --tail=100 -f

# Scale deployment
kubectl scale deployment septica-backend -n septica-production --replicas=5

# Rollback deployment
kubectl rollout undo deployment/septica-backend -n septica-production

# ==========================================
# Database Commands
# ==========================================
# Backup database
docker exec septica-postgres-prod pg_dump -U septica septica_production | gzip > backup.sql.gz

# Restore database
gunzip -c backup.sql.gz | docker exec -i septica-postgres-prod psql -U septica septica_production

# Connect to database
docker exec -it septica-postgres-prod psql -U septica septica_production

# ==========================================
# SSL Commands
# ==========================================
# Obtain Let's Encrypt certificate
docker run -it --rm -v $(pwd)/ssl:/etc/letsencrypt certbot/certbot certonly --webroot -w /var/www/certbot -d septica.example.com

# Renew certificate
docker run --rm -v $(pwd)/ssl:/etc/letsencrypt certbot/certbot renew

# Check certificate expiry
openssl x509 -in ssl/fullchain.pem -noout -enddate

# ==========================================
# Monitoring Commands
# ==========================================
# Check backend health
curl -f https://api.septica.example.com/health

# Get server info
curl https://api.septica.example.com/api/v1/info

# Check Prometheus metrics
curl http://localhost:9090/metrics
```

---

## Conclusion

This deployment guide provides a comprehensive roadmap for deploying the Romanian Septica PWA to production infrastructure. The guide covers:

✅ **Infrastructure Requirements** - Cloud provider comparisons and specifications
✅ **Environment Configuration** - Secure secret management and configuration
✅ **Docker Production Build** - Multi-stage builds with security best practices
✅ **Kubernetes Deployment** - Full K8s manifests with auto-scaling
✅ **Database Strategy** - Migration management and backup automation
✅ **HTTPS/SSL Setup** - Let's Encrypt and cert-manager configuration
✅ **CDN Configuration** - CloudFlare and cloud CDN integration
✅ **Monitoring & Logging** - Prometheus, Grafana, and Sentry setup
✅ **Performance Optimization** - Caching, connection pooling, indexes
✅ **Backup Strategy** - Automated daily backups with retention
✅ **Security Hardening** - Rate limiting, CSP headers, vulnerability scanning
✅ **Cost Estimates** - Detailed pricing for all major cloud providers
✅ **Troubleshooting** - Common issues and emergency procedures

**Next Steps:**
1. Choose cloud provider based on budget and requirements
2. Set up staging environment for testing
3. Configure monitoring and alerting
4. Perform load testing to validate scalability
5. Execute production deployment following checklist
6. Monitor metrics and optimize based on real-world usage

**Support:**
- Documentation: `/docs/`
- Issues: GitHub Issues
- Email: support@septica.example.com

---

**Document Version**: 1.0.0
**Last Updated**: October 6, 2025
**Maintained by**: Romanian Septica DevOps Team
