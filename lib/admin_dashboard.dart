import 'package:flutter/material.dart';
import 'package:frontend3/services/user_service.dart';
import 'login_page.dart';
import 'inventory_management_page.dart';
import 'services/activity_service.dart';
import 'services/inventory_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int selectedTab = 0;
  final ActivityService _activityService = ActivityService();
  final InventoryService _inventoryService = InventoryService();
  final UserService _userService = UserService();

  final List<String> tabs = ["Overview", "Inventory", "User Management"];

  List<String> users = [
    "user1@gmail.com",
    "user2@gmail.com",
    "user3@gmail.com",
  ];

  final TextEditingController _userController = TextEditingController();

  @override
  void dispose() {
    _userController.dispose();
    super.dispose();
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
                  "MAD2 Admin Dashboard",
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
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      // ------------------- LOGOUT ---------------------
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
                // ------------------- MAIN CONTENT ------------------------
                Expanded(child: _buildPageContent()),
              ],
            ),
          ),
        ],
      ),
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
        return const InventoryManagementPage();
      case 2:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: _userManagementTab(),
        );
      default:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: _overviewTab(),
        );
    }
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
            final categories = items
                .map((item) => item.category)
                .toSet()
                .length;

            return Row(
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
                  value: categories.toString(),
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
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _userController,
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
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () {
                if (_userController.text.isNotEmpty) {
                  setState(() {
                    users.add(_userController.text.trim());
                    _userController.clear();
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF133B7C),
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
              ),
              child: const Text("Add User"),
            ),
          ],
        ),
        const SizedBox(height: 20),

        StreamBuilder(
          stream: _userService.getUsers(limit: 10), 
          builder: (context, snapshot){
            if(snapshot.connectionState == ConnectionState.waiting){
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: Color(0xFF133B7C)),
                ),
              );
            }

            if(!snapshot.hasData || snapshot.data!.isEmpty){
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
                    'No Users yet',
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

          }
        )




        // ...users.map(
        //   (email) => Container(
        //     margin: const EdgeInsets.only(bottom: 10),
        //     padding: const EdgeInsets.all(16),
        //     decoration: BoxDecoration(
        //       color: Colors.white,
        //       borderRadius: BorderRadius.circular(14),
        //       boxShadow: [
        //         BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8),
        //       ],
        //     ),
        //     child: Row(
        //       children: [
        //         const Icon(Icons.person, color: Color(0xFF133B7C)),
        //         const SizedBox(width: 12),
        //         Expanded(
        //           child: Text(
        //             email,
        //             style: const TextStyle(
        //               fontSize: 16,
        //               fontWeight: FontWeight.w600,
        //             ),
        //           ),
        //         ),
        //         TextButton(
        //           onPressed: () {
        //             setState(() {
        //               users.remove(email);
        //             });
        //           },
        //           child: const Text(
        //             "Remove",
        //             style: TextStyle(color: Colors.redAccent),
        //           ),
        //         ),
        //       ],
        //     ),
        //   ),
        // ),
      ],
    );
  }


  Widget _userManagementTile(UserManageable user){
    
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
          const Icon(Icons.person, color: Color(0xFF133B7C)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              user.email,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                // users.remove(email);
              });
            },
            child: const Text(
              "Remove",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}