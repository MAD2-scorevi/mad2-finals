import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents an inventory item with all its details
class InventoryItem {
  final String id;
  String name;
  String category;
  int stockQuantity;
  double price;
  String description;
  int lowStockThreshold;
  DateTime lastUpdated;

  InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.stockQuantity,
    required this.price,
    required this.description,
    this.lowStockThreshold = 10,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  /// Check if the item is low on stock
  bool get isLowStock => stockQuantity <= lowStockThreshold;

  /// Check if the item is out of stock
  bool get isOutOfStock => stockQuantity <= 0;

  /// Get formatted stock status
  String get stockStatus {
    if (isOutOfStock) return 'Out of Stock';
    if (isLowStock) return 'Low Stock';
    return 'In Stock';
  }

  /// Get formatted price
  String get formattedPrice => '\$${price.toStringAsFixed(2)}';

  /// Create a copy of the item with updated fields
  InventoryItem copyWith({
    String? id,
    String? name,
    String? category,
    int? stockQuantity,
    double? price,
    String? description,
    int? lowStockThreshold,
    DateTime? lastUpdated,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      price: price ?? this.price,
      description: description ?? this.description,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'stockQuantity': stockQuantity,
      'price': price,
      'description': description,
      'lowStockThreshold': lowStockThreshold,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  /// Create from JSON
  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    // Handle lastUpdated field - it could be Timestamp, String, or null
    DateTime lastUpdated;
    if (json['lastUpdated'] is Timestamp) {
      lastUpdated = (json['lastUpdated'] as Timestamp).toDate();
    } else if (json['lastUpdated'] is String) {
      lastUpdated = DateTime.parse(json['lastUpdated'] as String);
    } else {
      lastUpdated = DateTime.now();
    }

    return InventoryItem(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      stockQuantity: json['stockQuantity'] as int,
      price: (json['price'] as num).toDouble(),
      description: json['description'] as String,
      lowStockThreshold: json['lowStockThreshold'] as int? ?? 10,
      lastUpdated: lastUpdated,
    );
  }

  @override
  String toString() {
    return 'InventoryItem(id: $id, name: $name, stock: $stockQuantity, price: $formattedPrice)';
  }
}

/// Service class for managing inventory operations with Firestore
class InventoryService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'inventory';

  // Private list to store inventory items
  final List<InventoryItem> _items = [];
  bool _isLoading = false;
  String? _error;

  /// Get all inventory items
  List<InventoryItem> get items => List.unmodifiable(_items);

