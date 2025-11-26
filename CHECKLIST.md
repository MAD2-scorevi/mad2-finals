# Firebase Setup Checklist

Use this checklist to ensure you've completed all the necessary steps.

## ☐ Step 1: Install Dependencies

- [ ] Open terminal in project directory
- [ ] Run `flutter pub get`
- [ ] Verify no errors in terminal output

## ☐ Step 2: Firebase Project Setup

- [ ] Go to [Firebase Console](https://console.firebase.google.com/)
- [ ] Create new project or select existing one
- [ ] Note your Firebase Project ID: mad2-finals
- [ ] Project Number: 19273889378

## ☐ Step 3: Configure Firebase

Choose ONE method:

### Option A: FlutterFire CLI (Recommended)
- [ ] Install FlutterFire CLI: `dart pub global activate flutterfire_cli`
- [ ] Login to Firebase: `firebase login`
- [ ] Run: `flutterfire configure`
- [ ] Select your Firebase project
- [ ] Select platforms (Android, iOS, Web, etc.)
- [ ] Verify `lib/firebase_options.dart` was updated

### Option B: Manual Setup
- [ ] Add Android app in Firebase Console
- [ ] Download and place `google-services.json` in `android/app/`
- [ ] Add iOS app in Firebase Console  
- [ ] Download and place `GoogleService-Info.plist` in `ios/Runner/`
- [ ] Add Web app and copy configuration
- [ ] Update `lib/firebase_options.dart` with your credentials

## ☐ Step 4: Enable Authentication

- [ ] Go to Firebase Console → Build → Authentication
- [ ] Click "Get Started"
- [ ] Enable "Email/Password" sign-in method
- [ ] Click "Save"

## ☐ Step 5: Create Firestore Database

- [ ] Go to Firebase Console → Build → Firestore Database
- [ ] Click "Create Database"
- [ ] Select "Start in test mode"
- [ ] Choose location: ________________
- [ ] Click "Enable"
- [ ] Wait for database to be created

## ☐ Step 6: Set Security Rules

- [ ] Go to Firestore Database → Rules tab
- [ ] Open `firestore.rules` file in your project
- [ ] Copy all content from the file
- [ ] Paste into Firebase Console Rules editor
- [ ] Click "Publish"
- [ ] Verify rules are active

## ☐ Step 7: Initialize Sample Users

- [ ] Run: `flutter run lib/init_firebase.dart`
- [ ] Wait for completion message
- [ ] Verify in Firebase Console → Authentication:
  - [ ] sample.user@gmail.com exists
  - [ ] sample.admin@gmail.com exists
  - [ ] sample.owner@gmail.com exists
- [ ] Verify in Firebase Console → Firestore Database:
  - [ ] "users" collection exists
  - [ ] 3 user documents exist with correct data

## ☐ Step 8: Test the Application

- [ ] Run: `flutter run` (or use IDE run button)
- [ ] App launches without errors
- [ ] Test User Login:
  - [ ] Email: sample.user@gmail.com
  - [ ] Password: sampleuser
  - [ ] Navigates to Products Page
- [ ] Test Admin Login:
  - [ ] Email: sample.admin@gmail.com
  - [ ] Password: sampleadmin  
  - [ ] Navigates to Admin Dashboard
- [ ] Test Owner Login:
  - [ ] Email: sample.owner@gmail.com
  - [ ] Password: sampleowner
  - [ ] Navigates to Product Owner Dashboard

## ☐ Step 9: Test Registration

- [ ] Tap "Create Account" or navigate to registration
- [ ] Fill in all fields:
  - [ ] Full Name
  - [ ] Email Address
  - [ ] Password
  - [ ] Phone Number
  - [ ] Address
  - [ ] Date of Birth
- [ ] Click "Register"
- [ ] Verify success message
- [ ] Check Firebase Console → Authentication (new user added)
- [ ] Check Firebase Console → Firestore (new user document)
- [ ] Try logging in with new account

## ☐ Step 10: Verify Security

- [ ] Logged in as regular user → Can access Products Page
- [ ] Logged in as admin → Can access Admin Dashboard
- [ ] Logged in as owner → Can access Product Owner Dashboard
- [ ] User data saved correctly in Firestore
- [ ] User role determines navigation correctly

## Common Issues & Solutions

### ❌ Firebase not initialized
**Solution:** 
- Run `flutterfire configure`
- Check `firebase_options.dart` has actual values (not placeholders)

### ❌ Authentication failed
**Solution:**
- Verify Email/Password is enabled in Firebase Console
- Check sample users were created successfully
- Try creating a new account via registration

### ❌ Permission denied
**Solution:**
- Publish security rules in Firebase Console
- Verify user has correct role in Firestore
- Check rules syntax is correct

### ❌ Build errors
**Solution:**
```bash
flutter clean
flutter pub get
flutter run
```

### ❌ Sample users not created
**Solution:**
- Check Firebase Console → Authentication is enabled
- Run init script again: `flutter run lib/init_firebase.dart`
- Manually create users in Firebase Console if needed

## Verification Checklist

After completing all steps, verify:

- [ ] ✅ Firebase project created
- [ ] ✅ Firebase configured for your app
- [ ] ✅ Authentication enabled
- [ ] ✅ Firestore database created
- [ ] ✅ Security rules published
- [ ] ✅ Sample users exist in Authentication
- [ ] ✅ Sample users exist in Firestore with correct roles
- [ ] ✅ App runs without errors
- [ ] ✅ Login works for all sample accounts
- [ ] ✅ Navigation is correct based on user role
- [ ] ✅ Registration works and creates new users
- [ ] ✅ User data is stored in Firestore

## You're Done! 🎉

If all items are checked, your Firebase setup is complete and working!

### What's Configured:

✅ **Firebase Core** - Project connected to Firebase
✅ **Authentication** - Email/Password login
✅ **Firestore Database** - User data storage
✅ **Security Rules** - Role-based access control
✅ **Sample Accounts** - 3 test users (user, admin, owner)
✅ **Registration** - New user creation
✅ **Login** - Authentication with role-based navigation

### Next Steps:

1. Start building additional features
2. Add more collections (products, orders, etc.)
3. Implement product management
4. Add order functionality
5. Enhance UI/UX
6. Deploy your app

---

**Date Completed:** ________________

**Notes:**
_________________________________________________
_________________________________________________
_________________________________________________ 

