import 'package:course_application/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';

// Screens jahan navigate karna hai
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import 'subscription_screen.dart';
import 'package:course_application/admin/add_notes_screen.dart';
import 'welcome_screen.dart'; // FIX: WelcomeScreen ko import kiya

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final AuthService _authService = AuthService();
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
  }

  void _logout() async {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Confirm Logout"),
          content: const Text("Are you sure you want to log out?"),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text("Logout", style: TextStyle(color: Colors.red)),
              onPressed: () async {
                // Pehle dialog ko band karo
                Navigator.of(dialogContext).pop();

                // Fir sign out karo
                await _authService.signOut();

                // Finally, WelcomeScreen par jao aur saari purani screens हटा do
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                        (Route<dynamic> route) => false,
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      // Agar user null hai, toh turant WelcomeScreen dikha do.
      // Yeh ek fallback hai, waise to auth stream isko handle karega.
      return const WelcomeScreen();
    }

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
              Text(
                _currentUser?.displayName ?? 'User',
                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                _currentUser?.email ?? 'No email available',
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
              const SizedBox(height: 30),
              const Divider(),
              const SizedBox(height: 10),
              ProfileMenuTile(
                title: "Edit Profile",
                icon: IconlyLight.edit,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()));
                },
              ),
              ProfileMenuTile(
                title: "Settings",
                icon: IconlyLight.setting,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                },
              ),
              ProfileMenuTile(
                title: "My Subscription",
                icon: IconlyLight.wallet,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SubscriptionScreen()));
                },
              ),

              FutureBuilder<bool>(
                future: _authService.isAdmin(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox.shrink();
                  }
                  if (snapshot.hasData && snapshot.data == true) {
                    return ProfileMenuTile(
                      title: "Admin Panel: Add Notes",
                      icon: Icons.admin_panel_settings,
                      textColor: Colors.green[700],
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const AddNotesScreen()));
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              const Divider(),
              const SizedBox(height: 10),
              ProfileMenuTile(
                title: "Logout",
                icon: IconlyLight.logout,
                textColor: Colors.red,
                onTap: _logout,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    final photoUrl = _currentUser?.photoURL;

    return Stack(
      children: [
        CircleAvatar(
          radius: 70,
          backgroundImage: photoUrl != null && photoUrl.isNotEmpty
              ? NetworkImage(photoUrl)
              : const AssetImage('assets/suzume.jpg') as ImageProvider,
          onBackgroundImageError: (_, __) {
            // Agar network image load nahi hoti hai toh fallback
          },
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
}

// Reusable Menu Tile Widget
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
          color: (textColor ?? Colors.deepPurple).withOpacity(0.1),
        ),
        child: Icon(icon, color: textColor ?? Colors.deepPurple),
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
