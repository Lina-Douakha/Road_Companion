import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/home/home.dart';
import 'package:road_companion/screens/authenticate/splash_screen.dart';

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
      debugShowCheckedModeBanner: false,   // Removes debug banner
      title: 'Road Companion',
      theme: ThemeData(
        primarySwatch: Colors.green,        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
    initialRoute: '/login', // Set your initial route to login
    routes: {
      '/login': (context) => SplashScreen(), // Login route
      '/home': (context) => HomePage(), // Home route to navigate to
      //home: SplashScreen(), //test the existing screens
      //home: HomePage(),
    }
    );
  }
}

