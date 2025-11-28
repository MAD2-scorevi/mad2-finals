import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<Map<String, dynamic>> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get user data from Firestore
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(result.user!.uid)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        // Check if account is deactivated
        String status = userData['status'] ?? 'active';
        if (status == 'inactive') {
          // Sign out the user immediately
          await _auth.signOut();
          return {
            'success': false,
            'message':
                'This account has been deactivated. Please contact support.',
          };
        }

        return {'success': true, 'user': result.user, 'userData': userData};
      } else {
        return {'success': false, 'message': 'User data not found'};
      }
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getErrorMessage(e.code)};
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred. Please try again.',
      };
    }
  }

  // Register new user
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required String address,
    required String dateOfBirth,
    String role = 'user', // Default role is 'user'
  }) async {
    try {
      // Create user account
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Store user data in Firestore
      await _firestore.collection('users').doc(result.user!.uid).set({
        'uid': result.user!.uid,
        'email': email,
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'address': address,
        'dateOfBirth': dateOfBirth,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'user': result.user,
        'message': 'Account created successfully',
      };
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getErrorMessage(e.code)};
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred. Please try again.',
      };
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get user role
  Future<String?> getUserRole(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return data['role'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Update user data
  Future<bool> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Delete current user's account (self-delete)
  // Only the logged-in user can delete their own account
  Future<Map<String, dynamic>> deleteMyAccount(String password) async {
    try {
      print('DELETE ACCOUNT: Starting account deletion');
      final user = _auth.currentUser;
      if (user == null) {
        print('DELETE ACCOUNT ERROR: No user signed in');
        return {'success': false, 'message': 'No user is currently signed in'};
      }

      final userEmail = user.email!;
      final userId = user.uid;
      print('DELETE ACCOUNT: User found: $userEmail (UID: $userId)');

      // Re-authenticate is REQUIRED for user.delete() to work
      // Try with a timeout, but if it fails, use alternative approach
      print(
        'DELETE ACCOUNT: Re-authenticating user (required for Auth deletion)...',
      );
      bool reauthSuccess = false;

      try {
        final credential = EmailAuthProvider.credential(
          email: userEmail,
          password: password,
        );
        await user
            .reauthenticateWithCredential(credential)
            .timeout(const Duration(seconds: 5));
        print('DELETE ACCOUNT: Re-authentication successful');
        reauthSuccess = true;
      } catch (e) {
        print('DELETE ACCOUNT: Re-auth failed or timed out: $e');
        // Will try alternative approach below
      }

      // If re-auth failed, try signing in fresh to get a new authenticated session
      if (!reauthSuccess) {
        print('DELETE ACCOUNT: Attempting fresh sign-in for authentication...');
        try {
          await _auth.signInWithEmailAndPassword(
            email: userEmail,
            password: password,
          );
          print('DELETE ACCOUNT: Fresh sign-in successful');
        } catch (e) {
          print(
            'DELETE ACCOUNT ERROR: Could not authenticate with provided password',
          );
          return {
            'success': false,
            'message': 'Invalid password. Please try again.',
          };
        }
      }

      // Get the current user again (in case we re-signed in)
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('DELETE ACCOUNT ERROR: User session lost');
        return {
          'success': false,
          'message': 'User session lost. Please try again.',
        };
      }

      // Delete Firestore user document FIRST (while user is still authenticated)
      print('DELETE ACCOUNT: Deleting Firestore document for UID: $userId...');
      try {
        await _firestore.collection('users').doc(userId).delete();
        print('DELETE ACCOUNT: Firestore document deleted');
      } catch (e) {
        print('DELETE ACCOUNT ERROR: Failed to delete Firestore document: $e');
        return {'success': false, 'message': 'Failed to delete user data: $e'};
      }

      // Delete Firebase Auth account LAST (after Firestore is cleaned up)
      print(
        'DELETE ACCOUNT: Deleting Firebase Auth account for UID: ${currentUser.uid}...',
      );
      try {
        await currentUser.delete();
        print('DELETE ACCOUNT: Firebase Auth account deleted successfully');
      } catch (e) {
        print(
          'DELETE ACCOUNT ERROR: Firestore deleted but Auth deletion failed: $e',
        );
        return {
          'success': false,
          'message':
              'User data deleted but authentication account could not be removed. Please contact support.',
        };
      }

      print('DELETE ACCOUNT: Account deletion completed successfully');
      return {'success': true, 'message': 'Account deleted successfully'};
    } on FirebaseAuthException catch (e) {
      print(
        'DELETE ACCOUNT ERROR: FirebaseAuthException - ${e.code}: ${e.message}',
      );
      return {'success': false, 'message': _getErrorMessage(e.code)};
    } catch (e, stackTrace) {
      print('DELETE ACCOUNT ERROR: $e');
      print('Stack trace: $stackTrace');
      return {'success': false, 'message': 'Failed to delete account: $e'};
    }
  }

  // Helper method to get user-friendly error messages
  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'weak-password':
        return 'The password is too weak.';
      case 'operation-not-allowed':
        return 'Operation not allowed. Please contact support.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
