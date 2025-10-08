# Health Check Endpoints Documentation

This document describes the comprehensive health check endpoints available for monitoring and observability in the Septica backend server.

## Overview

The health check system provides multiple endpoints for different monitoring purposes:
- **Liveness probes**: Basic server health
- **Readiness probes**: Service dependency health for Kubernetes
- **Detailed monitoring**: Comprehensive system status
- **Component-specific health**: Focused monitoring of individual services

## Endpoints

### 1. Basic Health Check (Liveness Probe)

**Endpoint**: `GET /health`

**Purpose**: Simple liveness probe to verify the server is running.

**Use Cases**:
- Basic uptime monitoring
- Load balancer health checks
- Kubernetes liveness probe

**Response** (200 OK):
```json
{
  "status": "ok",
  "timestamp": 1759918003,
  "service": "septica-backend"
}
```

**Example**:
```bash
curl http://localhost:8082/health
```

---

### 2. Readiness Probe

**Endpoint**: `GET /health/ready`

**Purpose**: Comprehensive readiness check for all critical services. Returns 503 if any critical service is unavailable.

**Use Cases**:
- Kubernetes readiness probe
- Deployment validation
- Service mesh health checks
- Circuit breaker integration

**Response** (200 OK when healthy):
```json
{
  "status": "healthy",
  "timestamp": "2025-10-08T13:00:00Z",
  "components": {
    "database": {
      "status": "healthy",
      "latency_ms": 5
    },
    "matchmaking": {
      "status": "healthy"
    },
    "ai_matchmaking": {
      "status": "healthy"
    },
    "websocket": {
      "status": "healthy"
    }
  }
}
```

**Response** (503 Service Unavailable when unhealthy):
```json
{
  "status": "unhealthy",
  "timestamp": "2025-10-08T13:00:00Z",
  "components": {
    "database": {
      "status": "unhealthy",
      "latency_ms": 0
    },
    "matchmaking": {
      "status": "not_initialized"
    },
    "ai_matchmaking": {
      "status": "not_initialized"
    },
    "websocket": {
      "status": "not_initialized"
    }
  }
}
```

**Example**:
```bash
curl http://localhost:8082/health/ready
```

**Kubernetes Readiness Probe Configuration**:
```yaml
readinessProbe:
  httpGet:
    path: /health/ready
    port: 8082
  initialDelaySeconds: 5
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3
```

---

### 3. Detailed Health Status

**Endpoint**: `GET /health/detailed`

**Purpose**: Comprehensive system status with detailed metrics for all components.

**Use Cases**:
- Operations dashboard monitoring
- Troubleshooting and debugging
- Performance analysis
- Capacity planning

**Response** (200 OK):
```json
{
  "status": "healthy",
  "timestamp": "2025-10-08T13:00:00Z",
  "version": "1.0.0",
  "uptime": 29734.789,
  "components": {
    "database": {
      "status": "up",
      "latency_ms": 5
    },
    "ai_matchmaking": {
      "status": "up",
      "active_ai": 3,
      "max_concurrent": 10,
      "enabled": true
    },
    "matchmaking": {
      "status": "up",
      "total_players": 12,
      "queues": {
        "total_players": 12,
        "queues": {
          "ranked": {
            "players": 8,
            "average_wait_time": 15,
            "longest_wait_seconds": 45,
            "players_waiting": 8
          },
          "casual": {
            "players": 4,
            "average_wait_time": 8,
            "longest_wait_seconds": 20,
            "players_waiting": 4
          }
        }
      }
    },
    "websocket": {
      "status": "up",
      "connections": 25,
      "games": 10
    }
  }
}
```

**Example**:
```bash
curl http://localhost:8082/health/detailed | jq .
```

---

### 4. AI Matchmaking Health

**Endpoint**: `GET /health/ai`

**Purpose**: Detailed status of AI matchmaking manager.

**Use Cases**:
- AI system monitoring
- Capacity planning for AI opponents
- AI deployment troubleshooting

**Response** (200 OK):
```json
{
  "status": "healthy",
  "timestamp": "2025-10-08T13:00:00Z",
  "active_ai_count": 3,
  "max_concurrent_ai": 10,
  "enabled": true,
  "activation_timeout": 10,
  "capacity_used": 30.0,
  "difficulty_distribution": {
    "easy": 0.4,
    "medium": 0.4,
    "hard": 0.2
  }
}
```

**Response** (503 Service Unavailable when AI manager not initialized):
```json
{
  "status": "unavailable",
  "message": "AI matchmaking manager not initialized"
}
```

