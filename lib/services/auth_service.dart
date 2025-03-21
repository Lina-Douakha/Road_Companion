import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:road_companion/screens/authenticate/email_verification_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Add this import

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign in with Email and Password
  Future<String?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await saveLoginState(result.user!); // Save login state after successful login
      return null; // Login successful, return null (no error)
    } on FirebaseAuthException catch (e) {
      return _getErrorMessageSignIn(e.code); // Return readable error message
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    await clearLoginState(); // Clear login state after logout
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Handle Login Errors
  String _getErrorMessageSignIn(String errorCode) {
    switch (errorCode) {
      case "invalid-email":
        return "auth.invalid_email".tr();
      case "user-not-found":
        return "auth.user_not_found".tr();
      case "wrong-password":
        return "auth.wrong_password".tr();
      case "user-disabled":
        return "auth.user_disabled".tr();
      default:
        return "auth.unexpected_error".tr();
    }
  }

  // Google Sign-In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User canceled login

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      await saveLoginState(userCredential.user!); // Save login state after Google sign-in
      return userCredential;
    } catch (e) {
      print("Google Sign-In failed: $e");
      return null;
    }
  }

  // Register User
  Future<String?> registerUser(String email, String password, String name, String phone, String role, BuildContext context) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        // Store user info in Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'UserID': user.uid,
          'Email': email,
          'Name': name,
          'Phone': phone,
          'Role': role, // New field added
        });

        if (!user.emailVerified) {
          await user.sendEmailVerification();
          if (context.mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const EmailVerificationScreen()),
            );
          }
        }
      }

      return null; // Success
    } on FirebaseAuthException catch (e) {
      return _getErrorMessageRegister(e.code);
    }
  }

  // Handle Registration Errors
  String _getErrorMessageRegister(String errorCode) {
    switch (errorCode) {
      case "email-already-in-use":
        return "auth.email_already_in_use".tr();
      case "invalid-email":
        return "auth.invalid_email".tr();
      case "weak-password":
        return "auth.weak_password".tr();
      default:
        return "auth.unexpected_error".tr();
    }
  }

  // ================== NEW METHODS FOR PERSISTENT LOGIN ==================

  // Check if the user is logged in
  Future<bool> isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  // Save login state
  Future<void> saveLoginState(User user) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('uid', user.uid);
  }

  // Clear login state (logout)
  Future<void> clearLoginState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('uid');
  }
}