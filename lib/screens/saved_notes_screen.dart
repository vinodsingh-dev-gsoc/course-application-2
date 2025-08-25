// lib/screens/saved_notes_screen.dart

import 'package:course_application/screens/pdf_screen_viewer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // Date formatting ke liye
import 'package:lottie/lottie.dart'; // Animations ke liye
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';


class SavedNotesScreen extends StatelessWidget {
  const SavedNotesScreen({super.key});

  // ===== NOTE DELETE KARNE KA FUNCTION =====
  Future<void> _deleteNote(BuildContext context, String noteId) async {
    final String userId = FirebaseAuth.instance.currentUser!.uid;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('saved_notes')
          .doc(noteId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note removed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing note: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text("My Saved Notes", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        elevation: 1,
        centerTitle: true,
      ),
      backgroundColor: Colors.grey[100],
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('saved_notes')
            .orderBy('savedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            // ===== BEHTAR EMPTY STATE =====
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset('assets/animations/empty_box.json', width: 200, height: 200),
                  const SizedBox(height: 20),
                  Text(
                    "You haven't saved any notes yet!",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          var savedNotes = snapshot.data!.docs;

          // ===== GRIDVIEW LAYOUT =====
          return AnimationLimiter(
            child: GridView.builder(
              padding: const EdgeInsets.all(12.0),
              itemCount: savedNotes.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Ek row me 2 cards
                crossAxisSpacing: 12.0,
                mainAxisSpacing: 12.0,
                childAspectRatio: 0.9, // Card ka size adjust karega
              ),
              itemBuilder: (context, index) {
                var noteData = savedNotes[index].data() as Map<String, dynamic>;
                var noteId = savedNotes[index].id;
                Timestamp? timestamp = noteData['savedAt'] as Timestamp?;
                String savedDate = timestamp != null
                    ? DateFormat('MMM d, yyyy').format(timestamp.toDate())
                    : 'N/A';

                return AnimationConfiguration.staggeredGrid(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  columnCount: 2,
                  child: ScaleAnimation(
                    child: FadeInAnimation(
                      child: _buildNoteCard(context, noteId, noteData, savedDate),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // ===== NAYA AUR SUNDAR NOTE CARD WIDGET =====
  Widget _buildNoteCard(BuildContext context, String noteId, Map<String, dynamic> noteData, String savedDate) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PdfViewerScreen(
              pdfUrl: noteData['pdfUrl'],
              title: noteData['title'],
              noteId: noteId,
            ),
          ),
        );
      },
      child: Card(
        elevation: 4,
        shadowColor: Colors.deepPurple.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 32),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.grey),
                    onPressed: () => _deleteNote(context, noteId),
                    tooltip: 'Remove Note',
                  ),
                ],
              ),
              const Spacer(),
              Text(
                noteData['title'] ?? 'Untitled Note',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Saved on: $savedDate',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}