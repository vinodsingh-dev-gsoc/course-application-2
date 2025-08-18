// lib/screens/selection_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:course_application/screens/notes_display_screen.dart';
import 'package:course_application/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

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
  bool _hasPurchased = false; // Purchase status add kiya gaya hai

  final DatabaseService _databaseService = DatabaseService();

  late Razorpay _razorpay;
  // TEST KEY ID yahan hardcode ki hai
  final String _razorpayKeyId = "rzp_test_R63e5HcDWJPQmZ";

  @override
  void initState() {
    super.initState();
    _fetchClasses();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
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

  // Check karega ki notes purchase kiye hain ya nahi
  Future<void> _checkIfPurchased() async {
    if (_selectedChapter == null) return;
    setState(() => _isFetchingNotes = true);
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).get();
      if (userDoc.exists && userDoc.data()!.containsKey('purchasedChapters')) {
        final List purchasedChapters = userDoc.data()!['purchasedChapters'];
        setState(() {
          _hasPurchased = purchasedChapters.contains(_selectedChapter!.id);
        });
      } else {
        setState(() => _hasPurchased = false);
      }
    } catch (e) {
      print("Error checking purchase status: $e");
      setState(() => _hasPurchased = false);
    } finally {
      if(mounted) setState(() => _isFetchingNotes = false);
    }
  }


  void _startPayment() async {
    if (_razorpayKeyId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payment key load nahi hui. Please provide a key in the code.")));
      return;
    }

    setState(() => _isFetchingNotes = true);

    var options = {
      'key': _razorpayKeyId,
      'amount': 5000, // 50 INR in paise
      'name': 'Course Application',
      'description': 'Notes for ${_selectedChapter!.name}',
      'prefill': {'email': FirebaseAuth.instance.currentUser?.email ?? ''}
    };
    try {
      _razorpay.open(options);
    } catch (e) {
      print("Error opening Razorpay checkout: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not start payment. Please try again.")));
    } finally {
      if (mounted) setState(() => _isFetchingNotes = false);
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    print("Payment Successful: ${response.paymentId}");
    // Demo ke liye, hum direct Firestore mein user ko access de rahe hain.
    // Production mein, yeh approach insecure hai.
    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid);
      await userRef.update({
        'purchasedChapters': FieldValue.arrayUnion([_selectedChapter!.id]),
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payment successful! Access granted.")));
      setState(() => _hasPurchased = true);

      // Ab notes screen par navigate karenge
      final notes = await _databaseService.getNotes(
        classId: _selectedClass!.id,
        subjectId: _selectedSubject!.id,
        patternId: _selectedPattern!.id,
        chapterId: _selectedChapter!.id,
      );
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NotesDisplayScreen(notes: notes),
          ),
        );
      }

    } catch (e) {
      print("Error updating user document: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error granting access.")));
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print("Payment Error: ${response.code} - ${response.message}");
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Payment failed: ${response.message}")));
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print("External Wallet: ${response.walletName}");
  }

  void _getNotes() async {
    if (_hasPurchased) {
      setState(() => _isFetchingNotes = true);
      final notes = await _databaseService.getNotes(
        classId: _selectedClass!.id,
        subjectId: _selectedSubject!.id,
        patternId: _selectedPattern!.id,
        chapterId: _selectedChapter!.id,
      );
      setState(() => _isFetchingNotes = false);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NotesDisplayScreen(notes: notes),
          ),
        );
      }
    } else {
      _startPayment();
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
                if (value != null) {
                  _checkIfPurchased();
                }
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
                _hasPurchased ? 'View Notes' : 'Unlock for ₹50',
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
