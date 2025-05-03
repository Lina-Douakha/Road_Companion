import 'package:flutter/material.dart';
import 'users_management_screen.dart';
import 'Users_statistics.dart';

class ManagementUsers extends StatefulWidget {
  const ManagementUsers({Key? key}) : super(key: key);  // FIXED this line

  @override
  State<ManagementUsers> createState() => _ManagementUsersState();
}

class _ManagementUsersState extends State<ManagementUsers> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    UsersManagementScreen(),
    StatisticsUsers(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.grey[50],
        selectedItemColor: const Color(0xFF1B9169),
        unselectedItemColor: Colors.grey[500],
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Manage Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Statistics',
          ),
        ],
      ),
    );
  }
}
