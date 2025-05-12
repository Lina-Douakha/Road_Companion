import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:road_companion/screens/admin/Requests-Reviews.dart';
import 'package:road_companion/screens/admin/UserIncidentDetails.dart';





class UserDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const UserDetailsScreen({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  _UserDetailsScreenState createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
// Reused and adapted deleteUser function for UserDetailsScreen
  Future<void> _deleteUser(String userId) async {
    try {
      // 1. Get the user document
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userSnapshot.exists) {
        throw Exception('admin.user_not_found'.tr());
      }

      // 2. Copy data to deleted_users
      await FirebaseFirestore.instance
          .collection('deleted_users')
          .doc(userId)
          .set(userSnapshot.data() as Map<String, dynamic>);

      // 3. Delete from original users collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .delete();

      // 4. Update UI (in this context, we just go back)
      Navigator.pop(context);

      _showUserActionSuccessDialog('delete');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete user: $e')),
      );
    }
  }// Enhanced version of your _toggleBlockUser method
  Future<void> _toggleBlockUser(String userId, bool currentBlockedStatus) async {
    try {
      // Update Firestore
      await _firestore.collection('users').doc(userId).update({
        'isBlocked': !currentBlockedStatus,
      });

      // Update UI
      setState(() {
        // Re-fetch user details to reflect the change
      });

      // Show success message
      _showUserActionSuccessDialog(!currentBlockedStatus ? 'block' : 'unblock');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to toggle block status: $e')),
      );
    }
  }// Updated dialog to confirm block/unblock action for UserDetailsScreen
  void _showBlockDialog(Map<String, dynamic> user, bool isBlocked) {
    final String actionText = isBlocked ? 'admin.Unblock'.tr() : 'admin.Block'.tr();

    final String message = isBlocked
        ? 'admin.unblock_message'.tr()
        : 'admin.block_message'.tr() ;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '$actionText',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 15),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'admin.cancel'.tr(),
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _toggleBlockUser(user['UserID'], isBlocked); // Call the modified _toggleBlockUser
            },
            child: Text(
              actionText,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isBlocked
                  ? const Color(0xFF00D47E).withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              foregroundColor: isBlocked ? const Color(0xFF00D47E) : Colors.amber,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
  // Updated dialog to confirm delete action for UserDetailsScreen
  void _showDeleteDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'admin.Delete'.tr(),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        content:  Text(
          'admin.delete_message'.tr(),
          style: TextStyle(fontSize: 15),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:  Text(
              'admin.cancel'.tr(),
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteUser(user['UserID']); // Call the adapted _deleteUser
            },
            child:  Text(
              'admin.Delete'.tr(),
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.1),
              foregroundColor: Colors.red,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final isDriverRole =  (widget.user['Role'] as String?)?.toLowerCase() == 'user';
    GeoPoint? location = widget.user['Location'];
    final role = widget.user['Role'];
    final key = 'registration.$role';

    return DefaultTabController(
      length: isDriverRole ? 2 : 2, // Adjust tab count based on role
      child: Scaffold(
        backgroundColor: Colors.white,

// Then use it in your build method
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B9169),
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
            statusBarColor: const Color(0xFF1B9169),
          ),
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          flexibleSpace: Builder(
            builder: (context) {
              return FlexibleSpaceBar(
                title: Align(
                  alignment: _isRTL(context) ? Alignment.centerRight : Alignment.centerLeft,
                  child: Text(
                    'admin.profile_title'.tr(namedArgs: {'name': widget.user['Name'] ?? 'User'}),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                titlePadding: _isRTL(context)
                    ? const EdgeInsets.only(right: 56, bottom: 16, left: 100) // RTL padding
                    : const EdgeInsets.only(left: 56, bottom: 16, right: 100), // LTR padding
              );
            },
          ),
          actions: [
            _buildUserStatusActions(context, widget.user['UserID']!),
            const SizedBox(width: 8),
          ],
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'admin.Details'.tr()),
              Tab(text: 'admin.Historique'.tr()),
            ],
          ),
        ),

        body: TabBarView(
          children: [
            // First Tab: Existing User Details UI
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildProfileCard(user: widget.user),

                const SizedBox(height: 24),
                Text(
                  "admin.Personal_Information".tr(),
                  style: Theme
                      .of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold,
                      color: const Color(0xFF1B9169)),
                ),
                Divider(color: Colors.grey[300]),
                _buildInfoCard(
                    context, 'admin.Name'.tr(), widget.user['Name'], icon: Icons.person,
                    valueColor: Colors.grey[600]),
             widget.user['Email']!= null
            ? _buildEmailCard(context, widget.user['Email'])
            : _buildInfoCard(context, 'admin.Email'.tr(), widget.user['Email'], icon: Icons.email),
                widget.user['Email']!= null
                    ?  _buildPhoneCard(context, widget.user['Phone'])
                    : _buildInfoCard(context, 'admin.Phone'.tr(), widget.user['Phone'], icon: Icons.phone),
                _buildInfoCard(
                    context, 'admin.UserID'.tr(), widget.user['UserID'], icon: Icons.tag,
                    valueColor: Colors.grey[600],
                showCopyIcon: true),

                _buildInfoCard(context, 'admin.Role'.tr(), 'registration.${widget.user['Role']}'.tr(),
                    icon: Icons.badge,
                    valueColor: Colors.grey[600]),
                _buildInfoCard(
                  context,
                  'admin.VerifiedAt'.tr(),
                  widget.user['VerifiedAt'] != null
                      ? DateFormat('yyyy-MM-dd HH:mm:ss').format(
                      (widget.user['VerifiedAt'] as Timestamp).toDate())
                      : 'admin.not_available'.tr(),
                  icon: Icons.calendar_today,
                  valueColor: Colors.grey[600],
                ),
                if ((widget.user['Role'] as String?)?.toLowerCase() != 'driver' &&
                    (widget.user['Role'] as String?)?.toLowerCase() != 'user') ...[
                  const SizedBox(height: 24),
                  Text(

           'admin.Informations'.tr(namedArgs: {'role': 'registration.${widget.user['Role']}'.tr()}),

                    style: Theme
                        .of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold,
                        color: const Color(0xFF1B9169)),
                  ),
                  Divider(color: Colors.grey[300]),

                  _buildInfoCard(
                    context,
                    'admin.location'.tr(),
                    location != null
                        ? '${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}'
                        : null,
                    icon: Icons.location_on,
                    valueColor: Colors.grey[600],

                  ),
                  _buildInfoCard(
                    context,
                    'admin.Address'.tr(),widget.user['Address'],
                    icon: Icons.location_on,
                    valueColor: Colors.grey[600],
                  ),
                  _buildInfoCard(
                      context, 'admin.Working_Hours'.tr(), widget.user['Working_hours'],
                      icon: Icons.access_time,
                      valueColor: Colors.grey[600],
                     ),
                  _buildLinkCard(context, 'admin.Link'.tr(), widget.user['Link'],
                      linkColor: Colors.blue),
                  _buildPdfCard(context, 'admin.Carte'.tr(),widget.user['pdf_carte'],
                      pdfColor: Colors.redAccent),
                  _buildPdfCard(context, 'admin.Registration'.tr(), widget.user['pdf_reg'],
                      pdfColor: Colors.redAccent),
                ],
              ],
            ),

            // Second Tab: Conditional Content
            isDriverRole
                ? IncidentHistoryScreen(userId: widget.user['UserID'])
                : RequestReviewsScreen(UserID: widget.user['UserID']),
          ],
        ),
      ),
    );
  }
  Widget _buildProfileCard({
    required Map<String, dynamic>? user,
  }) {
    // Extract userId
    final String? userId = user?['UserID'];

    return FutureBuilder<String>(
      future: determineUserStatus(userId ?? ''),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('admin.Error_loading_status'.tr());
        }
        final String status = snapshot.data ?? 'Unknown';
        final Color statusColor = getStatusUserColor(status);
        final IconData statusIcon = getStatusUserIcon(status);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: user?['ProfilePhoto'] == null
                    ? Colors.grey[400]
                    : Colors.transparent,
                backgroundImage: user?['ProfilePhoto'] != null
                    ? AssetImage(user!['ProfilePhoto'])
                    : null,
                child: user?['ProfilePhoto'] == null
                    ? (user?['Name']?.isNotEmpty ?? false
                    ? Text(
                  user!['Name'][0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )
                    : const Icon(Icons.person, size: 24, color: Colors.white))
                    : null,
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?['Name'] ?? 'admin.No_Name'.tr(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B9169),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                statusIcon,
                                size: 16,
                                color: statusColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                               'admin.$status'.tr() ,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
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
  }



// Get icon for the user status
  IconData getStatusUserIcon(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Icons.check_circle;
      case 'blocked':
        return Icons.block;
      case 'deleted':
        return Icons.delete_forever;
      default:
        return Icons.help_outline;
    }
  }

