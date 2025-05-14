import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:road_companion/screens/admin/admin_laws_navigation_menu.dart';
import 'package:road_companion/screens/admin/admin_reviews.dart';
import 'package:road_companion/screens/admin/Admin_management_users.dart';
import 'package:road_companion/screens/admin/Admin_management_incidents.dart';
import 'package:road_companion/screens/admin/manage_announcements.dart';
import 'package:road_companion/services/auth_service.dart';
import 'package:road_companion/screens/authenticate/login.dart';
import 'package:easy_localization/easy_localization.dart';

class AdminDashboardScreen extends StatefulWidget {
  AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ValueNotifier<String> selectedLanguage = ValueNotifier<String>("Français");

  Future<void> _logout(BuildContext context) async {
    final AuthService _authService = AuthService();

    bool? confirmLogout = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF0D92F4)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
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

  Widget _buildLanguageOption(String langCode) {
    return GestureDetector(
      onTap: () {
        context.setLocale(Locale(langCode));
        setState(() {}); // Now setState works since we're in a StatefulWidget
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

  Widget buildListTile(IconData icon, String title, {required String value, required VoidCallback onTap}) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(0xFF00D47E).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Color(0xFF00D47E)),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final isLargeScreen = screenWidth > 1200;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF1B9169),
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: SafeArea(
          child: Column(
            children: [
              // Logout button remains in original position
              Padding(
                padding: EdgeInsets.only(
                  left: isSmallScreen ? 255.0 : 315.0,
                  top: 7.0,
                ),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: TextButton.icon(
                    label: Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: isSmallScreen ? 14 : 16,
                      ),
                    ),
                    icon: Icon(
                      Icons.logout,
                      color: Colors.red,
                      size: isSmallScreen ? 23 : 28,
                    ),
                    onPressed: () => _logout(context),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isSmallScreen ? 20.0 : 40.0,
                    20.0, // Increased top padding to add space above title
                    isSmallScreen ? 20.0 : 40.0,
                    20.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Added SizedBox to create space above the title
                      SizedBox(height: isSmallScreen ? 20.0 : 30.0),
                      Text(
                        'admin.dashboard'.tr(),  // Translated title
                        style: TextStyle(
                          fontSize: isSmallScreen ? 28.0 : 32.0,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1B9169),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 5.0 : 10.0),
                      // Language selector button
                      ValueListenableBuilder<String>(
                        valueListenable: selectedLanguage,
                        builder: (context, currentLanguage, child) {
                          return buildListTile(
                              Icons.language,
                              "profile.language".tr(),
                              value: "language_options.${context.locale.languageCode}".tr(),
                              onTap: () {
                                _showLanguageSelection(context);
                              }
                          );
                        },
                      ),
                      Expanded(
                        child: isLargeScreen
                            ? _buildGridLayout(context)
                            : _buildListLayout(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListLayout(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxCardWidth = screenWidth > 500 ? 500.0 : screenWidth * 0.9;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxCardWidth),
        child: ListView(
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            _buildAdminCard(
              context,
              title: 'admin.users_management'.tr(),
              subtitle: 'admin.manage_users'.tr(),
              icon: Icons.people,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ManagementUsers()),
              ),
            ),
            const SizedBox(height: 16),
            _buildAdminCard(
              context,
              title: 'admin.incidents_management'.tr(),
              subtitle: 'admin.manage_incidents'.tr(),
              icon: Icons.report_problem,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ManagementIncidents()),
              ),
            ),
            const SizedBox(height: 16),
            _buildAdminCard(
              context,
              title: 'admin.educational_content'.tr(),
              subtitle: 'admin.manage_educational'.tr(),
              icon: Icons.school,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminNavigationMenu()),
              ),
            ),
            const SizedBox(height: 16),
            _buildAdminCard(
              context,
              title: 'admin.service_providers'.tr(),
              subtitle: 'admin.manage_providers'.tr(),
              icon: Icons.business_center,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdminReviewManager()),
              ),
            ),
            const SizedBox(height: 16),
               _buildAdminCard(
               context,
               title: 'admin.manage_announcements'.tr(),
               subtitle: 'admin.manage_announcements'.tr(),
               icon: Icons.business_center,
               onTap: () => Navigator.push(
                 context,
                 MaterialPageRoute(builder: (context) => ManageAnnouncementsScreen()),
               ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridLayout(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 1400 ? 3 : 2;
    final childAspectRatio = screenWidth > 1400 ? 1.5 : 2.0;
    final maxGridWidth = screenWidth > 1200 ? 1200.0 : screenWidth * 0.95;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxGridWidth),
        child: GridView.count(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            _buildAdminCard(
              context,
              title: 'admin.users_management'.tr(),
              subtitle: 'admin.manage_users'.tr(),
              icon: Icons.people,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ManagementUsers()),
              ),
            ),
            _buildAdminCard(
              context,
              title: 'admin.incidents_management'.tr(),
              subtitle: 'admin.manage_incidents'.tr(),
              icon: Icons.report_problem,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ManagementIncidents()),
              ),
            ),
            _buildAdminCard(
              context,
              title: 'admin.educational_content'.tr(),
              subtitle: 'admin.manage_educational'.tr(),
              icon: Icons.school,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminNavigationMenu()),
              ),
            ),
            _buildAdminCard(
              context,
              title: 'admin.service_providers'.tr(),
              subtitle: 'admin.manage_providers'.tr(),
              icon: Icons.business_center,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdminReviewManager()),
              ),
            ),
            _buildAdminCard(
               context,
               title: 'admin.manage_announcements'.tr(),
               subtitle: 'admin.manage_announcements'.tr(),
               icon: Icons.business_center,
               onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ManageAnnouncementsScreen()),
               ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCard(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        required VoidCallback onTap,
      }) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D47E).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF00D47E),
                    size: isSmallScreen ? 24 : 28,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 16 : 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2D3142),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward,
                  color: const Color(0xFF00D47E).withOpacity(0.8),
                  size: isSmallScreen ? 20 : 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}