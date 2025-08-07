// lib/screens/admin/add_notes_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddNotesScreen extends StatefulWidget {
  const AddNotesScreen({super.key});

  @override
  State<AddNotesScreen> createState() => _AddNotesScreenState();
}

class _AddNotesScreenState extends State<AddNotesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _classController = TextEditingController();
  final _subjectController = TextEditingController();
  final _chapterController = TextEditingController();
  final _patternController = TextEditingController();
  final _priceController = TextEditingController();
  bool _isLoading = false;

  // Abhi ke liye hum file upload skip kar rahe hain,
  // pehle text data save karna seekhenge.
  void _saveNote() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Yahan Firestore mein data save karne ka logic aayega (Next Step)
      print('Class: ${_classController.text}');
      print('Subject: ${_subjectController.text}');
      print('Chapter: ${_chapterController.text}');
      print('Pattern: ${_patternController.text}');
      print('Price: ${_priceController.text}');

      // Simulate network call
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note added successfully! (Dummy)')),
        );
        _formKey.currentState!.reset();
      });
    }
  }

  @override
  void dispose() {
    _classController.dispose();
    _subjectController.dispose();
    _chapterController.dispose();
    _patternController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add New Note", style: GoogleFonts.poppins()),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTextField(_classController, 'Class ID (e.g., class_10)'),
                _buildTextField(_subjectController, 'Subject ID (e.g., physics)'),
                _buildTextField(_chapterController, 'Chapter Name (e.g., Chapter 1: Light)'),
                _buildTextField(_patternController, 'Pattern ID (e.g., cbse)'),
                _buildTextField(_priceController, 'Price (e.g., 50)', isNumber: true),
                const SizedBox(height: 24),
                // File upload button abhi ke liye comment out hai
                // OutlinedButton.icon(
                //   icon: const Icon(Icons.upload_file),
                //   label: const Text("Upload Notes PDF"),
                //   onPressed: () { /* File picking logic yahan aayega */ },
                // ),
                const SizedBox(height: 24),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                  onPressed: _saveNote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text("Save Note", style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'This field cannot be empty';
          }
          return null;
        },
      ),
    );
  }
}