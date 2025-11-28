import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ActivityLog {
  final String id;
  final String userId;
  final String userEmail;
  final String userName;
  final String activityType;
  final String description;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;

  ActivityLog({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.activityType,
    required this.description,
    this.metadata,
    required this.timestamp,
  });

  factory ActivityLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ActivityLog(
      id: doc.id,
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      userName: data['userName'] ?? 'Unknown',
      activityType: data['activityType'] ?? '',
      description: data['description'] ?? '',
      metadata: data['metadata'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'activityType': activityType,
      'description': description,
      'metadata': metadata,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
    }
  }
}

class ActivityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Activity Types
  static const String LOGIN = 'login';
  static const String LOGOUT = 'logout';
  static const String USER_REGISTERED = 'user_registered';
  static const String USER_INFO_UPDATED = 'user_info_updated';
  static const String INVENTORY_ADDED = 'inventory_added';
  static const String INVENTORY_UPDATED = 'inventory_updated';
  static const String INVENTORY_DELETED = 'inventory_deleted';
  static const String ORDER_PLACED = 'order_placed';
  static const String ORDER_UPDATED = 'order_updated';
  static const String ADMIN_PROMOTED = 'admin_promoted';
  static const String ADMIN_DEMOTED = 'admin_demoted';

  Future<void> logActivity({
    required String activityType,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get user details from Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();

      await _firestore.collection('user_activities').add({
        'userId': user.uid,
        'userEmail': user.email ?? 'Unknown',
        'userName': userData?['fullName'] ?? 'Unknown User',
        'activityType': activityType,
        'description': description,
        'metadata': metadata,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error logging activity: $e');
    }
  }

  Stream<List<ActivityLog>> getRecentActivities({int limit = 20}) {
    return _firestore
        .collection('user_activities')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ActivityLog.fromFirestore(doc))
              .toList(),
        );
  }

  Stream<List<ActivityLog>> getActivitiesByType(
    String activityType, {
    int limit = 20,
  }) {
    return _firestore
        .collection('user_activities')
        .where('activityType', isEqualTo: activityType)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ActivityLog.fromFirestore(doc))
              .toList(),
        );
  }

  Stream<List<ActivityLog>> getUserActivities(String userId, {int limit = 20}) {
    return _firestore
        .collection('user_activities')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ActivityLog.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> logLogin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      final role = userData?['role'] ?? 'user';
      final roleLabel = role == 'admin'
          ? 'Admin'
          : role == 'owner'
          ? 'Owner'
          : 'User';

      await logActivity(
        activityType: LOGIN,
        description: 'Logged in as $roleLabel',
        metadata: {'role': role},
      );
    } catch (e) {
      await logActivity(activityType: LOGIN, description: 'Logged in');
    }
  }

  Future<void> logLogout() async {
    await logActivity(activityType: LOGOUT, description: 'User logged out');
  }

  Future<void> logUserRegistration(String email) async {
    await logActivity(
      activityType: USER_REGISTERED,
      description: 'New user registered',
      metadata: {'email': email},
    );
  }

  Future<void> logUserInfoUpdate(
    Map<String, dynamic> changes, {
    String? targetUser,
  }) async {
    final changesList = <String>[];

    if (changes.containsKey('fullName')) changesList.add('name');
    if (changes.containsKey('phoneNumber')) changesList.add('phone');
    if (changes.containsKey('address')) changesList.add('address');
    if (changes.containsKey('role')) changesList.add('role→${changes['role']}');
    if (changes.containsKey('isActive')) {
      changesList.add(changes['isActive'] ? 'activated' : 'deactivated');
    }

    final changesStr = changesList.isNotEmpty
        ? ': ${changesList.join(', ')}'
        : '';
    final targetStr = targetUser != null ? ' for $targetUser' : '';

    await logActivity(
      activityType: USER_INFO_UPDATED,
      description: 'Updated user$targetStr$changesStr',
      metadata: {...changes, if (targetUser != null) 'targetUser': targetUser},
    );
  }

  Future<void> logInventoryAdded(
    String itemName, {
    int? quantity,
    String? category,
    double? price,
  }) async {
    final details = <String>[];
    if (quantity != null) details.add('Qty: $quantity');
    if (category != null) details.add(category);
    if (price != null) details.add('₱${price.toStringAsFixed(2)}');

    final detailsStr = details.isNotEmpty ? ' (${details.join(', ')})' : '';

    await logActivity(
      activityType: INVENTORY_ADDED,
      description: 'Added "$itemName"$detailsStr',
      metadata: {
        'itemName': itemName,
        if (quantity != null) 'quantity': quantity,
        if (category != null) 'category': category,
        if (price != null) 'price': price,
      },
    );
  }

  Future<void> logInventoryUpdated(
    String itemName,
    Map<String, dynamic> changes,
  ) async {
    final changesList = <String>[];

    if (changes.containsKey('stockQuantity')) {
      final newQty = changes['stockQuantity'];
      changesList.add('stock→$newQty');
    }
    if (changes.containsKey('price')) {
      final newPrice = changes['price'];
      changesList.add('price→₱${newPrice.toStringAsFixed(2)}');
    }
    if (changes.containsKey('category')) {
      changesList.add('cat→${changes['category']}');
    }
    if (changes.containsKey('status')) {
      changesList.add(changes['status']);
    }

    final changesStr = changesList.isNotEmpty
        ? ': ${changesList.join(', ')}'
        : '';

    await logActivity(
      activityType: INVENTORY_UPDATED,
      description: 'Updated "$itemName"$changesStr',
      metadata: {'itemName': itemName, 'changes': changes},
    );
  }

  Future<void> logInventoryDeleted(String itemName) async {
    await logActivity(
      activityType: INVENTORY_DELETED,
      description: 'Deleted item: $itemName',
      metadata: {'itemName': itemName},
    );
  }

  Future<void> logOrderPlaced(
    String orderId,
    int itemCount, {
    double? total,
  }) async {
    final totalStr = total != null ? ', ₱${total.toStringAsFixed(2)}' : '';
    final itemStr = itemCount == 1 ? 'item' : 'items';

    await logActivity(
      activityType: ORDER_PLACED,
      description:
          'Order #${orderId.substring(0, 8).toUpperCase()}: $itemCount $itemStr$totalStr',
      metadata: {
        'orderId': orderId,
        'itemCount': itemCount,
        if (total != null) 'total': total,
      },
    );
  }

  Future<void> logAdminPromoted(String email, {String? userName}) async {
    final userStr = userName ?? email.split('@')[0];
    await logActivity(
      activityType: ADMIN_PROMOTED,
      description: 'Promoted $userStr to Admin',
      metadata: {'email': email, if (userName != null) 'userName': userName},
    );
  }

  Future<void> logAdminDemoted(String email, {String? userName}) async {
    final userStr = userName ?? email.split('@')[0];
    await logActivity(
      activityType: ADMIN_DEMOTED,
      description: 'Demoted $userStr from Admin',
      metadata: {'email': email, if (userName != null) 'userName': userName},
    );
  }
}
