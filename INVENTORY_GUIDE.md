# Inventory Management System - Setup Guide

## 🚀 Quick Start

### Firebase Firestore Setup

Your inventory system now uses **Firebase Firestore** as the backend database. All inventory data is stored in the `inventory` collection.

### First-Time Setup - Load Sample Data

When you first access the Inventory Management page and see "No products found", click the **"Load Sample Data"** button to populate Firestore with 10 sample products:

1. **Arduino Uno** - Microcontrollers (42 in stock)
2. **Raspberry Pi 4** - Single Board Computers (18 in stock)
3. **Breadboard** - Prototyping (60 in stock)
4. **Jumper Wires (Set)** - Accessories (120 in stock)
5. **ESP32 DevKit** - Microcontrollers (8 in stock - Low Stock!)
6. **LED Kit (100pcs)** - Components (45 in stock)
7. **Resistor Kit (500pcs)** - Components (75 in stock)
8. **Servo Motor SG90** - Motors & Actuators (32 in stock)
9. **HC-SR04 Ultrasonic Sensor** - Sensors (25 in stock)
10. **Power Supply 5V 2A** - Power (15 in stock)

## 📋 Features

### CRUD Operations
- ✅ **Create** - Add new products with full details
- 📖 **Read** - View all products, search, and filter
- ✏️ **Update** - Edit product information and stock levels
- 🗑️ **Delete** - Remove products with confirmation

### Smart Features
- 🔍 **Search** - Find products by name, description, or category
- 🏷️ **Filter** - Filter by category
- 📊 **Statistics** - Real-time dashboard showing:
  - Total Products
  - Low Stock Alerts
  - Out of Stock Items
  - Number of Categories
- ⚠️ **Low Stock Alerts** - Visual indicators for items below threshold
- 🎨 **Color-Coded Status** - Green (In Stock), Orange (Low), Red (Out of Stock)

## 🗄️ Firestore Structure

### Collection: `inventory`

Each document represents a product with the following fields:

```json
{
  "id": "INV001",
  "name": "Arduino Uno",
  "category": "Microcontrollers",
  "stockQuantity": 42,
  "price": 25.99,
  "description": "Popular microcontroller board based on ATmega328P",
  "lowStockThreshold": 15,
  "lastUpdated": "2025-11-27T10:30:00.000Z"
}
```

### Firestore Rules

Make sure your Firestore rules allow read/write access. For development:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /inventory/{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## 💻 Code Structure

### Files Created

1. **`lib/services/inventory_service.dart`**
   - Core service with Firestore integration
   - All CRUD operations
   - Real-time data synchronization

2. **`lib/inventory_management_page.dart`**
   - Complete UI with modals
   - Search and filter functionality
   - Action buttons for each product

3. **`lib/utils/populate_firestore.dart`**
   - Utility function to seed database
   - Can be called from anywhere

### Integration

The Inventory Management page is integrated into your Admin Dashboard's "Inventory" tab:

```dart
import 'inventory_management_page.dart';

// In admin_dashboard.dart
case 1:
  return const InventoryManagementPage();
```

## 🔧 Usage

### Add New Product
1. Click the floating "Add Product" button
2. Fill in all required fields
3. Set a low stock threshold for alerts
4. Click "Add Product"

### Edit Product
1. Click the orange edit icon on any product card
2. Modify the fields as needed
3. Click "Update"

### View Details
1. Click the blue eye icon to see full product information
2. Quick edit button available in the modal

### Delete Product
1. Click the red delete icon
2. Confirm the deletion in the warning dialog

### Search & Filter
- Use the search bar to find products by name or description
- Select a category from the dropdown to filter results

## ⚙️ Manual Database Population (Alternative)

If you need to programmatically populate the database:

```dart
import 'utils/populate_firestore.dart';

// Call from any screen with BuildContext
await populateFirestoreInventory(context);
```

## 📱 Testing

1. Run the app: `flutter run`
2. Login as admin
3. Navigate to "Inventory" tab
4. Click "Load Sample Data" if empty
5. Test CRUD operations

## 🔄 Real-time Updates

All changes are immediately synchronized with Firestore. Multiple users can view and manage inventory simultaneously with real-time updates.

## 🛠️ Troubleshooting

**Products not showing?**
- Check Firebase console to ensure `inventory` collection exists
- Verify Firestore rules allow authenticated access
- Check console logs for any errors

**Add button grayed out?**
- This was a visual issue - now the button is always active
- Try clicking "Load Sample Data" first

**Loading forever?**
- Check internet connection
- Verify Firebase configuration in `firebase_options.dart`
- Check Firestore rules

## 📈 Future Enhancements

- Real-time listeners for automatic UI updates
- Batch import/export CSV functionality
- Product images
- Barcode scanning
- Sales history tracking
- Stock movement logs
- Email alerts for low stock
- Multi-location inventory

## 🎯 Categories

Current categories:
- Microcontrollers
- Single Board Computers
- Prototyping
- Accessories
- Components
- Motors & Actuators
- Sensors
- Power

Add more categories by simply adding products with new category names!
