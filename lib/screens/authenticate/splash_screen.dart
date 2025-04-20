import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'onboarding_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:road_companion/services/auth_service.dart';
import 'package:road_companion/screens/home/home.dart';
import 'package:road_companion/screens/roadside_assistance/roadside_assistance_screen.dart';
import 'package:road_companion/screens/authenticate/login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  int _currentLight = 0;
  late Timer _timer;
  int _cycleCount = 0;
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

        if (_cycleCount == 1) {
          _timer.cancel();
          _checkLoginStatus();
        }
      });
    });
  }

  Future<String?> _getUserRole(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return userDoc.get('Role');
      }
      return null;
    } catch (e) {
      print("Error getting user role: $e");
      return null;
    }
  }

  Future<void> _checkLoginStatus() async {
    bool isLoggedIn = await _authService.isLoggedIn();

    if (isLoggedIn) {
      User? user = _authService.currentUser;
      if (user != null) {
        String? userRole = await _getUserRole(user.uid);

        if (userRole == 'mechanic'||
            userRole == 'parts_supplier' ||
            userRole == 'towing_service') {
          // Navigate to service provider home
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => RoadsideAssistanceScreen()),
          );
        } else {
          // Navigate to regular user home
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
          );
        }
      } else {
        // User is null, go to onboarding
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => OnboardingScreen()),
        );
      }
    } else {
      // Not logged in, go to onboarding
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => OnboardingScreen()),
      );
    }
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
              Text(
                "splash.app_name".tr(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
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