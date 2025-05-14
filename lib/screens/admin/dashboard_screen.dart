import 'package:flutter/material.dart';
import 'users_management_screen.dart';
import 'incidents_management_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'clickable_card.dart'; // make sure this file exists and is set up

import 'package:road_companion/Theming/colors.dart';// adjust if the path is different

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          tr("admin.dashboard"),
          style: TextStyle(
            fontSize: screenWidth * 0.05,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF00d47e),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(screenWidth * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: screenHeight * 0.07),
            ClickableCard(
              icon: Icons.group,
              text: tr('admin.manage_users'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UsersManagementScreen()),
                );
              },
            ),
            SizedBox(height: screenHeight * 0.03),
            ClickableCard(
              icon: Icons.report_problem,
              text: tr('admin.incident_reports'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const IncidentManagementScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
