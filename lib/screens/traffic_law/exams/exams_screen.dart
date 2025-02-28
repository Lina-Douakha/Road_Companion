import 'package:flutter/material.dart';

class ExamsScreen extends StatelessWidget {
  const ExamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> exams = [
      "Beginner’s Driving Exam",
      "Advanced Road Safety Test",
      "Highway Code Assessment",
      "Vehicle Control & Maneuvers",
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
            'Exams',
             style: TextStyle(color: Color(0xFFF8FAFC)),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1B9169),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: exams.length,
        itemBuilder: (context, index) {
          return Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.assignment, color: Color(0xFF00D47E)),
              title: Text(
                exams[index],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: ElevatedButton(
                onPressed: () {
                  // TODO: Navigate to exam screen
                },
                style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00D47E)),
                child: const Text(
                    "Start",
                  style: TextStyle(color: Color(0xFFF8FAFC)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
