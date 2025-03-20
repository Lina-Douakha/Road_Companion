import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';

class HelpCenterPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf3f5f7),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCustomHeader(context),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(tr("help.title")),
                  _buildHelpItem(Icons.call, tr("help.phone_support"), "077********", url: "tel:077********"),
                  _buildHelpItem(Icons.email, "Email", "roacompanion@gmail.com", url: "mailto:roacompanion@gmail.com"),
                  _buildHelpItem(Icons.help_outline, tr("help.faq"), tr("help.faq_desc")),
                  SizedBox(height: 20),
                  _buildSectionTitle(tr("help.links")),
                  _buildHelpItem(
                    Icons.facebook,
                    tr("help.facebook"),
                    tr("help.facebook_desc"),
                    url: "https://www.facebook.com/NATSRS.PageOfficielle",
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 70.0, left: 16.0, right: 16.0, bottom: 20.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: const Color(0xFF1b9169), size: 24),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Text(
            tr("help.center"),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1b9169),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[700]),
      ),
    );
  }

  Widget _buildHelpItem(IconData icon, String title, String subtitle, {String? url}) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, size: 30, color: Colors.grey[600]),
          title: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          subtitle: Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey[500])),
          onTap: () {
            if (url != null) {
              _launchURL(url);
            }
          },
        ),
        Divider(),
      ],
    );
  }

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Impossible d'ouvrir l'URL : $url");
    }
  }
}
