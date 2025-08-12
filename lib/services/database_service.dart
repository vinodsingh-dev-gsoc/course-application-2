import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String? uid; // User ID ko store karne ke liye

  DatabaseService({this.uid});

  // Notes ko save karne ka function (ab ismein price nahi hai)
  Future<String> addNote({
    required String classId,
    required String subjectId,
    required String chapterName,
    required String patternId,
    required String pdfUrl,
    required String fileName,
  }) async {
    try {
      await _db.collection('notes').add({
        'classId': classId,
        'subjectId': subjectId,
        'chapterName': chapterName,
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

  // Naya function: Admin ke liye class ka price set karne ke liye
  Future<void> setClassPrice(String classId, String className, double price) async {
    await _db.collection('classes').doc(classId).set({
      'name': className,
      'price': price,
    });
  }

  // Naya function: User ki purchase record karne ke liye
  Future<void> recordClassPurchase(String classId) async {
    if (uid != null) {
      await _db.collection('users').doc(uid).update({
        'purchasedClasses': FieldValue.arrayUnion([classId])
      });
    }
  }
  Future<List<QueryDocumentSnapshot>> getNotes({
    required String classId,
    required String subjectId,
    required String chapterName,
    required String patternId,
  }) async {
    try {
      final querySnapshot = await _db
          .collection('notes')
          .where('classId', isEqualTo: classId)
          .where('subjectId', isEqualTo: subjectId)
          .where('chapterName', isEqualTo: chapterName)
          .where('patternId', isEqualTo: patternId)
          .get();

      return querySnapshot.docs;
    } catch (e) {
      print('Error getting notes: $e');
      return []; // Error ke case mein empty list return karo
    }
  }
  // Naya function: Check karne ke liye ki user ne class khareedi hai ya nahi
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
