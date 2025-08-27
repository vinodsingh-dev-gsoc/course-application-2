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
import 'package:iconly/iconly.dart';

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
      _HomeScreenContent(onNavigate: _onItemTapped),
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
              icon: Icon(IconlyLight.home),
              activeIcon: Icon(IconlyBold.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(IconlyLight.bookmark),
              activeIcon: Icon(IconlyBold.bookmark),
              label: 'Saved',
            ),
            BottomNavigationBarItem(
              icon: Icon(IconlyLight.profile),
              activeIcon: Icon(IconlyBold.profile),
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
  final Function(int) onNavigate;
  const _HomeScreenContent({required this.onNavigate});

  @override
  State<_HomeScreenContent> createState() => __HomeScreenContentState();
}

class __HomeScreenContentState extends State<_HomeScreenContent> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  final List<String> eventBanners = [
    'assets/carousel_banner1.png',
    'assets/carousel_banner2.png',
    'assets/carousel_banner3.png',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildHeader(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  _buildSectionHeader("Special Offers 🔥"),
                  const SizedBox(height: 16),
                  _buildEventsBanner(),
                  const SizedBox(height: 30),
                  _buildSectionHeader("Categories"),
                  const SizedBox(height: 16),
                  _buildCategories(),
                  const SizedBox(height: 30),
                  _buildSectionHeader("Recently Opened",
                      onViewAll: () => widget.onNavigate(1)),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          _buildRecentNotesListSliver(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    if (_currentUser == null) {
      return SliverToBoxAdapter(child: Container());
    }

    return SliverAppBar(
      backgroundColor: Colors.grey[50],
      pinned: true,
      floating: true,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: StreamBuilder<DocumentSnapshot>(
        stream: DatabaseService().getUserStream(_currentUser!.uid),
        builder: (context, snapshot) {
          String displayName = 'User';
          String? photoUrl;

          if (snapshot.hasData && snapshot.data!.exists) {
            final userData = snapshot.data!.data() as Map<String, dynamic>;
            displayName = userData['displayName'] ?? 'User';
            photoUrl = userData['photoURL'];
          }

          return Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, $displayName! 👋',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      "What do you want to learn today?",
                      style: GoogleFonts.poppins(
                          fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => widget.onNavigate(2),
                child: CircleAvatar(
                  radius: 24,
                  backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                  backgroundColor: Colors.deepPurple.withOpacity(0.1),
                  child: photoUrl == null
                      ? const Icon(Icons.person,
                      size: 28, color: Colors.deepPurple)
                      : null,
                ),
              ),
            ],
          );
        },
      ),
    );
  }


  Widget _buildSectionHeader(String title, {VoidCallback? onViewAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            child: Text(
              "View All",
              style: GoogleFonts.poppins(
                  color: Colors.deepPurple, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }

  Widget _buildEventsBanner() {
    return custom_carousel.CarouselSlider.builder(
      itemCount: eventBanners.length,
      itemBuilder: (context, index, realIndex) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            image: DecorationImage(
              image: AssetImage(eventBanners[index]),
              fit: BoxFit.cover,
            ),
          ),
        );
      },
      options: custom_carousel.CarouselOptions(
        height: 160,
        autoPlay: true,
        enlargeCenterPage: true,
        viewportFraction: 1,
      ),
    );
  }

  Widget _buildCategories() {
    return Row(
      children: [
        _buildCategoryButton(
          'Explore Notes',
          Colors.deepPurple,
          IconlyBold.discovery,
              () => Navigator.push(context,
              MaterialPageRoute(builder: (context) => const SelectionScreen())),
        ),
        const SizedBox(width: 16),
        _buildCategoryButton(
          'My Library',
          Colors.orange.shade700,
          IconlyBold.bookmark,
              () => widget.onNavigate(1),
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

  Widget _buildRecentNotesListSliver() {
    if (_currentUser == null) {
      return const SliverToBoxAdapter(
          child: Center(child: Text('Please log in to see recent notes.')));
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
                child: Text('No recently opened notes.',
                    style: GoogleFonts.poppins(color: Colors.grey)),
              ),
            ),
          );
        }

        final recentNotes = snapshot.data!.docs;

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
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
              childCount: recentNotes.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentNoteCard(Map<String, dynamic> note) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
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
          child: const Icon(IconlyBold.document,
              color: Colors.redAccent, size: 24),
        ),
        title: Text(note['title'] ?? 'Untitled Note',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        subtitle: Text(note['subjectName'] ?? 'General',
            style: GoogleFonts.poppins()),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PdfViewerScreen(
                noteId: note['id'],
                pdfUrl: note['pdfUrl'],
                title: note['title'],
              ),
            ),
          );
        },
      ),
    );
  }
}