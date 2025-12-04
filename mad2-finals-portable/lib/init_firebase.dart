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


    final initializer = FirebaseInitializer();
    await initializer.initializeSampleUsers();


  } catch (e) {
    //Removed Print statement here. Catch does nothing other than that
  }
}

