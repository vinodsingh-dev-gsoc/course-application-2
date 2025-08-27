import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:iconly/iconly.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _classController = TextEditingController();
  File? _image;
  String? _photoUrl;
  bool _isLoading = true;

  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      User? user = _authService.currentUser();
      if (user != null) {
        DocumentSnapshot userDataSnapshot =
        await _databaseService.getUser(user.uid);
        if (userDataSnapshot.exists && mounted) {
          final data = userDataSnapshot.data() as Map<String, dynamic>?;
          _nameController.text = data?['displayName'] as String? ?? '';
          _classController.text = data?['class'] as String? ?? '';
          setState(() {
            _photoUrl = data?['photoURL'] as String?;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _classController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile =
    await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    User? user = _authService.currentUser();
    if (user != null) {
      try {
        String? newPhotoUrl = _photoUrl;
        if (_image != null) {
          newPhotoUrl =
          await _storageService.uploadProfilePicture(user.uid, _image!);
        }
        await _databaseService.updateUser(
          user.uid,
          fullName: _nameController.text,
          userClass: _classController.text,
          photoUrl: newPhotoUrl,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Profile Updated Successfully! 🎉'),
                backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update profile: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("Edit Profile",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.grey[50],
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : AnimationLimiter(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: AnimationConfiguration.toStaggeredList(
                duration: const Duration(milliseconds: 375),
                childAnimationBuilder: (widget) => SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: widget,
                  ),
                ),
                children: [
                  _buildProfileAvatar(),
                  const SizedBox(height: 40),
                  _buildTextField(
                    controller: _nameController,
                    labelText: 'Full Name',
                    prefixIcon: IconlyLight.profile,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _classController,
                    labelText: 'Class',
                    prefixIcon: IconlyLight.user,
                  ),
                  const SizedBox(height: 40),
                  _buildSaveButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    ImageProvider? backgroundImage;
    Widget? placeholder;

    if (_image != null) {
      backgroundImage = FileImage(_image!);
    } else if (_photoUrl != null && _photoUrl!.isNotEmpty) {
      backgroundImage = NetworkImage(_photoUrl!);
    } else {
      placeholder = Lottie.asset(
        'assets/animations/profile_avatar.json',
        height: 120,
        width: 120,
        fit: BoxFit.cover,
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        CircleAvatar(
          radius: 70,
          backgroundColor: Colors.deepPurple.withOpacity(0.1),
          backgroundImage: backgroundImage,
          child: placeholder,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child:
              const Icon(IconlyBold.camera, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: GoogleFonts.poppins(),
        prefixIcon: Icon(prefixIcon, color: Colors.grey[600]),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your $labelText';
        }
        return null;
      },
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _saveProfile,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple,
        minimumSize: const Size(double.infinity, 55),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 5,
        shadowColor: Colors.deepPurple.withOpacity(0.4),
      ),
      icon: _isLoading
          ? Container()
          : const Icon(IconlyBold.tick_square, color: Colors.white),
      label: _isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(
        "Save Changes",
        style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}