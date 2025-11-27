import 'package:cloud_firestore/cloud_firestore.dart';

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

  // NOTE: Cannot create Firebase Auth users from client app without signing out current user.
  // Users must register through the normal registration page.
  // If you need admin-created accounts, implement Firebase Cloud Functions with Admin SDK.

  // Soft delete - marks user as inactive instead of deleting
  // Cannot delete Firebase Auth user from client (requires Admin SDK)
  Future<void> deactivateUser({required String id}) async {
    try {
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
  }) async {
    try {
      await _firestore.collection('users').doc(id).update(updates);
    } catch (e) {
      throw StateError("Error updating user $id: $e");
    }
  }
}
