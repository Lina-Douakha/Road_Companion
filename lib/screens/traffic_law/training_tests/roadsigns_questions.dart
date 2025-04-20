import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:road_companion/Theming/colors.dart';
import 'package:easy_localization/easy_localization.dart';


class RoadSignQuestionScreen extends StatefulWidget {
  const RoadSignQuestionScreen({super.key});

  @override
  _RoadSignQuestionScreenState createState() => _RoadSignQuestionScreenState();
}

class _RoadSignQuestionScreenState extends State<RoadSignQuestionScreen> {
  int? selectedAnswer;
  bool showResult = false;
  bool showErrorMessage = false;
  bool isConfirmed = false;
  bool isLoading = true;

  List<Map<String, dynamic>> questions = [];
  int currentQuestionIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchQuestions();
  }
  /// **Fetch questions from Firestore where Category = "Panels"**
  Future<void> fetchQuestions() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection(tr("database.TestQuestions"))
          .where('Category', isEqualTo: 'Panels')
          .get();

      List<Map<String, dynamic>> fetchedQuestions = querySnapshot.docs.map((doc) => {
        "image": doc["ImageURL"],  // We only get the name (e.g., panel01.png)
        "question": doc["QuestionText"],
        "options": List<String>.from(doc["Options"]),
        "correctAnswer": doc["CorrectAnswer"]
      }).toList();

      // Mélanger la liste pour un affichage aléatoire
      fetchedQuestions.shuffle();

      setState(() {
        questions = fetchedQuestions;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching questions: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

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
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        selectedAnswer = null;
        showResult = false;
        isConfirmed = false;
      });
    }
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
                padding:
                EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: screenHeight * 0.04),
                    Text(
                      tr("Categories.Panels"),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B9169),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenHeight * 0.03),


                    Image.asset(
                      'assets/images/Panels/${questions[currentQuestionIndex]['image']}',
                      width: screenWidth * 0.4,
                      fit: BoxFit.fitWidth,
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
                          padding: const EdgeInsets.only(bottom: 15.0), // Espacement entre les options
                          child: buildAnswerOption(
                            index,
                            questions[currentQuestionIndex]['options'][index],
                            screenWidth,
                            screenHeight,
                            questions[currentQuestionIndex]['correctAnswer'],
                          ),
                        ),
                      ),
                    ),


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
                      child: Text('confirmer'.tr(),
                        style: const TextStyle(color: Colors.white, fontSize: 16),
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
                            child: Text('suivant'.tr(),
                              style: const TextStyle(color: Color(0xFF1B9169), fontSize: 16),
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
                  child: Text(
                    'error_select_answer'.tr(),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),

                ),
              ),
          ],
        ),
      ),
    );
  }
  Widget buildAnswerOption(int index, String text, double screenWidth, double screenHeight, String correctAnswer) {
    bool isSelected = selectedAnswer == index;
    bool isCorrect = text == correctAnswer;
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
        width: double.infinity, // Prend toute la largeur disponible
        padding: EdgeInsets.symmetric(
          vertical: screenHeight * 0.015, // Ajuste la hauteur dynamiquement
          horizontal: screenWidth * 0.05, // Ajuste la largeur en fonction de l'écran
        ),
        decoration: BoxDecoration(
          color: containerColor, // 🌟 Ajouté ici pour colorer tout le conteneur !
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                text,
                style: TextStyle(fontSize: screenWidth * 0.04, color: Colors.black), // Assure-toi que le texte reste lisible
              ),
            ),
            Icon(icon ?? Icons.radio_button_unchecked, color: iconColor),
          ],
        ),
      ),
    );

  }

}     