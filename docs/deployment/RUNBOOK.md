# Romanian Septica - Operations Runbook

## Quick Reference

### Emergency Contacts
- **On-Call Engineer**: +40-XXX-XXX-XXXX
- **DevOps Team**: devops@septica.ro
- **Incident Response**: incident@septica.ro

### Critical Thresholds
- **WebSocket Connections**: > 1800/2000 (90%)
- **Concurrent Games**: > 900/1000 (90%) 
- **Response Time**: > 500ms (Alert), > 1000ms (Critical)
- **Error Rate**: > 5% (Alert), > 10% (Critical)
- **Memory Usage**: > 80% (Warning), > 90% (Critical)
- **CPU Usage**: > 70% (Warning), > 85% (Critical)

## Incident Response Procedures

### Severity Levels

**SEV-1 (Critical)**: Service completely down, affects all users
**SEV-2 (High)**: Major feature impacted, affects many users  
**SEV-3 (Medium)**: Minor feature impacted, affects some users
**SEV-4 (Low)**: Cosmetic issue, minimal user impact

### Response Times
- **SEV-1**: 15 minutes
- **SEV-2**: 1 hour
- **SEV-3**: 4 hours  
- **SEV-4**: 24 hours

## Common Issues and Solutions

### 1. High WebSocket Connection Load

**Symptoms:**
- WebSocket connections approaching 1800+ limit
- Game connection failures
- Slow game response times

**Immediate Actions:**
```bash
# Check current connection count
kubectl exec deployment/septica-backend -n septica -- curl -s http://localhost:8080/metrics | grep websocket_connections

# Scale backend horizontally
kubectl scale deployment septica-backend --replicas=8 -n septica

# Monitor scaling progress
kubectl rollout status deployment/septica-backend -n septica

# Verify load distribution
kubectl get pods -n septica -l app.kubernetes.io/component=backend
```

**Root Cause Investigation:**
```bash
# Check WebSocket connection patterns
kubectl logs deployment/septica-backend -n septica | grep "websocket" | tail -100

# Analyze connection sources
kubectl exec deployment/septica-backend -n septica -- netstat -tn | grep :8080 | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr
```

### 2. Database Performance Issues

**Symptoms:**
- Slow query responses
- Database connection pool exhausted
- High database CPU usage

**Immediate Actions:**
```bash
# Check active connections
kubectl exec deployment/postgres -n septica -- psql -U septica_prod -d septica_prod -c "SELECT count(*) FROM pg_stat_activity WHERE state = 'active';"

# Check slow queries
kubectl exec deployment/postgres -n septica -- psql -U septica_prod -d septica_prod -c "SELECT query, mean_time, calls FROM pg_stat_statements ORDER BY mean_time DESC LIMIT 10;"

# Kill long-running queries if necessary
kubectl exec deployment/postgres -n septica -- psql -U septica_prod -d septica_prod -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE state = 'active' AND query_start < NOW() - INTERVAL '5 minutes';"
```

**Optimization:**
```bash
# Run VACUUM on large tables
kubectl exec deployment/postgres -n septica -- psql -U septica_prod -d septica_prod -c "VACUUM ANALYZE games;"
kubectl exec deployment/postgres -n septica -- psql -U septica_prod -d septica_prod -c "VACUUM ANALYZE players;"

# Check index usage
kubectl exec deployment/postgres -n septica -- psql -U septica_prod -d septica_prod -c "SELECT schemaname,tablename,attname,n_distinct,correlation FROM pg_stats WHERE tablename IN ('games', 'players');"
```

### 3. High Error Rate

**Symptoms:**
- Error rate > 5%
- Failed game actions
- Authentication failures

**Investigation:**
```bash
# Check recent errors
kubectl logs deployment/septica-backend -n septica | grep -i error | tail -50

# Group errors by type
kubectl logs deployment/septica-backend -n septica --since=1h | grep -i error | awk '{print $NF}' | sort | uniq -c | sort -nr

# Check Romanian game rule validation errors
kubectl logs deployment/septica-backend -n septica | grep "romanian.*rule\|septica.*validation" | tail -20
```

**Mitigation:**
```bash
# If authentication errors, restart backend pods
kubectl rollout restart deployment/septica-backend -n septica

# If game rule errors, verify configuration
kubectl get configmap septica-config -n septica -o yaml | grep -A 5 -B 5 GAME
```

### 4. Memory/CPU Resource Issues

**Symptoms:**
- Pod restarts due to OOMKilled
- High CPU usage alerts
- Slow response times

**Investigation:**
```bash
# Check resource usage
kubectl top pods -n septica --sort-by=memory
kubectl top pods -n septica --sort-by=cpu

# Check pod events for OOMKilled
kubectl get events -n septica --sort-by='.lastTimestamp' | grep -i "killed\|oom"

# Describe problematic pods
kubectl describe pod <pod-name> -n septica
```

