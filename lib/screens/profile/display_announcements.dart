import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AnnouncementsScreen extends StatefulWidget {
  final String currentUserRole;
  final String currentUserId;

  const AnnouncementsScreen({
    Key? key,
    required this.currentUserRole,
    required this.currentUserId,
  }) : super(key: key);

  @override
  _AnnouncementsScreenState createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  late Stream<QuerySnapshot> _announcementsStream;
  final DateFormat _dateFormat = DateFormat('MMM d, yyyy • h:mm a');
  Set<String> _seenAnnouncementIds = {};
  bool _isLoading = true;
  bool _showUnreadOnly = false;

  @override
  void initState() {
    super.initState();
    _loadSeenAnnouncements();
    _setupAnnouncementsStream();
  }

  Future<void> _loadSeenAnnouncements() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get the user's seen announcements from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserId)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        List<dynamic> seenAnnouncements = userData['seenAnnouncements'] ?? [];
        _seenAnnouncementIds = Set<String>.from(seenAnnouncements.map((id) => id.toString()));
      }
    } catch (e) {
      print('Error loading seen announcements: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _setupAnnouncementsStream() {
    _announcementsStream = FirebaseFirestore.instance
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  bool _isAnnouncementForUser(DocumentSnapshot document) {
    final data = document.data() as Map<String, dynamic>;
    final audience = data['audience'];

    if (audience == "All") {
      return true;
    }

    if (audience is List && audience.contains(widget.currentUserRole)) {
      return true;
    }

    return false;
  }

  String _getMessagePreview(String message) {
    if (message.length <= 100) {
      return message;
    }
    return '${message.substring(0, 100)}...';
  }

  Future<void> _markAnnouncementAsSeen(String announcementId) async {
    if (_seenAnnouncementIds.contains(announcementId)) {
      // Already marked as seen
      return;
    }

    // Add to local set for immediate UI update
    setState(() {
      _seenAnnouncementIds.add(announcementId);
    });

    try {
      // Update in Firestore using arrayUnion to add to the array
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserId)
          .set({
        'seenAnnouncements': FieldValue.arrayUnion([announcementId])
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error marking announcement as seen: $e');
      // Revert local change if Firestore update fails
      setState(() {
        _seenAnnouncementIds.remove(announcementId);
      });
    }
  }

  void _showFullAnnouncement(String announcementId, Map<String, dynamic> announcement) async {
    // Mark the announcement as seen
    await _markAnnouncementAsSeen(announcementId);

    // Navigate to details screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnnouncementDetailsScreen(
          announcementId: announcementId,
          announcementData: announcement,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          _showUnreadOnly ? 'Unread Announcements' : 'Announcements',
          style: TextStyle(
            color: Color(0xFF1B9169),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        iconTheme: IconThemeData(color: Color(0xFF1B9169)),
        actions: [

          // Filter button to toggle showing all vs only unread
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () {
              _showFilterOptions();
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D47E)),
        ),
      )
          : StreamBuilder<QuerySnapshot>(
        stream: _announcementsStream,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
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
                    'Error: ${snapshot.error}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D47E)),
              ),
            );
          }

          // First filter based on user role
          final roleFilteredDocs = snapshot.data!.docs
              .where((doc) => _isAnnouncementForUser(doc))
              .toList();

          // Then apply the unread filter if needed
          final filteredDocs = _showUnreadOnly
              ? roleFilteredDocs.where((doc) => !_seenAnnouncementIds.contains(doc.id)).toList()
              : roleFilteredDocs;

          if (filteredDocs.isEmpty) {
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
                    'No announcements available for you',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            itemCount: filteredDocs.length,
            itemBuilder: (context, index) {
              DocumentSnapshot document = filteredDocs[index];
              Map<String, dynamic> data = document.data() as Map<String, dynamic>;
              String id = document.id;

              String title = data['title'] ?? 'Untitled';
              String message = data['message'] ?? 'No content';
              Timestamp createdAt = data['createdAt'] ?? Timestamp.now();
              String formattedDate = _dateFormat.format(createdAt.toDate());
              String postedBy = data['createdBy'] ?? 'Admin';

              // Check if announcement is seen
              bool isSeen = _seenAnnouncementIds.contains(id);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                    color: isSeen ? Colors.transparent : Color(0xFF1B9169),
                    width: isSeen ? 0 : 1.5,
                  ),
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
                        Stack(
                          children: [
                            Icon(
                              Icons.campaign_outlined,
                              color: Color(0xFF1B9169),
                              size: 20,
                            ),
                            if (!isSeen)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    fontWeight: isSeen ? FontWeight.normal : FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              if (!isSeen)
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF1B9169).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'NEW',
                                    style: TextStyle(
                                      color: Color(0xFF1B9169),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
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
                          if (data['imageUrl'] != null)
                            Container(
                              height: 160,
                              width: double.infinity,
                              margin: EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  image: NetworkImage(data['imageUrl']),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          SizedBox(height: 8),
                          Text(
                            _getMessagePreview(message),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              height: 1.3,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () => _showFullAnnouncement(id, data),
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFD1FADF),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'View Details',
                                    style: TextStyle(
                                      color: Color(0xFF00D47E),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              if (isSeen)
                                Row(
                                  children: [
                                    Icon(
                                      Icons.visibility,
                                      size: 16,
                                      color: Colors.grey[500],
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Seen',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
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
      ),
    );
  }void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      builder: (context) {
        // Get the available height for the bottom sheet
        final mediaQuery = MediaQuery.of(context);
        final availableHeight = mediaQuery.size.height * 0.85;

        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: availableHeight),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: 20 + mediaQuery.padding.bottom
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar at top
                  Center(
                    child: Container(
                      width: 50,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color(0xFFEEFCF6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.filter_list,
                          size: 22,
                          color: Color(0xFF1B9169),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Filter Announcements',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1B9169),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Show All option
                  _buildFilterOption(
                    title: 'Show All Announcements',
                    subtitle: 'Display both read and unread',
                    icon: Icons.list_alt,
                    isSelected: !_showUnreadOnly,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _showUnreadOnly = false;
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  // Show Unread Only option
                  _buildFilterOption(
                    title: 'Show Unread Only',
                    subtitle: 'Display only new announcements',
                    icon: Icons.mark_email_unread_outlined,
                    isSelected: _showUnreadOnly,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _showUnreadOnly = true;
                      });
                    },
                  ),

                  const SizedBox(height: 12),


                  // Mark All as Read
                  _buildActionOption(
                    title: 'Mark All as Read',
                    subtitle: 'Clear all unread notifications',
                    icon: Icons.done_all,
                    onTap: () async {
                      Navigator.pop(context);
                      await _markAllAsSeen();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required bool isSelected,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? Color(0xFFEEFCF6) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Color(0xFF1B9169).withOpacity(0.3) : Colors.grey[200]!,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? Color(0xFF1B9169).withOpacity(0.15) : Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: isSelected ? Color(0xFF1B9169) : Colors.grey[700],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? Color(0xFF1B9169) : Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Color(0xFF1B9169),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[200]!,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFFD1FADF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: Color(0xFF00D47E),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
  Future<void> _markAllAsSeen() async {
    // Get all announcement IDs that are for this user
    QuerySnapshot announcements = await FirebaseFirestore.instance
        .collection('announcements')
        .get();

    List<String> announcementIds = announcements.docs
        .where((doc) => _isAnnouncementForUser(doc))
        .map((doc) => doc.id)
        .toList();

    if (announcementIds.isEmpty) {
      return;
    }

    // Add all to local set for immediate UI update
    setState(() {
      _seenAnnouncementIds.addAll(announcementIds);
    });

    try {
      // Update in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserId)
          .set({
        'seenAnnouncements': FieldValue.arrayUnion(announcementIds)
      }, SetOptions(merge: true));

      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All announcements marked as read'),
          backgroundColor: Color(0xFF1B9169),
        ),
      );
    } catch (e) {
      print('Error marking all announcements as seen: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to mark announcements as read'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class AnnouncementDetailsScreen extends StatelessWidget {
  final String announcementId;
  final Map<String, dynamic> announcementData;
  final DateFormat _dateFormat = DateFormat('MMMM d, yyyy • h:mm a');

  AnnouncementDetailsScreen({
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
      formattedDate = _dateFormat.format(timestamp.toDate());
    }

    // Format audience for display
    String audienceDisplay = 'Unknown';
    if (announcementData['audience'] == 'All') {
      audienceDisplay = 'All Users';
    } else if (announcementData['audience'] is List) {
      audienceDisplay = (announcementData['audience'] as List).join(', ');
    }

    String title = announcementData['title'] ?? 'Untitled';
    String message = announcementData['message'] ?? 'No content';
    String postedBy = announcementData['createdBy'] ?? 'Admin';

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
                        title,
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
                        title,
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
                          'Posted by $postedBy',
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
                      message,
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
}