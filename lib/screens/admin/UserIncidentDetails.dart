import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:road_companion/screens/incident_reporting/map_page.dart';
import 'package:lottie/lottie.dart';

class IncidentHistoryScreen extends StatefulWidget {
  final String userId;

  const IncidentHistoryScreen({super.key, required this.userId});

  @override
  State<IncidentHistoryScreen> createState() => _IncidentHistoryScreenState();
}

class _IncidentHistoryScreenState extends State<IncidentHistoryScreen> {
  List<Map<String, dynamic>> incidentHistory = [];
  bool isLoading = true;
  String? errorMessage;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeDateFormatting();
    _loadIncidentsFromFirebase();
  }

  Future<void> _loadIncidentsFromFirebase() async {
    try {
      final uid = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;

      if (uid == null) {
        setState(() {
          isLoading = false;
          errorMessage = 'User not authenticated'.tr();
        });
        return;
      }

      final querySnapshot = await FirebaseFirestore.instance
          .collection('Incident Reports')
          .where('UserID', isEqualTo: uid)
          .orderBy('ReportTime', descending: true)
          .get();

      setState(() {
        incidentHistory = querySnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'type': data['Type'] ?? 'Unknown'.tr(),
            'description': data['Description'],
            'status': data['Status'] ?? 'Unknown'.tr(),
            'date': (data['ReportTime'] as Timestamp).toDate(),
            'imageUrl': data['ImageURL'],
            'location': data['Address'] ?? _getLocationFromCoordinates(data['Location']),
            'coordinates': data['Location'],
          };
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load incidents'.tr();
      });
    }
  }



  Future<void> _initializeDateFormatting() async {
    final locale = context.locale.toString();
    await initializeDateFormatting(locale, null);
  }

  String _getLocationFromCoordinates(GeoPoint? coordinates) {
    if (coordinates == null) return 'Custom location';
    return 'Lat: ${coordinates.latitude.toStringAsFixed(4)}, Lng: ${coordinates.longitude.toStringAsFixed(4)}';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.amber;
      case 'resolved': return  const Color(0xFF00D47E);
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

  void _viewAllIncidentsOnMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapPage(
          incidents: incidentHistory.where((i) => i['coordinates'] != null).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: const Color(0xFF1B9169),
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: Container(
            color: Colors.white, // Solid white background
            child: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              automaticallyImplyLeading: false,
              titleSpacing: 0,
              title: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'incident_report.historique_des_incidents'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B9169),
                  ),
                ),
              ),
            ),
          ),
        ),


        body: RefreshIndicator(
          color: const Color(0xFF1B9169),
          backgroundColor: Colors.white,
          strokeWidth: 2.0,
          onRefresh: _loadIncidentsFromFirebase,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const SizedBox(height: 8),

                if (!isLoading && incidentHistory.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          "incident_report.Total".tr(),
                          incidentHistory.length.toString(),
                          Icons.list_alt,
                          const Color(0xFF1B9169),
                        ),
                        _buildStatItem(
                          "incident_report.Pending".tr(),
                          incidentHistory.where((i) => i['status'].toString().toLowerCase() == 'pending')
                              .length.toString(),
                          Icons.access_time,
                          Colors.amber,
                        ),
                        _buildStatItem(
                          "incident_report.Resolved".tr(),
                          incidentHistory.where((i) => i['status'].toString().toLowerCase() == 'resolved')
                              .length.toString(),
                          Icons.check_circle,
                          const Color(0xFF00D47E),
                        ),
                      ],
                    ),
                  ),
                if (isLoading)
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B9169)),
                      ),
                    ),
                  )
                else if (errorMessage != null)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            errorMessage!,
                            style: const TextStyle(color: Colors.red, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadIncidentsFromFirebase,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B9169),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text('admin.retry'.tr(), style: const TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (incidentHistory.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min, // Important to center content vertically
                          children: <Widget>[
                            Lottie.asset(
                              'assets/animation/empty.json',
                              width: 180,
                              height: 180,
                              repeat: true,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "incident_report.No_incidents_reported".tr(),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: incidentHistory.length,
                        itemBuilder: (context, index) {
                          final incident = incidentHistory[index];
                          return _buildIncidentCard(incident);
                        },
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title.tr(),
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildIncidentCard(Map<String, dynamic> incident) {
    final hasImage = incident['imageUrl'] != null;
    final hasLocation = incident['location'] != null;
    final typeofincident =  incident['type'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showIncidentDetails(incident),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                     'incident_report.$typeofincident'.tr(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      if (hasImage)
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Icon(Icons.image, size: 20, color: Colors.grey),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(incident['status']).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getStatusIcon(incident['status']),
                              size: 16,
                              color: _getStatusColor(incident['status']),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "incident_report.${incident['status']}".tr(),
                              style: TextStyle(
                                fontSize: 12,
                                color: _getStatusColor(incident['status']),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(context, incident['date']),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  if (hasLocation)
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 100,
                          child: Text(
                            incident['location'],
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showIncidentDetails(Map<String, dynamic> incident) {
    final hasDescription = incident['description'] != null &&
        incident['description'].toString().isNotEmpty;
    final hasImage = incident['imageUrl'] != null;
    final hasLocation = incident['location'] != null;
    final hasCoordinates = incident['coordinates'] != null;
    final typeofincident = incident['type'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Draggable handle
              Center(
                child: Container(
                  width: 60,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header row with type and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'incident_report.$typeofincident'.tr(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(incident['status']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(incident['status']),
                          size: 16,
                          color: _getStatusColor(incident['status']),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "incident_report.${incident['status']}".tr(), // Translated
                          style: TextStyle(
                            color: _getStatusColor(incident['status']),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Description section
              if (hasDescription) ...[
                const SizedBox(height: 16),
                Text(
                  "incident_report.Description".tr(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  incident['description'],
                  style: const TextStyle(fontSize: 14),
                ),
              ],

              // Date section
              const SizedBox(height: 16),
              Text(
                "incident_report.Reported-on".tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _formatDate(context, incident['date']),
                style: const TextStyle(fontSize: 14),
              ),

              // Location section with integrated map action
              if (hasLocation) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "incident_report.Location".tr(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (hasCoordinates)
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
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
                              const Icon(Icons.map_outlined,
                                size: 18,
                                color: Color(0xFF1B9169),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "incident_report.View_Map".tr(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF1B9169),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  incident['location'],
                  style: const TextStyle(fontSize: 14),
                ),
              ],

              // Image section
              if (hasImage) ...[
                const SizedBox(height: 16),
                Text(
                  "incident_report.Attached_Image".tr(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    incident['imageUrl'],
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],

              // Close button
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D47E),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "incident_report.Close".tr(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}