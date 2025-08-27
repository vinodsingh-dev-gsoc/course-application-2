import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Isko bhi import karlo

class ReferralScreen extends StatefulWidget {
  final String referralCode;
  final double walletBalance;

  const ReferralScreen({
    super.key,
    required this.referralCode,
    required this.walletBalance,
  });

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  void _shareCode(BuildContext context) {
    final String shareText =
        "Hey! 👋 Join me on PadhaiPedia for the best notes. Use my code '${widget.referralCode}' when you sign up! 📚✨";
    Share.share(shareText);
  }


  void _showWithdrawDialog() {
    final upiController = TextEditingController();
    final amountController = TextEditingController(); // Amount ke liye naya controller
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Withdraw to UPI", style: GoogleFonts.poppins()),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Amount to withdraw",
                    hintText: "e.g., 150",
                    prefixText: "₹",
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Amount cannot be empty";
                    }
                    final double? amount = double.tryParse(value);
                    if (amount == null) {
                      return "Please enter a valid amount";
                    }
                    if (amount > widget.walletBalance) {
                      return "Amount cannot be more than your wallet balance";
                    }
                    if (amount < 100) {
                      return "Minimum withdrawal amount is ₹100";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: upiController,
                  decoration: const InputDecoration(
                    labelText: "Enter your UPI ID",
                    hintText: "yourname@upi",
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "UPI ID cannot be empty";
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    final double withdrawalAmount = double.parse(amountController.text.trim());

                    await FirebaseFirestore.instance.collection('withdrawal_requests').add({
                      'userId': user.uid,
                      'userName': user.displayName,
                      'upiId': upiController.text.trim(),
                      'requestedAmount': withdrawalAmount,
                      'walletBalanceOnRequest': widget.walletBalance, // User ka current balance for validation
                      'requestedAt': FieldValue.serverTimestamp(),
                      'status': 'pending', // Initial status
                    });

                    // User ka wallet balance deduct karo
                    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                      'walletBalance': FieldValue.increment(-withdrawalAmount),
                    });
                  }

                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Withdrawal request has been sent! 💸"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("Refer & Earn",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Lottie.asset('assets/animations/gift_animation.json',
                  height: 180),
              const SizedBox(height: 20),
              _buildWalletBalanceCard(context),
              const SizedBox(height: 30),
              _buildReferralCodeCard(context),
              const SizedBox(height: 30),
              _buildShareButton(context),
              const SizedBox(height: 40),
              _buildHowItWorksSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletBalanceCard(BuildContext context) {
    bool canWithdraw = widget.walletBalance >= 100;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple, Colors.purple.shade300],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "Your Wallet Balance",
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "₹${widget.walletBalance.toStringAsFixed(2)}",
            style: GoogleFonts.poppins(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.account_balance_wallet, color: Colors.deepPurple),
            label: Text(
              "Withdraw Money",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.deepPurple),
            ),
            onPressed: canWithdraw ? _showWithdrawDialog : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          if (!canWithdraw)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                "Minimum ₹100 required to withdraw",
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReferralCodeCard(BuildContext context) {
    return Column(
      children: [
        Text(
          "Share this code with your friends:",
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey[700]),
        ),
        const SizedBox(height: 15),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: widget.referralCode));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Referral code copied to clipboard!"),
                backgroundColor: Colors.black87,
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.deepPurple),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.referralCode,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(width: 15),
                const Icon(Icons.copy, color: Colors.deepPurple),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShareButton(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.share, color: Colors.white),
      label: Text(
        "Share Your Code",
        style: GoogleFonts.poppins(
            fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
      ),
      onPressed: () => _shareCode(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 5,
      ),
    );
  }

  Widget _buildHowItWorksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "How it Works 🤔",
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        _buildStep("1.", "Invite your friends with your unique code."),
        _buildStep("2.", "Your friend signs up using your code."),
        _buildStep(
            "3.", "When they make their first purchase, you get 10% of the amount in your wallet! 💰"),
      ],
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}