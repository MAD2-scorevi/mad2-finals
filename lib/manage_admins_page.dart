import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageAdminsPage extends StatefulWidget {
  const ManageAdminsPage({super.key});

  @override
  _ManageAdminsPageState createState() => _ManageAdminsPageState();
}

class _ManageAdminsPageState extends State<ManageAdminsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController emailController = TextEditingController();
  bool _isLoading = true;
  List<Map<String, dynamic>> admins = [];

  @override
  void initState() {
    super.initState();
    _loadAdmins();
  }

  Future<void> _loadAdmins() async {
    setState(() => _isLoading = true);
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();

      setState(() {
        admins = querySnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'email': data['email'] ?? '',
            'fullName': data['fullName'] ?? 'N/A',
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading admins: \$e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF133B7C),
        title: const Text(
          "Manage Admins",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF133B7C)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Add New Admin",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: emailController,
                          decoration: InputDecoration(
                            hintText: "Enter admin email",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF133B7C),
                          padding: const EdgeInsets.symmetric(
                            vertical: 18,
                            horizontal: 20,
                          ),
                        ),
                        onPressed: _addAdmin,
                        child: const Text(
                          "Add",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),

                  const Text(
                    "Existing Admins",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  admins.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Center(
                            child: Text(
                              'No admin users found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: admins.length,
                          itemBuilder: (context, index) {
                            return _adminCard(admins[index]);
                          },
                        ),
                ],
              ),
            ),
    );
  }

  Widget _adminCard(Map<String, dynamic> admin) {
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
      child: Row(
        children: [
          const Icon(Icons.person, color: Color(0xFF133B7C)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  admin['email'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (admin['fullName'] != 'N/A')
                  Text(
                    admin['fullName'],
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.visibility, color: Color(0xFF133B7C)),
            tooltip: 'View Details',
            onPressed: () => _viewAdmin(admin),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.orange),
            tooltip: 'Edit Admin',
            onPressed: () => _editAdmin(admin),
          ),
          IconButton(
            icon: const Icon(Icons.person_remove, color: Colors.red),
            tooltip: 'Remove Admin',
            onPressed: () => _removeAdmin(admin['id'], admin['email']),
          ),
        ],
      ),
    );
  }

  Future<void> _addAdmin() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an email address')),
      );
      return;
    }

    // Validate email format
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }

    try {
      // Check if user exists in Firestore
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User not found. They must register first.'),
            ),
          );
        }
        return;
      }

      final userDoc = querySnapshot.docs.first;
      final userData = userDoc.data();

      // Check if already an admin
      if (userData['role'] == 'admin') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User is already an admin')),
          );
        }
        return;
      }

      // Check if owner
      if (userData['role'] == 'owner') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot modify owner role')),
          );
        }
        return;
      }

      // Promote to admin
      await _firestore.collection('users').doc(userDoc.id).update({
        'role': 'admin',
      });

      emailController.clear();
      _loadAdmins();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$email promoted to admin')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _viewAdmin(Map<String, dynamic> admin) async {
    // Fetch full admin details
    try {
      final doc = await _firestore.collection('users').doc(admin['id']).get();
      if (!doc.exists) return;

      final data = doc.data()!;

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Admin Details'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _detailRow('Full Name', data['fullName'] ?? 'N/A'),
                  _detailRow('Email', data['email'] ?? 'N/A'),
                  _detailRow('Phone', data['phoneNumber'] ?? 'N/A'),
                  _detailRow('Address', data['address'] ?? 'N/A'),
                  _detailRow('Date of Birth', data['dateOfBirth'] ?? 'N/A'),
                  _detailRow('Role', data['role'] ?? 'N/A'),
                  if (data['createdAt'] != null)
                    _detailRow(
                      'Joined',
                      _formatTimestamp(data['createdAt'] as Timestamp),
                    ),
                ],
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading details: $e')));
      }
    }
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.month}/${date.day}/${date.year}';
  }

  void _editAdmin(Map<String, dynamic> admin) async {
    // Fetch current data
    try {
      final doc = await _firestore.collection('users').doc(admin['id']).get();
      if (!doc.exists) return;

      final data = doc.data()!;

      final fullNameController = TextEditingController(text: data['fullName']);
      final phoneController = TextEditingController(text: data['phoneNumber']);
      final addressController = TextEditingController(text: data['address']);

      if (mounted) {
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Edit Admin'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF133B7C),
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Save'),
              ),
            ],
          ),
        );

        if (result == true) {
          await _firestore.collection('users').doc(admin['id']).update({
            'fullName': fullNameController.text.trim(),
            'phoneNumber': phoneController.text.trim(),
            'address': addressController.text.trim(),
          });

          _loadAdmins();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Admin updated successfully')),
            );
          }
        }
      }

      fullNameController.dispose();
      phoneController.dispose();
      addressController.dispose();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _removeAdmin(String userId, String email) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Admin'),
        content: Text('Remove admin access for $email?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestore.collection('users').doc(userId).update({
          'role': 'user',
        });
        _loadAdmins(); // Reload the list
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Removed admin access for $email')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
}
