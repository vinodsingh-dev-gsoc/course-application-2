import 'package:course_application/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "My Profile",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              _buildProfileAvatar(),
              const SizedBox(height: 20),
              _buildProfileName('Vinod'), // Tumhara naam!
              const SizedBox(height: 10),
              Text(
                'vinod.dev@email.com', // Dummy email
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
              const SizedBox(height: 30),
              const Divider(),
              const SizedBox(height: 10),
              // Menu Items
              ProfileMenuTile(
                title: "Edit Profile",
                icon: IconlyLight.edit,
                onTap: () {
                  print("Edit Profile Tapped!");
                },
              ),
              ProfileMenuTile(
                title: "Settings",
                icon: IconlyLight.setting,
                onTap: () {
                  print("Settings Tapped!");
                },
              ),
              ProfileMenuTile(
                title: "My Subscription",
                icon: IconlyLight.wallet,
                onTap: () {
                  print("Subscription Tapped!");
                },
              ),
              const Divider(),
              const SizedBox(height: 10),
              ProfileMenuTile(
                title: "Logout",
                icon: IconlyLight.logout,
                textColor: Colors.red,
                onTap: () {
                  // Best Practice: User se logout confirm karwana
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("Confirm Logout"),
                        content: const Text("Are you sure you want to log out?"),
                        actions: <Widget>[
                          TextButton(
                            child: const Text("Cancel"),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          TextButton(
                            child: const Text("Logout"),
                            onPressed: () {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const WelcomeScreen()),
                                    (Route<dynamic> route) => false,
                              );
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return Stack(
      children: [
        const CircleAvatar(
          radius: 70,
          backgroundImage: AssetImage('assets/suzume.jpg'), // Ensure this path is correct in pubspec.yaml
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.deepPurple,
              shape: BoxShape.circle,
              border: Border.all(width: 3, color: Colors.white),
            ),
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(
                IconlyBold.camera,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileName(String name) {
    return Text(
      name,
      style: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

// Reusable Menu Tile Widget (BEST PRACTICE!)
class ProfileMenuTile extends StatelessWidget {
  const ProfileMenuTile({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.textColor,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.deepPurple.withOpacity(0.1),
        ),
        child: Icon(icon, color: Colors.deepPurple),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
      trailing: const Icon(
        IconlyLight.arrow_right_2,
        color: Colors.grey,
      ),
    );
  }
}