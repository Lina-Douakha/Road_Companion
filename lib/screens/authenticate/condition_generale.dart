import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:road_companion/screens/authenticate/registration.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // On récupère les dimensions de l'écran
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: const Color(0xFF1B9169),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // Bande verte en haut
            Container(
              height: screenHeight * 0.04,
              color: const Color(0xFF1B9169),
            ),

            // Titre
            Padding(
              padding: EdgeInsets.only(
                top: screenHeight * 0.03,
                bottom: screenHeight * 0.03,
              ),
              child: Center(
                child: Text(
                  'registrationGeneral.terms_title'.tr(),
                  style: TextStyle(
                    color: const Color(0xFF1B9169),
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth * 0.06,
                  ),
                ),
              ),
            ),

            // Texte déroulant des conditions
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'conditionsgeneral'.tr(),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Bouton Accepter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: SizedBox(
                  width:
                      MediaQuery.of(context).size.width *
                      0.4, // 60% de la largeur de l'écran
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => const RegistrationScreen(
                                acceptedFromTerms: true,
                              ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00d47e),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'registrationGeneral.accept'.tr(),
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}