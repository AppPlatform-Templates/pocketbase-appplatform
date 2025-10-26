# Production Deployment Guide

This guide covers best practices for running PocketBase on DigitalOcean App Platform in production.

## Table of Contents

- [Database Migration](#database-migration)
- [Security Hardening](#security-hardening)
- [Performance Optimization](#performance-optimization)
- [Backup and Recovery](#backup-and-recovery)
- [Monitoring and Alerts](#monitoring-and-alerts)
- [High Availability](#high-availability)

## Database Backup Strategy

### The Challenge: Ephemeral Storage

The default deployment uses ephemeral SQLite storage, which means:
- ⚠️ **Data is lost on every deployment**
- Limited to 2GiB total storage
- Not suitable for production workloads without backups

**Important**: PocketBase only supports SQLite databases. It does NOT support PostgreSQL or other database engines.

### Recommended Solution: Litestream Backup

This template includes built-in Litestream support for continuous SQLite backup to DigitalOcean Spaces.

#### What is Litestream?

Litestream provides:
- **Continuous replication** of SQLite to object storage
- **Automatic restoration** on container restart
- **Point-in-time recovery** capabilities
- **Minimal performance impact** (async replication)

#### Step 1: Create DigitalOcean Space

1. Go to [DigitalOcean Spaces](https://cloud.digitalocean.com/spaces)
2. Click **Create a Space**
3. Choose your region (match your app region for best performance)
4. Name your space (e.g., `pocketbase-backups`)
5. Keep default settings (CDN not required for backups)

#### Step 2: Generate API Credentials

1. Go to [API Tokens](https://cloud.digitalocean.com/account/api/tokens)
2. Scroll to **Spaces access keys**
3. Click **Generate New Key**
4. Name it: `pocketbase-litestream`
5. **Save the keys** (you won't see the secret again):
   - Access Key ID
   - Secret Access Key

#### Step 3: Configure Environment Variables

In `.do/app.yaml`, uncomment and configure these variables:

```yaml
envs:
  - key: LITESTREAM_ACCESS_KEY_ID
    value: "your-spaces-access-key-id"
    scope: RUN_TIME
    type: SECRET

  - key: LITESTREAM_SECRET_ACCESS_KEY
    value: "your-spaces-secret-access-key"
    scope: RUN_TIME
    type: SECRET

  - key: REPLICA_URL
    value: "s3://your-space-name.nyc3.digitaloceanspaces.com/pocketbase-db"
    scope: RUN_TIME
```

Or configure via the App Platform dashboard:
- **Settings** → **App-Level Environment Variables**
- Add the three variables above
- Mark the keys as **Secret**

#### Step 4: Deploy

```bash
doctl apps update YOUR_APP_ID --spec .do/app.yaml
```

The app will automatically:
1. Start Litestream replication
2. Continuously backup your database to Spaces
3. Restore from backup on container restart

#### Step 5: Verify Backup is Working

Check logs to confirm Litestream is running:

```bash
doctl apps logs YOUR_APP_ID --type run
```

You should see:
```
✓ Litestream environment variables detected
Starting PocketBase with Litestream replication...
```

Check your Space - you should see backup files appearing:
- `generations/` directory with snapshot files
- WAL (Write-Ahead Log) files

### Alternative: Wait for NFS Support (Q1 2026)

DigitalOcean is adding NFS persistent volume support in Q1 2026. Once available, you can mount persistent storage for SQLite directly.

Expected configuration:

```yaml
services:
  - name: pocketbase
    volumes:
      - name: pocketbase-data
        mount_path: /app/pb_data
        size: 10GB  # Adjust as needed
```

## Security Hardening

### 1. Backup Security

#### Secure Your Spaces Access Keys

Protect your Litestream backup credentials:

```yaml
envs:
  - key: LITESTREAM_ACCESS_KEY_ID
    scope: RUN_TIME
    type: SECRET  # Encrypted at rest

  - key: LITESTREAM_SECRET_ACCESS_KEY
    scope: RUN_TIME
    type: SECRET  # Encrypted at rest
```

#### Restrict Space Access

Configure your DigitalOcean Space:
1. Set Space to **Private** (not public)
2. Use **Spaces access keys** with minimal permissions
3. Consider enabling **Space versioning** for backup recovery
4. Rotate access keys periodically

#### Enable Space File Listing Restrictions

Prevent unauthorized access to backup files:
```bash
# Set Space to private (via DO dashboard)
# Settings → Manage Files → File Listing: Restricted
```

### 2. Application Security

#### Enable HTTPS Only

App Platform provides automatic HTTPS, but enforce it in your app:

```yaml
envs:
  - key: PB_ENCRYPTION_COOKIE_SECURE
    value: "true"
    scope: RUN_TIME
```

#### Configure CORS

If your frontend is on a different domain:

```yaml
cors:
  allow_origins:
    - exact: https://yourdomain.com
  allow_methods:
    - GET
    - POST
    - PUT
    - PATCH
    - DELETE
    - OPTIONS
  allow_headers:
    - Authorization
    - Content-Type
  allow_credentials: true
```

#### Set Security Headers

Add environment variables for security:

```yaml
envs:
  - key: PB_LOG_LEVEL
    value: "warn"  # Reduce log verbosity in production

  - key: PB_ENCRYPTION_ENV
    value: ${SECRET_KEY}  # Use encrypted env vars
    scope: RUN_TIME
    type: SECRET
```

### 3. Admin Access

#### Change Default Admin Port

By default, admin UI is at `/_/`. Consider using a non-standard path:

```yaml
envs:
  - key: PB_ADMIN_PATH
    value: "/secure-admin-path-${RANDOM_STRING}"
    scope: RUN_TIME
    type: SECRET
```

#### Enable 2FA

Configure two-factor authentication for admin accounts via PocketBase settings.

### 4. Rate Limiting

App Platform provides DDoS protection, but add application-level rate limiting:

```javascript
// In PocketBase hooks (pb_hooks/main.js)
onRequest((e) => {
  const rateLimiter = new RateLimiter({
    max: 100,  // requests
    duration: 60  // seconds
  })

  if (!rateLimiter.allow(e.request.clientIP())) {
    throw new TooManyRequestsError("Rate limit exceeded")
  }
})
```

## Performance Optimization

### 1. Instance Sizing

Start conservatively and scale based on metrics:

| Traffic | Instance Size | Monthly Cost |
|---------|--------------|--------------|
| < 10K req/day | apps-s-1vcpu-1gb | $12 |
| 10K-100K req/day | apps-s-2vcpu-4gb | $24 |
| 100K-1M req/day | apps-d-2vcpu-4gb | $48 |
| > 1M req/day | apps-d-4vcpu-8gb + autoscaling | $96+ |

### 2. Database Optimization

#### SQLite Performance Tuning

PocketBase uses SQLite, which is already highly optimized. However, you can improve performance:

1. **Monitor Database Size**: Keep under 2GiB local storage limit
   ```bash
   # Check database size in logs
   doctl apps logs YOUR_APP_ID --type run | grep "pb_data"
   ```

2. **Regular Maintenance**: PocketBase handles SQLite optimization automatically via:
   - WAL mode (enabled by default)
   - Auto-vacuum
   - Index optimization

3. **Litestream Impact**: Minimal performance overhead (< 5%)
   - Async replication doesn't block writes
   - Configurable sync interval (default: 1s)

#### Optimize Litestream Configuration

Adjust replication frequency in `litestream.yml`:

```yaml
dbs:
  - path: /app/pb_data/data.db
    replicas:
      - url: ${REPLICA_URL}
        sync-interval: 10s  # Increase for less frequent sync (lower overhead)
        snapshot-interval: 24h  # Daily snapshots
```

Trade-off: Longer sync intervals = better performance, but more data at risk if container crashes

### 3. Caching

#### Enable Redis for Sessions

Add Redis for session storage and caching:

```yaml
databases:
  - name: cache
    engine: REDIS
    version: "7"
    production: true
    size: db-s-1vcpu-1gb

services:
  - name: pocketbase
    envs:
      - key: REDIS_URL
        value: ${cache.REDIS_URL}
```

### 4. CDN for Static Assets

If serving static files, use DigitalOcean Spaces CDN:

1. Create a Space for uploads
2. Configure PocketBase to use S3-compatible storage
3. Enable Spaces CDN

```yaml
envs:
  - key: S3_ENDPOINT
    value: "https://nyc3.digitaloceanspaces.com"
  - key: S3_BUCKET
    value: "your-bucket-name"
  - key: S3_ACCESS_KEY
    value: ${SPACES_KEY}
    type: SECRET
  - key: S3_SECRET_KEY
    value: ${SPACES_SECRET}
    type: SECRET
```

### 5. Autoscaling

For dedicated instances, enable autoscaling:

```yaml
services:
  - name: pocketbase
    instance_size_slug: apps-d-2vcpu-4gb
    instance_count: 2
    autoscaling:
      min_instance_count: 2
      max_instance_count: 10
      metrics:
        cpu:
          percent: 75
```

## Backup and Recovery

### 1. Litestream Automatic Backups

#### How Litestream Backups Work

Litestream provides continuous, automatic backups:

- **Real-time replication**: Changes are backed up within 1-10 seconds
- **Snapshots**: Full database snapshots taken daily (configurable)
- **WAL files**: Write-Ahead Log files for point-in-time recovery
- **Retention**: 7 days by default (configurable)

#### Backup Verification

Verify backups are working:

```bash
# Check app logs for Litestream status
doctl apps logs YOUR_APP_ID --type run | grep -i litestream

# List backup files in your Space (using AWS CLI with DO Spaces)
aws s3 ls s3://your-space-name/pocketbase-db/ \
  --endpoint-url https://nyc3.digitaloceanspaces.com
```

You should see:
- `generations/` directory
- Multiple WAL files
- Regular snapshot files

#### Manual Verification Restore

Test restoration locally:

```bash
# Install Litestream locally
brew install litestream  # macOS
# or download from https://litestream.io

# Restore to local file
litestream restore \
  -o ./test-restore.db \
  s3://your-space-name.nyc3.digitaloceanspaces.com/pocketbase-db

# Verify the database
sqlite3 ./test-restore.db "SELECT count(*) FROM _collections;"
```

### 2. Disaster Recovery Plan

1. **Regular Testing**: Test backup restoration quarterly
2. **Documentation**: Document recovery procedures
3. **RTO/RPO**: Define recovery time and point objectives
4. **Monitoring**: Alert on backup failures

### 3. Additional Backup Strategies

#### Configure Backup Retention

Adjust retention in `litestream.yml`:

```yaml
dbs:
  - path: /app/pb_data/data.db
    replicas:
      - url: ${REPLICA_URL}
        retention: 720h  # 30 days (default: 168h = 7 days)
        snapshot-interval: 24h  # Daily snapshots
```

#### Point-in-Time Recovery

Restore to a specific timestamp:

```bash
# Restore to specific time
litestream restore \
  -o ./restored.db \
  -timestamp 2024-01-15T10:30:00Z \
  s3://your-space-name.nyc3.digitaloceanspaces.com/pocketbase-db
```

#### File Storage Backups

If using PocketBase file uploads, they're stored in `/app/pb_data/storage/`. These are included in Litestream backups if you configure it to replicate the entire `pb_data` directory.

For additional file backup, consider using DigitalOcean Spaces:
- Configure PocketBase to use Spaces for file storage (S3-compatible)
- Enable versioning on your Spaces bucket for file recovery

## Monitoring and Alerts

### 1. Built-in Monitoring

Use App Platform's Insights tab:
- CPU usage
- Memory usage
- Request rate
- Response time
- Error rate

### 2. Custom Alerts

Set up alerts for critical metrics:

```bash
# Via doctl
doctl apps alert-destinations create \
  --type slack \
  --slack-url https://hooks.slack.com/...

doctl apps alerts create YOUR_APP_ID \
  --metric cpu \
  --operator GREATER_THAN \
  --threshold 80 \
  --window 5m
```

### 3. Application Logging

Structured logging in PocketBase:

```yaml
envs:
  - key: PB_LOG_LEVEL
    value: "warn"  # Production: warn, error only
  - key: PB_LOG_FORMAT
    value: "json"  # Structured logs for parsing
```

### 4. External Monitoring

Consider external monitoring services:
- **Uptime monitoring**: Pingdom, UptimeRobot
- **APM**: New Relic, Datadog
- **Error tracking**: Sentry

## High Availability

### Important: SQLite Limitations

**PocketBase uses SQLite**, which has different HA characteristics than traditional databases:

- ✅ **Single-writer**: SQLite handles one writer at a time
- ❌ **No multi-node clustering**: Cannot run multiple SQLite instances sharing the same file
- ✅ **Litestream backup**: Provides disaster recovery, not active-active HA

### 1. Multiple App Instances (Limited)

**⚠️ Warning**: Running multiple PocketBase instances can cause issues with SQLite:

```yaml
# NOT RECOMMENDED for SQLite
services:
  - name: pocketbase
    instance_count: 1  # Keep at 1 for SQLite
```

**Why?** Multiple instances would try to write to separate SQLite files (ephemeral storage is per-container), leading to data inconsistency.

**Solution**: Use single instance with vertical scaling + Litestream backup for DR.

### 2. Vertical Scaling

Scale up a single instance for better performance:

```yaml
services:
  - name: pocketbase
    instance_size_slug: apps-s-4vcpu-8gb  # Larger instance
    instance_count: 1  # Single instance for SQLite
```

### 3. Disaster Recovery with Litestream

Achieve HA through rapid recovery:

1. **Automatic restoration**: Container restart triggers DB restore from Spaces
2. **Fast recovery**: Typically < 30 seconds for small DBs
3. **Minimal data loss**: RPO of 1-10 seconds (sync interval)

### 4. Future: NFS for Multi-Instance (Q1 2026)

Once NFS support arrives, you can run multiple instances sharing persistent SQLite:

```yaml
services:
  - name: pocketbase
    instance_count: 3  # Multiple instances
    volumes:
      - name: shared-db
        mount_path: /app/pb_data
        size: 10GB
```

**Note**: Even with NFS, SQLite's single-writer limitation applies. Use PocketBase's built-in locking.

### 5. Multi-Region (Advanced)

For global HA with SQLite:
1. Deploy separate PocketBase instances per region
2. Use GeoDNS for routing users to nearest region
3. Implement application-level data sync (custom solution)
4. Accept eventual consistency between regions

## Checklist

Before going to production:

**Database & Backups:**
- [ ] Configured Litestream with DigitalOcean Spaces
- [ ] Set up Spaces access keys as encrypted secrets
- [ ] Verified backups are working (check logs and Space)
- [ ] Tested database restoration from backup
- [ ] Configured backup retention policy (7-30 days)
- [ ] Set Space to private access

**Security:**
- [ ] Set up HTTPS with custom domain
- [ ] Configured CORS properly for your frontend domain
- [ ] Created admin account via console
- [ ] Enabled 2FA for admin accounts (in PocketBase UI)
- [ ] Set appropriate log levels (warn/error for production)
- [ ] Configured rate limiting in PocketBase hooks
- [ ] Reviewed and locked down API access rules

**Performance & Scaling:**
- [ ] Sized instance based on expected load
- [ ] Kept instance_count at 1 (SQLite limitation)
- [ ] Configured Litestream sync-interval for your use case
- [ ] Load tested the application
- [ ] Monitored database size (< 2GiB limit)

**Monitoring & Operations:**
- [ ] Set up monitoring and alerts (CPU, memory, errors)
- [ ] Set up external uptime monitoring
- [ ] Documented backup and recovery procedures
- [ ] Documented admin access procedures
- [ ] Created disaster recovery plan
- [ ] Tested container restart recovery (Litestream restore)

## Cost Optimization

### Right-Sizing

Start small and scale based on metrics:
```bash
# Monitor usage
doctl apps list-metrics YOUR_APP_ID

# Scale when needed, not preemptively
```

### Reserved Instances

For stable workloads, consider reserved capacity (contact DO sales).

### Cleanup

Remove unused resources:
```bash
# List all apps
doctl apps list

# Delete unused apps
doctl apps delete OLD_APP_ID
```

## Support

For production support:
- [DigitalOcean Support](https://www.digitalocean.com/support/) - 24/7 for Business/Professional plans
- [Status Page](https://status.digitalocean.com/) - Platform status
- [Community](https://www.digitalocean.com/community/) - Community support

## Additional Resources

- [App Platform Best Practices](https://docs.digitalocean.com/products/app-platform/best-practices/)
- [Database Best Practices](https://docs.digitalocean.com/products/databases/best-practices/)
- [Security Best Practices](https://docs.digitalocean.com/products/security/)
- [PocketBase Production Guide](https://pocketbase.io/docs/going-to-production/)
