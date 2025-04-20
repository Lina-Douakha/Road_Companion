import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:road_companion/widgets/navigation_bar_widget.dart';
import 'dart:async';
import 'package:lottie/lottie.dart';
import 'package:easy_localization/easy_localization.dart';

class QuizResultsPage extends StatefulWidget {
  final String userId;
  final String testId;

  const QuizResultsPage({required this.userId, required this.testId});


  @override
  _QuizResultsPageState createState() => _QuizResultsPageState();
}

class _QuizResultsPageState extends State<QuizResultsPage> {
  double? userScore;
  double scorePercentage = 0.0;
  List<Map<String, String>> answerPairs = [];
  List<Map<String, String>> multiAnswerPairs = [];
  bool isLoading = true;
  int dotIndex = 0;
bool resultsFetched = false;
  @override
  void initState() {
    super.initState();
    fetchResults();
  }

  Future<void> fetchResults() async {
    if (!isLoading) return; // Prevent refetching if already loaded

    try {
      Map<String, dynamic> results = await calculateScore(widget.userId, widget.testId);

      if (mounted) {
        setState(() {
          userScore = (results["Score"] as num).toDouble(); // Safe casting
          answerPairs = results["AnswerPairs"];
          multiAnswerPairs = results["MultiAnswerPairs"];
          scorePercentage = double.parse((userScore! / 30).toStringAsFixed(2));
        });
      }
    } catch (e) {
      print("Error fetching results: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  double getScoreForQuestion(List<String> selectedOptions, List<String> correctOptions) {
    int correctCount = selectedOptions.where((option) => correctOptions.contains(option)).length;
    int totalCorrect = correctOptions.length;
    int extraCount = selectedOptions.length - correctCount; // Extra incorrect selections

    if (correctCount == totalCorrect && selectedOptions.length == totalCorrect) {
      return 1.0;
    } else if (correctCount > 0) {
      double scorePerCorrectAnswer = 1.0 / totalCorrect;
      double partialScore = correctCount * scorePerCorrectAnswer;


      double penalty = extraCount * scorePerCorrectAnswer;
      partialScore -= penalty;

      return partialScore > 0 ? partialScore : 0.0;
    }
    return 0.0;
  }

  Future<Map<String, dynamic>> calculateScore(String userId, String testId) async {
    List<Map<String, String>> answerPairs = [];
    List<Map<String, String>> multiAnswerPairs = [];
    double correctCount = 0.0; // Now using double for fractional scoring

    try {
      // Fetch user responses
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection("UserResponses").doc("$userId-$testId").get();
      if (!userDoc.exists) return {"Score": correctCount, "AnswerPairs": answerPairs, "MultiAnswerPairs": multiAnswerPairs};

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      Map<String, dynamic> userResponses = userData["Responses"] ?? {};

      // Fetch test questions
      DocumentSnapshot testDoc = await FirebaseFirestore.instance.collection("Exam Test").doc(testId).get();
      if (!testDoc.exists) return {"Score": correctCount, "AnswerPairs": answerPairs, "MultiAnswerPairs": multiAnswerPairs};

      List<dynamic> questionIds = testDoc["ExamQuestions"] ?? [];

      // Process first 24 questions (single-answer)
      for (int i = 0; i < 24; i++) {
        String questionId = questionIds[i];
        String? selectedAnswer = userResponses[i.toString()];

        DocumentSnapshot questionDoc = await FirebaseFirestore.instance.collection((tr("database.TestQuestions"))).doc(questionId).get();
        if (!questionDoc.exists) continue;

        Map<String, dynamic> questionData = questionDoc.data() as Map<String, dynamic>;
        List<dynamic> options = questionData["Options"] ?? [];
        String correctAnswer = questionData["CorrectAnswer"] ?? "";

        // Store answers
        answerPairs.add({
          "SelectedOption": selectedAnswer == null ? "tests.none_selected".tr() : options[int.parse(selectedAnswer)].toString(),
          "CorrectAnswer": correctAnswer,
        });

        // ✅ Check correctness (full points for single-answer questions)
        if (selectedAnswer != null && options[int.parse(selectedAnswer)].toString() == correctAnswer) {
          correctCount += 1;
        }
      }

      // ✅ Process remaining 6 questions (multiple-answer)
      for (int i = 24; i < questionIds.length; i++) {
        String questionId = questionIds[i];
        DocumentSnapshot questionDoc = await FirebaseFirestore.instance.collection(tr("database.questions_theorique")).doc(questionId).get();
        if (!questionDoc.exists) continue;

        Map<String, dynamic> questionData = questionDoc.data() as Map<String, dynamic>;
        List<dynamic> options = questionData["Options"] ?? [];
        var correctAnswersRaw = questionData["CorrectAnswer"];

        // ✅ Extract correct answer indexes
        List<int> correctAnswersIndexes = [];
        if (correctAnswersRaw is List) {
          correctAnswersIndexes = correctAnswersRaw.map((e) => int.tryParse(e.toString()) ?? -1).where((e) => e != -1).toList();
        } else if (correctAnswersRaw is Map) {
          correctAnswersIndexes = correctAnswersRaw.values.map((e) => int.tryParse(e.toString()) ?? -1).where((e) => e != -1).toList();
        }

        // ✅ Extract user's selected answers
        dynamic selectedAnswersRaw = userResponses[i.toString()];
        List<int> selectedAnswers = [];

        if (selectedAnswersRaw is List) {
          selectedAnswers = selectedAnswersRaw.map((e) => int.tryParse(e.toString()) ?? -1).where((e) => e != -1).toList();
        } else if (selectedAnswersRaw is String) {
          int? parsed = int.tryParse(selectedAnswersRaw);
          if (parsed != null) selectedAnswers = [parsed];
        }

        // ✅ Convert indexes to actual answer text
        List<String> correctText = correctAnswersIndexes
            .where((index) => index >= 0 && index < options.length)
            .map((index) => options[index].toString())
            .toList();

        List<String> selectedText = selectedAnswers
            .where((index) => index >= 0 && index < options.length)
            .map((index) => options[index].toString())
            .toList();

        // ✅ Handle case where no answer was selected
        multiAnswerPairs.add({
          "SelectedOption": selectedText.isEmpty ? "tests.none_selected".tr() : selectedText.join(", "),
          "CorrectAnswer": correctText.join(", "),
        });

        // Calculate partial score for multiple-answer questions
        correctCount += getScoreForQuestion(selectedText, correctText);
      }

      // Save score in Firestore
      await FirebaseFirestore.instance.collection("UserResponses").doc("$userId-$testId").update({"Score": correctCount});

      // Debugging output
      print("Final Score: $correctCount");
      print("Answer Pairs: $answerPairs");
      print("Multi-Answer Pairs: $multiAnswerPairs");

    } catch (e) {
      print("Error calculating score: $e");
    }

    return {"Score": correctCount, "AnswerPairs": answerPairs, "MultiAnswerPairs": multiAnswerPairs};
  }


  int _selectedIndex = 0;
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double baseSize = screenWidth * 0.05;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF1B9169),
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: isLoading
              ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min, // Prevents overflow
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: screenHeight * 0.02),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Lottie.asset(
                        'assets/animation/car_loading.json',
                        width: screenWidth * 0.8,
                        height: screenHeight * 0.4,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
              : CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: screenHeight * 0.04),
                    Text(
                      'tests.test_result'.tr(),
                      style: TextStyle(
                        fontSize: baseSize * 1.6,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1B9169),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.04),
                    Align(
                      alignment: Alignment.center,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: scorePercentage),
                        duration: const Duration(seconds: 1),
                        builder: (context, animatedValue, child) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                height: screenWidth * 0.35,
                                width: screenWidth * 0.35,
                                child: CircularProgressIndicator(
                                  value: animatedValue > 0 ? animatedValue : 0.01,
                                  strokeWidth: screenWidth * 0.035,
                                  backgroundColor: Colors.grey[300],
                                  valueColor:
                                  const AlwaysStoppedAnimation(Color(0xFF00D47E)),
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(height: screenHeight * 0.004),
                                  Text(
                                    '${(userScore ?? 0).toStringAsFixed(2)}/${answerPairs.length + multiAnswerPairs.length}',
                                    style: TextStyle(
                                      fontSize: baseSize * 1.4,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),


                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.04),
                  ],
                ),
              ),

              // Display single-answer and multiple-answer questions
              SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    bool isMultiAnswer = index >= answerPairs.length;
                    Map<String, String> currentPair = isMultiAnswer
                        ? multiAnswerPairs[index - answerPairs.length]
                        : answerPairs[index];

                    List<String> selectedOptions = [];
                    List<String> correctOptions = [];

                    if (isMultiAnswer) {
                      selectedOptions = currentPair["SelectedOption"] != null
                          ? currentPair["SelectedOption"]!.split(", ")
                          : [];

                      correctOptions = currentPair["CorrectAnswer"] != null
                          ? currentPair["CorrectAnswer"]!.split(", ")
                          : [];
                    } else {
                      selectedOptions = currentPair["SelectedOption"] != null
                          ? [currentPair["SelectedOption"]!.trim()]
                          : [];

                      correctOptions = currentPair["CorrectAnswer"] != null
                          ? [currentPair["CorrectAnswer"]!.trim()]
                          : [];
                    }

                    bool isFullyCorrect = Set<String>.from(selectedOptions)
                        .containsAll(correctOptions) &&
                        Set<String>.from(correctOptions)
                            .containsAll(selectedOptions);
                    bool isPartiallyCorrect = selectedOptions.any((option) => correctOptions.contains(option)) &&
                        !isFullyCorrect;

                    Color cardColor = isFullyCorrect
                        ? const Color(0xFFD1FADF)
                        : isPartiallyCorrect
                        ? const Color(0xFFFFF4CC)
                        : const Color(0xFFFFEBEE);

                    return Card(
                      color: cardColor,
                      margin: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.008,
                          horizontal: screenWidth * 0.05),
                      child: ListTile(
                        leading: Icon(
                          isFullyCorrect
                              ? Icons.check_circle
                              : isPartiallyCorrect
                              ? Icons.error_outline
                              : Icons.cancel,
                          color: isFullyCorrect
                              ? const Color(0xFF00D47E)
                              : isPartiallyCorrect
                              ? const Color(0xFFFFA500)
                              : Colors.red,
                          size: baseSize * 1.1,
                        ),
                        title: Text(
                          tr(
                            "tests.question_number",
                            namedArgs: {
                              'number': '${index + 1}'
                            },
                          ),
                          style: TextStyle(
                            fontSize: baseSize * 0.8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isMultiAnswer) ...[
                              Text(
                                'tests.selected_answers'.tr(),
                                style: TextStyle(
                                    fontSize: baseSize * 0.7,
                                    fontWeight: FontWeight.bold),
                              ),
                              ...selectedOptions.map((option) => Text(
                                "• $option",
                                style: TextStyle(
                                  fontSize: baseSize * 0.7,
                                  color: correctOptions.contains(option)
                                      ? const Color(0xFF00D47E)
                                      : Colors.red,
                                ),
                              )),
                              SizedBox(height: screenHeight * 0.005),
                              Text(
                                'tests.correction'.tr(),
                                style: TextStyle(
                                    fontSize: baseSize * 0.7,
                                    fontWeight: FontWeight.bold),
                              ),
                              ...correctOptions.map((option) => Text(
                                "• $option",
                                style: TextStyle(
                                    fontSize: baseSize * 0.7,
                                    color: Colors.black),
                              )),
                            ] else ...[
                              Text(
                                'tests.your_answer'.tr(),
                                style: TextStyle(
                                    fontSize: baseSize * 0.7,
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "• ${currentPair['SelectedOption']}",
                                style: TextStyle(
                                  fontSize: baseSize * 0.7,
                                  color: isFullyCorrect
                                      ? const Color(0xFF00D47E)
                                      : Colors.red,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.005),
                              Text(
                                'tests.correction'.tr(),
                                style: TextStyle(
                                    fontSize: baseSize * 0.7,
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "• ${currentPair['CorrectAnswer']}",
                                style: TextStyle(fontSize: baseSize * 0.7, color: Colors.black),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );

                      },
                  childCount: answerPairs.length + multiAnswerPairs.length,
                ),
              ),
            ],
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