import 'package:flutter/material.dart';
import 'package:road_companion/screens/profile/edit_profile.dart';
import 'package:road_companion/screens/profile/about.dart';
import 'package:road_companion/screens/profile/help.dart';
import 'package:road_companion/screens/profile/privacyPolicy.dart';

class ProfilePage extends StatefulWidget {
  final int selectedIndex;

  const ProfilePage({super.key, this.selectedIndex = 3});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedIndex = 3;
  final ValueNotifier<String> selectedLanguage = ValueNotifier<String>("Français");

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
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
                    "Langue",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Divider(),
              _buildLanguageOption("Français"),
              _buildLanguageOption("Anglais (English)"),
              _buildLanguageOption("Arabe (العربية)"),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(String language) {
    return ValueListenableBuilder<String>(
      valueListenable: selectedLanguage,
      builder: (context, currentLanguage, child) {
        bool isSelected = currentLanguage == language;
        return GestureDetector(
          onTap: () {
            selectedLanguage.value = language;
            Navigator.pop(context);
          },
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            margin: EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: isSelected ? Color(0xFFECFDF3) : Color(0xFFF3F5F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  language,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.black : Colors.black54,
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check, color: Colors.black),
              ],
            ),
          ),
        );
      },
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
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.black),
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
              Positioned(
                right: 4,
                bottom: 4,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.black,
                  child: Icon(Icons.edit, color: Colors.white, size: 16),
                ),
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
            _buildListTile(Icons.edit, "Modifier les informations du profil", onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditProfilePage()),
              );
            }),
            _buildListTile(Icons.notifications, "Notifications", value: "Activé"),
            ValueListenableBuilder<String>(
              valueListenable: selectedLanguage,
              builder: (context, currentLanguage, child) {
                return _buildListTile(Icons.language, "Langue", value: currentLanguage, onTap: () {
                  _showLanguageSelection(context);
                });
              },
            ),
          ]),
          _buildSettingsCard([
            _buildListTile(Icons.lock, "Sécurité"),
            _buildListTile(Icons.send, "Envoyer un retour"),
          ]),
          _buildSettingsCard([
            _buildListTile(Icons.help, "Aide & support", onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HelpCenterPage()),
              );
            }),
            _buildListTile(Icons.info, "À propos", onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AboutPage()),
              );
            }),
            _buildListTile(Icons.privacy_tip, "Politique de confidentialité", onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PrivacyPolicyPage()),
              );
            }),
          ]),
          TextButton.icon(
            onPressed: () {},
            icon: Icon(Icons.logout, color: Colors.red),
            label: Text("Se déconnecter", style: TextStyle(color: Colors.red)),
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
}
