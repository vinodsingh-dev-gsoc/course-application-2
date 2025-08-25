// lib/screens/home/home_screen.dart

import 'package:carousel_slider/carousel_slider.dart' as custom_carousel;
import 'package:course_application/screens/account_screen.dart';
import 'package:course_application/screens/pdf_screen_viewer.dart';
import 'package:course_application/screens/saved_notes_screen.dart';
import 'package:course_application/screens/selection_screen.dart';
import 'package:course_application/services/database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:course_application/services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NotificationService _notificationService = NotificationService();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  void _initializeNotifications() async {
    await _notificationService.initNotifications();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = <Widget>[
      _HomeScreenContent(onNavigate: _onItemTapped), // Pass the callback
      const SavedNotesScreen(),
      const AccountScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: _buildFancyBottomNavBar(),
    );
  }

  // ===== NAYA AUR FANCY BOTTOM NAVIGATION BAR =====
  Widget _buildFancyBottomNavBar() {
    return Container(
      margin: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25.0),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25.0),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bookmark_border),
              activeIcon: Icon(Icons.bookmark),
              label: 'Saved',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Account',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          selectedItemColor: Colors.deepPurple,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: false,
          showSelectedLabels: false,
          elevation: 0,
        ),
      ),
    );
  }
}


class _HomeScreenContent extends StatefulWidget {
  final Function(int) onNavigate; // Callback to handle navigation
  const _HomeScreenContent({required this.onNavigate});

  @override
  State<_HomeScreenContent> createState() => __HomeScreenContentState();
}

class __HomeScreenContentState extends State<_HomeScreenContent> {
  User? _currentUser;
  String _displayName = 'User';
  int _currentBannerIndex = 0;

  final List<String> eventBanners = [
    'assets/carousel_banner1.png',
    'assets/carousel_banner2.png',
    'assets/carousel_banner3.png',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      setState(() {
        _displayName = _currentUser!.displayName ?? 'User';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildEventsBanner(),
            const SizedBox(height: 24),
            _buildCategories(),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text('Recently Opened',
                  style: GoogleFonts.poppins(
                      fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            _buildRecentNotesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Hello, $_displayName! 👋',
                  style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  "What do you want to learn today?",
                  style:
                  GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => widget.onNavigate(2), // Navigate to Account screen
            child: CircleAvatar(
              radius: 28,
              backgroundImage: _currentUser?.photoURL != null
                  ? NetworkImage(_currentUser!.photoURL!)
                  : null,
              backgroundColor: Colors.deepPurple.withOpacity(0.1),
              child: _currentUser?.photoURL == null
                  ? const Icon(Icons.person,
                  size: 30, color: Colors.deepPurple)
                  : null,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildEventsBanner() {
    return custom_carousel.CarouselSlider(
      items: eventBanners.map((item) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 5.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(
            image: AssetImage(item),
            fit: BoxFit.cover,
          ),
        ),
      )).toList(),
      options: custom_carousel.CarouselOptions(
          height: 160,
          autoPlay: true,
          enlargeCenterPage: true,
          viewportFraction: 0.85,
          onPageChanged: (index, reason) {
            setState(() {
              _currentBannerIndex = index;
            });
          }
      ),
    );
  }


  Widget _buildCategories() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Categories',
              style: GoogleFonts.poppins(
                  fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildCategoryButton(
                'Explore Notes',
                Colors.deepPurple,
                Icons.explore_outlined,
                    () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SelectionScreen()));
                },
              ),
              const SizedBox(width: 16),
              _buildCategoryButton(
                'My Library',
                Colors.orange.shade700,
                Icons.bookmark_added_outlined,
                    () => widget.onNavigate(1), // Navigate to Saved screen
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildCategoryButton(
      String text, Color color, IconData iconData, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(iconData, color: Colors.white, size: 28),
              const SizedBox(height: 8),
              Text(
                text,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentNotesList() {
    if (_currentUser == null) {
      return const Center(child: Text('Please log in to see recent notes.'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: DatabaseService().getRecentNotesStream(_currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong!'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Text('No recently opened notes.',
                    style: GoogleFonts.poppins(color: Colors.grey)),
              ));
        }

        final recentNotes = snapshot.data!.docs;

        return AnimationLimiter(
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentNotes.length,
            itemBuilder: (context, index) {
              final note = recentNotes[index].data() as Map<String, dynamic>;
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 375),
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: _buildRecentNoteCard(note),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildRecentNoteCard(Map<String, dynamic> note) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 24),
        ),
        title: Text(note['title'] ?? 'Untitled Note',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        subtitle: Text(note['subjectName'] ?? 'General', style: GoogleFonts.poppins()),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => PdfViewerScreen(
              noteId: note['id'],
              pdfUrl: note['pdfUrl'],
              title: note['title'],
            ),
          ));
        },
      ),
    );
  }
}