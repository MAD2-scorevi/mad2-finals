import 'package:flutter/material.dart';
import 'admin_dashboard.dart';
import 'product_owner_dashboard.dart';
import 'user_home.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();

  String selectedRole = "user"; // default role

  void handleLogin() {
    // ====== API PLACEHOLDER =======
    /*
      final response = await loginApi(email.text, password.text);

      String role = response.role;
      if (role == 'admin') go to admin;
      if (role == 'product_owner') go to po window;
      if (role == 'user') go to user home;
    */
    // ===== END PLACEHOLDER =======

    if (selectedRole == "admin") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AdminDashboard()),
      );
    } else if (selectedRole == "product_owner") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductOwnerDashboard()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => UserHome()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Login",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),

              TextField(
                controller: email,
                decoration: InputDecoration(labelText: "Email"),
              ),
              TextField(
                controller: password,
                decoration: InputDecoration(labelText: "Password"),
                obscureText: true,
              ),

              SizedBox(height: 20),

              DropdownButton<String>(
                value: selectedRole,
                items: const [
                  DropdownMenuItem(
                    value: "user",
                    child: Text("User"),
                  ),
                  DropdownMenuItem(
                    value: "admin",
                    child: Text("Admin"),
                  ),
                  DropdownMenuItem(
                    value: "product_owner",
                    child: Text("Product Owner"),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedRole = value!;
                  });
                },
              ),

              SizedBox(height: 20),

              ElevatedButton(
                onPressed: handleLogin,
                child: Text("Login"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
