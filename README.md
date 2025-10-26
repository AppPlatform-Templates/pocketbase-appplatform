# PocketBase on DigitalOcean App Platform

Deploy [PocketBase](https://pocketbase.io) - an open source backend in 1 file - on DigitalOcean App Platform.

## What is PocketBase?

PocketBase is an open source Go backend that includes:
- Embedded database (SQLite) with realtime subscriptions
- Built-in files and users management
- Convenient Admin dashboard UI
- Simple REST-ish API

## Quick Deploy

[![Deploy to DO](https://www.deploytodo.com/do-btn-blue.svg)](https://cloud.digitalocean.com/apps/new?repo=https://github.com/AppPlatform-Templates/pocketbase-appplatform/tree/main)

Click the button above to deploy PocketBase to DigitalOcean App Platform in one click.

## 🚀 Using PocketBase

Once deployed, you need to **use** PocketBase to build applications. Here's how:

### 1. Create Your Admin Account

**Important**: The admin UI is not accessible until you create a superuser via the console.

To create your first admin account:

1. In your DigitalOcean dashboard:
   - Go to **Apps**
   - Click on your PocketBase app
   - Click on your service component (e.g., "pocketbase")
   - Click the **Console** tab
   - Click **Run command**

2. Run this command in the console:
   ```bash
   ./pocketbase superuser create your-email@example.com your-password
   ```

3. After creating the superuser, access the admin UI at:
   ```
   https://your-app-url.ondigitalocean.app/_/
   ```

### 2. Try the Example Todo App

We've built a complete working example to show you how to use PocketBase:

```bash
# Download the example
curl -O https://raw.githubusercontent.com/AppPlatform-Templates/pocketbase-appplatform/main/examples/todo-app.html

# Update the PocketBase URL in the file (line 169)
# Then open in browser
open todo-app.html
```

**Features demonstrated**:
- User authentication (sign up, login)
- CRUD operations (create, read, update, delete)
- Realtime updates
- User-specific data

### 3. Build Your Own Application

Follow our comprehensive guide:

**📖 [Complete Usage Guide: USING_POCKETBASE.md](USING_POCKETBASE.md)**

This guide includes:
- Step-by-step setup instructions
- Creating collections (database tables)
- Setting up security rules
- Building a complete Todo app
- User authentication
- Realtime subscriptions
- File uploads
- Code examples (HTML, React)

**📂 [Working Examples: examples/](examples/)**

Download and run ready-to-use example applications.

## Architecture

This deployment uses:
- **Service Component**: PocketBase Go application
- **Instance Size**: apps-s-1vcpu-1gb (1 vCPU, 1GB RAM) - $12/month
- **Region**: NYC (customizable to any DO region)
- **Database**: SQLite (ephemeral) - see production notes below
- **PocketBase Version**: v0.31.0 (pinned for stability)

## Version Information

This deployment is pinned to **PocketBase v0.31.0** for stable, predictable builds.

### Why Version Pinning?

- ✅ **Stable builds**: Won't break if the master branch has issues
- ✅ **Predictable**: Same version every time
- ✅ **Tested**: Version 0.31.0 is a stable release

### Upgrading PocketBase Version

To upgrade to a newer version of PocketBase:

1. **Update the Dockerfile**:
   ```dockerfile
   ARG POCKETBASE_VERSION=v0.32.0  # Change to desired version
   ```

2. **Or override via build args** in `.do/app.yaml`:
   ```yaml
   build_command: docker build --build-arg POCKETBASE_VERSION=v0.32.0 -t $IMAGE_NAME .
   ```

3. **Redeploy** your app

Check [PocketBase releases](https://github.com/pocketbase/pocketbase/releases) for available versions.

## Features

- Admin UI at `/admin`
- REST API at `/api`
- Realtime subscriptions
- File uploads and management
- User authentication and authorization
- JavaScript hooks support (via jsvm plugin)

## Deployment Options

### Option 1: Deploy to DO Button

1. Click the "Deploy to DO" button above
2. Sign in to your DigitalOcean account
3. Review the configuration
4. Click "Deploy"
5. Wait for the build to complete (~5-10 minutes)
6. Access your PocketBase instance at the provided URL

### Option 2: Manual Deployment

1. Fork this repository
2. Go to [DigitalOcean App Platform](https://cloud.digitalocean.com/apps)
3. Click "Create App"
4. Select your forked repository
5. App Platform will auto-detect the Dockerfile
6. Review and deploy

### Option 3: Using doctl CLI

```bash
# Install doctl if you haven't
# https://docs.digitalocean.com/reference/doctl/how-to/install/

# Create app from spec
doctl apps create --spec .do/app.yaml

# Or update existing app
doctl apps update YOUR_APP_ID --spec .do/app.yaml
```

## Configuration

### Environment Variables

The following environment variables can be configured:

| Variable | Default | Description |
|----------|---------|-------------|
| `PB_LOG_LEVEL` | `info` | Log level: `debug`, `info`, `warn`, `error` |

You can add more environment variables in the App Platform dashboard or in the `.do/app.yaml` file.

### Custom Domain

To use a custom domain:

1. Go to your app in the DigitalOcean control panel
2. Navigate to "Settings" → "Domains"
3. Add your custom domain
4. Update your DNS records as instructed

## Accessing PocketBase

Once deployed, you can access:

- **Admin UI**: `https://your-app-url.ondigitalocean.app/_/`
- **API**: `https://your-app-url.ondigitalocean.app/api/`
- **Health Check**: `https://your-app-url.ondigitalocean.app/api/health`

### Initial Setup

1. Create your admin account via the App Platform Console (see "Create Your Admin Account" section above)
2. Navigate to the Admin UI at `/_/`
3. Start creating collections and configuring your backend

## Storage Considerations

### Testing/Development (Current Setup)

- **Storage**: Ephemeral SQLite database
- **Location**: `/app/pb_data/data.db`
- **Limit**: 2GiB total ephemeral storage
- **Warning**: ⚠️ **Data is lost on each deployment**

This setup is ideal for:
- Testing and experimentation
- Development environments
- Demos and proof-of-concepts

### Production (Recommended)

For production use with persistent data, you have two options:

#### Option 1: Use Litestream for SQLite Backup (Available Now)

**Litestream** provides continuous replication of your SQLite database to DigitalOcean Spaces. This template includes built-in Litestream support:

- **Automatic backups**: Continuously replicates your database to object storage
- **Disaster recovery**: Automatically restores from backup on container restart
- **Easy setup**: Just configure environment variables (see Production Setup section below)

**Note**: PocketBase only supports SQLite databases. It does not support PostgreSQL or other database engines.

#### Option 2: Wait for NFS Support (Q1 2026)

DigitalOcean App Platform will support persistent volumes via NFS in Q1 2026. Once available, you can mount persistent storage for the SQLite database directly.

See `PRODUCTION.md` for detailed Litestream setup and production hardening steps.

## Production Setup: Litestream Backup

### What is Litestream?

[Litestream](https://litestream.io) is a streaming replication tool for SQLite databases. It continuously backs up your database to object storage (DigitalOcean Spaces) and can automatically restore it on container restart.

### Why Use Litestream?

- **Automatic Backups**: Continuous replication to DigitalOcean Spaces
- **Disaster Recovery**: Auto-restore database when container restarts
- **Cost-Effective**: ~$5/month for Spaces vs $15/month for managed database
- **Zero Downtime**: Replication happens in the background
- **SQLite Performance**: Keep using fast local SQLite with cloud backup

### Quick Setup

**Step 1: Create a DigitalOcean Space**

1. Go to [DigitalOcean Spaces](https://cloud.digitalocean.com/spaces)
2. Click **Create a Space**
3. Choose a region (e.g., `nyc3`)
4. Name your space (e.g., `my-pocketbase-backups`)
5. Click **Create a Space**

**Step 2: Generate API Keys**

1. Go to [API Tokens](https://cloud.digitalocean.com/account/api/tokens)
2. Scroll to **Spaces access keys**
3. Click **Generate New Key**
4. Name it (e.g., `pocketbase-litestream`)
5. Save the **Access Key** and **Secret Key** (you'll need these)

**Step 3: Configure Environment Variables**

In your App Platform dashboard:

1. Go to your PocketBase app
2. Click **Settings** → **App-Level Environment Variables**
3. Add these three variables:

   | Key | Value | Type |
   |-----|-------|------|
   | `LITESTREAM_ACCESS_KEY_ID` | Your Spaces access key | Secret |
   | `LITESTREAM_SECRET_ACCESS_KEY` | Your Spaces secret key | Secret |
   | `REPLICA_URL` | `s3://YOUR-SPACE-NAME.REGION.digitaloceanspaces.com/pocketbase-db` | Regular |

   Replace:
   - `YOUR-SPACE-NAME` with your actual space name
   - `REGION` with your space region (e.g., `nyc3`)

4. Click **Save** and redeploy your app

**That's it!** Your database is now being backed up continuously to DigitalOcean Spaces.

### Verifying Backups

Check your app logs to confirm Litestream is working:

```bash
doctl apps logs YOUR_APP_ID --type run
```

You should see:
```
✓ Litestream environment variables detected
Starting PocketBase with Litestream replication...
```

You can also check your Space in the DO dashboard - you should see backup files appearing.

### Restoring from Backup

Litestream automatically restores your database when the container starts. If your database is lost (e.g., after redeployment), Litestream will:

1. Detect the missing database
2. Restore it from the latest backup in Spaces
3. Start PocketBase with your data intact

No manual intervention required!

### Cost

- **Spaces Storage**: $5/month for 250 GB + 1 TB transfer
- **Typical Usage**: < 1 GB for most PocketBase databases
- **Total**: ~$5/month for production-grade backups

### Troubleshooting

**Backups not working?**

1. Check environment variables are set correctly
2. Verify your Spaces access key has write permissions
3. Check logs for Litestream errors: `doctl apps logs YOUR_APP_ID --type run`

**Database not restoring?**

1. Ensure `REPLICA_URL` matches your Space name and region
2. Check that backup files exist in your Space
3. Look for restoration logs on container startup

For more details, see `PRODUCTION.md` and the [Litestream documentation](https://litestream.io/guides/digitalocean/).

## Scaling

### Vertical Scaling
Upgrade to larger instance sizes:
- `apps-s-2vcpu-4gb` - 2 vCPU, 4GB RAM - $24/month
- `apps-s-4vcpu-8gb` - 4 vCPU, 8GB RAM - $48/month

### Horizontal Scaling
For dedicated CPU instances, enable autoscaling:
```yaml
instance_count: 1
autoscaling:
  min_instance_count: 1
  max_instance_count: 5
  metrics:
    cpu:
      percent: 80
```

## Monitoring

App Platform provides built-in monitoring:
- **Metrics**: CPU, memory, request rate in the "Insights" tab
- **Logs**: Real-time logs in the "Logs" tab
- **Alerts**: Configure alerts in the "Settings" tab

## Troubleshooting

### Build Fails

Check the build logs in the App Platform console. Common issues:
- Go version mismatch (requires Go 1.23+)
- Build timeout (increase in app spec if needed)

### App Won't Start

Check the runtime logs:
- Verify the port is set to 8080
- Ensure health check endpoint is accessible
- Check environment variables are set correctly

### Database Issues

PocketBase uses SQLite:
- Remember data is ephemeral without Litestream backups
- Check you're not exceeding 2GiB local storage
- If using Litestream, verify environment variables are set correctly
- Check Litestream logs for replication errors

### Performance Issues

- Monitor CPU/memory usage in Insights
- Consider upgrading instance size
- Check Litestream replication is not causing bottlenecks

## Cost Estimate

### Minimal Setup (SQLite without backups)
- **Service**: $12/month (apps-s-1vcpu-1gb)
- **Total**: ~$12/month

### Production Setup (SQLite + Litestream)
- **Service**: $12/month (apps-s-1vcpu-1gb)
- **DigitalOcean Spaces**: $5/month (250 GB storage + 1 TB transfer)
- **Total**: ~$17/month

## Limitations

- **Ephemeral Storage**: Only 2GiB, wiped on each deployment
- **No Persistent Volumes**: Until Q1 2026 NFS support
- **No SSH Access**: App Platform is a managed PaaS
- **Build Timeout**: 1 hour maximum
- **Region**: Must choose from available App Platform regions

## Resources

- [PocketBase Documentation](https://pocketbase.io/docs/)
- [App Platform Documentation](https://docs.digitalocean.com/products/app-platform/)
- [App Platform Pricing](https://www.digitalocean.com/pricing/app-platform)
- [App Spec Reference](https://docs.digitalocean.com/products/app-platform/reference/app-spec/)

## Support

For PocketBase-specific issues:
- [PocketBase GitHub](https://github.com/pocketbase/pocketbase)
- [PocketBase Discussions](https://github.com/pocketbase/pocketbase/discussions)

For App Platform issues:
- [DigitalOcean Support](https://www.digitalocean.com/support/)
- [Community Forums](https://www.digitalocean.com/community/)

## License

PocketBase is licensed under the [MIT License](https://github.com/pocketbase/pocketbase/blob/master/LICENSE.md).
