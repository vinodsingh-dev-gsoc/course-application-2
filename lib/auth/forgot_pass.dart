import 'package:course_application/constant/constant.dart';
import 'package:course_application/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';

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

  void _sendResetEmail() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final result = await _authService.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        if (result == 'Success') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Password reset link sent! Check your email.')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result ?? 'An error occurred')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildBackButton(context),
                  _buildImage(),
                  _buildTitle(),
                  _buildSubTitle(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 40),
                    child: _buildForm(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Row(
          children: [
            const Icon(
              IconlyLight.arrow_left,
              color: Colors.black54,
            ),
            const SizedBox(width: 10),
            Text(
              "Back",
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    return Image.asset(
      "assets/forgot.png",
      width: 300,
    );
  }

  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Text(
        "Forgot Password?",
        style: GoogleFonts.poppins(
            fontSize: 25, fontWeight: FontWeight.w600, color: black),
      ),
    );
  }

  Widget _buildSubTitle() {
    return const Padding(
      padding: EdgeInsets.only(top: 20, bottom: 20),
      child: Text(
        "Don't worry! Input your email to reset your password.",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16, color: Colors.black54),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel("Email Address"),
        const SizedBox(height: 10),
        _buildEmailField(),
        const SizedBox(height: 40),
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildSentButton(),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
          fontWeight: FontWeight.w600, color: Colors.black54, fontSize: 16),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your email';
        }
        if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
          return 'Please enter a valid email address';
        }
        return null;
      },
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        labelText: "Email",
        hintText: 'Enter Email',
      ),
    );
  }

  Widget _buildSentButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: blue,
        fixedSize: Size.fromWidth(MediaQuery.of(context).size.width),
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      onPressed: _sendResetEmail,
      child: const Text("Send Reset Email"),
    );
  }
}