import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:road_companion/screens/authenticate/login.dart';
import 'package:road_companion/services/auth_service.dart';
import 'package:road_companion/screens/authenticate/splash_screen.dart';
import 'package:road_companion/screens/profile/terms_condition_page.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  void _showDeleteConfirmation(BuildContext context) {
    TextEditingController passwordController = TextEditingController();
    bool isLoading = false;
    String? errorMessage; // To store error messages

    final user = FirebaseAuth.instance.currentUser;
    final isGoogleUser =
        user?.providerData.any(
          (userInfo) => userInfo.providerId == 'google.com',
        ) ??
        false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows keyboard to push UI up
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom:
                    MediaQuery.of(context).viewInsets.bottom +
                    16, // Adjust for keyboard
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "privacy.delete_confirmation_title".tr(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "privacy.delete_confirmation_message".tr(),
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Password Input (only for email/password users)
                  if (!isGoogleUser)
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      cursorColor: Colors.black,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        labelText: "privacy.enter_password".tr(),
                        labelStyle: const TextStyle(color: Colors.black),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.black),
                        ),
                      ),
                      selectionControls: MaterialTextSelectionControls(),
                    ),

                  // Display error message if any
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed:
                        isLoading
                            ? null
                            : () async {
                              setState(() {
                                isLoading = true;
                                errorMessage = null; // Reset error message
                              });
                              bool success = await _deleteAccount(
                                context,
                                isGoogleUser ? null : passwordController.text,
                              );
                              setState(() => isLoading = false);

                              if (!success) {
                                setState(() {
                                  errorMessage =
                                      isGoogleUser
                                          ? "privacy.delete_error".tr()
                                          : "privacy.wrong_password"
                                              .tr(); // Set error message
                                });
                              } else {
                                Navigator.pop(
                                  context,
                                ); // Close modal only if successful
                              }
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF44336),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child:
                        isLoading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : Text(
                              "privacy.delete_account".tr(),
                              style: const TextStyle(color: Colors.white),
                            ),
                  ),

                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "privacy.cancel".tr(),
                      style: const TextStyle(
                        color: Color(0xFF00D47E),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Function to Delete Account (Handles Wrong Password & Logout)
  Future<bool> _deleteAccount(BuildContext context, String? password) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("privacy.no_user_found".tr()),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    try {
      final AuthService _authService =
          AuthService(); // Create an instance of AuthService

      // Check if the user signed in with Google
      final isGoogleUser = user.providerData.any(
        (userInfo) => userInfo.providerId == 'google.com',
      );

      if (isGoogleUser) {
        // Skip password verification for Google users
        debugPrint(
          "User signed in with Google. Skipping password verification.",
        );
      } else {
        // For email/password users, re-authenticate with the provided password
        if (password == null || password.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("privacy.password_required".tr()),
              backgroundColor: Colors.red,
            ),
          );
          return false;
        }

        final AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
        debugPrint("User re-authenticated!");
      }

      // Step 2: Delete from Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .delete();
      debugPrint("User deleted from Firestore!");

      // Step 3: Delete from Firebase Authentication
      await user.delete();
      debugPrint("User deleted from Firebase Auth!");

      // Step 4: Force sign out
      await _authService.signOut();

      FirebaseAuth.instance.signOut().then((_) {
        debugPrint("User signed out!");
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => SplashScreen()),
          (route) => false, // This clears all previous routes
        );
      });

      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint("Error deleting account: ${e.code}");

      String errorMessage = "privacy.delete_error".tr();
      if (e.code == 'wrong-password') {
        errorMessage = "privacy.wrong_password".tr();
      } else if (e.code == 'requires-recent-login') {
        errorMessage = "privacy.reauthenticate".tr();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );

      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCustomHeader(context),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                _buildOptionTile(
                  icon: Icons.article,
                  text: "privacy.terms_and_conditions".tr(),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TermsConditionsPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _buildOptionTile(
                  icon: Icons.person_remove,
                  text: "privacy.delete_account".tr(),
                  onTap: () => _showDeleteConfirmation(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Custom Header (Back Button + Title)
  Widget _buildCustomHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 70.0,
        left: 16.0,
        right: 16.0,
        bottom: 20.0,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: Color(0xFF1B9169),
                size: 24,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Text(
            "privacy.title".tr(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B9169),
            ),
          ),
        ],
      ),
    );
  }

  /// Option Tiles (Terms & Delete Account)
  Widget _buildOptionTile({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF00D47E), size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}