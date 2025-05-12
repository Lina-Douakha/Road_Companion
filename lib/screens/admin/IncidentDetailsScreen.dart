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
          Icon(icon ?? Icons.info_outline, color: Colors.black38),
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
                        value ?? 'admin.not_available'.tr(),
                        style: TextStyle(
                          color: valueColor ?? Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (showCopyIcon && value != null)
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        tooltip: 'admin.copy'.tr(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
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
        title:  Text(
          'admin.incident_details'.tr(),
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
            return  Center(child: Text('admin.Incident_details_not_found'.tr()));
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
                    'incident_report.Description'.tr(),
                    description,
                    icon: Icons.description,
                  ),

                // Reported Date Card
                if (date != null)
                  _buildInfoCard(
                    context,
                    'incident_report.Reported-on'.tr(),
                    _formatDate(context, date),
                    icon: Icons.calendar_today,
                  ),

                // User ID Card
                if (userID.isNotEmpty)
                  _buildInfoCard(
                    context,
                    'admin.Reported_By'.tr(),
                    userID,
                    icon: Icons.person_outline,
                    showCopyIcon: true,
                  ),

                // Location Card
                if (location != null)
                  _buildInfoCard(
                    context,
                    'incident_report.Location'.tr(),
                    location,
                    icon: Icons.location_on_outlined,
                    showCopyIcon: true,
                  ),

                // Status-specific timestamps
                if (status == 'Resolved' && resolvedAt != null)
                  _buildInfoCard(
                    context,
                    'admin.Resolved_At'.tr(),
                    _formatDate(context, resolvedAt),
                    icon: Icons.check_circle_outline,
                  ),

                if (status == 'Rejected' && rejectedAt != null)
                  _buildInfoCard(
                    context,
                    'admin.Rejected_At'.tr(),
                    _formatDate(context, rejectedAt),
                    icon: Icons.cancel_outlined,
                  ),

                // Image (if available)
                if (imageUrl != null) ...[
                  const SizedBox(height: 20),
                  const Text(
                    "Attached_Image",
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

                // Action buttons - Directly include them in the main Column
                const SizedBox(height: 24),

                // Build action buttons based on status
                ..._buildActionButtons(status),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  // Modified to return a list of individual widgets instead of wrapped in a Column
  List<Widget> _buildActionButtons(String status) {
    List<Widget> buttons = [];

    if (status == 'Pending') {
      buttons.addAll([
        _buildQuickActionButton(Icons.check_circle, 'admin.resolve'.tr(), const Color(0xFF00D47E), () {
          _updateIncidentStatus(widget.incidentId, 'Resolved');
        }),
        const SizedBox(height: 12), // Vertical spacing between buttons
        _buildQuickActionButton(Icons.cancel, 'admin.reject'.tr(), Colors.red, () {
          _updateIncidentStatus(widget.incidentId, 'Rejected');
        }),
      ]);
    } else if (status == 'Resolved' || status == 'Rejected') {
      buttons.add(
        _buildQuickActionButton(Icons.refresh, 'admin.reset'.tr(), Colors.blue, () {
          _updateIncidentStatus(widget.incidentId, 'Pending');
        }),
      );
    }

    return buttons; // Return buttons directly, without wrapping in additional widgets
  }

  Widget _buildQuickActionButton(
      IconData icon,
      String label,
      Color color,
      VoidCallback onPressed,
      ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        splashColor: color.withOpacity(0.1),
        highlightColor: Colors.transparent,
        onTap: onPressed,
        child: Container(
          width: double.infinity, // Make button take full width
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center, // Center the content horizontally
            children: [
              Icon(
                icon,
                size: 20,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  //Show confirmation dialog before updating status
  void _updateIncidentStatus(String incidentId, String status) {
    // Determine confirmation message and colors based on status
    String actionVerb;
    String confirmButtonText;
    Color confirmColor;
    IconData confirmIcon;

    switch (status.toLowerCase()) {
      case 'resolved':
        actionVerb = 'resolve';
        confirmButtonText = 'admin.resolve'.tr();
        confirmColor = const Color(0xFF00D47E);
        confirmIcon = Icons.check_circle;
        break;
      case 'rejected':
        actionVerb = 'reject';
        confirmButtonText = 'admin.reject'.tr();
        confirmColor = Colors.red;
        confirmIcon = Icons.cancel;
        break;
      case 'pending':
        actionVerb = 'reset';
        confirmButtonText = 'admin.reset'.tr();
        confirmColor = Colors.blue;
        confirmIcon = Icons.refresh;
        break;
      default:
        actionVerb = 'update';
        confirmButtonText = 'admin.Update'.tr();
        confirmColor = Colors.blue;
        confirmIcon = Icons.update;
    }

    // Show confirmation dialog
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
                    color: confirmColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    confirmIcon,
                    color: confirmColor,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'admin.confirm_action'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  status.toLowerCase() == 'resolved'
                      ? 'admin.confirm_resolve_action'.tr()
                      : status.toLowerCase() == 'rejected'
                      ? 'admin.confirm_reject_action'.tr()
                      : 'admin.confirm_reset_action'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text('admin.cancel'.tr()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _performStatusUpdate(incidentId, status);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: confirmColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(confirmButtonText),
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

// Actually perform the status update after confirmation
  Future<void> _performStatusUpdate(String incidentId, String status) async {
    try {
      // Prepare update data with appropriate timestamp field
      final Map<String, dynamic> updateData = {
        'Status': status,
      };

      // Add appropriate timestamp based on status
      if (status == 'Resolved') {
        updateData['resolvedAt'] = FieldValue.serverTimestamp();
      } else if (status == 'Rejected') {
        updateData['rejectedAt'] = FieldValue.serverTimestamp();
      } else if (status == 'Pending') {
        // Reset timestamps when returning to pending
        updateData['resolvedAt'] = null;
        updateData['rejectedAt'] = null;
      }

      // Update the document
      await FirebaseFirestore.instance
          .collection('Incident Reports')
          .doc(incidentId)
          .update(updateData);

      if (mounted) {
        setState(() {
          _incidentFuture = _fetchIncidentDetails();
        });
      }


      // Show success message
      _showStatusUpdateSuccessDialog(status);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
// Show success dialog with custom message based on status
  void _showStatusUpdateSuccessDialog(String status) {
    String message;
    Color iconColor;

    switch (status.toLowerCase()) {
      case 'resolved':
        message = 'admin.incident_successfully_marked_as_resolved'.tr();
        iconColor = const Color(0xFF00D47E);
        break;
      case 'rejected':
        message = 'admin.incident_has_been_rejected'.tr();
        iconColor = Colors.red;
        break;
      case 'pending':
        message = 'admin.incident_status_reset_to_pending'.tr();
        iconColor = Colors.blue;
        break;
      default:
        message = 'admin.status_updated_successfully'.tr();
        iconColor = Colors.blue;
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
                    Icons.check_circle,
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
                  child: Text('OK'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

}