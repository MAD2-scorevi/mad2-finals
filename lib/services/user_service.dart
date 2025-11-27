import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserManageable{
  final String id;
  final String createdAt;
  final String email;
  
  UserManageable({
    required this.id,
    required this.createdAt,
    required this.email,
  });

  factory UserManageable.fromFirestore(DocumentSnapshot doc){
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
    );
  }
}

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<UserManageable>> getUsers({int limit = 20}){
    return _firestore
      .collection('users')
      .orderBy('createdAt', descending: true)
      .limit(20)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
          .map((doc){
            print(doc.data());
            return UserManageable.fromFirestore(doc);}
            )
          .toList(),
      );
  }
  // Future<void> addUser(String email);
  // Future<void> removeUser(String id);
}