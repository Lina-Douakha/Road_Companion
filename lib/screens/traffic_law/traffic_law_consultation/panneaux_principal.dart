import 'package:flutter/material.dart';
import 'package:road_companion/screens/traffic_law/traffic_law_consultation/panneaux_de_danger.dart';
import 'package:road_companion/screens/traffic_law/traffic_law_consultation/panneaux_interdiction.dart';
import 'package:road_companion/screens/traffic_law/traffic_law_consultation/panneaux_indication.dart';
import 'package:road_companion/screens/traffic_law/traffic_law_consultation/panneaux_intersection.dart';
import 'package:road_companion/screens/traffic_law/traffic_law_consultation/panneaux_obligation.dart';
import 'package:road_companion/widgets/navigation_bar_widget.dart';
import 'package:easy_localization/easy_localization.dart';

class ChoisirPanneauxGlobal extends StatelessWidget {
  const ChoisirPanneauxGlobal({super.key});

  @override
  Widget build(BuildContext context) {
    int _selectedIndex = 0;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Center vertically
          crossAxisAlignment: CrossAxisAlignment.center, // Center horizontally
          children: [
            const SizedBox(height: 50), // Optional space above
            Wrap(
              spacing: screenWidth * 0.07, // Horizontal space between boxes
              runSpacing: screenWidth * 0.07, // Vertical space between boxes
              alignment: WrapAlignment.center, // Center last item when alone
              children: _categories.asMap().entries.map((entry) {
                int index = entry.key;
                Map<String, String> category = entry.value;

                return categorieItem(
                  context,
                  category['imagePath']!,
                  category['title']!.tr(),
                      () => _handleNavigation(context, index),
                  screenWidth,
                );
              }).toList(),
            ),
            const SizedBox(height: 30), // Optional space below
          ],
        ),
      ),
      bottomNavigationBar: NavigationBarWidget(
        selectedIndex: _selectedIndex,
        onItemTapped: (index) {
          print("Onglet sélectionné : $index");
        },
      ),
    );
  }

  // Navigation handler
  void _handleNavigation(BuildContext context, int index) {
    switch (index) {
      case 0: // "Panneaux d'interdication"
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PanneauxInterdictionScreen()),
        );
        break;
      case 1: // "Panneaux de danger"
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PanneauxDeDangerScreen()),
        );
        break;
      case 2: // "Panneaux d'obligation"
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PanneauxObligationScreen()),
        );
        break;
      case 3: // "Panneaux d'indication"
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PanneauxIndicationScreen()),
        );
        break;
      case 4: // "Panneaux d'intersection"
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PanneauxIntersectionScreen()),
        );
        break;
      default:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ComingSoonScreen()),
        );
        break;
    }
  }

  // Widget for category items
  Widget categorieItem(
      BuildContext context,
      String imagePath,
      String title,
      VoidCallback onPressed,
      double screenWidth,
      ) {
    double boxSize = screenWidth * 0.35; // Box size
    double iconSize = screenWidth * 0.24; // Image size

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(18),
      splashColor: const Color.fromARGB(255, 183, 185, 186),
      child: Container(
        width: boxSize,
        height: boxSize,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 3), // shadow position
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: Image.asset(
                imagePath,
                width: iconSize,
                height: iconSize,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 3), // Reduced space between image and title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 🔹 Placeholder Screen for other categories
class ComingSoonScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("En cours de construction")),
      body: Center(
        child: Text(
          "Cette catégorie sera bientôt disponible!",
          style: TextStyle(fontSize: 20, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

final List<Map<String, String>> _categories = [
  {
    'imagePath': 'assets/images/panneaux_interdiction.png',
    'title': 'Categories.Interdiction',
  },
  {
    'imagePath': 'assets/images/panneaux_danger.png',
    'title': 'Categories.Danger',
  },
  {
    'imagePath': 'assets/images/panneaux_obligation.png',
    'title': 'Categories.Obligation',
  },
  {
    'imagePath': 'assets/images/panneaux_orientation.png',
    'title': 'Categories.Indication',
  },
  {
    'imagePath': 'assets/images/panneaux_priorité_inter.png',
    'title': 'Categories.Intersection',
  },
];


