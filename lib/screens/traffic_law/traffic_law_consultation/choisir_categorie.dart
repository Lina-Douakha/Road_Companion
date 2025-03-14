import 'package:flutter/material.dart';
import 'package:road_companion/screens/traffic_law/traffic_law_consultation/priorité_passage.dart';
import 'package:road_companion/screens/traffic_law/traffic_law_consultation/panneaux_principal.dart';
import 'package:road_companion/screens/traffic_law/traffic_law_consultation/questionExamen.dart';
import 'package:road_companion/screens/traffic_law/traffic_law_consultation/penalties.dart';

class ChoisirCategorie extends StatelessWidget {
  const ChoisirCategorie({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(height: screenHeight * 0.2),
          const Text(
            'Choisir une catégorie',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B9169),
            ),
          ),
          SizedBox(height: screenHeight * 0.0001),
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
                        'assets/images/panneau.jpg',
                        'Panneaux de signalisation',
                            () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChoisirPanneauxGlobal(),
                          ),
                        ),
                      ),
                      categorieItem(
                        context,
                        'assets/images/exam.jpg',
                        'Questions d\'examen',
                            () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QuestionExamen(),
                          ),
                        ),
                      ),
                      categorieItem(
                        context,
                        'assets/images/penalties.jpg',
                        'Pénalités et amendes',
                            () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Law(),
                          ),
                        ),
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

