import 'package:flutter/material.dart';
import 'package:road_companion/screens/traffic_law/traffic_law_consultation/choisir_categorie.dart';
import 'package:road_companion/widgets/navigation_bar_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // Liste des pages associées aux onglets de la navbar
  final List<Widget> _pages = [
    const Center(child: Text("Page principale")),
    const Center(child: Text("Page d’appel")),
    const ChoisirCategorie(),
    const Center(child: Text("Profil")),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Road Companion')),
        backgroundColor: const Color(0xFF1B9169),
        foregroundColor: Colors.white, // Ceci rend le texte blanc
      ),
      body: _pages[_selectedIndex],backgroundColor: Colors.white, // Affichage dynamique du contenu
      bottomNavigationBar: NavigationBarWidget(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,

      ), // ✅ Utilisation correcte de la navbar
    );
  }
}
