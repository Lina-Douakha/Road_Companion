import 'package:flutter/material.dart';

class PriorityQuestionScreen extends StatefulWidget {
  @override
  _PriorityQuestionScreenState createState() => _PriorityQuestionScreenState();
}

class _PriorityQuestionScreenState extends State<PriorityQuestionScreen> {
  // Liste des questions et réponses
  final List<Map<String, String>> questions = [
    {
      "imageUrl":
          "https://via.placeholder.com/300", // Remplace par une vraie image
      "question": "Qui a la priorité à cette intersection ?",
      "answer": "Le véhicule venant de droite a la priorité.",
    },
    {
      "imageUrl": "https://via.placeholder.com/300",
      "question": "Quel véhicule doit céder le passage ?",
      "answer": "La voiture rouge doit céder le passage.",
    },
    {
      "imageUrl": "https://via.placeholder.com/300",
      "question": "Que signifie ce panneau ?",
      "answer": "Ce panneau indique une priorité à droite.",
    },
  ];

  int currentIndex = 0;
  bool showAnswer = false;

  // Fonction pour changer de question
  void nextQuestion() {
    setState(() {
      currentIndex = (currentIndex + 1) % questions.length;
      showAnswer = false; // Masquer la réponse pour la nouvelle question
    });
  }

  @override
  Widget build(BuildContext context) {
    final questionData = questions[currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text("Priorité de passage"),
        backgroundColor: Colors.green[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Priorité de passage",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 15),

            // Affichage de l’image
            Image.network(
              questionData["imageUrl"]!,
              height: 200,
              fit: BoxFit.cover,
            ),

            SizedBox(height: 15),

            // Champ de texte pour la question
            TextField(
              controller: TextEditingController(text: questionData["question"]),
              readOnly: true,
              decoration: InputDecoration(border: OutlineInputBorder()),
            ),

            SizedBox(height: 15),

            // Bouton pour afficher la réponse
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  showAnswer = !showAnswer;
                });
              },
              icon: Icon(showAnswer ? Icons.expand_less : Icons.expand_more),
              label: Text("Afficher la réponse"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[400],
                foregroundColor: Colors.white,
              ),
            ),

            // Affichage conditionnel de la réponse
            if (showAnswer)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  questionData["answer"]!,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.green[800],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            Spacer(),

            // Bouton pour passer à une autre question
            IconButton(
              onPressed: nextQuestion, // Charger une nouvelle question
              icon: Icon(Icons.refresh, size: 30),
            ),
          ],
        ),
      ),
    );
  }
}
