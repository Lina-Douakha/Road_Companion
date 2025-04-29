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
            Expanded(
              child: Center(
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    Text(
                      tr("Categories.Choose"),
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeightHelper.bold,
                        color: ColorsManager.Green1,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Divider(
                        color: ColorsManager.Green1.withOpacity(0.2),
                        thickness: 1,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CategoryCard(
                                  text: tr("Categories.Prio"),
                                  imagePath: 'assets/images/priorités.png',
                                  iconBgColor: const Color(0xFFE5F6EF),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const PriorityQuestionsScreen()),
                                    );
                                  },
                                ),
                                const SizedBox(height: 20),
                                CategoryCard(
                                  text: tr("Categories.Panels"),
                                  imagePath: 'assets/images/panel.png',
                                  iconBgColor: const Color(0xFFF2F8FF),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const RoadSignQuestionScreen()),
                                    );
                                  },
                                ),
                                const SizedBox(height: 20),
                                CategoryCard(
                                  imagePath: 'assets/images/exam.png',
                                  text: tr("Categories.Questions_theorique"),
                                  iconBgColor: const Color(0xFFFFF8E5),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const TheoreticalQuestionsScreen()),
                                    );
                                  },
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
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
      ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  final String text;
  final String imagePath;
  final Color iconBgColor;
  final VoidCallback onTap;

  const CategoryCard({
    required this.text,
    required this.imagePath,
    required this.iconBgColor,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,  // Fixed width
      height: 100,
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    text,
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF424752),
                      height: 1.2,
                    ),
                  ),
                ),
                Container(
                  width: 30,
                  height: 30,
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