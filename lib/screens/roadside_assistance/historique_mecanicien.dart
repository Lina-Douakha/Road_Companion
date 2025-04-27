import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
class NotificationHistoryScreen extends StatefulWidget {
  @override
  _NotificationHistoryScreenState createState() => _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState extends State<NotificationHistoryScreen> {
  List<Map<String, String>> rawNotifications = [];
  String  providerID="";

  @override
  void initState() {
    super.initState();
    fetchCurrentUser();
    fetchNotifications();
  }
  void fetchCurrentUser() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        providerID = user.uid;
      });
    } else {
      print("No user logged in.");
    }
  }
  Future<void> fetchNotifications() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('Request_history')
          .doc(providerID)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        List<Map<String, String>> fetched = [];

        data.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            final username = value['username'] ?? 'No name';
            final location = "Lat: ${value['location']
                .latitude}, Lng: ${value['location'].longitude}";
            final address = value['address'] ?? location;
            final timestamp = value['date'] as Timestamp;
            final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(
                timestamp.toDate());
            final isAccepted = value['status'] == true;

            fetched.add({
              'image': 'assets/images/profil_pic.png',
              'username': username,
              'address': address,
              'date': dateStr,
              'status': isAccepted
                  ? "historique_mecanicien.accepted"
                  : "historique_mecanicien.rejected",
            });
          }
        });

        setState(() {
          rawNotifications = fetched;
        });
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    }
  }
  Future<void> _refreshData() async {
    await fetchNotifications();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    double screenHeight = MediaQuery
        .of(context)
        .size
        .height;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF1B9169),
        statusBarIconBrightness: Brightness.light,
      ),
      child:  Scaffold(
        backgroundColor: Colors.white,
        body: RefreshIndicator(
        onRefresh: _refreshData,
          color: Color(0xFF00D47E),
          backgroundColor: Colors.white,
        child: CustomScrollView(
          slivers: [
            // Only show the SliverAppBar if rawNotifications is not empty
            if (rawNotifications.isNotEmpty)
              SliverAppBar(
                expandedHeight: screenHeight * 0.12,
                floating: false,
                pinned: false,
                backgroundColor: Colors.white,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: EdgeInsets.only(bottom: screenHeight * 0.03),
                  title: Text(
                    'historique_mecanicien.title'.tr(),
                    style: TextStyle(
                      color: Color(0xFF1B9169),
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.04,
                    ),
                  ),
                  centerTitle: true,
                ),
              ),
            // Main content for empty notifications
            rawNotifications.isEmpty
                ? SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Lottie.asset(
                      'assets/animation/empty.json',
                      width: screenWidth * 0.6,
                      height: screenWidth * 0.6,
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Text(
                      'results.no_results'.tr(),
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenHeight * 0.008),
                    Text(
                      'historique_mecanicien.no_requests'.tr(),
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey.shade500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
                : SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final notification = rawNotifications[index];
                  final translatedNotification = {
                    'image': notification['image']!,
                    'username': notification['username']!.tr(),
                    'address': notification['address']!,
                    'date': notification['date']!,
                    'status': notification['status']!.tr(),
                  };

                  final statusColor =
                  translatedNotification["status"] ==
                      "historique_mecanicien.accepted".tr()
                      ? Color(0xFF01BF7F)
                      : Color(0xFFFF3B30);

                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenHeight * 0.008,
                    ),
                    child: Container(
                      padding: EdgeInsets.all(screenWidth * 0.035),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: screenWidth * 0.13,
                            height: screenWidth * 0.13,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                translatedNotification['image']!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.person,
                                    size: screenWidth * 0.12,
                                    color: Colors.grey,
                                  );
                                },
                              ),
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.04),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  translatedNotification["username"]!,
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.035,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: screenHeight * 0.004),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      color: Colors.grey.shade500,
                                      size: screenWidth * 0.03,
                                    ),
                                    SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        translatedNotification["address"]!,
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.03,
                                          color: Colors.grey.shade600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: screenHeight * 0.004),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      color: Colors.grey.shade500,
                                      size: screenWidth * 0.03,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      translatedNotification["date"]!,
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.03,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: EdgeInsets.only(left: screenWidth * 0.04),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.035,
                                  vertical: screenHeight * 0.005,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                                child: Text(
                                  translatedNotification["status"]!,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.w500,
                                    fontSize: screenWidth * 0.03,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: rawNotifications.length,
              ),
            ),
          ],
        ),
       ),
      )
    );
  }
}