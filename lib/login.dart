import 'package:flutter/material.dart';
import 'registration.dart'; // Make sure this file exists in /lib
import 'products.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String selectedRole = "User";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // TOP HEADER - Extending it all the way to the top
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40), // Adjust padding
              decoration: const BoxDecoration(
                color: Color(0xFF0F3360),
              ),
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
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // EMAIL LABEL
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Email or Phone Number",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 8),

            // EMAIL INPUT
            TextField(
              decoration: InputDecoration(
                hintText: "Enter email or phone number",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                filled: true,
              ),
            ),

            const SizedBox(height: 20),

            // PASSWORD LABEL
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Password",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 8),

            // PASSWORD INPUT
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                hintText: "Enter password",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                filled: true,
              ),
            ),

            const SizedBox(height: 20),

            // ROLE LABEL
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Role (for mockup)",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 8),

            // ROLE DROPDOWN
            DropdownButton<String>(
              value: selectedRole,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: "User", child: Text("User")),
                DropdownMenuItem(value: "Admin", child: Text("Admin")),
                DropdownMenuItem(value: "Staff", child: Text("Staff")),
              ],
              onChanged: (value) {
                setState(() {
                  selectedRole = value!;
                });
              },
            ),

            const SizedBox(height: 25),

            // ---------------- LOGIN BUTTON ----------------
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F3360),  // Keep the background color
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const ProductsPage()),
                  );
                },
                child: const Text(
                  "Log In",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,  // Set the text color to white
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            GestureDetector(
              onTap: () {
                // TODO: Forgot password functionality
              },
              child: const Text(
                "Forgot Password?",
                style: TextStyle(
                  color: Color(0xFF0F3360),
                  fontSize: 14,
                ),
              ),
            ),

            const SizedBox(height: 25),

            // Divider with OR
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Expanded(child: Divider(thickness: 1)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text("or"),
                ),
                Expanded(child: Divider(thickness: 1)),
              ],
            ),

            const SizedBox(height: 25),

            // ---------------- CREATE ACCOUNT BUTTON ----------------
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),  // Keep the background color
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegistrationPage()),
                  );
                },
                child: const Text(
                  "Create Account",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,  // Set the text color to white
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
