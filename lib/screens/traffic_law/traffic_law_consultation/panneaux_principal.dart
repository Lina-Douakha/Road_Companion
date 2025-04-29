import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF1B9169),
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        body: Column(
          children: [

            Container(
              height: MediaQuery.of(context).padding.top,
              color: const Color(0xFF1B9169),
            ),
            // Main content
            Expanded(
              child: Center(
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    Text(
                      tr("Categories.Panels"),
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1B9169),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Divider(
                        color: const Color(0xFF1B9169).withOpacity(0.2),
                        thickness: 1,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Column(
                            children: _categories.asMap().entries.map((entry) {
                              int index = entry.key;
                              Map<String, String> category = entry.value;

                              Color bgColor = _getCategoryBgColor(index);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: CategoryCard(
                                  title: category['title']!.tr(),
                                  imagePath: category['imagePath']!,
                                  iconBgColor: bgColor,
                                  onTap: () => _handleNavigation(context, index),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: NavigationBarWidget(
          selectedIndex: _selectedIndex,
          onItemTapped: (index) {
            print("Onglet sélectionné : $index");
          },
        ),
      ),
    );
  }

  Color _getCategoryBgColor(int index) {
    List<Color> colors = [
      const Color(0xFFFFEFEF), // Light red
      const Color(0xFFFFEFEF), // Light red
      const Color(0xFFF2F8FF), // Light blue
      const Color(0xFFF2F8FF), // Light blue
      const Color(0xFFFFF8E5), // Light yellow
    ];

    return colors[index % colors.length];
  }

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
    }
  }
}

class CategoryCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final Color iconBgColor;
  final VoidCallback onTap;

  const CategoryCard({
    required this.title,
    required this.imagePath,
    required this.iconBgColor,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: 85,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 3,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: iconBgColor.withOpacity(0.3),
          highlightColor: iconBgColor.withOpacity(0.15),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [

                Container(
                  width: 65,
                  height: 65,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                    width: 50, // Bigger image
                    height: 50, // Bigger image
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF424752),
                      height: 1.2,
                    ),
                  ),
                ),
                // Circle arrow icon
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: iconBgColor.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Color(0xFF424752),
                  ),
                ),
              ],
            ),
          ),
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