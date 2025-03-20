import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:road_companion/Theming/colors.dart';

class TheoreticalQuestionsScreen extends StatefulWidget {
  const TheoreticalQuestionsScreen({super.key});

  @override
  _TheoreticalQuestionsScreenState createState() => _TheoreticalQuestionsScreenState();
}

class _TheoreticalQuestionsScreenState extends State<TheoreticalQuestionsScreen> {
  List<Map<String, dynamic>> questions = [];
  int currentQuestionIndex = 0;
  List<int> selectedAnswers = [];
  bool showResult = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchQuestions();
  }Future<void> fetchQuestions() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Theoquestions') // Directly fetching from the correct collection
          .get();

      if (querySnapshot.docs.isEmpty) {
        print("⚠️ No questions found in Firestore!");
      } else {
        print("✅ Found ${querySnapshot.docs.length} questions!");
      }

      List<Map<String, dynamic>> fetchedQuestions = [];

      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Check if all required fields exist
        if (!data.containsKey("Options") ||
            !data.containsKey("QuestionText") ||
            !data.containsKey("CorrectAnswer")) {
          print("🚨 Error: Missing required fields in document ${doc.id}");
          continue; // Skip invalid document
        }

        try {
          fetchedQuestions.add({
            "question": data["QuestionText"] ?? "No question text found",
            "options": List<String>.from(data["Options"] as List<dynamic>),
            "correctAnswers": List<int>.from(data["CorrectAnswer"] as List<dynamic>),
          });
        } catch (e) {
          print("🚨 Error processing document ${doc.id}: $e");
        }
      }

      // Shuffle questions to display them randomly
      fetchedQuestions.shuffle();

      setState(() {
        questions = fetchedQuestions;
        isLoading = false;
      });
    } catch (e) {
      print("🚨 Error fetching questions: $e");
      setState(() {
        isLoading = false;
      });
    }
  }


  void selectAnswer(int index) {
    if (showResult) return; // Empêche la sélection après confirmation

    setState(() {
      if (selectedAnswers.contains(index)) {
        selectedAnswers.remove(index);
      } else {
        selectedAnswers.add(index);
      }
    });
  }

  bool showErrorMessage = false;

  void confirmAnswer() {
    if (selectedAnswers.isEmpty) {
      setState(() {
        showErrorMessage = true;
      });
      return;
    }

    setState(() {
      showResult = true;
      showErrorMessage = false; // Hide error message when proceeding
    });
  }

  void nextQuestion() {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        selectedAnswers.clear();
        showResult = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : questions.isEmpty
          ? const Center(child: Text("No questions available"))
          : Column(
        children: [
          Container(
            height: screenHeight * 0.04,
            color: const Color(0xFF1B9169),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: screenHeight * 0.04),
                  const Text(
                    'Questions Théoriques',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B9169),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  Text(
                    questions[currentQuestionIndex]['question'],
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  Column(
                    children: List.generate(
                      questions[currentQuestionIndex]['options'].length,
                          (index) => Padding(
                        padding: const EdgeInsets.only(bottom: 15.0),
                        child: buildAnswerOption(index, screenWidth, screenHeight),
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.02),
                  ElevatedButton(
                    onPressed: confirmAnswer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D47E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      minimumSize: Size(screenWidth * 0.85, 50),
                    ),
                    child: const Text(
                      'Confirmer',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
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
                          child: const Text(
                            'Suivant',
                            style: TextStyle(color: Color(0xFF1B9169), fontSize: 16),
                          ),
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
                color: Colors.red,
                child: const Text(
                  'Veuillez sélectionner une réponse avant de confirmer.',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }


  Widget buildAnswerOption(int index, double screenWidth, double screenHeight) {
    bool isSelected = selectedAnswers.contains(index);
    bool isCorrect = showResult && questions[currentQuestionIndex]['correctAnswers'].contains(index);
    bool isWrongSelected = showResult && isSelected && !isCorrect;

    Color containerColor = Colors.white;
    Color borderColor = Colors.grey[300]!;
    IconData? icon;
    Color iconColor = Colors.grey;

    if (showResult) {
      if (isCorrect) {
        containerColor = ColorsManager.Bgreen3;
        borderColor = ColorsManager.Bgreen;
        icon = Icons.check_circle;
        iconColor = ColorsManager.Bgreen;
      } else if (isWrongSelected) {
        containerColor = ColorsManager.Red;
        borderColor = Colors.red;
        icon = Icons.cancel;
        iconColor = Colors.red;
      }
    } else if (isSelected) {
      borderColor = Colors.grey[600]!;
      icon = Icons.radio_button_checked;
      iconColor = ColorsManager.Gray6;
    }
    return GestureDetector(
      onTap: () => selectAnswer(index),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: screenHeight * 0.015,
          horizontal: screenWidth * 0.05,
        ),
        decoration: BoxDecoration(
          color: containerColor,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: Text(questions[currentQuestionIndex]['options'][index])),
            Icon(icon ?? Icons.check_box_outline_blank, color: iconColor),
          ],
        ),
      ),
    );
  }
}
