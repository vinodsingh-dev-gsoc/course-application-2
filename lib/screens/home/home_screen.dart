import 'package:flutter/material.dart';
import '../account_screen.dart';
import '../selection_screen.dart';
// Ab HomeScreen ek StatefulWidget hai!
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // State variable jo yaad rakhega ki kaunsa tab active hai

  // Is list mein hum saari screens daalenge
  // _HomeScreenContent() hamara purana UI hai
  static final List<Widget> _screens = <Widget>[
    const _HomeScreenContent(), // Index 0: Home
    const Center(child: Text('Saved Screen')), // Index 1: Saved
    const Center(child: Text('Courses Screen')), // Index 2: Courses
    const AccountScreen(), // Index 3: Account
  ];

  // Yeh function tab call hoga jab user kisi tab par tap karega
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Body ab dynamically change hogi _selectedIndex ke hisaab se
      body: _screens.elementAt(_selectedIndex),
      // BottomNavigationBar ab interactive hai
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
            icon: Icon(Icons.book_outlined),
            activeIcon: Icon(Icons.book),
            label: 'Courses',
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
      ),
    );
  }
}

// BEST PRACTICE: Humne Home Screen ke UI ko ek alag private widget mein daal diya
class _HomeScreenContent extends StatelessWidget {
  const _HomeScreenContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: ListView(
            children: [
              const SizedBox(height: 20),
              _buildHeader(),
              const SizedBox(height: 30),
              _buildSearchBar(),
              const SizedBox(height: 30),
              _buildCategories(context),
              const SizedBox(height: 30),
              _buildCourseList(),
            ],
          ),
        ),
      ),
    );
  }

  // Neeche ke saare helper functions ab is widget ka hissa hain
  Widget _buildHeader() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hello', style: TextStyle(fontSize: 18, color: Colors.grey)),
            ],
        ),
        CircleAvatar(
          radius: 25,
          backgroundColor: Color(0xFFE0E0E0),
          child: Icon(Icons.person, size: 30, color: Colors.deepPurple),
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
      child: const TextField(
        decoration: InputDecoration(
          hintText: 'Search for notes...',
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          suffixIcon: Icon(Icons.filter_list, color: Colors.deepPurple),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildCategories(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Category', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        Row(
          children: [
            _buildCategoryButton('All Notes', const Color(0xFFE3F2FD), Colors.blue, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SelectionScreen()));
            }),
            const SizedBox(width: 16),
            _buildCategoryButton('Newest', const Color(0xFFEDE7F6), Colors.deepPurple, () {
              print('Newest button tapped!');
            }),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            _buildCategoryButton('Saved', const Color(0xFFFFF3E0), Colors.orange, () {
              print('Saved button tapped!');
            }),
            const SizedBox(width: 16),
            _buildCategoryButton('Recommend', const Color(0xFFE8F5E9), Colors.green, () {
              print('Recommend button tapped!');
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryButton(String text, Color bgColor, Color textColor, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
          child: Center(
            child: Text(text, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ),
    );
  }

  Widget _buildCourseList() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Notes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(height: 15),
        Center(child: Text('No recent notes yet.', style: TextStyle(color: Colors.grey))),
      ],
    );
  }
}