import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:course_application/models/selection_models.dart';
import 'package:course_application/screens/notes_display_screen.dart';
import 'package:course_application/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:lottie/lottie.dart';

class SelectionScreen extends StatefulWidget {
  const SelectionScreen({super.key});

  @override
  State<SelectionScreen> createState() => _SelectionScreenState();
}

class _SelectionScreenState extends State<SelectionScreen> {
  int _currentStep = 0;
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
  bool _isFetchingNotes = false;
  bool _hasPurchased = false;
  int _freePdfViewCount = 0; // Free view counter

  final DatabaseService _databaseService = DatabaseService();
  late Razorpay _razorpay;
  final String _razorpayKeyId = "rzp_test_R63e5HcDWJPQmZ"; // Replace with your key

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

  void _startPayment() async {
    if (_razorpayKeyId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              "Payment key not configured.")));
      return;
    }

    var options = {
      'key': _razorpayKeyId,
      'amount': 5000, // Amount in paise (e.g., 5000 for ₹50)
      'name': 'Course Application',
      'description': 'Unlock notes for ${_selectedClass!.name}',
      'prefill': {'email': FirebaseAuth.instance.currentUser?.email ?? ''}
    };
    try {
      _razorpay.open(options);
    } catch (e) {
      print("Error opening Razorpay checkout: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Could not start payment. Please try again.")));
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    print("Payment Successful: ${response.paymentId}");
    try {
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid);

      await userRef.set({
        'purchasedClasses': FieldValue.arrayUnion([_selectedClass!.id]),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Payment successful! Class Unlocked."),
        backgroundColor: Colors.green,
      ));
      setState(() => _hasPurchased = true);
      _navigateToNotes();
    } catch (e) {
      print("Error updating user document: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error granting access.")));
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print("Payment Error: ${response.code} - ${response.message}");
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Payment failed: ${response.message}")));
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print("External Wallet: ${response.walletName}");
  }

  void _getNotes() async {
    setState(() => _isFetchingNotes = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _selectedClass == null || _selectedChapter == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please make a complete selection.")));
      setState(() => _isFetchingNotes = false);
      return;
    }

    try {
      final userDoc = await _databaseService.getUserData(user.uid);
      final userData = userDoc.data() as Map<String, dynamic>?;

      final purchasedClasses = (userData?['purchasedClasses'] as List<dynamic>?) ?? [];
      _freePdfViewCount = userData?['freePdfViewCount'] ?? 0;
      _hasPurchased = purchasedClasses.contains(_selectedClass!.id);

      if (_hasPurchased) {
        _navigateToNotes();
      } else if (_freePdfViewCount < 5) {
        await _databaseService.incrementPdfViewCount(user.uid);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Free view used. ${4 - _freePdfViewCount} remaining.'),
          backgroundColor: Colors.blueAccent,
        ));
        _navigateToNotes();
      } else {
        _startPayment();
      }
    } catch (e) {
      print("Error in _getNotes: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Something went wrong. Please try again.")));
    } finally {
      if (mounted) setState(() => _isFetchingNotes = false);
    }
  }

  void _navigateToNotes() async {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('📚 Select Your Notes', style: GoogleFonts.poppins()),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Theme(
        data: ThemeData(
          colorScheme: ColorScheme.light(primary: Colors.deepPurple),
        ),
        child: Stepper(
          type: StepperType.vertical,
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 3) {
              setState(() => _currentStep += 1);
            } else {
              _getNotes();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep -= 1);
            }
          },
          steps: [
            Step(
              title: const Text('Class'),
              content: _buildDropdown<ClassModel>(
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
              isActive: _currentStep >= 0,
              state: _selectedClass != null ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: const Text('Pattern'),
              content: _buildDropdown<PatternModel>(
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
              isActive: _currentStep >= 1,
              state: _selectedPattern != null ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: const Text('Subject'),
              content: _buildDropdown<SubjectModel>(
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
              isActive: _currentStep >= 2,
              state: _selectedSubject != null ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: const Text('Chapter'),
              content: _buildDropdown<ChapterModel>(
                label: 'Select Chapter',
                value: _selectedChapter,
                items: _chapters,
                onChanged: (value) {
                  setState(() {
                    _selectedChapter = value;
                    _hasPurchased = false; // Reset purchase status on new chapter selection
                  });
                },
                isLoading: _isLoadingChapters,
                itemAsString: (ChapterModel c) => c.name,
                isEnabled: _selectedSubject != null,
              ),
              isActive: _currentStep >= 3,
              state: _selectedChapter != null ? StepState.complete : StepState.indexed,
            ),
          ],
        ),
      ),
      bottomNavigationBar: _selectedChapter != null
          ? Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          icon: Icon(_hasPurchased ? Icons.visibility : Icons.lock_open),
          style: ElevatedButton.styleFrom(
            backgroundColor: _hasPurchased ? Colors.green : Colors.orange,
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
          onPressed: _getNotes,
          label: _isFetchingNotes
              ? const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          )
              : Text(
            'Get Notes', // Button text ko simple rakha hai
            style: GoogleFonts.poppins(
                fontSize: 18, color: Colors.white),
          ),
        ),
      )
          : null,
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