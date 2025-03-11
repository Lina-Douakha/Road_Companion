// import 'package:flutter/material.dart';

// class ChoisirPanneauxGlobal extends StatelessWidget {
//   const ChoisirPanneauxGlobal({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       resizeToAvoidBottomInset: true,
//       body: LayoutBuilder(
//         builder: (context, constraints) {
//           double screenWidth = constraints.maxWidth;
//           double itemWidth = screenWidth * 0.50; // Taille de l'item
//           double itemHeight = screenWidth * 0.50;
//           int crossAxisCount = screenWidth > 600 ? 3 : 2;

//           return Padding(
//             padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
//             child: Column(
//               children: [
//                 const SizedBox(height: 20),
//                 Expanded(
//                   child: GridView.builder(
//                     padding: EdgeInsets.only(
//                       bottom: screenWidth * 0.2,
//                     ), // Espace pour le scroll
//                     gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                       crossAxisCount: crossAxisCount,
//                       crossAxisSpacing: screenWidth * 0.07,
//                       mainAxisSpacing: screenWidth * 0.1,
//                     ),
//                     itemCount: _categories.length,

//                     itemBuilder: (context, index) {
//                       final category = _categories[index];
//                       bool isLast = index == _categories.length - 1;
//                       bool needsCenter =
//                           (screenWidth > 600) &&
//                           ((index % crossAxisCount == 0) ||
//                               (_categories.length % crossAxisCount != 0 &&
//                                   isLast));
//                       return needsCenter
//                           ? Align(
//                             alignment: Alignment.center,
//                             child: categorieItem(
//                               context,
//                               category['imagePath']!,
//                               category['title']!,
//                               () => print(category['title']),
//                               screenWidth,
//                             ),
//                           )
//                           : categorieItem(
//                             context,
//                             category['imagePath']!,
//                             category['title']!,
//                             () => print(category['title']),
//                             screenWidth,
//                           );
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget categorieItem(
//     BuildContext context,
//     String imagePath,
//     String title,
//     VoidCallback onPressed,
//     double screenWidth,
//   ) {
//     double iconSize = screenWidth * 0.19;

//     return Material(
//       color: const Color(0xFFF1F5F9),
//       borderRadius: BorderRadius.circular(18),
//       elevation: 4,
//       child: InkWell(
//         onTap: onPressed,
//         borderRadius: BorderRadius.circular(18),
//         splashColor: const Color.fromARGB(255, 183, 185, 186),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             ClipRRect(
//               borderRadius: BorderRadius.circular(200),
//               child: Image.asset(
//                 imagePath,
//                 width: iconSize,
//                 height: iconSize,
//                 fit: BoxFit.cover,
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 8),
//               child: Text(
//                 title,
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: screenWidth * 0.035,
//                   fontWeight: FontWeight.w500,
//                   color: Colors.black87,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// final List<Map<String, String>> _categories = [
//   {
//     'imagePath': 'assets/images/panneaux_interdiction.png',
//     'title': 'Panneaux d\'interdiction',
//   },
//   {
//     'imagePath': 'assets/images/panneaux_danger.png',
//     'title': 'Panneaux de danger',
//   },
//   {
//     'imagePath': 'assets/images/panneaux_obligation.png',
//     'title': 'Panneaux d\'obligation',
//   },
//   {
//     'imagePath': 'assets/images/panneaux_orientation.png',
//     'title': 'Panneaux d\'orientation',
//   },
//   {
//     'imagePath': 'assets/images/panneaux_end_limitation.png',
//     'title': 'Panneaux de fin d\'interdiction',
//   },
//   {
//     'imagePath': 'assets/images/panneaux_priorité_inter.png',
//     'title': 'Panneaux de priorité à l\'intersection',
//   },
//   {
//     'imagePath': 'assets/images/panneaux_temporaire.png',
//     'title': 'Panneaux temporaires',
//   },
// ];
import 'package:flutter/material.dart';
import 'package:road_companion/screens/traffic_law/traffic_law_consultation/panneaux_de_danger.dart'; // Import the screen you have implemented
import 'package:road_companion/widgets/navigation_bar_widget.dart';

class ChoisirPanneauxGlobal extends StatelessWidget {
  const ChoisirPanneauxGlobal({super.key});

  @override
  Widget build(BuildContext context) {
    int _selectedIndex = 0;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          double screenWidth = constraints.maxWidth;
          double itemWidth = screenWidth * 0.50;
          double itemHeight = screenWidth * 0.50;
          int crossAxisCount = screenWidth > 600 ? 3 : 2;

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
            child: Column(
              children: [
                const SizedBox(height: 90),
                Expanded(
                  child: GridView.builder(
                    padding: EdgeInsets.only(bottom: screenWidth * 0.2),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: screenWidth * 0.07,
                      mainAxisSpacing: screenWidth * 0.1,
                    ),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      bool isLast = index == _categories.length - 1;
                      bool needsCenter =
                          (screenWidth > 600) &&
                              ((index % crossAxisCount == 0) ||
                                  (_categories.length % crossAxisCount != 0 &&
                                      isLast));

                      return needsCenter
                          ? Align(
                        alignment: Alignment.center,
                        child: categorieItem(
                          context,
                          category['imagePath']!,
                          category['title']!,
                              () => _handleNavigation(context, index),
                          screenWidth,
                        ),
                      )
                          : categorieItem(
                        context,
                        category['imagePath']!,
                        category['title']!,
                            () => _handleNavigation(context, index),
                        screenWidth,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
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
      case 1: // "Panneaux de danger"
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PanneauxScreen()),
        );
        break;
      default: // Placeholder for other categories
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ComingSoonScreen()),
        );
        break;
    }
  }

  // Widget for grid items
  Widget categorieItem(
      BuildContext context,
      String imagePath,
      String title,
      VoidCallback onPressed,
      double screenWidth,
      ) {
    double iconSize = screenWidth * 0.19;

    return Material(
      color: const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(18),
      elevation: 4,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        splashColor: const Color.fromARGB(255, 183, 185, 186),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(200),
              child: Image.asset(
                imagePath,
                width: iconSize,
                height: iconSize,
                fit: BoxFit.cover,
              ),
            ),
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

// 🔹 List of categories
final List<Map<String, String>> _categories = [
  {
    'imagePath': 'assets/images/panneaux_interdiction.png',
    'title': 'Panneaux d\'interdiction',
  },
  {
    'imagePath': 'assets/images/panneaux_danger.png',
    'title': 'Panneaux de danger',
  },
  {
    'imagePath': 'assets/images/panneaux_obligation.png',
    'title': 'Panneaux d\'obligation',
  },
  {
    'imagePath': 'assets/images/panneaux_orientation.png',
    'title': 'Panneaux d\'orientation',
  },
  {
    'imagePath': 'assets/images/panneaux_end_limitation.png',
    'title': 'Panneaux de fin d\'interdiction',
  },
  {
    'imagePath': 'assets/images/panneaux_priorité_inter.png',
    'title': 'Panneaux de priorité à l\'intersection',
  },
  {
    'imagePath': 'assets/images/panneaux_temporaire.png',
    'title': 'Panneaux temporaires',
  },
];
