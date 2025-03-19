import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'screens/home/home.dart';
import 'package:road_companion/screens/authenticate/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await EasyLocalization.ensureInitialized(); // Initialiser EasyLocalization

  runApp(
    EasyLocalization(
      supportedLocales: [
        Locale('fr'), // Français (par défaut)
        Locale('en'), // Anglais
        Locale('ar'), // Arabe
      ],
      path: 'assets/lang', // Dossier où sont stockés les fichiers JSON
      fallbackLocale: Locale('fr'), // Langue par défaut
      startLocale: Locale('fr'), // 🔹 Forcer le français au démarrage
      child: const RoadCompanionApp(),
    ),
  );
}

class RoadCompanionApp extends StatelessWidget {
  const RoadCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Road Companion',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      locale: context.locale, // Utilise la langue sélectionnée
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      home: SplashScreen(), // Démarrer avec l'écran de chargement
      routes: {
        '/login': (context) => SplashScreen(),
        '/home': (context) => HomePage(),
      },
    );
  }
}

