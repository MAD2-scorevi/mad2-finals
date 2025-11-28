import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/firebase_auth_service.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final FirebaseAuthService _authService = FirebaseAuthService();
  bool _isLoading = false;
  bool _isCheckingEmail = false;
  String? _emailError;

  @override
  void initState() {
    super.initState();
    emailController.addListener(_validateEmail);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    emailController.removeListener(_validateEmail);
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    addressController.dispose();
    dobController.dispose();
    super.dispose();
  }

  Timer? _debounceTimer;

  Future<void> _validateEmail() async {
    final email = emailController.text.trim();

    // Cancel previous timer
    _debounceTimer?.cancel();

    // Clear validation if empty
    if (email.isEmpty) {
      if (mounted) {
        setState(() {
          _emailError = null;
          _isCheckingEmail = false;
        });
      }
      return;
    }

    // Basic email format validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      if (mounted) {
        setState(() {
          _emailError = 'Invalid email format';
          _isCheckingEmail = false;
        });
      }
      return;
    }

    // Set checking state immediately when validation will start
    if (mounted) {
      setState(() {
        _isCheckingEmail = true;
      });
    }

    // Debounce: wait 500ms before checking Firebase
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;

      print('🔍 Validating email: $email');

      try {
        // Check both Firebase Auth AND Firestore for complete coverage

        // 1. Check Firebase Auth first (requires sign-in methods)
        final signInMethods = await FirebaseAuth.instance
            .fetchSignInMethodsForEmail(email);
        print('📧 Firebase Auth methods: $signInMethods');

        // 2. Check Firestore users collection (catches users created directly)
        QuerySnapshot? firestoreCheck;
        try {
          firestoreCheck = await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();
          print('📊 Firestore documents: ${firestoreCheck.docs.length}');
        } catch (firestoreError) {
          print('⚠️ Firestore check failed (no permission): $firestoreError');
          // Continue - we'll rely on Firebase Auth result
        }

        if (!mounted) return;

        // Email exists if found in EITHER location
        final existsInAuth = signInMethods.isNotEmpty;
        final existsInFirestore = (firestoreCheck?.docs.isNotEmpty ?? false);

        if (existsInAuth || existsInFirestore) {
          print(
            '❌ Email already registered: $email (Auth: $existsInAuth, Firestore: $existsInFirestore)',
          );
          setState(() {
            _isCheckingEmail = false;
            _emailError = '❌ This email is already registered';
          });
        } else {
          print('✅ Email available: $email');
          // Don't update UI for success - just clear error if exists
          if (_emailError != null || _isCheckingEmail) {
            setState(() {
              _isCheckingEmail = false;
              _emailError = null;
            });
          }
        }
      } on FirebaseAuthException catch (e) {
        print('⚠️ Firebase Auth error: ${e.code} - ${e.message}');

        if (!mounted) return;

        // Handle specific error cases
        if (e.code == 'invalid-email') {
          setState(() {
            _isCheckingEmail = false;
            _emailError = 'Invalid email format';
          });
        } else {
          setState(() {
            _isCheckingEmail = false;
            _emailError = 'Unable to verify email. Please try again.';
          });
        }
      } catch (e) {
        print('❌ Unexpected error: $e');

        if (!mounted) return;

        setState(() {
          _isCheckingEmail = false;
          _emailError = 'Unable to verify email. Please check your connection.';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Column(
          children: [
            // TOP HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 45),
              decoration: const BoxDecoration(color: Color(0xFF0F3360)),
              child: const Column(
                children: [
                  Text(
                    "Create Account",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Makerlab Electronics Philippines",
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // FULL NAME
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Full Name",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: fullNameController,
              decoration: _inputDecoration("Juan Dela Cruz"),
            ),
            const SizedBox(height: 20),

            // EMAIL ADDRESS
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Email Address",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: _inputDecoration("juan@example.com").copyWith(
                suffixIcon: _isCheckingEmail
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _emailError != null
                    ? Icon(Icons.error, color: Colors.red.shade700)
                    : emailController.text.isNotEmpty
                    ? Icon(Icons.check_circle, color: Colors.green.shade700)
                    : null,
                errorText: _emailError,
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.red.shade300, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Email warning
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Important: Your email address is permanent and cannot be changed after registration. Please double-check before proceeding.",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // PASSWORD
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Password",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: _inputDecoration("••••••••"),
            ),
            const SizedBox(height: 20),

            // PHONE NUMBER
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Phone Number",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: _inputDecoration("+63 912 345 6789"),
            ),
            const SizedBox(height: 20),

            // ADDRESS
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Address",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: addressController,
              decoration: _inputDecoration("Street, City, Province"),
            ),
            const SizedBox(height: 20),

            // DATE OF BIRTH
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Date of Birth",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: dobController,
              readOnly: true,
              onTap: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                  initialDate: DateTime(2000),
                );
                if (pickedDate != null) {
                  dobController.text =
                      "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                }
              },
              decoration: _inputDecoration("dd/mm/yyyy"),
            ),
            const SizedBox(height: 30),

            // REGISTER BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF12A84F),
                  disabledBackgroundColor: Colors.grey.shade400,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed:
                    (_isLoading ||
                        _emailError != null ||
                        _isCheckingEmail ||
                        emailController.text.trim().isEmpty)
                    ? null
                    : _register,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Register",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ),
            const SizedBox(height: 15),

            // BACK TO LOGIN
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFF0F3360)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  "Back to Login",
                  style: TextStyle(fontSize: 16, color: Color(0xFF0F3360)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Validate email
  bool isValidEmail(String email) {
    final regex = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
    return regex.hasMatch(email);
  }

  // Registration method
  void _register() async {
    final fullName = fullNameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final phone = phoneController.text.trim();
    final address = addressController.text.trim();
    final dob = dobController.text.trim();

    // Validation
    if (fullName.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        phone.isEmpty ||
        address.isEmpty ||
        dob.isEmpty) {
      _showSnackBar('Please fill in all fields');
      return;
    }

    if (!isValidEmail(email)) {
      _showSnackBar('Please enter a valid email');
      return;
    }

    if (password.length < 6) {
      _showSnackBar('Password must be at least 6 characters');
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    // Register with Firebase
    final result = await _authService.signUp(
      email: email,
      password: password,
      fullName: fullName,
      phoneNumber: phone,
      address: address,
      dateOfBirth: dob,
      role: 'user', // Default role for new registrations
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }

    if (result['success']) {
      _showSnackBar('Account created successfully!');
      // Wait a bit then navigate back to login
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.pop(context);
      }
    } else {
      _showSnackBar(result['message'] ?? 'Registration failed');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  // --- REUSABLE INPUT STYLE ---
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF6F6F6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
    );
  }
}
