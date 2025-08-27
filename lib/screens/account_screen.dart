import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:course_application/admin/add_notes_screen.dart';
import 'package:course_application/screens/edit_profile_screen.dart';
import 'package:course_application/screens/referral_screen.dart';
import 'package:course_application/screens/settings_screen.dart';
import 'package:course_application/screens/welcome_screen.dart';
import 'package:course_application/services/auth_service.dart';
import 'package:course_application/services/database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:course_application/admin/withdrawl_requests_screen.dart'; // Isko import karo

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
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text("Confirm Logout", style: GoogleFonts.poppins()),
          content: Text("Are you sure you want to log out?",
              style: GoogleFonts.poppins()),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child:
              const Text("Logout", style: TextStyle(color: Colors.white)),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _authService.signOut();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const WelcomeScreen()),
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
      backgroundColor: Colors.grey[50],
      body: StreamBuilder<DocumentSnapshot>(
        stream: _databaseService.getUserStream(_currentUser!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Could not load profile data.'));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;

          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildProfileHeader(userData),
                      const SizedBox(height: 30),
                      _buildMenuItems(userData),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 40.0,
      floating: true,
      pinned: true,
      snap: true,
      backgroundColor: Colors.grey[50],
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: Text(
        "My Profile",
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> userData) {
    final String displayName = userData['displayName'] ?? 'User Name';
    final String email = _currentUser!.email ?? 'user.email@example.com';
    final String? photoUrl = userData['photoURL'];

    return Column(
      children: [
        GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (context) => const EditProfileScreen())),
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.deepPurple.shade100,
                backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                    ? NetworkImage(photoUrl)
                    : null,
                child: photoUrl == null || photoUrl.isEmpty
                    ? Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                  style: GoogleFonts.poppins(
                      fontSize: 50, color: Colors.white),
                )
                    : null,
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(IconlyBold.camera,
                    color: Colors.white, size: 18),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        Text(
          displayName,
          style:
          GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Text(
          email,
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildMenuItems(Map<String, dynamic> userData) {
    return AnimationLimiter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 375),
          childAnimationBuilder: (widget) => SlideAnimation(
            horizontalOffset: 50.0,
            child: FadeInAnimation(
              child: widget,
            ),
          ),
          children: [
            _buildSectionHeader("General"),
            _buildMenuCard(
              children: [
                ProfileMenuTile(
                  title: "Edit Profile",
                  icon: IconlyLight.edit,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen())),
                ),
                const Divider(indent: 20, endIndent: 20),
                ProfileMenuTile(
                  title: "Refer & Earn",
                  icon: Icons.card_giftcard_rounded,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReferralScreen(
                        referralCode: userData['referralCode'] ?? 'N/A',
                        walletBalance: (userData['walletBalance'] ?? 0.0).toDouble(),
                      ),
                    ),
                  ),
                ),
                const Divider(indent: 20, endIndent: 20),
                ProfileMenuTile(
                  title: "Settings",
                  icon: IconlyLight.setting,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildAdminCard(),
            _buildSectionHeader("Account"),
            _buildMenuCard(
              children: [
                ProfileMenuTile(
                  title: "Logout",
                  icon: IconlyLight.logout,
                  textColor: Colors.redAccent,
                  onTap: _logout,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildMenuCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildAdminCard() {
    return FutureBuilder<bool>(
      future: _authService.isAdmin(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data == true) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader("Admin Panel"),
              _buildMenuCard(
                children: [
                  ProfileMenuTile(
                    title: "Add Notes",
                    icon: Icons.admin_panel_settings_outlined,
                    textColor: Colors.green[700],
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddNotesScreen())),
                  ),
                  const Divider(indent: 20, endIndent: 20),
                  ProfileMenuTile(
                    title: "Withdrawal Requests",
                    icon: IconlyLight.wallet,
                    textColor: Colors.blue[700],
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const WithdrawalRequestsScreen())),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          );
        }
        return const SizedBox.shrink();
      },
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
    final color = textColor ?? Colors.deepPurple;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: color.withOpacity(0.1),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: textColor ?? Colors.black87,
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