import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:road_companion/screens/emergency/emergency.dart';
import 'package:road_companion/screens/incident_reporting/incident_report_screen.dart';
import 'package:road_companion/screens/profile/profile.dart';
import 'package:road_companion/widgets/navigation_bar_widget.dart';
import 'package:road_companion/screens/traffic_law/Traffic_Law.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // Liste des pages associées aux onglets de la navbar
  final List<Widget> _pages = [
    const IncidentReportScreen(),
    const EmergencyCallPage(),
    const TrafficLawScreen(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF1B9169),
        statusBarIconBrightness: Brightness.light,
      ),
      child:  Scaffold(
        resizeToAvoidBottomInset: true,
        body: _pages[_selectedIndex],
        backgroundColor: Colors.white, // Affichage dynamique du contenu
        bottomNavigationBar: NavigationBarWidget(
          selectedIndex: _selectedIndex,
          onItemTapped: _onItemTapped,
        ), // Utilisation correcte de la navbar
      ),
    );
  }
}
