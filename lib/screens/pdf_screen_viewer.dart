// lib/screens/pdf_viewer_screen.dart

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:google_fonts/google_fonts.dart';

class PdfViewerScreen extends StatelessWidget {
  final String pdfUrl;
  final String title;

  const PdfViewerScreen({super.key, required this.pdfUrl, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: GoogleFonts.poppins()),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      // Yeh widget network se PDF load karke dikhaega
      body: SfPdfViewer.network(
        pdfUrl,
        // Optional: Loading indicator dikhane ke liye
        onDocumentLoadFailed: (details) {
          print("PDF Load Failed: ${details.error}");
          print("Description: ${details.description}");
        },
      ),
    );
  }
}