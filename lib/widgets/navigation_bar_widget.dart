import 'package:flutter/material.dart';

class NavigationBarWidget extends StatefulWidget {
  const NavigationBarWidget({super.key});

  @override
  State<NavigationBarWidget> createState() => _NavigationBarWidgetState();
}

class _NavigationBarWidgetState extends State<NavigationBarWidget> {
  int _selectedIndex = 0; // Onglet sélectionné

  // Liste des pages affichées selon l'onglet sélectionné
  final List<Widget> _pages = [
    const Center(child: Text("Page principale")), // Page 1
    const Center(child: Text("Page d’appel")), // Page 2
    const Center(child: Text("Page du menu")), // Page 3
    const Center(child: Text("Profil")), // Page 4
  ];

  // Fonction pour gérer les clics sur la navbar
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Mise à jour de l'index sélectionné
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex], // Affiche la page sélectionnée
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF1B9169),
        unselectedItemColor: const Color(0xFF9B9696),
        items: [
          _buildNavItem(Icons.location_on_outlined, 'Carte', 0),
          _buildNavItem(Icons.phone_in_talk, 'Urgence', 1),
          _buildNavItem(Icons.menu_book, 'Code', 2),
          _buildNavItem(Icons.person, 'Profile', 3),
        ],
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
    IconData icon,
    String label,
    int index,
  ) {
    return BottomNavigationBarItem(
      icon: InkResponse(
        onTap: () => _onItemTapped(index), // Gère le clic
        radius: 20, // Rayon de l'effet splash
        splashColor: Colors.green.withOpacity(
          0.3,
        ), // Personnalisation de la couleur du splash
        child: Padding(
          padding: const EdgeInsets.all(
            8.0,
          ), // Ajoute un padding autour de l'icône
          child: Icon(icon),
        ),
      ),
      label: label,
    );
  }
}
