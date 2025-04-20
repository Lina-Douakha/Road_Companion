import 'package:flutter/material.dart';
import 'package:road_companion/screens/traffic_law/traffic_law_consultation/priorité_passage.dart';
import 'package:road_companion/screens/traffic_law/traffic_law_consultation/panneaux_principal.dart';
import 'package:road_companion/screens/traffic_law/traffic_law_consultation/questionExamen.dart';
import 'package:road_companion/screens/traffic_law/traffic_law_consultation/penalties.dart';
import 'package:easy_localization/easy_localization.dart';

class ChoisirCategorie extends StatelessWidget {
  const ChoisirCategorie({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 150),
           Text(
             tr("Categories.Choose"),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B9169),
            ),
          ),
          const SizedBox(height:10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Center(
                child: SizedBox(
                  height: 450, // Adjusted for larger images
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.9, // Adjusted ratio for larger images
                    children: [
                      categorieItem(
                        context,
                        'assets/images/priorités.png',
                        tr("Categories.Prio"),
                            () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PriorityQuestionScreen(),
                          ),
                        ),
                      ),
                      categorieItem(
                        context,
                        'assets/images/panneaux.png',
                        tr("Categories.Panels"),
                            () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChoisirPanneauxGlobal(),
                          ),
                        ),
                      ),
                      categorieItem(
                        context,
                        'assets/images/exam.png',
                        tr("Categories.Questions_title"),
                            () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QuestionExamen(),
                          ),
                        ),
                      ),
                      categorieItem(
                        context,
                        'assets/images/penalties.png',
                        tr("Categories.Pénalités"),
                            () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => Law()),
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
                  width: 95, // Increased size
                  height: 95, // Increased size
                  fit: BoxFit.contain, // Ensure full image visibility
                ),
              ),
              const SizedBox(height: 8), // Adjusted space between image and title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16, // Increased text size
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

