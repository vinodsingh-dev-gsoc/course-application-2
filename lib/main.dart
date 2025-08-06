import 'package:flutter/material.dart';
import 'package:course_application/auth/auth_wrapper.dart';
import 'package:firebase_core/firebase_core.dart'; // Yeh import zaroori hai
import 'firebase_options.dart'; // Yeh file flutterfire ne banayi thi

Future<void >main()async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Course App',
      home: AuthWrapper(),
    );
  }
}