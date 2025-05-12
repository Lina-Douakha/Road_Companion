import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:road_companion/screens/admin/Add_announcement.dart';
import 'package:road_companion/screens/admin/announcement_detail.dart';
import 'package:easy_localization/easy_localization.dart';

class ManageAnnouncementsScreen extends StatefulWidget {
  const ManageAnnouncementsScreen({Key? key}) : super(key: key);

  @override
  _ManageAnnouncementsScreenState createState() => _ManageAnnouncementsScreenState();
}

class _ManageAnnouncementsScreenState extends State<ManageAnnouncementsScreen> {
  bool _isLoading = false;
  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Color(0xFF1B9169),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24), // Add some space below the pop icon
            Text(
              'admin.manage_announcements'.tr(),
              style: TextStyle(
                color: Color(0xFF1B9169),
                fontWeight: FontWeight.bold,

              ),
            ),
          ],
        ),
        centerTitle: true, // Keep the title centered
      ),
      body: _buildAnnouncementsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddAnnouncementScreen(),
            ),
          );

          // Refresh the list if a new announcement was added
          if (result == true) {
            setState(() {});
          }
        },
        backgroundColor: Color(0xFFD1FADF),
        child: Icon(Icons.add, color: Color(0xFF00D47E)),
      ),
    );
  }

  Widget _buildAnnouncementsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('announcements')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D47E)),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 60,
                  color: Colors.grey.shade400,
                ),
                SizedBox(height: 16),
                Text(
                  'admin.error.tr(): ${snapshot.error}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.sentiment_dissatisfied,
                  size: 60,
                  color: Colors.grey.shade400,
                ),
                SizedBox(height: 16),
                Text(
                  'admin.no_announcements_found'.tr(),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        final announcements = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemCount: announcements.length,
          itemBuilder: (context, index) {
            final announcement = announcements[index];
            final data = announcement.data() as Map<String, dynamic>;
            final id = announcement.id;

            // Format the timestamp
            String formattedDate = 'Pending';
            if (data['createdAt'] != null) {
              final timestamp = data['createdAt'] as Timestamp;
              formattedDate = DateFormat('MMM d, yyyy • h:mm a').format(timestamp.toDate());
            }



            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 6,
                    spreadRadius: 1,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.campaign_outlined,
                        color: Color(0xFF1B9169),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          data['title'] ?? 'Untitled',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          buildIconCircle(
                            icon: Icons.edit_outlined,
                            color: Color(0xFF1B9169),
                            onTap: () => _showEditAnnouncementDialog(context, id, data),
                          ),
                          SizedBox(width: 8),
                          buildIconCircle(
                            icon: Icons.delete_outlined,
                            color: Colors.orange,
                            onTap: () {
                              _showDeleteConfirmation(id);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            SizedBox(width: 6),
                            Text(
                              formattedDate,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),


                        SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AnnouncementDetailScreen(
                                  announcementId: id,
                                  announcementData: data,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                            decoration: BoxDecoration(
                              color: Color(0xFFD1FADF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'admin.view_details'.tr(),
                              style: TextStyle(
                                color: Color(0xFF00D47E),
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }void _showEditAnnouncementDialog(BuildContext context, String id, Map<String, dynamic> data) {
    final TextEditingController titleController = TextEditingController(text: data['title'] ?? '');
    final TextEditingController contentController = TextEditingController(text: data['message'] ?? '');

    // Extract audience from data
    List<String> _selectedAudience = [];
    if (data['audience'] is String && data['audience'] == 'All') {
      _selectedAudience = ['All'];
    } else if (data['audience'] is List) {
      _selectedAudience = List<String>.from(data['audience']);
    }

    // Keep the fixed keys for internal use
    final List<String> _audienceOptions =  ['All', 'user', 'mechanic', 'towing_service', 'parts_supplier'];

    void _toggleAudience(String audience, StateSetter setState) {
      setState(() {
        if (audience == 'All') {
          if (_selectedAudience.contains('All')) {
            _selectedAudience.remove('All');
          } else {
            _selectedAudience = ['All'];
          }
        } else {
          if (_selectedAudience.contains('All')) {
            _selectedAudience.remove('All');
          }
          if (_selectedAudience.contains(audience)) {
            _selectedAudience.remove(audience);
          } else {
            _selectedAudience.add(audience);
          }
        }
      });
    }

    showDialog(
      context: context,
      builder: (newContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Colors.white,
              insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'admin.edit_announcement'.tr(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B9169),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title field
                            Theme(
                              data: Theme.of(context).copyWith(
                                textSelectionTheme: TextSelectionThemeData(
                                  cursorColor: Color(0xFF00D47E),
                                  selectionHandleColor: Color(0xFF00D47E),
                                ),
                              ),
                              child: TextField(
                                cursorColor: Color(0xFF00D47E),
                                controller: titleController,
                                style: TextStyle(fontSize: 15),
                                decoration: InputDecoration(
                                  labelText: 'admin.title'.tr(),
                                  alignLabelWithHint: true,
                                  labelStyle: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF1B9169)
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                        color: Color(0xFF1B9169).withOpacity(0.3)
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                        color: Color(0xFF00D47E),
                                        width: 1.5
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12
                                  ),
                                  fillColor: Color(0xFF1B9169).withOpacity(0.05),
                                  filled: true,
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Content field
                            Theme(
                              data: Theme.of(context).copyWith(
                                textSelectionTheme: TextSelectionThemeData(
                                  cursorColor: Color(0xFF00D47E),
                                  selectionHandleColor: Color(0xFF00D47E),
                                ),
                              ),
                              child: TextField(
                                cursorColor: Color(0xFF00D47E),
                                controller: contentController,
                                maxLines: 5,
                                style: TextStyle(fontSize: 15),
                                decoration: InputDecoration(
                                  labelText: 'admin.message'.tr(),
                                  alignLabelWithHint: true,
                                  labelStyle: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF1B9169)
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                        color: Color(0xFF1B9169).withOpacity(0.3)
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                        color: Color(0xFF00D47E),
                                        width: 1.5
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12
                                  ),
                                  fillColor: Color(0xFF1B9169).withOpacity(0.05),
                                  filled: true,
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Audience selection - Using translated display but keeping original keys
                            Text(
                              'admin.audience'.tr(),
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF1B9169),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: _audienceOptions.map((audience) {
                                final isSelected = _selectedAudience.contains(audience);
                                // Use the translation function for display
                                String displayText = getTranslatedAudience(audience);

                                return GestureDetector(
                                  onTap: () => _toggleAudience(audience, setState),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isSelected ? Color(0xFFD1FADF) : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected ? Color(0xFF00D47E) : Color(0xFF1B9169).withOpacity(0.3),
                                        width: isSelected ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Text(
                                      displayText, // Use translated text here
                                      style: TextStyle(
                                        color: isSelected ? Color(0xFF00D47E) : Color(0xFF1B9169),
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: Color(0xFF1B9169),
                            padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'admin.cancel'.tr(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF00D47E),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 10
                            ),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            if (titleController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('admin.please_enter_a_title'.tr())),
                              );
                              return;
                            }

                            try {
                              // Determine audience value - Use the raw keys for Firebase storage
                              dynamic audience;
                              if (_selectedAudience.contains('All')) {
                                audience = 'All';
                              } else {
                                audience = _selectedAudience.where((item) => item != 'All').toList();
                              }

                              // Update announcement in Firestore
                              await FirebaseFirestore.instance
                                  .collection('announcements')
                                  .doc(id)
                                  .update({
                                'title': titleController.text.trim(),
                                'message': contentController.text.trim(),
                                'audience': audience,
                                'updatedAt': FieldValue.serverTimestamp(),
                              });

                              Navigator.pop(context);
                            } catch (e) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('admin.error_updating_announcement: $e'.tr())),
                              );
                            }
                          },
                          child: Text(
                            'admin.update'.tr(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

// Update the getTranslatedAudience function to match all possible audience keys
  String getTranslatedAudience(String audienceKey) {
    switch (audienceKey) {
      case 'All':
        return 'registration.All'.tr();
      case 'user':
        return 'registration.user'.tr();
      case 'mechanic':
        return 'registration.mechanic'.tr();
      case 'parts_supplier':
        return 'registration.spare_parts'.tr();
      case 'towing_service':
        return 'registration.towing_service'.tr();
      default:
        return audienceKey;
    }
  }

  Future<void> _showDeleteConfirmation(String id) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Center(
            child: Text(
              'admin.delete_announcement'.tr(),
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          content: Text(
            'admin.confiramation_message'.tr(),
            style: TextStyle(color: Colors.grey[800]),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'admin.cancel'.tr(),
                style: TextStyle(color: Color(0xFF1B9169)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                  'admin.delete'.tr(),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  )
              ),
              style: TextButton.styleFrom(
                backgroundColor: Color(0xFF00D47E),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteAnnouncement(id);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAnnouncement(String id) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // First get the announcement data to check if there's an image to delete
      final announcementDoc = await FirebaseFirestore.instance
          .collection('announcements')
          .doc(id)
          .get();

      if (announcementDoc.exists) {
        final data = announcementDoc.data() as Map<String, dynamic>;

        // Delete the document from Firestore
        await FirebaseFirestore.instance
            .collection('announcements')
            .doc(id)
            .delete();

        DeletionSuccessDialog();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('admin.error_deleting_announcement: $e'.tr())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }void DeletionSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D47E).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Color(0xFF00D47E),
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'admin.announcement_deleted'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D47E),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child:  Text('admin.OK'.tr()),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        Future.delayed(Duration(seconds: 2), () {
          Navigator.of(context).pop();
        });

        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 60,
                  width: 60,
                  child: Lottie.asset('assets/animation/success.json'),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildIconCircle({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.1),
        ),
        child: Icon(
          icon,
          size: 16,
          color: color,
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}