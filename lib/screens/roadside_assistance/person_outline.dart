import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:road_companion/screens/roadside_assistance/edit_profile_screen.dart';
import 'package:road_companion/screens/profile/about.dart';
import 'package:road_companion/screens/profile/help.dart';
import 'package:road_companion/screens/profile/privacyPolicy.dart';
import 'package:road_companion/screens/profile/ChangePasswordPage.dart';
import 'package:road_companion/services/auth_service.dart';
import 'package:road_companion/screens/authenticate/login.dart';

class PersonOutlineScreen extends StatefulWidget {
  @override
  _PersonOutlineScreenState createState() => _PersonOutlineScreenState();
}

class _PersonOutlineScreenState extends State<PersonOutlineScreen> {
  String localisation = "";
  String phoneNumber = "";
  String workingHours = "";
  String facebookPage = "";
  String? _profilePhoto;
  String? _userName;
  String? _userEmail;
  final ValueNotifier<String> selectedLanguage = ValueNotifier<String>("Français");
  final ValueNotifier<bool> notificationsEnabled = ValueNotifier<bool>(true);
  bool _isLoading = true;

  String _formatWilaya(String wilayaNumber) {
    if (wilayaNumber.isEmpty) {
      return "edit_profile_mecanic.Not_specified".tr();
    }

    try {
      // If already formatted, return as is
      if (wilayaNumber.contains("-")) {
        return wilayaNumber;
      }

      // Format with translation
      return "$wilayaNumber - ${"wilayas.$wilayaNumber".tr()}";
    } catch (e) {
      print("Error formatting wilaya: $e");
      return wilayaNumber;
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
  }

  Future<void> _fetchCurrentUser() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          _userEmail = user.email;
        });

        // Fetch user data
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _userName = userData['Name'] ?? "Nom non défini".tr();
            phoneNumber = userData['Phone'] ?? "Non spécifié".tr();
            localisation = _formatWilaya(userData['Location'] ?? "");
            _profilePhoto = userData['ProfilePhoto'];
            workingHours = _formatWorkingHours(userData['Working_hours'] ?? "");
            facebookPage = userData['Link'] ?? "Non spécifiée".tr();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error fetching user data: $e");
      setState(() {
        _userName = "Erreur de chargement".tr();
        phoneNumber = "Erreur de chargement".tr();
        localisation = "Erreur de chargement".tr();
        workingHours = "Erreur de chargement".tr();
        facebookPage = "Erreur de chargement".tr();
        _isLoading = false;
      });
    }
  }

  Future<void> _launchURL(String url) async {
    if (url.isEmpty) return;

    try {
      if (!url.startsWith("http://") && !url.startsWith("https://")) {
        url = "https://$url";
      }

      final Uri uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw 'Impossible d\'ouvrir $url';
      }
    } catch (e) {
      print("Error launching URL: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de l'ouverture du lien".tr()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatWorkingHours(String workingHours) {
    if (workingHours.isEmpty) {
      return "Non spécifiés".tr();
    }

    try {
      List<String> parts = workingHours.split("|");
      if (parts.length >= 3) {
        String days = parts[0].trim();
        String startTime = parts[1].trim();
        String endTime = parts[2].trim();


        List<String> dayNumbers = days.split("  ");
        List<String> translatedDays = dayNumbers.map((day) {
          return "days.$day".tr();
        }).toList();

        return "${translatedDays.join(", ")}\n${"De".tr()} $startTime ${"à".tr()} $endTime";
      }
      return workingHours;
    } catch (e) {
      print("Error formatting working hours: $e");
      return workingHours;
    }
  }
  void _showLanguageSelection(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 400;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(isSmallScreen ? 16 : 20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "profile.language".tr(),
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: isSmallScreen ? 20 : 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Divider(),
              _buildLanguageOption("fr", isSmallScreen),
              _buildLanguageOption("en", isSmallScreen),
              _buildLanguageOption("ar", isSmallScreen),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(String langCode, bool isSmallScreen) {
    return GestureDetector(
      onTap: () {
        context.setLocale(Locale(langCode));
        setState(() {});
        debugPrint("Langue actuelle: ${context.locale.languageCode}");
        Navigator.pop(context);
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: isSmallScreen ? 10 : 12,
          horizontal: isSmallScreen ? 12 : 16,
        ),
        margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 10),
        decoration: BoxDecoration(
          color: context.locale.languageCode == langCode
              ? Color(0xFFECFDF3)
              : Color(0xFFF3F5F7),
          borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
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
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.w500,
                color: context.locale.languageCode == langCode
                    ? Colors.black
                    : Colors.black54,
              ),
            ),
            if (context.locale.languageCode == langCode)
              Icon(Icons.check, color: Color(0xFF00D47E), size: isSmallScreen ? 18 : 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTopIcons() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width < 400 ? 12 : 16,
        vertical: 16
      ),
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

  Future<void> _logout() async {
    final AuthService _authService = AuthService();

    bool confirmLogout = await showDialog(
      context: context,
      builder: (context) {
        final isSmallScreen = MediaQuery.of(context).size.width < 400;

        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            "profile.logout_confirmation_title".tr(),
            style: TextStyle(fontSize: isSmallScreen ? 16 : 18),
          ),
          content: Text(
            "profile.logout_confirmation_message".tr(),
            style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                "profile.logout_cancel".tr(),
                style: TextStyle(
                  color: Color(0xFF0D92F4),
                  fontSize: isSmallScreen ? 14 : 16,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                "profile.logout".tr(),
                style: TextStyle(
                  color: Colors.red,
                  fontSize: isSmallScreen ? 14 : 16,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmLogout == true) {
      await _authService.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 350;
    final avatarRadius = isSmallScreen ? 40.0 : 50.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Stack(
          children: [
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

            Column(
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top + (isSmallScreen ? 3 : 7)),
                _buildTopIcons(),
                _buildProfileHeader(isSmallScreen),
                _buildContactInfoCard(isSmallScreen),
                _buildSettingsOptions(isSmallScreen),
              ],
            ),
          ],
        ),
      ),
    );
  }
Widget _buildProfileHeader(bool isSmallScreen) {
  final avatarRadius = isSmallScreen ? 40.0 : 50.0;
  if (_isLoading) {
    return Center(
      child: CircularProgressIndicator(),
    );
  }

  return Column(
    children: [
      CircleAvatar(
        radius: isSmallScreen ? 40 : 50,
        backgroundColor: Colors.grey[400],
        backgroundImage: _profilePhoto != null
            ? AssetImage(_profilePhoto!) as ImageProvider
            : null,
        child: _profilePhoto == null
            ? (_userName != null && _userName!.isNotEmpty
                ? Text(
                    _userName![0].toUpperCase(),
                    style: TextStyle(
                      fontSize: avatarRadius * 0.8,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    Icons.person,
                    size: avatarRadius * 0.8,
                    color: Colors.white,
                  ))
            : null,
      ),
      SizedBox(height: isSmallScreen ? 8 : 10),
      Text(
        _userName ?? "",
        style: TextStyle(
          fontSize: isSmallScreen ? 18 : 20,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      SizedBox(height: isSmallScreen ? 4 : 5),
      // Modification ici pour afficher email et téléphone sur la même ligne
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _userEmail ?? "",
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: isSmallScreen ? 14 : 16,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              "|",
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: isSmallScreen ? 14 : 16,
              ),
            ),
          ),
          Text(
            phoneNumber,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: isSmallScreen ? 14 : 16,
            ),
          ),
        ],
      ),
      SizedBox(height: isSmallScreen ? 16 : 24),
    ],
  );
}
Widget _buildContactInfoCard(bool isSmallScreen) {
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 12),
    child: Card(
      elevation: 0,
      color: Color(0xFFF5F7FA),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200, width: 0.5),
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Column(
          children: [
            // Wilaya Information - made more compact
            _buildCompactInfoRow(
              icon: Icons.location_on_outlined,
              title: "edit_profile_mecanic.Wilaya".tr(),
              value: _formatWilaya(localisation),
              isSmallScreen: isSmallScreen,
              iconColor: Colors.blue.shade600,
            ),

            Divider(height: 16, color: Colors.grey.shade200, thickness: 0.5),

            // Working Hours Information - made more compact
            _buildWorkingHoursInfo(isSmallScreen),

            if (facebookPage.isNotEmpty) ...[
              Divider(height: 16, color: Colors.grey.shade200, thickness: 0.5),

              // Compact Facebook Link
              InkWell(
                onTap: () => _launchURL(facebookPage),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.facebook,
                        size: 20,
                        color: Colors.blue.shade700),
                      SizedBox(width: 8),
                      Text(
                        "edit_profile_mecanic.Link".tr(),
                        style: TextStyle(
                          fontSize: isSmallScreen ? 15 : 16,
                          color: Colors.blue.shade700,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

// Compact version of info row
Widget _buildCompactInfoRow({
  required IconData icon,
  required String title,
  required String value,
  required bool isSmallScreen,
  Color? iconColor,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: isSmallScreen ? 20 : 24, color: iconColor),
      SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 15,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: isSmallScreen ? 15 : 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

Widget _buildInfoRow({
  required IconData icon,
  required String title,
  required String value,
  required bool isSmallScreen,
  Color iconColor = Colors.black54,
  bool isLink = false,
  VoidCallback? onTap,
}) {
  return InkWell(
    onTap: onTap,
    child: Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: isSmallScreen ? 20 : 24, color: iconColor),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 15,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value.isNotEmpty ? value : "edit_profile_mecanic.Not_specified".tr(),
                  style: TextStyle(
                    fontSize: isSmallScreen ? 15 : 16,
                    color: isLink ? Colors.blue : Colors.black87,
                    fontWeight: isLink ? FontWeight.w500 : FontWeight.normal,
                    decoration: isLink ? TextDecoration.underline : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildWorkingHoursInfo(bool isSmallScreen) {
  if (workingHours.isEmpty) {
    return _buildInfoRow(
      icon: Icons.access_time_outlined,
      title: "edit_profile_mecanic.working_hours".tr(),
      value: "edit_profile_mecanic.Not_specified".tr(),
      isSmallScreen: isSmallScreen,
      iconColor: Colors.orange.shade700,
    );
  }

  // Parse working hours if available
  List<String> parts = workingHours.split("|");
  String days = parts.length > 0 ? parts[0] : "";
  String startTime = parts.length > 1 ? parts[1] : "";
  String endTime = parts.length > 2 ? parts[2] : "";

  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(Icons.access_time_outlined,
          size: isSmallScreen ? 20 : 24,
          color: Colors.orange.shade700),
      SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "edit_profile_mecanic.working_hours".tr(),
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 15,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 4),
            if (days.isNotEmpty)
              Text(
                _formatDays(days),
                style: TextStyle(
                  fontSize: isSmallScreen ? 15 : 16,
                  color: Colors.black87,
                ),
              ),
            if (startTime.isNotEmpty && endTime.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  "${"De".tr()} $startTime ${"à".tr()} $endTime",
                  style: TextStyle(
                    fontSize: isSmallScreen ? 15 : 16,
                    color: Colors.black87,
                  ),
                ),
              ),
          ],
        ),
      ),
    ],
  );
}

String _formatDays(String daysString) {
  List<String> dayNumbers = daysString.trim().split("  ");
  return dayNumbers.map((day) => "days.$day".tr()).join(", ");
}



  Widget _buildSettingsOptions(bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      child: Column(
        children: [
          _buildSettingsCard([
            _buildListTile(
              Icons.edit,
              "profile.edit".tr(),
              isSmallScreen,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfileScreen(
                      localisation: localisation,
                      phoneNumber: phoneNumber,
                      workingHours: workingHours,
                      facebookPage: facebookPage,
                    ),
                  ),
                ).then((_) {
                  _fetchCurrentUser();
                });
              },
            ),
            ValueListenableBuilder<bool>(
              valueListenable: notificationsEnabled,
              builder: (context, isEnabled, child) {
                return _buildListTileWithSwitch(
                  Icons.notifications,
                  "profile.notifications".tr(),
                  isEnabled,
                  isSmallScreen,
                  onChanged: (value) {
                    notificationsEnabled.value = value;
                  },
                );
              },
            ),
            ValueListenableBuilder<String>(
              valueListenable: selectedLanguage,
              builder: (context, currentLanguage, child) {
                return _buildListTile(
                  Icons.language,
                  "profile.language".tr(),
                  isSmallScreen,
                  value: "language_options.${context.locale.languageCode}".tr(),
                  onTap: () {
                    _showLanguageSelection(context);
                  },
                );
              },
            ),
          ], isSmallScreen),

          SizedBox(height: isSmallScreen ? 12 : 16),

          _buildSettingsCard([
            _buildListTile(
              Icons.lock,
              "profile.security".tr(),
              isSmallScreen,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChangePasswordPage()),
                );
              },
            ),
            _buildListTile(
              Icons.send,
              "profile.send_feedback".tr(),
              isSmallScreen
            ),
          ], isSmallScreen),

          SizedBox(height: isSmallScreen ? 12 : 16),

          _buildSettingsCard([
            _buildListTile(
              Icons.help,
              "profile.help".tr(),
              isSmallScreen,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HelpCenterPage()),
                );
              },
            ),
            _buildListTile(
              Icons.info,
              "profile.about".tr(),
              isSmallScreen,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AboutPage()),
                );
              },
            ),
            _buildListTile(
              Icons.privacy_tip,
              "profile.privacy_policy".tr(),
              isSmallScreen,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PrivacyPolicyPage()),
                );
              },
            ),
          ], isSmallScreen),

          SizedBox(height: isSmallScreen ? 12 : 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              TextButton.icon(
                onPressed: _logout,
                icon: Icon(
                  Icons.logout,
                  color: Colors.red,
                  size: isSmallScreen ? 18 : 20,
                ),
                label: Text(
                  "profile.logout".tr(),
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: isSmallScreen ? 14 : 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children, bool isSmallScreen) {
    return Card(
      color: Color(0xFFF1F5F9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 15),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }

  Widget _buildListTile(
    IconData icon,
    String title,
    bool isSmallScreen, {
    String? value,
    VoidCallback? onTap
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Colors.black87,
        size: isSmallScreen ? 20 : 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: isSmallScreen ? 13 : 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: value != null
          ? Text(
              value,
              style: TextStyle(
                color: Colors.green,
                fontSize: isSmallScreen ? 13 : 14,
                fontWeight: FontWeight.w500,
              ),
            )
          : null,
      onTap: onTap,
      dense: true,
      contentPadding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12.0 : 16.0,
        vertical: 4.0
      ),
    );
  }

  Widget _buildListTileWithSwitch(
    IconData icon,
    String title,
    bool value,
    bool isSmallScreen, {
    required ValueChanged<bool> onChanged
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Colors.black87,
        size: isSmallScreen ? 20 : 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: isSmallScreen ? 13 : 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.green,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      dense: true,
      contentPadding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12.0 : 16.0,
        vertical: 4.0
      ),
    );
  }

Widget _buildInfoTile({
  required IconData icon,
  required String title,
  required bool isSmallScreen,
  String? value,
  Color iconColor = Colors.black87,
  bool isMultiLine = false,
  VoidCallback? onTap,
}) {
  return ListTile(
    leading: Icon(
      icon,
      color: iconColor,
      size: isSmallScreen ? 20 : 24,
    ),
    title: Text(
      title,
      style: TextStyle(
        fontSize: isSmallScreen ? 13 : 14,
        fontWeight: FontWeight.w500,
      ),
    ),
    subtitle: isMultiLine && value != null
        ? Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              value,
              style: TextStyle(
                color: value == "" || value == ""
                    ? Colors.grey
                    : Colors.black87,
                fontSize: isSmallScreen ? 13 : 14,
              ),
              maxLines: isMultiLine ? 3 : 1,
              overflow: TextOverflow.ellipsis,
            ),
          )
        : null,
    trailing: !isMultiLine && value != null
        ? SizedBox(
            width: isSmallScreen ? 120 : 150,
            child: Text(
              value,
              style: TextStyle(
                color: value == "" || value == ""
                    ? Colors.grey
                    : Colors.black87,
                fontSize: isSmallScreen ? 13 : 14,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          )
        : null,
    onTap: onTap,
    dense: true,
    contentPadding: EdgeInsets.symmetric(
      horizontal: isSmallScreen ? 12.0 : 16.0,
      vertical: 4.0,
    ),
  );
} Widget _buildClickableTile({
    required IconData icon,
    required Color color,
    required String text,
    required bool isSmallScreen,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: ListTile(
        leading: Icon(
          icon,
          color: color,
          size: isSmallScreen ? 24 : 28,
        ),
        title: Text(
          text,
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            color: text == "" || text == ""
                ? Colors.grey
                : Colors.blue,
          ),
        ),
        minLeadingWidth: isSmallScreen ? 24 : 32,
      ),
    );
  }
}

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