
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';



//pppppppppppppppppppppppppppppppppppppppppppppppppppp

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  int _currentLight = 0; // 0 = Rouge, 1 = Orange, 2 = Vert
  late Timer _timer;
  int _cycleCount = 0;  // Compte combien de fois la séquence a tourné

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      setState(() {
        _currentLight = (_currentLight + 1) % 3;

        if (_currentLight == 0) {
          _cycleCount++;
        }

        if (_cycleCount == 2) {
          _timer.cancel();
          _goToOnboarding();
        }
      });
    });
  }

  void _goToOnboarding() {
    Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (context) => OnboardingScreen()),
);

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 250,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildLight(0, Colors.red),
                  _buildLight(1, Colors.orange),
                  _buildLight(2, Colors.green),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Road Companion",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLight(int index, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: _currentLight == index ? color : Colors.grey[400],
        shape: BoxShape.circle,
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}

// -------------------- OnboardingScreen --------------------
class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  void goToNextPage() {
    if (_currentPage < 4) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.ease,
      );
    } else {
       Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) =>  LoginScreen()),
    );
    }
  }

  Widget buildOnboardingPage({
    required String imagePath,
    String? text,
    bool showSkip = false,
    bool isLastPage = false,
  }) {
    return Column(
      children: [
        const Spacer(),
        Image.asset(
          'assets/images/$imagePath',
          height: 220,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 10),
        if (text != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              text,
              textAlign: TextAlign.left,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        const SizedBox(height: 50),
        if (!isLastPage)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (showSkip)
                  GestureDetector(
                    onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                    child: const Text(
                      "Skip",
                      style: TextStyle(
                        color: Color(0xFF1B9169),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 60),
                GestureDetector(
                  onTap: goToNextPage,
                  child: Container(
                    width: 65,
                    height: 65,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF00D47E), width: 2),
                    ),
                    child: Center(
                      child: Container(
                        width: 51,
                        height: 57,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF1B9169),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: CustomPaint(
                            painter: ChevronArrowPainter(),
                            child: Container(),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        if (isLastPage) ...[
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) =>  LoginScreen()),
               ),

            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D47E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              minimumSize: const Size(290, 48),
            ),
            child: const Text(
              "Commencer",
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ],
        const Spacer(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: PageView(
        controller: _controller,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        children: [
          buildOnboardingPage(
            imagePath: 'Car_driving_bro.png',
            text: 'Road Companion, ton allié \npour une conduite plus sûre et\nintelligente !',
            showSkip: true,
          ),
          buildOnboardingPage(
            imagePath: 'City_driver_bro.png',
            text: 'Visualise tous les incidents \nsignalés et obtiens des infos \ntrafic en direct.',
          ),
          buildOnboardingPage(
            imagePath: 'City_driver_pana.png',
            text: 'Un GPS intelligent avec \nassistance routière pour des \ntrajets sans stress.',
          ),
          buildOnboardingPage(
            imagePath: 'ORHG1K0_1.png',
            text: 'Cours interactifs, quiz et tests\npour maîtriser le code de la \nroute.',
          ),
          buildOnboardingPage(
            imagePath: 'Car_driving_pana_1.png',
            isLastPage: true,
          ),
        ],
      ),
    );
  }
}

// -------------------- ChevronArrowPainter --------------------
class ChevronArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white..strokeWidth = 3..strokeCap = StrokeCap.round;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final Offset arrowTip = Offset(center.dx + 8, center.dy);
    canvas.drawLine(Offset(arrowTip.dx - 12, arrowTip.dy - 12), arrowTip, paint);
    canvas.drawLine(Offset(arrowTip.dx - 12, arrowTip.dy + 12), arrowTip, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 80), // Espace initial (au lieu de Spacer)

              const Text(
                "Bienvenue à Road Companion",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Se connecter",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B9169),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Veuillez vous connecter avec votre compte\n\n",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 30),

              // Champ Adresse email
              TextField(
                decoration: InputDecoration(
                  labelText: "Adresse email",
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  labelStyle: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black26),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black26),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black54),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Champ Mot de passe
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Mot de passe",
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  labelStyle: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black26),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black26),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black54),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    "Mot de passe oublié ?",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Bouton Se Connecter
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D47E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(48),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    "Se Connecter",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                "Ou connectez-vous avec",
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1B9169),
                ),
              ),
              const SizedBox(height: 12),

              // Bouton Google
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(48),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/images/google_icon.png', height: 24),
                      const SizedBox(width: 8),
                      const Text(
                        "Google",
                        style: TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

             Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    const Text(
      "Vous n'avez pas de compte ? ",
      style: TextStyle(color: Colors.black54),
    ),
    GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RegistrationScreen()),
        );
      },
      child: const Text(
        "Inscrivez-vous",
        style: TextStyle(
          color: Color(0xFF00D47E),
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  ],
),

              const SizedBox(height: 50), 
            ],
          ),
        ),
      ),
    );
  }
}


