# Adding a Deploy to DigitalOcean Button

This guide explains how to add a "Deploy to DigitalOcean" button to the PocketBase repository (or your fork).

## What is the Deploy to DO Button?

The Deploy to DO button allows users to deploy your application to DigitalOcean App Platform with a single click. It's perfect for:
- Open source projects
- Demo applications
- Templates and starters
- Making your app accessible to non-technical users

## Button Example

[![Deploy to DO](https://www.deploytodo.com/do-btn-blue.svg)](https://cloud.digitalocean.com/apps/new?repo=https://github.com/pocketbase/pocketbase/tree/master)

## Prerequisites

- Public GitHub repository
- Valid `.do/deploy.template.yaml` file in your repo
- Dockerfile or buildpack-compatible application

## Step 1: Ensure Configuration Files Exist

Your repository must have:

```
your-repo/
├── Dockerfile                      # Build configuration
├── .do/
│   ├── app.yaml                   # App Platform spec (reference)
│   └── deploy.template.yaml       # Deploy button configuration
└── README.md                       # Documentation
```

These files are already created in this directory.

## Step 2: Add the Button to Your README

### Markdown Syntax

```markdown
[![Deploy to DO](https://www.deploytodo.com/do-btn-blue.svg)](https://cloud.digitalocean.com/apps/new?repo=https://github.com/YOUR_USERNAME/YOUR_REPO/tree/BRANCH)
```

Replace:
- `YOUR_USERNAME` with your GitHub username or org
- `YOUR_REPO` with your repository name
- `BRANCH` with the branch to deploy (usually `main` or `master`)

### For PocketBase

```markdown
[![Deploy to DO](https://www.deploytodo.com/do-btn-blue.svg)](https://cloud.digitalocean.com/apps/new?repo=https://github.com/pocketbase/pocketbase/tree/master)
```

### HTML Syntax (Alternative)

```html
<a href="https://cloud.digitalocean.com/apps/new?repo=https://github.com/YOUR_USERNAME/YOUR_REPO/tree/BRANCH">
  <img src="https://www.deploytodo.com/do-btn-blue.svg" alt="Deploy to DO">
</a>
```

## Step 3: Test the Button

1. **Push your changes** to GitHub:
   ```bash
   git add .do/deploy.template.yaml Dockerfile
   git commit -m "Add DigitalOcean App Platform deployment support"
   git push origin master
   ```

2. **Click the button** in your README (you may need to refresh)

3. **Verify the deployment**:
   - You should be redirected to DigitalOcean
   - The app configuration should be pre-populated
   - You should see your app spec loaded from `deploy.template.yaml`

## Step 4: Customize the Deployment Experience

### Basic Configuration

The `.do/deploy.template.yaml` file controls what users see:

```yaml
spec:
  name: pocketbase  # Default app name (user can change)
  region: nyc       # Default region (user can change)

  services:
    - name: pocketbase
      # ... service configuration
```

### Environment Variables

Allow users to customize environment variables:

```yaml
envs:
  - key: PB_LOG_LEVEL
    value: "info"
    scope: RUN_TIME
    type: GENERAL  # GENERAL, SECRET, or DEFAULT

  - key: ADMIN_EMAIL
    value: ""  # Empty = user must provide
    scope: RUN_TIME
    type: GENERAL
```

### Optional Components

Users can enable optional components during deployment:

```yaml
# Commented out = optional, user can uncomment in UI
# databases:
#   - engine: PG
#     name: db
#     production: false
#     version: "16"
```

### Multiple Regions

Suggest the best region:

```yaml
spec:
  name: pocketbase
  region: nyc  # Default, but user can select any region
```

## Advanced: Multiple Deployment Options

### Option 1: Different Branches

Offer different configurations via branches:

- `master` - Production-ready with PostgreSQL
- `dev` - Development with SQLite
- `minimal` - Bare minimum configuration

Each branch has its own deploy button:

```markdown
Production: [![Deploy to DO](https://www.deploytodo.com/do-btn-blue.svg)](https://cloud.digitalocean.com/apps/new?repo=https://github.com/YOUR_USERNAME/YOUR_REPO/tree/master)

Development: [![Deploy to DO](https://www.deploytodo.com/do-btn-blue.svg)](https://cloud.digitalocean.com/apps/new?repo=https://github.com/YOUR_USERNAME/YOUR_REPO/tree/dev)
```

### Option 2: Multiple Templates

Create different template files:

```
.do/
├── deploy.template.yaml           # Default
├── deploy.template.postgres.yaml  # With PostgreSQL
└── deploy.template.minimal.yaml   # Minimal setup
```

Reference specific templates in URL:
```
https://cloud.digitalocean.com/apps/new?repo=https://github.com/YOUR_USERNAME/YOUR_REPO/tree/master&template=.do/deploy.template.postgres.yaml
```

## Button Variants

### Blue Button (Default)
```markdown
![Deploy to DO](https://www.deploytodo.com/do-btn-blue.svg)
```
[![Deploy to DO](https://www.deploytodo.com/do-btn-blue.svg)](https://cloud.digitalocean.com/apps/new)

### White Button
```markdown
![Deploy to DO](https://www.deploytodo.com/do-btn-white.svg)
```

### Blue Outline Button
```markdown
![Deploy to DO](https://www.deploytodo.com/do-btn-blue-border.svg)
```

## Best Practices

### 1. Clear Documentation

Add deployment instructions to your README:

```markdown
## Quick Deploy

[![Deploy to DO](https://www.deploytodo.com/do-btn-blue.svg)](https://cloud.digitalocean.com/apps/new?repo=...)

1. Click the button above
2. Sign in to DigitalOcean
3. Review the configuration
4. Click "Deploy"
5. Access your app at the provided URL

See [DEPLOY.md](DEPLOY.md) for detailed deployment instructions.
```

### 2. Set Sensible Defaults

Use conservative defaults:
- Smallest instance size that works
- Single instance
- Development database (if needed)
- Standard region (NYC)

Users can scale up later.

### 3. Document Costs

Be transparent about pricing:

```markdown
## Cost Estimate

- Service: $12/month (apps-s-1vcpu-1gb)
- Database (optional): $15/month (managed PostgreSQL)
- Total: ~$12-27/month

Free trial available for new DigitalOcean accounts.
```

### 4. Provide Configuration Examples

Show common customizations:

```markdown
## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PB_LOG_LEVEL` | `info` | Log level |
| `ADMIN_EMAIL` | - | Admin email (optional) |
```

### 5. Link to Full Documentation

```markdown
For advanced configuration, see:
- [App Platform Documentation](https://docs.digitalocean.com/products/app-platform/)
- [Production Deployment Guide](PRODUCTION.md)
- [App Spec Reference](https://docs.digitalocean.com/products/app-platform/reference/app-spec/)
```

## Troubleshooting

### Button Not Working

1. **Verify repository is public**
   ```bash
   # Check repo visibility
   gh repo view YOUR_USERNAME/YOUR_REPO --json visibility
   ```

2. **Verify `.do/deploy.template.yaml` exists**
   ```bash
   # Check file exists on GitHub
   curl -I https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/master/.do/deploy.template.yaml
   ```

3. **Validate YAML syntax**
   ```bash
   # Use yamllint or online validator
   yamllint .do/deploy.template.yaml
   ```

### Deployment Fails

1. **Check build logs** in the App Platform console
2. **Verify Dockerfile** builds locally:
   ```bash
   docker build -t test .
   ```
3. **Test the app spec**:
   ```bash
   doctl apps create --spec .do/app.yaml --wait
   ```

### Users Report Issues

1. Add a **TROUBLESHOOTING.md** section to your README
2. Set up **GitHub Discussions** for support
3. Add **deployment badges** to show status:
   ```markdown
   ![Deployment Status](https://img.shields.io/badge/deploy-to%20DO-blue)
   ```

## Examples in the Wild

See these repos for deploy button examples:
- [RabbitMQ](https://github.com/digitalocean/sample-rabbitmq)
- [Ghost](https://github.com/digitalocean/sample-ghost)
- [WordPress](https://github.com/digitalocean/sample-wordpress)

## Additional Resources

- [Deploy to DO Button Documentation](https://docs.digitalocean.com/products/app-platform/how-to/add-deploy-do-button/)
- [App Platform Samples](https://github.com/digitalocean/sample-apps-list)
- [App Spec Reference](https://docs.digitalocean.com/products/app-platform/reference/app-spec/)

## Contributing

If you improve the PocketBase deployment:
1. Fork the repository
2. Make your changes
3. Submit a pull request
4. Update documentation

## Support

For help with the Deploy button:
- [DigitalOcean Community](https://www.digitalocean.com/community/)
- [App Platform Tutorials](https://www.digitalocean.com/community/tags/app-platform)
- [GitHub Issues](https://github.com/YOUR_USERNAME/YOUR_REPO/issues)
