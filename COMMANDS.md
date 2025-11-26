# Commands Cheat Sheet

Quick reference for all commands needed for Firebase setup and app development.

---

## 🚀 Initial Setup Commands

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Install FlutterFire CLI (One-time)
```bash
dart pub global activate flutterfire_cli
```

### 3. Login to Firebase (One-time)
```bash
firebase login
```

### 4. Configure Firebase for Your Project
```bash
flutterfire configure
```
*This will prompt you to select/create a Firebase project*

---

## 🔧 Development Commands

### Run the App
```bash
flutter run
```

### Run on Specific Device
```bash
# List devices
flutter devices

# Run on specific device
flutter run -d <device-id>

# Examples:
flutter run -d chrome        # Web
flutter run -d windows       # Windows
flutter run -d android       # Android emulator
```

### Initialize Sample Users (Run Once)
```bash
flutter run lib/init_firebase.dart
```

### Clean Build
```bash
flutter clean
flutter pub get
flutter run
```

### Update Dependencies
```bash
flutter pub upgrade
```

### Check for Outdated Packages
```bash
flutter pub outdated
```

---

## 🐛 Debugging Commands

### Show Errors
```bash
flutter analyze
```

### Run with Debug Info
```bash
flutter run --verbose
```

### Check Doctor
```bash
flutter doctor
```

### Check Flutter Version
```bash
flutter --version
```

---

## 📱 Platform-Specific Commands

### Android
```bash
# Check Android licenses
flutter doctor --android-licenses

# Build APK
flutter build apk

# Build App Bundle
flutter build appbundle
```

### iOS (macOS only)
```bash
# Install CocoaPods dependencies
cd ios && pod install && cd ..

# Build iOS
flutter build ios

# Open Xcode
open ios/Runner.xcworkspace
```

### Web
```bash
# Run on Chrome
flutter run -d chrome

# Build for web
flutter build web
```

### Windows
```bash
# Build for Windows
flutter build windows
```

---

## 🔥 Firebase Commands

### Initialize Firebase (After installing FlutterFire CLI)
```bash
flutterfire configure
```

### Update Firebase Configuration
```bash
flutterfire configure --project=<project-id>
```

### List Firebase Projects
```bash
firebase projects:list
```

### Select Firebase Project
```bash
firebase use <project-id>
```

---

## 📦 Package Management

### Add a Package
```bash
flutter pub add <package_name>

# Examples:
flutter pub add firebase_core
flutter pub add provider
flutter pub add http
```

### Remove a Package
```bash
flutter pub remove <package_name>
```

### Show Package Tree
```bash
flutter pub deps
```

---

## 🧪 Testing Commands

### Run All Tests
```bash
flutter test
```

### Run Specific Test
```bash
flutter test test/widget_test.dart
```

### Run Tests with Coverage
```bash
flutter test --coverage
```

---

## 🏗️ Build Commands

### Development Build
```bash
flutter run
```

### Release Build (Android)
```bash
flutter build apk --release
flutter build appbundle --release
```

### Release Build (iOS)
```bash
flutter build ios --release
```

### Release Build (Web)
```bash
flutter build web --release
```

### Release Build (Windows)
```bash
flutter build windows --release
```

---

## 🗂️ Project Management

### Create New Flutter Project
```bash
flutter create <project_name>
```

### Format Code
```bash
flutter format .
```

### Generate Files
```bash
flutter pub run build_runner build
```

---

## 📊 Performance Commands

### Profile Mode
```bash
flutter run --profile
```

### Release Mode
```bash
flutter run --release
```

### Measure App Size
```bash
flutter build apk --analyze-size
```

---

## 🔍 Inspection Commands

### List All Devices
```bash
flutter devices
```

### Show SDK Path
```bash
flutter sdk-path
```

### Show Configuration
```bash
flutter config
```

---

## 🎯 Quick Workflow

### First Time Setup
```bash
# 1. Install dependencies
flutter pub get

# 2. Configure Firebase
flutterfire configure

# 3. Initialize sample users
flutter run lib/init_firebase.dart

# 4. Run the app
flutter run
```

### Daily Development
```bash
# Start development
flutter run

# After making changes (if needed)
flutter clean
flutter pub get
flutter run
```

### Before Committing Code
```bash
# Format code
flutter format .

# Check for issues
flutter analyze

# Run tests
flutter test
```

---

## 🆘 Troubleshooting Commands

### Build Issues
```bash
flutter clean
flutter pub get
flutter pub upgrade
flutter run
```

### Android Issues
```bash
# Re-accept licenses
flutter doctor --android-licenses

# Rebuild
flutter clean
cd android && ./gradlew clean && cd ..
flutter run
```

### iOS Issues
```bash
# Reinstall pods
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter run
```

### General Reset
```bash
flutter clean
flutter pub cache clean
flutter pub get
flutter run
```

---

## 📝 Git Commands (Bonus)

### Initialize Git
```bash
git init
git add .
git commit -m "Initial commit with Firebase setup"
```

### Ignore Files
Create `.gitignore` with:
```
# Firebase
firebase_options.dart
google-services.json
GoogleService-Info.plist
.firebase/

# Flutter
build/
.dart_tool/
.packages
```

---

## 🎓 Learning Commands

### Show Flutter Help
```bash
flutter help
```

### Show Command Help
```bash
flutter run --help
flutter build --help
```

### Open Documentation
```bash
flutter doctor -v
```

---

## ⚡ Common Command Sequences

### Full Clean Rebuild
```bash
flutter clean && flutter pub get && flutter run
```

### Update and Run
```bash
flutter pub upgrade && flutter run
```

### Format and Analyze
```bash
flutter format . && flutter analyze
```

### Test and Run
```bash
flutter test && flutter run
```

---

**Quick Tip**: Use `Ctrl+C` to stop a running Flutter app in the terminal.

**Note**: Some commands may require admin/sudo privileges depending on your system configuration.

---

*Last Updated: November 26, 2025*

