// lib/screens/account_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:course_application/services/database_service.dart';
import 'package:course_application/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';

import '../admin/add_notes_screen.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import 'welcome_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = _authService.currentUser();
  }

  void _logout() async {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                Navigator.of(dialogContext).pop();
                await _authService.signOut();
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
      return const WelcomeScreen();
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          "My Profile",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              _buildProfileSection(),
              const SizedBox(height: 20),
              _buildMenuCard(),
              const SizedBox(height: 20),
              _buildAdminCard(),
              const SizedBox(height: 10),
              _buildLogoutCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _databaseService.getUserStream(_currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('Could not load profile data.'));
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final String displayName = userData['displayName'] ?? 'User Name';
        final String email = _currentUser!.email ?? 'user.email@example.com';
        final String? photoUrl = userData['photoURL'];

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 10,
              )
            ],
          ),
          child: Column(
            children: [
              _buildProfileAvatar(photoUrl),
              const SizedBox(height: 15),
              Text(
                displayName,
                style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(
                email,
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileAvatar(String? photoUrl) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()));
      },
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                ? NetworkImage(photoUrl)
                : const AssetImage('assets/Welcome_Image.png') as ImageProvider,
            backgroundColor: Colors.grey[200],
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
                padding: EdgeInsets.all(6.0),
                child: Icon(
                  IconlyBold.camera,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          ProfileMenuTile(
            title: "Edit Profile",
            icon: IconlyLight.edit,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()));
            },
          ),
          const Divider(indent: 20, endIndent: 20),
          ProfileMenuTile(
            title: "Settings",
            icon: IconlyLight.setting,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdminCard() {
    return FutureBuilder<bool>(
      future: _authService.isAdmin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        if (snapshot.hasData && snapshot.data == true) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: ProfileMenuTile(
              title: "Admin Panel: Add Notes",
              icon: Icons.admin_panel_settings_outlined,
              textColor: Colors.green[700],
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AddNotesScreen()));
              },
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLogoutCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ProfileMenuTile(
        title: "Logout",
        icon: IconlyLight.logout,
        textColor: Colors.redAccent,
        onTap: _logout,
      ),
    );
  }
}

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
          fontWeight: FontWeight.w600,
          color: textColor,
          fontSize: 16,
        ),
      ),
      trailing: const Icon(
        IconlyLight.arrow_right_2,
        color: Colors.grey,
      ),
    );
  }
}