  /// Stream of inventory items for real-time updates
  Stream<List<InventoryItem>> get itemsStream {
    return _firestore.collection(_collectionName).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();

        // Handle lastUpdated field - it could be Timestamp, String, or null
        DateTime lastUpdated;
        if (data['lastUpdated'] is Timestamp) {
          lastUpdated = (data['lastUpdated'] as Timestamp).toDate();
        } else if (data['lastUpdated'] is String) {
          lastUpdated = DateTime.parse(data['lastUpdated'] as String);
        } else {
          lastUpdated = DateTime.now();
        }

        return InventoryItem(
          id: doc.id,
          name: data['name'] as String,
          category: data['category'] as String,
          stockQuantity: data['stockQuantity'] as int,
          price: (data['price'] as num).toDouble(),
          description: data['description'] as String,
          lowStockThreshold: data['lowStockThreshold'] as int? ?? 10,
          lastUpdated: lastUpdated,
        );
      }).toList();
    });
  }

  /// Check if data is loading
  bool get isLoading => _isLoading;

  /// Get error message if any
  String? get error => _error;

  /// Get total number of products
  int get totalProducts => _items.length;

  /// Get number of low stock items
  int get lowStockCount => _items.where((item) => item.isLowStock).length;

  /// Get number of out of stock items
  int get outOfStockCount => _items.where((item) => item.isOutOfStock).length;

  /// Get all unique categories
  List<String> get categories {
    final categorySet = _items.map((item) => item.category).toSet();
    return categorySet.toList()..sort();
  }

  /// Get total inventory value
  double get totalInventoryValue {
    return _items.fold(
      0.0,
      (sum, item) => sum + (item.price * item.stockQuantity),
    );
  }

  InventoryService();

  /// Load all items from Firestore
  Future<void> loadItems() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _firestore.collection(_collectionName).get();
      _items.clear();

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id; // Ensure document ID is included
          _items.add(InventoryItem.fromJson(data));
        } catch (e) {
          debugPrint('Error parsing item ${doc.id}: $e');
        }
      }

      debugPrint('Loaded ${_items.length} items from Firestore');
    } catch (e) {
      _error = 'Failed to load inventory: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Initialize Firestore with mock data (call this once to populate)
  Future<void> initializeMockData() async {
    try {
      final mockItems = [
        InventoryItem(
          id: 'INV001',
          name: 'Arduino Uno',
          category: 'Microcontrollers',
          stockQuantity: 42,
          price: 25.99,
          description: 'Popular microcontroller board based on ATmega328P',
          lowStockThreshold: 15,
        ),
        InventoryItem(
          id: 'INV002',
          name: 'Raspberry Pi 4',
          category: 'Single Board Computers',
          stockQuantity: 18,
          price: 55.00,
          description: '4GB RAM model, quad-core ARM processor',
          lowStockThreshold: 10,
        ),
        InventoryItem(
          id: 'INV003',
          name: 'Breadboard',
          category: 'Prototyping',
          stockQuantity: 60,
          price: 5.50,
          description: '830 tie points, solderless prototyping board',
          lowStockThreshold: 20,
        ),
        InventoryItem(
          id: 'INV004',
          name: 'Jumper Wires (Set)',
          category: 'Accessories',
          stockQuantity: 120,
          price: 8.99,
          description: 'Pack of 40 male-to-male jumper wires',
          lowStockThreshold: 30,
        ),
        InventoryItem(
          id: 'INV005',
          name: 'ESP32 DevKit',
          category: 'Microcontrollers',
          stockQuantity: 8,
          price: 12.99,
          description: 'WiFi + Bluetooth enabled microcontroller',
          lowStockThreshold: 15,
        ),
        InventoryItem(
          id: 'INV006',
          name: 'LED Kit (100pcs)',
          category: 'Components',
          stockQuantity: 45,
          price: 6.99,
          description: 'Assorted colors 5mm LEDs',
          lowStockThreshold: 20,
        ),
        InventoryItem(
          id: 'INV007',
          name: 'Resistor Kit (500pcs)',
          category: 'Components',
          stockQuantity: 75,
          price: 9.99,
          description: 'Various resistor values from 10Ω to 1MΩ',
          lowStockThreshold: 25,
        ),
        InventoryItem(
          id: 'INV008',
          name: 'Servo Motor SG90',
          category: 'Motors & Actuators',
          stockQuantity: 32,
          price: 3.50,
          description: 'Micro servo motor, 180° rotation',
          lowStockThreshold: 15,
        ),
        InventoryItem(
          id: 'INV009',
          name: 'HC-SR04 Ultrasonic Sensor',
          category: 'Sensors',
          stockQuantity: 25,
          price: 4.25,
          description: 'Distance measuring sensor, 2cm-400cm range',
          lowStockThreshold: 10,
        ),
        InventoryItem(
          id: 'INV010',
          name: 'Power Supply 5V 2A',
          category: 'Power',
          stockQuantity: 15,
          price: 8.50,
          description: 'DC adapter for Arduino and Raspberry Pi',
          lowStockThreshold: 10,
        ),
      ];

      // Add each item to Firestore
      final batch = _firestore.batch();
      for (var item in mockItems) {
        final docRef = _firestore.collection(_collectionName).doc(item.id);
        batch.set(docRef, item.toJson());
      }
      await batch.commit();

      debugPrint('Successfully added ${mockItems.length} items to Firestore');

      // Reload items
      await loadItems();
    } catch (e) {
      debugPrint('Error initializing mock data: $e');
      rethrow;
    }
  }

  /// Get item by ID
  InventoryItem? getItemById(String id) {
    try {
      return _items.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get items by category
  List<InventoryItem> getItemsByCategory(String category) {
    return _items.where((item) => item.category == category).toList();
  }

  /// Search items by name or description
  List<InventoryItem> searchItems(String query) {
    if (query.isEmpty) return items;

    final lowerQuery = query.toLowerCase();
    return _items.where((item) {
      return item.name.toLowerCase().contains(lowerQuery) ||
          item.description.toLowerCase().contains(lowerQuery) ||
          item.category.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Get low stock items
  List<InventoryItem> getLowStockItems() {
    return _items.where((item) => item.isLowStock).toList();
  }

  /// Get out of stock items
  List<InventoryItem> getOutOfStockItems() {
    return _items.where((item) => item.isOutOfStock).toList();
  }

  /// Add a new inventory item
  Future<bool> addItem(InventoryItem item) async {
    try {
      // Check if ID already exists
      if (_items.any((i) => i.id == item.id)) {
        debugPrint('Item with ID ${item.id} already exists');
        return false;
      }

      // Add to Firestore
      await _firestore
          .collection(_collectionName)
          .doc(item.id)
          .set(item.toJson());

      // Add to local list
      _items.add(item);
      notifyListeners();
      debugPrint('Added item: ${item.name}');
      return true;
    } catch (e) {
      debugPrint('Error adding item: $e');
      return false;
    }
  }

  /// Update an existing inventory item
  Future<bool> updateItem(String id, InventoryItem updatedItem) async {
    try {
      final index = _items.indexWhere((item) => item.id == id);

      if (index == -1) {
        debugPrint('Item with ID $id not found');
        return false;
      }

      final itemToUpdate = updatedItem.copyWith(
        id: id, // Ensure ID doesn't change
        lastUpdated: DateTime.now(),
      );

      // Update in Firestore
      await _firestore
          .collection(_collectionName)
          .doc(id)
          .update(itemToUpdate.toJson());

      // Update local list
      _items[index] = itemToUpdate;
      notifyListeners();
      debugPrint('Updated item: ${updatedItem.name}');
      return true;
    } catch (e) {
      debugPrint('Error updating item: $e');
      return false;
    }
  }

  /// Remove an inventory item
  Future<bool> removeItem(String id) async {
    try {
      final index = _items.indexWhere((item) => item.id == id);

      if (index == -1) {
        debugPrint('Item with ID $id not found');
        return false;
      }

      // Delete from Firestore
      await _firestore.collection(_collectionName).doc(id).delete();

      // Remove from local list
      final removedItem = _items.removeAt(index);
      notifyListeners();
      debugPrint('Removed item: ${removedItem.name}');
      return true;
    } catch (e) {
      debugPrint('Error removing item: $e');
      return false;
    }
  }

  /// Update stock quantity for an item
  Future<bool> updateStock(String id, int newQuantity) async {
    final item = getItemById(id);

    if (item == null) {
      debugPrint('Item with ID $id not found');
      return false;
    }

    return updateItem(
      id,
      item.copyWith(stockQuantity: newQuantity, lastUpdated: DateTime.now()),
    );
  }

  /// Increase stock quantity
  Future<bool> increaseStock(String id, int amount) async {
    final item = getItemById(id);

    if (item == null) {
      debugPrint('Item with ID $id not found');
      return false;
    }

    return await updateStock(id, item.stockQuantity + amount);
  }

  /// Decrease stock quantity
  Future<bool> decreaseStock(String id, int amount) async {
    final item = getItemById(id);

    if (item == null) {
      debugPrint('Item with ID $id not found');
      return false;
    }

    final newQuantity = item.stockQuantity - amount;
    if (newQuantity < 0) {
      debugPrint('Cannot decrease stock below 0');
      return false;
    }

    return await updateStock(id, newQuantity);
  }

  /// Generate a new unique ID
  String generateNewId() {
    if (_items.isEmpty) return 'INV001';

    // Find the highest numeric ID
    final ids = _items
        .map((item) => item.id.replaceAll(RegExp(r'[^0-9]'), ''))
        .where((id) => id.isNotEmpty)
        .map((id) => int.tryParse(id) ?? 0)
        .toList();

    final maxId = ids.isEmpty ? 0 : ids.reduce((a, b) => a > b ? a : b);
    return 'INV${(maxId + 1).toString().padLeft(3, '0')}';
  }

  /// Sort items by name
  void sortByName({bool ascending = true}) {
    _items.sort(
      (a, b) => ascending ? a.name.compareTo(b.name) : b.name.compareTo(a.name),
    );
    notifyListeners();
  }

  /// Sort items by stock quantity
  void sortByStock({bool ascending = true}) {
    _items.sort(
      (a, b) => ascending
          ? a.stockQuantity.compareTo(b.stockQuantity)
          : b.stockQuantity.compareTo(a.stockQuantity),
    );
    notifyListeners();
  }

  /// Sort items by price
  void sortByPrice({bool ascending = true}) {
    _items.sort(
      (a, b) =>
          ascending ? a.price.compareTo(b.price) : b.price.compareTo(a.price),
    );
    notifyListeners();
  }

  /// Clear all items (use with caution)
  Future<void> clearAll() async {
    try {
      // Delete all documents from Firestore
      final snapshot = await _firestore.collection(_collectionName).get();
      final batch = _firestore.batch();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      _items.clear();
      notifyListeners();
      debugPrint('All inventory items cleared');
    } catch (e) {
      debugPrint('Error clearing inventory: $e');
    }
  }
}
