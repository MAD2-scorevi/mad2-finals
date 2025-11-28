# Firebase Admin SDK Setup Guide

## Why You Need Admin SDK

Firebase Admin SDK provides privileged access to Firebase services, including:
- **Deleting Firebase Auth users** (cannot be done from client apps)
- Managing users without authentication
- Custom token generation
- Bypassing security rules for administrative tasks

**Important**: Admin SDK must run on a **trusted server environment**, never in client apps (Flutter/web/mobile).

---

## Architecture Overview

```
Flutter App (Client)
    ↓ HTTP Request
Backend Server (Node.js/Python/etc.)
    ↓ Admin SDK
Firebase Services (Auth, Firestore, etc.)
```

---

## Option 1: Node.js Backend (Recommended)

### Prerequisites
- Node.js installed (v18+ recommended)
- Firebase project service account key

### Step 1: Get Service Account Key

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click **Settings** (⚙️) → **Project settings**
4. Go to **Service accounts** tab
5. Click **Generate new private key**
6. Download the JSON file (e.g., `serviceAccountKey.json`)
7. **Keep this file secure!** Never commit it to version control

### Step 2: Create Backend Server

Create a new directory for your backend:
```bash
mkdir mad2-backend
cd mad2-backend
npm init -y
npm install express firebase-admin cors dotenv
```

### Step 3: Backend Code (`server.js`)

```javascript
const express = require('express');
const admin = require('firebase-admin');
const cors = require('cors');
require('dotenv').config();

// Initialize Firebase Admin SDK
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const app = express();
app.use(cors());
app.use(express.json());

// Delete user endpoint
app.delete('/api/users/:uid', async (req, res) => {
  try {
    const { uid } = req.params;
    const { adminToken } = req.headers;

    // Verify the request is from an authenticated admin
    const decodedToken = await admin.auth().verifyIdToken(adminToken);

    // Check if requester is admin
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(decodedToken.uid)
      .get();

    const role = userDoc.data()?.role;
    if (role !== 'admin' && role !== 'product_owner') {
      return res.status(403).json({ error: 'Unauthorized' });
    }

    // Delete Firebase Auth user
    await admin.auth().deleteUser(uid);

    // Delete Firestore document
    await admin.firestore().collection('users').doc(uid).delete();

    res.json({ success: true, message: 'User completely deleted' });
  } catch (error) {
    console.error('Delete user error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Update user endpoint (optional, for Admin SDK-level updates)
app.put('/api/users/:uid', async (req, res) => {
  try {
    const { uid } = req.params;
    const { adminToken } = req.headers;
    const { email, displayName, disabled } = req.body;

    // Verify admin
    const decodedToken = await admin.auth().verifyIdToken(adminToken);
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(decodedToken.uid)
      .get();

    const role = userDoc.data()?.role;
    if (role !== 'admin' && role !== 'product_owner') {
      return res.status(403).json({ error: 'Unauthorized' });
    }

    // Update Firebase Auth
    const updateData = {};
    if (email) updateData.email = email;
    if (displayName) updateData.displayName = displayName;
    if (disabled !== undefined) updateData.disabled = disabled;

    await admin.auth().updateUser(uid, updateData);

    res.json({ success: true, message: 'User updated' });
  } catch (error) {
    console.error('Update user error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Admin SDK server running on port ${PORT}`);
});
```

### Step 4: Environment Setup

Create `.env` file:
```
PORT=3000
```

Create `.gitignore`:
```
node_modules/
serviceAccountKey.json
.env
```

### Step 5: Run Backend Server

```bash
node server.js
```

Server will run at `http://localhost:3000`

---

## Option 2: Cloud Functions (Firebase Hosting)

If you don't want to manage a server, use Firebase Cloud Functions:

### Setup

```bash
npm install -g firebase-tools
firebase login
firebase init functions
```

### Function Code (`functions/index.js`)

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.deleteUser = functions.https.onCall(async (data, context) => {
  // Verify caller is admin
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Must be authenticated'
    );
  }

  const callerDoc = await admin.firestore()
    .collection('users')
    .doc(context.auth.uid)
    .get();

  const role = callerDoc.data()?.role;
  if (role !== 'admin' && role !== 'product_owner') {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Must be admin'
    );
  }

  try {
    const { uid } = data;

    // Delete Auth user
    await admin.auth().deleteUser(uid);

    // Delete Firestore doc
    await admin.firestore().collection('users').doc(uid).delete();

    return { success: true };
  } catch (error) {
    throw new functions.https.HttpsError('internal', error.message);
  }
});
```

### Deploy

```bash
firebase deploy --only functions
```

---

## Flutter Integration

### Add HTTP Package

```yaml
# pubspec.yaml
dependencies:
  http: ^1.1.0
