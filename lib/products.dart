import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart'; // Import login_page.dart to handle logout navigation
import 'services/inventory_service.dart';
import 'services/order_service.dart';
import 'services/activity_service.dart';
import 'order_history_page.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final InventoryService _inventoryService = InventoryService();
  final OrderService _orderService = OrderService();
  final ActivityService _activityService = ActivityService();
  bool _isLoading = true;
  final Map<String, int> _cartQuantities =
      {}; // Track cart quantities by product ID
  String _displayName = 'User';

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          final data = userDoc.data();
          final fullName = data?['fullName'] as String?;
          if (fullName != null && fullName.isNotEmpty) {
            if (mounted) setState(() => _displayName = fullName);
            return;
          }
        }
        // Fallback to email without domain
        final email = user.email ?? 'User';
        if (mounted) setState(() => _displayName = email.split('@')[0]);
      } catch (e) {
        // Fallback to email without domain
        final email = user.email ?? 'User';
        if (mounted) setState(() => _displayName = email.split('@')[0]);
      }
    }
  }

  Future<void> _loadProducts() async {
    if (mounted) setState(() => _isLoading = true);
    await _inventoryService.loadItems();
    if (mounted) setState(() => _isLoading = false);
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
        title: Text(
          "Hi, $_displayName!", // Title of the AppBar
          style: const TextStyle(
            color: Colors.white, // Title color (white)
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Menu icon for History and Logout
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              _showSettingsMenu(context); // Opens the menu (bottom sheet)
            },
          ),
        ],
      ),

      // ---------------- BODY ----------------
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0F3360)),
            )
          : Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
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
                                  itemBuilder: (context, index) =>
                                      _buildProductCard(
                                        _inventoryService.items[index],
                                      ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                // CHECKOUT BUTTON
                if (_hasItemsInCart())
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -3),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${_getTotalItems()} item${_getTotalItems() > 1 ? 's' : ''}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                                Text(
                                  _getTotalPrice(),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F3360),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _checkout,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F3360),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Checkout',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  // ---------------- MENU ----------------
  void _showSettingsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.history,
                color: Color(0xFF0F3360), // Custom color for History icon
              ),
              title: const Text('History'),
              onTap: () {
                Navigator.pop(context); // Close the bottom sheet
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => OrderHistoryPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.logout,
                color: Colors.red, // Custom color for Logout icon (red)
              ),
              title: const Text('Log Out'),
              onTap: () async {
                await _activityService.logLogout();
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                }
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 400;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PRODUCT NAME
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
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
                style: TextStyle(
                  fontSize: isMobile ? 14 : 15,
                  color: Colors.black87,
                ),
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
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
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
                      width: isMobile ? 32 : 36,
                      height: isMobile ? 32 : 36,
                      decoration: BoxDecoration(
                        color: isOutOfStock ? Colors.grey.shade300 : Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.remove,
                        color: isOutOfStock
                            ? Colors.grey.shade500
                            : Colors.white,
                        size: isMobile ? 18 : 24,
                      ),
                    ),
                  ),

                  SizedBox(width: isMobile ? 12 : 16),

                  // QUANTITY NUMBER
                  Text(
                    cartQty.toString(),
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(width: isMobile ? 12 : 16),

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
                      width: isMobile ? 32 : 36,
                      height: isMobile ? 32 : 36,
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
                        size: isMobile ? 18 : 24,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------- CART HELPER METHODS ----------------
  bool _hasItemsInCart() {
    return _cartQuantities.values.any((qty) => qty > 0);
  }

  int _getTotalItems() {
    return _cartQuantities.values.fold(0, (sum, qty) => sum + qty);
  }

  String _getTotalPrice() {
    double total = 0.0;
    _cartQuantities.forEach((id, qty) {
      final item = _inventoryService.items.firstWhere((item) => item.id == id);
      total += item.price * qty;
    });
    return '\$${total.toStringAsFixed(2)}';
  }

  // ---------------- CHECKOUT METHOD ----------------
  Future<void> _checkout() async {
    if (!_hasItemsInCart()) {
      _showSnackBar('Your cart is empty!');
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Items: ${_getTotalItems()}'),
            const SizedBox(height: 8),
            Text(
              'Total Amount: ${_getTotalPrice()}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text('Do you want to place this order?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F3360),
            ),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Create order items
    final orderItems = <OrderItem>[];
    _cartQuantities.forEach((id, qty) {
      if (qty > 0) {
        final item = _inventoryService.items.firstWhere(
          (item) => item.id == id,
        );
        orderItems.add(
          OrderItem(
            productId: item.id,
            productName: item.name,
            quantity: qty,
            price: item.price,
            category: item.category,
          ),
        );
      }
    });

    // Show loading
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF0F3360)),
        ),
      );
    }

    // Place order
    final orderId = await _orderService.createOrder(orderItems);

    if (orderId != null) {
      // Update inventory only if order was successful
      for (final item in orderItems) {
        final inventoryItem = _inventoryService.items.firstWhere(
          (i) => i.id == item.productId,
        );
        final newStock = inventoryItem.stockQuantity - item.quantity;
        print(
          'Updating ${inventoryItem.name}: ${inventoryItem.stockQuantity} -> $newStock',
        );
        final updatedItem = inventoryItem.copyWith(
          stockQuantity: newStock,
          lastUpdated: DateTime.now(),
        );
        final success = await _inventoryService.updateItem(
          item.productId,
          updatedItem,
        );
        print('Update result for ${inventoryItem.name}: $success');
      }

      // Log activity with order details
      final totalAmount = orderItems.fold<double>(
        0,
        (sum, item) => sum + (item.price * item.quantity),
      );
      await _activityService.logOrderPlaced(
        orderId,
        orderItems.length,
        total: totalAmount,
      );
    }

    // Close loading dialog
    if (mounted) {
      Navigator.pop(context);
    }

    if (orderId != null) {
      // Clear cart
      if (mounted) {
        setState(() {
          _cartQuantities.clear();
        });
      }

      // Reload products to update stock
      await _loadProducts();

      // Show success
      _showSnackBar(
        'Order placed successfully! Order ID: ${orderId.substring(0, 8).toUpperCase()}',
      );
    } else {
      _showSnackBar('Failed to place order. Please try again.');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
