// lib/services/auth_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Yeh class aapke app ki saari authentication related logic ko handle karti hai.
/// Jaise ki sign-in, sign-up, sign-out, etc.
/// Aisa karne se aapka UI code ekdum saaf rehta hai.
class AuthService {
  // Firebase services ke instances, inhe hum poori class mein use karenge.
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// --- PRIVATE HELPER FUNCTIONS ---

  /// Jab bhi koi naya user register ya sign-in karta hai,
  /// toh unki details Firestore database mein save karne ke liye yeh function hai.
  Future<void> _createUserInFirestore(User user) async {
    final userDoc = _db.collection('users').doc(user.uid);
    final snapshot = await userDoc.get();

    // Hum check karte hain ki user ka document pehle se toh nahi hai.
    // Agar nahi hai, tabhi naya document banayenge. Isse data overwrite nahi hoga.
    if (!snapshot.exists) {
      await userDoc.set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName ?? '', // Agar naam null hai toh empty string
        'photoURL': user.photoURL ?? '', // Agar photo null hai toh empty string
        'createdAt': FieldValue.serverTimestamp(), // User kab bana, iska server time
        'role': 'user', // Default role 'user' set kar rahe hain
      });
    }
  }


  /// --- PUBLIC AUTH FUNCTIONS ---

  /// Current user ke stream ko provide karta hai. UI isko sun kar
  /// login/logout state automatically handle kar sakta hai.
  Stream<User?> get user => _auth.authStateChanges();

  /// Check karta hai ki current logged-in user admin hai ya nahi.
  Future<bool> isAdmin() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return false; // Agar koi user login hi nahi hai, toh woh admin nahi ho sakta.
    }
    try {
      final doc = await _db.collection('users').doc(currentUser.uid).get();
      // Check karte hain ki document hai aur usme role 'admin' hai ya nahi.
      if (doc.exists && doc.data()?['role'] == 'admin') {
        return true;
      }
      return false;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  /// Google se sign-in karwata hai.
  /// Success par `null` return karega, error par error message (String).
  Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
      // Agar user ne Google Sign-In pop-up cancel kar diya toh googleUser null hoga.
      if (googleUser == null) {
        return 'Google sign in was cancelled.';
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: null,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      // Agar sign-in successful hai aur user object mil gaya hai...
      if (userCredential.user != null) {
        // ...toh uski details Firestore mein create/update kar do.
        await _createUserInFirestore(userCredential.user!);
      }
      return null; // Success
    } catch (e) {
      print('Google Sign-In Error: $e');
      return 'An error occurred during Google sign-in.';
    }
  }

  /// Email/Password se register hue user ka naam update karne ke liye.
  Future<String?> updateUserProfile(String name) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        // 1. Firebase Auth profile mein naam update karo (jo har jagah dikhega).
        await currentUser.updateDisplayName(name);

        // 2. Apne Firestore document mein bhi naam update karo.
        // SetOptions(merge: true) use karna bohot important hai.
        // Yeh sirf 'displayName' field ko update karega, baaki data (email, createdAt) ko nahi chedega.
        await _db.collection('users').doc(currentUser.uid).set({
          'displayName': name,
        }, SetOptions(merge: true));

        return null; // Success
      }
      return 'No user is signed in to update profile.';
    } catch (e) {
      print('Update Profile Error: $e');
      return 'Failed to update profile.';
    }
  }

  /// Email aur Password se sign-in karwata hai.
  Future<String?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      // User-friendly error messages dena hamesha achhi practice hai.
      if (e.code == 'user-not-found') {
        return 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        return 'Wrong password provided.';
      } else {
        return e.message ?? 'An unknown error occurred.';
      }
    } catch (e) {
      print('Sign-In Error: $e');
      return 'An unexpected error occurred.';
    }
  }

  /// Email aur Password se naya account register karwata hai.
  Future<String?> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Register hote hi user ki entry Firestore mein bana do.
      if (userCredential.user != null) {
        await _createUserInFirestore(userCredential.user!);
      }

      return null; // Success
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        return 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        return 'An account already exists for that email.';
      } else {
        return e.message ?? 'An unknown error occurred.';
      }
    } catch (e) {
      print('Registration Error: $e');
      return 'An unexpected error occurred.';
    }
  }

  /// User ko sign out karta hai.
  Future<void> signOut() async {
    // Dono jagah se sign out karna zaroori hai, Google se bhi aur Firebase se bhi.
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}