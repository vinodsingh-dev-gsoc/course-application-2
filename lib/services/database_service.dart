import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String? uid;

  DatabaseService({this.uid});

  Future<DocumentSnapshot> getUser(String uid) {
    return _db.collection('users').doc(uid).get();
  }

  Stream<DocumentSnapshot> getUserStream(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }

  Stream<QuerySnapshot> getRecentNotesStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('recentNotes')
        .orderBy('lastViewed', descending: true)
        .limit(5)
        .snapshots();
  }

  Future<void> addNoteToRecents(String uid, Map<String, dynamic> noteData) {
    final noteId = noteData['id'];
    return _db
        .collection('users')
        .doc(uid)
        .collection('recentNotes')
        .doc(noteId)
        .set({
      ...noteData,
      'lastViewed': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateUser(String uid, {String? fullName, String? userClass, String? photoUrl}) {
    Map<String, dynamic> dataToUpdate = {};
    if (fullName != null) dataToUpdate['displayName'] = fullName;
    if (userClass != null) dataToUpdate['class'] = userClass;
    if (photoUrl != null) dataToUpdate['photoURL'] = photoUrl;

    if (dataToUpdate.isNotEmpty) {
      return _db.collection('users').doc(uid).update(dataToUpdate);
    }
    return Future.value();
  }

  Future<String> addNote({
    required String classId,
    required String subjectId,
    required String chapterId,
    String? chapterName,
    required String patternId,
    required String pdfUrl,
    required String fileName,
    required double amount,
  }) async {
    try {
      await _db.collection('notes').add({
        'classId': classId,
        'subjectId': subjectId,
        'chapterId': chapterId,
        'chapterName': chapterName,
        'patternId': patternId,
        'pdfUrl': pdfUrl,
        'fileName': fileName,
        'createdAt': FieldValue.serverTimestamp(),
        'amount': amount,
      });
      return 'Success';
    } catch (e) {
      print('Error adding note to Firestore: $e');
      return 'Error: Could not save note details.';
    }
  }

  Future<void> createCourseStructure({
    required String classId,
    required String className,
    required String patternId,
    required String patternName,
    required String subjectId,
    required String subjectName,
    required String chapterId,
    required String chapterName,
  }) async {
    final classDoc = _db.collection('classes').doc(classId);
    final patternDoc = classDoc.collection('patterns').doc(patternId);
    final subjectDoc = patternDoc.collection('subjects').doc(subjectId);
    final chapterDoc = subjectDoc.collection('chapters').doc(chapterId);

    await _db.runTransaction((transaction) async {
      transaction.set(classDoc, {'name': className}, SetOptions(merge: true));
      transaction.set(patternDoc, {'name': patternName}, SetOptions(merge: true));
      transaction.set(subjectDoc, {'name': subjectName}, SetOptions(merge: true));
      transaction.set(chapterDoc, {'name': chapterName}, SetOptions(merge: true));
    });
  }

  Future<void> addNewItem({
    String? classId,
    String? patternId,
    String? subjectId,
    required String itemType,
    required String itemId,
    required String itemName,
  }) async {
    DocumentReference? docRef;
    if (itemType == 'Class') {
      docRef = _db.collection('classes').doc(itemId);
    } else if (itemType == 'Pattern' && classId != null) {
      docRef = _db.collection('classes').doc(classId).collection('patterns').doc(itemId);
    } else if (itemType == 'Subject' && classId != null && patternId != null) {
      docRef = _db.collection('classes').doc(classId).collection('patterns').doc(patternId).collection('subjects').doc(itemId);
    } else if (itemType == 'Chapter' && classId != null && patternId != null && subjectId != null) {
      docRef = _db.collection('classes').doc(classId).collection('patterns').doc(patternId).collection('subjects').doc(subjectId).collection('chapters').doc(itemId);
    }

    if (docRef != null) {
      await docRef.set({'name': itemName});
    }
  }

  Future<List<QueryDocumentSnapshot>> getNotes({
    required String classId,
    required String subjectId,
    required String chapterId,
    required String patternId,
  }) async {
    try {
      final querySnapshot = await _db
          .collection('notes')
          .where('classId', isEqualTo: classId)
          .where('subjectId', isEqualTo: subjectId)
          .where('chapterId', isEqualTo: chapterId)
          .where('patternId', isEqualTo: patternId)
          .get();

      return querySnapshot.docs;
    } catch (e) {
      print('Error getting notes: $e');
      return [];
    }
  }

  // ✨ --- YEH RAHE NAYE FUNCTIONS --- ✨

  // Function to check if the user has purchased a specific chapter
  Future<bool> hasAccessToChapter(String chapterId) async {
    if (uid != null) {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data()!.containsKey('purchasedChapters')) {
        final List purchasedChapters = doc.data()!['purchasedChapters'];
        return purchasedChapters.contains(chapterId);
      }
    }
    return false;
  }

  // Function to add a chapter to the user's purchased list after successful payment
  Future<void> grantChapterAccess(String userId, String chapterId) {
    return _db.collection('users').doc(userId).set({
      'purchasedChapters': FieldValue.arrayUnion([chapterId]),
    }, SetOptions(merge: true));
  }

  // --- YAHAN TAK --- ✨

  Future<DocumentSnapshot> getUserData(String uid) async {
    return _db.collection('users').doc(uid).get();
  }

  Future<void> incrementPdfViewCount(String uid) async {
    return _db.collection('users').doc(uid).update({
      'freePdfViewCount': FieldValue.increment(1),
    });
  }
}