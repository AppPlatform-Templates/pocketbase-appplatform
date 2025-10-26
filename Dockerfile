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

# Install dependencies
RUN apk --no-cache add ca-certificates wget

# Litestream version
ARG LITESTREAM_VERSION=v0.3.13

# Download and install Litestream
ADD https://github.com/benbjohnson/litestream/releases/download/${LITESTREAM_VERSION}/litestream-${LITESTREAM_VERSION}-linux-amd64.tar.gz /tmp/litestream.tar.gz
RUN tar -C /usr/local/bin -xzf /tmp/litestream.tar.gz && \
    rm /tmp/litestream.tar.gz && \
    chmod +x /usr/local/bin/litestream

# Copy the PocketBase binary from builder
COPY --from=builder /pocketbase /app/pocketbase

# Copy Litestream configuration
COPY litestream.yml /etc/litestream.yml

# Copy startup script
COPY scripts/run.sh /app/run.sh
RUN chmod +x /app/run.sh

# Create data directories for SQLite database
RUN mkdir -p /app/pb_data /app/pb_public

# Expose the default PocketBase port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/api/health || exit 1

# Run startup script (handles Litestream + PocketBase)
CMD ["/app/run.sh"]
