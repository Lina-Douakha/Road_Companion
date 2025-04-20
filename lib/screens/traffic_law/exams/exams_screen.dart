import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:road_companion/screens/traffic_law/exams/exams_result.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:road_companion/services/auth_service.dart';
import 'package:easy_localization/easy_localization.dart';

class ExamsScreen extends StatefulWidget {
  const ExamsScreen({super.key});

  @override
  _ExamsScreenState createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen> {
  int? selectedAnswer;
  List<Map<String, dynamic>> questions = [];
  int currentQuestionIndex = 0;
  Map<int, dynamic> selectedAnswers = {};

  bool isLoading = true;
  List<int?> userAnswers = []; // Store the user's selected answers
  String testId = "";
  String userId = "";
  bool responsesSaved = false;

  @override
  void initState() {
    super.initState();
    testId = generateRandomTestId();
    fetchCurrentUser();
  }


  // Fetch current logged-in user's ID
    void fetchCurrentUser() {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          userId = user.uid;
          fetchExamQuestions(testId);
        });
      } else {
        print("No user logged in.");
      }
    }


  String generateRandomTestId() {
    int randomNumber = Random().nextInt(20) +
        1; // Generates a number from 1 to 20
    return "Test$randomNumber";
  }

  Future<void> fetchExamQuestions(String examId) async {
    try {
      DocumentSnapshot examDoc = await FirebaseFirestore.instance
          .collection("Exam Test")
          .doc(examId)
          .get();

      if (!examDoc.exists) {
        print("Exam not found");
        setState(() => isLoading = false);
        return;
      }

      List<dynamic> questionIds = examDoc['ExamQuestions'] ?? [];
      List<Map<String, dynamic>> fetchedQuestions = [];

      // ✅ Fetch the first 24 questions from "Questions"
      for (int i = 0; i < 24 && i < questionIds.length; i++) {
        DocumentSnapshot questionDoc = await FirebaseFirestore.instance
            .collection(tr("database.TestQuestions"))
            .doc(questionIds[i])
            .get();

        if (questionDoc.exists) {
          fetchedQuestions.add(questionDoc.data() as Map<String, dynamic>);
        }
      }

      // ✅ Fetch the last 6 questions from "Theoquestions"
      for (int i = 24;  i < questionIds.length; i++) {
        DocumentSnapshot questionDoc = await FirebaseFirestore.instance
            .collection(tr("database.questions_theorique"))
            .doc(questionIds[i])
            .get();

        if (questionDoc.exists) {
          fetchedQuestions.add(questionDoc.data() as Map<String, dynamic>);
        }
      }

      setState(() {
        questions = fetchedQuestions;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching questions: $e");
      setState(() => isLoading = false);
    }
  }


  void nextQuestion() {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        selectedAnswer = null;
      });
    }
  }

  void previousQuestion() {
    if (currentQuestionIndex > 0) {
      setState(() {
        currentQuestionIndex--;
        selectedAnswer = null;
      });
    }
  }


  Future<void> saveUserResponses(String userId, String testId) async {
    CollectionReference userResponses = FirebaseFirestore.instance.collection("UserResponses");
    Map<String, dynamic> responseData = {
      "UserID": userId,
      "TestID": testId,
      "Responses": selectedAnswers.map((key, value) =>
          MapEntry(key.toString(), value is List ? value.map((e) => e.toString()).toList() : value.toString())),
      "Score": 0,
      "Timestamp": FieldValue.serverTimestamp(),
    };
    try {
      await userResponses.doc("$userId-$testId").set(responseData);
      print("User responses saved successfully!");
    } catch (e) {
      print("Error saving responses: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    final screenHeight = MediaQuery
        .of(context)
        .size
        .height;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF1B9169),
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: isLoading
            ? Center( // Ensures everything is centered in the screen
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              /*Text(
                "Préparation du test",
                style: TextStyle(
                  fontSize: screenWidth * 0.05,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00D47E),
                ),
              ),*/
              Lottie.asset(
                'assets/animation/Test.json',
                width: screenWidth * 0.5,
                height: screenHeight * 0.3,
                fit: BoxFit.contain,
              ),
            ],
          ),
        )

            : Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: screenHeight * 0.08),
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        tr(
                          "tests.test_label",
                          namedArgs: {
                            "id": testId.replaceAll("Test", "")
                          },
                        ), // Remove "Test" prefix if needed
                        style: TextStyle(
                          fontSize: screenWidth * 0.08,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1B9169),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.03,
                          vertical: screenHeight * 0.008,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1FADF),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Text(
                          'tests.question_progress'.tr(
                            namedArgs: {
                              'current': '${currentQuestionIndex + 1}',
                              'total': '${questions.length}'
                            }
                        ),
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1B9169),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    if (questions[currentQuestionIndex]['ImageURL'] != null &&
                        questions[currentQuestionIndex]['ImageURL']
                            .toString()
                            .isNotEmpty)
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: screenWidth * 0.6,
                            height: screenHeight * 0.2,
                            color: Colors.white,
                            child: Image.asset(
                              'assets/images/${questions[currentQuestionIndex]['Category'] ??
                                  ''}/${questions[currentQuestionIndex]['ImageURL']}',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      )
                    else
                      Center(
                        child: SizedBox(
                          width: screenWidth * 0.5, // Adjust size as needed
                          height: screenHeight * 0.2,
                          child: Lottie.asset('assets/animation/q&a.json'),
                        ),
                      ),


                    SizedBox(height: screenHeight * 0.02),
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        questions[currentQuestionIndex]['QuestionText'] ??
                            'Question not available',
                        style: const TextStyle(
                          fontSize: 18.0,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    for (int j = 0; j <
                        (questions[currentQuestionIndex]['Options'] as List<
                            dynamic>? ?? []).length; j++) ...[
                      buildAnswerOption(j,
                          questions[currentQuestionIndex]['Options'][j] ??
                              'Option not available', screenWidth),
                      SizedBox(height: screenHeight * 0.02),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              color: Colors.white, // Background to separate buttons
              padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Previous Question Button (Always Visible)
                  CircleAvatar(
                    radius: screenWidth * 0.08,
                    backgroundColor: const Color(0xFFD1FADF),
                    child: IconButton(
                      icon: const Icon(
                          Icons.arrow_back, color: Color(0xFF00D47E)),
                      onPressed: previousQuestion,
                    ),
                  ),

                  // Show "Next" button unless it's the last question
                  if (currentQuestionIndex < questions.length - 1)
                    CircleAvatar(
                      radius: screenWidth * 0.08,
                      backgroundColor: const Color(0xFFD1FADF),
                      child: IconButton(
                        icon: const Icon(
                            Icons.arrow_forward, color: Color(0xFF00D47E)),
                        onPressed: nextQuestion,
                      ),
                    )
                  else
                    ElevatedButton(
                      onPressed: () async {
                        if (!responsesSaved) {
                          saveUserResponses(userId, testId);
                          responsesSaved = true;
                        }

                        // Navigate to QuizResultsPage with a flag indicating if results were fetched
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                QuizResultsPage(
                                  userId: userId,
                                  testId: testId,

                                ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00D47E),
                        padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.1,
                            vertical: screenHeight * 0.015),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                      ),
                      child: Text(
                        'confirmer'.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),


                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildAnswerOption(int index, String text, double screenWidth) {
    bool isMultipleChoice = currentQuestionIndex >= questions.length - 6;

    return Align(
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (isMultipleChoice) {
              if (selectedAnswers[currentQuestionIndex] == null ||
                  selectedAnswers[currentQuestionIndex] is! List<int>) {
                selectedAnswers[currentQuestionIndex] =
                <int>[]; // Initialize list
              }
              List<int> selectedList =
              selectedAnswers[currentQuestionIndex] as List<int>;

              if (selectedList.contains(index)) {
                selectedList.remove(index);
              } else {
                selectedList.add(index);
              }
            } else {
              selectedAnswers[currentQuestionIndex] = index;
            }
          });
        },
        child: Container(
          width: screenWidth * 0.85,
          padding: EdgeInsets.symmetric(
              vertical: screenWidth * 0.01, horizontal: screenWidth * 0.03),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: isMultipleChoice
                  ? ((selectedAnswers[currentQuestionIndex] as List<int>?)
                  ?.contains(index) ??
                  false)
                  ? Colors.grey[600]!
                  : Colors.grey[300]!
                  : (selectedAnswers[currentQuestionIndex] == index
                  ? Colors.grey[600]!
                  : Colors.grey[300]!),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text(text, textAlign: TextAlign.start)),
              isMultipleChoice
                  ? Checkbox(
                value: (selectedAnswers[currentQuestionIndex] as List<int>?)?.contains(index) ?? false,
                onChanged: (bool? value) {
                  setState(() {
                    selectedAnswers[currentQuestionIndex] ??= <int>[];
                    List<int> selectedList = selectedAnswers[currentQuestionIndex] as List<int>;
                    if (value == true) {
                      selectedList.add(index);
                    } else {
                      selectedList.remove(index);
                    }
                  });
                },
                side: BorderSide(
                  color: Colors.grey[300]!, // ✅ Unselected border color
                  width: 2, // Adjust thickness if needed
                ),
                activeColor: Colors.grey[600], // ✅ When selected, fill becomes grey 600
                checkColor: Colors.white, // ✅ Checkmark color inside the box
                fillColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.grey[600]; // ✅ Selected: Fill is grey 600
                  }
                  return Colors.white; // ✅ Unselected: Fill is white
                }),
              )

          : Radio<int>(
                value: index,
                groupValue: selectedAnswers[currentQuestionIndex] is int
                    ? selectedAnswers[currentQuestionIndex] as int
                    : null,
                onChanged: (int? value) {
                  setState(() {
                    selectedAnswers[currentQuestionIndex] = value!;
                  });
                },
                activeColor: Colors.grey[600],
                fillColor: WidgetStateProperty.resolveWith<Color?>(
                      (Set<WidgetState> states) {
                    return selectedAnswers[currentQuestionIndex] == index
                        ? Colors.grey[600]
                        : Colors.grey[300];
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}