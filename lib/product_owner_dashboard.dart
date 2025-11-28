import 'package:flutter/material.dart';
import 'login_page.dart';
import 'manage_admins_page.dart';
import 'inventory_management_page.dart';
import 'services/inventory_service.dart';
import 'services/activity_service.dart';
import 'services/firebase_auth_service.dart';

class ProductOwnerDashboard extends StatefulWidget {
  const ProductOwnerDashboard({super.key});

  @override
  _ProductOwnerDashboardState createState() => _ProductOwnerDashboardState();
}

class _ProductOwnerDashboardState extends State<ProductOwnerDashboard> {
  int selectedTab = 0;
  final InventoryService _inventoryService = InventoryService();
  final ActivityService _activityService = ActivityService();
  final FirebaseAuthService _authService = FirebaseAuthService();

  final List<String> tabs = ["Overview", "Inventory", "Manage Admins"];

  @override
  void initState() {
    super.initState();
    _inventoryService.loadItems();
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
                      "MAD2 Inventory Dashboard",
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
        // ================= SIDE NAVIGATION =================
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

              // --------- LIST OF TABS ----------
              ...List.generate(
                tabs.length,
                (index) => InkWell(
                  onTap: () {
                    if (tabs[index] == "Manage Admins") {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ManageAdminsPage(),
                        ),
                      );
                      return;
                    }
                    setState(() => selectedTab = index);
                  },
                  child: Container(
                    width: double.infinity,
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

              // ================= DELETE ACCOUNT BUTTON =================
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

              // ================= LOGOUT BUTTON =================
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

        // ================= MAIN CONTENT =================
        Expanded(
          child: selectedTab == 1
              ? _buildPageContent() // Inventory tab without scroll wrapper
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(25),
                  child: _buildPageContent(),
                ),
        ),
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
                  onTap: () {
                    if (tabs[index] == "Manage Admins") {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ManageAdminsPage(),
                        ),
                      );
                      return;
                    }
                    setState(() => selectedTab = index);
                  },
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
              ? _buildPageContent() // Inventory tab has its own layout
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: _buildPageContent(),
                    ),
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

  // ===================== TAB CONTENT BUILDER =======================
  Widget _buildPageContent() {
    switch (selectedTab) {
      case 0:
        return _overviewTab();
      case 1:
        return _inventoryTab();
      default:
        return _overviewTab();
    }
  }

  // ============================ OVERVIEW TAB =============================
  Widget _overviewTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Real-time statistics cards
        StreamBuilder<List<InventoryItem>>(
          stream: _inventoryService.itemsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Row(
                children: [
                  _statCard(
                    title: "Total Products",
                    value: "0",
                    icon: Icons.inventory,
                  ),
                  _statCard(
                    title: "Low Stock",
                    value: "0",
                    icon: Icons.warning_amber_rounded,
                  ),
                  _statCard(
                    title: "Categories",
                    value: "0",
                    icon: Icons.category_rounded,
                  ),
                ],
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Row(
                children: [
                  _statCard(
                    title: "Total Products",
                    value: "0",
                    icon: Icons.inventory,
                  ),
                  _statCard(
                    title: "Low Stock",
                    value: "0",
                    icon: Icons.warning_amber_rounded,
                  ),
                  _statCard(
                    title: "Categories",
                    value: "0",
                    icon: Icons.category_rounded,
                  ),
                ],
              );
            }

            final items = snapshot.data!;
            final totalProducts = items.length;
            final lowStock = items
                .where(
                  (item) => item.stockQuantity > 0 && item.stockQuantity <= 5,
                )
                .length;
            final categories = items
                .map((item) => item.category)
                .toSet()
                .length;

            return Row(
              children: [
                _statCard(
                  title: "Total Products",
                  value: "$totalProducts",
                  icon: Icons.inventory,
                ),
                _statCard(
                  title: "Low Stock",
                  value: "$lowStock",
                  icon: Icons.warning_amber_rounded,
                ),
                _statCard(
                  title: "Categories",
                  value: "$categories",
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
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
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
      ),
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

  // ============================ INVENTORY TAB =============================
  Widget _inventoryTab() {
    return Padding(
      padding: const EdgeInsets.all(25),
      child: const InventoryManagementPage(),
    );
  }
}
