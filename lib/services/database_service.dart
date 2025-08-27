import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Constructor se UID hata diya. Service ab stateless hai.
  DatabaseService();

  // Redundant 'getUser' function hata diya.
  Future<DocumentSnapshot> getUserData(String uid) {
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
    return _db.collection('users').doc(uid).collection('recentNotes').doc(noteId).set({
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

  // BEST PRACTICE: Notes ko nested structure mein add karna.
  Future<String> addNote({
    required String classId,
    required String patternId,
    required String subjectId,
    required String chapterId,
    required String pdfUrl,
    required String fileName,
    required double amount,
    String? chapterName, // Optional parameter ko last mein rakha.
  }) async {
    try {
      final noteCollectionRef = _db
          .collection('classes')
          .doc(classId)
          .collection('patterns')
          .doc(patternId)
          .collection('subjects')
          .doc(subjectId)
          .collection('chapters')
          .doc(chapterId)
          .collection('notes');

      await noteCollectionRef.add({
        'pdfUrl': pdfUrl,
        'fileName': fileName,
        'amount': amount,
        'createdAt': FieldValue.serverTimestamp(),
        // Redundant IDs store karne ki zaroorat nahi.
      });
      return 'Success';
    } catch (e) {
      print('Error adding note: $e');
      throw Exception('Error: Could not save note details.');
    }
  }

  // BEST PRACTICE: Notes ko nested structure se get karna.
  Future<List<QueryDocumentSnapshot>> getNotes({
    required String classId,
    required String patternId,
    required String subjectId,
    required String chapterId,
  }) async {
    try {
      final querySnapshot = await _db
          .collection('classes')
          .doc(classId)
          .collection('patterns')
          .doc(patternId)
          .collection('subjects')
          .doc(subjectId)
          .collection('chapters')
          .doc(chapterId)
          .collection('notes')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs;
    } catch (e) {
      print('Error getting notes: $e');
      throw Exception('Could not fetch notes.');
    }
  }

  // Yeh function unchanged hai, structure create karne ke liye perfect hai.
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

  // Yeh bhi unchanged hai.
  Future<void> addNewItem({
    required String itemType,
    required String itemId,
    required String itemName,
    String? classId,
    String? patternId,
    String? subjectId,
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
      await docRef.set({'name': itemName}, SetOptions(merge: true));
    }
  }

  // Humare pichle discussion ke according, class-level access.
  Future<bool> hasAccessToClass(String uid, String classId) async {
    final doc = await getUserData(uid);
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      if (data.containsKey('purchasedClasses') && data['purchasedClasses'] is List) {
        return (data['purchasedClasses'] as List).contains(classId);
      }
    }
    return false;
  }

  Future<void> grantClassAccess(String uid, String classId) {
    return _db.collection('users').doc(uid).update({
      'purchasedClasses': FieldValue.arrayUnion([classId]),
    });
  }

  Future<void> incrementPdfViewCount(String uid) {
    return _db.collection('users').doc(uid).update({
      'freePdfViewCount': FieldValue.increment(1),
    });
  }

  // --- Referral System Functions ---

  Future<void> updateReferralInfo(String uid, String referredByCode) async {
    if (referredByCode.trim().isEmpty) return;
    final userDocRef = _db.collection('users').doc(uid);
    final snapshot = await userDocRef.get();
    if (snapshot.exists) {
      final data = snapshot.data() as Map<String, dynamic>;
      final hasReferrer = data.containsKey('referredBy') && data['referredBy'] != null;
      if (!hasReferrer) {
        await userDocRef.update({'referredBy': referredByCode.trim()});
      }
    }
  }

  Future<void> processReferralOnPurchase({
    required String purchaserUid,
    required double purchaseAmount,
  }) async {
    try {
      final purchaserDocRef = _db.collection('users').doc(purchaserUid);
      final purchaserDoc = await purchaserDocRef.get();

      if (!purchaserDoc.exists) throw Exception('Purchaser not found.');

      final purchaserData = purchaserDoc.data() as Map<String, dynamic>;
      final isFirstPurchase = !(purchaserData['firstPurchaseMade'] ?? false);
      final String? referredByCode = purchaserData['referredBy'];

      if (isFirstPurchase && referredByCode != null && referredByCode.isNotEmpty) {
        final referrerQuery = await _db.collection('users').where('referralCode', isEqualTo: referredByCode).limit(1).get();

        if (referrerQuery.docs.isNotEmpty) {
          final referrerDoc = referrerQuery.docs.first;
          final double rewardAmount = purchaseAmount * 0.10;

          await _db.runTransaction((transaction) async {
            transaction.update(referrerDoc.reference, {'walletBalance': FieldValue.increment(rewardAmount)});
            transaction.update(purchaserDocRef, {'firstPurchaseMade': true});
          });
        } else {
          await purchaserDocRef.update({'firstPurchaseMade': true});
        }
      } else if (isFirstPurchase) {
        await purchaserDocRef.update({'firstPurchaseMade': true});
      }
    } catch (e) {
      print('An unexpected error occurred while processing referral: $e');
      throw Exception('Could not process referral reward.');
    }
  }
}