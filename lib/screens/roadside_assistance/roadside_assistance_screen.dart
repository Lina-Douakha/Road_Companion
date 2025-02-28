import 'package:flutter/material.dart';

class RoadsideAssistanceScreen extends StatelessWidget {
  const RoadsideAssistanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Roadside Assistance',
          style: TextStyle(color: Color(0xFFF8FAFC)),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1B9169),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.car_repair,
              size: 80,
              color: Color(0xFF00D47E),
            ),
            const SizedBox(height: 20),
            const Text(
              'Need roadside assistance?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                // Simulate requesting assistance
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Request sent! Help is on the way.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.support_agent),
              label: const Text('Request Assistance'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
