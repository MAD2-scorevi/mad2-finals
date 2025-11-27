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
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Tested. At least this works
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

  // Untested. Research says that if you try to use the following 
  // it would sign you out and sign you in as the following
  Future<void> addUser({required String email}) async{
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: "abcd123");
    } catch (e) {
      throw StateError("Error adding user $email: $e");
    }
  }

  // I don't think you can delete any user, just your self so this might not work? 
  // Please advise on what to do
  Future<void> removeUser({required String id})async{
    // The lines below do nothing so commented but I want you to know I tried.
      // final user = _auth.currentUser;
      // if(user == null) return;
    try {
      // Untested. Nadedelete lang ata iyung users collection but not the firestore auth users
      await _firestore.collection('users').doc(id).delete(); //???
    } catch (e) {
      throw StateError("Error deleting $id: $e");
    }
  }
}