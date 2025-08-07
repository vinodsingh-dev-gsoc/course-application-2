import 'package:file_picker/file_picker.dart';
import 'package:course_application/services/database_service.dart';
import 'package:course_application/services/storage_service.dart';
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
  bool _isLoading = false;

  final StorageService _storageService = StorageService();
  final DatabaseService _databaseService = DatabaseService();
  PlatformFile? _selectedFile;

  @override
  void dispose() {
    _classController.dispose();
    _subjectController.dispose();
    _chapterController.dispose();
    _patternController.dispose();
    super.dispose();
  }

  void _pickFile() async {
    final file = await _storageService.pickFile();
    if (file != null) {
      setState(() {
        _selectedFile = file;
      });
    }
  }

  void _saveNote() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a PDF file!')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final String fileName = _selectedFile!.name;
      final String destination =
          'notes/${_classController.text.trim()}/${_subjectController.text.trim()}/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      final String? downloadUrl =
      await _storageService.uploadFile(destination, _selectedFile!);

      if (downloadUrl != null) {
        String result = await _databaseService.addNote(
          classId: _classController.text.trim(),
          subjectId: _subjectController.text.trim(),
          chapterName: _chapterController.text.trim(),
          patternId: _patternController.text.trim(),
          pdfUrl: downloadUrl,
          fileName: fileName,
        );

        if (result == 'Success' && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Note uploaded successfully!')),
          );
          _formKey.currentState!.reset();
          setState(() {
            _selectedFile = null;
          });
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result)),
          );
        }

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error uploading file!')),
        );
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
                _buildTextField(
                    _subjectController, 'Subject ID (e.g., physics)'),
                _buildTextField(
                    _chapterController, 'Chapter Name (e.g., Chapter 1: Light)'),
                _buildTextField(_patternController, 'Pattern ID (e.g., cbse)'),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  icon: const Icon(Icons.upload_file),
                  label: const Text("Upload Notes PDF"),
                  onPressed: _pickFile,
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedFile?.name ?? 'No file selected',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                  onPressed: _saveNote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text("Save Note",
                      style:
                      TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
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
