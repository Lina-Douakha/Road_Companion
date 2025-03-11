import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, 
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCustomHeader(context), 
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Road Companion est une application interactive et automatisée conçue pour améliorer la sécurité routière en Algérie. "
                    "Face à l’un des taux d’accidents les plus élevés en Afrique du Nord, cette application répond aux défis liés au manque de sensibilisation "
                    "au code de la route, à la signalisation insuffisante des incidents et à l’accès limité à une assistance routière en temps réel.\n\n"
                    "Road Companion aide les conducteurs en fournissant des outils intelligents pour une conduite plus sûre et plus responsable.",
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  
  Widget _buildCustomHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 70.0, left: 16.0, right: 16.0, bottom: 20.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
        
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color:  const Color(0xFF1b9169), size: 24),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          // Titre centré
          const Text(
            "À propos de",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B9169),
            ),
          ),
        ],
      ),
    );
  }
}
