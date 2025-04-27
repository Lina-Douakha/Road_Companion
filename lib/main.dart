import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'screens/home/home.dart';
import 'package:road_companion/screens/authenticate/splash_screen.dart';
import 'package:road_companion/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await EasyLocalization.ensureInitialized(); // Initialiser EasyLocalization
  await NotificationService.instance.initialize(); // Initialize notification service

  runApp(
    EasyLocalization(
      supportedLocales: [
        Locale('fr'), // Français (par défaut)
        Locale('en'), // Anglais
        Locale('ar'), // Arabe
      ],
      path: 'assets/lang', // Dossier où sont stockés les fichiers JSON
      fallbackLocale: Locale('fr'), // Langue par défaut
      startLocale: Locale('fr'), // Forcer le français au démarrage
      child: const RoadCompanionApp(),
    ),
  );
}

class RoadCompanionApp extends StatefulWidget {
  const RoadCompanionApp({super.key});

  @override
  State<RoadCompanionApp> createState() => _RoadCompanionAppState();
}

class _RoadCompanionAppState extends State<RoadCompanionApp> {
  @override
  void dispose() {
    // Clean up notification service resources when app is terminated
    NotificationService.instance.dispose();
    super.dispose();  // This is now valid because State has dispose()
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Road Companion',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Color(0xFF1B9169),
            statusBarIconBrightness: Brightness.light,
          ),
        ),
      ),
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      home: SplashScreen(),
      routes: {
        '/login': (context) => SplashScreen(),
        '/home': (context) => HomePage(),
      },
    );
  }
}

