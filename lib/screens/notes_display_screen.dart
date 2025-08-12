// lib/screens/notes_display_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
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
      ),
      body: notes.isEmpty
          ? const Center(
        child: Text("Sorry, no notes found for your selection."),
      )
          : ListView.builder(
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final note = notes[index].data() as Map<String, dynamic>;
          return ListTile(
            leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
            title: Text(note['fileName'] ?? 'No Name'),
            subtitle: Text(note['chapterName'] ?? ''),
            onTap: () {
              // Yahan hum PDF viewer open karne ka logic likhenge (future mein)
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Opening ${note['fileName']}...")),
              );
            },
          );
        },
      ),
    );
  }
}