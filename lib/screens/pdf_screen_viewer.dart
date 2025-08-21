// lib/screens/pdf_viewer_screen.dart

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PdfViewerScreen extends StatefulWidget {
  final String pdfUrl;
  final String title;
  final String noteId; // PDF ko uniquely identify karne ke liye

  const PdfViewerScreen({
    super.key,
    required this.pdfUrl,
    required this.title,
    required this.noteId,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  bool _isSaved = false;
  bool _isLoading = true;
  final String _userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _checkIfSaved();
  }

  // Check karo ki yeh note pehle se saved hai ya nahi
  void _checkIfSaved() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('saved_notes')
          .doc(widget.noteId)
          .get();

      if (mounted) {
        setState(() {
          _isSaved = doc.exists;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error checking saved status: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Note ko save/unsave karne ka function
  void _toggleSave() async {
    final noteRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('saved_notes')
        .doc(widget.noteId);

    setState(() => _isLoading = true); // Loading state on

    try {
      if (_isSaved) {
        // Agar pehle se saved hai, toh delete kardo
        await noteRef.delete();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Removed from Saved Notes!")));
      } else {
        // Agar nahi hai, toh save kardo
        await noteRef.set({
          'title': widget.title,
          'pdfUrl': widget.pdfUrl,
          'savedAt': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Note saved successfully!")));
      }

      if (mounted) {
        setState(() {
          _isSaved = !_isSaved; // State ko toggle karo
        });
      }
    } catch (e) {
      print("Error toggling save: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Something went wrong!")));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false); // Loading state off
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: GoogleFonts.poppins()),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          // Yahan humara save button aayega
          _isLoading
              ? const Padding(
            padding: EdgeInsets.only(right: 20.0),
            child: Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0)),
          )
              : IconButton(
            icon: Icon(
              _isSaved ? Icons.bookmark : Icons.bookmark_border,
            ),
            onPressed: _toggleSave,
          ),
        ],
      ),
      body: SfPdfViewer.network(
        widget.pdfUrl,
        onDocumentLoadFailed: (details) {
          print("PDF Load Failed: ${details.error}");
          print("Description: ${details.description}");
        },
      ),
    );
  }
}