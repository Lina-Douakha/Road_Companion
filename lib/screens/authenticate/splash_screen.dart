import 'package:flutter/material.dart';
import 'dart:async';
import 'onboarding_screen.dart'; // Import the OnboardingScreen

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