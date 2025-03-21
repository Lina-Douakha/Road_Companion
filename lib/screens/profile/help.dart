import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';

class HelpCenterPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
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
                  _buildHelpItem(Icons.call, tr("help.phone_support"), "0778256106", url: "tel:0778256106"),
                  _buildHelpItem(Icons.email, "Email", "na_meliani@esi.dz", url: "mailto:na_meliani@esi.dz"),
                  _buildHelpItem(Icons.help_outline, tr("help.faq"), tr("help.faq_desc")),
                  const SizedBox(height: 20),
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
              icon: const Icon(Icons.arrow_back, color: Color(0xFF1b9169), size: 24),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Text(
            tr("help.center"),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1b9169),
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
          title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          onTap: () {
            if (url != null) {
              _launchURL(url);
            }
          },
        ),
        const Divider(),
      ],
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);

    if (url.startsWith("mailto:")) {
      final Uri emailUri = Uri(
        scheme: "mailto",
        path: "na_meliani@esi.dz",
        queryParameters: {
          "subject": "",
          "body": "",
        },
      );

      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        debugPrint("Failed to open email.");
      }
      return;
    }

    if (url.contains("facebook.com")) {
      // Open Facebook in app if installed, otherwise in browser
      final Uri fbAppUri = Uri.parse("fb://facewebmodal/f?href=$url");
      if (await canLaunchUrl(fbAppUri)) {
        await launchUrl(fbAppUri);
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Failed to open URL: $url");
    }
  }
}



