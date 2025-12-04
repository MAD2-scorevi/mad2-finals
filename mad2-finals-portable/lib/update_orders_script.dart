import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

/// One-time script to update all pending orders to completed status
/// Run this with: flutter run -t lib/update_orders_script.dart
Future<void> main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final firestore = FirebaseFirestore.instance;

  final snapshot = await firestore
      .collection('orders')
      .where('status', isEqualTo: 'pending')
      .get();

  if (snapshot.docs.isEmpty) {
    return;
  }

  for (final doc in snapshot.docs) {
    try {
      await doc.reference.update({'status': 'completed'});
    } catch (e) {
      //Removed Print statement here. Catch does nothing other than that
    }
  }

}
