import 'package:flutter/material.dart';

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
              decoration: const BoxDecoration(
                color: Color(0xFF0F3360),
              ),
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
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
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
              decoration: _inputDecoration("juan@example.com"),
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
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  // TODO: Add validation / backend call
                },
                child: const Text(
                  "Register",
                  style: TextStyle(fontSize: 16),
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
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF0F3360),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
