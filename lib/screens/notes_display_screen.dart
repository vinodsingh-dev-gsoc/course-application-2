// lib/screens/notes_display_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:course_application/screens/pdf_screen_viewer.dart';
import 'package:flutter/material.dart';

class NotesDisplayScreen extends StatelessWidget {
  final List<QueryDocumentSnapshot> notes;

  const NotesDisplayScreen({super.key, required this.notes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Available Notes"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: notes.isEmpty
          ? const Center(
        child: Text("Sorry, no notes found for your selection."),
      )
          : ListView.builder(
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final note = notes[index].data() as Map<String, dynamic>;

          // Yeh dono cheezein database se nikaali
          final pdfUrl = note['pdfUrl'];
          final fileName = note['fileName'] ?? 'Note';

          return ListTile(
            leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
            title: Text(fileName),
            subtitle: Text(note['chapterName'] ?? ''),

            // ===== YAHAN CHANGE HUA HAI =====
            onTap: () {
              // Check karo ki URL hai ya nahi
              if (pdfUrl != null && pdfUrl is String && pdfUrl.isNotEmpty) {
                // Agar hai, to nayi screen par jao
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PdfViewerScreen(
                      pdfUrl: pdfUrl,
                      title: fileName,
                    ),
                  ),
                );
              } else {
                // Agar URL nahi hai to error dikhao
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Sorry, PDF link is not available!"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}