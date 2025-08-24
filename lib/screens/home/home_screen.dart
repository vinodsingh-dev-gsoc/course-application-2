// lib/screens/home/home_screen.dart

import 'package:carousel_slider/carousel_slider.dart';
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

  static final List<Widget> _screens = <Widget>[
    const _HomeScreenContent(),
    const SavedNotesScreen(),
    const AccountScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
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
        backgroundColor: Colors.white,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        elevation: 5.0,
      ),
    );
  }
}

class _HomeScreenContent extends StatefulWidget {
  const _HomeScreenContent();

  @override
  State<_HomeScreenContent> createState() => __HomeScreenContentState();
}

class __HomeScreenContentState extends State<_HomeScreenContent> {
  User? _currentUser;
  String _displayName = 'User';
  int _currentBannerIndex = 0;

  final List<String> eventBanners = [
    'Event 1: Flutter Workshop Coming Soon!',
    'Event 2: Live Q&A with Experts!',
    'Event 3: New DSA Course Launch!',
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
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            pinned: false,
            floating: true,
            stretch: true,
            expandedHeight: 100.0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
              const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              title: _buildHeader(),
              background: Container(color: Colors.white),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: _buildSearchBar(),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildEventsBanner(),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
              child: _buildCategories(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 15.0),
              child: Text('Recent Notes',
                  style: GoogleFonts.poppins(
                      fontSize: 22, fontWeight: FontWeight.bold)),
            ),
          ),
          _buildRecentNotesList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
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
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                "Let's start learning",
                style:
                GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            // AccountScreen pe navigate karne ke liye index change karo
            // Yeh better approach hai than pushing a new screen
            // (assuming _onItemTapped is accessible or handled by parent)
          },
          child: CircleAvatar(
            radius: 28,
            backgroundImage: _currentUser?.photoURL != null
                ? NetworkImage(_currentUser!.photoURL!)
                : null,
            backgroundColor: const Color(0xFFE0E0E0),
            child: _currentUser?.photoURL == null
                ? const Icon(Icons.person,
                size: 30, color: Colors.deepPurple)
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(30.0),
      ),
      child: TextField(
        style: GoogleFonts.poppins(),
        decoration: InputDecoration(
          hintText: 'Search for notes...',
          hintStyle: GoogleFonts.poppins(color: Colors.grey),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon:
          const Icon(Icons.filter_list, color: Colors.deepPurple),
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildEventsBanner() {
    return Column(
      children: [
        CarouselSlider(
          items: eventBanners.map((item) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 5.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.deepPurple,
            ),
            child: Center(
              child: Text(
                item,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          )).toList(),
          options: CarouselOptions(
              height: 150,
              autoPlay: true,
              enlargeCenterPage: true,
              aspectRatio: 16/9,
              viewportFraction: 0.8,
              onPageChanged: (index, reason) {
                setState(() {
                  _currentBannerIndex = index;
                });
              }
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: eventBanners.asMap().entries.map((entry) {
            return Container(
              width: 8.0,
              height: 8.0,
              margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.deepPurple)
                    .withOpacity(_currentBannerIndex == entry.key ? 0.9 : 0.4),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Category',
            style: GoogleFonts.poppins(
                fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Row(
          children: [
            _buildCategoryButton(
              'All Notes',
              Colors.blue,
              Icons.menu_book,
                  () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SelectionScreen()));
              },
            ),
            const SizedBox(width: 16),
            _buildCategoryButton(
              'Saved',
              Colors.orange,
              Icons.bookmark,
                  () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SavedNotesScreen()));
              },
            ),
          ],
        ),
      ],
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
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(iconData, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                text,
                style: GoogleFonts.poppins(
                  color: color,
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
      return const SliverToBoxAdapter(
        child: Center(child: Text('Please log in to see recent notes.')),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: DatabaseService().getRecentNotesStream(_currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return const SliverToBoxAdapter(
              child: Center(child: Text('Something went wrong!')));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Text('No recent notes yet.',
                      style: GoogleFonts.poppins(color: Colors.grey)),
                )),
          );
        }

        final recentNotes = snapshot.data!.docs;

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 20.0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final note = recentNotes[index].data() as Map<String, dynamic>;
                return _buildRecentNoteCard(note);
              },
              childCount: recentNotes.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentNoteCard(Map<String, dynamic> note) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      shadowColor: Colors.deepPurple.withOpacity(0.1),
      child: ListTile(
        leading: const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 28),
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