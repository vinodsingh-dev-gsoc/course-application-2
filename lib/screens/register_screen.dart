import 'package:course_application/screens/profile_setup_screen.dart';
import 'package:course_application/services/auth_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:lottie/lottie.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String? result = await _authService.registerWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }

    if (result == null) {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
              (Route<dynamic> route) => false,
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: SafeArea(
        child: AnimationLimiter(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: AnimationConfiguration.toStaggeredList(
                  duration: const Duration(milliseconds: 400),
                  childAnimationBuilder: (widget) => SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(child: widget),
                  ),
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 32),
                    _buildEmailField(),
                    const SizedBox(height: 20),
                    _buildPasswordField(),
                    const SizedBox(height: 20),
                    _buildConfirmPasswordField(),
                    const SizedBox(height: 32),
                    _buildSignUpButton(),
                    const SizedBox(height: 24),
                    _buildLoginNowText(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Lottie.asset(
          'assets/animations/register_animation.json',
          height: 200,
        ),
        const SizedBox(height: 20),
        Text(
          "Create Your Account",
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Join us to start your learning journey!",
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: "Email",
        prefixIcon: const Icon(IconlyLight.message),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your email';
        }
        if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
          return 'Please enter a valid email address';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        labelText: "Password",
        prefixIcon: const Icon(IconlyLight.lock),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? IconlyBold.show : IconlyLight.show,
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a password';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters long';
        }
        return null;
      },
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        labelText: "Confirm Password",
        prefixIcon: const Icon(IconlyLight.lock),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please confirm your password';
        }
        if (value != _passwordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
    );
  }

  Widget _buildSignUpButton() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : ElevatedButton(
      onPressed: _signUp,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple,
        minimumSize: const Size(double.infinity, 55),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 5,
        shadowColor: Colors.deepPurple.withOpacity(0.4),
      ),
      child: Text(
        "Sign Up",
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildLoginNowText() {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: GoogleFonts.poppins(color: Colors.grey[700], fontSize: 15),
        children: [
          const TextSpan(text: "Already a member? "),
          TextSpan(
            text: "Login now",
            style: const TextStyle(
              color: Colors.deepPurple,
              fontWeight: FontWeight.bold,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                Navigator.pop(context);
              },
          ),
        ],
      ),
    );
  }
}