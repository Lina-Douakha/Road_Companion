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

class _EmailVerificationScreenState extends State<EmailVerificationScreen> with SingleTickerProviderStateMixin {
  Timer? _timer;
  bool _isResending = false;
  late AnimationController _animationController;
  late Animation<double> _animation;
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _startEmailVerificationCheck();

    // Initialize animation controller for the pulse effect
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _startEmailVerificationCheck() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await FirebaseAuth.instance.currentUser?.reload();
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null && user.emailVerified) {
        timer.cancel(); // Stop the timer
        _animationController.stop();

        // Transfer user data from unverified_users to users collection
        await _transferUserData(user.uid);

        // Show success dialog
        if (mounted) {
          _showVerificationSuccessDialog();
        }
      }
    });
  }

  Future<void> _transferUserData(String userId) async {
    try {
      // Reference to Firestore collections
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final unverifiedUserRef = firestore.collection('unverified_users').doc(userId);
      final userRef = firestore.collection('users').doc(userId);

      // Get the unverified user data
      final unverifiedUserDoc = await unverifiedUserRef.get();

      if (unverifiedUserDoc.exists) {
        // Get the user data from unverified_users collection
        final userData = unverifiedUserDoc.data()!;

        // Add additional fields to userData
        userData['verifiedAt'] = FieldValue.serverTimestamp();
        userData['name'] = widget.name;
        userData['phone'] = widget.phone;
        userData['role'] = widget.role;

        // Create batch for transaction
        final WriteBatch batch = firestore.batch();

        // Add to users collection
        batch.set(userRef, userData);

        // Delete from unverified_users collection
        batch.delete(unverifiedUserRef);

        // Commit the batch
        await batch.commit();

        print('User data transferred successfully from unverified_users to users collection');
      } else {
        print('User document does not exist in unverified_users collection');
      }
    } catch (e) {
      print('Error transferring user data: ${e.toString()}');
      // Handle error silently - we don't want to interrupt the verification process
      // but we log it for debugging purposes
    }
  }

  void _showVerificationSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF00d47e), size: 28),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                "admin.verification_successful".tr(),
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Text("admin.verification_success_message".tr()),
        actions: [
          TextButton(
            onPressed: () {
              // Close the dialog first
              Navigator.of(context).pop();

              // Simply pop this screen to return to UsersManagementScreen
              Navigator.of(context).pop();
            },
            child: Text('OK', style: TextStyle(color: Color(0xFF00d47e))),
          ),
        ],
      ),
    );
  }

  Future<void> _resendVerificationEmail() async {
    if (_isResending) return; // Prevent multiple clicks

    setState(() {
      _isResending = true;
    });

    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text("admin.resent_success".tr())),
              ],
            ),
            backgroundColor: Color(0xFF00d47e),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text("${"admin.error".tr()}: ${e.toString()}")),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the email of the current user
    final String? userEmail = FirebaseAuth.instance.currentUser?.email;

    return ScaffoldMessenger(
      key: _scaffoldKey,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          title: Text(
            "email_verification.title".tr(),
            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.black87),
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      children: [
                        // Top section with animation
                        SizedBox(
                          height: constraints.maxHeight * 0.5,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Animated email icon
                                ScaleTransition(
                                  scale: _animation,
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00d47e).withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.email_outlined,
                                      size: 60, // Reduced from 80
                                      color: Color(0xFF00d47e),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24), // Reduced from 40

                                // Main heading
                                Text(
                                  "admin.check_inbox".tr(),
                                  style: const TextStyle(
                                    fontSize: 22, // Reduced from 24
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),

                                // Email address display
                                if (userEmail != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      userEmail,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                const SizedBox(height: 16), // Reduced from 24

                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Bottom section with actions

                        const SizedBox(height: 24),

                        // Resend button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isResending ? null : _resendVerificationEmail,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00d47e),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _isResending
                                ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text("admin.sending".tr()),
                              ],
                            )
                                : Text(
                              "admin.resend_button".tr(),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),


                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}