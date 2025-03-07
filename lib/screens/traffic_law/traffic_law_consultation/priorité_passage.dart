import 'package:flutter/material.dart';
import 'package:road_companion/widgets/navigation_bar_widget.dart';

class PriorityQuestionScreen extends StatefulWidget {
  @override
  _PriorityQuestionScreenState createState() => _PriorityQuestionScreenState();
}

class _PriorityQuestionScreenState extends State<PriorityQuestionScreen> {
  // Liste des questions et réponses
  final List<Map<String, String>> questions = [
    {
      "imageUrl": "assets/images/prioritéAlgerien.jpg",
      "question": "Qui a la priorité à cette intersection ?",
      "answer":
      "Intersection avec un panneau stop à 150 mètres :\n Un panneau stop est placé à 150 mètres.\nLes voitures bleue et jaune passent en même temps, suivies par la voiture rouge",
    },
    {
      "imageUrl": "assets/images/prioritéAlgerien2.jpg",
      "question": "Qui a la priorité à cette intersection ?",
      "answer": " Le véhicule rouge et le véhicule bleu ont la priorité.",
    },
  ];

  int currentIndex = 0;
  bool showAnswer = false;

  // Fonction pour aller à la question suivante
  void nextQuestion() {
    setState(() {
      currentIndex = (currentIndex + 1) % questions.length;
      showAnswer = false; // Masquer la réponse pour la nouvelle question
    });
  }

  int _selectedIndex = 0;
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Fonction pour revenir à la question précédente
  void previousQuestion() {
    setState(() {
      currentIndex = (currentIndex - 1 + questions.length) % questions.length;
      showAnswer = false; // Masquer la réponse pour la nouvelle question
    });
  }

  @override
  Widget build(BuildContext context) {
    final questionData = questions[currentIndex];
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text('Road Companion'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1B9169),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Priorité de passage',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B9169),
                      ),
                    ),
                    SizedBox(height: 15),

                    // Vérification de l'existence de l'image
                    if (questionData.containsKey("imageUrl"))
                      Image.asset(
                        questionData["imageUrl"]!,
                        height: 150,
                        fit: BoxFit.cover,
                      ),

                    SizedBox(height: 40),

                    // Champ de texte pour la question
                    SizedBox(
                      width: 350,
                      height: 60,
                      child: TextField(
                        controller: TextEditingController(
                          text:
                          questionData["question"] ??
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

                    // Bouton pour afficher la réponse
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

                    // Affichage conditionnel de la réponse
                    if (showAnswer)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          questionData["answer"] ?? "Réponse non disponible",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF000000),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    SizedBox(
                      height: 40,
                    ), // Ajout d'un espace pour éviter le chevauchement
                  ],
                ),
              ),
            ),

            // Boutons pour naviguer entre les questions
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
    );
  }
}

