import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../auth/auth_wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showAnimation = false;

  @override
  void initState() {
    super.initState();

    // 1 second ke baad animation start hoga
    Timer(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _showAnimation = true;
        });
      }
    });

    // Total 4 seconds ke baad (1s logo + 3s animation) agli screen pe jayega
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const AuthWrapper(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Yahan apna logo daalna

            // Animation yahan conditionally show hoga
            if (_showAnimation)
              Lottie.asset(
                'assets/animations/splash_screen.json',
                width: 300,
                height: 300,
                fit: BoxFit.contain,
              ),
          ],
        ),
      ),
    );
  }
}
