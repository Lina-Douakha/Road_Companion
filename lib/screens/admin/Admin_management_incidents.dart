import 'package:flutter/material.dart';
import 'incidents_management_screen.dart';
import 'Incidents_statistics.dart';

class ManagementIncidents extends StatefulWidget {
  const ManagementIncidents({Key? key}) : super(key: key);

  @override
  State<ManagementIncidents> createState() => _ManagementIncidentsState();
}

class _ManagementIncidentsState extends State<ManagementIncidents> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    IncidentManagementScreen(),
    StatisticsIncidents(),
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
            icon: Icon(Icons.report),  // Changed to a report icon for incidents
            label: 'Manage Incidents',
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
