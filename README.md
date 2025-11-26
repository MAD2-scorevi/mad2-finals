# Quick Start Guide

## Firebase Setup Complete! 🎉

All the necessary files have been created and configured. Follow these steps to get your app running with Firebase.

## Step 1: Install Dependencies

Open your terminal in the project directory and run:

```bash
flutter pub get
```

This will install all Firebase dependencies:
- firebase_core
- firebase_auth  
- cloud_firestore
- intl

## Step 2: Configure Firebase

You need to configure Firebase for your specific project. Choose one of the methods below:

### Method A: Using FlutterFire CLI (Recommended) ⭐

1. Install FlutterFire CLI:
```bash
dart pub global activate flutterfire_cli
```

2. Login to Firebase (if not already logged in):
```bash
firebase login
```

3. Configure Firebase for this project:
```bash
flutterfire configure
```

4. Follow the prompts:
   - Select or create a Firebase project
   - Select platforms you want to support (Android, iOS, Web, etc.)
   - This will automatically generate the correct `firebase_options.dart` file

### Method B: Manual Configuration

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create or select a project
3. Add your Flutter app for each platform
4. Download configuration files:
   - **Android**: Download `google-services.json` → place in `android/app/`
   - **iOS**: Download `GoogleService-Info.plist` → place in `ios/Runner/`
5. Copy the configuration values from Firebase Console into `lib/firebase_options.dart`

## Step 3: Enable Firebase Services

In the [Firebase Console](https://console.firebase.google.com/):

1. **Enable Authentication**:
   - Go to Build → Authentication
   - Click "Get Started"
   - Enable "Email/Password" sign-in method
   - Save

2. **Create Firestore Database**:
   - Go to Build → Firestore Database
   - Click "Create Database"
   - Choose "Start in test mode" (we'll add security rules next)
   - Select your preferred location
   - Click "Enable"

## Step 4: Set Up Security Rules

1. In Firebase Console, go to Firestore Database → Rules
2. Copy the content from the `firestore.rules` file in this project
3. Paste it into the Firebase Console
4. Click "Publish"

These rules implement role-based access control:
- **Users**: Can read/update their own data
- **Admins**: Can manage all users and data
- **Owners**: Can manage products and orders

## Step 5: Initialize Sample Users

Run the initialization script to create sample user accounts:

```bash
flutter run lib/init_firebase.dart
```

This will create three accounts:

| Role  | Email                    | Password     | Access                    |
|-------|--------------------------|--------------|---------------------------|
| User  | sample.user@gmail.com    | sampleuser   | Products Page             |
| Admin | sample.admin@gmail.com   | sampleadmin  | Admin Dashboard           |
| Owner | sample.owner@gmail.com   | sampleowner  | Product Owner Dashboard   |

## Step 6: Run the App

Now you can run your main app:

```bash
flutter run
```

Or use your IDE's run button.

## Testing

Try logging in with the sample accounts:

1. **User Account** → Should navigate to Products Page
2. **Admin Account** → Should navigate to Admin Dashboard  
3. **Owner Account** → Should navigate to Product Owner Dashboard

## Project Structure

```
lib/
├── main.dart                          # Main app entry point (Firebase initialized)
├── login_page.dart                    # Login with Firebase Auth
├── registration.dart                  # Register new users to Firebase
├── admin_dashboard.dart               # Admin interface
├── product_owner_dashboard.dart       # Owner interface
├── products.dart                      # User/Customer interface
├── firebase_options.dart              # Firebase configuration
├── init_firebase.dart                 # Sample user initialization script
└── services/
    ├── firebase_auth_service.dart     # Authentication service
    └── firebase_initializer.dart      # Database initialization
```

## Features Implemented

✅ Firebase Authentication (Email/Password)
✅ Firestore Database integration
✅ User registration with profile data
✅ Role-based access control (user, admin, owner)
✅ Secure login with role-based navigation
✅ User data storage in Firestore
✅ Firestore security rules
✅ Sample user accounts

## Database Schema

### Users Collection

```javascript
{
  "uid": "firebase-user-id",
  "email": "user@example.com",
  "fullName": "John Doe",
  "phoneNumber": "+63 912 345 6789",
  "address": "Street, City, Province",
  "dateOfBirth": "1/1/2000",
  "role": "user|admin|owner",
  "createdAt": Timestamp
}
```

## Troubleshooting

### "Firebase not initialized" error
- Make sure you ran `flutterfire configure` or manually added configuration files
- Verify `firebase_options.dart` has your actual project configuration

### "Authentication failed" error  
- Check that Email/Password authentication is enabled in Firebase Console
- Verify the sample users were created (check Firebase Console → Authentication)

### "Permission denied" error
- Make sure you published the security rules in Firebase Console
- Verify the user has the correct role in Firestore

### Build errors
```bash
flutter clean
flutter pub get
flutter run
```

### Platform-specific issues

**Android:**
- Ensure `google-services.json` is in `android/app/`
- Check minimum SDK version is 21 or higher

**iOS:**
- Ensure `GoogleService-Info.plist` is in `ios/Runner/`
- Run `pod install` in the `ios/` directory

**Web:**
- Make sure web configuration is added to `firebase_options.dart`

## Next Steps

1. ✅ Run `flutter pub get`
2. ✅ Run `flutterfire configure`
3. ✅ Enable Authentication in Firebase Console
4. ✅ Create Firestore Database
5. ✅ Publish security rules
6. ✅ Run initialization script: `flutter run lib/init_firebase.dart`
7. ✅ Run the main app: `flutter run`
8. ✅ Test login with sample accounts

## Additional Resources

- 📖 [Full Setup Guide](FIREBASE_SETUP.md) - Detailed step-by-step instructions
- 🔐 [Security Rules](firestore.rules) - Complete Firestore security rules
- 🔧 [Firebase Auth Service](lib/services/firebase_auth_service.dart) - Authentication methods
- 🎯 [Firebase Initializer](lib/services/firebase_initializer.dart) - Database setup

## Need Help?

- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- Check Firebase Console for error logs
- Review Flutter console output for error details

---

**Happy Coding! 🚀**

