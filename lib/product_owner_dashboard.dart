import 'package:flutter/material.dart';
import 'manage_admins_page.dart';

class ProductOwnerDashboard extends StatefulWidget {
  @override
  _ProductOwnerDashboardState createState() => _ProductOwnerDashboardState();
}

class _ProductOwnerDashboardState extends State<ProductOwnerDashboard> {
  int selectedTab = 0;

  // Navigation Tabs
  final List<String> tabs = [
    "Overview",
    "Inventory",
    "Feature Requests",
    "Manage Admins"
  ];

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
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
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
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 20),
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            color: selectedTab == index
                                ? const Color(0xFF1F3D60)
                                : Colors.transparent,
                            child: Text(
                              tabs[index],
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ------------------- MAIN CONTENT ------------------------
                Expanded(
                  child: SingleChildScrollView(
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
        Row(
          children: [
            _statCard(title: "Total Products", value: "152", icon: Icons.inventory),
            _statCard(title: "Low Stock", value: "12", icon: Icons.warning_amber_rounded),
            _statCard(title: "Categories", value: "9", icon: Icons.category_rounded),
          ],
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
        _activityTile("User John ordered Raspberry Pi 4 (x2)"),
        _activityTile("Inventory updated: Arduino Uno restocked"),
        _activityTile("Feature request submitted: Dark Mode"),
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
                  color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
            ),
            Text(title, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _activityTile(String msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
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
      child: Row(
        children: [
          const Icon(Icons.history, color: Color(0xFF133B7C)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  // ============================ INVENTORY TAB =============================
  Widget _inventoryTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Inventory Overview",
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 15),
        _inventoryTile("Arduino Uno", "42 in stock"),
        _inventoryTile("Raspberry Pi 4", "18 in stock"),
        _inventoryTile("Breadboard", "60 in stock"),
        _inventoryTile("Jumper Wires (Set)", "120 in stock"),
      ],
    );
  }

  Widget _inventoryTile(String product, String stock) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          const Icon(Icons.devices, color: Color(0xFF133B7C)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              product,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            stock,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Color(0xFF0A1A3F)),
          ),
        ],
      ),
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
              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
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
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Color(0xFF133B7C)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              feature,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
