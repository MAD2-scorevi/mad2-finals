import 'package:flutter/material.dart';
import 'login_page.dart'; // Import login_page.dart to handle logout navigation
import 'services/inventory_service.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final InventoryService _inventoryService = InventoryService();
  bool _isLoading = true;
  final Map<String, int> _cartQuantities =
      {}; // Track cart quantities by product ID

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    await _inventoryService.loadItems();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ---------------- HEADER ----------------
      appBar: AppBar(
        backgroundColor: const Color(
          0xFF0F3360,
        ), // Background color of the AppBar
        automaticallyImplyLeading:
            false, // To remove the back button in the AppBar
        elevation: 0, // Removes the shadow below the AppBar
        title: const Text(
          "Hi, User!", // Title of the AppBar
          style: TextStyle(
            color: Colors.white, // Title color (white)
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Settings gear icon with a custom color (dark blue)
          IconButton(
            icon: const Icon(
              Icons.settings,
              color: Colors
                  .white, // Change the color to white (or any color you like)
            ),
            onPressed: () {
              _showSettingsMenu(
                context,
              ); // Opens the settings menu (bottom sheet)
            },
          ),
        ],
      ),

      // ---------------- BODY ----------------
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0F3360)),
            )
          : Padding(
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
                    child: _inventoryService.items.isEmpty
                        ? const Center(
                            child: Text(
                              'No products available',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _inventoryService.items.length,
                            itemBuilder: (context, index) => _buildProductCard(
                              _inventoryService.items[index],
                            ),
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
                color: Color(0xFF0F3360), // Custom color for Settings icon
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
                color: Color(0xFF0F3360), // Custom color for History icon
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
                color: Colors.red, // Custom color for Logout icon (red)
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
  Widget _buildProductCard(InventoryItem item) {
    final cartQty = _cartQuantities[item.id] ?? 0;
    final bool isOutOfStock = item.stockQuantity <= 0;
    final bool isLowStock = item.stockQuantity > 0 && item.stockQuantity <= 5;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Stock status badge
              if (isOutOfStock)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Out of Stock',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else if (isLowStock)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Low Stock',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 4),

          // PRICE
          Text(
            item.formattedPrice,
            style: const TextStyle(fontSize: 15, color: Colors.black87),
          ),

          const SizedBox(height: 6),

          // CATEGORY TAG & STOCK INFO
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F0FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item.category,
                  style: const TextStyle(
                    color: Color(0xFF0F3360),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (!isOutOfStock)
                Text(
                  '${item.stockQuantity} in stock',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // ---------------- QUANTITY CONTROLS ----------------
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // MINUS BUTTON
              InkWell(
                onTap: isOutOfStock
                    ? null
                    : () {
                        setState(() {
                          if (cartQty > 0) {
                            _cartQuantities[item.id] = cartQty - 1;
                          }
                        });
                      },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isOutOfStock ? Colors.grey.shade300 : Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.remove,
                    color: isOutOfStock ? Colors.grey.shade500 : Colors.white,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // QUANTITY NUMBER
              Text(
                cartQty.toString(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(width: 16),

              // PLUS BUTTON
              InkWell(
                onTap: isOutOfStock || cartQty >= item.stockQuantity
                    ? null
                    : () {
                        setState(() {
                          _cartQuantities[item.id] = cartQty + 1;
                        });
                      },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isOutOfStock || cartQty >= item.stockQuantity
                        ? Colors.grey.shade300
                        : const Color(0xFF0F3360),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add,
                    color: isOutOfStock || cartQty >= item.stockQuantity
                        ? Colors.grey.shade500
                        : Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
