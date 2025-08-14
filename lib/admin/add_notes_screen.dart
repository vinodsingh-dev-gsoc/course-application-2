import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:course_application/services/database_service.dart';
import 'package:course_application/services/storage_service.dart';
import 'package:file_picker/file_picker.dart';
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

// ===== NAYA CHAPTER MODEL =====
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


class AddNotesScreen extends StatefulWidget {
  const AddNotesScreen({super.key});

  @override
  State<AddNotesScreen> createState() => _AddNotesScreenState();
}

class _AddNotesScreenState extends State<AddNotesScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  PlatformFile? _selectedFile;

  final StorageService _storageService = StorageService();
  final DatabaseService _databaseService = DatabaseService();

  List<ClassModel> _classes = [];
  List<PatternModel> _patterns = [];
  List<SubjectModel> _subjects = [];
  List<ChapterModel> _chapters = []; // Chapter list add ki

  ClassModel? _selectedClass;
  PatternModel? _selectedPattern;
  SubjectModel? _selectedSubject;
  ChapterModel? _selectedChapter; // Selected chapter add kiya

  bool _isLoadingClasses = true;
  bool _isLoadingPatterns = false;
  bool _isLoadingSubjects = false;
  bool _isLoadingChapters = false; // Chapter loading state add kiya

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }

  @override
  void dispose() {
    // dispose controller yahan se hata diya kyunki ab text field nahi hai
    super.dispose();
  }

  // ===== DATA FETCHING FUNCTIONS =====

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
      _chapters = []; // Reset chapters
      _selectedPattern = null;
      _selectedSubject = null;
      _selectedChapter = null; // Reset selected chapter
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
      _chapters = []; // Reset chapters
      _selectedSubject = null;
      _selectedChapter = null; // Reset selected chapter
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

  // ===== NAYA FETCH CHAPTERS FUNCTION =====
  Future<void> _fetchChapters(String classId, String patternId, String subjectId) async {
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

  // ===== FILE HANDLING AND SAVING =====

  void _pickFile() async {
    final file = await _storageService.pickFile();
    if (file != null) {
      setState(() {
        _selectedFile = file;
      });
    }
  }

  void _clearFile() {
    setState(() {
      _selectedFile = null;
    });
  }

  void _saveNote() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a PDF file!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // createCourseStructure ki zaroorat yahan nahi hai,
    // kyunki ab hum chapter select kar rahe hain, naya nahi bana rahe har baar.
    // Dialog se naya chapter add hoga.

    final String fileName = _selectedFile!.name;
    final String destination =
        'notes/${_selectedClass!.id}/${_selectedPattern!.id}/${_selectedSubject!.id}/${_selectedChapter!.id}/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    final String? downloadUrl = await _storageService.uploadFile(destination, _selectedFile!);

    if (downloadUrl != null) {
      String result = await _databaseService.addNote(
        classId: _selectedClass!.id,
        subjectId: _selectedSubject!.id,
        chapterId: _selectedChapter!.id, // Selected chapter ka naam
        patternId: _selectedPattern!.id,
        pdfUrl: downloadUrl,
        fileName: fileName,
      );

      if (result == 'Success' && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note uploaded successfully!')),
        );
        // Reset file picker
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
      setState(() => _isLoading = false);
    }
  }

  // ===== DIALOG FOR ADDING NEW ITEMS (UPDATED) =====

  Future<void> _showAddItemDialog(String itemType) async {
    final nameController = TextEditingController();
    final idController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    // Chapter ID ke liye ek function
    String generateId(String name) {
      return name.toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New $itemType'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(labelText: '$itemType Name (e.g., Class 11)'),
                validator: (value) => (value?.isEmpty ?? true) ? 'Name cannot be empty' : null,
                onChanged: (value) {
                  // ID ko automatically generate karo
                  idController.text = generateId(value);
                },
              ),
              TextFormField(
                controller: idController,
                decoration: InputDecoration(labelText: '$itemType ID (auto-generated)'),
                validator: (value) => (value?.isEmpty ?? true) ? 'ID cannot be empty' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await _databaseService.addNewItem(
                  classId: _selectedClass?.id,
                  patternId: _selectedPattern?.id,
                  subjectId: _selectedSubject?.id, // Subject ID pass karo
                  itemType: itemType,
                  itemId: idController.text.trim(),
                  itemName: nameController.text.trim(),
                );
                Navigator.pop(context, true);
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );

    if (result == true) {
      if (itemType == 'Class') await _fetchClasses();
      if (itemType == 'Pattern' && _selectedClass != null) await _fetchPatterns(_selectedClass!.id);
      if (itemType == 'Subject' && _selectedClass != null && _selectedPattern != null) {
        await _fetchSubjects(_selectedClass!.id, _selectedPattern!.id);
      }
      // Naya chapter add hone ke baad fetch karo
      if (itemType == 'Chapter' && _selectedClass != null && _selectedPattern != null && _selectedSubject != null) {
        await _fetchChapters(_selectedClass!.id, _selectedPattern!.id, _selectedSubject!.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add New Note (Smart)", style: GoogleFonts.poppins()),
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
                _buildDropdown<ClassModel>(
                  label: 'Class',
                  value: _selectedClass,
                  items: _classes,
                  onChanged: (value) {
                    setState(() => _selectedClass = value);
                    if (value != null) _fetchPatterns(value.id);
                  },
                  isLoading: _isLoadingClasses,
                  itemAsString: (c) => c.name,
                  onAddNew: () => _showAddItemDialog('Class'),
                ),
                const SizedBox(height: 20),
                _buildDropdown<PatternModel>(
                  label: 'Pattern',
                  value: _selectedPattern,
                  items: _patterns,
                  onChanged: (value) {
                    setState(() => _selectedPattern = value);
                    if (_selectedClass != null && value != null) {
                      _fetchSubjects(_selectedClass!.id, value.id);
                    }
                  },
                  isLoading: _isLoadingPatterns,
                  itemAsString: (p) => p.name,
                  isEnabled: _selectedClass != null,
                  onAddNew: () => _showAddItemDialog('Pattern'),
                ),
                const SizedBox(height: 20),
                _buildDropdown<SubjectModel>(
                  label: 'Subject',
                  value: _selectedSubject,
                  items: _subjects,
                  onChanged: (value) {
                    setState(() => _selectedSubject = value);
                    if (_selectedClass != null && _selectedPattern != null && value != null) {
                      _fetchChapters(_selectedClass!.id, _selectedPattern!.id, value.id);
                    }
                  },
                  isLoading: _isLoadingSubjects,
                  itemAsString: (s) => s.name,
                  isEnabled: _selectedPattern != null,
                  onAddNew: () => _showAddItemDialog('Subject'),
                ),
                const SizedBox(height: 20),

                // ===== CHAPTER TEXTFIELD KI JAGAH NAYA DROPDOWN =====
                _buildDropdown<ChapterModel>(
                  label: 'Chapter',
                  value: _selectedChapter,
                  items: _chapters,
                  onChanged: (value) => setState(() => _selectedChapter = value),
                  isLoading: _isLoadingChapters,
                  itemAsString: (c) => c.name,
                  isEnabled: _selectedSubject != null,
                  onAddNew: () => _showAddItemDialog('Chapter'),
                ),

                const SizedBox(height: 24),
                _buildFilePicker(),
                const SizedBox(height: 24),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                  icon: const Icon(Icons.save, color: Colors.white),
                  onPressed: _saveNote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  label: const Text("Save Note",
                      style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===== DROPDOWN WIDGET (UPDATED FOR "ADD NEW") =====
  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required void Function(T?) onChanged,
    required String Function(T) itemAsString,
    required VoidCallback onAddNew,
    bool isLoading = false,
    bool isEnabled = true,
  }) {
    // Dropdown items ki list banayi
    List<DropdownMenuItem<T>> dropdownItems = items.map((T item) {
      return DropdownMenuItem<T>(
        value: item,
        child: Text(itemAsString(item), style: GoogleFonts.poppins()),
      );
    }).toList();

    return DropdownButtonFormField<T>(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
        filled: !isEnabled,
        fillColor: Colors.grey[200],
        prefixIcon: isLoading
            ? Transform.scale(scale: 0.5, child: const CircularProgressIndicator())
            : null,
      ),
      value: value,
      isExpanded: true,
      items: [
        ...dropdownItems,
        // "Add New" button ek special DropdownMenuItem hai
        DropdownMenuItem(
          // value null rakha taaki yeh select na ho sake
          value: null,
          enabled: false,
          child: InkWell(
            onTap: onAddNew,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Row(
                children: [
                  Icon(Icons.add_circle_outline, color: Colors.green.shade700),
                  const SizedBox(width: 12),
                  Text('Add New $label', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
      ],
      onChanged: isEnabled ? onChanged : null,
      validator: (value) => value == null ? 'Please select a $label' : null,
    );
  }

  Widget _buildFilePicker() {
    if (_selectedFile == null) {
      return OutlinedButton.icon(
        icon: const Icon(Icons.upload_file),
        label: const Text("Upload Notes PDF"),
        onPressed: _pickFile,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.picture_as_pdf, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedFile!.name,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _clearFile,
            ),
          ],
        ),
      );
    }
  }
}