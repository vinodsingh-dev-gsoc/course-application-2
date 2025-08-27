import 'package:course_application/screens/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart'; // Lottie ko import karo
import 'login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin { // TickerProviderStateMixin ka use karo multiple animations ke liye
  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 3, // Lottie ke liye thodi aur jagah
              child: FadeTransition(
                opacity: _fadeInAnimation,
                child: Container(
                  alignment: Alignment.center,
                  // Static Image ko Lottie se replace karo
                  child: Lottie.asset(
                    'assets/animations/welcome_animation.json', // Apna animation yahan daalo
                    height: 300,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2, // Iska flex adjust karo
              child: SlideTransition(
                position: _slideAnimation,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    // Ek sundar sa gradient use karo
                    gradient: LinearGradient(
                      colors: [Colors.deepPurple.shade50, Colors.white],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(50),
                      topRight: Radius.circular(50),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FadeTransition(
                          opacity: _fadeInAnimation,
                          child: Text(
                            "Discover Your\nDream Course Here",
                            style: GoogleFonts.poppins(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        FadeTransition(
                          opacity: _fadeInAnimation,
                          child: Text(
                            "Find the best course for you here. There are a lot of best quality courses around the world.",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        const Spacer(),
                        _buildAuthButtons(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 5,
            ),
            child: const Text(
              "Sign In",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RegisterScreen()),
              );
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.deepPurple.shade200, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: const Text(
              "Sign Up",
              style: TextStyle(color: Colors.deepPurple, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}