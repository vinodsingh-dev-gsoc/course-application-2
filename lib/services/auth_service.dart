// lib/services/auth_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? currentUser() {
    return _auth.currentUser;
  }

  Future<void> _createUserInFirestore(User user) async {
    final userDoc = _db.collection('users').doc(user.uid);
    final snapshot = await userDoc.get();

    if (!snapshot.exists) {
      await userDoc.set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName ?? '',
        'photoURL': user.photoURL ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'role': 'user',
        'freePdfViewCount': 0, // ✨ YEH RAHA APNA NAYA FEATURE!
      });
    }
  }

  Stream<User?> get user => _auth.authStateChanges();

  Future<bool> isAdmin() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return false;
    }
    try {
      final doc = await _db.collection('users').doc(currentUser.uid).get();
      if (doc.exists && doc.data()?['role'] == 'admin') {
        return true;
      }
      return false;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return 'Google sign in was cancelled.';
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
      await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        await _createUserInFirestore(userCredential.user!);
      }
      return null;
    } catch (e) {
      print('Google Sign-In Error: $e');
      return 'An error occurred during Google sign-in.';
    }
  }

  Future<String?> updateUserProfile(String name) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await currentUser.updateDisplayName(name);

        await _db.collection('users').doc(currentUser.uid).set({
          'displayName': name,
        }, SetOptions(merge: true));

        return null;
      }
      return 'No user is signed in to update profile.';
    } catch (e) {
      print('Update Profile Error: $e');
      return 'Failed to update profile.';
    }
  }

  Future<String?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
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

  Future<String?> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        await _createUserInFirestore(userCredential.user!);
      }

      return null;
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

  Future<String?> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'No user found for that email.';
      }
      return e.message ?? 'An unknown error occurred.';
    } catch (e) {
      return 'An unexpected error occurred.';
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        return 'No user found or user has no email.';
      }

      // Step 1: User ko unke current password se re-authenticate karo
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Step 2: Agar re-authentication successful ho, to naya password update karo
      await user.updatePassword(newPassword);

      return null; // Success!

    } on FirebaseAuthException catch (e) {
      // Common errors ko handle karo
      if (e.code == 'wrong-password') {
        return 'Your current password is incorrect.';
      } else if (e.code == 'weak-password') {
        return 'The new password is too weak.';
      } else {
        return 'An error occurred: ${e.message}';
      }
    } catch (e) {
      return 'An unexpected error occurred. Please try again.';
    }
  }
}