**Immediate Actions:**
```bash
# Increase resource limits temporarily
kubectl patch deployment septica-backend -n septica -p '{"spec":{"template":{"spec":{"containers":[{"name":"septica-backend","resources":{"limits":{"memory":"1Gi","cpu":"800m"}}}]}}}}'

# Scale horizontally to distribute load
kubectl scale deployment septica-backend --replicas=6 -n septica
```

### 5. Redis Cache Issues

**Symptoms:**
- Session management failures
- Slow user authentication
- Cache miss ratio high

**Investigation:**
```bash
# Check Redis status
kubectl exec deployment/redis -n septica -- redis-cli ping

# Check Redis memory usage
kubectl exec deployment/redis -n septica -- redis-cli info memory

# Check cache statistics
kubectl exec deployment/redis -n septica -- redis-cli info stats
```

**Actions:**
```bash
# Clear cache if corrupted
kubectl exec deployment/redis -n septica -- redis-cli flushdb

# Restart Redis if necessary
kubectl rollout restart deployment/redis -n septica

# Check Redis configuration
kubectl exec deployment/redis -n septica -- redis-cli config get maxmemory
```

## Romanian Game-Specific Issues

### 1. Tournament System Failures

**Symptoms:**
- Tournament creation failures
- Bracket generation errors
- Romanian ELO rating calculation issues

**Investigation:**
```bash
# Check tournament logs
kubectl logs deployment/septica-backend -n septica | grep -i tournament | tail -20

# Verify tournament configuration
kubectl get configmap septica-config -n septica -o yaml | grep TOURNAMENT

# Check database tournament tables
kubectl exec deployment/postgres -n septica -- psql -U septica_prod -d septica_prod -c "SELECT COUNT(*) FROM tournaments WHERE status = 'active';"
```

### 2. Romanian Card Rule Validation

**Symptoms:**
- Invalid card plays accepted
- Romanian Septica rules not enforced
- Card beating logic errors

**Investigation:**
```bash
# Check Romanian rule validation
kubectl logs deployment/septica-backend -n septica | grep -i "romanian\|septica\|card.*beat\|rule.*validation"

# Test rule validation endpoint
kubectl exec deployment/septica-backend -n septica -- curl -X POST http://localhost:8080/api/validate-move -d '{"suit":"hearts","value":"7","trump":"spades"}'
```

### 3. Cultural Asset Loading Issues

**Symptoms:**
- Romanian cultural images not loading
- PWA assets missing
- Frontend display issues

**Investigation:**
```bash
# Check frontend logs
kubectl logs deployment/septica-frontend -n septica | tail -20

# Test static asset serving
kubectl exec deployment/septica-frontend -n septica -- curl -I http://localhost/images/romanian-cards/hearts-7.png

# Check nginx configuration
kubectl exec deployment/septica-frontend -n septica -- nginx -t
```

## Monitoring and Alerting

### Key Metrics Dashboard URLs

```bash
# Prometheus
kubectl port-forward svc/prometheus 9090:9090 -n monitoring &
# Access: http://localhost:9090

# Grafana  
kubectl port-forward svc/grafana 3000:3000 -n monitoring &
# Access: http://localhost:3000
```

### Critical Alerts Configuration

**High WebSocket Load:**
```yaml
alert: HighWebSocketConnections
expr: septica_websocket_connections > 1800
for: 5m
labels:
  severity: warning
  service: romanian-septica
annotations:
  summary: "WebSocket connections approaching limit"
  description: "Current connections: {{ $value }}/2000"
```

**Game Engine Errors:**
```yaml
alert: GameEngineErrors  
expr: rate(septica_game_errors_total[5m]) > 0.1
for: 2m
labels:
  severity: critical
  service: romanian-septica
annotations:
  summary: "Romanian Septica game engine errors"
  description: "Error rate: {{ $value }} errors/second"
```

### Health Check Commands

```bash
# Application health
curl -f https://septica.ro/health

# Backend API health
kubectl exec deployment/septica-backend -n septica -- curl -f http://localhost:8080/health

# Database health
kubectl exec deployment/postgres -n septica -- pg_isready -U septica_prod

# Redis health
kubectl exec deployment/redis -n septica -- redis-cli ping

# Frontend health
kubectl exec deployment/septica-frontend -n septica -- curl -f http://localhost/health
```

## Maintenance Procedures

### Scheduled Maintenance

**Weekly Maintenance (Sundays 02:00 UTC):**
```bash
# Database maintenance
kubectl exec deployment/postgres -n septica -- psql -U septica_prod -d septica_prod -c "VACUUM ANALYZE;"

# Clear old logs (keep 7 days)
kubectl exec deployment/septica-backend -n septica -- find /app/logs -name "*.log" -mtime +7 -delete

# Redis maintenance
kubectl exec deployment/redis -n septica -- redis-cli bgrewriteaof
```

**Monthly Maintenance:**
```bash
# Update security patches
kubectl set image deployment/septica-backend septica-backend=ghcr.io/bogdan/septica/backend:latest -n septica
kubectl set image deployment/septica-frontend septica-frontend=ghcr.io/bogdan/septica/frontend:latest -n septica

# Database statistics update
kubectl exec deployment/postgres -n septica -- psql -U septica_prod -d septica_prod -c "ANALYZE;"

# Certificate renewal check
kubectl describe certificate septica-tls -n septica
```

