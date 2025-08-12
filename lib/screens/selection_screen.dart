import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Data ko hold karne ke liye simple models
class ClassModel {
  final String id;
  final String name;
  ClassModel({required this.id, required this.name});
}

class SubjectModel {
  final String id;
  final String name;
  SubjectModel({required this.id, required this.name});
}

class ChapterModel {
  final String id;
  final String name;
  ChapterModel({required this.id, required this.name});
}

class SelectionScreen extends StatefulWidget {
  const SelectionScreen({super.key});

  @override
  State<SelectionScreen> createState() => _SelectionScreenState();
}

class _SelectionScreenState extends State<SelectionScreen> {
  // Lists to hold data from Firestore
  List<ClassModel> _classes = [];
  List<SubjectModel> _subjects = [];
  List<ChapterModel> _chapters = [];

  // Selected values
  ClassModel? _selectedClass;
  SubjectModel? _selectedSubject;
  ChapterModel? _selectedChapter;
  String? _selectedPattern; // Pattern hardcoded rakhte hain for now

  // Loading states
  bool _isLoadingClasses = true;
  bool _isLoadingSubjects = false;
  bool _isLoadingChapters = false;

  final List<String> _patterns = ['CBSE', 'ICSE', 'State Board'];

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }

  // --- Data Fetching Functions ---

  Future<void> _fetchClasses() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('classes').get();
      _classes = snapshot.docs.map((doc) => ClassModel(id: doc.id, name: doc.data()['name'])).toList();
    } catch (e) {
      print("Error fetching classes: $e");
      // Show an error message to the user
    }
    setState(() {
      _isLoadingClasses = false;
    });
  }

  Future<void> _fetchSubjects(String classId) async {
    setState(() {
      _isLoadingSubjects = true;
      _subjects = [];
      _chapters = [];
      _selectedSubject = null;
      _selectedChapter = null;
    });
    try {
      final snapshot = await FirebaseFirestore.instance.collection('classes').doc(classId).collection('subjects').get();
      _subjects = snapshot.docs.map((doc) => SubjectModel(id: doc.id, name: doc.data()['name'])).toList();
    } catch (e) {
      print("Error fetching subjects: $e");
    }
    setState(() {
      _isLoadingSubjects = false;
    });
  }

  Future<void> _fetchChapters(String classId, String subjectId) async {
    setState(() {
      _isLoadingChapters = true;
      _chapters = [];
      _selectedChapter = null;
    });
    try {
      final snapshot = await FirebaseFirestore.instance.collection('classes').doc(classId).collection('subjects').doc(subjectId).collection('chapters').get();
      _chapters = snapshot.docs.map((doc) => ChapterModel(id: doc.id, name: doc.data()['name'])).toList();
    } catch (e) {
      print("Error fetching chapters: $e");
    }
    setState(() {
      _isLoadingChapters = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    bool allOptionsSelected = _selectedClass != null &&
        _selectedPattern != null &&
        _selectedSubject != null &&
        _selectedChapter != null;

    return Scaffold(
      appBar: AppBar(
        title: Text('📚 Select Your Notes', style: GoogleFonts.poppins()),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Class Dropdown ---
            _buildDropdown<ClassModel>(
              label: 'Select Class',
              value: _selectedClass,
              items: _classes,
              onChanged: (value) {
                setState(() {
                  _selectedClass = value;
                });
                if (value != null) {
                  _fetchSubjects(value.id);
                }
              },
              isLoading: _isLoadingClasses,
              itemAsString: (ClassModel c) => c.name,
            ),
            const SizedBox(height: 20.0),

            // --- Pattern Dropdown ---
            _buildDropdown<String>(
              label: 'Select Pattern',
              value: _selectedPattern,
              items: _patterns,
              onChanged: (value) {
                setState(() {
                  _selectedPattern = value;
                });
              },
              itemAsString: (String s) => s,
              // Class select hone par hi enable hoga
              isEnabled: _selectedClass != null,
            ),
            const SizedBox(height: 20.0),

            // --- Subject Dropdown ---
            _buildDropdown<SubjectModel>(
              label: 'Select Subject',
              value: _selectedSubject,
              items: _subjects,
              onChanged: (value) {
                setState(() {
                  _selectedSubject = value;
                });
                if (_selectedClass != null && value != null) {
                  _fetchChapters(_selectedClass!.id, value.id);
                }
              },
              isLoading: _isLoadingSubjects,
              itemAsString: (SubjectModel s) => s.name,
              // Pattern select hone par hi enable hoga
              isEnabled: _selectedPattern != null,
            ),
            const SizedBox(height: 20.0),

            // --- Chapter Dropdown ---
            _buildDropdown<ChapterModel>(
              label: 'Select Chapter',
              value: _selectedChapter,
              items: _chapters,
              onChanged: (value) {
                setState(() {
                  _selectedChapter = value;
                });
              },
              isLoading: _isLoadingChapters,
              itemAsString: (ChapterModel c) => c.name,
              // Subject select hone par hi enable hoga
              isEnabled: _selectedSubject != null,
            ),
            const SizedBox(height: 40.0),

            // --- Get Notes Button ---
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: allOptionsSelected ? Colors.green : Colors.grey,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              onPressed: allOptionsSelected
                  ? () {
                // Yahan notes fetch karne ka logic aayega
                print('Class: ${_selectedClass!.name}');
                print('Pattern: $_selectedPattern');
                print('Subject: ${_selectedSubject!.name}');
                print('Chapter: ${_selectedChapter!.name}');
              }
                  : null,
              child: Text(
                'Get Notes',
                style: GoogleFonts.poppins(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Reusable Dropdown Widget ---
  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required void Function(T?) onChanged,
    required String Function(T) itemAsString,
    bool isLoading = false,
    bool isEnabled = true,
  }) {
    return DropdownButtonFormField<T>(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
        filled: !isEnabled,
        fillColor: Colors.grey[200],
        prefixIcon: isLoading ? Transform.scale(scale: 0.5, child: const CircularProgressIndicator()) : null,
      ),
      value: value,
      isExpanded: true,
      items: items.map((T item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(itemAsString(item), style: GoogleFonts.poppins()),
        );
      }).toList(),
      onChanged: isEnabled ? onChanged : null,
    );
  }
}