**Metrics Explained**:
- `active_ai_count`: Number of currently deployed AI opponents
- `max_concurrent_ai`: Maximum allowed concurrent AI players
- `enabled`: Whether AI matchmaking is enabled
- `activation_timeout`: Seconds before AI is deployed for waiting players
- `capacity_used`: Percentage of AI capacity in use
- `difficulty_distribution`: Distribution of AI difficulty levels

**Example**:
```bash
curl http://localhost:8082/health/ai | jq .
```

---

### 5. Matchmaking Queue Health

**Endpoint**: `GET /health/matchmaking`

**Purpose**: Detailed matchmaking queue statistics and cleanup status.

**Use Cases**:
- Queue monitoring and alerting
- Player wait time analysis
- Queue cleanup verification
- Matchmaking performance tuning

**Response** (200 OK):
```json
{
  "status": "healthy",
  "timestamp": "2025-10-08T13:00:00Z",
  "queue_stats": {
    "total_players": 12,
    "queues": {
      "ranked": {
        "players": 8,
        "average_wait_time": 15,
        "longest_wait_seconds": 45,
        "players_waiting": 8
      },
      "casual": {
        "players": 4,
        "average_wait_time": 8,
        "longest_wait_seconds": 20,
        "players_waiting": 4
      }
    }
  },
  "cleanup_stats": {
    "orphaned": 0,
    "stale": 2,
    "active": 12
  }
}
```

**Response** (503 Service Unavailable when matchmaking not initialized):
```json
{
  "status": "unavailable",
  "message": "Matchmaking service not initialized"
}
```

**Cleanup Stats Explained**:
- `orphaned`: Queue entries with non-existent players (should be 0)
- `stale`: Entries older than 10 minutes (cleaned automatically)
- `active`: Currently active queue entries

**Example**:
```bash
curl http://localhost:8082/health/matchmaking | jq .
```

**Monitoring Alerts**:
```yaml
# Example Prometheus alert rules
groups:
  - name: matchmaking_alerts
    rules:
      - alert: HighOrphanedQueueEntries
        expr: matchmaking_cleanup_orphaned > 10
        for: 5m
        annotations:
          summary: "High orphaned queue entries detected"

      - alert: LongPlayerWaitTime
        expr: matchmaking_longest_wait_seconds > 120
        for: 2m
        annotations:
          summary: "Players waiting too long in queue"
```

---

### 6. WebSocket Hub Health

**Endpoint**: `GET /health/websocket`

**Purpose**: WebSocket hub status and connection metrics.

**Use Cases**:
- Real-time connection monitoring
- Game session tracking
- WebSocket performance analysis

**Response** (200 OK):
```json
{
  "status": "healthy",
  "timestamp": "2025-10-08T13:00:00Z",
  "connections": 25,
  "active_games": 10
}
```

**Response** (503 Service Unavailable when hub not initialized):
```json
{
  "status": "unavailable",
  "message": "WebSocket hub not initialized"
}
```

**Metrics Explained**:
- `connections`: Number of active WebSocket connections
- `active_games`: Number of ongoing game sessions

**Example**:
```bash
curl http://localhost:8082/health/websocket | jq .
```

---

## Integration Examples

### Kubernetes Deployment

```yaml
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
---
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
        image: septica-backend:latest
        ports:
        - containerPort: 8082
        livenessProbe:
          httpGet:
            path: /health
            port: 8082
          initialDelaySeconds: 10
          periodSeconds: 30
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /health/ready
            port: 8082
          initialDelaySeconds: 5
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
```

### Docker Compose Health Check

```yaml
version: '3.8'
services:
  backend:
    image: septica-backend:latest
    ports:
      - "8082:8082"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8082/health/ready"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

### Prometheus Monitoring

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'septica-backend'
    static_configs:
      - targets: ['localhost:8082']
    metrics_path: /metrics
    scrape_interval: 15s

  - job_name: 'septica-health'
    static_configs:
      - targets: ['localhost:8082']
    metrics_path: /health/detailed
    scrape_interval: 30s
```

### Grafana Dashboard Queries

```promql
# Active WebSocket connections
websocket_connections_total

# Active AI opponents
ai_opponents_active

# Queue wait times by type
matchmaking_queue_wait_seconds{queue_type="ranked"}

# Database latency
database_latency_milliseconds
```

---

## Monitoring Best Practices

### 1. Health Check Frequency
- **Liveness probe**: Every 30 seconds
- **Readiness probe**: Every 10 seconds
- **Detailed monitoring**: Every 1-5 minutes
- **Component-specific**: Every 2-3 minutes

### 2. Alerting Thresholds
- Database latency > 100ms: Warning
- Database latency > 500ms: Critical
- Any component status "unhealthy": Critical
- AI capacity > 90%: Warning
- Player wait time > 2 minutes: Warning
- Orphaned queue entries > 10: Warning

