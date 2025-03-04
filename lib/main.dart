import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/home/home.dart';
//import 'package:road_companion/screens/authenticate/splash_screen.dart';

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
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomePage(), //test the existing screens
    );
  }
}
