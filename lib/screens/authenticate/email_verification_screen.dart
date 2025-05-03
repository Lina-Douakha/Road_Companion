import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:road_companion/screens/home/home.dart';
import 'package:road_companion/screens/roadside_assistance/roadside_assistance_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String name;
  final String phone;
  final String role;

  const EmailVerificationScreen({Key? key, required this.name, required this.phone, required this.role}) : super(key: key);

  @override
  _EmailVerificationScreenState createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startEmailVerificationCheck();
  }

  void _startEmailVerificationCheck() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await FirebaseAuth.instance.currentUser?.reload();
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null && user.emailVerified) {
        timer.cancel(); // Stop the timer

        // Step 1: Check if the user exists in 'unverified_users'
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('unverified_users').doc(user.uid).get();

        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

          // Step 2: Move user data to 'users' collection
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'UserID': user.uid,
            'Email': user.email,
            'Name': userData['Name'], // Retrieve from unverified_users
            'Phone': userData['Phone'],
            'Role': userData['Role'],
            'Location': userData['Location'],
            'Address': userData['Address'],
            'isBlocked': false,
            'VerifiedAt': FieldValue.serverTimestamp(), // Add verification timestamp
          });

          // Step 3: Remove from 'unverified_users'
          await FirebaseFirestore.instance.collection('unverified_users').doc(user.uid).delete();

          // Step 4: Navigate based on role
          if (mounted) {
            _navigateBasedOnRole(userData['Role'] ?? widget.role);
          }
        }
      }
    });
  }

  void _navigateBasedOnRole(String role) {
    if (role == 'mechanic' || role == 'parts_supplier' || role == 'towing_service') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => RoadsideAssistanceScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    }
  }

  Future<void> _resendVerificationEmail() async {
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("email_verification.description".tr()), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${"email_verification.error".tr()}: ${e.toString()}"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.email, size: 80, color: Color(0xFF00d47e)),
              const SizedBox(height: 20),
              Text(
                "email_verification.title".tr(),
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                "email_verification.resent_success".tr(),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _resendVerificationEmail,
                style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00d47e)),
                child: Text("email_verification.resend_button".tr(), style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}