// Get color for the user status
  Color getStatusUserColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return const Color(0xFF00D47E); // green
      case 'blocked':
        return Colors.amber;
      case 'deleted':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }


  Widget _buildInfoCard(
      BuildContext context,
      String title,
      String? value, {
        IconData? icon,
        Color? valueColor,
        bool showCopyIcon = false, // new param to toggle copy icon
      }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon ?? Icons.info_outline, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        value ?? 'admin.Not_available'.tr(),
                        style: TextStyle(
                          color: valueColor ?? Colors.black54,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (showCopyIcon && value != null)
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        tooltip: 'admin.copy',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: value));

                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildEmailCard(BuildContext context, String email) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.email, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'admin.Email'.tr(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () async {
                    final emailUri = Uri(scheme: 'mailto', path: email);
                    if (await canLaunchUrl(emailUri)) {
                      await launchUrl(emailUri);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                         SnackBar(content: Text('admin.Could_not_launch_email_app'.tr())),
                      );
                    }
                  },
                  child: Text(
                    email,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildLinkCard(BuildContext context, String title, String? url,
      {Color? linkColor}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
       // border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.link, color: linkColor ?? Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  url ?? 'admin.Not_available'.tr(),
                  style: TextStyle(
                    color: linkColor ?? Colors.blue,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (url != null)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: (linkColor ?? Colors.blue).withOpacity(0.1),
                foregroundColor: linkColor ?? Colors.blue,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.open_in_browser, size: 18),
              label:  Text('admin.Open'.tr(), style: TextStyle(fontSize: 12)),
              onPressed: () async {
                final Uri uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(content: Text('admin.Could_not_launch_URL'.tr())),
                  );
                }
              },

            ),
        ],
      ),
    );
  }
  Widget _buildPdfCard(BuildContext context, String title, String? pdfUrl, {Color? pdfColor}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.picture_as_pdf, color: pdfColor ?? Colors.redAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  pdfUrl ?? 'admin.Not_uploaded'.tr(),
                  style: TextStyle(
                    color: pdfColor ?? Colors.redAccent,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (pdfUrl != null)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: (pdfColor ?? Colors.redAccent).withOpacity(0.1),
                foregroundColor: pdfColor ?? Colors.redAccent,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.visibility, size: 18),
              label:  Text('admin.View'.tr(), style: TextStyle(fontSize: 12)),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(content: Text('admin.PDF_viewing_not_yet_implemented'.tr())),
                );
              },
            ),
        ],
      ),
    );
  }

  Future<String> determineUserStatus(String userId) async {
    // Reference to your Firestore users collection
    final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);

    // Try fetching the user document
    final docSnapshot = await userDoc.get();

    // If the user document doesn't exist, consider the user as "Deleted"
    if (!docSnapshot.exists) {
      return 'Deleted';
    }

    // If the user exists, check if they are blocked
    final user = docSnapshot.data();
    if (user != null && user['isBlocked'] == true) {
      return 'Blocked';
    }

    // Default is "Active" if the user is not blocked
    return 'Active';
  }
  Widget _buildUserStatusActions(BuildContext context, String userId) {
    return FutureBuilder<String>(
      future: determineUserStatus(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B9169)),
            ),
          );
        }

        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final status = snapshot.data ?? 'Active';
        final isCurrentlyBlocked = widget.user['isBlocked'] == true;

        if (status == 'Deleted') {
          return const SizedBox.shrink();
        }

        if (status == 'Active') {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.lock, color: Colors.white), // Use lock icon for blocking
                tooltip: 'Block User',
                onPressed: () => _showBlockDialog(widget.user, false),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.white),
                tooltip: 'Delete User',
                onPressed: () => _showDeleteDialog(widget.user),
              ),
            ],
          );
        }

        if (status == 'Blocked') {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.lock_open_outlined, color: Colors.white), // Use open lock for unblocking
                tooltip: 'Unblock User',
                onPressed: () => _showBlockDialog(widget.user, true),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.white),
                tooltip: 'Delete User',
                onPressed: () => _showDeleteDialog(widget.user),
              ),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildPhoneCard(BuildContext context, String phoneNumber) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.phone, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Text(
                  'admin.Phone'.tr(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () async {
                    final phoneUri = Uri(scheme: 'tel', path: phoneNumber);
                    if (await canLaunchUrl(phoneUri)) {
                      await launchUrl(phoneUri);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('admin.Could_not_launch_phone_app'.tr())),
                      );
                    }
                  },
                  child: Text(
                    phoneNumber,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// Show success dialog with custom message based on user actions
  void _showUserActionSuccessDialog(String actionType) {
    String message;
    Color iconColor;
    IconData iconData;

    switch (actionType.toLowerCase()) {
      case 'block':
        message = 'admin.user_successfully_blocked'.tr();
        iconColor = Colors.amber;
        iconData = Icons.block;
        break;
      case 'unblock':
        message = 'admin.user_successfully_unblocked'.tr();
        iconColor = const Color(0xFF00D47E); // Green
        iconData = Icons.check_circle;
        break;
      case 'delete':
        message = 'admin.user_successfully_deleted'.tr();
        iconColor = Colors.red;
        iconData = Icons.delete_forever;
        break;
      default:
        message = 'admin.action_completed_successfully'.tr();
        iconColor = Colors.blue;
        iconData = Icons.check_circle;
    }

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
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    iconData,
                    color: iconColor,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: iconColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text('admin.OK'.tr()),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  bool _isRTL(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'ar';
  }


}




  extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this; // or return '' depending on what you prefer
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}




