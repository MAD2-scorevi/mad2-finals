import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

/// One-time script to update all pending orders to completed status
/// Run this with: flutter run -t lib/update_orders_script.dart
Future<void> main() async {
  print('Initializing Firebase...');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final firestore = FirebaseFirestore.instance;

  print('Fetching all orders with pending status...');
  final snapshot = await firestore
      .collection('orders')
      .where('status', isEqualTo: 'pending')
      .get();

  print('Found ${snapshot.docs.length} pending orders');

  if (snapshot.docs.isEmpty) {
    print('No pending orders to update');
    return;
  }

  print('Updating orders to completed status...');
  int updated = 0;

  for (final doc in snapshot.docs) {
    try {
      await doc.reference.update({'status': 'completed'});
      updated++;
      print('Updated order ${doc.id}');
    } catch (e) {
      print('Error updating order ${doc.id}: $e');
    }
  }

  print('Successfully updated $updated out of ${snapshot.docs.length} orders');
  print('Done!');
}
