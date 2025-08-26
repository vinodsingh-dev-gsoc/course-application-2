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

  // Models and selected items
  List<ClassModel> _classes = [];
  List<PatternModel> _patterns = [];
  List<SubjectModel> _subjects = [];
  List<ChapterModel> _chapters = [];

  ClassModel? _selectedClass;
  PatternModel? _selectedPattern;
  SubjectModel? _selectedSubject;
  ChapterModel? _selectedChapter;
  List<QueryDocumentSnapshot> _fetchedNotes = [];

  // Loading states
  bool _isLoadingClasses = true;
  bool _isLoadingPatterns = false;
  bool _isLoadingSubjects = false;
  bool _isLoadingChapters = false;
  bool _isProcessing = false;

  // Payment and Access states
  bool _hasPurchasedChapter = false;
  double _notesTotalAmount = 0.0;
  int _freePdfViewCount = 0;

  final DatabaseService _databaseService = DatabaseService();
  late Razorpay _razorpay;
  final String _razorpayKeyId = "rzp_test_R9eAZNO40fYk2m"; // Aapki Key

  @override
  void initState() {
    super.initState();
    _fetchClasses();
    _initializeRazorpay();
    _fetchInitialUserData();
  }

  void _initializeRazorpay() {
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

  // --- Data Fetching Logic ---
  Future<void> _fetchClasses() async {
    setState(() => _isLoadingClasses = true);
    final snapshot = await FirebaseFirestore.instance.collection('classes').get();
    _classes = snapshot.docs
        .map((doc) => ClassModel(id: doc.id, name: doc.data()['name']))
        .toList();
    setState(() => _isLoadingClasses = false);
  }

  Future<void> _fetchPatterns(String classId) async {
    setState(() {
      _isLoadingPatterns = true;
      _resetSelections(from: 'pattern');
    });
    final snapshot = await FirebaseFirestore.instance.collection('classes').doc(classId).collection('patterns').get();
    _patterns = snapshot.docs.map((doc) => PatternModel(id: doc.id, name: doc.data()['name'])).toList();
    setState(() => _isLoadingPatterns = false);
  }

  Future<void> _fetchSubjects(String classId, String patternId) async {
    setState(() {
      _isLoadingSubjects = true;
      _resetSelections(from: 'subject');
    });
    final snapshot = await FirebaseFirestore.instance.collection('classes').doc(classId).collection('patterns').doc(patternId).collection('subjects').get();
    _subjects = snapshot.docs.map((doc) => SubjectModel(id: doc.id, name: doc.data()['name'])).toList();
    setState(() => _isLoadingSubjects = false);
  }

  Future<void> _fetchChapters(String classId, String patternId, String subjectId) async {
    setState(() {
      _isLoadingChapters = true;
      _resetSelections(from: 'chapter');
    });
    final snapshot = await FirebaseFirestore.instance.collection('classes').doc(classId).collection('patterns').doc(patternId).collection('subjects').doc(subjectId).collection('chapters').get();
    _chapters = snapshot.docs.map((doc) => ChapterModel(id: doc.id, name: doc.data()['name'])).toList();
    setState(() => _isLoadingChapters = false);
  }

  Future<void> _fetchInitialUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userDoc = await _databaseService.getUserData(user.uid);
    if (userDoc.exists) {
      final userData = userDoc.data() as Map<String, dynamic>;
      setState(() {
        _freePdfViewCount = userData['freePdfViewCount'] ?? 0;
      });
    }
  }

  Future<void> _onChapterSelected(ChapterModel? chapter) async {
    if (chapter == null) {
      setState(() => _selectedChapter = null);
      return;
    };
    setState(() {
      _selectedChapter = chapter;
      _isProcessing = true;
      _hasPurchasedChapter = false;
      _notesTotalAmount = 0.0;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final hasAccess = await _databaseService.hasAccessToChapter(chapter.id);
    if (hasAccess) {
      setState(() {
        _hasPurchasedChapter = true;
        _isProcessing = false;
      });
      return;
    }

    _fetchedNotes = await _databaseService.getNotes(
      classId: _selectedClass!.id,
      subjectId: _selectedSubject!.id,
      patternId: _selectedPattern!.id,
      chapterId: chapter.id,
    );

    double total = 0;
    for (var doc in _fetchedNotes) {
      final data = doc.data() as Map<String, dynamic>;
      total += (data['amount'] ?? 0.0);
    }

    setState(() {
      _notesTotalAmount = total;
      _isProcessing = false;
    });
  }

  // --- Payment Logic ---
  void _startPayment() {
    final user = FirebaseAuth.instance.currentUser;
    var options = {
      'key': _razorpayKeyId,
      'amount': (_notesTotalAmount * 100).toInt(),
      'name': 'PadhaiPedia',
      'description': 'Notes for ${_selectedChapter!.name}',
      'prefill': {'email': user?.email ?? ''},
    };
    try {
      _razorpay.open(options);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payment error. Please try again.")));
      setState(() => _isProcessing = false);
    }
  }

  // ✨ --- YAHAN PAR CHANGE HUA HAI --- ✨
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // --- YEH NAYI LINE ADD KI GAYI HAI ---
    // Reward process shuru karo!
    await _databaseService.processReferralOnPurchase(
      purchaserUid: user.uid,
      purchaseAmount: _notesTotalAmount,
    );
    // --- YAHAN TAK ---

    // Baaki ka logic same rahega
    await _databaseService.grantChapterAccess(user.uid, _selectedChapter!.id);

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("Payment successful! Chapter Unlocked."),
      backgroundColor: Colors.green,
    ));

    setState(() => _hasPurchasedChapter = true);
    _navigateToNotesScreen();
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Payment failed: ${response.message}")));
    setState(() => _isProcessing = false);
  }

  void _handleExternalWallet(ExternalWalletResponse response) { /* Handle external wallet */ }

  // --- UI Logic & Navigation ---
  void _handleGetNotes() async {
    if(_selectedChapter == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a chapter first.")));
      return;
    }
    setState(() => _isProcessing = true);

    if (_hasPurchasedChapter || _notesTotalAmount == 0.0) {
      _navigateToNotesScreen();
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _freePdfViewCount < 5) {
      await _databaseService.incrementPdfViewCount(user.uid);
      setState(() => _freePdfViewCount++);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Free view used. ${5 - _freePdfViewCount} remaining.'),
        backgroundColor: Colors.blueAccent,
      ));
      _navigateToNotesScreen();
      return;
    }
    _startPayment();
  }

  void _navigateToNotesScreen() async {
    if (_fetchedNotes.isEmpty) {
      _fetchedNotes = await _databaseService.getNotes(
        classId: _selectedClass!.id,
        subjectId: _selectedSubject!.id,
        patternId: _selectedPattern!.id,
        chapterId: _selectedChapter!.id,
      );
    }
    if (mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => NotesDisplayScreen(notes: _fetchedNotes)));
    }
    setState(() => _isProcessing = false);
  }

  void _resetSelections({required String from}) {
    if (from == 'pattern') {
      _patterns = []; _subjects = []; _chapters = [];
      _selectedPattern = null; _selectedSubject = null; _selectedChapter = null;
    } else if (from == 'subject') {
      _subjects = []; _chapters = [];
      _selectedSubject = null; _selectedChapter = null;
    } else if (from == 'chapter') {
      _chapters = [];
      _selectedChapter = null;
    }
    _fetchedNotes = [];
    _notesTotalAmount = 0.0;
    _hasPurchasedChapter = false;
  }

  // --- Widgets ---
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
        data: ThemeData(colorScheme: ColorScheme.light(primary: Colors.deepPurple)),
        child: Stepper(
          type: StepperType.vertical,
          currentStep: _currentStep,
          onStepContinue: () {
            final isLastStep = _currentStep == 3;
            if (isLastStep) {
              _handleGetNotes();
            } else if (_isStepComplete(_currentStep)) {
              setState(() => _currentStep += 1);
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep -= 1);
            }
          },
          controlsBuilder: (context, details) {
            final isLastStep = _currentStep == 3;
            return Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: _isProcessing && isLastStep
                  ? Center(child: CircularProgressIndicator())
                  : Row(
                children: [
                  if(isLastStep)
                    _buildFinalButton()
                  else
                    ElevatedButton(
                      onPressed: details.onStepContinue,
                      child: const Text('Continue'),
                    ),
                  const SizedBox(width: 8),
                  if (_currentStep > 0)
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: const Text('Back'),
                    ),
                ],
              ),
            );
          },
          steps: [
            _buildStep(
              title: 'Class',
              step: 0,
              content: _buildDropdown<ClassModel>(
                label: 'Select Class',
                value: _selectedClass,
                items: _classes,
                onChanged: (value) {
                  setState(() => _selectedClass = value);
                  if (value != null) _fetchPatterns(value.id);
                },
                isLoading: _isLoadingClasses,
                itemAsString: (c) => c.name,
              ),
            ),
            _buildStep(
              title: 'Pattern',
              step: 1,
              content: _buildDropdown<PatternModel>(
                label: 'Select Pattern',
                value: _selectedPattern,
                items: _patterns,
                onChanged: (value) {
                  setState(() => _selectedPattern = value);
                  if (_selectedClass != null && value != null) _fetchSubjects(_selectedClass!.id, value.id);
                },
                isLoading: _isLoadingPatterns,
                itemAsString: (p) => p.name,
                isEnabled: _selectedClass != null,
              ),
            ),
            _buildStep(
              title: 'Subject',
              step: 2,
              content: _buildDropdown<SubjectModel>(
                label: 'Select Subject',
                value: _selectedSubject,
                items: _subjects,
                onChanged: (value) {
                  setState(() => _selectedSubject = value);
                  if (_selectedClass != null && _selectedPattern != null && value != null) _fetchChapters(_selectedClass!.id, _selectedPattern!.id, value.id);
                },
                isLoading: _isLoadingSubjects,
                itemAsString: (s) => s.name,
                isEnabled: _selectedPattern != null,
              ),
            ),
            _buildStep(
              title: 'Chapter',
              step: 3,
              content: Column(
                children: [
                  _buildDropdown<ChapterModel>(
                    label: 'Select Chapter',
                    value: _selectedChapter,
                    items: _chapters,
                    onChanged: _onChapterSelected,
                    isLoading: _isLoadingChapters,
                    itemAsString: (c) => c.name,
                    isEnabled: _selectedSubject != null,
                  ),
                  if (_selectedChapter != null && !_isLoadingChapters && _chapters.isNotEmpty && _fetchedNotes.isEmpty && !_isProcessing && _notesTotalAmount == 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: Lottie.asset('assets/animations/empty_box.json', height: 150),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Step _buildStep({required String title, required int step, required Widget content}) {
    return Step(
      title: Text(title),
      content: content,
      isActive: _currentStep >= step,
      state: _isStepComplete(step) ? StepState.complete : StepState.indexed,
    );
  }

  bool _isStepComplete(int step){
    switch(step){
      case 0: return _selectedClass != null;
      case 1: return _selectedPattern != null;
      case 2: return _selectedSubject != null;
      case 3: return _selectedChapter != null;
      default: return false;
    }
  }

  Widget _buildDropdown<T>({
    required String label, required T? value, required List<T> items,
    required void Function(T?) onChanged, required String Function(T) itemAsString,
    bool isLoading = false, bool isEnabled = true,
  }) {
    return DropdownButtonFormField<T>(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
        filled: !isEnabled,
        fillColor: Colors.grey[200],
        prefixIcon: isLoading ? Transform.scale(scale: 0.5, child: const CircularProgressIndicator()) : null,
      ),
      value: value, isExpanded: true,
      items: items.map((T item) => DropdownMenuItem<T>(value: item, child: Text(itemAsString(item)))).toList(),
      onChanged: isEnabled ? onChanged : null,
    );
  }

  Widget _buildFinalButton(){
    if (_selectedChapter == null) {
      return ElevatedButton(onPressed: null, child: Text('Select Chapter'));
    }

    String text;
    Color color;
    IconData icon;

    if (_hasPurchasedChapter) {
      text = 'View Notes';
      color = Colors.green;
      icon = Icons.visibility;
    } else if (_notesTotalAmount > 0) {
      text = 'Unlock for ₹${_notesTotalAmount.toStringAsFixed(0)}';
      color = Colors.orange.shade700;
      icon = Icons.lock_open;
    } else {
      text = 'View Notes (Free)';
      color = Colors.blue;
      icon = Icons.visibility;
    }

    return ElevatedButton.icon(
      icon: Icon(icon),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      onPressed: _handleGetNotes,
      label: Text(text),
    );
  }
}
