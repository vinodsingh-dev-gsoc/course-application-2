// lib/screens/notes_display_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:course_application/screens/pdf_screen_viewer.dart'; // Correct screen name
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/database_service.dart';

class NotesDisplayScreen extends StatelessWidget {
  final List<QueryDocumentSnapshot> notes;
  // TODO: `subjectName` ko yahan pe add karo, for example:
  // final String subjectName;
  // const NotesDisplayScreen({super.key, required this.notes, required this.subjectName});

  const NotesDisplayScreen({super.key, required this.notes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Available Notes", style: GoogleFonts.poppins()),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: notes.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            "Sorry, no notes found for your selection.",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey),
          ),
        ),
      )
          : ListView.builder(
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final noteData = notes[index].data() as Map<String, dynamic>;
          final noteId = notes[index].id;

          final pdfUrl = noteData['pdfUrl'];
          final fileName = noteData['fileName'] ?? 'Untitled Note';
          final chapterName = noteData['chapterName'] ?? 'No chapter details';

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 35),
              title: Text(
                fileName,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                chapterName,
                style: GoogleFonts.poppins(),
              ),
              onTap: () {
                if (pdfUrl != null && pdfUrl is String && pdfUrl.isNotEmpty) {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    // Note ko recents mein add karo
                    DatabaseService().addNoteToRecents(user.uid, {
                      'id': noteId, // Correct: Use noteId
                      'title': fileName, // Correct: Use fileName
                      'pdfUrl': pdfUrl, // Correct: Use pdfUrl
                      // 'subjectName': subjectName, // TODO: Isko enable karne ke liye upar constructor mein add karo
                    });
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PdfViewerScreen( // Correct screen name
                        noteId: noteId,
                        pdfUrl: pdfUrl,
                        title: fileName,
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Sorry, PDF link is not available!"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}