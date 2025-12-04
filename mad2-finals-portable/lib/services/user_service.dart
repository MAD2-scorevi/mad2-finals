import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserManageable {
  final String id;
  final String createdAt;
  final String email;
  final String fullName;
  final String phoneNumber;
  final String address;
  final String dateOfBirth;
  final String role;
  final String status;

  UserManageable({
    required this.id,
    required this.createdAt,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    required this.address,
    required this.dateOfBirth,
    required this.role,
    required this.status,
  });

  factory UserManageable.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final rawCreatedAt = data['createdAt'];
    if (rawCreatedAt == null) {
      throw StateError("Doc ${doc.id} missing field 'createdAt'");
    }

    final createdAt = rawCreatedAt is Timestamp
        ? rawCreatedAt.toDate().toIso8601String()
        : rawCreatedAt.toString();

    final email = data['email'];
    if (email == null) {
      throw StateError("Doc ${doc.id} missing field 'email'");
    }
    return UserManageable(
      id: doc.id,
      createdAt: createdAt,
      email: data['email'],
      fullName: data['fullName'] ?? 'N/A',
      phoneNumber: data['phoneNumber'] ?? 'N/A',
      address: data['address'] ?? 'N/A',
      dateOfBirth: data['dateOfBirth'] ?? 'N/A',
      role: data['role'] ?? 'user',
      status: data['status'] ?? 'active',
    );
  }
}

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get all regular users (excluding admins, owners, and inactive users)
  Stream<List<UserManageable>> getUsers({int limit = 20}) {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'user')
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          final users = snapshot.docs
              .map((doc) => UserManageable.fromFirestore(doc))
              .where((user) => user.status != 'inactive')
              .toList();

          // Sort by createdAt in Dart (descending)
          users.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return users;
        });
  }

  // Add a new user - creates Firebase Auth account AND Firestore document
  // Note: Creates user while keeping admin session active
  // Default password: "Welcome123!" - user should change on first login
  Future<String> addUser({
    required String email,
    required String adminEmail,
    required String adminPassword,
    String fullName = '',
    String phoneNumber = '',
    String address = '',
    String password = 'Welcome123!',
  }) async {
    try {

      // Store current admin user
      final currentAdmin = _auth.currentUser;
      if (currentAdmin == null) {
        throw StateError('No admin is currently signed in');
      }

      // Create Firebase Auth user (this will temporarily switch the auth context)
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final newUserId = userCredential.user!.uid;

      // Create Firestore document with the Auth UID
      await _firestore.collection('users').doc(newUserId).set({
        'email': email,
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'address': address,
        'role': 'user',
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Sign out the newly created user
      await _auth.signOut();

      // Re-authenticate as admin
      await _auth.signInWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );

      return newUserId;
    } catch (e) {
      // Try to sign out and re-auth admin in case of error
      try {
        await _auth.signOut();
        await _auth.signInWithEmailAndPassword(
          email: adminEmail,
          password: adminPassword,
        );
      } catch (authError) {
        //Removed Print statement here. Catch does nothing other than that
      }
      throw StateError("Error adding user $email: $e");
    }
  }

  // Deactivate user - marks Firestore as inactive
  // Note: Firebase Auth accounts cannot be deleted without Admin SDK
  // The account remains in Firebase Auth but cannot access the system
  // because Firestore marks it as 'inactive'
  Future<void> deactivateUser({
    required String id,
    required String adminEmail,
    required String adminPassword,
  }) async {
    try {

      // Get current user
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw StateError('No user is currently signed in');
      }

      // Verify credentials match current user (case-insensitive)
      if (currentUser.email?.toLowerCase() != adminEmail.toLowerCase()) {
        throw StateError('Provided credentials do not match current user');
      }

      // Note: Skipping reauthentication as it times out on Windows desktop
      // The admin is already authenticated and we trust the current session

      // Check if user has admin role
      final adminDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final role = adminDoc.data()?['role'];

      if (role != 'admin' && role != 'product_owner') {
        throw StateError(
          'Access denied: Only admin or product owner can perform this action',
        );
      }

      // Mark as inactive in Firestore
      await _firestore.collection('users').doc(id).update({
        'status': 'inactive',
        'deactivatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw StateError("Error deactivating user $id: $e");
    }
  }

  // Reactivate a deactivated user
  Future<void> reactivateUser({required String id}) async {
    try {
      await _firestore.collection('users').doc(id).update({
        'status': 'active',
        'reactivatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw StateError("Error reactivating user $id: $e");
    }
  }

  // Update user profile information
  Future<void> updateUserProfile({
    required String id,
    required Map<String, dynamic> updates,
    required String adminEmail,
    required String adminPassword,
  }) async {
    try {

      // Get current user
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw StateError('No user is currently signed in');
      }

      // Verify credentials match current user (case-insensitive)
      if (currentUser.email?.toLowerCase() != adminEmail.toLowerCase()) {
        throw StateError('Provided credentials do not match current user');
      }

      // Note: Skipping reauthentication as it times out on Windows desktop
      // The admin is already authenticated and we trust the current session

      // Check if user has admin role
      final adminDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final role = adminDoc.data()?['role'];

      if (role != 'admin' && role != 'product_owner') {
        throw StateError(
          'Access denied: Only admin or product owner can perform this action',
        );
      }

      await _firestore.collection('users').doc(id).update(updates);
    } catch (e) {
      throw StateError("Error updating user $id: $e");
    }
  }
}
