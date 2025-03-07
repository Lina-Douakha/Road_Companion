import 'package:flutter/material.dart';
import 'login.dart';
import 'package:flutter/services.dart';

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
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }
  void goToLogin() {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => LoginScreen()),
  );
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
        const SizedBox(height: 80),
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
        const SizedBox(height: 30),
        if (!isLastPage)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (showSkip)
                  GestureDetector(
                    onTap: goToLogin,
                    
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
              MaterialPageRoute(builder: (context) => LoginScreen()),
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Color(0xFF1B9169),
          statusBarIconBrightness: Brightness.light,
        ),
    child: Scaffold(
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
            text: 'Visualise tous les incidents \nsignalés et obtiens des informations \ntrafic en direct.',
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
    ),
    );
  }
}

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