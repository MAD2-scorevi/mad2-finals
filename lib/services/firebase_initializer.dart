import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// This script initializes sample users in Firebase
/// Run this once to create the sample accounts
class FirebaseInitializer {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initializeSampleUsers() async {
    print('Starting Firebase initialization...');

    // Sample users data
    final sampleUsers = [
      {
        'email': 'sample.user@gmail.com',
        'password': 'sampleuser',
        'fullName': 'Sample User',
        'phoneNumber': '+63 912 345 6789',
        'address': 'Sample Address, Manila, Philippines',
        'dateOfBirth': '1/1/2000',
        'role': 'user',
      },
      {
        'email': 'sample.admin@gmail.com',
        'password': 'sampleadmin',
        'fullName': 'Sample Admin',
        'phoneNumber': '+63 912 345 6790',
        'address': 'Admin Address, Manila, Philippines',
        'dateOfBirth': '1/1/1995',
        'role': 'admin',
      },
      {
        'email': 'sample.owner@gmail.com',
        'password': 'sampleowner',
        'fullName': 'Sample Owner',
        'phoneNumber': '+63 912 345 6791',
        'address': 'Owner Address, Manila, Philippines',
        'dateOfBirth': '1/1/1990',
        'role': 'owner',
      },
    ];

    for (var userData in sampleUsers) {
      try {
        print('Creating user: ${userData['email']}...');

        // Check if user already exists
        final existingUsers = await _auth.fetchSignInMethodsForEmail(
          userData['email'] as String,
        );

        if (existingUsers.isNotEmpty) {
          print('User ${userData['email']} already exists. Skipping...');
          continue;
        }

        // Create user
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: userData['email'] as String,
          password: userData['password'] as String,
        );

        // Store user data in Firestore
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'email': userData['email'],
          'fullName': userData['fullName'],
          'phoneNumber': userData['phoneNumber'],
          'address': userData['address'],
          'dateOfBirth': userData['dateOfBirth'],
          'role': userData['role'],
          'createdAt': FieldValue.serverTimestamp(),
        });

        print('✓ Successfully created: ${userData['email']} (${userData['role']})');
      } catch (e) {
        print('✗ Error creating ${userData['email']}: $e');
      }
    }

    print('\nFirebase initialization completed!');
    print('\nSample Users:');
    print('─────────────────────────────────────────────────');
    print('User Role  | Email                    | Password');
    print('─────────────────────────────────────────────────');
    print('User       | sample.user@gmail.com    | sampleuser');
    print('Admin      | sample.admin@gmail.com   | sampleadmin');
    print('Owner      | sample.owner@gmail.com   | sampleowner');
    print('─────────────────────────────────────────────────');

    // Sign out after initialization
    await _auth.signOut();
  }

  /// Setup Firestore security rules (for reference)
  /// You need to set these rules in Firebase Console manually
  static String getSecurityRules() {
    return '''
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper function to check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Helper function to get user role
    function getUserRole() {
      return get(/databases/\$(database)/documents/users/\$(request.auth.uid)).data.role;
    }
    
    // Helper function to check if user is admin
    function isAdmin() {
      return isAuthenticated() && getUserRole() == 'admin';
    }
    
    // Helper function to check if user is owner
    function isOwner() {
      return isAuthenticated() && getUserRole() == 'owner';
    }
    
    // Helper function to check if user is regular user
    function isUser() {
      return isAuthenticated() && getUserRole() == 'user';
    }
    
    // Users collection
    match /users/{userId} {
      // Users can read their own data
      allow read: if isAuthenticated() && request.auth.uid == userId;
      
      // Admins can read all users
      allow read: if isAdmin();
      
      // Users can update their own data (except role)
      allow update: if isAuthenticated() && request.auth.uid == userId 
                    && !request.resource.data.diff(resource.data).affectedKeys().hasAny(['role', 'uid']);
      
      // Admins can update any user
      allow update: if isAdmin();
      
      // Only system can create users (through Firebase Auth)
      allow create: if isAuthenticated() && request.auth.uid == userId;
      
      // Admins can delete users
      allow delete: if isAdmin();
    }
    
    // Products collection (example)
    match /products/{productId} {
      // Everyone can read products
      allow read: if true;
      
      // Only owners and admins can create, update, delete products
      allow create, update, delete: if isOwner() || isAdmin();
    }
    
    // Orders collection (example)
    match /orders/{orderId} {
      // Users can read their own orders
      allow read: if isAuthenticated() && resource.data.userId == request.auth.uid;
      
      // Admins and owners can read all orders
      allow read: if isAdmin() || isOwner();
      
      // Users can create their own orders
      allow create: if isAuthenticated() && request.resource.data.userId == request.auth.uid;
      
      // Users can update their own orders (cancel, etc.)
      allow update: if isAuthenticated() && resource.data.userId == request.auth.uid;
      
      // Admins and owners can update any order
      allow update: if isAdmin() || isOwner();
      
      // Only admins can delete orders
      allow delete: if isAdmin();
    }
  }
}
    ''';
  }
}

