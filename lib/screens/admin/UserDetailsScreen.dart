import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'Requests-Reviews.dart';
import 'UserIncidentDetails.dart';



class UserDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> user;



  const UserDetailsScreen({
    Key? key,
    required this.user,


  }) : super(key: key);




  @override
  Widget build(BuildContext context) {
    final isDriverRole =  (user['Role'] as String?)?.toLowerCase() == 'user';
    GeoPoint? location = user['Location'];

    return DefaultTabController(
      length: isDriverRole ? 2 : 2, // Adjust tab count based on role
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
            statusBarColor: const Color(0xFF1B9169),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: const Color(0xFF1B9169)),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            "${user['Name'] ?? 'User'}'s Profile",
            style: const TextStyle(
              color: Color(0xFF1B9169),
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: TabBar(
            labelColor: Color(0xFF1B9169),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF1B9169),
            indicatorWeight: 3,
            tabs: [
              const Tab(text: 'Details'),
              Tab(text: isDriverRole ? 'Incidents' : 'Historique Requests'.tr()),
            ],
          ),

        ),
        body: TabBarView(
          children: [
            // First Tab: Existing User Details UI
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildProfileCard(user: user),

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
                    context, 'Name'.tr(), user['Name'], icon: Icons.person,
                    valueColor: Colors.grey[600]),
                _buildInfoCard(
                    context, 'Email'.tr(), user['Email'], icon: Icons.email,
                    valueColor: Colors.grey[600]),
                _buildInfoCard(
                    context, 'Phone'.tr(), user['Phone'], icon: Icons.phone,
                    valueColor: Colors.grey[600]),
                _buildInfoCard(
                    context, 'UserID'.tr(), user['UserID'], icon: Icons.tag,
                    valueColor: Colors.grey[600],
                showCopyIcon: true),
                _buildInfoCard(context, 'registration.Role'.tr(), user['Role'],
                    icon: Icons.badge,
                    valueColor: Colors.grey[600]),
                _buildInfoCard(
                  context,
                  'Verified At'.tr(),
                  user['VerifiedAt'] != null
                      ? DateFormat('yyyy-MM-dd HH:mm:ss').format(
                      (user['VerifiedAt'] as Timestamp).toDate())
                      : 'Not available'.tr(),
                  icon: Icons.calendar_today,
                  valueColor: Colors.grey[600],
                ),
                if ((user['Role'] as String?)?.toLowerCase() != 'driver' &&
                    (user['Role'] as String?)?.toLowerCase() != 'user') ...[
                  const SizedBox(height: 24),
                  Text(
                    "${(user['Role'] as String?)?.capitalize()} Information"
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
                    'Address'.tr(),user['Address'],
                    icon: Icons.location_on,
                    valueColor: Colors.grey[600],
                  ),
                  _buildInfoCard(
                      context, 'Working Hours'.tr(), user['Working_hours'],
                      icon: Icons.access_time,
                      valueColor: Colors.grey[600],
                     ),
                  _buildLinkCard(context, 'Link'.tr(), user['Link'],
                      linkColor: Colors.blue),
                  _buildPdfCard(context, 'Carte'.tr(), user['pdf_carte'],
                      pdfColor: Colors.redAccent),
                  _buildPdfCard(context, 'Registration'.tr(), user['pdf_reg'],
                      pdfColor: Colors.redAccent),
                ],
              ],
            ),

            // Second Tab: Conditional Content
            isDriverRole
                ? IncidentHistoryScreen(userId: user['UserID'])
                : RequestReviewsScreen(UserID: user['UserID']),
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
        return const Color(0xF023AC7F); // green
      case 'blocked':
        return Colors.redAccent;
      case 'deleted':
        return Colors.grey;
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
                  await _updateUserID(user['UserID'], newValue);
                } else {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user['UserID'])
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
                if (user['UserID'] == null) {
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
                      .doc(user['UserID'])
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


}

  extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this; // or return '' depending on what you prefer
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}





