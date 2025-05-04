import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:road_companion/screens/authenticate/email_verification_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // User role constants
  static const String userRole = 'user';
  static const String mechanicRole = 'mechanic';
  static const String partsSupplierRole = 'parts_supplier';
  static const String towingServiceRole = 'towing_service';

  Future<String?> signIn(String email, String password) async {
    try {
      // 1. Check if the email exists in the deleted_users collection
      final deletedUserQuery = await _firestore
          .collection('deleted_users')
          .where('Email', isEqualTo: email)
          .get();

      if (deletedUserQuery.docs.isNotEmpty) {
        // User was deleted
        return "Your account has been deleted by the admin.";
      }

      // 2. Check if the email exists in the users collection
      final userQuery = await _firestore
          .collection('users')
          .where('Email', isEqualTo: email)
          .get();

      if (userQuery.docs.isEmpty) {
        // Email not found in users collection
        return "auth.user_not_found".tr();
      }

      final userData = userQuery.docs.first.data();

      // 3. Check if the user is blocked
      if (userData['isBlocked'] == true) {
        return "Your account has been blocked by the admin.";
      }

      // 4. Try signing in with Firebase Auth
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



  Future<void> signOut() async {
    await _auth.signOut();
    await clearLoginState();
  }

  User? get currentUser => _auth.currentUser;
  Future<String?> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        // 1. Check if user was deleted
        final deletedUserQuery = await _firestore
            .collection('deleted_users')
            .where('Email', isEqualTo: user.email)
            .get();

        if (deletedUserQuery.docs.isNotEmpty) {
          await _auth.signOut();
          return "auth.account_deleted".tr();
        }

        // 2. Check if user exists and is blocked
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          if (userData != null && userData['isBlocked'] == true) {
            await _auth.signOut();
            return "auth.account_blocked".tr();
          }
        } else {
          // New user (first Google login)
          await _firestore.collection('users').doc(user.uid).set({
            'UserID': user.uid,
            'Email': user.email,
            'Name': user.displayName ?? 'No Name',
            'Phone': '',
            'Role': 'user',
            'VerifiedAt': FieldValue.serverTimestamp(),
            'isBlocked': false,
          });
        }

        await saveLoginState(user);
      }

      return null; // Success, no error
    } catch (e) {
      print("Google Sign-In failed: $e");
      return "auth.unexpected_error".tr(); // return a general error
    }
  }



  Future<String?> registerUser({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
    required BuildContext context,
    LatLng? location,
    String? address,
  }) async {
    try {
      // 1. Check if the email exists in the deleted_users collection
      final deletedUserQuery = await _firestore
          .collection('deleted_users')
          .where('Email', isEqualTo: email)
          .get();

      if (deletedUserQuery.docs.isNotEmpty) {
        // User was deleted
        return "auth.account_deleted".tr();
      }
// 2. Check if the email exists in the users collection
      final userQuery = await _firestore
          .collection('users')
          .where('Email', isEqualTo: email)
          .get();
       //block
      if (userQuery.docs.isNotEmpty) {
        final userData = userQuery.docs.first.data();
        if (userData['isBlocked'] == true) {
          return "auth.account_blocked".tr();
        }
        // Already registered
        return "auth.email_already_in_use".tr();
      }

      final pendingQuery = await _firestore.collection('unverified_users').where('Email', isEqualTo: email).get();
      if (pendingQuery.docs.isNotEmpty) {
        for (var doc in pendingQuery.docs) {
          await _firestore.collection('unverified_users').doc(doc.id).delete();
        }
        User? existingUser = _auth.currentUser;
        if (existingUser != null && !existingUser.emailVerified) {
          await existingUser.delete();
        }
      }

      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        Map<String, dynamic> userData = {
          'UserID': user.uid,
          'Email': email,
          'Name': name,
          'Phone': phone,
          'Role': role,
          'Location': null,
          'Address': null,
          'CreatedAt': FieldValue.serverTimestamp(),
          'EmailVerified': false,


        };

        if (role != userRole && location != null) {
          userData.addAll({
            'Location': GeoPoint(location.latitude, location.longitude),
            'Address': address ?? '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
          });
        }

        await _firestore.collection('unverified_users').doc(user.uid).set(userData);
        await user.sendEmailVerification();

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
        return null;
      }
    } on FirebaseAuthException catch (e) {
      return _getErrorMessageRegister(e.code);
    }
    return "auth.unknown_error".tr();
  }

  Future<void> moveUserToVerified(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('unverified_users').doc(userId).get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        // Manually extract fields
        String email = userData['Email'];
        String name = userData['Name'];
        String phone = userData['Phone'];
        String role = userData['Role'];
        GeoPoint? location = userData['Location'];
        String? address = userData['Address'];

        Map<String, dynamic> verifiedUserData = {
          'UserID': userId,
          'Email': email,
          'Name': name,
          'Phone': phone,
          'Role': role,
          'CreatedAt': userData['CreatedAt'],
          'EmailVerified': true,
        };

        if (role != AuthService.userRole && location != null && address != null) {
          verifiedUserData['Location'] = location;
          verifiedUserData['Address'] = address;
        }

        await _firestore.collection('users').doc(userId).set(verifiedUserData);
        await _firestore.collection('unverified_users').doc(userId).delete();
      }
    } catch (e) {
      print("Error moving user to verified: $e");
      rethrow;
    }
  }


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

  Future<bool> isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  Future<void> saveLoginState(User user) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('uid', user.uid);
  }

  Future<void> clearLoginState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('uid');
  }


  Future<String?> registerUserAdmin({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
    required BuildContext context,
    LatLng? location,
    String? address,
  }) async {
    try {
      // 1. Check if the email exists in the deleted_users collection
      final deletedUserQuery = await _firestore
          .collection('deleted_users')
          .where('Email', isEqualTo: email)
          .get();

      if (deletedUserQuery.docs.isNotEmpty) {
        return "auth.account_deleted".tr();
      }

      // 2. Check if the email exists in the users collection
      final userQuery = await _firestore
          .collection('users')
          .where('Email', isEqualTo: email)
          .get();

      if (userQuery.docs.isNotEmpty) {
        final userData = userQuery.docs.first.data();
        if (userData['isBlocked'] == true) {
          return "auth.account_blocked".tr();
        }
        return "auth.email_already_in_use".tr();
      }

      // 3. Clean up unverified users if any
      final pendingQuery = await _firestore
          .collection('unverified_users')
          .where('Email', isEqualTo: email)
          .get();

      if (pendingQuery.docs.isNotEmpty) {
        for (var doc in pendingQuery.docs) {
          await _firestore.collection('unverified_users').doc(doc.id).delete();
        }
        User? existingUser = _auth.currentUser;
        if (existingUser != null && !existingUser.emailVerified) {
          await existingUser.delete();
        }
      }

      // 4. Create the user
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        Map<String, dynamic> userData = {
          'UserID': user.uid,
          'Email': email,
          'Name': name,
          'Phone': phone,
          'Role': role,
          'Location': null,
          'Address': null,
          'CreatedAt': FieldValue.serverTimestamp(),
          'EmailVerified': true, // ✅ Mark email as verified immediately
          'VerifiedAt': FieldValue.serverTimestamp(), // ✅ Add VerifiedAt timestamp
          'isBlocked': false, // ✅ Also mark as not blocked by default
        };

        if (role != userRole && location != null) {
          userData.addAll({
            'Location': GeoPoint(location.latitude, location.longitude),
            'Address': address ?? '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
          });
        }

        // Save directly into 'users' collection (not 'unverified_users')
        await _firestore.collection('users').doc(user.uid).set(userData);

        // ✅ No need for email verification screen navigation
        return null;
      }
    } on FirebaseAuthException catch (e) {
      return _getErrorMessageRegister(e.code);
    }
    return "auth.unknown_error".tr();
  }



}