import 'package:flutter/material.dart';
import 'product_owner_dashboard.dart'; // Import Product Owner Dashboard
import 'admin_dashboard.dart'; // Import Admin Dashboard
import 'registration.dart'; // Import Registration Page
import 'products.dart'; // Import Products Page
import 'services/firebase_auth_service.dart';
import 'services/activity_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FirebaseAuthService _authService = FirebaseAuthService();
  final ActivityService _activityService = ActivityService();
  bool _isLoading = false;

  // Define colors based on the design image and provided registration code
  static const Color primaryBlue = Color(0xFF0F3360);
  static const Color primaryGreen = Color(0xFF12A84F);
  static const Color inputFillColor = Color(0xFFF6F6F6);

  // Validate Email
  bool isValidEmail(String email) {
    final regex = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
    return regex.hasMatch(email);
  }

  void _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Email and password cannot be empty');
      return;
    }

    if (!isValidEmail(email)) {
      _showSnackBar('Please enter a valid email');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Firebase Authentication with role-based access
    final result = await _authService.signIn(email, password);

    setState(() {
      _isLoading = false;
    });

    if (result['success']) {
      final userData = result['userData'] as Map<String, dynamic>;
      final role = userData['role'] as String;

      // Log login activity
      await _activityService.logLogin();

      // Navigate based on role
      if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AdminDashboard()),
        );
      } else if (role == 'owner') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ProductOwnerDashboard()),
        );
      } else if (role == 'user') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProductsPage()),
        );
      } else {
        _showSnackBar('Invalid user role');
      }
    } else {
      _showSnackBar(result['message'] ?? 'Login failed');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // --- REUSABLE INPUT STYLE (Matching the Registration Page and Image) ---
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: inputFillColor,
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        // Slight primary color border when focused
        borderSide: const BorderSide(color: primaryBlue, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ---------------- TOP HEADER SECTION (Matching Image) ----------------
            Container(
              width: double.infinity,
              // Adjust padding to include safe area for status bar
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 45,
                bottom: 45,
                left: 20,
                right: 20,
              ),
              decoration: const BoxDecoration(color: primaryBlue),
              child: const Column(
                children: [
                  Text(
                    "Welcome",
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

            // ---------------- LOGIN FORM CONTENT ----------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // EMAIL or PHONE NUMBER LABEL
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Email or Phone Number",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // EMAIL INPUT
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration("Enter email or phone number"),
                  ),

                  const SizedBox(height: 20),

                  // PASSWORD LABEL
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Password",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // PASSWORD INPUT
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: _inputDecoration("••••••••"),
                  ),

                  const SizedBox(height: 35),

                  // ---------------- LOG IN BUTTON ----------------
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
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
                            "Log In",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),

                  const SizedBox(height: 15),

                  // FORGOT PASSWORD LINK
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        _showSnackBar("Forgot Password functionality TBD.");
                        // TODO: Implement navigation to Forgot Password screen
                      },
                      child: const Text(
                        "Forgot Password?",
                        style: TextStyle(
                          color: primaryBlue,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // DIVIDER WITH OR
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Expanded(
                        child: Divider(thickness: 1, color: Colors.grey),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text("or", style: TextStyle(color: Colors.grey)),
                      ),
                      Expanded(
                        child: Divider(thickness: 1, color: Colors.grey),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // ---------------- CREATE ACCOUNT BUTTON ----------------
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RegistrationPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Create Account",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Updated for deployment
