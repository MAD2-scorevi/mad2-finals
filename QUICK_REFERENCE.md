# Quick Reference Guide

## Sample User Credentials

| Role | Email | Password | Access |
|------|-------|----------|--------|
| **User** | sample.user@gmail.com | sampleuser | Products Page |
| **Admin** | sample.admin@gmail.com | sampleadmin | Admin Dashboard |
| **Owner** | sample.owner@gmail.com | sampleowner | Product Owner Dashboard |

## Essential Commands

### Install Dependencies
```bash
flutter pub get
```

### Configure Firebase (First Time Only)
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure project
flutterfire configure
```

### Initialize Sample Users (Run Once)
```bash
flutter run lib/init_firebase.dart
```

### Run the App
```bash
flutter run
```

### Clean Build (If Issues Occur)
```bash
flutter clean
flutter pub get
flutter run
```

## Firebase Console URLs

- **Console Home**: https://console.firebase.google.com/
- **Authentication**: Console → Build → Authentication
- **Firestore Database**: Console → Build → Firestore Database
- **Security Rules**: Firestore Database → Rules tab

## User Registration Form Fields

All fields are required for new user registration:

1. **Full Name** - User's complete name
2. **Email Address** - Valid email format
3. **Password** - Minimum 6 characters
4. **Phone Number** - Contact number
5. **Address** - Physical address
6. **Date of Birth** - Date picker format: dd/mm/yyyy

## Database Structure

### Users Collection Path
```
Firestore → users → {userId}
```

### User Document Fields
```javascript
{
  uid: string,           // Firebase Auth UID
  email: string,         // User's email
  fullName: string,      // User's full name
  phoneNumber: string,   // Contact number
  address: string,       // Physical address
  dateOfBirth: string,   // Format: dd/mm/yyyy
  role: string,          // "user", "admin", or "owner"
  createdAt: Timestamp   // Auto-generated
}
```

## User Roles & Permissions

### User Role (Default)
- ✅ View products
- ✅ Create orders
- ✅ View own orders
- ✅ Update own profile
- ❌ Access admin features
- ❌ Access owner features

### Admin Role
- ✅ All user permissions
- ✅ View all users
- ✅ Update user data
- ✅ Delete users
- ✅ Manage system settings
- ✅ View all orders

### Owner Role
- ✅ All user permissions
- ✅ Create/update/delete products
- ✅ View all orders
- ✅ Update order status
- ✅ Manage inventory

## Key Files

### Configuration
- `lib/firebase_options.dart` - Firebase project configuration
- `firestore.rules` - Database security rules
- `pubspec.yaml` - Dependencies

### Services
- `lib/services/firebase_auth_service.dart` - Authentication methods
- `lib/services/firebase_initializer.dart` - Database initialization

### Pages
- `lib/login_page.dart` - Login with Firebase Auth
- `lib/registration.dart` - User registration
- `lib/admin_dashboard.dart` - Admin interface
- `lib/product_owner_dashboard.dart` - Owner interface
- `lib/products.dart` - User/customer interface

### Scripts
- `lib/init_firebase.dart` - Creates sample users
- `lib/main.dart` - App entry point

## Common Error Solutions

### Error: "Firebase not initialized"
```bash
flutterfire configure
```

### Error: "Target of URI doesn't exist"
```bash
flutter pub get
```

### Error: "Permission denied"
- Publish security rules in Firebase Console
- Check user has correct role in Firestore

### Error: "Authentication failed"
- Enable Email/Password in Firebase Console
- Verify sample users exist in Authentication

### Error: Build fails
```bash
flutter clean
flutter pub get
```

## Testing Checklist

- [ ] Login as user → Products Page
- [ ] Login as admin → Admin Dashboard
- [ ] Login as owner → Product Owner Dashboard
- [ ] Register new account → Success message
- [ ] New user appears in Firebase Console
- [ ] User data saved in Firestore

## Firebase Console Navigation

1. **Enable Authentication**
   - Build → Authentication → Sign-in method → Email/Password → Enable

2. **Create Firestore Database**
   - Build → Firestore Database → Create database → Test mode

3. **Set Security Rules**
   - Firestore Database → Rules → Paste rules from `firestore.rules` → Publish

4. **View Users**
   - Authentication → Users tab

5. **View Data**
   - Firestore Database → Data tab → users collection

## Next Development Steps

1. ✅ Firebase setup complete
2. ⬜ Implement product management
3. ⬜ Create order system
4. ⬜ Add shopping cart
5. ⬜ Implement search/filter
6. ⬜ Add product images
7. ⬜ Payment integration
8. ⬜ Order tracking
9. ⬜ Email notifications
10. ⬜ Deploy to production

## Support Resources

- **Firebase Docs**: https://firebase.google.com/docs
- **FlutterFire Docs**: https://firebase.flutter.dev/
- **Flutter Docs**: https://flutter.dev/docs

## Important Notes

⚠️ **Security Rules**: Always use proper security rules in production
⚠️ **Test Mode**: Change from test mode to production rules before launch
⚠️ **API Keys**: Never commit Firebase config files to public repositories
⚠️ **Password Reset**: Implement password reset for production
⚠️ **Email Verification**: Consider adding email verification

---

**Setup Date**: ________________
**Firebase Project ID**: ________________
**Last Updated**: November 26, 2025

