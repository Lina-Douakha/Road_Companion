import 'package:flutter/material.dart';

class TrafficLawScreen extends StatelessWidget {
  const TrafficLawScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> trafficLaws = [
      {'title': 'Speed Limits', 'description': 'Observe speed limits to ensure safety.'},
      {'title': 'Seat Belt Requirement', 'description': 'All passengers must wear seat belts.'},
      {'title': 'Traffic Signals', 'description': 'Follow all traffic signals and signs.'},
      {'title': 'No Drunk Driving', 'description': 'Driving under the influence is strictly prohibited.'},
      {'title': 'Right of Way', 'description': 'Yield to pedestrians and emergency vehicles.'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
            'Traffic Laws',
             style: TextStyle(color: Color(0xFFF8FAFC)),

        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1B9169),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: trafficLaws.length,
        itemBuilder: (context, index) {
          return Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.gavel, color: Color(0xFF00D47E)),
              title: Text(
                trafficLaws[index]['title']!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(trafficLaws[index]['description']!),
            ),
          );
        },
      ),
    );
  }
}
