import 'package:course_application/auth/forgot_pass.dart';
import 'package:course_application/auth/reset_pass.dart';
import 'package:course_application/constant/constant.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:otp_text_field/otp_field.dart';
import 'package:otp_text_field/style.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  void _sendOtp() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Simulate a network request
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          _isLoading = false;
        });
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ResetPasswordScreen()),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildBackButton(context),
                _buildImage(),
                _buildTitle(),
                _buildSubTitle(),
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                  child: Form(
                    key: _formKey,
                    child: _buildForm(),
                  ),
                ),
              ],
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
        "Don't worry! Input your email for reset password",
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
        const SizedBox(height: 20),
        _buildLabel("OTP Code"),
        const SizedBox(height: 10),
        _buildOtpField(),
        const SizedBox(height: 30),
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
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextFormField(
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
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                vertical: 15,
              ),
              elevation: 0,
              backgroundColor: blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {},
            child: const Icon(IconlyLight.arrow_right),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpField() {
    return OTPTextField(
      contentPadding: const EdgeInsets.symmetric(vertical: 20),
      length: 5,
      width: MediaQuery.of(context).size.width,
      textFieldAlignment: MainAxisAlignment.spaceAround,
      fieldWidth: 60,
      fieldStyle: FieldStyle.box,
      outlineBorderRadius: 15,
      style: const TextStyle(fontSize: 17),
      onChanged: (pin) {
        print("Changed: $pin");
      },
      onCompleted: (pin) {
        print("Completed: $pin");
      },
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
      onPressed: _sendOtp,
      child: const Text("Sent"),
    );
  }
}