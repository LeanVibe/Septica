# Multi-stage build for production-optimized Romanian Septica backend
# Stage 1: Builder stage with Go build environment
FROM golang:1.23-alpine AS builder

# Install essential build dependencies
RUN apk add --no-cache git ca-certificates tzdata

# Set working directory
WORKDIR /app

# Copy go mod files first for better layer caching
COPY go.mod go.sum ./
RUN go mod download && go mod verify

# Copy source code
COPY . .

# Build the Go binary with optimizations for production
# CGO_ENABLED=0 for static binary, GOOS=linux for Linux containers
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags='-w -s -extldflags "-static"' \
    -a -installsuffix cgo \
    -o septica-server \
    ./cmd/server/main.go

# Stage 2: Minimal runtime image
FROM alpine:3.18

# Install runtime dependencies (ca-certificates for HTTPS, curl for health checks)
RUN apk --no-cache add ca-certificates tzdata curl wget

# Create non-root user for security best practices
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

# Set timezone to Romanian timezone
ENV TZ=Europe/Bucharest

# Create necessary directories with proper permissions
RUN mkdir -p /app/logs /app/migrations && \
    chown -R appuser:appgroup /app

# Copy the binary from builder stage
COPY --from=builder /app/septica-server /app/septica-server

# Copy migrations directory (for automated database setup)
COPY --from=builder --chown=appuser:appgroup /app/migrations /app/migrations

# Set working directory
WORKDIR /app

# Switch to non-root user (security best practice)
USER appuser

# Expose the application port (8082 is the actual running port)
EXPOSE 8082

# Health check configuration
# Checks every 30s, timeout after 3s, initial delay 5s, retry 3 times
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8082/health || exit 1

# Environment variables with production defaults
ENV PORT=8082
ENV ENVIRONMENT=production
ENV GIN_MODE=release

# Run the binary
CMD ["./septica-server"]
