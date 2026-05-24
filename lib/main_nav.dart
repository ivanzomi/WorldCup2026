import 'package:flutter/material.dart';
import 'home_screen.dart'; // All Football tang in Home i zang ta ding
import 'live_menu_screen.dart';
import 'profile_screen.dart';

class MainNav extends StatefulWidget {
  const MainNav({Key? key}) : super(key: key);

  @override
  _MainNavState createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int _currentIndex = 0; // App hon phet in Home ah lut masa ding

  final List<Widget> _screens = [
    const HomeScreen(), // Tab 1: Home thak
    const LiveMenuScreen(), // Tab 2: World Cup (Live te omna)
    const ProfileScreen(), // Tab 3: Profile & Admin
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black87,
        selectedItemColor: Colors.greenAccent,
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.sports_soccer), label: "Live"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}