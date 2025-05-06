import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:road_companion/screens/admin/Add_announcement.dart';

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

    // Format audience for display
    String audienceDisplay = 'Unknown';
    if (announcementData['audience'] == 'All') {
      audienceDisplay = 'All Users';
    } else if (announcementData['audience'] is List) {
      audienceDisplay = (announcementData['audience'] as List).join(', ');
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Color(0xFF1B9169)),
        title: Text(
          'Announcement Details',
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
                        _buildInfoRow(Icons.schedule, 'Posted on $formattedDate'),
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          Icons.person,
                          'Posted by ${announcementData['createdBy'] ?? 'Admin'}',
                        ),
                        const SizedBox(height: 10),
                        _buildInfoRow(Icons.group, 'Audience: $audienceDisplay'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Message header
                  Text(
                    'Message',
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
                      announcementData['message'] ?? 'No message content',
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

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Center(
            child: Column(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange.shade600, // A more visually appealing warning color
                  size: 36,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Confirm Delete', // More direct title
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          content: const Padding(
            padding: EdgeInsets.only(top: 16.0),
            child: Text(
              'Are you sure you want to delete this announcement? This action cannot be undone.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent, // A more modern red
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Delete'),
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteAnnouncement(context); // Assuming _deleteAnnouncement still takes context
              },
            ),
          ],
          actionsAlignment: MainAxisAlignment.spaceAround, // Distribute buttons nicely
          contentPadding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 24.0), // Adjust content padding
        );
      },
    );
  }

  Future<void> _deleteAnnouncement(BuildContext context) async {
    try {
      // Delete the document from Firestore
      await FirebaseFirestore.instance
          .collection('announcements')
          .doc(announcementId)
          .delete();

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Announcement deleted successfully'),
            backgroundColor: Color(0xFF1B9169),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        // Navigate back to the manage screen with refresh flag
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting announcement: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}