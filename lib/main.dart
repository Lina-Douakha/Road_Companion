import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
//import 'screens/home/home.dart'; //appel dans le cas d'afficher le navbar
import 'package:road_companion/screens/authenticate/splash_screen.dart';
// import 'package:road_companion/screens/traffic_law/traffic_law_consultation/choisir_categorie.dart';
//import 'package:road_companion/screens/traffic_law/traffic_law_consultation/priorité_passage.dart';

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
            Colors.white, // ✅ Fond blanc par défaut pour tous les Scaffold
      ),
      //home: ChoisirCategorie(),
      home: SplashScreen(),
      //home: HomePage(), //test the existing screens
      //home: PriorityQuestionScreen(),
    );
  }
}