class RegistrationScreen extends StatefulWidget {
  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {

  bool offerService = true;
  String serviceType = 'Mécanicien';
  bool acceptedTerms = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 50),
            const Center(
              child: Text(
                'Bienvenue à Road Companion',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            const Center(
              child: Text(
                "S'inscrire",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField(label: "Nom d'utilisateur", hint: "Username"),
            _buildTextField(label: "Adresse Email", hint: "Email Address", icon: Icons.email_outlined),
            _buildPhoneField(),
            _buildTextField(label: "Mot de passe", hint: "Password", isPassword: true),
            _buildTextField(label: "Confirmez le mot de passe", hint: "Confirm Password", isPassword: true),
            const SizedBox(height: 10),
            const Text("Offrez-vous un service ?", style: TextStyle(fontWeight: FontWeight.bold)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRadio("Oui", true),
                _buildRadio("Non", false),
              ],
            ),
            if (offerService) ...[
              const SizedBox(height: 10),
              const Text("Quel type de service offrez-vous ?", style: TextStyle(fontWeight: FontWeight.bold)),
              _buildServiceTypeRadio("Mécanicien"),
              _buildServiceTypeRadio("Service de remorquage"),
              _buildServiceTypeRadio("Pièces de rechange"),
              const SizedBox(height: 10),
              const Text("Veuillez ajouter les documents (obligatoires):", style: TextStyle(fontWeight: FontWeight.bold)),
              _buildStaticDocumentField("Carte d’identité (PDF)"),
              _buildStaticDocumentField("Registre de commerce (PDF)"),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Checkbox(
                  value: acceptedTerms,
                  onChanged: (val) {
                    setState(() {
                      acceptedTerms = val ?? false;
                    });
                  },
                  activeColor: Colors.green,
                ),
                Expanded(
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(color: Colors.black),
                      children: [
                        TextSpan(text: "En créant un compte, vous acceptez "),
                        TextSpan(
                          text: "nos conditions générales",
                          style: TextStyle(color: Colors.green, decoration: TextDecoration.underline),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: acceptedTerms ? Colors.green : const Color(0xFFCBD5E1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: acceptedTerms ? () {
                  // Logique d'inscription ici
                } : null,
                child: const Text("Continue", style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({required String label, required String hint, IconData? icon, bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          TextField(
            obscureText: isPassword,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: icon != null ? Icon(icon) : null,
              suffixIcon: isPassword ? const Icon(Icons.visibility_off) : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: const Color.fromARGB(255, 255, 255, 255),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Numéro de téléphone", style: TextStyle(fontWeight: FontWeight.bold)),
          TextField(
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: "+213  Numéro de téléphone",
              filled: true,
              fillColor: const Color.fromARGB(255, 255, 255, 255),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadio(String label, bool value) {
    return Row(
      children: [
        Radio<bool>(
          value: value,
          groupValue: offerService,
          activeColor: Colors.green,
          onChanged: (val) => setState(() => offerService = val!),
        ),
        Text(label),
      ],
    );
  }

  Widget _buildServiceTypeRadio(String type) {
    return Row(
      children: [
        Radio<String>(
          value: type,
          groupValue: serviceType,
          activeColor: Colors.green,
          onChanged: (val) => setState(() => serviceType = val!),
        ),
        Text(type),
      ],
    );
  }

  Widget _buildStaticDocumentField(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            height: 50,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFFCBD5E1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Aucun fichier sélectionné",
                  style: TextStyle(color: Colors.grey),
                ),
                const Icon(Icons.add, color: Colors.grey), // Icône "+" demandée
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LoginFlowLauncher extends StatelessWidget {
  const LoginFlowLauncher({super.key});

  @override
  Widget build(BuildContext context) {
    // Dès qu'on arrive sur cette "page", on démarre la séquence
    Future.delayed(Duration.zero, () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SplashScreen()),
      );
    });

    // Pendant 1 microseconde, on affiche juste un container vide
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()), // Optionnel
    );
  }
}
