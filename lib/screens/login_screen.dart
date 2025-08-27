import 'package:course_application/auth/forgot_pass.dart';
import 'package:course_application/screens/home/home_screen.dart';
import 'package:course_application/screens/profile_setup_screen.dart';
import 'package:course_application/screens/register_screen.dart';
import 'package:course_application/services/auth_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:lottie/lottie.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
            (Route<dynamic> route) => false,
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);
    String? result = await _authService.signInWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );
    if (mounted) {
      setState(() => _isLoading = false);
    }
    if (result == null) {
      _navigateToHome();
    } else {
      _showErrorSnackBar(result);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    String? result = await _authService.signInWithGoogle();

    if (mounted) {
      setState(() => _isLoading = false);
    }

    if (result == null) {
      _navigateToHome();
    } else if (result == 'new_user') {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
              (Route<dynamic> route) => false,
        );
      }
    } else {
      _showErrorSnackBar(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: AnimationLimiter(
          child: Center(
            child: SingleChildScrollView(
              padding:
              const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
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
                      _buildForgotPasswordButton(context),
                      const SizedBox(height: 25),
                      _buildSignInButton(),
                      const SizedBox(height: 24),
                      _buildDivider(),
                      const SizedBox(height: 24),
                      _buildGoogleSignInButton(),
                      const SizedBox(height: 32),
                      _buildRegisterNowText(context),
                    ],
                  ),
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
          'assets/animations/login_animation.json',
          height: 200,
        ),
        const SizedBox(height: 20),
        Text(
          "Welcome Back!",
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Sign in to continue your learning journey",
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your password';
        }
        return null;
      },
    );
  }

  Widget _buildForgotPasswordButton(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const ForgotPasswordScreen()),
          );
        },
        child: Text(
          "Forgot Password?",
          style: GoogleFonts.poppins(
            color: Colors.deepPurple,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSignInButton() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : ElevatedButton(
      onPressed: _signIn,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 5,
        shadowColor: Colors.deepPurple.withOpacity(0.4),
      ),
      child: Text(
        "Sign In",
        style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            "OR",
            style: GoogleFonts.poppins(color: Colors.grey.shade600),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildGoogleSignInButton() {
    return OutlinedButton.icon(
      icon: Image.asset('assets/google_logo.png', height: 24),
      onPressed: _signInWithGoogle,
      label: Text(
        "Sign In with Google",
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  Widget _buildRegisterNowText(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: GoogleFonts.poppins(color: Colors.grey[700], fontSize: 15),
        children: [
          const TextSpan(text: "Don't have an account? "),
          TextSpan(
            text: "Register now",
            style: const TextStyle(
              color: Colors.deepPurple,
              fontWeight: FontWeight.bold,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RegisterScreen()),
                );
              },
          ),
        ],
      ),
    );
  }
}