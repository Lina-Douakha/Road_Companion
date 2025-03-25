import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:road_companion/screens/authenticate/email_verification_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';// Add this import
import 'package:firebase_core/firebase_core.dart';





class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<String?> signIn(String email, String password) async {
    try {
      // Check if the email exists in Firestore
      final userQuery = await _firestore.collection('users').where('Email', isEqualTo: email).get();

      if (userQuery.docs.isEmpty) {
        // Email not found in database
        return "auth.user_not_found".tr();
      }

      // Try signing in with Firebase Auth
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return null; // Login successful
    } on FirebaseAuthException catch (e) {

      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return "auth.wrong_password".tr();
      } else if (e.code == 'invalid-email') {
        return "auth.invalid_email".tr();
      } else if (e.code == 'too-many-requests') {
        return "login.error_too_many_attempts".tr();
      } else {
        return "auth.unexpected_error".tr();
      }
    }
  }





  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    await clearLoginState(); // Clear login state after logout
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

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
        User? user = userCredential.user;

        if (user != null) {
          // Check if the user already has a Firestore document
          final userDoc = await _firestore.collection('users').doc(user.uid).get();

          if (!userDoc.exists) {
            // Create a new Firestore document for the user
            await _firestore.collection('users').doc(user.uid).set({
              'UserID': user.uid,
              'Email': user.email,
              'Name': user.displayName ?? 'No Name',
              'Phone': '', // Default empty phone number
              'Role': 'User', // Default role
            });

            print("New user profile created in Firestore for Google sign-in.");
          } else {
            print("User profile already exists in Firestore.");
          }

          await saveLoginState(user); // Save login state after Google sign-in
        }

        return userCredential;
      } catch (e) {
        print("Google Sign-In failed: $e");
        return null;
      }
    }

    // regiter a user
  Future<String?> registerUser(
      String email,
      String password,
      String name,
      String phone,
      String role,
      BuildContext context) async {
    try {
      // Step 1: Check if the email exists in 'users' (already verified users)
      final userQuery = await _firestore.collection('users').where('Email', isEqualTo: email).get();
      if (userQuery.docs.isNotEmpty) {
        return "auth.email_already_in_use".tr();
      }

      // Step 2: Check if the email exists in 'unverified_users'
      final pendingQuery = await _firestore.collection('unverified_users').where('Email', isEqualTo: email).get();
      if (pendingQuery.docs.isNotEmpty) {
        // Delete the unverified user from Firestore
        for (var doc in pendingQuery.docs) {
          await _firestore.collection('unverified_users').doc(doc.id).delete();
        }

        // Delete the unverified user from FirebaseAuth
        User? existingUser = FirebaseAuth.instance.currentUser;
        if (existingUser != null && !existingUser.emailVerified) {
          await existingUser.delete();
        }
      }

      // Step 3: Register the user in FirebaseAuth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        // Step 4: Store the user in 'unverified_users' (waiting for email verification)
        await _firestore.collection('unverified_users').doc(user.uid).set({
          'Email': email,
          'Name': name,
          'Phone': phone,
          'Role': role,
          'CreatedAt': FieldValue.serverTimestamp(),
        });

        // Step 5: Send email verification
        await user.sendEmailVerification();

        // Redirect to verification screen
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => EmailVerificationScreen(
                name: name,
                phone: phone,
                role: role,
              ),
            ),
          );
        }

        return null; // Successfully registered, waiting for verification
      }
    } on FirebaseAuthException catch (e) {
      return _getErrorMessageRegister(e.code);
    }
    return "auth.unknown_error".tr(); // Unknown error
  }

  Future<void> moveUserToVerified(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('unverified_users').doc(userId).get();
      if (userDoc.exists) {
        // Move to 'users' collection
        await _firestore.collection('users').doc(userId).set(userDoc.data() as Map<String, dynamic>);

        // Remove from 'unverified_users'
        await _firestore.collection('unverified_users').doc(userId).delete();
      }
    } catch (e) {
      print("Error moving user to verified: $e");
    }
  }

  // Handle Registration Errors
  String _getErrorMessageRegister(String errorCode) {
    switch (errorCode) {

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