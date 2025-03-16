import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:road_companion/Theming/colors.dart';

class PriorityQuestionsScreen extends StatefulWidget {
  const PriorityQuestionsScreen({super.key});

  @override
  _PriorityQuestionsScreenState createState() => _PriorityQuestionsScreenState();
}

class _PriorityQuestionsScreenState extends State<PriorityQuestionsScreen> {
  int? selectedAnswer;
  bool showResult = false;
  bool showErrorMessage = false;
  bool isConfirmed = false;

  final int correctAnswer = 1;

  void selectAnswer(int index) {
    if (!isConfirmed) {
      setState(() {
        selectedAnswer = index;
        showErrorMessage = false;
      });
    }
  }

  void confirmAnswer() {
    if (selectedAnswer == null) {
      setState(() {
        showErrorMessage = true;
      });
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          showErrorMessage = false;
        });
      });
    } else {
      setState(() {
        showResult = true;
        isConfirmed = true;
      });
    }
  }

  void nextQuestion() {
    setState(() {
      selectedAnswer = null;
      showResult = false;
      isConfirmed = false;
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
        body: Column(
          children: [
            Container(
              height: screenHeight * 0.04,
              color: const Color(0xFF1B9169),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF1B9169)),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 10),
                  const Center(
                    child: Text(
                      'Les questions du Priorité de passage',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B9169),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: screenHeight * 0.03),
                    Image.asset(
                      'assets/images/priorities/preo1_2.png',
                      width: screenWidth * 0.75,
                      fit: BoxFit.fitWidth,
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    const Text(
                      'Qui a la priorité ?',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    buildAnswerOption(0, 'La voiture rouge passe en premier', screenWidth),
                    SizedBox(height: screenHeight * 0.02),
                    buildAnswerOption(1, 'Les voitures jaune et bleue passent en même temps', screenWidth),
                    SizedBox(height: screenHeight * 0.02),
                    buildAnswerOption(2, 'La voiture rouge passe en dernier', screenWidth),
                    SizedBox(height: screenHeight * 0.03),
                    ElevatedButton(
                      onPressed: confirmAnswer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00D47E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        minimumSize: Size(screenWidth * 0.85, 50),
                      ),
                      child: const Text('Confirmer', style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                    if (showResult)
                      Column(
                        children: [
                          SizedBox(height: screenHeight * 0.02),
                          OutlinedButton(
                            onPressed: nextQuestion,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF1B9169)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              minimumSize: Size(screenWidth * 0.85, 50),
                            ),
                            child: const Text('Suivant', style: TextStyle(color: Color(0xFF1B9169), fontSize: 16)),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            if (showErrorMessage)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  color: ColorsManager.Red,
                  child: const Text(
                    'Veuillez sélectionner une réponse avant de confirmer.',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget buildAnswerOption(int index, String text, double screenWidth) {
    bool isSelected = selectedAnswer == index;
    bool isCorrect = index == correctAnswer;
    bool isWrongSelected = showResult && isSelected && !isCorrect;

    Color containerColor = Colors.white;
    Color borderColor = Colors.grey[300]!;
    IconData? icon;

    if (showResult) {
      if (isCorrect) {
        containerColor = ColorsManager.Bgreen3;
        borderColor = ColorsManager.Bgreen;
        icon = Icons.check_circle;
      } else if (isWrongSelected) {
        containerColor = ColorsManager.Red;
        borderColor = Colors.red;
        icon = Icons.cancel;
      }
    } else if (isSelected) {
      borderColor = Colors.grey[600]!;
      icon = Icons.radio_button_checked;
    }

    return Align(
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: () => selectAnswer(index),
        child: Container(
          width: screenWidth * 0.85,
          padding: EdgeInsets.all(screenWidth * 0.04),
          decoration: BoxDecoration(
            color: containerColor,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Icon(icon ?? Icons.radio_button_unchecked, color: borderColor),
              const SizedBox(width: 10),
              Expanded(child: Text(text)),
            ],
          ),
        ),
      ),
    );
  }
}