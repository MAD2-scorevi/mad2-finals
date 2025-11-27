# 🔥 Firestore Setup Instructions

## Step 1: Deploy Firestore Rules

Your Firestore rules have been updated to allow the `inventory` collection. You need to deploy them:

### Option A: Using Firebase Console (Easiest)
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click **Firestore Database** in the left menu
4. Click the **Rules** tab at the top
5. Copy and paste the contents of `firestore.rules` from this project
6. Click **Publish**

### Option B: Using Firebase CLI
```bash
# Install Firebase CLI if you haven't
npm install -g firebase-tools

# Login
firebase login

# Deploy rules
firebase deploy --only firestore:rules
```

## Step 2: Load Sample Inventory Data

Once the rules are deployed:

1. **Run your Flutter app**
2. **Login as admin**
3. **Navigate to "Inventory" tab**
4. **Click the "Load Sample Data" button** (the blue button with download icon)
5. Wait for success message
6. Check your Firebase Console - you should now see an `inventory` collection with 10 products!

## Current Firestore Rules for Inventory

```javascript
// Inventory collection
match /inventory/{productId} {
  // Everyone can read inventory (for browsing products)
  allow read: if true;

  // Only admins can create, update, delete inventory items
  allow create, update, delete: if isAdmin();
}
```

## What Gets Created

The "Load Sample Data" button will create 10 products in Firestore:

1. **INV001** - Arduino Uno (42 in stock)
2. **INV002** - Raspberry Pi 4 (18 in stock)
3. **INV003** - Breadboard (60 in stock)
4. **INV004** - Jumper Wires Set (120 in stock)
5. **INV005** - ESP32 DevKit (8 in stock - Low Stock!)
6. **INV006** - LED Kit 100pcs (45 in stock)
7. **INV007** - Resistor Kit 500pcs (75 in stock)
8. **INV008** - Servo Motor SG90 (32 in stock)
9. **INV009** - HC-SR04 Ultrasonic Sensor (25 in stock)
10. **INV010** - Power Supply 5V 2A (15 in stock)

## Verify in Firebase Console

After clicking "Load Sample Data":
1. Go to Firebase Console → Firestore Database
2. You should see a new `inventory` collection
3. Click on it to see all 10 documents (INV001 through INV010)
4. Each document will have: id, name, category, price, stockQuantity, description, lowStockThreshold, lastUpdated

---

**Note:** You need to deploy the Firestore rules FIRST before the "Load Sample Data" button will work, otherwise you'll get permission errors!
