import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/home/home.dart';
import 'package:road_companion/screens/emergency/emergency.dart';
import 'package:road_companion/screens/incident_reporting/incident_report_screen.dart';
import 'package:road_companion/widgets/navigation_bar_widget.dart';


class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // Index pour suivre l'onglet actif

  // Liste des écrans
  final List<Widget> _screens = [
    IncidentReportScreen(), // Écran "Map" affiche l'écran des incidents
    EmergencyCallPage(), // Écran "Urgence"
    Placeholder(), // Remplace-le par l'écran du 3e onglet plus tard
   // ProfileScreen(), // Écran "Profil"
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Change l'index pour afficher le bon écran
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex, // Garde l'état des écrans
        children: _screens,
      ),
      bottomNavigationBar: NavigationBarWidget(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
