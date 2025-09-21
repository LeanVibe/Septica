# Romanian Septica - Production Deployment Guide

## Overview

This guide provides comprehensive instructions for deploying the Romanian Septica multiplayer card game platform to production. The system is designed for high availability, scalability, and authentic Romanian gaming experience.

## Architecture Overview

```
Internet
    ↓
[Load Balancer] → [Ingress Controller]
    ↓
[Frontend Pods] ← WebSocket → [Backend Pods]
    ↓                           ↓
[Static Assets]            [PostgreSQL]
                          [Redis Cache]
```

**Components:**
- **Go Backend**: Game engine, WebSocket server, tournament system
- **PWA Frontend**: Three.js enhanced UI with Romanian cultural themes
- **PostgreSQL**: Game state, player profiles, ELO ratings
- **Redis**: Session management, real-time caching
- **Prometheus + Grafana**: Monitoring and analytics

## Prerequisites

### Infrastructure Requirements

1. **Kubernetes Cluster**
   - Minimum: 3 worker nodes (4 vCPU, 8GB RAM each)
   - Production: 5+ worker nodes (8 vCPU, 16GB RAM each)
   - Kubernetes version: 1.25+

2. **Storage**
   - Fast SSD storage class (50+ IOPS)
   - Minimum: 200GB total storage
   - Backup solution configured

3. **Network**
   - Load balancer with SSL termination
   - CDN for static assets (optional but recommended)
   - DDoS protection

### Required Tools

```bash
# Install required CLI tools
kubectl version --client
kustomize version
helm version
docker version
```

### Access Requirements

- Kubernetes cluster admin access
- Container registry access (GitHub Container Registry)
- DNS management for domain configuration
- SSL certificate management

## Environment Setup

### 1. Namespace Preparation

```bash
# Create production namespace
kubectl create namespace septica

# Create monitoring namespace
kubectl create namespace monitoring

# Label namespaces for network policies
kubectl label namespace septica name=septica
kubectl label namespace monitoring name=monitoring
```

### 2. Secret Management

⚠️ **CRITICAL**: Never use default secrets in production!

```bash
# Generate strong secrets
openssl rand -base64 32  # For JWT_SECRET
openssl rand -base64 32  # For GAME_ENCRYPTION_KEY
openssl rand -base64 32  # For SESSION_SECRET

# Create production secrets
kubectl create secret generic septica-secrets \
  --from-literal=DATABASE_URL="postgres://septica_prod:STRONG_PASSWORD@postgres:5432/septica_prod?sslmode=require" \
  --from-literal=JWT_SECRET="YOUR_64_CHAR_JWT_SECRET" \
  --from-literal=GAME_ENCRYPTION_KEY="YOUR_32_CHAR_GAME_KEY" \
  --from-literal=SESSION_SECRET="YOUR_SESSION_SECRET" \
  -n septica
```

### 3. SSL Certificate Setup

```bash
# Install cert-manager for automatic SSL
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Create Let's Encrypt cluster issuer
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@septica.ro
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
```

## Deployment Process

### Phase 1: Infrastructure Deployment

```bash
# 1. Deploy monitoring stack first
kubectl apply -f k8s/monitoring/prometheus.yaml
kubectl apply -f k8s/monitoring/grafana.yaml

# Wait for monitoring to be ready
kubectl wait --for=condition=ready pod -l app=prometheus -n monitoring --timeout=300s
kubectl wait --for=condition=ready pod -l app=grafana -n monitoring --timeout=300s
```

### Phase 2: Database Setup

```bash
# 2. Deploy PostgreSQL with persistent storage
kubectl apply -k k8s/overlays/production/

# Wait for database to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=database -n septica --timeout=300s

# Run database migrations
kubectl exec -it deployment/postgres -n septica -- psql -U septica_prod -d septica_prod -c "SELECT version();"
```

### Phase 3: Application Deployment

```bash
# 3. Deploy backend services
kubectl rollout status deployment/septica-backend -n septica --timeout=600s

# 4. Deploy frontend services  
kubectl rollout status deployment/septica-frontend -n septica --timeout=300s

# 5. Verify all services are healthy
kubectl get pods -n septica
kubectl get svc -n septica
kubectl get ingress -n septica
```

