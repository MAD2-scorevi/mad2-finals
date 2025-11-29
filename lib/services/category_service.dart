import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryService {
  final CollectionReference categoriesCollection =
  FirebaseFirestore.instance.collection('categories');

  // Fetch all categories
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final QuerySnapshot snapshot = await categoriesCollection.get();
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }).toList();
    } catch (e) {
      print("Error fetching categories: $e");
      return [];
    }
  }

  // Get category count (for dashboard)
  Future<int> getCategoryCount() async {
    try {
      final QuerySnapshot snapshot = await categoriesCollection.get();
      return snapshot.size;
    } catch (e) {
      print("Error counting categories: $e");
      return 0;
    }
  }
}
