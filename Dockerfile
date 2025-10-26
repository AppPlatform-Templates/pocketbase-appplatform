# Build stage
FROM golang:1.24-alpine AS builder

WORKDIR /app

# Install build dependencies
RUN apk add --no-cache git ca-certificates

# PocketBase version to build (can be overridden via build args)
ARG POCKETBASE_VERSION=v0.31.0

# Clone PocketBase repository at specific version
RUN git clone --depth 1 --branch ${POCKETBASE_VERSION} https://github.com/pocketbase/pocketbase.git .

# Build the application from examples/base
WORKDIR /app/examples/base
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o /pocketbase

# Runtime stage
FROM alpine:latest

WORKDIR /app

# Install ca-certificates for HTTPS
RUN apk --no-cache add ca-certificates

# Copy the binary from builder
COPY --from=builder /pocketbase /app/pocketbase

# Create data directory for SQLite database
RUN mkdir -p /app/pb_data /app/pb_public

# Expose the default PocketBase port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/api/health || exit 1

# Run PocketBase
CMD ["/app/pocketbase", "serve", "--http=0.0.0.0:8080"]
