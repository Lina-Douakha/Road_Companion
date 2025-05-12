import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:road_companion/screens/admin/Add_announcement.dart';
import 'package:easy_localization/easy_localization.dart';

class AnnouncementDetailScreen extends StatelessWidget {
  final String announcementId;
  final Map<String, dynamic> announcementData;

  const AnnouncementDetailScreen({
    Key? key,
    required this.announcementId,
    required this.announcementData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Format the timestamp
    String formattedDate = 'Pending';
    if (announcementData['createdAt'] != null) {
      final timestamp = announcementData['createdAt'] as Timestamp;
      formattedDate = DateFormat('MMMM d, yyyy • h:mm a').format(timestamp.toDate());
    }

    dynamic audienceRaw = announcementData['audience'];

    String audienceDisplay = 'Unknown';

    if (audienceRaw is String && audienceRaw == 'All') {
      audienceDisplay = getTranslatedAudience('All');
    } else if (audienceRaw is List) {
      audienceDisplay = audienceRaw
          .map((role) => getTranslatedAudience(role.toString()))
          .join(', ');
    } else if (audienceRaw is String) {
      audienceDisplay = getTranslatedAudience(audienceRaw);
    }


    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Color(0xFF1B9169)),
        title: Text(
          'admin.announcement_details'.tr(),
          style: TextStyle(
            color: Color(0xFF1B9169),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: Color(0xFF1B9169)),
            onPressed: () => _navigateToEdit(context),
          ),
          // Delete icon removed from here
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image if available
            if (announcementData['imageUrl'] != null)
              Container(
                width: double.infinity,
                height: 220,
                child: Stack(
                  children: [
                    Image.network(
                      announcementData['imageUrl'],
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
                          ),
                        );
                      },
                    ),
                    // Add a semi-transparent gradient overlay at the bottom
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 80,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.6),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Title overlay on the image
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Text(
                        announcementData['title'] ?? 'Untitled',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 3.0,
                              color: Color.fromARGB(150, 0, 0, 0),
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            // Content area
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Only show title here if there's no image
                  if (announcementData['imageUrl'] == null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        announcementData['title'] ?? 'Untitled',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B9169),
                        ),
                      ),
                    ),

                  // Metadata card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFFEEFCF6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Color(0xFF1B9169).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(Icons.schedule,'admin.posted_on'.tr(namedArgs: {'date': formattedDate})),
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          Icons.person,
                          'admin.posted_by'.tr(namedArgs: {'user': announcementData['createdBy']}),
                        ),
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          Icons.group,
                          'admin.audience-detail'.tr(namedArgs: {'audience': audienceDisplay}),
                        ),


                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Message header
                  Text(
                    'admin.message'.tr(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1B9169),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Message content
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Color(0xFF1B9169).withOpacity(0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      announcementData['message'] ?? 'admin.no_message'.tr(),
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(0xFF1B9169).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: Color(0xFF1B9169),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.black87,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _navigateToEdit(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddAnnouncementScreen(
          announcementId: announcementId,
          announcementData: announcementData,
        ),
      ),
    );

    if (result == true) {
      Navigator.pop(context, true); // Return to manage screen with refresh flag
    }
  }

  String getTranslatedAudience(String audienceKey) {
    switch (audienceKey) {
      case 'All':
        return 'registration.All'.tr();
      case 'user':
        return 'registration.user'.tr();
      case 'mechanic':
        return 'registration.mechanic'.tr();
      case 'towing_service':
        return 'registration.towing_service'.tr();
      case 'parts_supplier':
        return 'registration.parts_supplier'.tr();
      default:
        return audienceKey;
    }
  }



}