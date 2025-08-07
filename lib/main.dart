// main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'auth/auth_wrapper.dart';
import 'firebase_options.dart';

// Apne auth wrapper/dispatcher widget ko import karo
// import 'package:course_application/auth/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // CHANGE 1: Yahan apni poori ID daalo
  const String serverClientId = '227776801675-ltvl5cb2nbi2lskueb39h385bllodmb3m.apps.googleusercontent.com';
  await GoogleSignIn.instance.initialize(
    serverClientId: serverClientId,
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
      // CHANGE 2: Yahan apne app ka starting widget daalo
      home: AuthWrapper(), // Example: AuthWrapper
    );
  }
}