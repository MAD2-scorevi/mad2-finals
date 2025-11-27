import 'package:flutter/material.dart';
import 'login_page.dart';
import 'manage_admins_page.dart';
import 'inventory_management_page.dart';
import 'services/inventory_service.dart';
import 'services/activity_service.dart';

class ProductOwnerDashboard extends StatefulWidget {
  const ProductOwnerDashboard({super.key});

  @override
  _ProductOwnerDashboardState createState() => _ProductOwnerDashboardState();
}

class _ProductOwnerDashboardState extends State<ProductOwnerDashboard> {
  int selectedTab = 0;
  final InventoryService _inventoryService = InventoryService();
  final ActivityService _activityService = ActivityService();

  final List<String> tabs = [
    "Overview",
    "Inventory",
    "Feature Requests",
    "Manage Admins",
  ];

  @override
  void initState() {
    super.initState();
    _inventoryService.loadItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      body: Column(
        children: [
          // ================= HEADER =================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 25),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF071C3A), Color(0xFF133B7C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "MAD2 Inventory Dashboard",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Manage products, stock levels, and electronics categories.",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // ================= BODY =================
          Expanded(
            child: Row(
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
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const Spacer(),

                      // ================= LOGOUT BUTTON =================
                      InkWell(
                        onTap: () async {
                          await _activityService.logLogout();
                          if (mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LoginPage(),
                              ),
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
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
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
            ),
          ),
        ],
      ),
    );
  }

  // ===================== TAB CONTENT BUILDER =======================
  Widget _buildPageContent() {
    switch (selectedTab) {
      case 0:
        return _overviewTab();
      case 1:
        return _inventoryTab();
      case 2:
        return _featureRequestTab();
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
      case ActivityService.FEATURE_REQUEST:
        icon = Icons.lightbulb;
        iconColor = Colors.amber;
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

  // ============================ FEATURE REQUEST TAB =============================
  Widget _featureRequestTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Upcoming Features",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        _roadmapTile("Auto-low-stock email alerts"),
        _roadmapTile("Supplier integration & restock requests"),
        _roadmapTile("Bulk CSV product import"),
        _roadmapTile("QR inventory scanning to update stock"),
      ],
    );
  }

  Widget _roadmapTile(String feature) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
          const Icon(Icons.check_circle_outline, color: Color(0xFF133B7C)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              feature,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
