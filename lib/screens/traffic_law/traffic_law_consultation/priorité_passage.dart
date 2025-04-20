import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:road_companion/widgets/navigation_bar_widget.dart';
import 'package:easy_localization/easy_localization.dart';

class PriorityQuestionScreen extends StatefulWidget {
  @override
  _PriorityQuestionScreenState createState() => _PriorityQuestionScreenState();
}

class _PriorityQuestionScreenState extends State<PriorityQuestionScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> questions = [];
  int currentIndex = 0;
  bool showAnswer = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPriorityQuestions();
  }

  // ✅ Fetch priority questions from Firestore
  Future<void> _fetchPriorityQuestions() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(tr("database.courses"))
          .where("Category", isEqualTo: "priorities")
          .get();

      List<Map<String, dynamic>> fetchedQuestions = querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      if (mounted) {
        setState(() {
          questions = fetchedQuestions;
          isLoading = false; // ✅ Stop loading once questions are fetched
        });
      }
    } catch (e) {
      print("Error fetching priority questions: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void nextQuestion() {
    if (questions.isNotEmpty) {
      setState(() {
        currentIndex = (currentIndex + 1) % questions.length;
        showAnswer = false;
      });
    }
  }

  void previousQuestion() {
    if (questions.isNotEmpty) {
      setState(() {
        currentIndex = (currentIndex - 1 + questions.length) % questions.length;
        showAnswer = false;
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
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF1B9169),
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 70),
               Text(
                tr("Categories.Prio"),
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B9169),
                ),
              ),
              const SizedBox(height: 10),

              // Show loading indicator if data is still loading
              if (isLoading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              // Show content only if questions are available
              else if (questions.isNotEmpty)
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (questions[currentIndex]["imageURL"] != null &&
                            questions[currentIndex]["imageURL"].isNotEmpty)
                          Image.asset(
                            "assets/images/priorities/${questions[currentIndex]["imageURL"]}",
                            width: screenWidth * 0.8,
                            height: screenHeight * 0.3,
                            fit: BoxFit.contain,
                          ),

                        const SizedBox(height: 10),

                        // Dynamic Question Container
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: 60,
                            maxHeight: screenHeight * 0.4,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            width: screenWidth * 0.9,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: SingleChildScrollView(
                              child: Text(
                                questions[currentIndex]["Question"] ?? "Question non disponible",
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Show Answer Button
                        SizedBox(
                          width: 300,
                          height: 55,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                showAnswer = !showAnswer;
                              });
                            },
                            label: const Text(
                              "Afficher la réponse",
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD1FADF),
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: Icon(
                              showAnswer ? Icons.expand_less : Icons.expand_more,
                              color: const Color(0xFF00D47E),
                              size: 30,
                            ),
                          ),
                        ),

                        // Show Answer if button is pressed
                        if (showAnswer)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              width: screenWidth * 0.9,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white,
                              ),
                              child: Text(
                                questions[currentIndex]["Description"] ?? "Réponse non disponible",
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),

              // Fixed Navigation Buttons
              if (!isLoading && questions.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      onPressed: previousQuestion,
                      icon: const Icon(Icons.arrow_circle_left_outlined, size: 30),
                      color: const Color(0xFF1B9169),
                      tooltip: "Question précédente",
                    ),
                    IconButton(
                      onPressed: nextQuestion,
                      icon: const Icon(Icons.arrow_circle_right_outlined, size: 30),
                      color: const Color(0xFF1B9169),
                      tooltip: "Question suivante",
                    ),
                  ],
                ),
            ],
          ),
        ),

        // ✅ Bottom Navigation Bar
        bottomNavigationBar: NavigationBarWidget(
          selectedIndex: _selectedIndex,
          onItemTapped: _onItemTapped,
        ),
      ),
    );
  }
}





