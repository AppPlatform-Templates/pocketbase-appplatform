# PocketBase on App Platform - Quick Start

Get PocketBase v0.31.0 running on DigitalOcean App Platform in 5 minutes.

> **Note**: This deployment uses PocketBase v0.31.0 (pinned for stability). See README.md for upgrade instructions.

## Prerequisites

- DigitalOcean account ([Sign up here](https://www.digitalocean.com) - $200 credit available)
- GitHub account

## Step 1: Deploy (Choose One Method)

### Method A: One-Click Deploy (Easiest)

1. Click this button:

   [![Deploy to DO](https://www.deploytodo.com/do-btn-blue.svg)](https://cloud.digitalocean.com/apps/new?repo=https://github.com/AppPlatform-Templates/pocketbase-appplatform/tree/main)

2. Sign in to DigitalOcean
3. Click **"Deploy"**
4. Wait 5-10 minutes for build to complete

### Method B: Manual Deploy

1. Go to https://cloud.digitalocean.com/apps
2. Click **"Create App"**
3. Choose **"GitHub"**
4. Select repository: `AppPlatform-Templates/pocketbase-appplatform`
5. Branch: `main`
6. Click **"Next"** → **"Next"** → **"Deploy"**

### Method C: CLI Deploy (Advanced)

```bash
# Install doctl
brew install doctl  # macOS
# or see: https://docs.digitalocean.com/reference/doctl/

# Authenticate
doctl auth init

# Create app
git clone https://github.com/pocketbase/pocketbase.git
cd pocketbase
doctl apps create --spec .do/app.yaml --wait
```

## Step 2: Access Your App

Once deployed (you'll get a notification):

1. Click on your app in the [Apps dashboard](https://cloud.digitalocean.com/apps)
2. Copy the app URL (looks like: `https://pocketbase-xxxxx.ondigitalocean.app`)
3. Open it in your browser

## Step 3: Create Admin Account

1. Go to: `https://your-app-url.ondigitalocean.app/_/`
2. Click **"Create your first admin"**
3. Fill in:
   - Email
   - Password (min 10 characters)
4. Click **"Create admin"**

You're in! The admin dashboard will load.

## Step 4: Create Your First Collection

1. In the admin dashboard, click **"New collection"**
2. Choose a type:
   - **Base collection**: For custom data
   - **Auth collection**: For users/authentication
   - **View collection**: For read-only SQL views

3. For a simple example, create a **Base collection**:
   - Name: `posts`
   - Add fields:
     - `title` (Text)
     - `content` (Editor)
     - `published` (Bool)
   - Click **"Create"**

## Step 5: Add Your First Record

1. Click on the `posts` collection
2. Click **"New record"**
3. Fill in the fields
4. Click **"Create"**

## Step 6: Test the API

```bash
# Replace YOUR_APP_URL with your actual URL
APP_URL="https://your-app-url.ondigitalocean.app"

# List collections (requires auth)
curl "$APP_URL/api/collections"

# List posts (if public)
curl "$APP_URL/api/collections/posts/records"
```

## What's Next?

### For Development

1. **Enable public access** to your collection (in collection settings)
2. **Create API rules** for authentication and authorization
3. **Test realtime subscriptions**
4. **Add file uploads**

### For Production

⚠️ **Important**: Current setup uses ephemeral SQLite (data is lost on deployment)

**To make data persistent:**

1. Read [PRODUCTION.md](PRODUCTION.md)
2. Add a managed PostgreSQL database
3. Migrate from SQLite to PostgreSQL
4. Implement security hardening

### Connect a Frontend

Use PocketBase JavaScript SDK:

```bash
npm install pocketbase
```

```javascript
import PocketBase from 'pocketbase';

const pb = new PocketBase('https://your-app-url.ondigitalocean.app');

// List posts
const records = await pb.collection('posts').getFullList();

// Create a post
const record = await pb.collection('posts').create({
  title: 'Hello World',
  content: 'My first post!',
  published: true
});

// Realtime subscriptions
pb.collection('posts').subscribe('*', (e) => {
  console.log(e.action); // create, update, delete
  console.log(e.record);
});
```

### Add a Custom Domain

1. Go to your app in the control panel
2. Click **"Settings"** → **"Domains"**
3. Add your domain
4. Update DNS records as instructed

## Troubleshooting

### Build Failed

- Check build logs in the App Platform console
- Verify Go version (requires 1.23+)

### Can't Access Admin UI

- Wait 5-10 minutes for initial build
- Check app status in control panel
- Verify URL is correct

### Data Lost After Redeployment

- **Expected behavior** with SQLite in ephemeral storage
- Migrate to PostgreSQL for persistence (see PRODUCTION.md)

### API Returns Errors

- Check collection rules (may require authentication)
- Verify API endpoint URLs
- Check request format

## Costs

### Minimal Setup (Current)
- **Service**: $12/month (apps-s-1vcpu-1gb)
- **Free trial**: $200 credit for new accounts

### Production Setup
- **Service**: $12/month
- **PostgreSQL**: +$15/month
- **Total**: $27/month

## Resources

| Resource | Link |
|----------|------|
| **PocketBase Docs** | https://pocketbase.io/docs/ |
| **API Reference** | https://pocketbase.io/docs/api-reference/ |
| **JavaScript SDK** | https://github.com/pocketbase/js-sdk |
| **Dart SDK** | https://github.com/pocketbase/dart-sdk |
| **App Platform Docs** | https://docs.digitalocean.com/products/app-platform/ |
| **Community** | https://github.com/pocketbase/pocketbase/discussions |

## Need Help?

- **PocketBase**: https://github.com/pocketbase/pocketbase/discussions
- **App Platform**: https://www.digitalocean.com/community/tags/app-platform
- **DigitalOcean Support**: https://www.digitalocean.com/support/

## Testing Your Deployment

Run the included test script:

```bash
./test-deployment.sh https://your-app-url.ondigitalocean.app
```

This will verify:
- Health check
- Admin UI accessibility
- API endpoints
- Response times
- HTTPS/SSL
- Security headers

---

**You're all set!** Start building with PocketBase on App Platform.

For advanced configuration and production deployment, see:
- [README.md](README.md) - Full documentation
- [PRODUCTION.md](PRODUCTION.md) - Production guide
- [SUMMARY.md](SUMMARY.md) - Complete overview
