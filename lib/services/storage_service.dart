import 'dart:typed_data'; // Isko import karo bytes ke liye
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Yeh batayega ki app web pe hai ya nahi
import 'dart:io';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // File pick karne ke liye ek common object
  PlatformFile? _pickedFile;

  // File pick karo
  Future<PlatformFile?> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      _pickedFile = result.files.first;
      return _pickedFile;
    }
    return null;
  }

  // File upload karo (Yeh ab web aur mobile dono handle karega)
  Future<String?> uploadFile(String destination, PlatformFile file) async {
    try {
      final ref = _storage.ref(destination);
      UploadTask uploadTask;

      if (kIsWeb) {
        // Web ke liye bytes use karo
        uploadTask = ref.putData(file.bytes!);
      } else {
        // Mobile/Desktop ke liye file path use karo
        uploadTask = ref.putFile(File(file.path!));
      }

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }
}