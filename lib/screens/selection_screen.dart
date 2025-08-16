// lib/screens/selection_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:course_application/screens/notes_display_screen.dart';
import 'package:course_application/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ===== MODELS (SABME == AUR HASHCODE ADDED) =====
class ClassModel {
  final String id;
  final String name;
  ClassModel({required this.id, required this.name});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ClassModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class PatternModel {
  final String id;
  final String name;
  PatternModel({required this.id, required this.name});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is PatternModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class SubjectModel {
  final String id;
  final String name;
  SubjectModel({required this.id, required this.name});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is SubjectModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class ChapterModel {
  final String id;
  final String name;
  ChapterModel({required this.id, required this.name});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ChapterModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}


class SelectionScreen extends StatefulWidget {
  const SelectionScreen({super.key});

  @override
  State<SelectionScreen> createState() => _SelectionScreenState();
}

class _SelectionScreenState extends State<SelectionScreen> {
  // Lists to hold data from Firestore
  List<ClassModel> _classes = [];
  List<PatternModel> _patterns = [];
  List<SubjectModel> _subjects = [];
  List<ChapterModel> _chapters = [];

  // Selected values
  ClassModel? _selectedClass;
  PatternModel? _selectedPattern;
  SubjectModel? _selectedSubject;
  ChapterModel? _selectedChapter;

  // Loading states
  bool _isLoadingClasses = true;
  bool _isLoadingPatterns = false;
  bool _isLoadingSubjects = false;
  bool _isLoadingChapters = false;
  bool _isFetchingNotes = false;

  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }

  // --- Data Fetching Functions (Cascading Logic) ---

  Future<void> _fetchClasses() async {
    setState(() => _isLoadingClasses = true);
    try {
      final snapshot =
      await FirebaseFirestore.instance.collection('classes').get();
      _classes = snapshot.docs
          .map((doc) => ClassModel(id: doc.id, name: doc.data()['name']))
          .toList();
    } catch (e) {
      print("Error fetching classes: $e");
    }
    setState(() => _isLoadingClasses = false);
  }

  Future<void> _fetchPatterns(String classId) async {
    setState(() {
      _isLoadingPatterns = true;
      _patterns = [];
      _subjects = [];
      _chapters = [];
      _selectedPattern = null;
      _selectedSubject = null;
      _selectedChapter = null;
    });
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .collection('patterns')
          .get();
      _patterns = snapshot.docs
          .map((doc) => PatternModel(id: doc.id, name: doc.data()['name']))
          .toList();
    } catch (e) {
      print("Error fetching patterns: $e");
    }
    setState(() => _isLoadingPatterns = false);
  }

  Future<void> _fetchSubjects(String classId, String patternId) async {
    setState(() {
      _isLoadingSubjects = true;
      _subjects = [];
      _chapters = [];
      _selectedSubject = null;
      _selectedChapter = null;
    });
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .collection('patterns')
          .doc(patternId)
          .collection('subjects')
          .get();
      _subjects = snapshot.docs
          .map((doc) => SubjectModel(id: doc.id, name: doc.data()['name']))
          .toList();
    } catch (e) {
      print("Error fetching subjects: $e");
    }
    setState(() => _isLoadingSubjects = false);
  }

  Future<void> _fetchChapters(
      String classId, String patternId, String subjectId) async {
    setState(() {
      _isLoadingChapters = true;
      _chapters = [];
      _selectedChapter = null;
    });
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .collection('patterns')
          .doc(patternId)
          .collection('subjects')
          .doc(subjectId)
          .collection('chapters')
          .get();
      _chapters = snapshot.docs
          .map((doc) => ChapterModel(id: doc.id, name: doc.data()['name']))
          .toList();
    } catch (e) {
      print("Error fetching chapters: $e");
    }
    setState(() => _isLoadingChapters = false);
  }

  void _getNotes() async {
    setState(() => _isFetchingNotes = true);

    // ===== YAHAN CHANGE HUA HAI =====
    final notes = await _databaseService.getNotes(
      classId: _selectedClass!.id,
      subjectId: _selectedSubject!.id,
      patternId: _selectedPattern!.id,
      chapterId: _selectedChapter!.id, // Ab ID se notes dhoondhenge
    );
    // ===== CHANGE KHATAM =====

    setState(() => _isFetchingNotes = false);
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NotesDisplayScreen(notes: notes),
        ),
      );
    }
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
            _buildDropdown<ClassModel>(
              label: 'Select Class',
              value: _selectedClass,
              items: _classes,
              onChanged: (value) {
                setState(() => _selectedClass = value);
                if (value != null) {
                  _fetchPatterns(value.id);
                }
              },
              isLoading: _isLoadingClasses,
              itemAsString: (ClassModel c) => c.name,
            ),
            const SizedBox(height: 20.0),
            _buildDropdown<PatternModel>(
              label: 'Select Pattern',
              value: _selectedPattern,
              items: _patterns,
              onChanged: (value) {
                setState(() => _selectedPattern = value);
                if (_selectedClass != null && value != null) {
                  _fetchSubjects(_selectedClass!.id, value.id);
                }
              },
              isLoading: _isLoadingPatterns,
              itemAsString: (PatternModel p) => p.name,
              isEnabled: _selectedClass != null,
            ),
            const SizedBox(height: 20.0),
            _buildDropdown<SubjectModel>(
              label: 'Select Subject',
              value: _selectedSubject,
              items: _subjects,
              onChanged: (value) {
                setState(() => _selectedSubject = value);
                if (_selectedClass != null &&
                    _selectedPattern != null &&
                    value != null) {
                  _fetchChapters(
                      _selectedClass!.id, _selectedPattern!.id, value.id);
                }
              },
              isLoading: _isLoadingSubjects,
              itemAsString: (SubjectModel s) => s.name,
              isEnabled: _selectedPattern != null,
            ),
            const SizedBox(height: 20.0),
            _buildDropdown<ChapterModel>(
              label: 'Select Chapter',
              value: _selectedChapter,
              items: _chapters,
              onChanged: (value) {
                setState(() => _selectedChapter = value);
              },
              isLoading: _isLoadingChapters,
              itemAsString: (ChapterModel c) => c.name,
              isEnabled: _selectedSubject != null,
            ),
            const SizedBox(height: 40.0),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                allOptionsSelected ? Colors.green : Colors.grey,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              onPressed: allOptionsSelected ? _getNotes : null,
              child: _isFetchingNotes
                  ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
                  : Text(
                'Get Notes',
                style: GoogleFonts.poppins(
                    fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
        prefixIcon: isLoading
            ? Transform.scale(
            scale: 0.5, child: const CircularProgressIndicator())
            : null,
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
      validator: (value) => value == null ? 'Please select an option' : null,
    );
  }
}