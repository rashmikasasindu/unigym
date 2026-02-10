import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign Up & Save Data
  Future<void> signUp({
    required String email, 
    required String password,
    required String name,
    required String regNum,
    required String gender,
    // Role is removed from arguments
  }) async {
    try {
      // 1. Create User in Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      User? user = result.user;

      if (user != null) {
        // 2. Update Display Name (For Home Page "Welcome, Name!")
        await user.updateDisplayName(name);

        // 3. Send Verification Email
        await user.sendEmailVerification();

        // 4. Save Details to Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'name': name,
          'registration_number': regNum,
          'gender': gender,
          'role': 'User', // <--- Default role set automatically
          'created_at': DateTime.now(),
        });
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // Sign In
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      User? user = result.user;

      if (user != null && !user.emailVerified) {
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