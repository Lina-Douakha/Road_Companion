import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:road_companion/services/auth_service.dart';
import 'package:road_companion/screens/home/home.dart';
import 'package:road_companion/screens/roadside_assistance/roadside_assistance_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:road_companion/screens/admin/admin_menu.dart';
import 'onboarding_screen.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Animation controllers
  late AnimationController _lottieController;
  late AnimationController _textController;
  late Animation<double> _nameAnimation;
  late Animation<double> _sloganAnimation;

  @override
  void initState() {
    super.initState();

    // Lottie animation controller
    _lottieController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // Text animation controller
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _nameAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _sloganAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    // Start animations
    _lottieController.forward();
    _textController.forward();

    // Schedule navigation after animations complete
    Future.delayed(const Duration(seconds: 4), () {
      _checkLoginStatus();
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

        if (userRole == 'mechanic' ||
            userRole == 'parts_supplier' ||
            userRole == 'towing_service') {
          // Navigate to service provider home
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => RoadsideAssistanceScreen()),
          );
        } else if (userRole == 'admin') {
          // Navigate to admin dashboard
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AdminDashboardScreen()),
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
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // App Name with animation
                AnimatedBuilder(
                  animation: _nameAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _nameAnimation.value,
                      child: Transform.translate(
                        offset: Offset(0, -30 * (1 - _nameAnimation.value)),
                        child: Text(
                          "ROAD COMPANION",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1B9169),
                            letterSpacing: 1.8,
                            height: 1.2,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),

                // Lottie animation
                SizedBox(
                  height: 240, // Control the size of the animation
                  width: 240,
                  child: Lottie.asset(
                    'assets/animation/map.json',
                    controller: _lottieController,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 40),

                // Slogan with animation
                AnimatedBuilder(
                  animation: _sloganAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _sloganAnimation.value,
                      child: Transform.translate(
                        offset: Offset(0, 30 * (1 - _sloganAnimation.value)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            "Your all-in-one road assistant — from help on the road to passing the code.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black54,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const Spacer(flex: 2),

                // Subtle loading indicator
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      color: const Color(0xFF1B9169).withOpacity(0.7),
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _lottieController.dispose();
    _textController.dispose();
    super.dispose();
  }
}