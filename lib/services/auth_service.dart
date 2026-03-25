import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Sign Up & Save Data
  Future<void> signUp({
    required String email, 
    required String password,
    required String name,     // <-- Added Name
    required String contact,
    required String regNum,
    required String gender,
    // <-- Removed Role
  }) async {
    User? createdUser;
    try {
      // A. Create User in Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      createdUser = result.user;

      if (createdUser != null) {
        // B. Update the "Display Name" in Firebase Auth
        await createdUser.updateDisplayName(name);

        // C. Send Verification Email immediately
        await createdUser.sendEmailVerification();

        // D. Save Extra Details to Firestore Database
        await _firestore.collection('users').doc(createdUser.uid).set({
          'uid': createdUser.uid,
          'name': name,
          'email': email,
          'contact_number': contact,
          'registration_number': regNum,
          'gender': gender,
          'role': 'User',
          'created_at': DateTime.now(),
        });
      }
    } catch (e) {
      // If anything after Auth creation fails (e.g., Firestore write),
      // delete the half-created auth account so authStateChanges returns to
      // null and the user is not stuck on the verification page.
      if (createdUser != null) {
        await createdUser.delete();
      }
      if (e is FirebaseAuthException) {
        throw Exception(e.message ?? 'Authentication error.');
      }
      // Wrap any other exception (PlatformException, etc.) into a clean
      // Exception so the UI always receives a readable string — never a
      // raw List<Object> or PlatformException object.
      throw Exception(e.toString());
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