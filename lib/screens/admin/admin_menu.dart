import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:road_companion/screens/admin/admin_laws_navigation_menu.dart';
import 'package:road_companion/screens/admin/admin_reviews.dart';
import 'package:road_companion/screens/admin/Admin_management_users.dart';
import 'package:road_companion/screens/admin/Admin_management_incidents.dart';
import 'package:road_companion/services/auth_service.dart';
import 'package:road_companion/screens/authenticate/login.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

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
                        'Admin Dashboard',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 28.0 : 32.0,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1B9169),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 5.0 : 10.0),
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
              title: 'Users Management',
              subtitle: 'Manage users',
              icon: Icons.people,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ManagementUsers()),
              ),
            ),
            const SizedBox(height: 16),
            _buildAdminCard(
              context,
              title: 'Incidents Management',
              subtitle: 'Manage incidents',
              icon: Icons.report_problem,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ManagementIncidents()),
              ),
            ),
            const SizedBox(height: 16),
            _buildAdminCard(
              context,
              title: 'Educational Content',
              subtitle: 'Manage statistics, exams and traffic laws',
              icon: Icons.school,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminNavigationMenu()),
              ),
            ),
            const SizedBox(height: 16),
            _buildAdminCard(
              context,
              title: 'Service Providers',
              subtitle: 'Manage users, reviews and feedback',
              icon: Icons.business_center,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdminReviewManager()),
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
              title: 'Users Management',
              subtitle: 'Manage users',
              icon: Icons.people,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ManagementUsers()),
              ),
            ),
            _buildAdminCard(
              context,
              title: 'Incidents Management',
              subtitle: 'Manage incidents',
              icon: Icons.report_problem,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ManagementIncidents()),
              ),
            ),
            _buildAdminCard(
              context,
              title: 'Educational Content',
              subtitle: 'Manage statistics, exams and traffic laws',
              icon: Icons.school,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminNavigationMenu()),
              ),
            ),
            _buildAdminCard(
              context,
              title: 'Service Providers',
              subtitle: 'Manage users, reviews and feedback',
              icon: Icons.business_center,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdminReviewManager()),
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