```

### Update UserService

Add this method to `user_service.dart`:

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

// Add to UserService class:

// For Node.js backend
static const String _backendUrl = 'http://localhost:3000'; // Change in production

Future<bool> deleteUserCompletely(String uid) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    // Get admin's ID token
    final idToken = await user.getIdToken();

    // Call backend API
    final response = await http.delete(
      Uri.parse('$_backendUrl/api/users/$uid'),
      headers: {
        'Content-Type': 'application/json',
        'adminToken': idToken ?? '',
      },
    );

    if (response.statusCode == 200) {
      print('✅ User completely deleted from Firebase Auth and Firestore');
      notifyListeners();
      return true;
    } else {
      print('❌ Delete failed: ${response.body}');
      return false;
    }
  } catch (e) {
    print('❌ Error calling backend: $e');
    return false;
  }
}

// For Cloud Functions
Future<bool> deleteUserWithCloudFunction(String uid) async {
  try {
    final callable = FirebaseFunctions.instance.httpsCallable('deleteUser');
    final result = await callable.call({'uid': uid});

    print('✅ User deleted via Cloud Function: ${result.data}');
    notifyListeners();
    return true;
  } catch (e) {
    print('❌ Cloud Function error: $e');
    return false;
  }
}
```

### Update Admin Dashboard

Replace `deactivateUser` calls with `deleteUserCompletely`:

```dart
// In admin_dashboard.dart, replace deactivation logic:

final success = await _userService.deleteUserCompletely(user['uid']);
if (success) {
  _refreshUserStream();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('User completely removed from system')),
  );
}
```

---

## Security Considerations

### 1. Secure Service Account Key
- **Never commit** `serviceAccountKey.json` to Git
- Use environment variables in production
- Restrict file permissions: `chmod 600 serviceAccountKey.json`

### 2. Verify Admin on Backend
Always verify the requesting user is an admin on the **backend**, not just the client.

### 3. Use HTTPS in Production
- Deploy backend with SSL/TLS
- Use services like Heroku, Railway, Google Cloud Run

### 4. Rate Limiting
Add rate limiting to prevent abuse:

```javascript
const rateLimit = require('express-rate-limit');

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});

app.use('/api/', limiter);
```

---

## Deployment Options

### Node.js Backend

1. **Heroku** (Free tier available)
   ```bash
   heroku create mad2-admin-backend
   git push heroku main
   ```

2. **Railway** (Easy deployment)
   - Connect GitHub repo
   - Auto-deploys on push

3. **Google Cloud Run** (Scales to zero)
   ```bash
   gcloud run deploy mad2-admin --source .
   ```

4. **AWS Lambda + API Gateway**
   - Serverless option
   - Pay per request

### Cloud Functions
- Automatically hosted by Firebase
- No server management needed
- Pay per invocation

---

## Testing

### Test Backend Locally

```bash
# In mad2-backend directory
node server.js
```

### Test with Postman/curl

```bash
# Get ID token from Flutter app (print it during admin login)
curl -X DELETE http://localhost:3000/api/users/USER_UID_HERE \
  -H "adminToken: YOUR_ID_TOKEN_HERE"
```

---

## Production Checklist

- [ ] Service account key secured (not in Git)
- [ ] Backend deployed with HTTPS
- [ ] Admin verification on backend
- [ ] Rate limiting enabled
- [ ] CORS configured for your Flutter app domain
- [ ] Error logging set up (e.g., Sentry)
- [ ] Backend URL updated in Flutter app
- [ ] Firestore security rules updated if needed

---

## Cost Estimates

### Cloud Functions
- 2 million free invocations/month
- $0.40 per million after that

### Node.js on Railway/Heroku
- Free tier: $0/month (with limitations)
- Paid: ~$5-10/month

### Google Cloud Run
- Free tier: 2 million requests/month
- Pay only when used

---

## Troubleshooting

### "Permission denied" errors
- Check service account has proper roles
- Verify admin role check on backend

### CORS errors
- Add your Flutter app's origin to CORS config
- For desktop: `http://localhost:*`

### "Invalid token" errors
- Ensure ID token is fresh (< 1 hour)
- Re-authenticate if needed

---

## Next Steps

1. Choose Option 1 (Node.js) or Option 2 (Cloud Functions)
2. Set up service account key
3. Deploy backend
4. Update Flutter `user_service.dart` with backend URL
5. Test with a non-critical user account
6. Deploy to production

---

## Questions?

- Firebase Admin SDK docs: https://firebase.google.com/docs/admin/setup
- Cloud Functions docs: https://firebase.google.com/docs/functions
- Express.js docs: https://expressjs.com/
