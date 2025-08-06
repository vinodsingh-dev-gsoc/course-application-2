import 'package:flutter/material.dart';

class SelectionScreen extends StatefulWidget {
  const SelectionScreen({super.key});

  @override
  State<SelectionScreen> createState() => _SelectionScreenState();
}

class _SelectionScreenState extends State<SelectionScreen> {
  String? _selectedClass;
  String? _selectedPattern;
  String? _selectedSubject;
  String? _selectedChapter;

  final List<String> _classes = ['Class 10', 'Class 11', 'Class 12'];
  final List<String> _patterns = ['CBSE', 'ICSE', 'State Board'];
  final List<String> _subjects = ['Physics', 'Maths', 'Chemistry'];
  final List<String> _chapters = ['Chapter 1', 'Chapter 2', 'Chapter 3'];

  Widget _buildDropdownSelector(
      {required String label,
        required List<String> options,
        required String? selectedOption,
        required void Function(String?) onChanged}) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      ),
      value: selectedOption,
      isExpanded: true,
      items: options.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    bool allOptionsSelected = _selectedClass != null &&
        _selectedPattern != null &&
        _selectedSubject != null &&
        _selectedChapter != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('📚 Select Your Notes'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildDropdownSelector(
                label: 'Select Class',
                options: _classes,
                selectedOption: _selectedClass,
                onChanged: (newValue) {
                  setState(() {
                    _selectedClass = newValue;
                  });
                },
              ),
              const SizedBox(height: 20.0),
              _buildDropdownSelector(
                label: 'Select Pattern',
                options: _patterns,
                selectedOption: _selectedPattern,
                onChanged: (newValue) {
                  setState(() {
                    _selectedPattern = newValue;
                  });
                },
              ),
              const SizedBox(height: 20.0),
              _buildDropdownSelector(
                label: 'Select Subject',
                options: _subjects,
                selectedOption: _selectedSubject,
                onChanged: (newValue) {
                  setState(() {
                    _selectedSubject = newValue;
                  });
                },
              ),
              const SizedBox(height: 20.0),
              _buildDropdownSelector(
                label: 'Select Chapter',
                options: _chapters,
                selectedOption: _selectedChapter,
                onChanged: (newValue) {
                  setState(() {
                    _selectedChapter = newValue;
                  });
                },
              ),
              const SizedBox(height: 40.0),
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
                  print('Class: $_selectedClass');
                  print('Pattern: $_selectedPattern');
                  print('Subject: $_selectedSubject');
                  print('Chapter: $_selectedChapter');
                }
                    : null,
                child: const Text(
                  'Get Notes',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}