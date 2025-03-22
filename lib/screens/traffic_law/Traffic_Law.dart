import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:road_companion/Theming/colors.dart';
import 'package:road_companion/screens/traffic_law/training_tests/choose_category_quizz.dart';
import 'package:road_companion/screens/traffic_law/traffic_law_consultation/choisir_categorie.dart';
import 'package:road_companion/screens/traffic_law/exams/pre_exam.dart';

class TrafficLawScreen extends StatelessWidget {
  const TrafficLawScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: ColorsManager.Green1,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            Container(
              height: screenHeight * 0.04,
              color: ColorsManager.Green1,
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.05,
                    vertical: screenHeight * 0.05,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: screenHeight * 0.07),
                      Text(
                        'Code de la route',
                        style: TextStyle(
                          fontSize: screenWidth * 0.08,
                          fontWeight: FontWeight.bold,
                          color: ColorsManager.Green1,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      Text(
                        'Apprenez le Code de la route aujourd’hui, conduisez en toute sécurité demain !',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: screenWidth * 0.045),
                      ),
                      SizedBox(height: screenHeight * 0.07),
                      ClickableCard(
                        icon: Icons.school,
                        text: 'Apprentissage',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ChoisirCategorie()),
                          );
                        },
                        screenWidth: screenWidth,
                      ),
                      ClickableCard(
                        icon: Icons.quiz,
                        text: 'Quiz',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ChooseCategoryQuizScreen()),
                          );
                        },
                        screenWidth: screenWidth,
                      ),
                      ClickableCard(
                        icon: Icons.assignment,
                        text: 'Tests',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const PreExamScreen()),
                          );
                        },
                        screenWidth: screenWidth,
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

class ClickableCard extends StatefulWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  final double screenWidth;

  const ClickableCard({
    super.key,
    required this.icon,
    required this.text,
    required this.onTap,
    required this.screenWidth,
  });

  @override
  _ClickableCardState createState() => _ClickableCardState();
}

class _ClickableCardState extends State<ClickableCard> {
  bool isTapped = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => isTapped = true),
      onTapUp: (_) => setState(() => isTapped = false),
      onTapCancel: () => setState(() => isTapped = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.symmetric(vertical: widget.screenWidth * 0.05),
        padding: EdgeInsets.symmetric(horizontal: widget.screenWidth * 0.05, vertical: 14),
        height: 65,
        decoration: BoxDecoration(
          color: isTapped ? ColorsManager.Green1 : ColorsManager.Bgreen3,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(widget.icon, color: ColorsManager.Bgreen, size: widget.screenWidth * 0.07),
                SizedBox(width: widget.screenWidth * 0.06),
                Text(
                  widget.text,
                  style: TextStyle(fontSize: widget.screenWidth * 0.045, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            Icon(Icons.arrow_forward_ios, size: widget.screenWidth * 0.04, color: Colors.green),
          ],
        ),
      ),
    );
  }
}