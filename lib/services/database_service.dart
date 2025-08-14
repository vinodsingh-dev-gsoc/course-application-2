import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String? uid;

  DatabaseService({this.uid});

  // ===== CHANGE 1: YAHAN chapterId ADD KIYA =====
  Future<String> addNote({
    required String classId,
    required String subjectId,
    required String chapterId, // chapterName ki jagah
    String? chapterName, // Isko bhi rakhenge taaki display aasan ho
    required String patternId,
    required String pdfUrl,
    required String fileName,
  }) async {
    try {
      await _db.collection('notes').add({
        'classId': classId,
        'subjectId': subjectId,
        'chapterId': chapterId, // ID ko save kiya
        'chapterName': chapterName, // Naam ko bhi save kar liya
        'patternId': patternId,
        'pdfUrl': pdfUrl,
        'fileName': fileName,
        'createdAt': FieldValue.serverTimestamp(),
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

  // ===== CHANGE 2: YAHAN chapterId SE QUERY KI =====
  Future<List<QueryDocumentSnapshot>> getNotes({
    required String classId,
    required String subjectId,
    required String chapterId, // chapterName ki jagah
    required String patternId,
  }) async {
    try {
      final querySnapshot = await _db
          .collection('notes')
          .where('classId', isEqualTo: classId)
          .where('subjectId', isEqualTo: subjectId)
          .where('chapterId', isEqualTo: chapterId) // Ab ID se search hoga
          .where('patternId', isEqualTo: patternId)
          .get();

      return querySnapshot.docs;
    } catch (e) {
      print('Error getting notes: $e');
      return [];
    }
  }

  Future<bool> hasAccessToClass(String classId) async {
    if (uid != null) {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data()!.containsKey('purchasedClasses')) {
        final List purchasedClasses = doc.data()!['purchasedClasses'];
        return purchasedClasses.contains(classId);
      }
    }
    return false;
  }
}