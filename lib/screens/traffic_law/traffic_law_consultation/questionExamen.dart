import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:road_companion/widgets/navigation_bar_widget.dart';
import 'package:easy_localization/easy_localization.dart';

class QuestionExamen extends StatefulWidget {
  @override
  _QuestionExamenState createState() => _QuestionExamenState();
}

class _QuestionExamenState extends State<QuestionExamen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> questions = [];
  int currentIndex = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchExamQuestions();
  }

  Future<void> _fetchExamQuestions() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(tr("database.courses"))
          .where("Category", isEqualTo: "question") // Filter for exam questions
          .get();

      List<Map<String, dynamic>> fetchedQuestions = querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      setState(() {
        questions = fetchedQuestions;
        isLoading = false; // Stop loading indicator
      });
    } catch (e) {
      print("Error fetching exam questions: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Next question
  void nextQuestion() {
    setState(() {
      currentIndex = (currentIndex + 1) % questions.length;
    });
  }

  /// Previous question
  void previousQuestion() {
    setState(() {
      currentIndex = (currentIndex - 1 + questions.length) % questions.length;
    });
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
          child: isLoading
              ? const Center(child: CircularProgressIndicator()) // Loading
              : questions.isEmpty
              ? const Center(child: Text("Aucune question trouvée."))
              : Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: screenHeight * 0.09),

              // Title
               Center(
                child: Text(
                  tr("Categories.Questions_title"),
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B9169),
                  ),
                ),
              ),
              //const SizedBox(height: 8),
              SizedBox(height: screenHeight * 0.04),

              // Question counter (Styled Container)
              Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.03,
                    vertical: screenHeight * 0.008,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FADF), // Light green background
                    borderRadius: BorderRadius.circular(20.0), // Rounded shape
                  ),
                  child: Text(
                    'tests.question_progress'.tr(
                        namedArgs: {
                          'current': '${currentIndex + 1}',
                          'total': '${questions.length}'
                        }
                    ), // Dynamic question number
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1B9169), // Dark green text
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Main container
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Question display (auto-size)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                        ),
                        child: Text(
                          questions[currentIndex]["QuestionText"] ??
                              "Question non disponible",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Answer display (auto-size)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                          borderRadius: BorderRadius.circular(12),
                          color: const Color.fromARGB(255, 255, 255, 255),
                        ),
                        child: Text(
                          questions[currentIndex]["Answer"] ??
                              "Réponse non disponible",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              // Navigation buttons
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

        // Bottom navigation bar
        bottomNavigationBar: NavigationBarWidget(
          selectedIndex: _selectedIndex,
          onItemTapped: _onItemTapped,
        ),
      ),
    );
  }
}



