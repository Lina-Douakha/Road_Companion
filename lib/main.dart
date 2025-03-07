import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/home/home.dart';
import 'package:road_companion/screens/authenticate/splash_screen.dart';
import 'package:road_companion/screens/traffic_law/exams/exams_screen.dart';

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
      debugShowCheckedModeBanner: false,
      title: 'Road Companion',
      theme: ThemeData(
        scaffoldBackgroundColor:
            Colors.white, // Fond blanc par défaut pour tous les Scaffold
      ),
      //home: SplashScreen(),  // test the auth feature
      home: HomePage(), // test the app features
      //home: ExamsScreen(),  // test the exam screen
    );
  }
}
