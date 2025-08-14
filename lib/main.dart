// main.dart
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'auth/auth_wrapper.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAppCheck.instance.activate(
    // Web ke liye
    webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'), // Isko abhi ke liye aise hi chhod do

    // Android ke liye
    // Jab aap app test kar rahe ho (debug mode), to 'debug' provider use hoga.
    // Jab aap app publish karoge (release mode), to 'playIntegrity' use hoga.
    androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,

    // iOS ke liye
    appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.appAttest,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Course Application',
      debugShowCheckedModeBanner: false,
      home: AuthWrapper(),
    );
  }
}