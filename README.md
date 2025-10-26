# PocketBase on DigitalOcean App Platform

Deploy [PocketBase](https://pocketbase.io) - an open source backend in 1 file - on DigitalOcean App Platform.

## What is PocketBase?

PocketBase is an open source Go backend that includes:
- Embedded database (SQLite) with realtime subscriptions
- Built-in files and users management
- Convenient Admin dashboard UI
- Simple REST-ish API

## Quick Deploy

[![Deploy to DO](https://www.deploytodo.com/do-btn-blue.svg)](https://cloud.digitalocean.com/apps/new?repo=https://github.com/bikram20/pocketbase-appplatform/tree/main)

Click the button above to deploy PocketBase to DigitalOcean App Platform in one click.

## 🚀 Using PocketBase

Once deployed, you need to **use** PocketBase to build applications. Here's how:

### 1. Create Your Admin Account

Visit `https://your-app-url.ondigitalocean.app/_/` and create your first admin account.

**Important**: There's no default admin. You must create one on first visit.

### 2. Try the Example Todo App

We've built a complete working example to show you how to use PocketBase:

```bash
# Download the example
curl -O https://raw.githubusercontent.com/bikram20/pocketbase-appplatform/main/examples/todo-app.html

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

1. Navigate to the Admin UI (`/_/`)
2. Create your admin account
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

For production use, you have two options:

#### Option 1: Wait for NFS Support (Q1 2026)
DigitalOcean App Platform will support persistent volumes via NFS in Q1 2026. Once available, you can mount persistent storage for the SQLite database.

#### Option 2: Migrate to PostgreSQL (Available Now)

PocketBase supports PostgreSQL as a database backend. To use PostgreSQL:

1. **Add a managed database** to your app:
   - In `.do/app.yaml`, uncomment the `databases` section
   - Or add via the DigitalOcean control panel

2. **Update the run command** to use PostgreSQL:
   ```yaml
   run_command: /app/pocketbase serve --http=0.0.0.0:8080 --db.type=postgres --db.conn=${db.DATABASE_URL}
   ```

3. **Redeploy** your app

See `PRODUCTION.md` for detailed production hardening steps.

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

If using SQLite:
- Remember data is ephemeral
- Check you're not exceeding 2GiB storage

If using PostgreSQL:
- Verify `DATABASE_URL` is set correctly
- Check database connectivity from the app

### Performance Issues

- Monitor CPU/memory usage in Insights
- Consider upgrading instance size
- For PostgreSQL, check connection pool settings

## Cost Estimate

### Minimal Setup (SQLite)
- **Service**: $12/month (apps-s-1vcpu-1gb)
- **Total**: ~$12/month

### Production Setup (PostgreSQL)
- **Service**: $12/month (apps-s-1vcpu-1gb)
- **Managed DB**: $15/month (basic PostgreSQL)
- **Total**: ~$27/month

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
