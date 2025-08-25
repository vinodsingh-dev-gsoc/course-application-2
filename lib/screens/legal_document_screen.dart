// lib/screens/legal_document_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';

class LegalDocumentScreen extends StatelessWidget {
  final String title;
  final String markdownFilePath;

  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.markdownFilePath,
  });

  // Yeh function asset file se text load karega
  Future<String> _loadMarkdownAsset() async {
    return await rootBundle.loadString(markdownFilePath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: GoogleFonts.poppins()),
      ),
      body: FutureBuilder<String>(
        future: _loadMarkdownAsset(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Could not load document.'));
          }
          // Markdown widget text ko aache se format karke dikhayega
          return Markdown(
            data: snapshot.data!,
            padding: const EdgeInsets.all(16.0),
          );
        },
      ),
    );
  }
}