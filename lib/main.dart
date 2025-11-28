import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';

import 'login_page.dart';
import 'admin_dashboard.dart';
import 'products.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Suppress keyboard event errors in debug mode
  FlutterError.onError = (FlutterErrorDetails details) {
    if (details.toString().contains('_LpressedKeys.containsKey') ||
        details.toString().contains('physical key is already pressed')) {
      // Ignore these keyboard tracking errors
      return;
    }
    FlutterError.presentError(details);
  };

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // DEFAULT SCREEN
      initialRoute: "/login",

      // ROUTES
      routes: {
        "/login": (context) => LoginPage(),
        "/admin": (context) => AdminDashboard(),
        "/products": (context) => ProductsPage(),
      },
    );
  }
}

// Updated for deployment
