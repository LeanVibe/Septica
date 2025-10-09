# Observability Setup Guide

## Overview

Complete observability suite for Romanian Septica backend with Grafana dashboards, Prometheus alerts, and developer tooling.

## Quick Start

```bash
# View all available commands
make help

# Run tests with coverage
make test
make coverage

# Start development environment
make docker-up
make run

# Check system health
make health
make metrics
```

## Grafana Dashboards (Planned)

Three comprehensive dashboards covering all 16 Prometheus metrics:

### 1. Game Metrics Dashboard
- Concurrent games gauge
- Game duration distribution  
- Game errors by type
- Total games by mode

### 2. Matchmaking & AI Dashboard
- Queue sizes by type
- Queue wait times
- AI deployment stats
- Matchmaking success/failure rates
- Queue cleanup metrics

### 3. System Health Dashboard
- WebSocket connections
- Rate limit violations
- HTTP request metrics
- Message throughput

## Prometheus Alerts (Planned)

### Critical Alerts
- `QueueOverflow`: >100 players waiting
- `AIDeploymentFailureSpike`: >10 failures/min
- `DatabaseDown`: Service unavailable
- `HighGameErrorRate`: >6 errors/min

### Warning Alerts
- `LongQueueWaitTime`: 95th percentile >60s
- `HighRateLimitViolations`: >8 violations/min
- `WebSocketConnectionSpike`: +50 connections in 5min
- `LowAIAvailability`: 0 AI with queue demand

## Current Status

✅ **Completed:**
- 16 Prometheus metrics exposed at `/metrics`
- 6 health check endpoints
- Developer Makefile (46 targets)
- Test coverage scripts (70% threshold)
- Pre-commit hooks
- CI/CD pipeline scripts

📋 **Planned:**
- Grafana dashboard JSON files
- Prometheus alert rule YAML files
- Dashboard import instructions
- Alert manager configuration

## Metrics Available

```
# Game Metrics
septica_concurrent_games
septica_games_total{mode}
septica_game_duration_seconds{mode}
septica_game_errors_total{type}

# WebSocket Metrics  
septica_websocket_connections
septica_websocket_messages_total{type,direction}
septica_websocket_errors_total{type}

# Matchmaking Metrics
septica_queue_size{queue_type}
septica_queue_wait_time_seconds{queue_type}
septica_matchmaking_success_total{queue_type}
septica_matchmaking_failures_total{reason}

# AI Metrics
septica_ai_opponents_active
septica_ai_move_duration_seconds{difficulty}
septica_ai_deployments_total{difficulty}
septica_ai_deployment_failures_total{reason}

# System Metrics
septica_queue_cleanup_total{type}
septica_rate_limit_exceeded_total{ip,path}
septica_http_request_duration_seconds{method,path,status}
septica_http_requests_total{method,path,status}
```

## Developer Workflow

```bash
# Initial setup
make setup

# Development
make watch              # Hot reload
make test-unit         # Fast tests
make format            # Code formatting

# Quality checks
make check             # Full validation
make coverage-check    # Enforce 70% coverage
make lint              # Static analysis

# Deployment
make docker-build      # Build image
make ci-build          # Full CI pipeline
```

## Next Steps

1. Import Grafana dashboards when dashboards are created
2. Configure Prometheus alert manager
3. Set up PagerDuty/Slack integration
4. Create runbook for alert responses

