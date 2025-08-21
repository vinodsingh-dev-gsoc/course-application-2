import 'package:course_application/constant/constant.dart';
import 'package:course_application/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    // Keyboard ko hide karein taki SnackBar aaram se dikhe
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await _authService.sendPasswordResetEmail(
      email: _emailController.text.trim(),
    );

    // Ye check karega ki widget abhi bhi screen pe hai ya nahi
    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset link sent! Check your email.'),
          backgroundColor: Colors.green,
        ),
      );
      // Thoda delay add karte hain taaki user SnackBar padh sake
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // Ek standard AppBar use karna better practice hai
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: Text(
          "Forgot Password",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildImage(),
                const SizedBox(height: 32),
                _buildSubTitle(),
                const SizedBox(height: 32),
                _buildEmailField(),
                const SizedBox(height: 40),
                _buildSentButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    // Thodi animation se feel aachi aati hai ✨
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 50 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Image.asset(
        "assets/forgot.png", // Make sure this asset exists
        height: 250,
      ),
    );
  }

  Widget _buildSubTitle() {
    return Text(
      "Don't worry! Enter your registered email below to receive password reset instruction.",
      textAlign: TextAlign.center,
      style: GoogleFonts.poppins(
        fontSize: 16,
        color: Colors.black54,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      autofocus: true, // User ke liye aasani
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.done, // Keyboard pe 'done' button
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter your email';
        }
        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
        if (!emailRegex.hasMatch(value)) {
          return 'Please enter a valid email address';
        }
        return null;
      },
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.email_outlined),
        labelText: "Email Address",
        hintText: 'you@example.com',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[100],
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _buildSentButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: blue,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 5, // Thoda shadow aacha lagta hai
        shadowColor: blue.withOpacity(0.4),
      ),
      onPressed: _isLoading ? null : _sendResetEmail,
      child: _isLoading
          ? const SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 3,
        ),
      )
          : Text(
        "Send Reset Email",
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}