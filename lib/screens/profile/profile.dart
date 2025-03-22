import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:road_companion/providers/locale_provider.dart';
import 'package:road_companion/screens/profile/edit_profile.dart';
import 'package:road_companion/screens/profile/about.dart';
import 'package:road_companion/screens/profile/help.dart';
import 'package:road_companion/screens/profile/privacyPolicy.dart';
import 'package:road_companion/screens/profile/ChangePasswordPage.dart';
import 'package:road_companion/services/auth_service.dart';
import 'package:road_companion/screens/authenticate/login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatefulWidget {
  final int selectedIndex;

  const ProfilePage({super.key, this.selectedIndex = 3});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ValueNotifier<String> selectedLanguage = ValueNotifier<String>("Français");
  final ValueNotifier<bool> notificationsEnabled = ValueNotifier<bool>(true);
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // Fetch user data from Firestore
  Future<void> _fetchUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          setState(() {
            _userData = userDoc.data() as Map<String, dynamic>;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error fetching user data: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showLanguageSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "profile.language".tr(),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Divider(),
              _buildLanguageOption("fr"),
              _buildLanguageOption("en"),
              _buildLanguageOption("ar"),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(String langCode) {
    return GestureDetector(
      onTap: () {
        context.setLocale(Locale(langCode));
        setState(() {});
        debugPrint("Langue actuelle: ${context.locale.languageCode}");
        Navigator.pop(context);
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: context.locale.languageCode == langCode
              ? Color(0xFFECFDF3)
              : Color(0xFFF3F5F7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "language_options.$langCode".tr(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: context.locale.languageCode == langCode
                    ? Colors.black
                    : Colors.black54,
              ),
            ),
            if (context.locale.languageCode == langCode)
              Icon(Icons.check, color: Color(0xFF00D47E)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopIcons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Stack(
          children: [
            // Background with Curved Grey Section
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ClipPath(
                clipper: CurvedBackgroundClipper(),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.3,
                  color: Color(0xFFF1F5F9),
                ),
              ),
            ),

            // Content
            Column(
              children: [
                SizedBox(height: 40),
                _buildTopIcons(),
                _buildProfileHeader(),
                _buildSettingsOptions(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(), // Show loading indicator
      );
    }

    if (_userData == null) {
      return Center(
        child: Text("profile.no_user_data".tr()), // Show error message if no data
      );
    }

    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: _userData?['ProfilePhoto'] != null
              ? AssetImage(_userData!['ProfilePhoto']) as ImageProvider
              : null, // No default image
          backgroundColor: _userData?['ProfilePhoto'] == null
              ? Colors.grey[400] // Background color for fallback
              : Colors.transparent, // Transparent if profile photo exists
          child: _userData?['ProfilePhoto'] == null
              ? (_userData?['Name'] != null && _userData!['Name'].isNotEmpty
                  ? Text(
                      _userData!['Name'][0].toUpperCase(), // First letter of the name
                      style: TextStyle(
                        fontSize: 50,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // Text color
                      ),
                    )
                  : Icon(
                      Icons.person, // Fallback icon
                      size: 50,
                      color: Colors.white,
                    ))
              : null, // No child if profile photo exists
        ),
        SizedBox(height: 10),
        Text(
          _userData!['Name'] ?? "profile.no_name".tr(), // Display user name
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 5),
        Text(
          "${_userData!['Email'] ?? "profile.no_email".tr()} | ${_userData!['Phone'] ?? "profile.no_phone".tr()}", // Display email and phone
          style: TextStyle(color: Colors.grey[700]),
        ),
        SizedBox(height: 10),
      ],
    );
  }

  Widget _buildSettingsOptions() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSettingsCard([
            _buildListTile(Icons.edit, "profile.edit".tr(), onTap: () async {
              final bool? isUpdated = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditProfilePage()),
              );

              if (isUpdated == true) {
                // Refresh data instantly when changes are made
                setState(() {
                  _fetchUserData();
                });
              }
            }),
            ValueListenableBuilder<bool>(
              valueListenable: notificationsEnabled,
              builder: (context, isEnabled, child) {
                return _buildListTileWithSwitch(
                  Icons.notifications,
                  "profile.notifications".tr(),
                  isEnabled,
                  onChanged: (value) {
                    notificationsEnabled.value = value;
                  },
                );
              },
            ),
            ValueListenableBuilder<String>(
              valueListenable: selectedLanguage,
              builder: (context, currentLanguage, child) {
                return _buildListTile(Icons.language, "profile.language".tr(), value: "language_options.${context.locale.languageCode}".tr(), onTap: () {
                  _showLanguageSelection(context);
                });
              },
            ),
          ]),

          SizedBox(height: 16),

          _buildSettingsCard([
            _buildListTile(Icons.lock, "profile.security".tr(), onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChangePasswordPage()),
              );
            }),
            _buildListTile(Icons.send, "profile.send_feedback".tr()),
          ]),

          SizedBox(height: 16),

          _buildSettingsCard([
            _buildListTile(Icons.help, "profile.help".tr(), onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HelpCenterPage()),
              );
            }),
            _buildListTile(Icons.info, "profile.about".tr(), onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AboutPage()),
              );
            }),
            _buildListTile(Icons.privacy_tip, "profile.privacy_policy".tr(), onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PrivacyPolicyPage()),
              );
            }),
          ]),

          SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              TextButton.icon(
                onPressed: _logout,
                icon: Icon(Icons.logout, color: Colors.red),
                label: Text("profile.logout".tr(), style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Card(
      color: Color(0xFFF1F5F9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title, {String? value, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: value != null
          ? Text(
              value,
              style: TextStyle(
                color: Colors.green,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            )
          : null,
      onTap: onTap,
      dense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
    );
  }

  Widget _buildListTileWithSwitch(IconData icon, String title, bool value, {required ValueChanged<bool> onChanged}) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.green,
      ),
      dense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
    );
  }

  // ================== LOGOUT FUNCTIONALITY ==================

  Future<void> _logout() async {
    final AuthService _authService = AuthService();

    // Show a confirmation dialog before logging out
    bool confirmLogout = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text("profile.logout_confirmation_title".tr()),
          content: Text("profile.logout_confirmation_message".tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                "profile.logout_cancel".tr(),
                style: TextStyle(color: Color(0xFF0D92F4)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text("profile.logout".tr(), style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmLogout == true) {
      // Log out the user
      await _authService.signOut();

      // Navigate to the LoginScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }
}

// Curved Background Clipper
class CurvedBackgroundClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path path = Path();
    path.lineTo(0, size.height * 0.7);
    path.quadraticBezierTo(
      size.width / 2, size.height * 0.9,
      size.width, size.height * 0.7,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
