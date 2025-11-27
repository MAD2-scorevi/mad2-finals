import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double price;
  final String category;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.category,
  });

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'productName': productName,
    'quantity': quantity,
    'price': price,
    'category': category,
  };

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    productId: json['productId'] ?? '',
    productName: json['productName'] ?? '',
    quantity: json['quantity'] ?? 0,
    price: (json['price'] ?? 0).toDouble(),
    category: json['category'] ?? '',
  );

  double get totalPrice => quantity * price;
}

class Order {
  final String id;
  final String userId;
  final String userEmail;
  final List<OrderItem> items;
  final double totalAmount;
  final DateTime orderDate;
  final String status; // 'pending', 'processing', 'completed', 'cancelled'

  Order({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.items,
    required this.totalAmount,
    required this.orderDate,
    this.status = 'completed',
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'userEmail': userEmail,
    'items': items.map((item) => item.toJson()).toList(),
    'totalAmount': totalAmount,
    'orderDate': Timestamp.fromDate(orderDate),
    'status': status,
  };

  factory Order.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final itemsData = data['items'] as List<dynamic>? ?? [];

    DateTime orderDate = DateTime.now();
    if (data['orderDate'] != null) {
      if (data['orderDate'] is Timestamp) {
        orderDate = (data['orderDate'] as Timestamp).toDate();
      } else if (data['orderDate'] is String) {
        orderDate = DateTime.parse(data['orderDate']);
      }
    }

    return Order(
      id: doc.id,
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      items: itemsData.map((item) => OrderItem.fromJson(item)).toList(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      orderDate: orderDate,
      status: data['status'] ?? 'pending',
    );
  }

  String get formattedTotal => '\$${totalAmount.toStringAsFixed(2)}';

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(orderDate);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${orderDate.month}/${orderDate.day}/${orderDate.year}';
    }
  }

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
}

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new order
  Future<String?> createOrder(List<OrderItem> items) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final totalAmount = items.fold(0.0, (sum, item) => sum + item.totalPrice);

      final orderData = Order(
        id: '', // Will be set by Firestore
        userId: user.uid,
        userEmail: user.email ?? '',
        items: items,
        totalAmount: totalAmount,
        orderDate: DateTime.now(),
        status: 'completed',
      ).toJson();

      final docRef = await _firestore.collection('orders').add(orderData);
      return docRef.id;
    } catch (e) {
      print('Error creating order: $e');
      return null;
    }
  }

  // Get user's order history stream
  Stream<List<Order>> getUserOrdersStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
          final orders = snapshot.docs
              .map((doc) => Order.fromFirestore(doc))
              .toList();
          // Sort in memory to avoid index requirement
          orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));
          return orders;
        });
  }

  // Get specific order by ID
  Future<Order?> getOrderById(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      if (doc.exists) {
        return Order.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error fetching order: $e');
      return null;
    }
  }

  // Update order status (for admin use)
  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': status,
      });
      return true;
    } catch (e) {
      print('Error updating order status: $e');
      return false;
    }
  }

  // Get all orders (for admin dashboard)
  Stream<List<Order>> getAllOrdersStream() {
    return _firestore.collection('orders').snapshots().map((snapshot) {
      final orders = snapshot.docs
          .map((doc) => Order.fromFirestore(doc))
          .toList();
      // Sort in memory to avoid index requirement
      orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));
      return orders;
    });
  }

  // Get order statistics
  Future<Map<String, dynamic>> getOrderStats() async {
    try {
      final snapshot = await _firestore.collection('orders').get();
      final orders = snapshot.docs
          .map((doc) => Order.fromFirestore(doc))
          .toList();

      final totalOrders = orders.length;
      final totalRevenue = orders.fold(
        0.0,
        (sum, order) => sum + order.totalAmount,
      );
      final pendingOrders = orders.where((o) => o.status == 'pending').length;
      final completedOrders = orders
          .where((o) => o.status == 'completed')
          .length;

      return {
        'totalOrders': totalOrders,
        'totalRevenue': totalRevenue,
        'pendingOrders': pendingOrders,
        'completedOrders': completedOrders,
      };
    } catch (e) {
      print('Error fetching order stats: $e');
      return {
        'totalOrders': 0,
        'totalRevenue': 0.0,
        'pendingOrders': 0,
        'completedOrders': 0,
      };
    }
  }
}
