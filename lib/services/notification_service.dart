// lib/services/notification_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:course_application/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// IMPORTANT: Yeh function class ke bahar hona chahiye
// Jab app terminated state mein ho, to background notification handle karne ke liye
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
  print("Message data: ${message.data}");
  print("Message notification: ${message.notification?.title}");
}

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final AuthService _authService = AuthService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> initNotifications() async {
    // 1. User se permission maango (iOS & Android 13+ ke liye zaroori)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');

      // Background message handler ko setup karo
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 2. Device ka unique FCM token get karo
      final fcmToken = await _fcm.getToken();
      print('FCM Token: $fcmToken');

      // 3. Token ko Firestore mein save karo
      if (fcmToken != null) {
        await _saveTokenToDatabase(fcmToken);
      }

      // 4. Jab naya token generate ho to usko bhi save karo
      _fcm.onTokenRefresh.listen(_saveTokenToDatabase);

    } else {
      print('User declined or has not accepted permission');
    }
  }

  Future<void> _saveTokenToDatabase(String token) async {
    final user = _authService.currentUser();
    if (user != null) {
      final userDocRef = _db.collection('users').doc(user.uid);

      // 'fcmTokens' naam ka ek array maintain karo
      // Taaki user multiple devices se login kar sake
      await userDocRef.set({
        'fcmTokens': FieldValue.arrayUnion([token])
      }, SetOptions(merge: true));
    }
  }
}