### Phase 4: DNS and SSL Configuration

```bash
# Configure DNS records (external to cluster)
# A record: septica.ro → Load Balancer IP
# CNAME: www.septica.ro → septica.ro

# Verify SSL certificate issuance
kubectl describe certificate septica-tls -n septica
kubectl get certificaterequest -n septica
```

## Configuration Management

### Environment-Specific Settings

**Staging Environment:**
```bash
# Deploy to staging
kubectl apply -k k8s/overlays/staging/

# Verify staging deployment
kubectl get pods -n septica-staging
```

**Production Environment:**
```bash
# Deploy to production with security policies
kubectl apply -k k8s/overlays/production/

# Enable additional security
kubectl apply -f k8s/overlays/production/pod-security-policy.yaml
kubectl apply -f k8s/overlays/production/network-policy-strict.yaml
```

### Scaling Configuration

```bash
# Manual scaling for high traffic events
kubectl scale deployment septica-backend --replicas=10 -n septica
kubectl scale deployment septica-frontend --replicas=6 -n septica

# Configure HPA for auto-scaling
kubectl get hpa -n septica
```

## Monitoring Setup

### Prometheus Configuration

```bash
# Access Prometheus dashboard
kubectl port-forward svc/prometheus 9090:9090 -n monitoring

# Verify Romanian Septica metrics
curl http://localhost:9090/api/v1/query?query=septica_websocket_connections
```

### Grafana Dashboard

```bash
# Access Grafana dashboard
kubectl port-forward svc/grafana 3000:3000 -n monitoring

# Login credentials
# Username: admin
# Password: Check secret or set during deployment
kubectl get secret grafana-secrets -n monitoring -o jsonpath='{.data.GF_SECURITY_ADMIN_PASSWORD}' | base64 -d
```

**Key Metrics to Monitor:**
- WebSocket connections: `septica_websocket_connections`
- Concurrent games: `septica_concurrent_games`
- Tournament participation: `septica_tournament_participants`
- Response times: `septica_game_action_duration_seconds`
- Error rates: `septica_game_errors_total`

## Security Hardening

### Network Security

```bash
# Verify network policies are active
kubectl get networkpolicy -n septica

# Test network isolation
kubectl run test-pod --image=busybox -n septica --rm -it -- wget -O- septica-backend:8080/health
```

### Pod Security

```bash
# Verify pod security policies
kubectl get psp septica-psp

# Check security context compliance
kubectl get pods -n septica -o jsonpath='{.items[*].spec.securityContext}'
```

### Resource Limits

```bash
# Verify resource limits are enforced
kubectl describe pods -n septica | grep -A 10 "Limits"

# Monitor resource usage
kubectl top pods -n septica
kubectl top nodes
```

## Backup and Recovery

### Database Backup

```bash
# Create database backup
kubectl exec deployment/postgres -n septica -- pg_dump -U septica_prod septica_prod > septica_backup_$(date +%Y%m%d_%H%M%S).sql

# Automated backup script (run via cron)
cat <<EOF > backup-script.sh
#!/bin/bash
BACKUP_FILE="septica_backup_\$(date +%Y%m%d_%H%M%S).sql"
kubectl exec deployment/postgres -n septica -- pg_dump -U septica_prod septica_prod > "\$BACKUP_FILE"
# Upload to cloud storage
aws s3 cp "\$BACKUP_FILE" s3://septica-backups/database/
EOF
```

### Configuration Backup

```bash
# Backup Kubernetes configurations
kubectl get all,configmap,secret,pvc,ingress -n septica -o yaml > septica-k8s-backup.yaml

# Backup monitoring configurations
kubectl get all,configmap,secret,pvc -n monitoring -o yaml > monitoring-backup.yaml
```

## Troubleshooting

### Common Issues

**1. WebSocket Connection Issues**
```bash
# Check backend logs
kubectl logs -f deployment/septica-backend -n septica

# Test WebSocket endpoint
kubectl exec -it deployment/septica-frontend -n septica -- curl -v http://septica-backend:8080/ws/connect
```

**2. Database Connection Problems**
```bash
# Check database status
kubectl exec -it deployment/postgres -n septica -- pg_isready -U septica_prod

# Check connection string
kubectl get secret septica-secrets -n septica -o jsonpath='{.data.DATABASE_URL}' | base64 -d
```

