// lib/admin/add_notes_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:course_application/models/selection_models.dart';
import 'package:course_application/services/database_service.dart';
import 'package:course_application/services/storage_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddNotesScreen extends StatefulWidget {
  const AddNotesScreen({super.key});

  @override
  State<AddNotesScreen> createState() => _AddNotesScreenState();
}

class _AddNotesScreenState extends State<AddNotesScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();

  int _currentStep = 0;
  bool _isLoading = false;
  PlatformFile? _selectedFile;

  final StorageService _storageService = StorageService();
  final DatabaseService _databaseService = DatabaseService();

  List<ClassModel> _classes = [];
  List<PatternModel> _patterns = [];
  List<SubjectModel> _subjects = [];
  List<ChapterModel> _chapters = [];

  ClassModel? _selectedClass;
  PatternModel? _selectedPattern;
  SubjectModel? _selectedSubject;
  ChapterModel? _selectedChapter;

  bool _isLoadingClasses = true;
  bool _isLoadingPatterns = false;
  bool _isLoadingSubjects = false;
  bool _isLoadingChapters = false;

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _fetchClasses() async {
    setState(() => _isLoadingClasses = true);
    final snapshot =
    await FirebaseFirestore.instance.collection('classes').get();
    _classes = snapshot.docs
        .map((doc) => ClassModel(id: doc.id, name: doc.data()['name']))
        .toList();
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
    final snapshot = await FirebaseFirestore.instance
        .collection('classes')
        .doc(classId)
        .collection('patterns')
        .get();
    _patterns = snapshot.docs
        .map((doc) => PatternModel(id: doc.id, name: doc.data()['name']))
        .toList();
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
    setState(() => _isLoadingSubjects = false);
  }

  Future<void> _fetchChapters(
      String classId, String patternId, String subjectId) async {
    setState(() {
      _isLoadingChapters = true;
      _chapters = [];
      _selectedChapter = null;
    });
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
    setState(() => _isLoadingChapters = false);
  }

  void _pickFile() async {
    final file = await _storageService.pickFile();
    if (file != null) setState(() => _selectedFile = file);
  }

  void _clearFile() => setState(() => _selectedFile = null);

  void _saveNote() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _currentStep = 4;
      });
      return;
    }

    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a file to upload!')));
      return;
    }
    setState(() => _isLoading = true);
    final String fileName = _selectedFile!.name;
    final String destination =
        'notes/${_selectedClass!.id}/${_selectedPattern!.id}/${_selectedSubject!.id}/${_selectedChapter!.id}/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    final String? downloadUrl =
    await _storageService.uploadFile(destination, _selectedFile!);

    if (downloadUrl != null) {
      final double? amount = double.tryParse(_amountController.text.trim());

      await _databaseService.addNote(
        classId: _selectedClass!.id,
        subjectId: _selectedSubject!.id,
        chapterId: _selectedChapter!.id,
        chapterName: _selectedChapter!.name,
        patternId: _selectedPattern!.id,
        pdfUrl: downloadUrl,
        fileName: fileName,
        amount: amount ?? 0.0,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Note uploaded successfully!')));
        setState(() {
          _selectedFile = null;
          _currentStep = 0;
          _selectedClass = null;
          _selectedPattern = null;
          _selectedSubject = null;
          _selectedChapter = null;
          _patterns = [];
          _subjects = [];
          _chapters = [];
          _amountController.clear();
        });
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Error uploading file!')));
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<Map<String, String>?> _showAddItemDialog(String itemType) async {
    final nameController = TextEditingController();
    final idController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    String generateId(String name) =>
        name.toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');

    return await showDialog<Map<String, String>?>(
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
                decoration: InputDecoration(labelText: '$itemType Name'),
                validator: (value) =>
                (value?.isEmpty ?? true) ? 'Name cannot be empty' : null,
                onChanged: (value) => idController.text = generateId(value),
              ),
              TextFormField(
                controller: idController,
                decoration:
                InputDecoration(labelText: '$itemType ID (auto-generated)'),
                validator: (value) =>
                (value?.isEmpty ?? true) ? 'ID cannot be empty' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final String itemId = idController.text.trim();
                final String itemName = nameController.text.trim();
                await _databaseService.addNewItem(
                  classId: _selectedClass?.id,
                  patternId: _selectedPattern?.id,
                  subjectId: _selectedSubject?.id,
                  itemType: itemType,
                  itemId: itemId,
                  itemName: itemName,
                );
                if (mounted)
                  Navigator.pop(context, {'id': itemId, 'name': itemName});
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text("Add New Note", style: GoogleFonts.poppins()),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white),
      body: Form(
        key: _formKey,
        child: Theme(
          data: ThemeData(
            colorScheme: ColorScheme.light(primary: Colors.deepPurple),
          ),
          child: Stepper(
            type: StepperType.vertical,
            currentStep: _currentStep,
            onStepContinue: () {
              final isLastStep = _currentStep == 4;
              if (isLastStep) {
                _saveNote();
              } else {
                setState(() => _currentStep += 1);
              }
            },
            onStepCancel: () {
              if (_currentStep > 0) {
                setState(() => _currentStep -= 1);
              }
            },
            steps: [
              _buildStep(
                title: 'Class',
                step: 0,
                content: _buildDropdownWithAdd<ClassModel>(
                  label: 'Class',
                  value: _selectedClass,
                  items: _classes,
                  onChanged: (value) {
                    setState(() => _selectedClass = value);
                    if (value != null) _fetchPatterns(value.id);
                  },
                  isLoading: _isLoadingClasses,
                  itemAsString: (c) => c.name,
                  onAddNew: () async {
                    final newItemData = await _showAddItemDialog('Class');
                    if (newItemData != null && mounted) {
                      await _fetchClasses();
                      final newClass = ClassModel(
                          id: newItemData['id']!, name: newItemData['name']!);
                      setState(() => _selectedClass = newClass);
                      _fetchPatterns(newClass.id);
                    }
                  },
                ),
              ),
              _buildStep(
                title: 'Pattern',
                step: 1,
                content: _buildDropdownWithAdd<PatternModel>(
                  label: 'Pattern',
                  value: _selectedPattern,
                  items: _patterns,
                  onChanged: (value) {
                    setState(() => _selectedPattern = value);
                    if (_selectedClass != null && value != null)
                      _fetchSubjects(_selectedClass!.id, value.id);
                  },
                  isLoading: _isLoadingPatterns,
                  itemAsString: (p) => p.name,
                  isEnabled: _selectedClass != null,
                  onAddNew: () async {
                    final newItemData = await _showAddItemDialog('Pattern');
                    if (newItemData != null && mounted) {
                      await _fetchPatterns(_selectedClass!.id);
                      final newPattern = PatternModel(
                          id: newItemData['id']!, name: newItemData['name']!);
                      setState(() => _selectedPattern = newPattern);
                      _fetchSubjects(_selectedClass!.id, newPattern.id);
                    }
                  },
                ),
              ),
              _buildStep(
                title: 'Subject',
                step: 2,
                content: _buildDropdownWithAdd<SubjectModel>(
                  label: 'Subject',
                  value: _selectedSubject,
                  items: _subjects,
                  onChanged: (value) {
                    setState(() => _selectedSubject = value);
                    if (_selectedClass != null &&
                        _selectedPattern != null &&
                        value != null)
                      _fetchChapters(
                          _selectedClass!.id, _selectedPattern!.id, value.id);
                  },
                  isLoading: _isLoadingSubjects,
                  itemAsString: (s) => s.name,
                  isEnabled: _selectedPattern != null,
                  onAddNew: () async {
                    final newItemData = await _showAddItemDialog('Subject');
                    if (newItemData != null && mounted) {
                      await _fetchSubjects(_selectedClass!.id, _selectedPattern!.id);
                      final newSubject = SubjectModel(
                          id: newItemData['id']!, name: newItemData['name']!);
                      setState(() => _selectedSubject = newSubject);
                      _fetchChapters(
                          _selectedClass!.id, _selectedPattern!.id, newSubject.id);
                    }
                  },
                ),
              ),
              _buildStep(
                title: 'Chapter',
                step: 3,
                content: _buildDropdownWithAdd<ChapterModel>(
                  label: 'Chapter',
                  value: _selectedChapter,
                  items: _chapters,
                  onChanged: (value) => setState(() => _selectedChapter = value),
                  isLoading: _isLoadingChapters,
                  itemAsString: (c) => c.name,
                  isEnabled: _selectedSubject != null,
                  onAddNew: () async {
                    final newItemData = await _showAddItemDialog('Chapter');
                    if (newItemData != null && mounted) {
                      await _fetchChapters(_selectedClass!.id,
                          _selectedPattern!.id, _selectedSubject!.id);
                      final newChapter = ChapterModel(
                          id: newItemData['id']!, name: newItemData['name']!);
                      setState(() => _selectedChapter = newChapter);
                    }
                  },
                ),
              ),
              _buildStep(
                title: 'Upload & Save',
                step: 4,
                content: Column(
                  children: [
                    _buildFilePicker(),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Amount (e.g., 49.00)",
                        prefixText: "₹",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an amount';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save, color: Colors.white),
                        onPressed: _saveNote,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding:
                            const EdgeInsets.symmetric(vertical: 16)),
                        label: const Text("Save Note",
                            style: TextStyle(
                                fontSize: 18, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Step _buildStep({
    required String title,
    required int step,
    required Widget content,
  }) {
    return Step(
      title: Text(title),
      content: content,
      isActive: _currentStep >= step,
      state: _currentStep > step ? StepState.complete : StepState.indexed,
    );
  }

  Widget _buildDropdownWithAdd<T>({
    required String label,
    required T? value,
    required List<T> items,
    required void Function(T?) onChanged,
    required String Function(T) itemAsString,
    required VoidCallback onAddNew,
    bool isLoading = false,
    bool isEnabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<T>(
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
                child: Text(itemAsString(item), style: GoogleFonts.poppins()));
          }).toList(),
          onChanged: isEnabled ? onChanged : null,
          validator: (value) => value == null ? 'Please select a $label' : null,
        ),
        const SizedBox(height: 8),
        if (isEnabled)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onAddNew,
              icon: Icon(Icons.add, size: 16),
              label: Text('Add New $label'),
            ),
          )
      ],
    );
  }

  Widget _buildFilePicker() {
    if (_selectedFile == null) {
      return OutlinedButton.icon(
        icon: const Icon(Icons.upload_file),
        label: const Text("Upload Notes PDF"),
        onPressed: _pickFile,
        style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16)),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            const Icon(Icons.picture_as_pdf, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
                child: Text(_selectedFile!.name,
                    overflow: TextOverflow.ellipsis)),
            IconButton(icon: const Icon(Icons.close), onPressed: _clearFile),
          ],
        ),
      );
    }
  }
}