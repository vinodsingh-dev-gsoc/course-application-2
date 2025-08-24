// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:course_application/screens/change_password_screen.dart';
// Edit Profile screen ko import karlo taaki navigate kar sakein
import 'edit_profile_screen.dart';
import 'home/legal_document_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // In settings ke liye state variables bana lete hain
  bool _pushNotifications = true;
  bool _emailNotifications = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Settings", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        children: [
          _buildSectionHeader("Account"),
          _buildSettingsTile(
            title: "Edit Profile",
            subtitle: "Change your name, photo, etc.",
            icon: IconlyLight.profile,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()));
            },
          ),
          _buildSettingsTile(
            title: "Change Password",
            subtitle: "Update your security",
            icon: IconlyLight.lock,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
              );
            },
          ),
          const SizedBox(height: 20),
          _buildSectionHeader("Notifications"),
          _buildSwitchTile(
            title: "Push Notifications",
            subtitle: "Get updates on new notes and offers",
            icon: IconlyLight.notification,
            value: _pushNotifications,
            onChanged: (value) {
              setState(() {
                _pushNotifications = value;
              });
            },
          ),
          _buildSwitchTile(
            title: "Email Notifications",
            subtitle: "Get summaries and news in your inbox",
            icon: IconlyLight.message,
            value: _emailNotifications,
            onChanged: (value) {
              setState(() {
                _emailNotifications = value;
              });
            },
          ),
          const SizedBox(height: 20),
          _buildSectionHeader("About"),
          _buildSettingsTile(
            title: "Privacy Policy",
            subtitle: "How we handle your data",
            icon: IconlyLight.shield_done,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => const LegalDocumentScreen(
                  title: 'Privacy Policy',
                  markdownFilePath: 'assets/text/privacy_policy.md',
                ),
              ));
            },
          ),
          _buildSettingsTile(
            title: "Terms of Service",
            subtitle: "Read our terms and conditions",
            icon: IconlyLight.document,
            onTap: () { Navigator.push(context, MaterialPageRoute(
              builder: (context) => const LegalDocumentScreen(
                title: 'Terms of Service',
                markdownFilePath: 'assets/text/terms_of_service.md',
              ),
            ));},
          ),
          _buildSettingsTile(
            title: "App Version",
            subtitle: "1.0.0",
            icon: IconlyLight.info_circle,
            onTap: () {},
            // Aage arrow nahi dikhana hai isliye trailing ko null kar denge
            showArrow: false,
          ),
        ],
      ),
    );
  }

  // Section Headers ke liye ek reusable widget
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.poppins(
          color: Colors.grey[600],
          fontWeight: FontWeight.bold,
          fontSize: 14,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // Normal settings tile ke liye ek reusable widget
  Widget _buildSettingsTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool showArrow = true,
  }) {
    return Container(
      color: Colors.white,
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: Colors.deepPurple, size: 24),
        title: Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
        trailing: showArrow ? const Icon(IconlyLight.arrow_right_2, color: Colors.grey) : null,
      ),
    );
  }

  // On/Off switch wale tiles ke liye ek reusable widget
  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      color: Colors.white,
      child: SwitchListTile(
        secondary: Icon(icon, color: Colors.deepPurple, size: 24),
        title: Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
        value: value,
        onChanged: onChanged,
        activeColor: Colors.deepPurple,
      ),
    );
  }
}