**3. SSL Certificate Issues**
```bash
# Check certificate status
kubectl describe certificate septica-tls -n septica

# Force certificate renewal
kubectl delete certificaterequest --all -n septica
```

### Performance Diagnostics

```bash
# Check resource usage
kubectl top pods -n septica --sort-by=memory
kubectl top pods -n septica --sort-by=cpu

# Analyze slow queries
kubectl exec -it deployment/postgres -n septica -- psql -U septica_prod -d septica_prod -c "SELECT query, mean_time, calls FROM pg_stat_statements ORDER BY mean_time DESC LIMIT 10;"
```

## Maintenance Procedures

### Rolling Updates

```bash
# Update backend image
kubectl set image deployment/septica-backend septica-backend=ghcr.io/bogdan/septica/backend:v1.1.0 -n septica

# Update frontend image
kubectl set image deployment/septica-frontend septica-frontend=ghcr.io/bogdan/septica/frontend:v1.1.0 -n septica

# Monitor rollout
kubectl rollout status deployment/septica-backend -n septica
kubectl rollout status deployment/septica-frontend -n septica
```

### Database Maintenance

```bash
# Vacuum and analyze database
kubectl exec deployment/postgres -n septica -- psql -U septica_prod -d septica_prod -c "VACUUM ANALYZE;"

# Check database size
kubectl exec deployment/postgres -n septica -- psql -U septica_prod -d septica_prod -c "SELECT pg_size_pretty(pg_database_size('septica_prod'));"
```

### Log Management

```bash
# View application logs
kubectl logs -f deployment/septica-backend -n septica --tail=100

# Export logs for analysis
kubectl logs deployment/septica-backend -n septica --since=1h > backend-logs.txt
```

## Disaster Recovery

### Recovery Procedures

1. **Database Recovery**
```bash
# Restore from backup
kubectl exec -i deployment/postgres -n septica -- psql -U septica_prod -d septica_prod < septica_backup_20240921_120000.sql
```

2. **Full Application Recovery**
```bash
# Restore entire application
kubectl apply -f septica-k8s-backup.yaml
kubectl apply -f monitoring-backup.yaml
```

3. **DNS Failover**
- Update DNS records to point to backup infrastructure
- Verify SSL certificates are valid for backup domain

## Performance Optimization

### Database Optimization

```sql
-- Optimize Romanian Septica queries
CREATE INDEX CONCURRENTLY idx_games_active ON games(status) WHERE status = 'active';
CREATE INDEX CONCURRENTLY idx_players_elo ON players(elo_rating);
CREATE INDEX CONCURRENTLY idx_tournaments_date ON tournaments(start_date);
```

### Caching Strategy

```bash
# Configure Redis for optimal performance
kubectl exec deployment/redis -n septica -- redis-cli CONFIG SET maxmemory-samples 10
kubectl exec deployment/redis -n septica -- redis-cli CONFIG SET timeout 300
```

### CDN Configuration

```nginx
# Configure CDN for static Romanian cultural assets
location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
    add_header X-Romanian-Cultural-Asset "true";
}
```

## Success Metrics

**Deployment Success Criteria:**
- ✅ All pods running and healthy
- ✅ WebSocket connections working
- ✅ Database migrations completed
- ✅ SSL certificate issued
- ✅ Monitoring dashboards accessible
- ✅ Romanian game rules functioning correctly
- ✅ Tournament system operational

**Performance Targets:**
- Response time: < 100ms for API calls
- WebSocket latency: < 50ms
- Game action processing: < 200ms
- Concurrent players: 2000+
- Uptime: 99.9%

## Support Contacts

**Technical Support:**
- DevOps Team: devops@septica.ro
- Development Team: dev@septica.ro
- Infrastructure: infrastructure@septica.ro

**Emergency Contacts:**
- On-call Engineer: +40-XXX-XXX-XXXX
- System Administrator: admin@septica.ro

**Romanian Cultural Consultant:**
- Game Rules Validation: cultural@septica.ro
- Traditional Gaming Expert: traditions@septica.ro

---

**🇷🇴 Romanian Septica Production Deployment - Bringing Authentic Romanian Card Gaming to the World! 🎮**