import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Sign Up & Save Data
  Future<void> signUp({
    required String email, 
    required String password,
    required String contact,
    required String regNum,
    required String gender,
    required String role,
  }) async {
    try {
      // A. Create User in Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      User? user = result.user;

      if (user != null) {
        // B. Send Verification Email immediately
        await user.sendEmailVerification();

        // C. Save Extra Details to Firestore Database
        await _firestore.collection('users').doc(user.uid).set({
          'email': email,
          'contact_number': contact,
          'registration_number': regNum,
          'gender': gender,
          'role': role,
          'created_at': DateTime.now(),
          'uid': user.uid,
        });
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // 2. Sign In (With Verification Check)
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      User? user = result.user;

      // Check if email is verified
      if (user != null && !user.emailVerified) {
         // If not verified, sign them out immediately and throw error
         await signOut();
         throw Exception("Email not verified. Please check your inbox.");
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // Password Reset
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}