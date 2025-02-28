import 'package:flutter/material.dart';

class IncidentReportScreen extends StatelessWidget {
  const IncidentReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController descriptionController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
        'Report an Incident',
        style: TextStyle(color: Color(0xFFF8FAFC)),
      ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1B9169),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Describe the incident:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Enter incident details...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Simulating incident submission
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Incident report submitted successfully!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.report),
                label: const Text(
                    'Submit Report',
                  style: TextStyle(color: Color(0xFFF8FAFC)),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF00D47E),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  textStyle: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

