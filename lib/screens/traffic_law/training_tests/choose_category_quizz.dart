import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:road_companion/Theming/colors.dart';
import 'package:road_companion/Theming/font_weight_helper.dart';
import 'package:road_companion/screens/traffic_law/training_tests/priority_questions.dart';
import 'package:road_companion/screens/traffic_law/training_tests/roadsigns_questions.dart';
import 'package:road_companion/screens/traffic_law/training_tests/Questions.dart';
import 'package:easy_localization/easy_localization.dart';


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
                      SizedBox(height: screenHeight * 0.07), // Dynamic space above title
                      Text(
                        tr("Categories.Choose"),
                        style: TextStyle(
                          fontSize: screenWidth * 0.07,
                          fontWeight: FontWeightHelper.bold,
                          color: ColorsManager.Green1,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.09), // Dynamic space under title
                      Column(
                        children: [
                          CategoryCard(
                            text: tr("Categories.Prio"),
                            imagePath: 'assets/images/priorités.png',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const PriorityQuestionsScreen()),
                              );
                            },
                          ),
                          SizedBox(height: screenHeight * 0.03),
                          CategoryCard(
                            text: tr("Categories.Panels"),
                            imagePath: 'assets/images/panel.png',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const RoadSignQuestionScreen()),
                              );
                            },
                          ),
                          SizedBox(height: screenHeight * 0.03),
                          CategoryCard(
                            imagePath: 'assets/images/exam.png',
                            text: tr("Categories.Questions_theorique"),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const TheoreticalQuestionsScreen()),
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

    return SizedBox(
      width: cardWidth,
      height: cardHeight,
      child: Card(
        elevation: 4,
        color: const Color(0xFFf1f5f9), // Light background color
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: onTap,
          splashColor: const Color.fromARGB(255, 183, 185, 186), // Splash color when pressed
          highlightColor: const Color(0xFFE2E4E6), // Color on tap hold
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              children: [
                // Image on the left*
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child:ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      imagePath,
                      width: cardHeight * 0.8, // Reduced image size
                      height: cardHeight * 0.8,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Centered text
                Expanded(
                  child: Align(
                    alignment: Alignment.center, // Center the text vertically
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
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

