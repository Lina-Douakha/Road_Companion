import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:road_companion/screens/incident_reporting/map_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/date_symbol_data_local.dart';

class IncidentDetailsScreen extends StatefulWidget {
  final String incidentId;


  const IncidentDetailsScreen({Key? key, required this.incidentId}) : super(key: key);

  @override
  State<IncidentDetailsScreen> createState() => _IncidentDetailsScreenState();
}

class _IncidentDetailsScreenState extends State<IncidentDetailsScreen> {
  late Future<DocumentSnapshot<Map<String, dynamic>>> _incidentFuture;

  @override
  void initState() {
    super.initState();
    _incidentFuture = FirebaseFirestore.instance
        .collection('Incident Reports')
        .doc(widget.incidentId)
        .get();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _fetchIncidentDetails() async {
    return FirebaseFirestore.instance.collection('Incident Reports').doc(widget.incidentId).get();
  }Future<void> _markAsResolved(BuildContext context) async {
    try {
      // Update the status and add the resolvedAt field with the current timestamp
      await FirebaseFirestore.instance
          .collection('Incident Reports')
          .doc(widget.incidentId)
          .update({
        'Status': 'Resolved',       // Update status to Resolved
        'resolvedAt': FieldValue.serverTimestamp(), // Add the resolvedAt field with the server timestamp
      });

      // Show the success dialog
      _showSuccessDialog(context);

      // Optionally, show a SnackBar for quick feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incident marked as resolved')),
      );
    } catch (e) {
      // Show an error message in case of failure
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing dialog on tap outside
      builder: (context) {
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
                  'Incident marked as resolved',
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

    // Automatically close the dialog after 2 seconds
    Future.delayed(Duration(seconds: 2), () {
      Navigator.of(context).pop();
    });
  }

// Success Dialog UI with better styling and smoother experience
  void SuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing dialog on tap outside
      builder: (context) {
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
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );

    // Automatically close the dialog after 2 seconds
    Future.delayed(Duration(seconds: 2), () {
      Navigator.of(context).pop();
    });
  }

// Updated _confirmDelete method with enhanced confirmation dialog and rejectedAt field
  Future<void> _confirmDelete(BuildContext context) async {
    print('Confirm delete: ${widget.incidentId}');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "Confirm Rejection",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: const Text(
            "Are you sure you want to reject this incident?",
            style: TextStyle(fontSize: 16),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.blue),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                "Reject",
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await FirebaseFirestore.instance
                      .collection('Incident Reports') // Ensure this matches your collection name
                      .doc(widget.incidentId)
                      .update({
                    'Status': 'Rejected', // Update status to 'Rejected'
                    'rejectedAt': FieldValue.serverTimestamp(), // Add rejectedAt field with timestamp
                  });

                  // Show the success dialog
                  SuccessDialog(context, 'Incident marked as rejected');
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error rejecting incident: $e')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: const Color(0xFF1B9169),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1B9169)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Incident Details",
          style: TextStyle(
            color: Color(0xFF1B9169),
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _incidentFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Something went wrong: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF1B9169)));
          }
          if (!snapshot.hasData || snapshot.data == null || !snapshot.data!.exists) {
            return const Center(child: Text('Incident details not found.'));
          }

          Map<String, dynamic> incident = snapshot.data!.data()!;
          final category = incident['Type'] ?? 'Unknown';
          final status = incident['Status'] ?? 'Pending';
          final description = incident['Description'] ?? '';
          final location = incident['Address'] ?? _getLocationFromCoordinates(incident['Location']);
          final coordinates = incident['Location'];
          final date = incident['ReportTime'] is Timestamp
              ? (incident['ReportTime'] as Timestamp).toDate()
              : null;
          final imageUrl = incident['ImageURL'];
          final userID = incident['UserID'];
          final resolvedAt = incident['resolvedAt']; // New field for resolved time
          final rejectedAt = incident['rejectedAt']; // New field for rejected time

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIncidentHeader(
                  category: category,
                  status: status,
                ),
                const SizedBox(height: 10),

                if (coordinates != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MapPage(
                              incidents: [incident],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.map_outlined, size: 18, color: Color(0xFF1B9169)),
                            const SizedBox(width: 4),
                            Text(
                              'View Map'.tr(),
                              style: const TextStyle(fontSize: 14, color: Color(0xFF1B9169)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),


                // Description
                if (description.isNotEmpty)
                  _buildInfoCard(
                    context,
                    'Description'.tr(),
                    description,
                    icon: Icons.description,
                  ),

                // Reported Date
                if (date != null)
                  _buildInfoCard(
                    context,
                    'Reported On'.tr(),
                    _formatDate(context, date),
                    icon: Icons.calendar_today,
                  ),

                // UserID
                if (userID.isNotEmpty)
                  _buildInfoCard(
                    context,
                    'Reported By'.tr(),
                    userID,
                    icon: Icons.person_outline,
                    showCopyIcon: true, // Let user copy UserID easily
                  ),

                // Location
                if (location != null)
                  _buildInfoCard(
                    context,
                    'Location'.tr(),
                    location,
                    icon: Icons.location_on_outlined,
                    showCopyIcon: true,
                  ),



                // Image
                if (imageUrl != null) ...[
                  const Text(
                    "Attached Image",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 150,
                          color: Colors.grey[300],
                          child: const Center(child: Icon(Icons.broken_image)),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

              //  const SizedBox(height: 20),

                // Conditionally render based on status
                if (status == 'Pending') ...[
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Mark as Resolved Button
                      ElevatedButton.icon(
                        onPressed: () => _markAsResolved(context),
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text("Mark Resolved", style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00D47E), // Green background
                          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 5,
                        ),
                      ),

                      // Reject Button
                      OutlinedButton.icon(
                        onPressed: () => _confirmDelete(context),
                        icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                        label: const Text("Reject", style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red, width: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          textStyle: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ] else if (status == 'Resolved') ...[
                  // Resolved At Card
                  if (resolvedAt != null)
                    _buildInfoCard(
                      context,
                      'Resolved At'.tr(),
                      _formatDate(context, resolvedAt.toDate()),
                      icon: Icons.check_circle_outline,
                    ),
                ] else if (status == 'Rejected') ...[
                  // Rejected At Card
                  if (rejectedAt != null)
                    _buildInfoCard(
                      context,
                      'Rejected At'.tr(),
                      _formatDate(context, rejectedAt.toDate()),
                      icon: Icons.cancel_outlined,
                    ),
                ],

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'resolved': return Colors.green;
      case 'rejected': return Colors.red;
      case 'inprogress': return Colors.blue;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Icons.access_time;
      case 'resolved': return Icons.check_circle;
      case 'rejected': return Icons.cancel;
      case 'inprogress': return Icons.build;
      default: return Icons.help_outline;
    }
  }

  String _formatDate(BuildContext context, DateTime date) {
    final locale = context.locale.toString();
    final format = DateFormat.yMMMMd(locale).add_jm();
    return format.format(date);
  }

  String _getLocationFromCoordinates(GeoPoint? coordinates) {
    if (coordinates == null) return 'Custom location';
    return 'Lat: ${coordinates.latitude.toStringAsFixed(4)}, Lng: ${coordinates.longitude.toStringAsFixed(4)}';
  }

// This function builds a card with information
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

// Function to get the incident icon path
  String _getIncidentTypeIconPath(String category) {
    final incidentTypes = {
      'accident': 'assets/GPS/accident_icon.png',
      'breakdown': 'assets/GPS/breakdown_icon.png',
      'Road_Blockages': 'assets/GPS/circulation.png',
      'Roadwork': 'assets/GPS/roadwork.png',
      'Special_Events': 'assets/GPS/event.png',
      'other': 'assets/GPS/other.png',
    };

    return incidentTypes[category] ?? 'assets/GPS/other.png';
  }

// This function builds the header for an incident
  Widget _buildIncidentHeader({
    required String category,
    required String status,
  }) {
    final Color statusColor = _getStatusColor(status);  // Define this method for status color
    final String iconPath = _getIncidentTypeIconPath(category);
    final String translationKey = _getIncidentTranslationKey(category); // Assume translation key function is implemented

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
          Image.asset(
            iconPath,
            width: 32,
            height: 32,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  translationKey.tr(),  // Using translation here
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B9169),
                  ),
                ),
                const SizedBox(height: 6),
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
                        _getStatusIcon(status),
                        size: 16,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'incident_report.$status'.tr(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      )

                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  String _getIncidentTranslationKey(String category) {
    return 'incident_report.$category';
  }



/*
  void _viewAllIncidentsOnMap() {
    Navigator.push
      context,
      MaterialPageRoute(
        builder: (context) => MapPage(
          incidents: .where((i) => i['coordinates'] != null).toList(),
        ),
      ),
    );
  } */


}