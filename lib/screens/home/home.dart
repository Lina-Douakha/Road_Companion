import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:road_companion/screens/emergency/emergency.dart';
import 'package:road_companion/screens/incident_reporting/incident_report_screen.dart';
import 'package:road_companion/screens/profile/profile.dart';
import 'package:road_companion/widgets/navigation_bar_widget.dart';
import 'package:road_companion/screens/traffic_law/Traffic_Law.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:road_companion/screens/GPS_navigation/map_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // Liste des pages associées aux onglets de la navbar
  final List<Widget> _pages = [
    const MapPage(),
    const EmergencyCallPage(),
    const TrafficLawScreen(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    // Add a delay to make sure everything is initialized
    Future.delayed(Duration(seconds: 1), () {
      checkForWarnings();
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Check for new warnings
  Future<void> checkForWarnings() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    print("Checking warnings for user: ${currentUser?.uid}");
    if (currentUser == null) return;

    try {
      // Get user document
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      print("User doc exists: ${userDoc.exists}");
      print("User doc has warnings field: ${userDoc.data()?.containsKey('warnings')}");

      if (!userDoc.exists || !userDoc.data()!.containsKey('warnings')) return;

      // Get SharedPreferences to track which warnings we've seen
      final prefs = await SharedPreferences.getInstance();
      final lastSeenWarningCount = prefs.getInt('lastSeenWarningCount') ?? 0;
      print("Last seen warning count: $lastSeenWarningCount");

      // Get current warning count
      final List<dynamic> warnings = userDoc.data()!['warnings'] ?? [];
      final currentWarningCount = warnings.length;
      print("Current warning count: $currentWarningCount");

      // If there are new warnings
      if (currentWarningCount > lastSeenWarningCount && warnings.isNotEmpty) {
        print("New warnings found!");
        // Get only the new warnings
        final newWarnings = warnings.sublist(lastSeenWarningCount);

        // Show the latest warning
        if (newWarnings.isNotEmpty) {
          print("Showing warning: ${newWarnings.last['message']}");
          showWarningPopup(newWarnings.last['message']);
        }

        // Update the last seen count
        await prefs.setInt('lastSeenWarningCount', currentWarningCount);
      } else {
        print("No new warnings to show");
      }
    } catch (e) {
      print('Error checking for warnings: $e');
    }
  }
  // Show warning popup
  void showWarningPopup(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 5,
          backgroundColor: Colors.white,
          child: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Warning icon
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange[700],
                    size: 28,
                  ),
                ),
                SizedBox(height: 12),

                // Title
                Text(
                  'Warning',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 16),

                // Warning message
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 24),

                // Acknowledge button
                Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[500],
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF1B9169),
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: _pages[_selectedIndex],
        backgroundColor: Colors.white, // Affichage dynamique du contenu
        bottomNavigationBar: NavigationBarWidget(
          selectedIndex: _selectedIndex,
          onItemTapped: _onItemTapped,
        ), // Utilisation correcte de la navbar
      ),
    );
  }
}