import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:road_companion/screens/traffic_law/exams/exams_screen.dart';
import 'package:road_companion/widgets/navigation_bar_widget.dart';
class PreExamScreen extends StatefulWidget {
  const PreExamScreen({super.key});

  @override
  _PreExamScreenState createState() => _PreExamScreenState();
}

class _PreExamScreenState extends State<PreExamScreen> {
  int currentRuleIndex = 0;
  final List<Map<String, String>> rules = [

    {"title": "Limite de Temps", "description": "Vous aurez un temps limité pour terminer l'examen."},
    {"title": "Aucune Aide Externe", "description": "Vous n'êtes pas autorisé à utiliser des ressources externes."},
    {"title": "Navigation", "description": "Vous pouvez revenir en arrière et revoir vos réponses avant de soumettre."},
    {"title": "Honnêteté", "description": "Assurez-vous de passer l'examen avec intégrité."}

  ];

  void nextRule() {
    if (currentRuleIndex < rules.length - 1) {
      setState(() {
        currentRuleIndex++;
      });
    }
  }

  void previousRule() {
    if (currentRuleIndex > 0) {
      setState(() {
        currentRuleIndex--;
      });
    }
  }
  int _selectedIndex = 0;
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF1B9169),
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(
                    'assets/animation/pre_exam.json',
                    width: screenWidth * 0.6,
                    height: screenHeight * 0.3,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 5,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          rules[currentRuleIndex]['title']!,
                          style: TextStyle(
                            fontSize: screenWidth * 0.05,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1B9169),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        Text(
                          rules[currentRuleIndex]['description']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: screenWidth * 0.04),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios),
                        onPressed: previousRule,
                        color: currentRuleIndex > 0 ? Colors.black : Colors.grey,
                      ),
                      Text(
                        "${currentRuleIndex + 1} / ${rules.length}",
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios),
                        onPressed: nextRule,
                        color: currentRuleIndex < rules.length - 1 ? Colors.black : Colors.grey,
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.04),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D47E),
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.1,
                        vertical: screenHeight * 0.015,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      // Navigate to the Exam Screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ExamsScreen(), // Ensure you pass necessary parameters
                        ),
                      );
                    },
                    child: Text(
                      "Faire le test",
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: NavigationBarWidget(
          selectedIndex: _selectedIndex,
          onItemTapped: _onItemTapped,
        ),
      ),
    );
  }
}