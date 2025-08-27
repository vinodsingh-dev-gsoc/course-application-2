import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:course_application/screens/pdf_screen_viewer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import '../services/database_service.dart';

class NotesDisplayScreen extends StatelessWidget {
  final List<QueryDocumentSnapshot> notes;
  final String subjectName; // Yahan `subjectName` add ho gaya hai! ✨

  const NotesDisplayScreen({
    super.key,
    required this.notes,
    required this.subjectName, // Aur constructor mein bhi!
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(subjectName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        centerTitle: true,
      ),
      body: notes.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: notes.length,
        itemBuilder: (context, index) {
          return _buildNoteCard(context, notes[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset('assets/animations/not_found.json', height: 250),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Text(
              "Oops! No notes found for this chapter yet.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(BuildContext context, QueryDocumentSnapshot note) {
    final noteData = note.data() as Map<String, dynamic>;
    final noteId = note.id;

    final pdfUrl = noteData['pdfUrl'] as String?;
    final fileName = noteData['fileName'] as String? ?? 'Untitled Note';
    final chapterName = noteData['chapterName'] as String? ?? 'No chapter details';

    // Yahan hum file ke naam se ek initial nikal rahe hain for design
    final fileInitial = fileName.isNotEmpty ? fileName[0].toUpperCase() : '?';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 5,
      shadowColor: Colors.deepPurple.withOpacity(0.1),
      clipBehavior: Clip.antiAlias, // Important for rounded corners on gradients
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () {
          if (pdfUrl != null && pdfUrl.isNotEmpty) {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              DatabaseService().addNoteToRecents(user.uid, {
                'id': noteId,
                'title': fileName,
                'pdfUrl': pdfUrl,
                'subjectName': subjectName, // Ab hum subjectName bhi save kar rahe hain!
              });
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PdfViewerScreen(
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
        splashColor: Colors.white.withOpacity(0.3),
        highlightColor: Colors.white.withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple.shade400, Colors.purple.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    fileInitial,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      chapterName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}