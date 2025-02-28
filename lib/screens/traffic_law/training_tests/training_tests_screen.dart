import 'package:flutter/material.dart';

class TrainingTestsScreen extends StatelessWidget {
  const TrainingTestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> tests = [
      "Basic Road Signs",
      "Traffic Signals Test",
      "Right of Way Rules",
      "Speed Limits & Penalties",
      "General Driving Knowledge",
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Training Tests',
          style: TextStyle(color: Color(0xFFF8FAFC)),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1B9169),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: tests.length,
        itemBuilder: (context, index) {
          return Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.book, color: Color(0xFF00D47E)),
              title: Text(
                tests[index],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: ElevatedButton(
                onPressed: () {
                  // TODO: Navigate to test screen
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
