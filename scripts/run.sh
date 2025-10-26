#!/bin/sh
set -e

echo "==================================="
echo "PocketBase Startup Script"
echo "==================================="

# Check if Litestream environment variables are configured
if [ -n "$LITESTREAM_ACCESS_KEY_ID" ] && [ -n "$LITESTREAM_SECRET_ACCESS_KEY" ] && [ -n "$REPLICA_URL" ]; then
    echo "✓ Litestream environment variables detected"
    echo "  Litestream will provide continuous backup to: $REPLICA_URL"
    echo ""

    # Restore database from replica if it doesn't exist locally
    if [ ! -f /app/pb_data/data.db ]; then
        echo "Database not found locally. Attempting to restore from replica..."
        litestream restore -if-replica-exists -config /etc/litestream.yml /app/pb_data/data.db

        if [ -f /app/pb_data/data.db ]; then
            echo "✓ Database restored successfully from replica"
        else
            echo "ℹ No replica found. Starting with fresh database."
        fi
    else
        echo "✓ Database found locally"
    fi

    echo ""
    echo "Starting PocketBase with Litestream replication..."
    echo "==================================="

    # Start Litestream with PocketBase as a subprocess
    # This allows Litestream to continuously replicate the database
    exec litestream replicate -config /etc/litestream.yml -exec "/app/pocketbase serve --http=0.0.0.0:8080"

else
    echo "⚠ WARNING: Litestream environment variables not configured"
    echo "  Your database will NOT be backed up!"
    echo ""
    echo "  To enable automatic backups to DigitalOcean Spaces, configure:"
    echo "  - LITESTREAM_ACCESS_KEY_ID"
    echo "  - LITESTREAM_SECRET_ACCESS_KEY"
    echo "  - REPLICA_URL (e.g., s3://your-space.nyc3.digitaloceanspaces.com/pocketbase-db)"
    echo ""
    echo "  See README.md for setup instructions."
    echo ""
    echo "Starting PocketBase WITHOUT backup..."
    echo "==================================="

    # Start PocketBase directly without Litestream
    exec /app/pocketbase serve --http=0.0.0.0:8080
fi
