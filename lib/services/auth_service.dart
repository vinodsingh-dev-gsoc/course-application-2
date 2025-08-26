// lib/services/auth_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nanoid/nanoid.dart'; // nanoid package import karo

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? currentUser() {
    return _auth.currentUser;
  }

  // ✨ --- YEH FUNCTION UPDATE HUA HAI --- ✨
  Future<void> _createUserInFirestore(User user, {String? referredByCode}) async {
    final userDoc = _db.collection('users').doc(user.uid);
    final snapshot = await userDoc.get();

    if (!snapshot.exists) {
      // Har naye user ke liye ek unique, chhota referral code generate hoga
      final String newUserReferralCode = nanoid(8);

      await userDoc.set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName ?? '',
        'photoURL': user.photoURL ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'role': 'user',
        'freePdfViewCount': 0,
        // --- NAYE REFERRAL FIELDS ---
        'referralCode': newUserReferralCode, // User ka apna unique code
        'referredBy': referredByCode,      // Jisne refer kiya uska code (agar hai toh)
        'walletBalance': 0.0,              // Shuruaati wallet balance
        'firstPurchaseMade': false,        // Pehli purchase ka status
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

  // ✨ --- YEH FUNCTION BHI UPDATE HUA HAI --- ✨
  Future<String?> signInWithGoogle({String? referredByCode}) async {
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

      // Yahan check karenge ki naya user hai ya purana
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
      if (userCredential.user != null) {
        // Agar user naya hai, tabhi referral code ke saath document create karenge
        if (isNewUser) {
          await _createUserInFirestore(userCredential.user!, referredByCode: referredByCode);
        }
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

  // ✨ --- YEH FUNCTION BHI UPDATE HUA HAI --- ✨
  Future<String?> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? referredByCode, // Optional referral code parameter
  }) async {
    try {
      UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Yahan pe referredByCode pass kar rahe hain
        await _createUserInFirestore(userCredential.user!, referredByCode: referredByCode);
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

      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);

      return null;

    } on FirebaseAuthException catch (e) {
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