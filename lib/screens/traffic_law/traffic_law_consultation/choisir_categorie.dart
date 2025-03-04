import 'package:flutter/material.dart';
import 'package:road_companion/widgets/navigation_bar_widget.dart';

class ChoisirCategorie extends StatelessWidget {
  const ChoisirCategorie({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: const Color(0xFF1B9169), elevation: 0),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 100),
          const Text(
            'Choisir une catégorie',

            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B9169),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Center(
                // Centre les boutons
                child: SizedBox(
                  height: 400, // Définit une hauteur pour le GridView
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1,
                    // Carré
                    children: [
                      categorieItem(
                        'lib/assets/images/priorité.jpg',
                        'Priorité de passage',
                        () => print('Priorité sélectionnée'),
                      ),
                      categorieItem(
                        'lib/assets/images/panneaux.jpg',
                        'Panneaux de signalisation',
                        () => print('Panneaux sélectionnés'),
                      ),
                      categorieItem(
                        'lib/assets/images/exam.jpg',
                        'Questions d\'examen',
                        () => print('Examens sélectionnés'),
                      ),
                      categorieItem(
                        'lib/assets/images/penalties.jpg',
                        'Pénalités et amendes',
                        () => print('Pénalités sélectionnées'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBarWidget(),
    );
  }

  Widget categorieItem(String imagePath, String title, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Material(
        color: const Color(0xFFF1F5F9), // Couleur de fond
        borderRadius: BorderRadius.circular(18), // Bord arrondi
        elevation: 4, // Ombre
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(18),
          splashColor: const Color.fromARGB(255, 183, 185, 186),
          // Couleur du splash effect
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(200), // Bord rond
                child: Image.asset(
                  imagePath,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
