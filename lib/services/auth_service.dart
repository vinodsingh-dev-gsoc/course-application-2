// lib/services/auth_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- YEH HELPER FUNCTION MISSING THA ---
  // User ka data Firestore mein banane ke liye
  Future<void> _createUserInFirestore(User user) async {
    final userDoc = _db.collection('users').doc(user.uid);
    final snapshot = await userDoc.get();

    // Sirf tab document banao agar pehle se nahi hai
    if (!snapshot.exists) {
      await userDoc.set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName ?? '',
        'photoURL': user.photoURL ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Check karne ke liye ki user admin hai ya nahi
  Future<bool> isAdmin() async {
    User? user = _auth.currentUser;
    if (user == null) {
      return false;
    }
    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data()!['role'] == 'admin') {
        return true;
      }
      return false;
    } catch (e) {
      print(e); // Error handling
      return false;
    }
  }

  // Sign in with Google
  Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return 'Google sign in was cancelled.';

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // Sign in ke turant baad user ka data Firestore mein daal do
        await _createUserInFirestore(user);
      }
      return 'Success';
    } catch (e) {
      return e.toString();
    }
  }

  // Email/Password se register hue user ka naam update karne ke liye
  Future<String?> updateUserProfile(String name) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // 1. Firebase Auth profile mein naam update karo
        await user.updateDisplayName(name);

        // 2. Firestore document mein naam update karo
        await _db.collection('users').doc(user.uid).set({
          'displayName': name,
        }, SetOptions(merge: true)); // merge: true se baaki data nahi udega

        return 'Success';
      }
      return 'No user is signed in.';
    } catch (e) {
      return e.toString();
    }
  }

  // Sign in with Email and Password
  Future<String?> signInWithEmailAndPassword(
      {required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return 'Success';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        return 'Wrong password provided.';
      } else {
        return e.message;
      }
    } catch (e) {
      return e.toString();
    }
  }

  // Register with Email and Password
  Future<String?> registerWithEmailAndPassword(
      {required String email, required String password}) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);

      // Register hote hi Firestore mein user ki entry bana do
      if (userCredential.user != null) {
        await _createUserInFirestore(userCredential.user!);
      }

      return 'Success';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        return 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        return 'The account already exists for that email.';
      } else {
        return e.message;
      }
    } catch (e) {
      return e.toString();
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}