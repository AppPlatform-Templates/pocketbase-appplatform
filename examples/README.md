# PocketBase Examples

This directory contains ready-to-use example applications demonstrating how to use PocketBase.

## Todo App Example

A complete, production-ready todo application demonstrating:
- User authentication (sign up, login, logout)
- CRUD operations (create, read, update, delete)
- Realtime updates
- Proper error handling
- Modern UI/UX

### Quick Start

1. **Deploy PocketBase** (if you haven't already):
   - See [main README](../README.md) for deployment instructions

2. **Create Collections in PocketBase**:
   - Access your PocketBase admin at `https://your-app-url.ondigitalocean.app/_/`
   - Create admin account (first time only)
   - Create `todos` collection (see instructions below)

3. **Download and run the example**:
   ```bash
   # Download the example
   curl -O https://raw.githubusercontent.com/AppPlatform-Templates/pocketbase-appplatform/main/examples/todo-app.html

   # Open in browser
   open todo-app.html
   # Or on Linux:
   xdg-open todo-app.html
   ```

4. **Update the PocketBase URL**:
   - Edit `todo-app.html`
   - Find line 169: `const POCKETBASE_URL = '...'`
   - Replace with your PocketBase URL

5. **Open in browser** and start using it!

### Setting Up the Todos Collection

#### Option 1: Using the Admin UI (Recommended)

1. Go to your PocketBase admin: `https://your-app-url.ondigitalocean.app/_/`
2. Click **"New collection"**
3. Select **"Base collection"**
4. **Name**: `todos`
5. **Add these fields**:

   | Field Name | Type | Required | Options |
   |------------|------|----------|---------|
   | `title` | Text | ✅ Yes | - |
   | `description` | Editor | ❌ No | - |
   | `completed` | Bool | ✅ Yes | Default: `false` |
   | `user` | Relation | ✅ Yes | Collection: `users`<br>Max: 1 |

6. **Configure API Rules** (Security tab):
   - **List/Search**: `@request.auth.id != "" && user = @request.auth.id`
   - **View**: `@request.auth.id != "" && user = @request.auth.id`
   - **Create**: `@request.auth.id != ""`
   - **Update**: `@request.auth.id != "" && user = @request.auth.id`
   - **Delete**: `@request.auth.id != "" && user = @request.auth.id`

7. Click **"Create"**

#### Option 2: Using the API

```bash
# Get your admin token first
ADMIN_EMAIL="your-admin@email.com"
ADMIN_PASSWORD="your-admin-password"
BASE_URL="https://your-app-url.ondigitalocean.app"

# Login as admin
TOKEN=$(curl -X POST "$BASE_URL/api/admins/auth-with-password" \
  -H "Content-Type: application/json" \
  -d "{\"identity\":\"$ADMIN_EMAIL\",\"password\":\"$ADMIN_PASSWORD\"}" \
  | jq -r '.token')

# Create todos collection
curl -X POST "$BASE_URL/api/collections" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "todos",
    "type": "base",
    "schema": [
      {
        "name": "title",
        "type": "text",
        "required": true
      },
      {
        "name": "description",
        "type": "editor",
        "required": false
      },
      {
        "name": "completed",
        "type": "bool",
        "required": true
      },
      {
        "name": "user",
        "type": "relation",
        "required": true,
        "options": {
          "collectionId": "users",
          "maxSelect": 1
        }
      }
    ],
    "listRule": "@request.auth.id != \"\" && user = @request.auth.id",
    "viewRule": "@request.auth.id != \"\" && user = @request.auth.id",
    "createRule": "@request.auth.id != \"\"",
    "updateRule": "@request.auth.id != \"\" && user = @request.auth.id",
    "deleteRule": "@request.auth.id != \"\" && user = @request.auth.id"
  }'
```

### Features Demonstrated

✅ **Authentication**
- Sign up with email/password
- Login with validation
- Logout and session management
- Auto-login on page refresh

✅ **CRUD Operations**
- Create todos with title and description
- Read/list todos
- Update (toggle completion status)
- Delete todos with confirmation

✅ **Security**
- User-specific data (users can only see their own todos)
- API rules enforce authentication
- XSS protection (HTML escaping)

✅ **Realtime Updates**
- Changes appear instantly across all open tabs
- No page refresh needed

✅ **User Experience**
- Modern, responsive design
- Loading states
- Error handling
- Empty states
- Form validation

### Testing the App

1. **Create an account**:
   - Click "Sign Up" tab
   - Enter email and password
   - Click "Create Account"

2. **Login**:
   - Enter your credentials
   - Click "Login"

3. **Create todos**:
   - Enter a title
   - Optionally add a description
   - Click "Add Todo"

4. **Test realtime**:
   - Open the app in two browser tabs
   - Create a todo in one tab
   - Watch it appear in the other tab instantly!

5. **Test completion**:
   - Click "✅ Complete" on a todo
   - Watch it get marked as completed

6. **Test deletion**:
   - Click "🗑️ Delete"
   - Confirm deletion
   - Todo disappears

### Customization Ideas

Want to extend this example? Try adding:

1. **Due Dates**:
   - Add `dueDate` field (Date type)
   - Show overdue todos in red
   - Sort by due date

2. **Categories/Tags**:
   - Add `category` field (Select type)
   - Filter todos by category
   - Color-code by category

3. **Priority Levels**:
   - Add `priority` field (Select: low, medium, high)
   - Sort by priority
   - Different icons for each level

4. **Search**:
   - Add search input
   - Filter todos by title/description
   - Highlight search terms

5. **Sharing**:
   - Add `shared_with` relation field (users collection)
   - Allow sharing todos with other users
   - Show shared todos separately

## More Examples

### Coming Soon

- **Blog Platform**: Full-featured blog with posts, comments, and categories
- **Chat Application**: Realtime chat with rooms and direct messages
- **E-commerce**: Products, cart, and orders
- **File Manager**: Upload, organize, and share files

Want to contribute an example? [Submit a PR](https://github.com/AppPlatform-Templates/pocketbase-appplatform/pulls)!

## Resources

- **Full Usage Guide**: [USING_POCKETBASE.md](../USING_POCKETBASE.md)
- **Deployment Guide**: [README.md](../README.md)
- **Production Setup**: [PRODUCTION.md](../PRODUCTION.md)
- **PocketBase Docs**: https://pocketbase.io/docs/

## Troubleshooting

### "Collection or view not found"

Make sure you created the `todos` collection in the PocketBase admin dashboard. See "Setting Up the Todos Collection" above.

### "Failed to create record"

Check that:
1. You're logged in
2. The `todos` collection exists
3. All required fields are provided
4. The `user` relation field points to the correct users collection

### "The request requires valid record authorization token"

This means you need to login first. The app should handle this automatically, but if you see this error:
1. Make sure you're logged in
2. Try logging out and logging back in
3. Check browser console for errors

### CORS Errors

If you see CORS errors:
1. Make sure the PocketBase URL in the code is correct
2. You're opening the HTML file in a browser (not using `file://`)
3. Consider serving the HTML via a local web server

## Support

Need help?
- Check [USING_POCKETBASE.md](../USING_POCKETBASE.md) for detailed documentation
- Open an issue: https://github.com/AppPlatform-Templates/pocketbase-appplatform/issues
- PocketBase community: https://github.com/pocketbase/pocketbase/discussions
