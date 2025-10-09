# Romanian Septica Backend - Developer Guide

Complete guide for developers working on the Romanian Septica backend project.

## Table of Contents

1. [Getting Started](#getting-started)
2. [Development Workflow](#development-workflow)
3. [Makefile Commands](#makefile-commands)
4. [Testing Strategy](#testing-strategy)
5. [Code Quality](#code-quality)
6. [Database Management](#database-management)
7. [Docker Development](#docker-development)
8. [CI/CD Pipeline](#cicd-pipeline)
9. [Troubleshooting](#troubleshooting)
10. [Best Practices](#best-practices)

---

## Getting Started

### Prerequisites

- **Go 1.24.0+** - [Download](https://golang.org/dl/)
- **Docker & Docker Compose** - [Download](https://www.docker.com/products/docker-desktop)
- **PostgreSQL 15+** (or use Docker)
- **Make** (usually pre-installed on macOS/Linux)

### Initial Setup

```bash
# Clone the repository
git clone <repository-url>
cd backend

# Complete development environment setup (one command!)
make setup

# This will:
# - Install development tools (golangci-lint, air)
# - Download Go dependencies
# - Start Docker containers (PostgreSQL)
```

### Quick Start

```bash
# Start the backend server
make run

# Or with hot reload (recommended for development)
make watch

# Server will be available at http://localhost:8082
```

---

## Development Workflow

### Recommended Workflow

1. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   ```bash
   # Use hot reload for rapid development
   make watch
   ```

3. **Run quality checks**
   ```bash
   make check  # Runs format + vet + test
   ```

4. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat: your feature description"
   ```

5. **Push and create PR**
   ```bash
   git push origin feature/your-feature-name
   ```

### Hot Reload Development

For the best development experience, use `make watch` which provides instant feedback:

```bash
make watch

# Automatically reloads on file changes
# Provides immediate error feedback
# Maintains database connections
```

---

## Makefile Commands

### Essential Commands

```bash
make help         # Show all available commands
make info         # Show project information
make stats        # Show code statistics
```

### Build & Run

| Command | Description |
|---------|-------------|
| `make build` | Build Go binary (output: `server`) |
| `make run` | Run server on port 8082 |
| `make watch` | Run with hot reload (requires air) |
| `make clean` | Remove build artifacts |

### Testing

| Command | Description |
|---------|-------------|
| `make test` | Run all tests with coverage |
| `make test-unit` | Run unit tests only (fast) |
| `make test-integration` | Run integration tests |
| `make test-verbose` | Run tests with verbose output |
| `make test-race` | Run tests with race detector |
| `make test-ai` | Run AI player tests |
| `make coverage` | Generate HTML coverage report |
| `make coverage-check` | Fail if coverage < 70% |

### Code Quality

| Command | Description |
|---------|-------------|
| `make format` | Format code with gofmt |
| `make lint` | Run golangci-lint |
| `make vet` | Run go vet |
| `make check` | Run all quality checks |

### Docker

| Command | Description |
|---------|-------------|
| `make docker-build` | Build Docker image |
| `make docker-up` | Start all containers |
| `make docker-down` | Stop all containers |
| `make docker-logs` | Tail all logs |
| `make docker-logs-backend` | Tail backend logs only |
| `make docker-logs-db` | Tail database logs only |
| `make docker-clean` | Remove containers and volumes |
| `make docker-restart` | Restart all containers |

### Database

| Command | Description |
|---------|-------------|
| `make db-shell` | Connect to PostgreSQL shell |
| `make db-status` | Check database connection |
| `make db-reset` | Drop and recreate database ⚠️ |
| `make db-backup` | Backup database to file |

### Development Utilities

| Command | Description |
|---------|-------------|
| `make deps` | Download Go dependencies |
| `make deps-update` | Update dependencies |
| `make deps-tidy` | Tidy dependencies |
| `make install-tools` | Install dev tools |
| `make setup` | Complete environment setup |

### Monitoring & Debugging

| Command | Description |
|---------|-------------|
| `make health` | Check server health |
| `make metrics` | Show Prometheus metrics |
| `make ps` | Show running processes |
| `make kill` | Kill all backend processes |

### CI/CD

| Command | Description |
|---------|-------------|
| `make ci-build` | Run complete CI pipeline |
| `make ci-test` | Run CI test pipeline |
| `make pre-commit` | Run pre-commit checks |
| `make install-hooks` | Install git hooks |

---

## Testing Strategy

### Coverage Requirements

- **Minimum Coverage**: 70%
- **Target Coverage**: 80%+
- **Critical Paths**: 90%+ (game engine, authentication)

### Running Tests

```bash
# Quick unit tests (during development)
make test-unit

# Full test suite with coverage
make test

# Check coverage threshold
make coverage-check

# Generate HTML coverage report
make coverage
open coverage.html
```

### Test Organization

```
backend/
├── internal/
│   ├── game/
│   │   ├── engine.go
│   │   └── engine_test.go          # Unit tests
│   ├── websocket/
│   │   ├── hub.go
│   │   └── hub_test.go
└── tests/
    └── integration/                 # Integration tests
        └── game_flow_test.go
```

### Writing Tests

**Unit Test Example:**
```go
func TestGameEngine_PlayCard(t *testing.T) {
    // Arrange
    engine := NewGameEngine()

    // Act
    err := engine.PlayCard(player, card)

    // Assert
    assert.NoError(t, err)
    assert.Equal(t, expectedState, engine.State)
}
```

**Integration Test Example:**
```go
func TestGameFlow_Integration(t *testing.T) {
    if testing.Short() {
        t.Skip("Skipping integration test")
    }

    // Test complete game flow
}
```

### Test Coverage Analysis

```bash
# View coverage summary
./scripts/test-coverage.sh

# Output includes:
# - Total coverage percentage
# - Top 10 files by coverage
# - Bottom 10 files by coverage
# - Package-level breakdown
```

---

## Code Quality

### Pre-commit Checks

Install the pre-commit hook to automatically check code quality:

```bash
make install-hooks
```

The hook runs:
1. Code formatting check
2. `go vet` static analysis
3. `go.mod`/`go.sum` validation
4. Unit tests
5. Common issue detection

### Manual Quality Checks

```bash
# Format code
make format

# Run static analysis
make vet

# Run linter
make lint

# Run all quality checks
make check
```

### Linting Configuration

The project uses `golangci-lint` with custom configuration. Create `.golangci.yml`:

```yaml
linters:
  enable:
    - gofmt
    - govet
    - errcheck
    - staticcheck
    - gosimple
    - ineffassign
    - unused

linters-settings:
  gofmt:
    simplify: true
```

### Code Style Guidelines

1. **Follow Go conventions**
   - Use `gofmt` for formatting
   - Follow [Effective Go](https://golang.org/doc/effective_go.html)

2. **Error handling**
   ```go
   if err != nil {
       return fmt.Errorf("context: %w", err)
   }
   ```

3. **Context usage**
   ```go
   func DoSomething(ctx context.Context) error {
       // Use context for cancellation and timeouts
   }
   ```

4. **Testing**
   - Write table-driven tests
   - Use `testify/assert` for assertions
   - Mock external dependencies

---

## Database Management

### Connection Details

**Local Development:**
- Host: `localhost`
- Port: `5435`
- Database: `septica`
- User: `septica_user`
- Password: `septica_dev_password`

### Database Shell Access

```bash
# Connect to PostgreSQL
make db-shell

# Example queries
SELECT * FROM users;
SELECT * FROM games WHERE status = 'active';
```

### Database Operations

```bash
# Check database connection
make db-status

# Backup database
make db-backup
# Creates: backup_YYYYMMDD_HHMMSS.sql

# Reset database (⚠️ DESTROYS DATA)
make db-reset
```

### Migrations

The project uses GORM auto-migrations:

```go
// Migrations run automatically on server startup
db.AutoMigrate(&User{}, &Game{}, &GameState{})
```

To skip migrations:
```bash
SKIP_MIGRATIONS=true make run
```

---

## Docker Development

### Container Architecture

```
┌─────────────────────────────────────┐
│  Backend (Go)                       │
│  Port: 8082                         │
│  Health: /health                    │
└─────────────────┬───────────────────┘
                  │
                  ▼
┌─────────────────────────────────────┐
│  PostgreSQL                         │
│  Port: 5435                         │
│  Volume: postgres_data              │
└─────────────────────────────────────┘
```

### Docker Commands

```bash
# Start all services
make docker-up

# View logs
make docker-logs

# Stop services
make docker-down

# Rebuild and restart
make docker-build
make docker-restart

# Clean everything (including volumes)
make docker-clean
```

### Environment Variables

Create `.env` file:

```bash
# Server
PORT=8082
ENVIRONMENT=development

# Database
DB_PASSWORD=your_secure_password

# JWT
JWT_SECRET=your_jwt_secret_min_32_chars
JWT_EXPIRATION=24h

# Game Settings
MAX_CONCURRENT_GAMES=10000
GAME_TIMEOUT=30m
```

---

## CI/CD Pipeline

### Local CI Testing

Test the complete CI pipeline locally:

```bash
make ci-build
```

Pipeline steps:
1. Environment information
2. Install dependencies
3. Code formatting check
4. Static analysis (go vet)
5. Linting (golangci-lint)
6. Unit tests
7. Integration tests
8. Coverage analysis (70% threshold)
9. Race detector
10. Build binary
11. Docker image build

### GitHub Actions Integration

The CI pipeline can be integrated with GitHub Actions:

```yaml
name: CI
on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-go@v4
        with:
          go-version: '1.24'
      - name: Run CI Pipeline
        run: make ci-build
```

---

## Troubleshooting

### Common Issues

#### Port Already in Use

```bash
# Kill existing processes
make kill

# Or use different port
PORT=8083 make run
```

#### Database Connection Failed

```bash
# Check if PostgreSQL is running
make db-status

# Restart Docker containers
make docker-restart

# Check Docker logs
make docker-logs-db
```

#### Tests Failing

```bash
# Run verbose tests to see details
make test-verbose

# Run specific test
go test -v ./internal/game -run TestSpecificTest

# Reset test database
make db-reset
```

#### Build Errors

```bash
# Clean and rebuild
make clean
make deps-tidy
make build
```

#### Coverage Below Threshold

```bash
# See which files need tests
./scripts/check-coverage.sh

# Generate detailed coverage report
make coverage
open coverage.html
```

### Debug Mode

Enable debug logging:

```bash
LOG_LEVEL=debug make run
```

### Performance Profiling

```bash
# CPU profiling
go test -cpuprofile=cpu.prof -bench=.

# Memory profiling
go test -memprofile=mem.prof -bench=.

# Analyze profiles
go tool pprof cpu.prof
```

---

## Best Practices

### Development Workflow

1. **Always use hot reload**: `make watch`
2. **Run tests before committing**: `make check`
3. **Install pre-commit hooks**: `make install-hooks`
4. **Keep coverage above 70%**: `make coverage-check`

### Code Organization

```
internal/
├── game/          # Game engine and rules
├── websocket/     # WebSocket protocol
├── auth/          # Authentication
├── database/      # Data models
├── handlers/      # HTTP handlers
├── middleware/    # HTTP middleware
└── ai/            # AI player logic
```

### Dependency Management

```bash
# Add new dependency
go get github.com/package/name

# Update dependencies
make deps-update

# Tidy dependencies
make deps-tidy
```

### Error Handling

```go
// Wrap errors with context
if err != nil {
    return fmt.Errorf("failed to create game: %w", err)
}

// Handle errors at appropriate levels
func HandleGameCreate(c *gin.Context) {
    if err := createGame(); err != nil {
        log.Error("Game creation failed", "error", err)
        c.JSON(500, gin.H{"error": "Failed to create game"})
        return
    }
}
```

### Testing Best Practices

1. **Write table-driven tests**
   ```go
   tests := []struct {
       name string
       input int
       want int
   }{
       {"case1", 1, 2},
       {"case2", 2, 4},
   }
   ```

2. **Use test helpers**: See `test/helpers.go`

3. **Mock external dependencies**

4. **Test edge cases and errors**

### Git Workflow

```bash
# Feature development
git checkout -b feature/awesome-feature
make check
git commit -m "feat: awesome feature"

# Bug fixes
git checkout -b fix/bug-description
make check
git commit -m "fix: bug description"

# Before pushing
make ci-build
git push origin feature/awesome-feature
```

---

## Quick Reference

### Daily Development Commands

```bash
# Morning setup
make docker-up          # Start services
make watch             # Start with hot reload

# During development
make test-unit         # Quick test feedback
make format           # Format code

# Before committing
make check            # Full quality check
git add .
git commit -m "..."

# End of day
make docker-down      # Stop services
```

### Emergency Commands

```bash
make kill             # Kill all processes
make docker-clean     # Clean everything
make db-reset         # Reset database
make setup           # Reinstall everything
```

---

## Additional Resources

- [Go Documentation](https://golang.org/doc/)
- [Gin Framework](https://gin-gonic.com/docs/)
- [GORM Documentation](https://gorm.io/docs/)
- [WebSocket Protocol](../multiplayer-protocol.md)
- [Game Rules](../game-rules.md)
- [API Documentation](../backend-api.md)

---

## Support

For issues or questions:
1. Check this guide
2. Run `make help`
3. Check project documentation in `docs/`
4. Create an issue on GitHub

---

**Happy Coding! 🎮🃏**
