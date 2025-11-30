import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend3/services/user_service.dart';
import 'login_page.dart';
import 'inventory_management_page.dart';
import 'services/activity_service.dart';
import 'services/inventory_service.dart';
import 'services/firebase_auth_service.dart';
import 'package:frontend3/services/category_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int selectedTab = 0;
  //variable to store the count
  int categoryCount = 0;
  final ActivityService _activityService = ActivityService();
  final InventoryService _inventoryService = InventoryService();
  final UserService _userService = UserService();
  final FirebaseAuthService _authService = FirebaseAuthService();
  final CategoryService _categoryService = CategoryService();

  final List<String> tabs = [
    "Overview",
    "Inventory",
    "User Management",
    "Categories",
  ];

  final TextEditingController _userController = TextEditingController();

  bool _isCheckingUserEmail = false;
  String? _userEmailError;
  Timer? _debounceUserTimer;

  // Cache credentials for the entire session (until logout)
  Map<String, String>? _cachedCredentials;

  // Key to force stream refresh after operations
  Key _userStreamKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _userController.addListener(_validateUserEmail);
    loadCounts(); // calling the function
  }

  // Keep this function definition here!
  void loadCounts() async {
    final service = CategoryService();
    int count = await service.getCategoryCount();

    setState(() {
      categoryCount = count;
    });
  }

  @override
  void dispose() {
    _debounceUserTimer?.cancel();
    _userController.removeListener(_validateUserEmail);
    _userController.dispose();
    super.dispose();
  }

  Future<void> _validateUserEmail() async {
    final email = _userController.text.trim();

    // Cancel previous timer
    _debounceUserTimer?.cancel();

    // Clear validation if empty
    if (email.isEmpty) {
      if (mounted && (_userEmailError != null || _isCheckingUserEmail)) {
        setState(() {
          _userEmailError = null;
          _isCheckingUserEmail = false;
        });
      }
      return;
    }

    // Basic email format validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      if (mounted && _userEmailError != 'Invalid email format') {
        setState(() {
          _userEmailError = 'Invalid email format';
          _isCheckingUserEmail = false;
        });
      }
      return;
    }

    // Set checking state immediately when validation will start
    if (mounted) {
      setState(() {
        _isCheckingUserEmail = true;
      });
    }

    // Debounce: wait 500ms before checking Firebase
    _debounceUserTimer = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;

      print('🔍 Admin validating email: $email');

      try {
        // Check both Firebase Auth AND Firestore for complete coverage
        // Admin has permissions for both

        // 1. Check Firebase Auth
        final signInMethods = await FirebaseAuth.instance
            .fetchSignInMethodsForEmail(email);
        print('📧 Admin - Firebase Auth methods: $signInMethods');

        // 2. Check Firestore users collection
        final firestoreCheck = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();
        print('📊 Admin - Firestore documents: ${firestoreCheck.docs.length}');

        if (!mounted) return;

        // Email exists if found in EITHER location
        final existsInAuth = signInMethods.isNotEmpty;
        final existsInFirestore = firestoreCheck.docs.isNotEmpty;

        if (existsInAuth || existsInFirestore) {
          print(
            '❌ Admin: Email already registered: $email (Auth: $existsInAuth, Firestore: $existsInFirestore)',
          );
          setState(() {
            _isCheckingUserEmail = false;
            _userEmailError = '❌ Email already registered';
          });
        } else {
          print('✅ Admin: Email available: $email');
          // Don't update UI for success - just clear error if exists
          if (_userEmailError != null || _isCheckingUserEmail) {
            setState(() {
              _isCheckingUserEmail = false;
              _userEmailError = null;
            });
          }
        }
      } on FirebaseAuthException catch (e) {
        print('⚠️ Admin Firebase Auth error: ${e.code} - ${e.message}');

        if (!mounted) return;

        if (e.code == 'invalid-email') {
          setState(() {
            _isCheckingUserEmail = false;
            _userEmailError = 'Invalid email format';
          });
        } else {
          setState(() {
            _isCheckingUserEmail = false;
            _userEmailError = 'Unable to verify email. Try again.';
          });
        }
      } catch (e) {
        print('❌ Admin unexpected error: $e');

        if (!mounted) return;

        setState(() {
          _isCheckingUserEmail = false;
          _userEmailError = 'Unable to verify email. Check connection.';
        });
      }
    });
  } // Refresh the user stream after operations

  void _refreshUserStream() {
    setState(() {
      _userStreamKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 800;

          return Column(
            children: [
              // ================= HEADER =================
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  vertical: isMobile ? 20 : 40,
                  horizontal: isMobile ? 16 : 25,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF071C3A), Color(0xFF133B7C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "MAD2 Admin Dashboard",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 20 : 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Manage products, stock levels, and electronics categories.",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: isMobile ? 12 : 16,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isMobile ? 8 : 18),

              // ================= BODY =================
              Expanded(
                child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // ------------------- SIDE NAVIGATION ---------------------
        Container(
          width: 220,
          padding: const EdgeInsets.symmetric(vertical: 20),
          color: const Color(0xFF102A44),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "Navigation",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ...List.generate(
                tabs.length,
                (index) => InkWell(
                  onTap: () => setState(() => selectedTab = index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    color: selectedTab == index
                        ? const Color(0xFF1F3D60)
                        : Colors.transparent,
                    child: Text(
                      tabs[index],
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              // ------------------- DELETE ACCOUNT ---------------------
              InkWell(
                onTap: () => _showDeleteAccountDialog(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  color: const Color(0xFF6B0000),
                  child: const Row(
                    children: [
                      Icon(Icons.delete_forever, color: Colors.white, size: 20),
                      SizedBox(width: 10),
                      Text(
                        "Delete My Account",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              // ------------------- LOGOUT ---------------------
              InkWell(
                onTap: () async {
                  await _activityService.logLogout();
                  if (mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                    );
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  color: const Color(0xFF8B0000),
                  child: const Row(
                    children: [
                      Icon(Icons.logout, color: Colors.white, size: 20),
                      SizedBox(width: 10),
                      Text(
                        "Log Out",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // ------------------- MAIN CONTENT ------------------------
        Expanded(child: _buildPageContent()),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Mobile tab selector
        Container(
          color: const Color(0xFF102A44),
          child: Row(
            children: List.generate(
              tabs.length,
              (index) => Expanded(
                child: InkWell(
                  onTap: () => setState(() => selectedTab = index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: selectedTab == index
                              ? Colors.white
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      tabs[index],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: selectedTab == index
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Main content
        Expanded(
          child: selectedTab == 1
              ? _buildPageContent() // Inventory has its own structure
              : SingleChildScrollView(
                  child: SizedBox(
                    width: double.infinity,
                    child: _buildPageContent(),
                  ),
                ),
        ),
        // Logout button for mobile
        InkWell(
          onTap: () async {
            await _activityService.logLogout();
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            color: const Color(0xFF8B0000),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text(
                  "Log Out",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Delete Account',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'WARNING: This action is permanent and cannot be undone.',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your account and all associated data will be permanently deleted from both Firestore and Firebase Authentication.',
              ),
              const SizedBox(height: 16),
              const Text('Please enter your password to confirm:'),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                passwordController.dispose();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final password = passwordController.text.trim();
                final dialogContext = context;
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);

                if (password.isEmpty) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Please enter your password')),
                  );
                  return;
                }

                navigator.pop(); // Close dialog

                // Show loading
                showDialog(
                  context: dialogContext,
                  barrierDismissible: false,
                  builder: (context) =>
                      const Center(child: CircularProgressIndicator()),
                );

                final result = await _authService.deleteMyAccount(password);

                if (!mounted) return;
                navigator.pop(); // Close loading

                if (result['success']) {
                  // Navigate to login page
                  navigator.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => LoginPage()),
                    (route) => false,
                  );
                } else {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        result['message'] ?? 'Failed to delete account',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                passwordController.dispose();
              },
              child: const Text('Delete Account'),
            ),
          ],
        );
      },
    );
  }

  // ===================== PAGE BUILDER =======================
  Widget _buildPageContent() {
    switch (selectedTab) {
      case 0:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: _overviewTab(),
        );
      case 1:
        return _inventoryTab();
      case 2:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: _userManagementTab(),
        );
      case 3:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: _categoriesTab(),
        );
      default:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: _overviewTab(),
        );
    }
  }

  // ============================ INVENTORY TAB =============================
  Widget _inventoryTab() {
    return const InventoryManagementPage();
  }

  // ============================ OVERVIEW TAB =============================
  Widget _overviewTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Real-time inventory stats
        StreamBuilder<List<InventoryItem>>(
          stream: _inventoryService.itemsStream,
          builder: (context, snapshot) {
            final items = snapshot.data ?? [];
            final totalProducts = items.length;
            final lowStock = items
                .where((item) => item.stockQuantity <= 5)
                .length;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _statCard(
                  title: "Total Products",
                  value: totalProducts.toString(),
                  icon: Icons.inventory,
                ),
                _statCard(
                  title: "Low Stock",
                  value: lowStock.toString(),
                  icon: Icons.warning_amber_rounded,
                ),
                _statCard(
                  title: "Categories",
                  value: categoryCount.toString(), // <--- UPDATED HERE
                  icon: Icons.category_rounded,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 30),
        const Text(
          "Recent Activity",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        // Real-time activity feed
        StreamBuilder<List<ActivityLog>>(
          stream: _activityService.getRecentActivities(limit: 10),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: Color(0xFF133B7C)),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'No activities yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              );
            }

            final activities = snapshot.data!;
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length,
              itemBuilder: (context, index) {
                return _activityTile(activities[index]);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: constraints.maxWidth > 600
              ? 200
              : constraints.maxWidth / 3 - 16,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF133B7C),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 32),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(title, style: const TextStyle(color: Colors.white70)),
            ],
          ),
        );
      },
    );
  }

  Widget _activityTile(ActivityLog activity) {
    IconData icon;
    Color iconColor;

    // Choose icon and color based on activity type
    switch (activity.activityType) {
      case ActivityService.LOGIN:
        icon = Icons.login;
        iconColor = Colors.green;
        break;
      case ActivityService.LOGOUT:
        icon = Icons.logout;
        iconColor = Colors.grey;
        break;
      case ActivityService.INVENTORY_ADDED:
        icon = Icons.add_circle;
        iconColor = const Color(0xFF133B7C);
        break;
      case ActivityService.INVENTORY_UPDATED:
        icon = Icons.edit;
        iconColor = Colors.orange;
        break;
      case ActivityService.INVENTORY_DELETED:
        icon = Icons.delete;
        iconColor = Colors.red;
        break;
      case ActivityService.ORDER_PLACED:
        icon = Icons.shopping_cart;
        iconColor = Colors.purple;
        break;
      case ActivityService.ADMIN_PROMOTED:
        icon = Icons.person_add;
        iconColor = Colors.green;
        break;
      case ActivityService.ADMIN_DEMOTED:
        icon = Icons.person_remove;
        iconColor = Colors.red;
        break;
      case ActivityService.USER_REGISTERED:
        icon = Icons.person;
        iconColor = Colors.blue;
        break;
      case ActivityService.USER_INFO_UPDATED:
        icon = Icons.edit;
        iconColor = Colors.blueGrey;
        break;
      default:
        icon = Icons.history;
        iconColor = const Color(0xFF133B7C);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.description,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${activity.userName} • ${activity.formattedTime}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================ USER MANAGEMENT TAB =============================
  Widget _userManagementTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "User Management",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Add new users or manage existing user accounts",
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 20),

        // Add User Section
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _userController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: "Enter user email",
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  errorText: _userEmailError,
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.red.shade300,
                      width: 2,
                    ),
                  ),
                  suffixIcon: _isCheckingUserEmail
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _userEmailError != null
                      ? Icon(Icons.error, color: Colors.red.shade700)
                      : _userController.text.isNotEmpty
                      ? Icon(Icons.check_circle, color: Colors.green.shade700)
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed:
                  (_userEmailError != null ||
                      _isCheckingUserEmail ||
                      _userController.text.trim().isEmpty)
                  ? null
                  : _addUser,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF133B7C),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade400,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
              ),
              child: const Text("Add User"),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Email permanence warning for admins
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            border: Border.all(color: Colors.blue.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Note: Email addresses are permanent in Firebase and cannot be changed. Deactivating a user marks them as inactive but preserves their Firebase Auth record.",
                  style: TextStyle(fontSize: 11, color: Colors.blue.shade900),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        StreamBuilder<List<UserManageable>>(
          key: _userStreamKey, // Enable stream refresh
          stream: _userService.getUsers(limit: 50),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: Color(0xFF133B7C)),
                ),
              );
            }

            if (snapshot.hasError) {
              // Ignore permission errors during auth transitions (adding users, etc)
              final errorMsg = snapshot.error.toString();
              if (errorMsg.contains('permission-denied') ||
                  errorMsg.contains('PERMISSION_DENIED')) {
                // Show loading indicator instead of error during auth transition
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(color: Color(0xFF133B7C)),
                  ),
                );
              }

              // Show actual errors that aren't permission-related
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Error loading users: ${snapshot.error}',
                    style: const TextStyle(fontSize: 16, color: Colors.red),
                  ),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'No active users found',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              );
            }

            final users = snapshot.data!;
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: users.length,
              itemBuilder: (context, index) {
                return _userManagementTile(users[index]);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _userManagementTile(UserManageable user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.person, color: Color(0xFF133B7C)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.email,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (user.fullName != 'N/A')
                  Text(
                    user.fullName,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.visibility, color: Color(0xFF133B7C)),
            tooltip: 'View Details',
            onPressed: () => _viewUser(user),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.orange),
            tooltip: 'Edit User',
            onPressed: () => _editUser(user),
          ),
          IconButton(
            icon: const Icon(Icons.person_remove, color: Colors.red),
            tooltip: 'Deactivate User',
            onPressed: () => _deactivateUser(user.id, user.email),
          ),
        ],
      ),
    );
  }

  void _viewUser(UserManageable user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Full Name', user.fullName),
              _detailRow('Email', user.email),
              _detailRow('Phone', user.phoneNumber),
              _detailRow('Address', user.address),
              _detailRow('Date of Birth', user.dateOfBirth),
              _detailRow('Role', user.role),
              _detailRow('Status', user.status),
              _detailRow('Joined', user.createdAt),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _editUser(UserManageable user) async {
    final fullNameController = TextEditingController(text: user.fullName);
    final phoneController = TextEditingController(text: user.phoneNumber);
    final addressController = TextEditingController(text: user.address);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF133B7C),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      // Get admin credentials for re-authentication
      final credentials = await _getAdminCredentials();
      if (credentials == null) {
        fullNameController.dispose();
        phoneController.dispose();
        addressController.dispose();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Update cancelled')));
        }
        return;
      }

      try {
        await _userService.updateUserProfile(
          id: user.id,
          updates: {
            'fullName': fullNameController.text.trim(),
            'phoneNumber': phoneController.text.trim(),
            'address': addressController.text.trim(),
          },
          adminEmail: credentials['email']!,
          adminPassword: credentials['password']!,
        );

        await _activityService.logUserInfoUpdate({
          'fullName': fullNameController.text.trim(),
          'phoneNumber': phoneController.text.trim(),
          'address': addressController.text.trim(),
        }, targetUser: user.email);

        if (mounted) {
          _refreshUserStream(); // Refresh the stream
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User updated successfully'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error updating user: $e')));
        }
      }
    }

    fullNameController.dispose();
    phoneController.dispose();
    addressController.dispose();
  }

  // Helper method to get admin credentials for re-authentication
  Future<Map<String, String>?> _getAdminCredentials() async {
    // Check if we have cached credentials (valid for entire session)
    if (_cachedCredentials != null) {
      print('Using cached credentials from this session');
      return _cachedCredentials;
    }

    print('No cached credentials, requesting admin confirmation');
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Admin Credentials'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Please enter your admin credentials to continue:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) {
                // Move focus to password field on Enter
                FocusScope.of(dialogContext).nextFocus();
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                // Trigger confirm on Enter in password field
                final email = emailController.text.trim();
                final password = passwordController.text.trim();
                if (email.isNotEmpty && password.isNotEmpty) {
                  emailController.text = email;
                  passwordController.text = password;
                  Navigator.pop(dialogContext, true);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF133B7C),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              // Capture values before popping
              final email = emailController.text.trim();
              final password = passwordController.text.trim();
              Navigator.pop(dialogContext, true);
              // Store in controllers for retrieval after dialog closes
              emailController.text = email;
              passwordController.text = password;
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (result == true) {
      final credentials = {
        'email': emailController.text.trim(),
        'password': passwordController.text.trim(),
      };
      emailController.dispose();
      passwordController.dispose();

      // Cache credentials for entire session
      _cachedCredentials = credentials;
      print('Credentials cached for session (until logout)');

      return credentials;
    }

    emailController.dispose();
    passwordController.dispose();
    return null;
  }

  Future<void> _addUser() async {
    final email = _userController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an email address')),
      );
      return;
    }

    // Validate email format
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }

    try {
      // Check if user already exists
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User with this email already exists'),
            ),
          );
        }
        return;
      }

      // Get admin credentials for re-authentication
      final credentials = await _getAdminCredentials();
      if (credentials == null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Operation cancelled')));
        }
        return;
      }

      // Add user to Firebase Auth and Firestore
      await _userService.addUser(
        email: email,
        adminEmail: credentials['email']!,
        adminPassword: credentials['password']!,
      );

      // Log activity
      await _activityService.logUserInfoUpdate({
        'role': 'user',
      }, targetUser: email);

      _userController.clear();

      if (mounted) {
        _refreshUserStream(); // Refresh the stream
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'User $email created successfully with password "Welcome123!"',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding user: $e')));
      }
    }
  }

  Future<void> _deactivateUser(String userId, String email) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate User'),
        content: Text(
          'Are you sure you want to deactivate $email?\n\nThe user will no longer be able to access the system, but their data will be preserved.\n\nNote: Firebase Auth record will remain but the account will be inaccessible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Deactivate',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      // Get admin credentials for re-authentication
      final credentials = await _getAdminCredentials();
      if (credentials == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Deactivation cancelled')),
          );
        }
        return;
      }

      try {
        await _userService.deactivateUser(
          id: userId,
          adminEmail: credentials['email']!,
          adminPassword: credentials['password']!,
        );

        await _activityService.logUserInfoUpdate({
          'isActive': false,
        }, targetUser: email);

        if (mounted) {
          _refreshUserStream(); // Refresh the stream
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User $email deactivated successfully'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deactivating user: $e')),
          );
        }
      }
    }
  }

  // ============================ CATEGORIES TAB =============================
  Widget _categoriesTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Categories Management',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: () => _showAddCategoryDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Category'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF12A84F),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Categories list
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: _categoryService.categoriesStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final categories = snapshot.data ?? [];

            if (categories.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 50),
                    Icon(
                      Icons.category_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No categories yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Click "Add Category" to create your first category',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: categories.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF0F3360),
                      child: Text(
                        category['name'][0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      category['name'],
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: Color(0xFF0F3360),
                          ),
                          onPressed: () => _showEditCategoryDialog(
                            category['id'],
                            category['name'],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDeleteCategory(
                            category['id'],
                            category['name'],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  void _showAddCategoryDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Category'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Category Name',
              hintText: 'Enter category name',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () {
                controller.dispose();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF12A84F),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final name = controller.text.trim();
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);

                if (name.isEmpty) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a category name'),
                    ),
                  );
                  return;
                }

                navigator.pop();

                final result = await _categoryService.createCategory(name);

                if (!mounted) return;

                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(result['message']),
                    backgroundColor: result['success']
                        ? Colors.green
                        : Colors.red,
                  ),
                );

                if (result['success']) {
                  // Log activity
                  await _activityService.logCategoryAdded(name);
                  loadCounts(); // Refresh count
                }

                controller.dispose();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showEditCategoryDialog(String id, String currentName) {
    final TextEditingController controller = TextEditingController(
      text: currentName,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Category'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Category Name',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () {
                controller.dispose();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F3360),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final name = controller.text.trim();
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);

                if (name.isEmpty) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a category name'),
                    ),
                  );
                  return;
                }

                navigator.pop();

                final result = await _categoryService.updateCategory(id, name);

                if (!mounted) return;

                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(result['message']),
                    backgroundColor: result['success']
                        ? Colors.green
                        : Colors.red,
                  ),
                );

                if (result['success']) {
                  // Log activity
                  await _activityService.logCategoryUpdated(currentName, name);
                }

                controller.dispose();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteCategory(String id, String name) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Category'),
          content: Text('Are you sure you want to delete "$name"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);

                navigator.pop();

                final result = await _categoryService.deleteCategory(id);

                if (!mounted) return;

                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(result['message']),
                    backgroundColor: result['success']
                        ? Colors.green
                        : Colors.red,
                  ),
                );

                if (result['success']) {
                  // Log activity
                  await _activityService.logCategoryDeleted(name);
                  loadCounts(); // Refresh count
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
