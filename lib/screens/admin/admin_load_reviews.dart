import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:road_companion/screens/admin/UserDetailsScreen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lottie/lottie.dart';

class AdminLoadReviews extends StatefulWidget {
  final String providerId;

  const AdminLoadReviews({Key? key, required this.providerId}) : super(key: key);

  @override
  _AdminLoadReviewsState createState() => _AdminLoadReviewsState();
}

class _AdminLoadReviewsState extends State<AdminLoadReviews> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<Map<String, dynamic>> reviews = [];
  String status = 'Loading...';
  bool isLoading = true;
  double averageRating = 0.0;
  int totalReviews = 0;
  List<Map<String, dynamic>> users = [];
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    loadReviews(widget.providerId);
  }

  Future<void> toggleBlockUser(String userId, bool currentBlockedStatus) async {
    try {
      await firestore.collection('users').doc(userId).update({
        'isBlocked': !currentBlockedStatus,
      });

      setState(() {
        final userIndex = users.indexWhere((user) => user['UserID'] == userId);
        if (userIndex != -1) {
          users[userIndex]['isBlocked'] = !currentBlockedStatus;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('admin.user_management.failed_toggle'.tr(args: [e.toString()]))),
      );
    }
  }

  Future<void> loadReviews(String providerID) async {
      try {
        setState(() {
          isLoading = true;
          reviews = [];
          averageRating = 0.0;
          totalReviews = 0;
        });

        final providerRef = _db.collection('Reviews').doc(providerID);
        final providerDoc = await providerRef.get();

        if (!providerDoc.exists) {
          setState(() {
            status = 'admin.review_management.no_reviews_found'.tr();
            isLoading = false;
          });
          return;
        }

        final data = providerDoc.data() as Map<String, dynamic>;
        final reviewsMap = data['reviews'] as Map<String, dynamic>? ?? {};

        List<Map<String, dynamic>> validReviews = [];
        double totalRating = 0.0;
        int validReviewCount = 0;

        // Check each review to verify sender exists
        for (var entry in reviewsMap.entries) {
          final reviewData = entry.value as Map<String, dynamic>;
          final String senderID = reviewData['senderID'] ?? '';

          if (senderID.isNotEmpty) {
            try {
              // Verify sender exists in users collection
              final userDoc = await _db.collection('users').doc(senderID).get();

              if (userDoc.exists) {
                final userData = userDoc.data() as Map<String, dynamic>;

                // Add the review to valid reviews
                validReviews.add({
                  'name': userData['Name'] ?? reviewData['name'] ?? 'Unknown',
                  'image': userData['ProfilePhoto'] ?? reviewData['image'] ?? '',
                  'rating': (reviewData['rating'] is num)
                      ? (reviewData['rating'] as num).toDouble()
                      : 0.0,
                  'comment': reviewData['comment'] ?? 'No comment',
                  'date': reviewData['date'] ?? 'No date',
                  'senderID': senderID,
                  'isVisible': reviewData.containsKey('isVisible')
                      ? (reviewData['isVisible'] as bool)
                      : true,
                });

                // Calculate average rating
                totalRating += validReviews.last['rating'];
                validReviewCount++;
              }
            } catch (e) {
              debugPrint('Error checking user $senderID: $e');
            }
          }
        }

        // Calculate average rating if there are valid reviews
        if (validReviewCount > 0) {
          averageRating = totalRating / validReviewCount;
        }

        if (mounted) {
          setState(() {
            reviews = validReviews;
            totalReviews = validReviewCount;
            status = validReviews.isEmpty
                ? 'admin.review_management.no_valid_reviews'.tr()
                : 'admin.review_management.reviews_loaded'.tr(args: [validReviews.length.toString()]);
            isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            status = 'admin.review_management.load_error'.tr(args: [e.toString()]);
            isLoading = false;
          });
        }
        debugPrint('Error loading reviews: $e');
      }
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Color(0xFF1B9169),
        surfaceTintColor: Color(0xFF1B9169),
        elevation: 0,
        title: Text(
          'admin.review_management.provider_reviews'.tr(),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Color(0xFF1B9169),
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            color: Color(0xFF1B9169),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            'admin.review_management.provider_id'.tr(args: [widget.providerId]),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8),
                        InkWell(
                          onTap: () async {
                            await Clipboard.setData(ClipboardData(text: widget.providerId));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('admin.review_management.provider_id_copied'.tr(),
                                    style: TextStyle(color: Colors.green)),
                                backgroundColor: Colors.green[50],
                                behavior: SnackBarBehavior.floating,
                                margin: EdgeInsets.all(10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          },
                          child: Icon(
                            Icons.copy,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(
              child: CircularProgressIndicator(
                color: Color(0xFF00D47E),
              ),
            )
                : reviews.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                final review = reviews[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 8,
                          spreadRadius: 1,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.0),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            try {
                              final snapshot = await firestore.collection('users').doc(review['senderID']).get();

                              if (snapshot.exists) {
                                Map<String, dynamic> userData = snapshot.data() as Map<String, dynamic>? ?? {};

                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => UserDetailsScreen(user: userData),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('admin.review_management.user_profile_not_found'.tr())),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('admin.review_management.error_loading_profile'.tr(args: [e.toString()]))),
                              );
                              print('Error navigating to user profile: $e');
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: Color(0xFF1B9169).withOpacity(0.1),
                                      backgroundImage: review['image'] != null && review['image'].isNotEmpty
                                          ? AssetImage(review['image'])
                                          : null,
                                      child: review['image'] == null || review['image'].isEmpty
                                          ? Text(
                                        review['name'] != null && review['name'].isNotEmpty
                                            ? review['name'][0].toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                          color: Color(0xFF1B9169),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      )
                                          : null,
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            review['name'] ?? 'Anonymous',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            review['date'] ?? 'No date',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getRatingColor(review['rating']).withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.star,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            review['rating'].toStringAsFixed(1),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                Text(
                                  review['comment'] ?? 'No comment',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () {
                                        // Add functionality to flag or moderate review
                                        _showModerateDialog(review);
                                      },
                                      icon: Icon(
                                        Icons.flag_outlined,
                                        size: 16,
                                        color: Colors.orange[700],
                                      ),
                                      label: Text(
                                        'admin.review_management.moderate'.tr(),
                                        style: TextStyle(
                                          color: Colors.orange[700],
                                        ),
                                      ),
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        backgroundColor: Colors.orange[50],
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8), // Add spacing between buttons
                                    TextButton.icon(
                                      onPressed: () {
                                        showUserManagementDialog(review);
                                      },
                                      icon: Icon(
                                        Icons.admin_panel_settings_outlined,
                                        size: 16,
                                        color: Colors.blue[700],
                                      ),
                                      label: Text(
                                        'admin.review_management.manage_user'.tr(),
                                        style: TextStyle(
                                          color: Colors.blue[700],
                                        ),
                                      ),
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        backgroundColor: Colors.blue[50],
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animation/emptybox.json',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
            Text(
              'admin.review_management.no_reviews'.tr(),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

  void showUserManagementDialog(Map<String, dynamic> review) {
    showDialog(
      context: context,
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
                // Header with centered styling
                Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.admin_panel_settings,
                        color: Colors.blue[700],
                        size: 28,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'admin.review_management.manage_user'.tr(),
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),

                Divider(height: 24, thickness: 1, color: Colors.grey[200]),

                // Instructions - centered
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'admin.user_management.choose_action'.tr(),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                SizedBox(height: 24),

                // Buttons - already centered
                Column(
                  children: [
                    // Warning Button
                    Container(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          showWarningMessageDialog(review['senderID']);
                        },
                        icon: Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange[700],
                          size: 20,
                        ),
                        label: Text(
                          'admin.user_management.send_warning'.tr(),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[700],
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[50],
                          padding: EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),

                    Container(
                      width: double.infinity,
                      child: FutureBuilder<DocumentSnapshot>(
                        future: firestore.collection('users').doc(review['senderID']).get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (snapshot.hasError) {
                            return ElevatedButton(
                              onPressed: null,
                              child: Text('Error loading user data'),
                            );
                          }

                          Map<String, dynamic> userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
                          bool isBlocked = userData['isBlocked'] ?? false;
                          return ElevatedButton.icon(
                            onPressed: () {
                              toggleBlockUser(review['senderID'], isBlocked).then((_) {
                                Navigator.pop(context);
                                SuccessDialog(
                                    context,
                                    isBlocked ? "admin.user_management.user_activated".tr() : "admin.user_management.user_blocked".tr()
                                );
                              });
                            },
                            icon: Icon(
                              isBlocked ? Icons.person_add : Icons.block,
                              color: isBlocked ? Colors.green : Colors.red,
                              size: 20,
                            ),
                            label: Text(
                              isBlocked ? 'admin.user_management.activate_user'.tr() : 'admin.user_management.block_user'.tr(),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isBlocked ? Colors.green : Colors.red,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isBlocked ? Colors.green[50] : Colors.red[50],
                              padding: EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 16),

                    // Cancel action
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        tr("admin.cancel"),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        backgroundColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
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
  }

  void showWarningMessageDialog(String userId) {
    final TextEditingController messageController = TextEditingController(
        text: "admin.default_warning".tr()
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 5,
          backgroundColor: Colors.white,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Column(
                        children: [
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
                          Text(
                            'admin.user_management.warning_message_title'.tr(),
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      Divider(height: 24, thickness: 1, color: Colors.grey[200]),

                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'admin.user_management.enter_warning_message'.tr(),
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      SizedBox(height: 12),
                      Theme(
                        data: Theme.of(context).copyWith(
                          textSelectionTheme: TextSelectionThemeData(
                            selectionHandleColor: Colors.orange[300],
                            selectionColor: Colors.orange[100],
                          ),
                        ),
                        child: TextField(
                          controller: messageController,
                          maxLines: 5,
                          minLines: 4,
                          style: TextStyle(fontSize: 15),
                          textAlign: TextAlign.justify,
                          textAlignVertical: TextAlignVertical.top,
                          cursorColor: Colors.orange[300],
                          decoration: InputDecoration(
                            hintText: 'admin.user_management.write_warning_placeholder'.tr(),
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            filled: true,
                            fillColor: Colors.grey[50],
                            contentPadding: EdgeInsets.all(16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.orange[300]!, width: 1),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 24),

                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                if (messageController.text.trim().isNotEmpty) {
                                  try {
                                    // Show loading indicator
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (BuildContext context) {
                                        return Dialog(
                                          backgroundColor: Colors.white,
                                          child: Padding(
                                            padding: const EdgeInsets.all(20.0),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                CircularProgressIndicator(
                                                  color: Colors.orange[500],
                                                ),
                                                SizedBox(width: 20),
                                                Text("admin.user_management.sending_warning".tr()),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );

                                    final currentAdmin = FirebaseAuth.instance.currentUser;
                                    final adminId = currentAdmin?.uid ?? 'unknown_admin';

                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(userId)
                                        .update({
                                      'warningCount': FieldValue.increment(1),
                                      'lastWarningDate': DateTime.now().toIso8601String(),
                                      'warnings': FieldValue.arrayUnion([
                                        {
                                          'message': messageController.text.trim(),
                                          'adminId': adminId,
                                          'timestamp': DateTime.now().toIso8601String(),
                                        }
                                      ]),
                                    });

                                    Navigator.pop(context); // Close loading dialog

                                    Navigator.pop(context); // Close warning message dialog

                                    SuccessDialog(context, "admin.user_management.warning_sent".tr());
                                  } catch (e) {
                                    // Close loading indicator
                                    Navigator.pop(context);

                                    // Show error message
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('admin.user_management.failed_to_send_warning'.tr(args: [e.toString()]),
                                            style: TextStyle(color: Colors.red)),
                                        backgroundColor: Colors.red[50],
                                        behavior: SnackBarBehavior.floating,
                                        margin: EdgeInsets.all(10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    );
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('admin.user_management.warning_empty'.tr(),
                                          style: TextStyle(color: Colors.red)),
                                      backgroundColor: Colors.red[50],
                                      behavior: SnackBarBehavior.floating,
                                      margin: EdgeInsets.all(10),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Text(
                                'admin.user_management.send_warning'.tr(),
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
                          SizedBox(height: 10),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              tr("admin.cancel"),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
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
          ),
        );
      },
    );
  }


  Color _getRatingColor(double rating) {
    if (rating >= 4.5) return Colors.green[700]!;
    if (rating >= 3.5) return Colors.green[400]!;
    if (rating >= 2.5) return Colors.orange;
    return Colors.red;
  }


  void _showModerateDialog(Map<String, dynamic> review) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Column(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFF1B9169).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.admin_panel_settings,
                color: Color(0xFF1B9169),
                size: 28,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'admin.moderation_dialog.moderate_review'.tr(),
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User info section
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person, size: 16, color: Colors.grey[600]),
                        SizedBox(width: 8),
                        Text(
                          'admin.moderation_dialog.user'.tr(),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          '${review['name']}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.star, size: 16, color: Colors.grey[600]),
                        SizedBox(width: 8),
                        Text(
                          'admin.review_management.rating'.tr(),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(width: 4),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getRatingColor(review['rating']).withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${review['rating']}',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              // Action section
              Center(
                child: Text(
                  'admin.moderation_dialog.moderation_actions'.tr(),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    fontSize: 14,
                  ),
                ),
              ),
              SizedBox(height: 4),
              Divider(),
            ],
          ),
        ),
        actionsPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          // Row of buttons for better layout
          Row(
            children: [
              // Cancel button
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    tr("admin.cancel"),
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: TextButton(
                  onPressed: () {
                    bool wasVisible = review['isVisible']; // safely check first


                    if (mounted) {
                      setState(() {
                        if (wasVisible) {
                          _hideReview(review);
                        } else {
                          _unhideReview(review);
                        }
                      });
                      Navigator.of(context).pop(); // close the dialog immediately
                      if (wasVisible){
                        SuccessDialog(context, "admin.review_management.review_hidden".tr());
                      } else {
                        SuccessDialog(context, "admin.review_management.review_unhidden".tr());
                      }
                    }
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.orange[50],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    (review['isVisible'] == true) ? 'admin.moderation_dialog.hide'.tr() : 'admin.moderation_dialog.unhide'.tr(),
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),

              // Delete button
              Expanded(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _deleteReview(review);
                    });
                    Navigator.of(context).pop();
                    SuccessDialog(context, "admin.review_management.review_deleted".tr());
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.red[50],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'admin.moderation_dialog.delete'.tr(),
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _unhideReview(Map<String, dynamic> review) async {
    try {
      // Get the provider ID
      String providerID = widget.providerId;
      String senderID = review['senderID'];

      String reviewDate = review['date']; // Use date as additional identifier
      String reviewComment = review['comment']; // Use comment as additional identifier

      if (senderID.isEmpty) {
        debugPrint('Error: senderID is empty');
        return;
      }

      // Reference to the provider's reviews document
      DocumentReference providerRef = _db.collection('Reviews').doc(providerID);

      // Get the current document
      DocumentSnapshot providerDoc = await providerRef.get();

      if (!providerDoc.exists) {
        debugPrint('Error: Provider document does not exist');
        return;
      }

      // Get the current data
      Map<String, dynamic> data = providerDoc.data() as Map<String, dynamic>;
      Map<String, dynamic> reviewsMap = data['reviews'] ?? {};

      // Find the exact review using multiple identifiers
      String reviewKey = "";
      reviewsMap.forEach((key, value) {
        Map<String, dynamic> reviewData = value as Map<String, dynamic>;
        // Match on multiple fields to ensure we get exactly the right review
        if (reviewData['senderID'] == senderID &&
            reviewData['date'] == reviewDate &&
            reviewData['comment'] == reviewComment) {
          reviewKey = key;
          return;
        }
      });

      if (reviewKey.isNotEmpty) {
        // Get the specific review data
        Map<String, dynamic> reviewData = reviewsMap[reviewKey] as Map<String, dynamic>;

        // Update the visibility field
        reviewData['isVisible'] = true;

        // Update the review in the map
        reviewsMap[reviewKey] = reviewData;

        // Update Firestore with the modified reviews map
        await providerRef.update({
          'reviews': reviewsMap
        });

        // Refresh the reviews list
        loadReviews(providerID);
      } else {
        debugPrint('Error: Exact review match not found');
      }

    } catch (e) {
      debugPrint('Error hiding review: $e');
    }
  }
  Future<void> _hideReview(Map<String, dynamic> review) async {
    try {
      // Get the provider ID
      String providerID = widget.providerId;
      String senderID = review['senderID'];

      String reviewDate = review['date']; // Use date as additional identifier
      String reviewComment = review['comment']; // Use comment as additional identifier

      if (senderID.isEmpty) {
        debugPrint('Error: senderID is empty');
        return;
      }

      // Reference to the provider's reviews document
      DocumentReference providerRef = _db.collection('Reviews').doc(providerID);

      // Get the current document
      DocumentSnapshot providerDoc = await providerRef.get();

      if (!providerDoc.exists) {
        debugPrint('Error: Provider document does not exist');
        return;
      }

      // Get the current data
      Map<String, dynamic> data = providerDoc.data() as Map<String, dynamic>;
      Map<String, dynamic> reviewsMap = data['reviews'] ?? {};

      // Find the exact review using multiple identifiers
      String reviewKey = "";
      reviewsMap.forEach((key, value) {
        Map<String, dynamic> reviewData = value as Map<String, dynamic>;

        // Match on multiple fields to ensure we get exactly the right review
        if (reviewData['senderID'] == senderID &&
            reviewData['date'] == reviewDate &&
            reviewData['comment'] == reviewComment) {
          reviewKey = key;
          return;
        }
      });

      if (reviewKey.isNotEmpty) {
        // Get the specific review data
        Map<String, dynamic> reviewData = reviewsMap[reviewKey] as Map<String, dynamic>;

        // Update the visibility field
        reviewData['isVisible'] = false;

        // Update the review in the map
        reviewsMap[reviewKey] = reviewData;

        // Update Firestore with the modified reviews map
        await providerRef.update({
          'reviews': reviewsMap
        });

        // Refresh the reviews list
        loadReviews(providerID);
      } else {
        debugPrint('Error: Exact review match not found');
      }

    } catch (e) {
      debugPrint('Error hiding review: $e');
    }
  }

// Function to delete a review (remove it completely from Firestore)
  Future<void> _deleteReview(Map<String, dynamic> review) async {
    try {
      // Get the provider ID
      String providerID = widget.providerId;
      String senderID = review['senderID'];
      String reviewDate = review['date']; // Use date as additional identifier
      String reviewComment = review['comment']; // Use comment as additional identifier

      if (senderID.isEmpty) {
        debugPrint('Error: senderID is empty');
        return;
      }

      // Reference to the provider's reviews document
      DocumentReference providerRef = _db.collection('Reviews').doc(providerID);

      // Get the current document
      DocumentSnapshot providerDoc = await providerRef.get();

      if (!providerDoc.exists) {
        debugPrint('Error: Provider document does not exist');
        return;
      }

      // Get the current data
      Map<String, dynamic> data = providerDoc.data() as Map<String, dynamic>;
      Map<String, dynamic> reviewsMap = data['reviews'] ?? {};

      // Find the exact review using multiple identifiers
      String reviewKey = "";
      reviewsMap.forEach((key, value) {
        Map<String, dynamic> reviewData = value as Map<String, dynamic>;
        // Match on multiple fields to ensure we get exactly the right review
        if (reviewData['senderID'] == senderID &&
            reviewData['date'] == reviewDate &&
            reviewData['comment'] == reviewComment) {
          reviewKey = key;
          return;
        }
      });

      if (reviewKey.isNotEmpty) {
        // Remove the review from the map
        reviewsMap.remove(reviewKey);

        // Update Firestore with the modified reviews map
        await providerRef.update({
          'reviews': reviewsMap
        });

        // Refresh the reviews list
        loadReviews(providerID);
      } else {
        debugPrint('Error: Exact review match not found');
      }

    } catch (e) {
      debugPrint('Error deleting review: $e');
    }
  }
  void SuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        Future.delayed(Duration(seconds: 1), () {
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
                  child: Icon(
                    Icons.check_circle_outline,
                    size: 50,
                    color: Color(0xFF00D47E),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}