# MAD2 Finals - Portable Setup Instructions

## Quick Setup for Testing on Another Computer

### Prerequisites
- Flutter SDK installed (3.35.4 or later)
- Dart SDK (3.9.2 or later)
- Android Studio or VS Code with Flutter extension
- Firebase CLI (optional, for Firebase deployment)

### Setup Steps

1. **Install Dependencies**
   ```bash
   flutter pub get
   ```

2. **Configure Firebase**
   - The `google-services.json` file is included
   - Firebase config is in `lib/firebase_options.dart`
   - Firestore rules are in `firestore.rules`

3. **Run the App**
   ```bash
   # On connected device/emulator
   flutter run

   # On specific device
   flutter run -d <device-id>

   # Check available devices
   flutter devices
   ```

4. **Build for Production**
   ```bash
   # Universal APK
   flutter build apk --release

   # Split APKs (smaller)
   flutter build apk --split-per-abi
   ```

### Project Structure
```
lib/
├── main.dart                      # App entry point
├── login_page.dart                # Login screen
├── registration.dart              # User registration
├── admin_dashboard.dart           # Admin interface
├── product_owner_dashboard.dart   # Product owner interface
├── inventory_management_page.dart # Inventory management
├── manage_admins_page.dart        # Admin management
├── order_history_page.dart        # Order history
├── products.dart                  # Product catalog
├── firebase_options.dart          # Firebase configuration
├── init_firebase.dart             # Firebase initialization
├── services/                      # Backend services
└── utils/                         # Utility functions
```

### Key Features
- Firebase Authentication (email/password)
- Cloud Firestore database
- Real-time inventory management
- Admin dashboard with user management
- Product catalog with search and filtering
- Order history tracking
- Role-based access control

### Default Admin Credentials
Set up admin users through Firebase Console or registration flow.

### Troubleshooting
- If dependencies fail: `flutter clean && flutter pub get`
- If build fails: Delete `build` folder and rebuild
- For Firebase issues: Check `google-services.json` is in place

### Notes
- This is a portable version containing only source code and dependencies
- The full project includes platform-specific build folders (android/, ios/, etc.)
- For deployment, you'll need to configure signing keys in Android/iOS projects
