import 'package:flutter/material.dart';
import 'package:road_companion/screens/roadside_assistance/historique_mecanicien.dart';
import 'package:road_companion/screens/roadside_assistance/reviews.dart';
import 'package:road_companion/screens/roadside_assistance/person_outline.dart';
import 'package:road_companion/screens/roadside_assistance/map_screen.dart'; // Importez votre MapScreen

class RoadsideAssistanceScreen extends StatefulWidget {
  @override
  _RoadsideAssistanceScreenState createState() => _RoadsideAssistanceScreenState();
}

class _RoadsideAssistanceScreenState extends State<RoadsideAssistanceScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    NotificationHistoryScreen(),
    ForumScreen(),
    MapScreen(), // Nouvel écran de carte
    PersonOutlineScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 10,
              offset: Offset(0, -3),)
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
          child: BottomNavigationBar(
            backgroundColor: Colors.white,
            selectedItemColor: Color(0xFF1B9169),
            unselectedItemColor: Colors.grey,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            selectedFontSize: 0, // Masque les labels
            unselectedFontSize: 0, // Masque les labels
            iconSize: isSmallScreen ? 24 : 28, // Taille d'icône responsive
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.history),
                activeIcon: Column(
                  children: [
                    Icon(Icons.history, color: Color(0xFF1B9169)),
                    SizedBox(height: 4),
                    Container(
                      width: 6,
                      height: 6,

                    ),
                  ],
                ),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.forum),
                activeIcon: Column(
                  children: [
                    Icon(Icons.forum, color: Color(0xFF1B9169)),
                    SizedBox(height: 4),
                    Container(
                      width: 6,
                      height: 6,

                    ),
                  ],
                ),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.map),
                activeIcon: Column(
                  children: [
                    Icon(Icons.map, color: Color(0xFF1B9169)),
                    SizedBox(height: 4),
                    Container(
                      width: 6,
                      height: 6,

                    ),
                  ],
                ),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Column(
                  children: [
                    Icon(Icons.person_outline, color: Color(0xFF1B9169)),
                    SizedBox(height: 4),
                    Container(
                      width: 6,
                      height: 6,

                    ),
                  ],
                ),
                label: '',
              ),
            ],
          ),
        ),
      ),
    );
  }
}