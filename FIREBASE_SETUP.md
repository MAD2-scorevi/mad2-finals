# Firebase Setup Guide

This guide will help you set up Firebase Authentication and Firestore Database for the MAD2 Finals project.

## Prerequisites

1. A Google/Firebase account
2. Flutter SDK installed
3. Firebase CLI (optional but recommended)

## Step 1: Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add Project" or select an existing project
3. Enter a project name (e.g., "mad2-finals")
4. Follow the setup wizard

## Step 2: Enable Authentication

1. In Firebase Console, go to **Build** → **Authentication**
2. Click "Get Started"
3. Enable **Email/Password** sign-in method
4. Click "Save"

## Step 3: Create Firestore Database

1. In Firebase Console, go to **Build** → **Firestore Database**
2. Click "Create Database"
3. Choose **Start in test mode** (we'll update rules later)
4. Select a location closest to your users
5. Click "Enable"

## Step 4: Register Your Flutter App

### For Android:
1. In Firebase Console, click the Android icon
2. Enter your package name (found in `android/app/build.gradle.kts`)
3. Download `google-services.json`
4. Place it in `android/app/` directory
5. Follow the Firebase setup instructions

### For iOS:
1. In Firebase Console, click the iOS icon
2. Enter your bundle ID (found in `ios/Runner.xcodeproj/project.pbxproj`)
3. Download `GoogleService-Info.plist`
4. Place it in `ios/Runner/` directory

### For Web:
1. In Firebase Console, click the Web icon
2. Register your app
3. Copy the configuration

## Step 5: Install Dependencies

Run the following command in your terminal:

```bash
flutter pub get
```

This will install all Firebase dependencies defined in `pubspec.yaml`:
- firebase_core
- firebase_auth
- cloud_firestore
- intl

## Step 6: Configure Firebase for Flutter

### Option A: Using FlutterFire CLI (Recommended)

1. Install FlutterFire CLI:
```bash
dart pub global activate flutterfire_cli
```

2. Configure Firebase:
```bash
flutterfire configure
```

3. Select your Firebase project and platforms
4. This will generate/update `lib/firebase_options.dart` with your actual configuration

### Option B: Manual Configuration

Edit `lib/firebase_options.dart` and replace the placeholder values with your actual Firebase project configuration from the Firebase Console.

## Step 7: Initialize Sample Users

Run the initialization script to create sample users:

```bash
flutter run lib/init_firebase.dart
```

This will create three sample accounts:

| Role  | Email                    | Password     |
|-------|--------------------------|--------------|
| User  | sample.user@gmail.com    | sampleuser   |
| Admin | sample.admin@gmail.com   | sampleadmin  |
| Owner | sample.owner@gmail.com   | sampleowner  |

## Step 8: Set Up Firestore Security Rules

1. Go to **Firestore Database** → **Rules** in Firebase Console
2. Copy the security rules from `lib/services/firebase_initializer.dart` (see `getSecurityRules()` method)
3. Paste them in the Firebase Console
4. Click "Publish"

### Security Rules Summary:

- **Users Collection**: 
  - Users can read/update their own data
  - Admins can read/update all users
  - Role field is protected from modification

- **Products Collection** (example):
  - Everyone can read products
  - Only owners and admins can create/update/delete

- **Orders Collection** (example):
  - Users can read their own orders
  - Admins and owners can read all orders
  - Users can create their own orders
  - Only admins can delete orders

## Step 9: Database Structure

### Users Collection (`users`)

Each user document contains:

```json
{
  "uid": "firebase-user-id",
  "email": "user@example.com",
  "fullName": "John Doe",
  "phoneNumber": "+63 912 345 6789",
  "address": "Street, City, Province",
  "dateOfBirth": "1/1/2000",
  "role": "user|admin|owner",
  "createdAt": "timestamp"
}
```

### User Roles:

- **user**: Regular customers who can browse and purchase products
- **admin**: Administrators who can manage users and system settings
- **owner**: Product owners who can manage products and orders

## Step 10: Test the Application

1. Run your Flutter app:
```bash
flutter run
```

2. Try logging in with one of the sample accounts
3. Verify role-based navigation:
   - User → Products Page
   - Admin → Admin Dashboard
   - Owner → Product Owner Dashboard

## Troubleshooting

### Common Issues:

1. **Firebase not initialized**: Make sure you've run `flutterfire configure`
2. **Authentication fails**: Check Firebase Console Authentication section is enabled
3. **Firestore permission denied**: Verify security rules are published
4. **Build errors**: Run `flutter clean && flutter pub get`

### Platform-Specific Issues:

**Android:**
- Make sure `google-services.json` is in `android/app/`
- Check `android/app/build.gradle.kts` has the Google Services plugin

**iOS:**
- Make sure `GoogleService-Info.plist` is in `ios/Runner/`
- Run `pod install` in the `ios` directory

**Web:**
- Configure web credentials in `lib/firebase_options.dart`

## Additional Configuration

### Multi-Factor Authentication (Optional)
You can enable MFA in Firebase Console → Authentication → Sign-in method → Advanced

### Email Verification (Optional)
Add email verification in the registration flow using:
```dart
await FirebaseAuth.instance.currentUser?.sendEmailVerification();
```

### Password Reset
The "Forgot Password" feature can be implemented using:
```dart
await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
```

## Testing

To test the complete flow:

1. **Registration**: Create a new account from the registration page
2. **Login**: Log in with the created account or sample accounts
3. **Role-based Access**: Verify navigation based on user role
4. **Data Persistence**: Check that user data is stored in Firestore

## Next Steps

1. Implement additional features (products, orders, etc.)
2. Add more collections to Firestore as needed
3. Update security rules for new collections
4. Implement proper error handling and user feedback
5. Add loading states and form validation
6. Consider adding offline support with Firestore persistence

## Resources

- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
- [Firebase Authentication](https://firebase.google.com/docs/auth)

## Support

If you encounter any issues:
1. Check the Firebase Console for errors
2. Review the Flutter console output
3. Verify all configuration files are in place
4. Make sure all dependencies are installed

