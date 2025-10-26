# Using PocketBase - Complete Guide

This guide walks you through using PocketBase from initial setup to building a complete application.

## Table of Contents

- [Initial Setup](#initial-setup)
- [Building Your First Application](#building-your-first-application)
- [End-to-End Example: Todo App](#end-to-end-example-todo-app)
- [User Authentication](#user-authentication)
- [Realtime Subscriptions](#realtime-subscriptions)
- [File Uploads](#file-uploads)
- [Next Steps](#next-steps)

## Initial Setup

### Step 1: Create Your Admin Account

After deploying PocketBase, you need to create an admin account:

1. **Open the Admin UI** in your browser:
   ```
   https://your-app-url.ondigitalocean.app/_/
   ```

2. **You'll see the setup screen** asking you to create the first admin:

   ![Admin Setup Screen]

   - **Email**: Your admin email (e.g., `admin@yourcompany.com`)
   - **Password**: Strong password (minimum 10 characters)
   - **Password Confirm**: Repeat your password

3. **Click "Create admin"**

4. **You're logged in!** You'll see the PocketBase Admin Dashboard.

> **⚠️ IMPORTANT**:
> - There's no default admin account - you MUST create this on first visit
> - **Create your admin IMMEDIATELY** after deployment (before the app is publicly accessible)
> - If someone else accesses `/_/` first, they'll create the admin account
> - If using ephemeral storage (SQLite), this admin will be lost on redeployment
> - If you lose your password, see [Troubleshooting](#lost-admin-password--cant-access-admin-ui)

### Step 2: Explore the Admin Dashboard

The dashboard has several sections:

- **Collections**: Your database tables
- **Logs**: API request logs
- **Settings**: App configuration
- **Admins**: Manage admin users

## Building Your First Application

Let's build a complete Todo application that demonstrates PocketBase's core features.

## End-to-End Example: Todo App

We'll create a todo application with:
- User authentication (sign up, login)
- CRUD operations (create, read, update, delete todos)
- Realtime updates (see changes instantly)
- User-specific todos (each user sees only their todos)

### Part 1: Setup Collections (Backend)

#### 1. Create Users Collection

PocketBase has a built-in users collection, but we'll use the Auth collection type:

1. **In Admin Dashboard**, click **"New collection"**
2. Select **"Auth collection"**
3. **Name**: `users`
4. **Fields** (these are auto-created):
   - `email` (required, unique)
   - `username` (optional)
   - `verified` (boolean)
   - `emailVisibility` (boolean)

5. **Click "Create"**

#### 2. Create Todos Collection

Now create the todos collection:

1. Click **"New collection"**
2. Select **"Base collection"**
3. **Name**: `todos`
4. **Add fields** (click "+ Add field"):

   | Field Name | Type | Required | Options |
   |------------|------|----------|---------|
   | `title` | Text | ✅ | - |
   | `description` | Editor | ❌ | - |
   | `completed` | Bool | ✅ | Default: `false` |
   | `user` | Relation | ✅ | Collection: `users`, Max: 1 |

5. **Set API Rules** (important for security):

   Click on **"API Rules"** tab:

   - **List/Search**: `@request.auth.id != "" && user = @request.auth.id`
   - **View**: `@request.auth.id != "" && user = @request.auth.id`
   - **Create**: `@request.auth.id != ""`
   - **Update**: `@request.auth.id != "" && user = @request.auth.id`
   - **Delete**: `@request.auth.id != "" && user = @request.auth.id`

   These rules ensure:
   - Users must be authenticated
   - Users can only see/modify their own todos

6. **Click "Create"**

### Part 2: Frontend Application

#### Option A: Plain HTML + JavaScript

Create a simple HTML file:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PocketBase Todo App</title>
    <style>
        body {
            font-family: system-ui, -apple-system, sans-serif;
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
        }
        .auth-form, .todo-app { margin: 20px 0; }
        .hidden { display: none; }
        input, textarea, button {
            display: block;
            margin: 10px 0;
            padding: 10px;
            width: 100%;
            box-sizing: border-box;
        }
        button {
            background: #0066ff;
            color: white;
            border: none;
            cursor: pointer;
            border-radius: 5px;
        }
        button:hover { background: #0052cc; }
        .todo-item {
            padding: 15px;
            margin: 10px 0;
            border: 1px solid #ddd;
            border-radius: 5px;
        }
        .todo-item.completed { opacity: 0.6; text-decoration: line-through; }
    </style>
</head>
<body>
    <h1>PocketBase Todo App</h1>

    <!-- Authentication Forms -->
    <div id="auth-section">
        <h2>Sign Up / Login</h2>
        <div class="auth-form">
            <h3>Sign Up</h3>
            <input type="email" id="signup-email" placeholder="Email">
            <input type="password" id="signup-password" placeholder="Password (min 8 chars)">
            <input type="password" id="signup-password-confirm" placeholder="Confirm Password">
            <button onclick="signUp()">Sign Up</button>
        </div>

        <div class="auth-form">
            <h3>Login</h3>
            <input type="email" id="login-email" placeholder="Email">
            <input type="password" id="login-password" placeholder="Password">
            <button onclick="login()">Login</button>
        </div>
    </div>

    <!-- Todo Application -->
    <div id="app-section" class="hidden">
        <div style="display: flex; justify-content: space-between; align-items: center;">
            <h2>My Todos</h2>
            <button onclick="logout()" style="width: auto; background: #ff3333;">Logout</button>
        </div>

        <div class="todo-app">
            <h3>Add New Todo</h3>
            <input type="text" id="todo-title" placeholder="Todo title">
            <textarea id="todo-description" placeholder="Description (optional)"></textarea>
            <button onclick="createTodo()">Add Todo</button>
        </div>

        <div id="todos-list"></div>
    </div>

    <script type="module">
        import PocketBase from 'https://cdn.jsdelivr.net/npm/pocketbase@0.21.5/+esm'

        // Initialize PocketBase (replace with your URL)
        const pb = new PocketBase('https://your-app-url.ondigitalocean.app')

        // Make pb globally available
        window.pb = pb

        // Check if user is already logged in
        if (pb.authStore.isValid) {
            showApp()
            loadTodos()
        }

        // Sign Up
        window.signUp = async function() {
            const email = document.getElementById('signup-email').value
            const password = document.getElementById('signup-password').value
            const passwordConfirm = document.getElementById('signup-password-confirm').value

            try {
                await pb.collection('users').create({
                    email,
                    password,
                    passwordConfirm
                })

                alert('Account created! Please login.')
                document.getElementById('login-email').value = email
            } catch (error) {
                alert('Error: ' + error.message)
            }
        }

        // Login
        window.login = async function() {
            const email = document.getElementById('login-email').value
            const password = document.getElementById('login-password').value

            try {
                await pb.collection('users').authWithPassword(email, password)
                showApp()
                loadTodos()

                // Subscribe to realtime updates
                subscribeToTodos()
            } catch (error) {
                alert('Error: ' + error.message)
            }
        }

        // Logout
        window.logout = function() {
            pb.authStore.clear()
            document.getElementById('auth-section').classList.remove('hidden')
            document.getElementById('app-section').classList.add('hidden')
        }

        // Show app section
        function showApp() {
            document.getElementById('auth-section').classList.add('hidden')
            document.getElementById('app-section').classList.remove('hidden')
        }

        // Create Todo
        window.createTodo = async function() {
            const title = document.getElementById('todo-title').value
            const description = document.getElementById('todo-description').value

            if (!title) {
                alert('Title is required')
                return
            }

            try {
                await pb.collection('todos').create({
                    title,
                    description,
                    completed: false,
                    user: pb.authStore.model.id
                })

                // Clear form
                document.getElementById('todo-title').value = ''
                document.getElementById('todo-description').value = ''

                // Reload todos
                loadTodos()
            } catch (error) {
                alert('Error: ' + error.message)
            }
        }

        // Load Todos
        window.loadTodos = async function() {
            try {
                const records = await pb.collection('todos').getFullList({
                    sort: '-created'
                })

                displayTodos(records)
            } catch (error) {
                console.error('Error loading todos:', error)
            }
        }

        // Display Todos
        function displayTodos(todos) {
            const container = document.getElementById('todos-list')

            if (todos.length === 0) {
                container.innerHTML = '<p>No todos yet. Create one above!</p>'
                return
            }

            container.innerHTML = todos.map(todo => `
                <div class="todo-item ${todo.completed ? 'completed' : ''}">
                    <h4>${todo.title}</h4>
                    ${todo.description ? `<p>${todo.description}</p>` : ''}
                    <div>
                        <button onclick="toggleTodo('${todo.id}', ${!todo.completed})"
                                style="width: auto; display: inline-block; margin-right: 10px;">
                            ${todo.completed ? 'Mark Incomplete' : 'Mark Complete'}
                        </button>
                        <button onclick="deleteTodo('${todo.id}')"
                                style="width: auto; display: inline-block; background: #ff3333;">
                            Delete
                        </button>
                    </div>
                </div>
            `).join('')
        }

        // Toggle Todo Completion
        window.toggleTodo = async function(id, completed) {
            try {
                await pb.collection('todos').update(id, { completed })
                loadTodos()
            } catch (error) {
                alert('Error: ' + error.message)
            }
        }

        // Delete Todo
        window.deleteTodo = async function(id) {
            if (!confirm('Delete this todo?')) return

            try {
                await pb.collection('todos').delete(id)
                loadTodos()
            } catch (error) {
                alert('Error: ' + error.message)
            }
        }

        // Subscribe to realtime updates
        function subscribeToTodos() {
            pb.collection('todos').subscribe('*', function (e) {
                console.log('Realtime update:', e.action, e.record)
                loadTodos() // Reload todos on any change
            })
        }
    </script>
</body>
</html>
```

**To use this:**

1. Save as `index.html`
2. **Replace** `https://your-app-url.ondigitalocean.app` with your actual PocketBase URL
3. Open in your browser
4. Sign up, login, and start creating todos!

#### Option B: React Application

```bash
# Create React app
npx create-react-app pocketbase-todo
cd pocketbase-todo

# Install PocketBase SDK
npm install pocketbase
```

**src/App.js**:

```javascript
import { useState, useEffect } from 'react'
import PocketBase from 'pocketbase'

const pb = new PocketBase('https://your-app-url.ondigitalocean.app')

function App() {
  const [user, setUser] = useState(pb.authStore.model)
  const [todos, setTodos] = useState([])
  const [title, setTitle] = useState('')
  const [description, setDescription] = useState('')

  // Auth form state
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')

  useEffect(() => {
    if (user) {
      loadTodos()
      subscribeToTodos()
    }
  }, [user])

  const signUp = async (e) => {
    e.preventDefault()
    try {
      await pb.collection('users').create({
        email,
        password,
        passwordConfirm: password
      })
      alert('Account created! Please login.')
    } catch (error) {
      alert('Error: ' + error.message)
    }
  }

  const login = async (e) => {
    e.preventDefault()
    try {
      const authData = await pb.collection('users').authWithPassword(email, password)
      setUser(authData.record)
    } catch (error) {
      alert('Error: ' + error.message)
    }
  }

  const logout = () => {
    pb.authStore.clear()
    setUser(null)
    setTodos([])
  }

  const loadTodos = async () => {
    try {
      const records = await pb.collection('todos').getFullList({
        sort: '-created'
      })
      setTodos(records)
    } catch (error) {
      console.error('Error loading todos:', error)
    }
  }

  const createTodo = async (e) => {
    e.preventDefault()
    try {
      await pb.collection('todos').create({
        title,
        description,
        completed: false,
        user: user.id
      })
      setTitle('')
      setDescription('')
      loadTodos()
    } catch (error) {
      alert('Error: ' + error.message)
    }
  }

  const toggleTodo = async (id, completed) => {
    try {
      await pb.collection('todos').update(id, { completed })
      loadTodos()
    } catch (error) {
      alert('Error: ' + error.message)
    }
  }

  const deleteTodo = async (id) => {
    if (!window.confirm('Delete this todo?')) return
    try {
      await pb.collection('todos').delete(id)
      loadTodos()
    } catch (error) {
      alert('Error: ' + error.message)
    }
  }

  const subscribeToTodos = () => {
    pb.collection('todos').subscribe('*', () => {
      loadTodos()
    })
  }

  if (!user) {
    return (
      <div style={{ maxWidth: '400px', margin: '50px auto', padding: '20px' }}>
        <h1>PocketBase Todo</h1>

        <h2>Sign Up</h2>
        <form onSubmit={signUp}>
          <input
            type="email"
            placeholder="Email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required
          />
          <input
            type="password"
            placeholder="Password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
          />
          <button type="submit">Sign Up</button>
        </form>

        <h2>Login</h2>
        <form onSubmit={login}>
          <input
            type="email"
            placeholder="Email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required
          />
          <input
            type="password"
            placeholder="Password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
          />
          <button type="submit">Login</button>
        </form>
      </div>
    )
  }

  return (
    <div style={{ maxWidth: '800px', margin: '50px auto', padding: '20px' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between' }}>
        <h1>My Todos</h1>
        <button onClick={logout}>Logout</button>
      </div>

      <form onSubmit={createTodo}>
        <input
          type="text"
          placeholder="Todo title"
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          required
        />
        <textarea
          placeholder="Description (optional)"
          value={description}
          onChange={(e) => setDescription(e.target.value)}
        />
        <button type="submit">Add Todo</button>
      </form>

      <div>
        {todos.length === 0 ? (
          <p>No todos yet!</p>
        ) : (
          todos.map(todo => (
            <div key={todo.id} style={{
              padding: '15px',
              margin: '10px 0',
              border: '1px solid #ddd',
              borderRadius: '5px',
              opacity: todo.completed ? 0.6 : 1
            }}>
              <h3 style={{ textDecoration: todo.completed ? 'line-through' : 'none' }}>
                {todo.title}
              </h3>
              {todo.description && <p>{todo.description}</p>}
              <button onClick={() => toggleTodo(todo.id, !todo.completed)}>
                {todo.completed ? 'Mark Incomplete' : 'Mark Complete'}
              </button>
              <button onClick={() => deleteTodo(todo.id)} style={{ marginLeft: '10px' }}>
                Delete
              </button>
            </div>
          ))
        )}
      </div>
    </div>
  )
}

export default App
```

**To run**:
```bash
npm start
```

## User Authentication

PocketBase provides built-in authentication:

### Sign Up
```javascript
await pb.collection('users').create({
  email: 'user@example.com',
  password: 'securepassword',
  passwordConfirm: 'securepassword'
})
```

### Login
```javascript
const authData = await pb.collection('users').authWithPassword(
  'user@example.com',
  'securepassword'
)

// Access user data
console.log(authData.record.id)
console.log(authData.record.email)
```

### Logout
```javascript
pb.authStore.clear()
```

### Check if Logged In
```javascript
if (pb.authStore.isValid) {
  console.log('User is logged in:', pb.authStore.model)
}
```

### OAuth2 Login (Google, Facebook, etc.)

```javascript
// Get OAuth2 providers
const authMethods = await pb.collection('users').listAuthMethods()

// Authenticate with Google
const authData = await pb.collection('users').authWithOAuth2({
  provider: 'google'
})
```

## Realtime Subscriptions

PocketBase supports realtime updates via Server-Sent Events (SSE):

```javascript
// Subscribe to all changes in todos collection
pb.collection('todos').subscribe('*', function (e) {
  console.log(e.action) // 'create', 'update', 'delete'
  console.log(e.record) // the changed record
})

// Subscribe to specific record
pb.collection('todos').subscribe('RECORD_ID', function (e) {
  console.log('This specific todo changed:', e.record)
})

// Unsubscribe
pb.collection('todos').unsubscribe()
```

## File Uploads

### 1. Add File Field to Collection

In Admin UI:
1. Edit your collection
2. Add field → **File**
3. Configure options (max files, max size, allowed types)

### 2. Upload Files

```html
<input type="file" id="fileInput">
<button onclick="uploadFile()">Upload</button>

<script>
async function uploadFile() {
  const fileInput = document.getElementById('fileInput')
  const file = fileInput.files[0]

  const formData = new FormData()
  formData.append('title', 'My Document')
  formData.append('file', file) // 'file' is your field name

  const record = await pb.collection('documents').create(formData)
  console.log('Uploaded:', record)
}
</script>
```

### 3. Display Files

```javascript
// Get file URL
const url = pb.files.getUrl(record, record.file)

// For images
<img src={url} alt={record.title} />

// For downloads
<a href={url} download>Download File</a>
```

## Advanced Features

### Filters and Sorting

```javascript
// Filter todos by completed status
const completed = await pb.collection('todos').getList(1, 50, {
  filter: 'completed = true'
})

// Complex filters
const recent = await pb.collection('todos').getList(1, 50, {
  filter: 'created >= "2025-01-01" && completed = false',
  sort: '-created'
})

// Search
const results = await pb.collection('todos').getList(1, 50, {
  filter: 'title ~ "shopping"'
})
```

### Expanding Relations

```javascript
// Get todos with user information expanded
const todos = await pb.collection('todos').getList(1, 50, {
  expand: 'user'
})

// Access expanded data
todos.items.forEach(todo => {
  console.log(todo.title)
  console.log(todo.expand.user.email) // expanded user
})
```

### Pagination

```javascript
// Get page 1 (20 items per page)
const result = await pb.collection('todos').getList(1, 20)

console.log(result.page)         // current page
console.log(result.perPage)      // items per page
console.log(result.totalItems)   // total count
console.log(result.totalPages)   // total pages
console.log(result.items)        // the records
```

## Testing Your Application

### 1. Test with cURL

```bash
# Health check
curl https://your-app-url.ondigitalocean.app/api/health

# Create user (sign up)
curl -X POST https://your-app-url.ondigitalocean.app/api/collections/users/records \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "testpassword123",
    "passwordConfirm": "testpassword123"
  }'

# Login
curl -X POST https://your-app-url.ondigitalocean.app/api/collections/users/auth-with-password \
  -H "Content-Type: application/json" \
  -d '{
    "identity": "test@example.com",
    "password": "testpassword123"
  }'

# Get todos (requires auth token from login response)
curl https://your-app-url.ondigitalocean.app/api/collections/todos/records \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### 2. Test in Browser Console

Open your app in browser, then in console:

```javascript
// Test authentication
const user = await pb.collection('users').authWithPassword(
  'test@example.com',
  'testpassword123'
)
console.log('Logged in:', user)

// Create test data
for (let i = 1; i <= 5; i++) {
  await pb.collection('todos').create({
    title: `Test Todo ${i}`,
    description: `Description for todo ${i}`,
    completed: false,
    user: pb.authStore.model.id
  })
}

// List all todos
const todos = await pb.collection('todos').getFullList()
console.log('All todos:', todos)
```

## Next Steps

### 1. Add More Features

- **Categories/Tags**: Add a `tags` field (Select or Relation)
- **Due Dates**: Add `dueDate` field (Date)
- **Priority**: Add `priority` field (Select: low, medium, high)
- **Sharing**: Create a `shared_todos` relation collection

### 2. Production Deployment

- Migrate to PostgreSQL (see [PRODUCTION.md](PRODUCTION.md))
- Set up custom domain
- Enable HTTPS
- Configure CORS properly
- Set up backups

### 3. Advanced Backend

- **Hooks**: Add server-side logic (JavaScript hooks)
- **Custom Validation**: Validate data before save
- **Scheduled Jobs**: Run cron jobs
- **Email Templates**: Customize verification emails

### 4. Mobile App

Use PocketBase with:
- **React Native**: Same SDK works!
- **Flutter**: Use [pocketbase-dart](https://pub.dev/packages/pocketbase)
- **Swift/iOS**: Use REST API or community SDKs

## Common Use Cases

### Blog Platform
```javascript
Collections:
- users (auth)
- posts (title, content, author→users, published_date)
- comments (content, post→posts, author→users)
- categories (name, slug)
```

### E-commerce
```javascript
Collections:
- users (auth)
- products (name, description, price, images, category)
- cart_items (user→users, product→products, quantity)
- orders (user→users, total, status, items)
```

### Task Management
```javascript
Collections:
- users (auth)
- projects (name, description, owner→users)
- tasks (title, project→projects, assignee→users, status)
- comments (task→tasks, author→users, content)
```

### Social Network
```javascript
Collections:
- users (auth, bio, avatar)
- posts (content, author→users, likes_count)
- follows (follower→users, following→users)
- likes (user→users, post→posts)
```

## Resources

- **PocketBase Docs**: https://pocketbase.io/docs/
- **API Reference**: https://pocketbase.io/docs/api-reference/
- **JavaScript SDK**: https://github.com/pocketbase/js-sdk
- **Community**: https://github.com/pocketbase/pocketbase/discussions
- **Examples**: https://pocketbase.io/docs/how-to-use/

## Troubleshooting

### "The request requires valid record authorization token"

This means you need to be authenticated. Make sure to:
1. Login first: `await pb.collection('users').authWithPassword(...)`
2. Check auth is valid: `pb.authStore.isValid`

### "Failed to create record"

Check:
1. All required fields are provided
2. Field types match (string, number, boolean, etc.)
3. Relations point to valid records
4. API rules allow creation

### CORS Errors

If testing locally:
1. Make sure your PocketBase URL is correct
2. Check CORS settings in PocketBase admin (Settings → Allowed origins)
3. Add your development URL (e.g., `http://localhost:3000`)

### Realtime Not Working

1. Ensure you're authenticated
2. Check browser console for errors
3. Verify WebSocket/SSE isn't blocked by firewall
4. Try unsubscribe and subscribe again

### Lost Admin Password / Can't Access Admin UI

If you see the "Superuser login" screen instead of "Create your first admin", it means an admin account was already created. If you've lost the password or don't know the credentials:

#### Option 1: Redeploy the App (Wipes All Data)

This creates a fresh PocketBase instance with no data:

```bash
# Get your app ID (if you don't know it)
doctl apps list

# Trigger a new deployment (force rebuild)
doctl apps create-deployment YOUR_APP_ID --force-build --wait
```

Replace `YOUR_APP_ID` with your actual App Platform app ID.

**Example:**
```bash
doctl apps create-deployment 6a300681-df86-4a5e-8a30-0ab51321bb63 --force-build --wait
```

After redeployment:
1. **Immediately** go to `https://your-app-url.ondigitalocean.app/_/`
2. Create your admin account
3. Start fresh

⚠️ **Warning**: This will delete ALL data (users, collections, records) since we're using ephemeral SQLite storage.

#### Option 2: Migrate to PostgreSQL (Recommended for Production)

If you need to preserve data, migrate to PostgreSQL first:

1. Follow the production migration guide in [PRODUCTION.md](PRODUCTION.md)
2. Add a managed PostgreSQL database to your app
3. Your data will persist across deployments
4. Use PocketBase's admin management features to reset passwords

#### Option 3: Delete and Recreate App

If you want a completely new app:

```bash
# Delete the current app
doctl apps delete YOUR_APP_ID --force

# Create a new app
doctl apps create --spec .do/app.yaml --wait
```

This gives you a fresh app with a new URL.

#### Prevention Tips

1. **Create admin immediately** after deployment (before the app is publicly accessible)
2. **Use strong, saved passwords** (password manager recommended)
3. **Migrate to PostgreSQL** for production (data persists)
4. **Create multiple admin accounts** (Settings → Admins in admin UI)
5. **Document your credentials** securely

---

**You're now ready to build amazing applications with PocketBase!** 🚀
