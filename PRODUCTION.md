# Production Deployment Guide

This guide covers best practices for running PocketBase on DigitalOcean App Platform in production.

## Table of Contents

- [Database Migration](#database-migration)
- [Security Hardening](#security-hardening)
- [Performance Optimization](#performance-optimization)
- [Backup and Recovery](#backup-and-recovery)
- [Monitoring and Alerts](#monitoring-and-alerts)
- [High Availability](#high-availability)

## Database Migration

### Why Migrate from SQLite?

The default deployment uses ephemeral SQLite storage, which means:
- ⚠️ **Data is lost on every deployment**
- Limited to 2GiB total storage
- Not suitable for production workloads

### Option 1: Migrate to PostgreSQL (Recommended)

#### Step 1: Add Managed Database

Update `.do/app.yaml` to include a managed PostgreSQL database:

```yaml
databases:
  - name: db
    engine: PG
    version: "16"
    production: true  # Set to true for production features
    cluster_name: pocketbase-prod-db
    db_name: pocketbase
    db_user: pocketbase
    num_nodes: 1  # Increase for HA
    size: db-s-1vcpu-1gb  # Start small, scale as needed
```

#### Step 2: Update Service Configuration

Modify the service run command to use PostgreSQL:

```yaml
services:
  - name: pocketbase
    run_command: |
      /app/pocketbase serve \
        --http=0.0.0.0:8080 \
        --db.type=postgres \
        --db.conn=${db.DATABASE_URL}

    envs:
      - key: DATABASE_URL
        value: ${db.DATABASE_URL}
        scope: RUN_TIME
```

#### Step 3: Data Migration

If you have existing SQLite data:

1. **Export from SQLite** (run locally or in a one-off job):
   ```bash
   # PocketBase has built-in export functionality
   ./pocketbase export
   ```

2. **Import to PostgreSQL**:
   ```bash
   # After deploying with PostgreSQL
   ./pocketbase import <exported-data>
   ```

#### Step 4: Deploy

```bash
doctl apps update YOUR_APP_ID --spec .do/app.yaml
```

### Option 2: Wait for NFS Support (Q1 2026)

DigitalOcean is adding NFS persistent volume support in Q1 2026. This will allow you to mount persistent storage for SQLite.

Once available, update your app spec:

```yaml
services:
  - name: pocketbase
    volumes:
      - name: pocketbase-data
        mount_path: /app/pb_data
        size: 10GB  # Adjust as needed
```

## Security Hardening

### 1. Database Security

#### Enable Trusted Sources

For managed databases, restrict access to your app only:

```bash
# Get your app's trusted source
doctl apps list
doctl databases firewalls add YOUR_DB_ID --rule "type:app uuid:YOUR_APP_ID"

# Remove public access
doctl databases firewalls remove YOUR_DB_ID --rule "type:public_ip"
```

Or use VPC networking for complete isolation.

#### Use Strong Passwords

If using database authentication:
```yaml
envs:
  - key: DB_PASSWORD
    value: ${db.PASSWORD}
    scope: RUN_TIME
    type: SECRET  # Encrypted at rest
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

#### Connection Pooling

For PostgreSQL, enable connection pooling:

```yaml
databases:
  - name: db
    engine: PG
    production: true
    connection_pools:
      - name: pool
        mode: transaction
        size: 25  # Adjust based on load
        db_name: pocketbase
        user: pocketbase
```

Use the pool connection string:
```yaml
envs:
  - key: DATABASE_URL
    value: ${db.pool.DATABASE_URL}
```

#### Database Size

Monitor and scale your database:

```bash
# Check current size
doctl databases db get YOUR_DB_ID

# Resize if needed
doctl databases resize YOUR_DB_ID --size db-s-2vcpu-4gb
```

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

### 1. Database Backups

#### Managed Database Backups

Managed databases include automatic backups:
- Daily backups retained for 7 days (can extend to 30 days)
- Point-in-time recovery available

Enable extended retention:
```bash
doctl databases backups list YOUR_DB_ID
```

#### Manual Backups

Schedule periodic exports:

```yaml
jobs:
  - name: backup
    kind: CRON
    schedule: "0 2 * * *"  # Daily at 2 AM
    run_command: |
      /app/pocketbase export /tmp/backup && \
      aws s3 cp /tmp/backup s3://your-backup-bucket/$(date +%Y%m%d).tar.gz
    envs:
      - key: AWS_ACCESS_KEY_ID
        value: ${BACKUP_KEY}
        type: SECRET
      - key: AWS_SECRET_ACCESS_KEY
        value: ${BACKUP_SECRET}
        type: SECRET
```

### 2. Disaster Recovery Plan

1. **Regular Testing**: Test backup restoration quarterly
2. **Documentation**: Document recovery procedures
3. **RTO/RPO**: Define recovery time and point objectives
4. **Monitoring**: Alert on backup failures

### 3. File Storage Backups

If using Spaces for file uploads, enable versioning:

```bash
# Enable versioning on your Spaces bucket
aws s3api put-bucket-versioning \
  --bucket your-bucket-name \
  --versioning-configuration Status=Enabled \
  --endpoint-url https://nyc3.digitaloceanspaces.com
```

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

### 1. Multi-Node Database

For critical workloads:

```yaml
databases:
  - name: db
    engine: PG
    production: true
    num_nodes: 2  # Primary + standby
    size: db-s-2vcpu-4gb
```

### 2. Multiple App Instances

Run multiple instances with a load balancer:

```yaml
services:
  - name: pocketbase
    instance_count: 3  # Spread across availability zones
```

### 3. Read Replicas

For read-heavy workloads:

```yaml
databases:
  - name: db
    num_nodes: 3  # 1 primary + 2 read replicas
```

Configure PocketBase to use read replicas for queries.

### 4. Multi-Region (Advanced)

For global availability:
1. Deploy apps in multiple regions
2. Use GeoDNS for routing
3. Replicate data across regions
4. Handle conflict resolution

## Checklist

Before going to production:

- [ ] Migrated from SQLite to PostgreSQL
- [ ] Enabled database backups (7+ day retention)
- [ ] Configured trusted sources / VPC for database
- [ ] Set up HTTPS with custom domain
- [ ] Configured CORS properly
- [ ] Changed default admin path
- [ ] Enabled 2FA for admin accounts
- [ ] Set appropriate log levels
- [ ] Sized instances based on expected load
- [ ] Configured autoscaling (if using dedicated instances)
- [ ] Set up monitoring and alerts
- [ ] Tested backup and recovery procedures
- [ ] Documented runbooks and procedures
- [ ] Load tested the application
- [ ] Configured rate limiting
- [ ] Set up external monitoring
- [ ] Created disaster recovery plan

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
