import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

void main() {
  runApp(DemandeAideApp());
}

class DemandeAideApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DemandeAideScreen(),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
    );
  }
}

class DemandeAideScreen extends StatefulWidget {
  @override
  _DemandeAideScreenState createState() => _DemandeAideScreenState();
}

class _DemandeAideScreenState extends State<DemandeAideScreen> {
  bool _isRejectedButtonPressed = false;
  bool _isAcceptedButtonPressed = false;

  void _onRejectedButtonTap() {
    setState(() => _isRejectedButtonPressed = true);
    Future.delayed(Duration(milliseconds: 200), () {
      setState(() => _isRejectedButtonPressed = false);
    });
    print("Rejeté");
  }

  void _onAcceptedButtonTap() {
    setState(() => _isAcceptedButtonPressed = true);
    Future.delayed(Duration(milliseconds: 200), () {
      setState(() => _isAcceptedButtonPressed = false);
    });
    print("Accepté");
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            height: screenHeight * 0.04, // Barre supérieure ajustée en hauteur
            color: Color(0xFF1B9169),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "demande_aide.titre".tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: screenWidth * 0.07, // Adaptation du texte
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B9169),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.05),

                  // Image de profil ajustée
                  CircleAvatar(
                    radius:
                        screenWidth *
                        0.14, // Ajusté selon la largeur de l'écran
                    backgroundImage: AssetImage('assets/images/profil_pic.png'),
                  ),
                  SizedBox(height: screenHeight * 0.02),

                  Text(
                    "demande_aide.nom_utilisateur".tr(),
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.005),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.grey,
                        size: screenWidth * 0.035,
                      ),
                      SizedBox(width: screenWidth * 0.01),
                      Text(
                        "demande_aide.localisation".tr(),
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: screenWidth * 0.035,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.05),

                  // ✅ Boutons Responsive
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Bouton "Rejeté"
                      Flexible(
                        child: GestureDetector(
                          onTap: _onRejectedButtonTap,
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 200),
                            padding: EdgeInsets.symmetric(
                              vertical: screenHeight * 0.014,
                              horizontal: screenWidth * 0.07,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  _isRejectedButtonPressed
                                      ? Color(0xFF94A3B8).withOpacity(0.3)
                                      : Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                "demande_aide.bouton_rejete".tr(),
                                style: TextStyle(
                                  fontSize: screenWidth * 0.04,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      _isRejectedButtonPressed
                                          ? Colors.white
                                          : const Color(0xFFCBD5E1),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.05),

                      // Bouton "Accepté"
                      Flexible(
                        child: GestureDetector(
                          onTap: _onAcceptedButtonTap,
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 200),
                            padding: EdgeInsets.symmetric(
                              vertical: screenHeight * 0.014,
                              horizontal: screenWidth * 0.07,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  _isAcceptedButtonPressed
                                      ? Color(0xFFD1FADF).withOpacity(0.7)
                                      : Color(0xFF00D47E),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Center(
                              child: Text(
                                "demande_aide.bouton_accepte".tr(),
                                style: TextStyle(
                                  fontSize: screenWidth * 0.04,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: screenHeight * 0.03),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}