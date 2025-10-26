# PocketBase on DigitalOcean App Platform - Conversion Summary

## Overview

Successfully converted the PocketBase repository for deployment on DigitalOcean App Platform.

**PocketBase Version**: v0.31.0 (pinned for stable, predictable builds)

## What is PocketBase?

PocketBase is an open source Go backend that includes:
- Embedded SQLite database with realtime subscriptions
- Built-in files and users management
- Admin dashboard UI
- REST-ish API

**GitHub**: https://github.com/pocketbase/pocketbase
**Release**: [v0.31.0](https://github.com/pocketbase/pocketbase/releases/tag/v0.31.0)

## Compatibility Analysis

### ✅ Compatible

- **Language**: Go 1.23+ (fully supported)
- **Architecture**: AMD64 Linux (App Platform native)
- **Build Method**: Static binary compilation via Dockerfile
- **HTTP Server**: Configurable port (set to 8080)
- **Stateless**: Core application is stateless

### ⚠️ Considerations

- **Database**: SQLite is ephemeral on App Platform (data lost on deployment)
- **Storage**: Limited to 2GiB ephemeral storage
- **Production**: Requires PostgreSQL migration for persistent data

### ❌ Blockers

None! PocketBase is fully compatible with App Platform.

## Architecture Mapping

| Component | Type | Configuration | Cost |
|-----------|------|---------------|------|
| PocketBase Service | Service | apps-s-1vcpu-1gb | $12/month |
| Database (optional) | Managed PostgreSQL | db-s-1vcpu-1gb | +$15/month |
| **Total (minimal)** | - | - | **$12/month** |
| **Total (production)** | - | - | **$27/month** |

## Files Created

### Configuration Files

1. **Dockerfile**
   - Multi-stage build
   - Compiles PocketBase from source
   - Creates minimal Alpine-based runtime image
   - Exposes port 8080
   - Includes health check

2. **.do/app.yaml**
   - Complete App Platform specification
   - Service configuration
   - Health check setup
   - Environment variables
   - Optional database configuration (commented)

3. **.do/deploy.template.yaml**
   - Deploy-to-DO button configuration
   - User-customizable parameters
   - Sensible defaults

4. **.dockerignore**
   - Optimizes build performance
   - Excludes unnecessary files

5. **.github/workflows/deploy.yml**
   - Automated CI/CD pipeline
   - Validates app spec
   - Deploys on push to master/main
   - Health check verification

### Documentation Files

1. **README.md**
   - Quick start guide
   - Deployment options
   - Configuration instructions
   - Troubleshooting
   - Cost estimates

2. **PRODUCTION.md**
   - Database migration guide (SQLite → PostgreSQL)
   - Security hardening
   - Performance optimization
   - Backup and recovery
   - Monitoring and alerts
   - High availability setup
   - Production checklist

3. **DEPLOY_BUTTON.md**
   - How to add Deploy-to-DO button
   - Button customization
   - Best practices
   - Troubleshooting

4. **SUMMARY.md** (this file)
   - Overview of the conversion
   - Quick reference

## Deployment Options

### Option 1: Deploy-to-DO Button (Easiest)

```markdown
[![Deploy to DO](https://www.deploytodo.com/do-btn-blue.svg)](https://cloud.digitalocean.com/apps/new?repo=https://github.com/pocketbase/pocketbase/tree/master)
```

**Steps:**
1. Click button
2. Sign in to DigitalOcean
3. Review configuration
4. Deploy
5. Access app at provided URL

**Time to deploy**: ~5-10 minutes

### Option 2: Manual Deployment via UI

1. Go to [DigitalOcean App Platform](https://cloud.digitalocean.com/apps)
2. Click "Create App"
3. Select GitHub repository: `pocketbase/pocketbase`
4. App Platform auto-detects Dockerfile
5. Review and deploy

**Time to deploy**: ~10-15 minutes

### Option 3: CLI Deployment (Advanced)

```bash
# Install doctl
brew install doctl  # macOS
# or download from https://docs.digitalocean.com/reference/doctl/

# Authenticate
doctl auth init

# Create app
doctl apps create --spec .do/app.yaml --wait

# Or update existing app
doctl apps update YOUR_APP_ID --spec .do/app.yaml --wait
```

**Time to deploy**: ~5-10 minutes

### Option 4: GitHub Actions (CI/CD)

1. Add secrets to GitHub repository:
   - `DIGITALOCEAN_ACCESS_TOKEN`
   - `DO_APP_ID` (after first deployment)

2. Push to master/main branch
3. GitHub Actions automatically deploys

**Time to deploy**: Automatic on every push

## Testing the Deployment

### 1. Access the Application

After deployment:
- **App URL**: `https://your-app-name.ondigitalocean.app`
- **Admin UI**: `https://your-app-name.ondigitalocean.app/_/`
- **API**: `https://your-app-name.ondigitalocean.app/api/`
- **Health Check**: `https://your-app-name.ondigitalocean.app/api/health`

### 2. Create Admin Account

1. Navigate to Admin UI (`/_/`)
2. Create your first admin account
3. Log in

### 3. Test API

```bash
# Health check
curl https://your-app-name.ondigitalocean.app/api/health

# List collections (after creating admin)
curl -H "Authorization: Bearer YOUR_TOKEN" \
  https://your-app-name.ondigitalocean.app/api/collections
```

### 4. Verify Functionality

- [ ] Admin UI accessible
- [ ] Can create collections
- [ ] Can create records
- [ ] API endpoints working
- [ ] File uploads working (ephemeral)
- [ ] Realtime subscriptions working

## Storage Considerations

### Testing/Development (Current Setup)

✅ **What Works:**
- Full PocketBase functionality
- Admin UI
- API operations
- File uploads (up to 2GiB total)
- Testing and demos

⚠️ **Limitations:**
- **Data is ephemeral** (lost on every deployment)
- 2GiB total storage limit
- Not suitable for production

### Production (Recommended)

Two paths:

#### Path 1: PostgreSQL Migration (Available Now)

**Pros:**
- Persistent data
- Scalable
- Production-ready
- High availability options

**Cons:**
- Additional cost (+$15/month)
- Requires migration from SQLite

**Setup:**
1. Uncomment database section in `.do/app.yaml`
2. Update run command to use PostgreSQL
3. Migrate data
4. Redeploy

See `PRODUCTION.md` for detailed steps.

#### Path 2: Wait for NFS Support (Q1 2026)

**Pros:**
- Keep using SQLite
- Simple setup
- Persistent storage

**Cons:**
- Not available yet
- Still 2GiB SQLite limitations for large datasets

## Environment Variables

| Variable | Default | Description | Required |
|----------|---------|-------------|----------|
| `PB_LOG_LEVEL` | `info` | Log level (debug, info, warn, error) | No |
| `DATABASE_URL` | - | PostgreSQL connection string (if using PG) | No |
| `REDIS_URL` | - | Redis connection string (if using Redis) | No |

Add more via App Platform dashboard or `.do/app.yaml`.

## Scaling

### Vertical Scaling

Upgrade instance size:

| Instance | vCPU | RAM | Cost/month |
|----------|------|-----|------------|
| apps-s-1vcpu-1gb | 1 | 1GB | $12 |
| apps-s-2vcpu-4gb | 2 | 4GB | $24 |
| apps-s-4vcpu-8gb | 4 | 8GB | $48 |
| apps-d-2vcpu-4gb | 2 | 4GB | $48 (dedicated) |

### Horizontal Scaling

For dedicated instances, enable autoscaling:

```yaml
autoscaling:
  min_instance_count: 2
  max_instance_count: 10
  metrics:
    cpu:
      percent: 75
```

### Database Scaling

Resize managed database:

```bash
doctl databases resize YOUR_DB_ID --size db-s-2vcpu-4gb --num-nodes 2
```

## Security Checklist

For production deployments:

- [ ] Migrate to PostgreSQL
- [ ] Enable database trusted sources / VPC
- [ ] Configure CORS properly
- [ ] Use strong admin passwords
- [ ] Enable 2FA for admin accounts
- [ ] Set up rate limiting
- [ ] Configure security headers
- [ ] Use custom domain with HTTPS
- [ ] Set up monitoring and alerts
- [ ] Regular backups
- [ ] Document recovery procedures

See `PRODUCTION.md` for detailed security hardening.

## Cost Breakdown

### Minimal Setup (Testing)

| Component | Configuration | Cost |
|-----------|--------------|------|
| Service | apps-s-1vcpu-1gb | $12/month |
| **Total** | | **$12/month** |

**Billed by the second** (minimum 1 minute)

### Production Setup

| Component | Configuration | Cost |
|-----------|--------------|------|
| Service | apps-s-1vcpu-1gb | $12/month |
| Database | PostgreSQL basic | $15/month |
| **Total** | | **$27/month** |

**Database billed by the hour** (minimum 1 hour)

### High Availability Setup

| Component | Configuration | Cost |
|-----------|--------------|------|
| Service | apps-d-2vcpu-4gb × 3 | $144/month |
| Database | PostgreSQL + standby | $30/month |
| Redis | Cache layer | $15/month |
| **Total** | | **$189/month** |

## Limitations

App Platform constraints:

1. **Storage**: 2GiB ephemeral only (until NFS in Q1 2026)
2. **Build timeout**: 1 hour maximum
3. **Architecture**: AMD64 only (no ARM)
4. **Networking**: No SSH/SFTP direct access
5. **Regions**: Limited to App Platform regions

PocketBase-specific:

1. **SQLite**: Ephemeral on App Platform
2. **File uploads**: Limited to 2GiB total (use Spaces for production)
3. **Migrations**: Manual for SQLite → PostgreSQL

## Troubleshooting

### Build Fails

- Check Go version (requires 1.23+)
- Verify Dockerfile syntax
- Check build logs in console

### App Won't Start

- Verify port 8080 is configured
- Check health check endpoint
- Review runtime logs

### Data Lost After Deployment

- Expected behavior with SQLite
- Migrate to PostgreSQL for persistence

### Performance Issues

- Monitor CPU/memory in Insights
- Consider scaling up
- Add caching layer (Redis)

## Next Steps

1. **Deploy the app**:
   - Use Deploy-to-DO button OR
   - Manual deployment via UI OR
   - CLI deployment with doctl

2. **Test functionality**:
   - Access Admin UI
   - Create test collections
   - Test API endpoints

3. **For production**:
   - Read `PRODUCTION.md`
   - Migrate to PostgreSQL
   - Implement security hardening
   - Set up monitoring
   - Configure backups

4. **Optional enhancements**:
   - Add custom domain
   - Configure CORS for frontend
   - Set up CI/CD with GitHub Actions
   - Add caching layer (Redis)
   - Implement rate limiting

## Resources

### Documentation

- [README.md](README.md) - Quick start and deployment
- [PRODUCTION.md](PRODUCTION.md) - Production hardening guide
- [DEPLOY_BUTTON.md](DEPLOY_BUTTON.md) - Deploy button setup

### External Resources

- [PocketBase Documentation](https://pocketbase.io/docs/)
- [App Platform Documentation](https://docs.digitalocean.com/products/app-platform/)
- [App Spec Reference](https://docs.digitalocean.com/products/app-platform/reference/app-spec/)
- [App Platform Pricing](https://www.digitalocean.com/pricing/app-platform)

### Support

- [DigitalOcean Community](https://www.digitalocean.com/community/)
- [PocketBase Discussions](https://github.com/pocketbase/pocketbase/discussions)
- [App Platform Tutorials](https://www.digitalocean.com/community/tags/app-platform)

## Contributing

To improve this deployment:

1. Fork the repository
2. Make your changes
3. Test thoroughly
4. Submit pull request
5. Update documentation

## License

PocketBase is licensed under the [MIT License](https://github.com/pocketbase/pocketbase/blob/master/LICENSE.md).

This deployment configuration is provided as-is for use with PocketBase on DigitalOcean App Platform.

---

**Conversion completed**: Successfully converted PocketBase for DigitalOcean App Platform deployment with full documentation and production guidance.
