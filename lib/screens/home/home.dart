import 'package:flutter/material.dart';
import '../traffic_law/traffic_law_consultation/traffic_law_screen.dart';
import '../incident_reporting/incident_report_screen.dart';
import '../roadside_assistance/roadside_assistance_screen.dart';
import '../traffic_law/training_tests/training_tests_screen.dart';
import '../traffic_law/exams/exams_screen.dart';
import '../authenticate/login.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
            'Road Companion',
          style: TextStyle(color: Color(0xFFF8FAFC)),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1B9169),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const SizedBox(height: 20),
              _buildFeatureButton(
              context,
              icon: Icons.login,
              text: 'Login',
              page:  LoginScreen(),
              ),
            _buildFeatureButton(
              context,
              icon: Icons.gavel,
              text: 'Traffic Laws',
              page: const TrafficLawScreen(),
            ),
            _buildFeatureButton(
              context,
              icon: Icons.warning,
              text: 'Report Incident',
              page: const IncidentReportScreen(),
            ),
            _buildFeatureButton(
              context,
              icon: Icons.car_repair,
              text: 'Roadside Assistance',
              page: const RoadsideAssistanceScreen(),
            ),
            _buildFeatureButton(
              context,
              icon: Icons.school,
              text: 'Training Tests',
              page: const TrainingTestsScreen(),
            ),
            _buildFeatureButton(
              context,
              icon: Icons.assignment,
              text: 'Exam Tests',
              page: const ExamsScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureButton(BuildContext context, {required IconData icon, required String text, required Widget page}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        },
        icon: Icon(icon, size: 24),
        label: Text(text, style: const TextStyle(fontSize: 18)),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}