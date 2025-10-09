# Developer Scripts

Automation scripts for the Romanian Septica Backend project.

## Available Scripts

### test-coverage.sh
Generates comprehensive test coverage reports with detailed statistics.

**Usage:**
```bash
./scripts/test-coverage.sh
```

**Features:**
- Runs all tests with atomic coverage mode
- Generates HTML coverage report (`coverage.html`)
- Shows coverage summary by package
- Lists top 10 and bottom 10 files by coverage
- Color-coded output for easy reading

**Output:**
- `coverage.out` - Raw coverage data
- `coverage.html` - Interactive HTML report

---

### check-coverage.sh
Validates that test coverage meets the minimum threshold (default: 70%).

**Usage:**
```bash
./scripts/check-coverage.sh

# Or with custom threshold
COVERAGE_THRESHOLD=80 ./scripts/check-coverage.sh
```

**Features:**
- Runs tests and calculates total coverage
- Compares against threshold (default 70%)
- Lists files with low coverage if below threshold
- Provides suggestions for improvement
- Exit code 1 if threshold not met (CI-friendly)

**Environment Variables:**
- `COVERAGE_THRESHOLD` - Minimum coverage percentage (default: 70)

---

### pre-commit
Git pre-commit hook that ensures code quality before commits.

**Installation:**
```bash
# Automatic installation
make install-hooks

# Or manual installation
cp scripts/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

**Checks Performed:**
1. ✓ Code formatting (gofmt)
2. ✓ Static analysis (go vet)
3. ✓ Dependency validation (go.mod/go.sum)
4. ✓ Unit tests (fast execution)
5. ✓ Common issues detection (debugging statements, TODOs)
6. ✓ Optional: golangci-lint (if installed)

**Bypass Hook (not recommended):**
```bash
git commit --no-verify -m "message"
```

---

### ci-build.sh
Complete CI/CD build pipeline for continuous integration.

**Usage:**
```bash
./scripts/ci-build.sh
```

**Pipeline Steps:**
1. Environment Information - Shows Go version, git info, build time
2. Install Dependencies - Downloads and tidies Go modules
3. Code Formatting Check - Validates gofmt compliance
4. Static Analysis - Runs go vet
5. Linting - Runs golangci-lint (if available)
6. Unit Tests - Executes fast unit tests
7. Integration Tests - Runs integration test suite
8. Test Coverage - Generates coverage and validates threshold
9. Race Detector - Checks for race conditions
10. Build Binary - Compiles the server binary
11. Docker Build - Creates Docker image (if Dockerfile exists)

**Environment Variables:**
- `COVERAGE_THRESHOLD` - Minimum coverage (default: 70)
- `BUILD_OUTPUT` - Binary name (default: server)

**Output Artifacts:**
- `server` - Compiled binary
- `coverage.html` - Coverage report
- `coverage.out` - Raw coverage data
- `test_results.log` - Test output
- `integration_results.log` - Integration test output
- `race_results.log` - Race detector output

**Exit Codes:**
- 0 - All steps successful
- 1 - One or more steps failed

---

## Integration with Makefile

All scripts are integrated with the Makefile for convenience:

```bash
# Test coverage
make coverage              # Run test-coverage.sh
make coverage-check        # Run check-coverage.sh

# Pre-commit
make pre-commit           # Run pre-commit checks
make install-hooks        # Install git hook

# CI pipeline
make ci-build            # Run complete CI pipeline
make ci-test             # Run test pipeline only
```

---

## Script Permissions

All scripts are executable by default. If needed, make them executable:

```bash
chmod +x scripts/*.sh scripts/pre-commit
```

---

## Customization

### Coverage Threshold

Adjust minimum coverage percentage:

```bash
# In scripts
export COVERAGE_THRESHOLD=80

# Or in Makefile
COVERAGE_THRESHOLD=80 make coverage-check
```

### CI Pipeline

Modify `ci-build.sh` to add/remove steps:

```bash
# Add custom step
run_step "12" "Custom Check" "
    echo 'Running custom validation...'
    ./custom-script.sh
"
```

### Pre-commit Hook

Customize checks in `scripts/pre-commit`:

```bash
# Add custom check
check_step "6" "Custom Validation"
if ! ./custom-validator.sh; then
    check_error "Custom validation failed"
fi
check_success "Custom validation OK"
```

---

## Troubleshooting

### Script Not Found

```bash
# Ensure scripts directory exists
ls -la scripts/

# Check permissions
ls -l scripts/
```

### Permission Denied

```bash
# Make scripts executable
chmod +x scripts/*.sh scripts/pre-commit
```

### Coverage Script Fails

```bash
# Run manually to see full output
go test ./... -coverprofile=coverage.out -covermode=atomic
go tool cover -func=coverage.out
```

### Pre-commit Hook Not Running

```bash
# Check hook installation
ls -l .git/hooks/pre-commit

# Reinstall
make install-hooks

# Test manually
./scripts/pre-commit
```

### CI Build Fails

```bash
# Run with verbose output
bash -x ./scripts/ci-build.sh

# Run individual steps
make format
make vet
make test
make build
```

---

## Best Practices

1. **Run coverage checks regularly**
   ```bash
   make coverage-check
   ```

2. **Install pre-commit hooks**
   ```bash
   make install-hooks
   ```

3. **Test CI pipeline locally before pushing**
   ```bash
   make ci-build
   ```

4. **Review coverage reports**
   ```bash
   make coverage
   open coverage.html
   ```

5. **Keep scripts updated** - Adjust thresholds and checks as project evolves

---

## CI/CD Integration

### GitHub Actions Example

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
        run: ./scripts/ci-build.sh
      - name: Upload Coverage
        uses: codecov/codecov-action@v3
        with:
          file: ./coverage.out
```

### GitLab CI Example

```yaml
test:
  image: golang:1.24
  script:
    - chmod +x scripts/ci-build.sh
    - ./scripts/ci-build.sh
  artifacts:
    paths:
      - coverage.html
      - server
```

---

## Maintenance

- Review and update scripts quarterly
- Adjust coverage thresholds as project matures
- Add new checks as needed
- Keep documentation synchronized with script changes

---

For more information, see the [Developer Guide](../docs/developer-guide.md).
