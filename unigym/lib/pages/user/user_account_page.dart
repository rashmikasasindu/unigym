import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserAccountPage extends StatelessWidget {
  const UserAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Account")),
      body: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            // The AuthGate in main.dart will notice you logged out 
            // and automatically switch back to LoginPage
          },
          child: const Text("Log Out"),
        ),
      ),
    );
  }
}