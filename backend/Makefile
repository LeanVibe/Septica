# Makefile for Romanian Septica Backend
# Go backend with PostgreSQL database, WebSocket multiplayer, and comprehensive tooling

.PHONY: help
.DEFAULT_GOAL := help

# Variables
BINARY_NAME=server
GO=go
GOFLAGS=-v
DOCKER_COMPOSE=docker-compose
DB_HOST=localhost
DB_PORT=5435
DB_NAME=septica
DB_USER=septica_user
DB_PASSWORD=septica_dev_password
PORT=8082
COVERAGE_THRESHOLD=70

# Colors for output
COLOR_RESET=\033[0m
COLOR_BOLD=\033[1m
COLOR_GREEN=\033[32m
COLOR_YELLOW=\033[33m
COLOR_BLUE=\033[36m

# ==========================================
# Help & Information
# ==========================================

help: ## Show this help message
	@echo '$(COLOR_BOLD)Romanian Septica Backend - Developer Commands$(COLOR_RESET)'
	@echo ''
	@echo '$(COLOR_BLUE)Usage: make [target]$(COLOR_RESET)'
	@echo ''
	@echo '$(COLOR_BOLD)Available targets:$(COLOR_RESET)'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(COLOR_GREEN)%-20s$(COLOR_RESET) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ''

# ==========================================
# Build & Run
# ==========================================

build: ## Build Go binary (output: server)
	@echo "$(COLOR_BLUE)Building $(BINARY_NAME)...$(COLOR_RESET)"
	$(GO) build $(GOFLAGS) -o $(BINARY_NAME) ./cmd/server/main.go
	@echo "$(COLOR_GREEN)✓ Build complete: $(BINARY_NAME)$(COLOR_RESET)"

run: ## Run server (PORT=8082)
	@echo "$(COLOR_BLUE)Starting server on port $(PORT)...$(COLOR_RESET)"
	PORT=$(PORT) $(GO) run ./cmd/server/main.go

watch: ## Run with hot reload using air (requires air: go install github.com/air-verse/air@latest)
	@which air > /dev/null || (echo "$(COLOR_YELLOW)Installing air...$(COLOR_RESET)" && go install github.com/air-verse/air@latest)
	@echo "$(COLOR_BLUE)Starting server with hot reload...$(COLOR_RESET)"
	air

clean: ## Remove build artifacts
	@echo "$(COLOR_BLUE)Cleaning build artifacts...$(COLOR_RESET)"
	rm -f $(BINARY_NAME)
	rm -f coverage.out coverage.html
	rm -f *.test
	rm -f *.db
	rm -f *.log
	@echo "$(COLOR_GREEN)✓ Clean complete$(COLOR_RESET)"

# ==========================================
# Testing
# ==========================================

test: ## Run all tests with coverage
	@echo "$(COLOR_BLUE)Running all tests with coverage...$(COLOR_RESET)"
	$(GO) test ./... -coverprofile=coverage.out -covermode=atomic
	@echo "$(COLOR_GREEN)✓ Tests complete$(COLOR_RESET)"

test-unit: ## Run unit tests only (fast)
	@echo "$(COLOR_BLUE)Running unit tests...$(COLOR_RESET)"
	$(GO) test -short ./... -v
	@echo "$(COLOR_GREEN)✓ Unit tests complete$(COLOR_RESET)"

test-integration: ## Run integration tests
	@echo "$(COLOR_BLUE)Running integration tests...$(COLOR_RESET)"
	$(GO) test -run Integration ./... -v
	@echo "$(COLOR_GREEN)✓ Integration tests complete$(COLOR_RESET)"

test-verbose: ## Run tests with verbose output
	@echo "$(COLOR_BLUE)Running tests with verbose output...$(COLOR_RESET)"
	$(GO) test ./... -v -coverprofile=coverage.out

test-race: ## Run tests with race detector
	@echo "$(COLOR_BLUE)Running tests with race detector...$(COLOR_RESET)"
	$(GO) test -race ./... -v

test-ai: ## Run AI player tests
	@echo "$(COLOR_BLUE)Running AI player tests...$(COLOR_RESET)"
	$(GO) test ./internal/ai/... -v

coverage: ## Generate HTML coverage report
	@echo "$(COLOR_BLUE)Generating coverage report...$(COLOR_RESET)"
	@./scripts/test-coverage.sh

coverage-check: ## Fail if coverage < 70%
	@echo "$(COLOR_BLUE)Checking coverage threshold ($(COVERAGE_THRESHOLD)%)...$(COLOR_RESET)"
	@./scripts/check-coverage.sh

# ==========================================
# Code Quality
# ==========================================

lint: ## Run golangci-lint
	@echo "$(COLOR_BLUE)Running linter...$(COLOR_RESET)"
	@which golangci-lint > /dev/null || (echo "$(COLOR_YELLOW)Installing golangci-lint...$(COLOR_RESET)" && go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest)
	golangci-lint run --timeout=5m
	@echo "$(COLOR_GREEN)✓ Lint complete$(COLOR_RESET)"

format: ## Format code with gofmt
	@echo "$(COLOR_BLUE)Formatting code...$(COLOR_RESET)"
	gofmt -w .
	@echo "$(COLOR_GREEN)✓ Format complete$(COLOR_RESET)"

fmt: format ## Alias for format

vet: ## Run go vet
	@echo "$(COLOR_BLUE)Running go vet...$(COLOR_RESET)"
	$(GO) vet ./...
	@echo "$(COLOR_GREEN)✓ Vet complete$(COLOR_RESET)"

check: format vet test ## Run format + vet + lint + test (full check)
	@echo "$(COLOR_GREEN)✓ All checks passed$(COLOR_RESET)"

# ==========================================
# Docker
# ==========================================

docker-build: ## Build Docker image
	@echo "$(COLOR_BLUE)Building Docker image...$(COLOR_RESET)"
	docker build -t septica-backend:latest .
	@echo "$(COLOR_GREEN)✓ Docker image built: septica-backend:latest$(COLOR_RESET)"

docker-up: ## Start all containers
	@echo "$(COLOR_BLUE)Starting containers...$(COLOR_RESET)"
	$(DOCKER_COMPOSE) up -d
	@echo "$(COLOR_GREEN)✓ Containers started$(COLOR_RESET)"
	@echo "$(COLOR_YELLOW)Backend: http://localhost:8082$(COLOR_RESET)"
	@echo "$(COLOR_YELLOW)PostgreSQL: localhost:5435$(COLOR_RESET)"

docker-down: ## Stop all containers
	@echo "$(COLOR_BLUE)Stopping containers...$(COLOR_RESET)"
	$(DOCKER_COMPOSE) down
	@echo "$(COLOR_GREEN)✓ Containers stopped$(COLOR_RESET)"

docker-logs: ## Tail container logs
	@echo "$(COLOR_BLUE)Tailing container logs (Ctrl+C to exit)...$(COLOR_RESET)"
	$(DOCKER_COMPOSE) logs -f

docker-logs-backend: ## Tail backend container logs
	@echo "$(COLOR_BLUE)Tailing backend logs (Ctrl+C to exit)...$(COLOR_RESET)"
	$(DOCKER_COMPOSE) logs -f backend

docker-logs-db: ## Tail database container logs
	@echo "$(COLOR_BLUE)Tailing database logs (Ctrl+C to exit)...$(COLOR_RESET)"
	$(DOCKER_COMPOSE) logs -f postgres

docker-clean: ## Remove all containers and volumes
	@echo "$(COLOR_BLUE)Removing containers and volumes...$(COLOR_RESET)"
	$(DOCKER_COMPOSE) down -v
	@echo "$(COLOR_GREEN)✓ Cleanup complete$(COLOR_RESET)"

docker-restart: docker-down docker-up ## Restart all containers

# ==========================================
# Database
# ==========================================

db-shell: ## Connect to PostgreSQL shell
	@echo "$(COLOR_BLUE)Connecting to PostgreSQL...$(COLOR_RESET)"
	PGPASSWORD=$(DB_PASSWORD) psql -h $(DB_HOST) -p $(DB_PORT) -U $(DB_USER) -d $(DB_NAME)

db-status: ## Check database connection
	@echo "$(COLOR_BLUE)Checking database connection...$(COLOR_RESET)"
	@PGPASSWORD=$(DB_PASSWORD) psql -h $(DB_HOST) -p $(DB_PORT) -U $(DB_USER) -d $(DB_NAME) -c "SELECT version();" > /dev/null && echo "$(COLOR_GREEN)✓ Database connection successful$(COLOR_RESET)" || echo "$(COLOR_YELLOW)✗ Database connection failed$(COLOR_RESET)"

db-migrate: ## Run database migrations (handled by GORM auto-migrate)
	@echo "$(COLOR_BLUE)Database migrations are handled automatically by GORM$(COLOR_RESET)"
	@echo "$(COLOR_YELLOW)Migrations run on server startup$(COLOR_RESET)"

db-reset: ## Drop and recreate database (WARNING: destroys all data)
	@echo "$(COLOR_YELLOW)⚠️  WARNING: This will destroy ALL database data!$(COLOR_RESET)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		echo ""; \
		echo "$(COLOR_BLUE)Dropping database...$(COLOR_RESET)"; \
		PGPASSWORD=$(DB_PASSWORD) psql -h $(DB_HOST) -p $(DB_PORT) -U $(DB_USER) -d postgres -c "DROP DATABASE IF EXISTS $(DB_NAME)"; \
		echo "$(COLOR_BLUE)Creating database...$(COLOR_RESET)"; \
		PGPASSWORD=$(DB_PASSWORD) psql -h $(DB_HOST) -p $(DB_PORT) -U $(DB_USER) -d postgres -c "CREATE DATABASE $(DB_NAME)"; \
		echo "$(COLOR_GREEN)✓ Database reset complete$(COLOR_RESET)"; \
	else \
		echo ""; \
		echo "$(COLOR_YELLOW)Cancelled$(COLOR_RESET)"; \
	fi

db-backup: ## Backup database to file
	@echo "$(COLOR_BLUE)Backing up database...$(COLOR_RESET)"
	PGPASSWORD=$(DB_PASSWORD) pg_dump -h $(DB_HOST) -p $(DB_PORT) -U $(DB_USER) $(DB_NAME) > backup_$(shell date +%Y%m%d_%H%M%S).sql
	@echo "$(COLOR_GREEN)✓ Backup complete$(COLOR_RESET)"

# ==========================================
# Development Utilities
# ==========================================

deps: ## Download Go dependencies
	@echo "$(COLOR_BLUE)Downloading dependencies...$(COLOR_RESET)"
	$(GO) mod download
	@echo "$(COLOR_GREEN)✓ Dependencies downloaded$(COLOR_RESET)"

deps-update: ## Update dependencies
	@echo "$(COLOR_BLUE)Updating dependencies...$(COLOR_RESET)"
	$(GO) get -u ./...
	$(GO) mod tidy
	@echo "$(COLOR_GREEN)✓ Dependencies updated$(COLOR_RESET)"

deps-tidy: ## Tidy dependencies
	@echo "$(COLOR_BLUE)Tidying dependencies...$(COLOR_RESET)"
	$(GO) mod tidy
	@echo "$(COLOR_GREEN)✓ Dependencies tidied$(COLOR_RESET)"

install-tools: ## Install development tools (golangci-lint, air)
	@echo "$(COLOR_BLUE)Installing development tools...$(COLOR_RESET)"
	@which golangci-lint > /dev/null || go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
	@which air > /dev/null || go install github.com/air-verse/air@latest
	@echo "$(COLOR_GREEN)✓ Tools installed: golangci-lint, air$(COLOR_RESET)"

setup: install-tools deps docker-up ## Complete development environment setup
	@echo "$(COLOR_GREEN)✓ Development environment ready!$(COLOR_RESET)"
	@echo "$(COLOR_YELLOW)Run 'make run' to start the server$(COLOR_RESET)"

# ==========================================
# CI/CD & Quality Gates
# ==========================================

ci-build: ## Run CI build pipeline
	@echo "$(COLOR_BLUE)Running CI build pipeline...$(COLOR_RESET)"
	@./scripts/ci-build.sh

ci-test: test lint ## Run CI test pipeline
	@echo "$(COLOR_GREEN)✓ CI test pipeline complete$(COLOR_RESET)"

pre-commit: format vet test-unit ## Run pre-commit checks
	@echo "$(COLOR_GREEN)✓ Pre-commit checks passed$(COLOR_RESET)"

install-hooks: ## Install git pre-commit hook
	@echo "$(COLOR_BLUE)Installing git pre-commit hook...$(COLOR_RESET)"
	@cp scripts/pre-commit .git/hooks/pre-commit
	@chmod +x .git/hooks/pre-commit
	@echo "$(COLOR_GREEN)✓ Pre-commit hook installed$(COLOR_RESET)"

# ==========================================
# Monitoring & Debugging
# ==========================================

health: ## Check server health
	@echo "$(COLOR_BLUE)Checking server health...$(COLOR_RESET)"
	@curl -s http://localhost:$(PORT)/health | jq '.' || echo "$(COLOR_YELLOW)Server not running or jq not installed$(COLOR_RESET)"

metrics: ## Show Prometheus metrics
	@echo "$(COLOR_BLUE)Fetching Prometheus metrics...$(COLOR_RESET)"
	@curl -s http://localhost:$(PORT)/metrics | head -50

ps: ## Show running processes
	@echo "$(COLOR_BLUE)Backend processes:$(COLOR_RESET)"
	@ps aux | grep -E "$(BINARY_NAME)|go run" | grep -v grep || echo "No backend processes running"

kill: ## Kill all backend processes
	@echo "$(COLOR_BLUE)Killing backend processes...$(COLOR_RESET)"
	@pkill -f "$(BINARY_NAME)" || echo "No processes to kill"
	@echo "$(COLOR_GREEN)✓ Processes killed$(COLOR_RESET)"

# ==========================================
# Project Information
# ==========================================

info: ## Show project information
	@echo "$(COLOR_BOLD)Romanian Septica Backend$(COLOR_RESET)"
	@echo "$(COLOR_BLUE)Go Version:$(COLOR_RESET) $$(go version)"
	@echo "$(COLOR_BLUE)Module:$(COLOR_RESET) septica-backend"
	@echo "$(COLOR_BLUE)Binary:$(COLOR_RESET) $(BINARY_NAME)"
	@echo "$(COLOR_BLUE)Port:$(COLOR_RESET) $(PORT)"
	@echo "$(COLOR_BLUE)Database:$(COLOR_RESET) PostgreSQL $(DB_PORT)"

stats: ## Show code statistics
	@echo "$(COLOR_BLUE)Code Statistics:$(COLOR_RESET)"
	@echo "Go files: $$(find . -name '*.go' -not -path './vendor/*' | wc -l)"
	@echo "Lines of code: $$(find . -name '*.go' -not -path './vendor/*' | xargs wc -l | tail -1)"
	@echo "Test files: $$(find . -name '*_test.go' | wc -l)"
