import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  final ScrollController scrollController = ScrollController();
  @override
  void initState() {
    super.initState();
    loadReviews(widget.providerId);
  }
  Future<void> loadReviews(String providerID) async {
    try {
      final providerRef = _db.collection('Reviews').doc(providerID);
      final providerDoc = await providerRef.get();

      if (!providerDoc.exists) {
        setState(() {
          status = '❌ Document does not exist!';
          isLoading = false;
        });
        return;
      }

      final data       = providerDoc.data() as Map<String, dynamic>;
      final reviewsMap = data['reviews'] as Map<String, dynamic>? ?? {};

      setState(() {
        reviews = reviewsMap.entries.map((entry) {
          final v = entry.value as Map<String, dynamic>;

          // **Pull the real bool straight from Firestore:**
          final bool isVisible = v.containsKey('isVisible')
              ? (v['isVisible'] as bool)
              : true;  // (fallback if somehow missing)

          return {
            'name'      : v['name']     ?? 'No Name',
            'image'     : v['image']    ?? '',
            'rating'    : (v['rating'] is num)
                ? (v['rating'] as num).toDouble()
                : 0.0,
            'comment'   : v['comment']  ?? 'No comment',
            'date'      : v['date']     ?? 'No date',
            'senderID'  : v['senderID'] ?? '',

            // ← **This is the key addition**:
            'isVisible' : isVisible,
          };
        }).toList();

        status    = reviews.isEmpty ? '❌ No reviews found.' : '✅ Reviews loaded!';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        status    = '❌ Error: $e';
        isLoading = false;
      });
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
          'Provider Reviews',
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
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Provider ID: ${widget.providerId}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
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
                color: Color(0xFF00D47E), // Replace with any color you want
              ),
            )
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
                    onTap: () {
                // Handle tap on provider card
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
                                    ? NetworkImage(review['image'])
                                    : null,
                                child: review['image'] == null || review['image'].isEmpty
                                    ? Text(
                                  review['name'][0].toUpperCase(),
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
                                      review['name'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      review['date'],
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
                                      color:Colors.white,
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
                            review['comment'],
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
                                  'Moderate',
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
                                  'Manage User',
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
                        color: Colors.blueAccent,
                        size: 28,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Manage User',
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
                    'Choose an action for this user:',
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
                          'Send Warning',
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
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Implement block user functionality
                          Navigator.pop(context);
                          SuccessDialog(context, "User blocked successfully!");
                        },
                        icon: Icon(
                          Icons.block,
                          color: Colors.red,
                          size: 20,
                        ),
                        label: Text(
                          'Block User',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[50],
                          padding: EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),


                    SizedBox(height: 16),

                    // Cancel action
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Cancel',
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
        text: "Your recent comment has been flagged for not following our community guidelines. Please remember to keep all interactions respectful and appropriate. Continued violations may result in account restrictions."
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
                            'Send Warning',
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
                          'Enter a message to warn this user:',
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
                            selectionColor: Colors.orange[100], // optional, for selected text background
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
                            hintText: 'Write your warning message here...',
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
                                                Text("Sending warning..."),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );

                                    // Get current admin user ID
                                    final currentAdmin = FirebaseAuth.instance.currentUser;
                                    final adminId = currentAdmin?.uid ?? 'unknown_admin';

                                    // Add warning data to user's document
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

                                    // Close loading indicator
                                    Navigator.pop(context);

                                    // Close warning dialog
                                    Navigator.pop(context);

                                    // Show success message
                                    SuccessDialog(context, "Warning sent successfully");
                                  } catch (e) {
                                    // Close loading indicator
                                    Navigator.pop(context);

                                    // Show error message
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to send warning: ${e.toString()}',
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
                                  // Show error for empty message
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Please enter a warning message',
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
                                'Send Warning',
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
                              'Cancel',
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
              'Moderate Review',
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
                          'User:',
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
                          'Rating:',
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
                  'Moderation Actions',
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
                    'Cancel',
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
                       SuccessDialog(context, "Review hidden successfully!");
                     }else {
                       SuccessDialog(context, "Review unhidden successfully!");
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
                    (review['isVisible'] == true) ? 'Hide' : 'Unhide',
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
                    SuccessDialog(context, "Review deleted successfully!");
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.red[50],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Delete',
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
        print("//////////////");
        print(reviewData['senderID']);
        print(reviewData['date']);
        print(reviewData['comment']);
        print("//////////////");
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

