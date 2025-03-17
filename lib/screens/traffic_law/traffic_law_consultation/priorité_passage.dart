import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:road_companion/widgets/navigation_bar_widget.dart';

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

  //Fetch priority questions from Firestore
  Future<void> _fetchPriorityQuestions() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection("Traffic-Laws")
          .where("Category", isEqualTo: "priorities") // Filter for priority questions
          .get();

      List<Map<String, dynamic>> fetchedQuestions = querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      setState(() {
        questions = fetchedQuestions;
        isLoading = false; // Stop loading indicator
      });
    } catch (e) {
      print("Error fetching priority questions: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  // Go to next question
  void nextQuestion() {
    if (questions.isNotEmpty) {
      setState(() {
        currentIndex = (currentIndex + 1) % questions.length;
        showAnswer = false; // Hide answer when switching
      });
    }
  }

  // Go to previous question
  void previousQuestion() {
    if (questions.isNotEmpty) {
      setState(() {
        currentIndex = (currentIndex - 1 + questions.length) % questions.length;
        showAnswer = false; // Hide answer when switching
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
              ? Center(child: CircularProgressIndicator()) // Show loading indicator
              : questions.isEmpty
              ? Center(child: Text("Aucune question de priorité trouvée."))
              : Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: screenHeight * 0.09),
                      const Text(
                        'Priorité de passage',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B9169),
                        ),
                      ),
                      SizedBox(height: 20),

                      // Show image if exists (Load from assets instead of network)
                      if (questions[currentIndex]["imageURL"] != null &&
                          questions[currentIndex]["imageURL"].isNotEmpty)
                        Image.asset(
                          "assets/images/priorities/${questions[currentIndex]["imageURL"]}",
                          height: 150,
                          fit: BoxFit.cover,
                        ),


                      SizedBox(height: 40),

                      // Show Question
                      SizedBox(
                        width: 350,
                        height: 60,
                        child: TextField(
                          controller: TextEditingController(
                            text: questions[currentIndex]["Question"] ??
                                "Question non disponible",
                          ),
                          readOnly: true,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 30),

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
                          label: Text(
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
                            color: Color(0xFF00D47E),
                            size: 30,
                          ),
                        ),
                      ),

                      // Show Answer if button is pressed
                      if (showAnswer)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            questions[currentIndex]["Description"] ?? "Réponse non disponible",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF000000),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              // Navigation Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: previousQuestion,
                    icon: Icon(Icons.arrow_circle_left_outlined, size: 30),
                    color: Color(0xFF1B9169),
                    tooltip: "Question précédente",
                  ),
                  IconButton(
                    onPressed: nextQuestion,
                    icon: Icon(Icons.arrow_circle_right_outlined, size: 30),
                    color: Color(0xFF1B9169),
                    tooltip: "Question suivante",
                  ),
                ],
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