### Rolling Updates

```bash
# Step 1: Update backend (zero-downtime)
kubectl set image deployment/septica-backend septica-backend=ghcr.io/bogdan/septica/backend:v1.2.0 -n septica

# Step 2: Monitor rollout
kubectl rollout status deployment/septica-backend -n septica --timeout=300s

# Step 3: Verify health
sleep 30
curl -f https://septica.ro/health

# Step 4: Update frontend
kubectl set image deployment/septica-frontend septica-frontend=ghcr.io/bogdan/septica/frontend:v1.2.0 -n septica

# Step 5: Monitor frontend rollout
kubectl rollout status deployment/septica-frontend -n septica --timeout=300s
```

## Disaster Recovery

### Data Backup Verification

```bash
# Verify latest backup
ls -la /backups/septica_backup_*.sql | tail -1

# Test backup restore (to staging)
kubectl exec deployment/postgres -n septica-staging -- psql -U septica_staging -d septica_staging < latest_backup.sql
```

### Failover Procedures

**Database Failover:**
```bash
# 1. Promote read replica to primary
kubectl patch service postgres -n septica -p '{"spec":{"selector":{"role":"master"}}}'

# 2. Update connection strings
kubectl patch secret septica-secrets -n septica --type='json' -p='[{"op": "replace", "path": "/data/DATABASE_URL", "value":"'$(echo -n "postgres://septica_prod:password@postgres-failover:5432/septica_prod" | base64)'"}]'

# 3. Restart backend pods to pick up new connection
kubectl rollout restart deployment/septica-backend -n septica
```

**Application Failover:**
```bash
# 1. Switch traffic to backup region
# Update DNS A record: septica.ro → backup-lb-ip

# 2. Verify backup region health
curl -f https://backup.septica.ro/health

# 3. Monitor traffic switch
watch "dig septica.ro +short"
```

## Performance Tuning

### Database Optimization

```sql
-- Romanian Septica specific optimizations
CREATE INDEX CONCURRENTLY idx_games_players ON games USING gin(player_ids);
CREATE INDEX CONCURRENTLY idx_game_moves_timestamp ON game_moves(created_at) WHERE created_at > NOW() - INTERVAL '24 hours';
CREATE INDEX CONCURRENTLY idx_tournaments_elo ON tournament_participants(elo_rating);

-- Analyze Romanian card game patterns
ANALYZE games;
ANALYZE players;  
ANALYZE tournaments;
```

### Application Tuning

```bash
# Optimize Go garbage collection
kubectl patch deployment septica-backend -n septica -p '{"spec":{"template":{"spec":{"containers":[{"name":"septica-backend","env":[{"name":"GOGC","value":"100"},{"name":"GOMEMLIMIT","value":"400Mi"}]}]}}}}'

# Optimize WebSocket settings
kubectl patch configmap septica-config -n septica --type merge -p '{"data":{"WS_READ_BUFFER_SIZE":"2048","WS_WRITE_BUFFER_SIZE":"2048"}}'
```

## Capacity Planning

### Current Limits
- WebSocket Connections: 2000
- Concurrent Games: 1000  
- Database Connections: 100
- Memory per Pod: 512Mi-1Gi
- CPU per Pod: 100m-800m

### Scaling Triggers
- Scale backend when connections > 1500
- Scale frontend when CPU > 70%
- Add database read replicas when connections > 80
- Increase PVC size when storage > 80%

### Growth Planning
```bash
# Estimate capacity needs
# Current: 2000 concurrent users
# Target: 10000 concurrent users (5x growth)

# Required scaling:
# Backend pods: 5 → 25 (5x)
# Frontend pods: 3 → 15 (5x)  
# Database connections: 100 → 500 (5x)
# Storage: 100GB → 500GB (5x)
```

## Communication Templates

### Incident Notification

```
🚨 INCIDENT ALERT - Romanian Septica

Severity: SEV-2
Service: Backend API
Issue: High error rate (12%)
Impact: Users experiencing game connection failures
Started: 2024-09-21 14:30 UTC
Status: Investigating

Actions taken:
- Scaled backend from 3 to 6 pods
- Investigating WebSocket connection issues
- Database performance normal

Next update: 15 minutes
Incident Commander: @devops-oncall
```

### Maintenance Notification

```
🔧 SCHEDULED MAINTENANCE - Romanian Septica

When: Sunday 2024-09-22, 02:00-04:00 UTC
Duration: 2 hours maximum
Impact: Brief interruptions during updates

What we're doing:
- Security updates for all services
- Database optimization
- Romanian game rule validation improvements

Expected downtime: <5 minutes total
Status page: https://status.septica.ro
```

---

**🇷🇴 For emergency assistance with Romanian Septica operations, contact the on-call engineer immediately! 🎮**