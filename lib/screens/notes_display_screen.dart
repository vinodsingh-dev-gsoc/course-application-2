// lib/screens/notes_display_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:course_application/screens/pdf_screen_viewer.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotesDisplayScreen extends StatelessWidget {
  final List<QueryDocumentSnapshot> notes;

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
        child: Text(
          "Sorry, no notes found for your selection.",
          style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey),
        ),
      )
          : ListView.builder(
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final noteData = notes[index].data() as Map<String, dynamic>;
          final noteId = notes[index].id; // <-- YEH HAI ASLI HERO!

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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PdfViewerScreen(
                        pdfUrl: pdfUrl,
                        title: fileName,
                        noteId: noteId, // <-- HUMNE ID YAHAN PASS KAR DI!
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