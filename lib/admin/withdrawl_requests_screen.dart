import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:lottie/lottie.dart';

class WithdrawalRequestsScreen extends StatelessWidget {
  const WithdrawalRequestsScreen({super.key});

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("UPI ID copied to clipboard!"),
        backgroundColor: Colors.black87,
      ),
    );
  }

  Future<void> _markAsPaid(String docId) async {
    await FirebaseFirestore.instance
        .collection('withdrawal_requests')
        .doc(docId)
        .update({'status': 'completed'});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "Withdrawal Requests",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('withdrawal_requests')
            .orderBy('requestedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(
                    'assets/animations/empty_box.json',
                    width: 200,
                    height: 200,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "No pending withdrawal requests!",
                    style: GoogleFonts.poppins(
                        fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          final requests = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index].data() as Map<String, dynamic>;
              final requestId = requests[index].id;
              final String userName = request['userName'] ?? 'N/A';
              final String userId = request['userId'] ?? 'N/A';
              final String upiId = request['upiId'] ?? 'N/A';
              final double requestedAmount = (request['requestedAmount'] ?? 0.0).toDouble();
              final double walletBalance = (request['walletBalanceOnRequest'] ?? 0.0).toDouble();
              final String status = request['status'] ?? 'pending';

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            userName,
                            style: GoogleFonts.poppins(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: status == 'pending' ? Colors.orange.shade100 : Colors.green.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: status == 'pending' ? Colors.orange.shade800 : Colors.green.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text("User ID: $userId",
                          style: GoogleFonts.poppins(color: Colors.grey[600])),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "UPI ID: $upiId",
                              style: GoogleFonts.poppins(
                                  fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 20),
                            onPressed: () => _copyToClipboard(context, upiId),
                            tooltip: "Copy UPI ID",
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildAmountColumn("Requested", "₹${requestedAmount.toStringAsFixed(2)}", Colors.green),
                          _buildAmountColumn("Wallet Balance", "₹${walletBalance.toStringAsFixed(2)}", Colors.blueGrey),
                        ],
                      ),
                      if(status == 'pending') ...[
                        const SizedBox(height: 15),
                        ElevatedButton.icon(
                          onPressed: () => _markAsPaid(requestId),
                          icon: const Icon(IconlyBold.tick_square,
                              color: Colors.white),
                          label: const Text(
                            "Mark as Paid",
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            minimumSize: const Size(double.infinity, 45),
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAmountColumn(String title, String amount, Color color){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 4),
        Text(amount, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}