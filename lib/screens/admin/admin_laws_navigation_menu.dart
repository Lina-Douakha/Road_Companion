import 'package:flutter/material.dart';
import 'package:road_companion/screens/admin/admin_traffic_laws.dart';
import 'package:road_companion/screens/admin/admin_tests.dart';
import 'package:road_companion/screens/admin/admin_stat.dart';
import 'package:easy_localization/easy_localization.dart';

class AdminNavigationMenu extends StatefulWidget {
  const AdminNavigationMenu({Key? key}) : super(key: key);

  @override
  State<AdminNavigationMenu> createState() => _AdminNavigationMenuState();
}

class _AdminNavigationMenuState extends State<AdminNavigationMenu> {
  int _selectedIndex = 0;

  final List<Widget> _screens =  [
    AdminStatScreen(),
    AdminExamManager(),
    TrafficLawsManager(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // No AppBar here
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.grey[50], // Off-white color
        selectedItemColor:  Color(0xFF1B9169),
        unselectedItemColor: Colors.grey[500],
        elevation: 8,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: tr("admin.statistics"),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.quiz),
            label: tr("admin.exams"),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.gavel),
            label: tr("admin.laws"),
          ),
        ],
      ),
    );
  }
}