import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/services.dart';



class NotificationHistoryScreen extends StatefulWidget {
  final String UserID;
  final bool embedInParent;
  const NotificationHistoryScreen({Key? key, required this.UserID,  this.embedInParent = false,}) : super(key: key);

  @override
  _NotificationHistoryScreenState createState() => _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState extends State<NotificationHistoryScreen> {

  List<Map<String, String>> rawNotifications = [];

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('Request_history')
          .doc(widget.UserID)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        List<Map<String, String>> fetched = [];

        data.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            final username = value['username'] ?? 'No name';
            final location = "Lat: ${value['location']?.latitude}, Lng: ${value['location']?.longitude}";
            final timestamp = value['date'] as Timestamp;
            final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(timestamp.toDate());
            final isAccepted = value['status'] == true;

            fetched.add({
              'image': 'assets/images/profil_pic.png',
              'username': username,
              'location': location,
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


  Widget buildNotificationContent(BuildContext context) {

    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;


    if (rawNotifications.isEmpty) {
      return Column(
        children: [
          Lottie.asset(
            'assets/animation/empty.json',
            width: screenWidth * 0.6,
            height: screenWidth * 0.6,
          ),
          Text(
            'results.no_results'.tr(),
            style: TextStyle(
              fontSize: screenWidth * 0.045,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),

        ],
      );
    }

    return Column(
      children: rawNotifications.map((notification) {
        final translatedNotification = {
          'image': notification['image']!,
          'username': notification['username']!.tr(),
          'location': notification['location']!,
          'date': notification['date']!,
          'status': notification['status']!.tr(),
        };

        final statusColor = translatedNotification["status"] ==
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
                        return Icon(Icons.person, color: Colors.grey);
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
                          Icon(Icons.location_on_outlined,
                              size: screenWidth * 0.03,
                              color: Colors.grey.shade500),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              translatedNotification["location"]!,
                              style: TextStyle(
                                  fontSize: screenWidth * 0.03,
                                  color: Colors.grey.shade600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.004),
                      Row(
                        children: [
                          Icon(Icons.access_time,
                              size: screenWidth * 0.03,
                              color: Colors.grey.shade500),
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
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.035,
                      vertical: screenHeight * 0.005),
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
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedInParent) {
      // Si on est en mode imbriqué, retourner juste le contenu (votre méthode build actuelle)
      return buildNotificationContent(context);
    } else {
      // Si on est en mode écran indépendant, utiliser le CustomScrollView
      return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: buildNotificationContent(context)),
        ],
      );
    }
  }

}
