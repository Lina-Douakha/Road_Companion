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
        throw Exception('User not found.');
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User moved to deleted_users and removed.')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User ${!currentBlockedStatus ? 'blocked' : 'active'} successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to toggle block status: $e')),
      );
    }
  }

// Updated dialog to confirm block/unblock action for UserDetailsScreen
  void _showBlockDialog(Map<String, dynamic> user, bool isBlocked) {
    final String actionText = isBlocked ? "Unblock" : "Block";
    final Color actionColor = isBlocked
        ? const Color(0xFF00D47E)
        : Colors.red;

    final String message = isBlocked
        ? 'Are you sure you want to unblock "${user['Name']}"?'
        : 'Are you sure you want to block "${user['Name']}"?\n\nThis will immediately prevent the user from logging in again until unblocked.';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '$actionText User',
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
            child: const Text(
              'Cancel',
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
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isBlocked ? const Color(0xFF1B9169) : Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isBlocked
                  ? const Color(0xFF00D47E).withOpacity(0.1)
                  : Colors.red,
              foregroundColor: isBlocked ? const Color(0xFF00D47E) : Colors.white,
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
        title: const Text(
          'Delete User',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        content: const Text(
          'Are you sure you want to permanently delete this user?',
          style: TextStyle(fontSize: 15),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteUser(user['UserID']); // Call the adapted _deleteUser
            },
            child: const Text(
              'Delete',
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

    return DefaultTabController(
      length: isDriverRole ? 2 : 2, // Adjust tab count based on role
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B9169),
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false, // Important for left alignment within FlexibleSpaceBar
          systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
            statusBarColor: const Color(0xFF1B9169),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          flexibleSpace: FlexibleSpaceBar(
            title: Align(
              alignment: Alignment.centerLeft, // Align title to the left within FlexibleSpaceBar
              child: Text(
                "${widget.user['Name'] ?? 'User'}'s Profile",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis, // Handle long titles with ellipsis
              ),
            ),
            titlePadding: const EdgeInsets.only(left: 56, bottom: 16), // Adjust padding as needed
          ),
          actions: [
            _buildUserStatusActions(context, widget.user['UserID']!),
            const SizedBox(width: 8),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'Details'),
              Tab(text: 'Historique'),
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
                  "Personal Information".tr(),
                  style: Theme
                      .of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold,
                      color: const Color(0xFF1B9169)),
                ),
                Divider(color: Colors.grey[300]),
                _buildInfoCard(
                    context, 'Name'.tr(), widget.user['Name'], icon: Icons.person,
                    valueColor: Colors.grey[600]),
             widget.user['Email']!= null
            ? _buildEmailCard(context, widget.user['Email'])
            : _buildInfoCard(context, 'Email'.tr(), widget.user['Email'], icon: Icons.email),
                widget.user['Email']!= null
                    ?  _buildPhoneCard(context, widget.user['Phone'])
                    : _buildInfoCard(context, 'Phone'.tr(), widget.user['Phone'], icon: Icons.phone),
                _buildInfoCard(
                    context, 'UserID'.tr(), widget.user['UserID'], icon: Icons.tag,
                    valueColor: Colors.grey[600],
                showCopyIcon: true),
                _buildInfoCard(context, 'registration.Role'.tr(), widget.user['Role'],
                    icon: Icons.badge,
                    valueColor: Colors.grey[600]),
                _buildInfoCard(
                  context,
                  'Verified At'.tr(),
                  widget.user['VerifiedAt'] != null
                      ? DateFormat('yyyy-MM-dd HH:mm:ss').format(
                      (widget.user['VerifiedAt'] as Timestamp).toDate())
                      : 'Not available'.tr(),
                  icon: Icons.calendar_today,
                  valueColor: Colors.grey[600],
                ),
                if ((widget.user['Role'] as String?)?.toLowerCase() != 'driver' &&
                    (widget.user['Role'] as String?)?.toLowerCase() != 'user') ...[
                  const SizedBox(height: 24),
                  Text(
                    "${(widget.user['Role'] as String?)?.capitalize()} Information"
                        .tr(),
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
                    'Location'.tr(),
                    location != null
                        ? '${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}'
                        : null,
                    icon: Icons.location_on,
                    valueColor: Colors.grey[600],

                  ),
                  _buildInfoCard(
                    context,
                    'Address'.tr(),widget.user['Address'],
                    icon: Icons.location_on,
                    valueColor: Colors.grey[600],
                  ),
                  _buildInfoCard(
                      context, 'Working Hours'.tr(), widget.user['Working_hours'],
                      icon: Icons.access_time,
                      valueColor: Colors.grey[600],
                     ),
                  _buildLinkCard(context, 'Link'.tr(), widget.user['Link'],
                      linkColor: Colors.blue),
                  _buildPdfCard(context, 'Carte'.tr(),widget.user['pdf_carte'],
                      pdfColor: Colors.redAccent),
                  _buildPdfCard(context, 'Registration'.tr(), widget.user['pdf_reg'],
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
          return const Text('Error loading status');
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
                      user?['Name'] ?? 'No Name',
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
                                status,
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
                        value ?? 'Not available',
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
                        tooltip: 'Copy',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: value));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Copied to clipboard')),
                          );
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
                const Text(
                  'Email',
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
                        const SnackBar(content: Text('Could not launch email app')),
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

  void _showEditDialog(BuildContext context, String fieldLabel, String fieldKey,
      String currentValue) {
    final TextEditingController controller = TextEditingController(
        text: currentValue);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit $fieldLabel'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: fieldLabel),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () async {
                final newValue = controller.text.trim();

                if (newValue.isEmpty || newValue == currentValue) {
                  Navigator.of(context).pop();
                  return;
                }

                if (fieldKey == 'UserID') {
                  await _updateUserID(widget.user['UserID'], newValue);
                } else {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(widget.user['UserID'])
                      .update({fieldKey: newValue});
                }

                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showEditRoleDialog(BuildContext context, String currentRole) {
    final List<String> roles = [
      'User',
      'mechanic',
      'towing_service',
      'parts_supplier'
    ];
    String selectedRole = currentRole;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Role'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return DropdownButtonFormField<String>(
                value: selectedRole,
                items: roles.map((role) {
                  return DropdownMenuItem<String>(
                    value: role,
                    child: Text(role),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedRole = value;
                    });
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Select Role',
                  border: OutlineInputBorder(),
                ),
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context),
                child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                if (widget.user['UserID'] == null) {
                  print("Error: User ID is null. Cannot update role.");
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text(
                        "Error: Could not update role (User ID missing).")),
                  );
                  return;
                }
                try {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(widget.user['UserID'])
                      .update({'Role': selectedRole});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Role updated successfully")),
                  );
                } catch (e) {
                  print("Firestore update error: $e"); // Added for debugging
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to update role: $e")),
                  );
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateUserID(String oldUserID, String newUserID) async {
    try {
      final usersRef = FirebaseFirestore.instance.collection('users');

      final oldDoc = await usersRef.doc(oldUserID).get();
      if (!oldDoc.exists) throw Exception("Old document not found");

      final userData = oldDoc.data()!;
      userData['UserID'] = newUserID;

      await usersRef.doc(newUserID).set(userData);
      await usersRef.doc(oldUserID).delete();

      print("UserID updated successfully.");
    } catch (e) {
      print("Error updating UserID: $e");
    }
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
                  url ?? 'Not available',
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
              label: const Text('Open', style: TextStyle(fontSize: 12)),
              onPressed: () async {
                final Uri uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not launch URL')),
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
                  pdfUrl ?? 'Not uploaded',
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
              label: const Text('View', style: TextStyle(fontSize: 12)),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PDF viewing not yet implemented')),
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
                const Text(
                  'Phone',
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
                        const SnackBar(content: Text('Could not launch phone app')),
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

}




  extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this; // or return '' depending on what you prefer
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}




