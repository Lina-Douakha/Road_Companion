import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:road_companion/providers/locale_provider.dart';
import 'package:road_companion/screens/profile/edit_profile.dart';
import 'package:road_companion/screens/profile/about.dart';
import 'package:road_companion/screens/profile/help.dart';
import 'package:road_companion/screens/profile/privacyPolicy.dart';
import 'package:road_companion/screens/profile/ChangePasswordPage.dart';


class ProfilePage extends StatefulWidget {
  final int selectedIndex;

  const ProfilePage({super.key, this.selectedIndex = 3});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ValueNotifier<String> selectedLanguage = ValueNotifier<String>("Français");
  final ValueNotifier<bool> notificationsEnabled = ValueNotifier<bool>(true);

  @override
  void initState() {
    super.initState();
  }

  void _showLanguageSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
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
                    "profile.language".tr(), // Utiliser la clé JSON
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
        debugPrint("Langue actuelle: ${context.locale.languageCode}");  // ✅ Vérification
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
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "language_options.$langCode".tr(), // Utiliser la clé JSON
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: context.locale.languageCode == langCode
                    ? Colors.black
                    : Colors.black54,
              ),
            ),
            if (context.locale.languageCode == langCode)
              Icon(Icons.check, color: Colors.black),
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
      backgroundColor: Colors.grey[200],
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 40),
            _buildTopIcons(),
            _buildProfileHeader(),
            _buildSettingsOptions(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage('assets/images/photo_de_profile.png'),
              ),

            ],
          ),
          SizedBox(height: 10),
          Text(
            "Laila Khan",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            "Frontend Developer (React)",
            style: TextStyle(color: Colors.grey[600]),
          ),
          SizedBox(height: 5),
          Text(
            "youremail@domain.com | +01 234 567 89",
            style: TextStyle(color: Colors.grey[700]),
          ),
          SizedBox(height: 10),
        ],
      ),
    );
  }
  Widget _buildSettingsOptions() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSettingsCard([
            _buildListTile(Icons.edit, "profile.edit".tr(), onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditProfilePage()),
              );
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
          _buildSettingsCard([
            _buildListTile(Icons.lock, "profile.security".tr(), onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChangePasswordPage()),
              );
            }),
            _buildListTile(Icons.send, "profile.send_feedback".tr()),
          ]),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.start, // Alignement à droite
            children: [
              TextButton.icon(
                onPressed: () {},
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(children: children),
    );
  }

  Widget _buildListTile(IconData icon, String title, {String? value, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(title),
      trailing: value != null ? Text(value, style: TextStyle(color: Colors.green)) : null,
      onTap: onTap,
    );
  }
  Widget _buildListTileWithSwitch(IconData icon, String title, bool value, {required ValueChanged<bool> onChanged}) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(title),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.green,
      ),
    );
  }
}
