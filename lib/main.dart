import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:road_companion/main_screen.dart';
import 'screens/home/home.dart';
import 'package:road_companion/screens/emergency/emergency.dart';
import 'package:road_companion/screens/incident_reporting/incident_report_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const RoadCompanionApp());
}

class RoadCompanionApp extends StatelessWidget {
  const RoadCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Road Companion',
      debugShowCheckedModeBanner: false, // Removes debug banner
      theme: ThemeData(
        primarySwatch: Colors.blue,        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MainScreen(), 
     
    );
  }
}

