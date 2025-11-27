import 'package:flutter/material.dart';
import '../services/inventory_service.dart';

/// Utility function to populate Firestore with initial inventory data
/// Call this from anywhere in your app to seed the database
Future<void> populateFirestoreInventory(BuildContext context) async {
  final inventoryService = InventoryService();

  try {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Populating Firestore with inventory data...'),
          ],
        ),
      ),
    );

    // Initialize mock data
    await inventoryService.initializeMockData();

    // Close loading dialog
    Navigator.pop(context);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '✅ Successfully populated Firestore with 10 inventory items!',
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );

    debugPrint('Firestore inventory collection populated successfully!');
  } catch (e) {
    // Close loading dialog if open
    Navigator.pop(context);

    // Show error message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ Error populating Firestore: $e'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );

    debugPrint('Error populating Firestore: $e');
  }
}
