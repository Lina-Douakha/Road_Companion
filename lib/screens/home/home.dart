import 'package:flutter/material.dart';
import 'package:road_companion/screens/traffic_law/traffic_law_consultation/choisir_categorie.dart'; // Importation de la navbar

void main() {
  runApp(const MaterialApp(home: HomePage()));
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ChoisirCategorie(); // Appel du widget de navigation
  }
}
