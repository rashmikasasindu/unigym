import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import 'email_verification_page.dart';
import '../home/home_page.dart';
import '../admin/admin_home_page.dart';
import '../instructor/instructor_home_page.dart';

/// AuthGate listens to Firebase auth state and, once a user is signed in,
/// fetches their Firestore role to route them to the correct home screen.
/// Users cannot switch views after login — the route is locked to their role.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // Waiting for auth state
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        // Not logged in → show login
        if (!authSnapshot.hasData || authSnapshot.data == null) {
          return const LoginPage();
        }

        final user = authSnapshot.data!;

        // Logged in but email not verified → hold on verification screen
        if (!user.emailVerified) {
  return FutureBuilder(
    future: user.reload(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const _LoadingScreen();
      }

      final updatedUser = FirebaseAuth.instance.currentUser;

      if (updatedUser != null && !updatedUser.emailVerified) {
        return EmailVerificationPage(email: updatedUser.email ?? '');
      }

      // If verified, rebuild AuthGate
      return const AuthGate();
    },
  );
}

        // Logged in & verified → fetch role from Firestore once
        final uid = user.uid;
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen();
            }

            if (roleSnapshot.hasError || !roleSnapshot.hasData) {
              // On error, default to user home
              return const HomePage();
            }

            final data =
                roleSnapshot.data!.data() as Map<String, dynamic>? ?? {};
            final role = (data['role'] as String? ?? 'user').toLowerCase();

            switch (role) {
              case 'admin':
                return const AdminHomePage();
              case 'instructor':
                return const InstructorHomePage();
              default:
                return const HomePage();
            }
          },
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
