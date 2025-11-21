import 'package:flutter/material.dart';

class UserHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("User Home"),
      ),
      body: Center(
        child: Text("Regular User Page",
            style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
