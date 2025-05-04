import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:road_companion/screens/incident_reporting/map_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class IncidentDetailsScreen extends StatefulWidget {
  final String incidentId;

  const IncidentDetailsScreen({Key? key, required this.incidentId}) : super(key: key);

  @override
  State<IncidentDetailsScreen> createState() => _IncidentDetailsScreenState();
}

class _IncidentDetailsScreenState extends State<IncidentDetailsScreen> {
  late Future<DocumentSnapshot<Map<String, dynamic>>> _incidentFuture;
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  Map<String, dynamic>? _incidentData;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _incidentFuture = _fetchIncidentDetails();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _fetchIncidentDetails() async {
    return FirebaseFirestore.instance.collection('Incident Reports').doc(widget.incidentId).get();
  }

  void _setupMapMarker(GeoPoint coordinates, String category) {
    if (_mapController == null) return;

    final LatLng position = LatLng(coordinates.latitude, coordinates.longitude);

    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: MarkerId(widget.incidentId),
          position: position,
          infoWindow: InfoWindow(title: category),
        ),
      );

      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(position, 15));
    });
  }

  Future<void> _markAsResolved(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('Incident Reports')
          .doc(widget.incidentId)
          .update({
        'Status': 'Resolved',
        'resolvedAt': FieldValue.serverTimestamp(),
      });

      // Show success dialog
      _showSuccessDialog(context, 'Incident marked as resolved');

      // Refresh the data
      setState(() {
        _incidentFuture = _fetchIncidentDetails();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
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
                  style: const TextStyle(
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
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pop();
    });
  }

  Future<void> _confirmDelete(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                "Reject",
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await FirebaseFirestore.instance
                      .collection('Incident Reports')
                      .doc(widget.incidentId)
                      .update({
                    'Status': 'Rejected',
                    'rejectedAt': FieldValue.serverTimestamp(),
                  });

                  // Show success dialog
                  _showSuccessDialog(context, 'Incident marked as rejected');

                  // Refresh the data
                  setState(() {
                    _incidentFuture = _fetchIncidentDetails();
                  });
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

  String _formatDate(BuildContext context, DateTime date) {
    final locale = context.locale.toString();
    final format = DateFormat.yMMMMd(locale).add_jm();
    return format.format(date);
  }

  String _getLocationFromCoordinates(GeoPoint? coordinates) {
    if (coordinates == null) return 'Unknown location';
    return 'Lat: ${coordinates.latitude.toStringAsFixed(4)}, Lng: ${coordinates.longitude.toStringAsFixed(4)}';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.amber;
      case 'resolved':
        return const Color(0xFF00D47E);
      case 'rejected':
        return Colors.red;
      case 'inprogress':
        return Colors.blue;
      default:
        return Colors.grey;
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

  Widget _buildInfoCard(
      BuildContext context,
      String title,
      String? value, {
        IconData? icon,
        Color? valueColor,
        bool showCopyIcon = false,
      }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon ?? Icons.info_outline, color: const Color(0xFF1B9169)),
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
                      ),
                    ),
                    if (showCopyIcon && value != null)
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        tooltip: 'Copy',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
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
  String _getIncidentTypeIconPath(String category) {
    // Normalize the category name by removing special characters and converting to lowercase
    final normalizedCategory = category.toLowerCase().trim();

    // Map for exact matches
    final incidentTypes = {
      'accident': 'assets/GPS/accident_icon.png',
      'breakdown': 'assets/GPS/breakdown_icon.png',
      'road_blockages': 'assets/GPS/circulation.png',
      'roadwork': 'assets/GPS/roadwork.png',
      'special_events': 'assets/GPS/event.png',
      'other': 'assets/GPS/other.png',
    };

    // First try direct lookup
    if (incidentTypes.containsKey(normalizedCategory)) {
      return incidentTypes[normalizedCategory]!;
    }

    // Next, try after replacing spaces with underscores and vice versa
    String alternateKey = normalizedCategory.replaceAll('_', ' ');
    if (incidentTypes.containsKey(alternateKey)) {
      return incidentTypes[alternateKey]!;
    }

    alternateKey = normalizedCategory.replaceAll(' ', '_');
    if (incidentTypes.containsKey(alternateKey)) {
      return incidentTypes[alternateKey]!;
    }

    // If category contains any of these words, return the corresponding icon
    for (final entry in incidentTypes.entries) {
      final key = entry.key;
      if (normalizedCategory.contains(key) || key.contains(normalizedCategory)) {
        return entry.value;
      }
    }

    // Default fallback
    return 'assets/GPS/other.png';
  }

  String _getIncidentTranslationKey(String category) {
    return 'incident_report.$category';
  }

  Widget _buildIncidentHeader({
    required String category,
    required String status,
  }) {
    final Color statusColor = _getStatusColor(status);
    final String iconPath = _getIncidentTypeIconPath(category);
    final String translationKey = _getIncidentTranslationKey(category);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1B9169).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(
              iconPath,
              width: 32,
              height: 32,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  translationKey.tr(),
                  style: const TextStyle(
                    fontSize: 20,
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

  Widget _buildMapPreview(GeoPoint coordinates, String category) {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(coordinates.latitude, coordinates.longitude),
              zoom: 15,
            ),
            markers: _markers,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              setState(() {
                _isMapReady = true;
              });
              _setupMapMarker(coordinates, category);
            },
            myLocationEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
          Positioned(
            right: 10,
            bottom: 10,
            child: FloatingActionButton.small(
              backgroundColor: const Color(0xFF1B9169),
              onPressed: () {
                // Navigate to the full map page
                final mapIncident = {
                  'id': widget.incidentId,
                  'type': category,
                  'coordinates': coordinates,
                };

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MapPage(
                      incidents: [mapIncident],
                    ),
                  ),
                );
              },
              child: const Icon(Icons.fullscreen, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(String status) {
    if (status.toLowerCase() != 'pending') {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mark as Resolved Button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _markAsResolved(context),
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text("Mark Resolved", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D47E),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Reject Button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _confirmDelete(context),
              icon: const Icon(Icons.cancel_outlined, color: Colors.red),
              label: const Text("Reject", style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
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
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1B9169)),
            );
          }
          if (!snapshot.hasData || snapshot.data == null || !snapshot.data!.exists) {
            return const Center(child: Text('Incident details not found.'));
          }

          final incident = snapshot.data!.data()!;
          _incidentData = incident;

          final category = incident['Type'] ?? 'Unknown';
          final status = incident['Status'] ?? 'Pending';
          final description = incident['Description'] ?? '';
          final address = incident['Address'];
          final geoPoint = incident['Location'] as GeoPoint?;
          final location = address ?? _getLocationFromCoordinates(geoPoint);
          final date = incident['ReportTime'] is Timestamp
              ? (incident['ReportTime'] as Timestamp).toDate()
              : null;
          final imageUrl = incident['ImageURL'];
          final userID = incident['UserID'] ?? '';
          final resolvedAt = incident['resolvedAt'] is Timestamp
              ? (incident['resolvedAt'] as Timestamp).toDate()
              : null;
          final rejectedAt = incident['rejectedAt'] is Timestamp
              ? (incident['rejectedAt'] as Timestamp).toDate()
              : null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Incident Header
                _buildIncidentHeader(
                  category: category,
                  status: status,
                ),

                // Map Preview (if coordinates available)
                if (geoPoint != null)
                  _buildMapPreview(geoPoint, category),

                // Description Card
                if (description.isNotEmpty)
                  _buildInfoCard(
                    context,
                    'Description'.tr(),
                    description,
                    icon: Icons.description,
                  ),

                // Reported Date Card
                if (date != null)
                  _buildInfoCard(
                    context,
                    'Reported On'.tr(),
                    _formatDate(context, date),
                    icon: Icons.calendar_today,
                  ),

                // User ID Card
                if (userID.isNotEmpty)
                  _buildInfoCard(
                    context,
                    'Reported By'.tr(),
                    userID,
                    icon: Icons.person_outline,
                    showCopyIcon: true,
                  ),

                // Location Card
                if (location != null)
                  _buildInfoCard(
                    context,
                    'Location'.tr(),
                    location,
                    icon: Icons.location_on_outlined,
                    showCopyIcon: true,
                  ),

                // Status-specific timestamps
                if (status == 'Resolved' && resolvedAt != null)
                  _buildInfoCard(
                    context,
                    'Resolved At'.tr(),
                    _formatDate(context, resolvedAt),
                    icon: Icons.check_circle_outline,
                  ),

                if (status == 'Rejected' && rejectedAt != null)
                  _buildInfoCard(
                    context,
                    'Rejected At'.tr(),
                    _formatDate(context, rejectedAt),
                    icon: Icons.cancel_outlined,
                  ),

                // Image (if available)
                if (imageUrl != null) ...[
                  const SizedBox(height: 20),
                  const Text(
                    "Attached Image",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF1B9169),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
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
                ],

                // Action Buttons (only for pending incidents)
                _buildActionButtons(status),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}