import 'package:flutter/material.dart';
import 'login_page.dart'; // Import login_page.dart to handle logout navigation
import 'products.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  // Sample static product data
  final List<Map<String, dynamic>> products = [
    {
      "name": "Arduino Uno R3",
      "price": 850.00,
      "category": "Microcontrollers",
      "qty": 0
    },
    {
      "name": "Raspberry Pi 4",
      "price": 3200.00,
      "category": "Single Board Computers",
      "qty": 0
    },
    {
      "name": "ESP32 DevKit",
      "price": 450.00,
      "category": "Microcontrollers",
      "qty": 0
    },
    {
      "name": "LED Strip 5M",
      "price": 320.00,
      "category": "Lighting",
      "qty": 0
    },
    {
      "name": "Servo Motor SG90",
      "price": 85.00,
      "category": "Motors",
      "qty": 0
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ---------------- HEADER ----------------
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F3360), // Background color of the AppBar
        automaticallyImplyLeading: false, // To remove the back button in the AppBar
        elevation: 0, // Removes the shadow below the AppBar
        title: const Text(
          "Hi, User!",  // Title of the AppBar
          style: TextStyle(
            color: Colors.white,  // Title color (white)
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Settings gear icon with a custom color (dark blue)
          IconButton(
            icon: const Icon(
              Icons.settings,
              color: Colors.white,  // Change the color to white (or any color you like)
            ),
            onPressed: () {
              _showSettingsMenu(context); // Opens the settings menu (bottom sheet)
            },
          ),
        ],
      ),


      // ---------------- BODY ----------------
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Products",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Browse and order electronics",
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),

            const SizedBox(height: 16),

            // PRODUCT LIST — scrollable
            Expanded(
              child: ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, index) =>
                    _buildProductCard(products[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- SETTINGS MENU ----------------
  void _showSettingsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.settings,
                color: Color(0xFF0F3360),  // Custom color for Settings icon
              ),
              title: const Text('Settings'),
              onTap: () {
                // Navigate to Settings page (you can create this page later)
                Navigator.pop(context); // Close the bottom sheet
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.history,
                color: Color(0xFF0F3360),  // Custom color for History icon
              ),
              title: const Text('History'),
              onTap: () {
                // Navigate to History page (you can create this page later)
                Navigator.pop(context); // Close the bottom sheet
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.logout,
                color: Colors.red,  // Custom color for Logout icon (red)
              ),
              title: const Text('Log Out'),
              onTap: () {
                // Navigate back to the login page
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
            ),
          ],
        );
      },
    );
  }


  // ---------------- PRODUCT CARD UI ----------------
  Widget _buildProductCard(Map<String, dynamic> product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFD),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PRODUCT NAME
          Text(
            product["name"],
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          // PRICE
          Text(
            "₱${product['price'].toStringAsFixed(2)}",
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 6),

          // CATEGORY TAG
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F0FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              product["category"],
              style: const TextStyle(
                color: Color(0xFF0F3360),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ---------------- QUANTITY CONTROLS ----------------
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // MINUS BUTTON
              InkWell(
                onTap: () {
                  setState(() {
                    if (product["qty"] > 0) {
                      product["qty"]--;
                    }
                  });
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.remove, color: Colors.white),
                ),
              ),

              const SizedBox(width: 16),

              // QUANTITY NUMBER
              Text(
                product["qty"].toString(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(width: 16),

              // PLUS BUTTON
              InkWell(
                onTap: () {
                  setState(() {
                    product["qty"]++;
                  });
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F3360),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
