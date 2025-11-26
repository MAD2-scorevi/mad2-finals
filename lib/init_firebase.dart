import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/firebase_initializer.dart';

/// This is a utility script to initialize Firebase with sample users
/// Run this once using: flutter run lib/init_firebase.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    print('\n══════════════════════════════════════════════════');
    print('  Firebase Database Initialization Script');
    print('══════════════════════════════════════════════════\n');

    final initializer = FirebaseInitializer();
    await initializer.initializeSampleUsers();

    print('\n══════════════════════════════════════════════════');
    print('  Initialization Complete!');
    print('══════════════════════════════════════════════════\n');

    print('Next Steps:');
    print('1. Set up Firestore Security Rules in Firebase Console');
    print('2. Copy the security rules from firebase_initializer.dart');
    print('3. Test login with the sample accounts\n');

  } catch (e) {
    print('Error initializing Firebase: $e');
  }
}

