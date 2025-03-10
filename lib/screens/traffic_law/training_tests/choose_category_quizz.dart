import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:road_companion/Theming/colors.dart';
import 'package:road_companion/Theming/font_weight_helper.dart';
import 'package:road_companion/screens/traffic_law/training_tests/priority_questions.dart'; // Import your screen
import 'package:road_companion/screens/traffic_law/training_tests/roadsigns_questions.dart'; // Remplace par le bon chemin si nécessaire

class ChooseCategoryQuizScreen extends StatelessWidget {
  const ChooseCategoryQuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF1B9169),
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            Container(
              height: screenHeight * 0.04,
              color: const Color(0xFF1B9169),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: screenHeight * 0.05),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: screenHeight * 0.07), // Added space above title
                      Text(
                        'Choisir une catégorie',
                        style: TextStyle(
                          fontSize: screenWidth * 0.07,
                          fontWeight: FontWeightHelper.bold,
                          color: ColorsManager.Green1,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.05),
                      Column(
                        children: [
                          CategoryCard(
                            text: 'Priorité de passage',
                            imagePath: 'assets/images/priorité.jpg',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const PriorityQuestionsScreen()),
                              );
                            },
                          ),
                          SizedBox(height: screenHeight * 0.03),
                          CategoryCard(
                            text: 'Panneaux de signalisation',
                            imagePath: 'assets/images/ORHG1K0_1.png',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const RoadSignQuestionScreen()),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  final String text;
  final String imagePath;
  final VoidCallback onTap;

  const CategoryCard({
    required this.text,
    required this.imagePath,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double cardWidth = screenWidth * 0.8;
    final double cardHeight = cardWidth * 0.4;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: cardWidth,
        height: cardHeight,
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Image.asset(imagePath, width: cardHeight * 0.8, height: cardHeight * 0.8),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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