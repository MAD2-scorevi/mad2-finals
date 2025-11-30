import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryService {
  final CollectionReference categoriesCollection = FirebaseFirestore.instance
      .collection('categories');

  // Stream of categories for real-time updates
  Stream<List<Map<String, dynamic>>> get categoriesStream {
    return categoriesCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
      }).toList();
    });
  }

  // Fetch all categories
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final QuerySnapshot snapshot = await categoriesCollection.get();
      return snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
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

  // Create a new category
  Future<Map<String, dynamic>> createCategory(String name) async {
    try {
      // Check if category already exists
      final existing = await categoriesCollection
          .where('name', isEqualTo: name)
          .get();

      if (existing.docs.isNotEmpty) {
        return {'success': false, 'message': 'Category "$name" already exists'};
      }

      await categoriesCollection.add({
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return {'success': true, 'message': 'Category created successfully'};
    } catch (e) {
      print("Error creating category: $e");
      return {'success': false, 'message': 'Failed to create category: $e'};
    }
  }

  // Update category name
  Future<Map<String, dynamic>> updateCategory(String id, String newName) async {
    try {
      // Check if new name already exists (excluding current category)
      final existing = await categoriesCollection
          .where('name', isEqualTo: newName)
          .get();

      if (existing.docs.isNotEmpty && existing.docs.first.id != id) {
        return {
          'success': false,
          'message': 'Category "$newName" already exists',
        };
      }

      await categoriesCollection.doc(id).update({
        'name': newName,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {'success': true, 'message': 'Category updated successfully'};
    } catch (e) {
      print("Error updating category: $e");
      return {'success': false, 'message': 'Failed to update category: $e'};
    }
  }

  // Delete category
  Future<Map<String, dynamic>> deleteCategory(String id) async {
    try {
      // Check if any products use this category
      final productsWithCategory = await FirebaseFirestore.instance
          .collection('inventory')
          .where('category', isEqualTo: id)
          .get();

      if (productsWithCategory.docs.isNotEmpty) {
        return {
          'success': false,
          'message':
              'Cannot delete category. ${productsWithCategory.size} product(s) are using it.',
        };
      }

      await categoriesCollection.doc(id).delete();

      return {'success': true, 'message': 'Category deleted successfully'};
    } catch (e) {
      print("Error deleting category: $e");
      return {'success': false, 'message': 'Failed to delete category: $e'};
    }
  }
}
