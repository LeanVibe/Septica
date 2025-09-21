# Multi-stage build for production-optimized Romanian Septica backend
# Stage 1: Builder stage with Go build environment
FROM golang:1.23-alpine AS builder

# Install essential build dependencies
RUN apk add --no-cache git ca-certificates tzdata

# Set working directory
WORKDIR /app

# Copy go mod files first for better layer caching
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build the Go binary with optimizations for production
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags='-w -s -extldflags "-static"' \
    -a -installsuffix cgo \
    -o septica-server \
    ./cmd/server/main.go

# Stage 2: Minimal runtime image
FROM alpine:3.18

# Install runtime dependencies
RUN apk --no-cache add ca-certificates tzdata curl

# Create non-root user for security
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

# Set timezone
ENV TZ=Europe/Bucharest

# Create necessary directories
RUN mkdir -p /app/logs && \
    chown -R appuser:appgroup /app

# Copy the binary from builder stage
COPY --from=builder /app/septica-server /app/septica-server

# Copy any static assets if needed
COPY --from=builder /app/migrations /app/migrations

# Set working directory
WORKDIR /app

# Switch to non-root user
USER appuser

# Expose the application port
EXPOSE 8080

# Health check configuration
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Environment variables with defaults
ENV PORT=8080
ENV ENV=production
ENV GIN_MODE=release

# Run the binary
CMD ["./septica-server"]