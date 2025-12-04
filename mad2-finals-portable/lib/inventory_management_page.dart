import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'services/inventory_service.dart';
import 'services/activity_service.dart';
import 'services/category_service.dart';

class InventoryManagementPage extends StatefulWidget {
  const InventoryManagementPage({super.key});

  @override
  _InventoryManagementPageState createState() =>
      _InventoryManagementPageState();
}

class _InventoryManagementPageState extends State<InventoryManagementPage> {
  final InventoryService _inventoryService = InventoryService();
  final ActivityService _activityService = ActivityService();
  final CategoryService _categoryService = CategoryService();
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  List<String> _categories = ['All'];
  StreamSubscription? _categorySubscription;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() {
    _categorySubscription = _categoryService.categoriesStream.listen((
      categoryList,
    ) {
      if (mounted) {
        setState(() {
          _categories = [
            'All',
            ...categoryList.map((cat) => cat['name'] as String).toList()
              ..sort(),
          ];
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _categorySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<InventoryItem>>(
      stream: _inventoryService.itemsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF133B7C)),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final items = snapshot.data ?? [];

        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;

            return SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Cards
                  _buildStatsSection(items),
                  const SizedBox(height: 30),

                  // Search and Filter Section
                  _buildSearchAndFilter(items, isMobile),
                  const SizedBox(height: 25),

                  // Section Title and Add Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Products",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showAddItemModal(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF133B7C),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 16 : 20,
                            vertical: isMobile ? 12 : 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.add),
                        label: Text(isMobile ? 'Add' : 'Add Product'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Inventory Items - Real-time filtering with ValueListenableBuilder
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _searchController,
                    builder: (context, value, child) {
                      final filteredItems = _getFilteredItems(items);

                      if (filteredItems.isEmpty) {
                        return _buildEmptyState();
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          return _buildInventoryCard(
                            filteredItems[index],
                            isMobile,
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<InventoryItem> _getFilteredItems(List<InventoryItem> allItems) {
    var items = allItems;

    // Filter by category
    if (_selectedCategory != 'All') {
      items = items
          .where((item) => item.category == _selectedCategory)
          .toList();
    }

    // Filter by search query
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      items = items.where((item) {
        return item.name.toLowerCase().contains(query) ||
            item.category.toLowerCase().contains(query) ||
            item.description.toLowerCase().contains(query);
      }).toList();
    }

    return items;
  }

  Widget _buildStatsSection(List<InventoryItem> items) {
    final totalProducts = items.length;
    final lowStockCount = items
        .where(
          (item) =>
              item.stockQuantity > 0 &&
              item.stockQuantity <= item.lowStockThreshold,
        )
        .length;
    final outOfStockCount = items
        .where((item) => item.stockQuantity <= 0)
        .length;

    return Center(
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: [
          _buildStatCard(
            title: 'Total Products',
            value: totalProducts.toString(),
            icon: Icons.inventory,
            color: const Color(0xFF133B7C),
            onTap: () {
              setState(() {
                _selectedCategory = 'All';
                _searchController.clear();
              });
            },
          ),
          _buildStatCard(
            title: 'Low Stock',
            value: lowStockCount.toString(),
            icon: Icons.warning_amber_rounded,
            color: const Color(0xFF133B7C),
            onTap: () => _showLowStockItems(items),
          ),
          _buildStatCard(
            title: 'Out of Stock',
            value: outOfStockCount.toString(),
            icon: Icons.remove_circle_outline,
            color: const Color(0xFF133B7C),
            onTap: () => _showOutOfStockItems(items),
          ),
          // Use StreamBuilder for dynamic category count
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _categoryService.categoriesStream,
            builder: (context, snapshot) {
              final categoryCount = snapshot.data?.length ?? 0;
              return _buildStatCard(
                title: 'Categories',
                value: categoryCount.toString(),
                icon: Icons.category_rounded,
                color: const Color(0xFF133B7C),
                // No onTap - just display the count
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth > 600
            ? 200.0
            : (constraints.maxWidth / 2) - 18;
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: cardWidth.clamp(140.0, 250.0),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: color,
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
                Text(
                  title,
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLowStockItems(List<InventoryItem> items) {
    final lowStockItems = items
        .where(
          (item) =>
              item.stockQuantity > 0 &&
              item.stockQuantity <= item.lowStockThreshold,
        )
        .toList();
    _showFilteredItemsDialog(
      'Low Stock Items',
      lowStockItems,
      Colors.orange,
      Icons.warning_amber_rounded,
    );
  }

  void _showOutOfStockItems(List<InventoryItem> items) {
    final outOfStockItems = items
        .where((item) => item.stockQuantity <= 0)
        .toList();
    _showFilteredItemsDialog(
      'Out of Stock Items',
      outOfStockItems,
      Colors.red,
      Icons.remove_circle_outline,
    );
  }

  void _showFilteredItemsDialog(
    String title,
    List<InventoryItem> items,
    Color color,
    IconData icon,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Text(title),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: items.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No items found'),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      leading: Icon(Icons.devices, color: color),
                      title: Text(item.name),
                      subtitle: Text(
                        '${item.category} • ${item.stockQuantity} in stock',
                      ),
                      trailing: Text(
                        item.formattedPrice,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _showViewDetailsModal(context, item);
                      },
                    );
                  },
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

  Widget _buildSearchAndFilter(List<InventoryItem> items, bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search products...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF133B7C)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 16,
              ),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _categories.contains(_selectedCategory)
                ? _selectedCategory
                : 'All',
            isExpanded: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 16,
              ),
            ),
            items: _categories.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(category, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedCategory = value ?? 'All');
            },
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search products...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF133B7C)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _categories.contains(_selectedCategory)
                ? _selectedCategory
                : 'All',
            isExpanded: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 16,
              ),
            ),
            items: _categories.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(category, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedCategory = value ?? 'All');
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No products found',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters or add a new product',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryCard(InventoryItem item, bool isMobile) {
    Color statusColor = Colors.green;
    IconData statusIcon = Icons.check_circle;
    String statusText = 'In Stock';

    if (item.isOutOfStock) {
      statusColor = Colors.red;
      statusIcon = Icons.remove_circle;
      statusText = 'Out of Stock';
    } else if (item.isLowStock) {
      statusColor = Colors.orange;
      statusIcon = Icons.warning_amber_rounded;
      statusText = 'Low Stock';
    }

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
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.inventory_2, color: const Color(0xFF133B7C)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.category,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Price',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            item.formattedPrice,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF133B7C),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Stock',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            '${item.stockQuantity}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, size: 14, color: statusColor),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  alignment: WrapAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(
                        Icons.visibility,
                        color: Color(0xFF133B7C),
                        size: 18,
                      ),
                      label: const Text('View', style: TextStyle(fontSize: 13)),
                      onPressed: () => _showViewDetailsModal(context, item),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(
                        Icons.edit,
                        color: Colors.orange,
                        size: 18,
                      ),
                      label: const Text('Edit', style: TextStyle(fontSize: 13)),
                      onPressed: () => _showEditItemModal(context, item),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.red,
                        size: 18,
                      ),
                      label: const Text(
                        'Delete',
                        style: TextStyle(fontSize: 13),
                      ),
                      onPressed: () => _showDeleteConfirmation(context, item),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Icon(
                  Icons.inventory_2,
                  color: const Color(0xFF133B7C),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        item.category,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 100,
                  child: Text(
                    item.formattedPrice,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF133B7C),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 80,
                  child: Text(
                    '${item.stockQuantity}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 90,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.visibility,
                    color: Color(0xFF133B7C),
                    size: 20,
                  ),
                  tooltip: 'View Details',
                  onPressed: () => _showViewDetailsModal(context, item),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orange, size: 20),
                  tooltip: 'Edit Product',
                  onPressed: () => _showEditItemModal(context, item),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  tooltip: 'Delete Product',
                  onPressed: () => _showDeleteConfirmation(context, item),
                ),
              ],
            ),
    );
  }

  // ==================== MODALS ====================

  void _showViewDetailsModal(BuildContext context, InventoryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFF133B7C)),
            const SizedBox(width: 10),
            const Text('Product Details'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('ID', item.id),
              const Divider(),
              _buildDetailRow('Name', item.name),
              const Divider(),
              _buildDetailRow('Category', item.category),
              const Divider(),
              _buildDetailRow('Price', item.formattedPrice),
              const Divider(),
              _buildDetailRow('Stock Quantity', item.stockQuantity.toString()),
              const Divider(),
              _buildDetailRow('Status', item.stockStatus),
              const Divider(),
              _buildDetailRow('Low Stock Alert', '≤ ${item.lowStockThreshold}'),
              const Divider(),
              _buildDetailRow(
                'Description',
                item.description,
                isMultiline: true,
              ),
              const Divider(),
              _buildDetailRow(
                'Last Updated',
                '${item.lastUpdated.day}/${item.lastUpdated.month}/${item.lastUpdated.year}',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditItemModal(context, item);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF133B7C),
              foregroundColor: Colors.white,
            ),
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isMultiline = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _showAddItemModal(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    String? selectedCategory;
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    final descriptionController = TextEditingController();
    final thresholdController = TextEditingController(text: '10');

    showDialog(
      context: context,
      builder: (context) => StreamBuilder<List<Map<String, dynamic>>>(
        stream: _categoryService.categoriesStream,
        builder: (context, snapshot) {
          final categories = snapshot.data ?? [];
          final categoryNames =
              categories.map((cat) => cat['name'] as String).toList()..sort();

          // Wait for categories to load
          if (!snapshot.hasData || categoryNames.isEmpty) {
            return const AlertDialog(
              content: Center(child: CircularProgressIndicator()),
            );
          }

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.add_circle_outline, color: Color(0xFF133B7C)),
                SizedBox(width: 10),
                Text('Add New Product'),
              ],
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Product Name *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.inventory_2),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: categoryNames.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        selectedCategory = value;
                      },
                      validator: (value) =>
                          value == null ? 'Please select a category' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Required';
                        if (double.tryParse(value!) == null)
                          return 'Invalid price';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: stockController,
                      decoration: const InputDecoration(
                        labelText: 'Stock Quantity *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.storage),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Required';
                        if (int.tryParse(value!) == null)
                          return 'Invalid quantity';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: thresholdController,
                      decoration: const InputDecoration(
                        labelText: 'Low Stock Threshold *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.warning_amber),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Required';
                        if (int.tryParse(value!) == null)
                          return 'Invalid number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Required' : null,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final newItem = InventoryItem(
                      id: _inventoryService.generateNewId(),
                      name: nameController.text,
                      category: selectedCategory!,
                      price: double.parse(priceController.text),
                      stockQuantity: int.parse(stockController.text),
                      description: descriptionController.text,
                      lowStockThreshold: int.parse(thresholdController.text),
                    );

                    final success = await _inventoryService.addItem(newItem);
                    if (!mounted) return;
                    if (success) {
                      // Log activity with details
                      await _activityService.logInventoryAdded(
                        newItem.name,
                        quantity: newItem.stockQuantity,
                        category: newItem.category,
                        price: newItem.price,
                      );

                      Navigator.pop(context);
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${newItem.name} added successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF133B7C),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Add Product'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditItemModal(BuildContext context, InventoryItem item) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: item.name);
    String? selectedCategory = item.category;
    final priceController = TextEditingController(text: item.price.toString());
    final stockController = TextEditingController(
      text: item.stockQuantity.toString(),
    );
    final descriptionController = TextEditingController(text: item.description);
    final thresholdController = TextEditingController(
      text: item.lowStockThreshold.toString(),
    );

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismiss by tapping outside
      builder: (dialogContext) => StreamBuilder<List<Map<String, dynamic>>>(
        stream: _categoryService.categoriesStream,
        builder: (context, snapshot) {
          final categories = snapshot.data ?? [];
          final categoryNames =
              categories.map((cat) => cat['name'] as String).toList()..sort();

          // Wait for categories to load
          if (!snapshot.hasData || categoryNames.isEmpty) {
            return const AlertDialog(
              content: Center(child: CircularProgressIndicator()),
            );
          }

          // Ensure selectedCategory is in the list
          if (!categoryNames.contains(selectedCategory)) {
            selectedCategory = categoryNames.first;
          }

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.edit, color: Colors.orange),
                SizedBox(width: 10),
                Text('Edit Product'),
              ],
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Product Name *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.inventory_2),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: categoryNames.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        selectedCategory = value;
                      },
                      validator: (value) =>
                          value == null ? 'Please select a category' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Required';
                        if (double.tryParse(value!) == null)
                          return 'Invalid price';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: stockController,
                      decoration: const InputDecoration(
                        labelText: 'Stock Quantity *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.storage),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Required';
                        if (int.tryParse(value!) == null)
                          return 'Invalid quantity';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: thresholdController,
                      decoration: const InputDecoration(
                        labelText: 'Low Stock Threshold *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.warning_amber),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Required';
                        if (int.tryParse(value!) == null)
                          return 'Invalid number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Required' : null,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    // Capture values BEFORE any async operations
                    final updatedName = nameController.text;
                    final updatedCategory = selectedCategory!;
                    final updatedPrice = double.parse(priceController.text);
                    final updatedStock = int.parse(stockController.text);
                    final updatedDescription = descriptionController.text;
                    final updatedThreshold = int.parse(
                      thresholdController.text,
                    );

                    // Capture the navigator before async operations
                    final navigator = Navigator.of(dialogContext);
                    final messenger = ScaffoldMessenger.of(context);

                    try {
                      final updatedItem = item.copyWith(
                        name: updatedName,
                        category: updatedCategory,
                        price: updatedPrice,
                        stockQuantity: updatedStock,
                        description: updatedDescription,
                        lowStockThreshold: updatedThreshold,
                      );

                      final success = await _inventoryService.updateItem(
                        item.id,
                        updatedItem,
                      );

                      // Close dialog
                      navigator.pop();

                      if (success) {
                        // Build changes map for activity log
                        final changes = <String, dynamic>{};
                        if (updatedItem.stockQuantity != item.stockQuantity) {
                          changes['stockQuantity'] = updatedItem.stockQuantity;
                        }
                        if (updatedItem.price != item.price) {
                          changes['price'] = updatedItem.price;
                        }
                        if (updatedItem.category != item.category) {
                          changes['category'] = updatedItem.category;
                        }

                        await _activityService.logInventoryUpdated(
                          updatedItem.name,
                          changes.isNotEmpty ? changes : {'action': 'details'},
                        );

                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              '${updatedItem.name} updated successfully!',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Failed to update product. Please try again.',
                            ),
                            backgroundColor: Colors.red,
                            duration: Duration(seconds: 5),
                          ),
                        );
                      }
                    } catch (e) {
                      navigator.pop();
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Update failed: ${e.toString()}'),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 5),
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, InventoryItem item) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismiss by tapping outside
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text('Confirm Delete'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to delete this product?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${item.id} • ${item.category}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Capture the navigator before async operations
              final navigator = Navigator.of(dialogContext);
              final messenger = ScaffoldMessenger.of(context);

              try {
                final itemName = item.name;
                final success = await _inventoryService.removeItem(item.id);

                // Close dialog
                navigator.pop();

                if (success) {
                  await _activityService.logInventoryDeleted(itemName);

                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('$itemName deleted successfully!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Failed to delete product. Please try again.',
                      ),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 5),
                    ),
                  );
                }
              } catch (e) {
                navigator.pop();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Delete failed: ${e.toString()}'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 5),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
