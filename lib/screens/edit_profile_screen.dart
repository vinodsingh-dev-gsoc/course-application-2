// lib/screens/edit_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';

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
  bool _isLoading = true; // Start with loading true

  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // ===== YEH RAHA AAPKA FIX! (UPDATED FUNCTION) =====
  Future<void> _loadUserData() async {
    // No need to set state here, already true
    try {
      User? user = _authService.currentUser();
      if (user != null) {
        DocumentSnapshot userDataSnapshot = await _databaseService.getUser(user.uid);
        if (userDataSnapshot.exists && mounted) {
          final data = userDataSnapshot.data() as Map<String, dynamic>?;

          // Use correct field name 'displayName' and handle null safely
          _nameController.text = data?['displayName'] as String? ?? '';

          // Safely access 'class' field, provide empty string if it doesn't exist
          _classController.text = data?['class'] as String? ?? '';

          // Update the photoUrl state
          setState(() {
            _photoUrl = data?['photoURL'] as String?;
          });
        }
      }
    } catch (e) {
      print("Error loading user data: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    } finally {
      // Finally block ensures that the loader is ALWAYS turned off
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
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
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
          newPhotoUrl = await _storageService.uploadProfilePicture(user.uid, _image!);
        }
        await _databaseService.updateUser(
          user.uid,
          fullName: _nameController.text,
          userClass: _classController.text,
          photoUrl: newPhotoUrl,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile Updated Successfully! 🎉')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update profile: $e')),
          );
        }
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // Baaki saara code same rahega
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Profile", style: GoogleFonts.poppins()),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildProfileAvatar(),
              const SizedBox(height: 32),
              _buildTextField(
                controller: _nameController,
                labelText: 'Full Name',
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _classController,
                labelText: 'Class',
                prefixIcon: Icons.school_outlined,
              ),
              const SizedBox(height: 40),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    ImageProvider backgroundImage;
    if (_image != null) {
      backgroundImage = FileImage(_image!);
    } else if (_photoUrl != null && _photoUrl!.isNotEmpty) {
      backgroundImage = NetworkImage(_photoUrl!);
    } else {
      backgroundImage = const AssetImage('assets/Welcome_Image.png');
    }

    return Column(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundImage: backgroundImage,
          backgroundColor: Colors.grey[200],
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.camera_alt, color: Colors.deepPurple),
          label: Text(
            'Change Profile Photo',
            style: GoogleFonts.poppins(color: Colors.deepPurple),
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
        prefixIcon: Icon(prefixIcon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
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
    return ElevatedButton(
      onPressed: _isLoading ? null : _saveProfile,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple,
        minimumSize: const Size(double.infinity, 55),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        "Save Changes",
        style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}