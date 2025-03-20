import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class NavigationBarWidget extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const NavigationBarWidget({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: onItemTapped,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFF1B9169),
      unselectedItemColor: const Color(0xFF9B9696),
      items: [
        _buildNavItem(Icons.location_on_outlined, "nav.map".tr(), 0),
        _buildNavItem(Icons.phone_in_talk, "nav.emergency".tr(), 1),
        _buildNavItem(Icons.menu_book, "nav.road_code".tr(), 2),
        _buildNavItem(Icons.person, "nav.profile".tr(), 3),
      ],
    );
  }

  BottomNavigationBarItem _buildNavItem(
      IconData icon,
      String label,
      int index,
      ) {
    return BottomNavigationBarItem(
      icon: InkWell(
        onTap: () => onItemTapped(index), // Gestion du clic
        borderRadius: BorderRadius.circular(30), // Arrondi de l'effet splash
        splashColor: Colors.green.withOpacity(0.3), // Couleur de l'effet splash
        child: Padding(
          padding: const EdgeInsets.all(
            8.0,
          ), // Ajoute du padding autour de l'icône
          child: Icon(icon),
        ),
      ),
      label: label,
    );
  }
}
