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
          onPressed: () async => await FirebaseAuth.instance.signOut(),
          child: const Text("Logout"),
        ),
      ),
    );
  }
}