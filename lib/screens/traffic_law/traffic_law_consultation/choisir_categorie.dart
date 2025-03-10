import 'package:flutter/material.dart';
//import 'priority_question_screen.dart'; // Importation de la page
import 'package:road_companion/screens/traffic_law/traffic_law_consultation/priorité_passage.dart';

class ChoisirCategorie extends StatelessWidget {
  const ChoisirCategorie({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                child: SizedBox(
                  height: 400,
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1,
                    children: [
                      categorieItem(
                        context,
                        'assets/images/priorité.jpg',
                        'Priorité de passage',
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PriorityQuestionScreen(),
                          ),
                        ),
                      ),
                      categorieItem(
                        context,
                        'assets/images/panneaux.jpg',
                        'Panneaux de signalisation',
                        () => print('Panneaux sélectionnés'),
                      ),
                      categorieItem(
                        context,
                        'assets/images/exam.jpg',
                        'Questions d\'examen',
                        () => print('Examens sélectionnés'),
                      ),
                      categorieItem(
                        context,
                        'assets/images/penalties.jpg',
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
    );
  }

  Widget categorieItem(
    BuildContext context,
    String imagePath,
    String title,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Material(
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
