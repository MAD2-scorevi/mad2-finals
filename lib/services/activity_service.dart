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
  static const String FEATURE_REQUEST = 'feature_request';
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
    await logActivity(activityType: LOGIN, description: 'User logged in');
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

  Future<void> logUserInfoUpdate(Map<String, dynamic> changes) async {
    await logActivity(
      activityType: USER_INFO_UPDATED,
      description: 'User information updated',
      metadata: changes,
    );
  }

  Future<void> logInventoryAdded(String itemName) async {
    await logActivity(
      activityType: INVENTORY_ADDED,
      description: 'Added new item: $itemName',
      metadata: {'itemName': itemName},
    );
  }

  Future<void> logInventoryUpdated(
    String itemName,
    Map<String, dynamic> changes,
  ) async {
    await logActivity(
      activityType: INVENTORY_UPDATED,
      description: 'Updated item: $itemName',
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

  Future<void> logOrderPlaced(String orderId, int itemCount) async {
    await logActivity(
      activityType: ORDER_PLACED,
      description: 'Placed order with $itemCount item(s)',
      metadata: {'orderId': orderId, 'itemCount': itemCount},
    );
  }

  Future<void> logFeatureRequest(String feature) async {
    await logActivity(
      activityType: FEATURE_REQUEST,
      description: 'Submitted feature request: $feature',
      metadata: {'feature': feature},
    );
  }

  Future<void> logAdminPromoted(String email) async {
    await logActivity(
      activityType: ADMIN_PROMOTED,
      description: 'Promoted $email to admin',
      metadata: {'email': email},
    );
  }

  Future<void> logAdminDemoted(String email) async {
    await logActivity(
      activityType: ADMIN_DEMOTED,
      description: 'Removed admin access from $email',
      metadata: {'email': email},
    );
  }
}