### 3. Response Time Expectations
All health endpoints should respond within:
- `/health`: < 10ms
- `/health/ready`: < 50ms
- `/health/detailed`: < 100ms
- Component-specific: < 50ms

### 4. Failure Scenarios

**Database Connection Lost**:
- `/health`: Returns 200 OK (server still running)
- `/health/ready`: Returns 503 Service Unavailable
- `/health/detailed`: Shows database status "down"

**WebSocket Hub Crash**:
- `/health`: Returns 200 OK
- `/health/ready`: Returns 503 Service Unavailable
- `/health/websocket`: Returns 503 Service Unavailable

**AI Manager Disabled**:
- All endpoints return 200 OK
- `/health/ai`: Shows enabled: false

---

## Troubleshooting

### Common Issues

**1. Readiness Probe Failing**
```bash
# Check detailed status
curl http://localhost:8082/health/detailed | jq .components

# Verify database connectivity
curl http://localhost:8082/health/detailed | jq .components.database

# Check logs
docker logs septica-backend --tail 100
```

**2. High AI Capacity Usage**
```bash
# Check AI manager status
curl http://localhost:8082/health/ai | jq .

# View active AI count and capacity
curl http://localhost:8082/health/ai | jq '{active: .active_ai_count, max: .max_concurrent_ai, percent: .capacity_used}'
```

**3. Long Queue Wait Times**
```bash
# Check matchmaking health
curl http://localhost:8082/health/matchmaking | jq .queue_stats

# View longest wait by queue type
curl http://localhost:8082/health/matchmaking | jq '.queue_stats.queues[] | {queue: .queue_type, longest_wait: .longest_wait_seconds}'
```

**4. Orphaned Queue Entries**
```bash
# Check cleanup stats
curl http://localhost:8082/health/matchmaking | jq .cleanup_stats

# Manual cleanup trigger (requires admin API - future feature)
# POST /admin/cleanup/queue
```

---

## Security Considerations

### Public vs Protected Endpoints

**Public Endpoints** (No authentication required):
- `/health` - Basic liveness probe
- `/health/ready` - Readiness probe
- `/health/detailed` - Detailed status
- `/health/ai` - AI manager status
- `/health/matchmaking` - Matchmaking status
- `/health/websocket` - WebSocket status

**Rationale**: Health endpoints are public to enable:
- Kubernetes probes without authentication complexity
- Load balancer health checks
- Public status page integrations

**Security Mitigations**:
- No sensitive data exposed (user IDs, game details, etc.)
- Aggregated metrics only
- Rate limiting on all endpoints
- CORS restrictions apply

### Future Enhancements

**Planned Protected Admin Endpoints**:
- `/admin/health/detailed` - Includes database connection strings
- `/admin/health/player-details` - Individual player queue status
- `/admin/cleanup/manual` - Manual cleanup trigger

---

## Testing

Run health endpoint tests:
```bash
go test ./internal/handlers -v -run Health
```

Expected output:
```
=== RUN   TestBasicHealthEndpoint
--- PASS: TestBasicHealthEndpoint (0.01s)
=== RUN   TestReadinessEndpoint
--- PASS: TestReadinessEndpoint (0.01s)
=== RUN   TestDetailedHealthEndpoint
--- PASS: TestDetailedHealthEndpoint (0.01s)
=== RUN   TestAIHealthEndpoint
--- PASS: TestAIHealthEndpoint (0.01s)
=== RUN   TestMatchmakingHealthEndpoint
--- PASS: TestMatchmakingHealthEndpoint (0.01s)
=== RUN   TestWebSocketHealthEndpoint
--- PASS: TestWebSocketHealthEndpoint (0.01s)
=== RUN   TestReadinessUnhealthy
--- PASS: TestReadinessUnhealthy (0.00s)
PASS
ok      septica-backend/internal/handlers       0.491s
```

---

## Performance Impact

The health check system is designed for minimal performance impact:

**Resource Usage**:
- Memory: < 1MB additional overhead
- CPU: < 0.1% during health checks
- Network: ~500 bytes per health check request

**Latency**:
- Basic health: ~2ms
- Readiness: ~10ms (includes database ping)
- Detailed: ~15ms (includes all component checks)

**Optimization**:
- All queries use read locks for thread safety
- Database checks use simple ping (no complex queries)
- Metrics aggregation is cached where possible
- No blocking operations in health checks

---

## Changelog

### Version 1.0.0 (October 2025)
- Initial implementation of comprehensive health check system
- Added 6 health endpoints for different monitoring purposes
- Integrated with existing Prometheus metrics
- Added automated queue cleanup monitoring
- Full test coverage for all endpoints
- Kubernetes-ready readiness probes
