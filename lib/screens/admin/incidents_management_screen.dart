import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'IncidentDetailsScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';

enum IncidentStatusFilter { Pending, Resolved, Rejected }

class IncidentManagementScreen extends StatefulWidget {
  const IncidentManagementScreen({Key? key}) : super(key: key);

  @override
  State<IncidentManagementScreen> createState() => _IncidentManagementScreenState();
}

class _IncidentManagementScreenState extends State<IncidentManagementScreen> {
  IncidentStatusFilter _selectedStatus = IncidentStatusFilter.Pending;
  String selectedCategory = 'All';
  String searchQuery = '';
  int _pendingCount = 0;
  int _rejectedCount = 0;

  final List<String> _categories = [
    'All',
    'accident',
    'breakdown',
    'Road_Blockages',
    'Roadwork',
    'Special_Events',
    'other'
  ];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _filterIncidents(List<Map<String, dynamic>> incidents) {
    return incidents.where((incident) {
      final status = incident['Status']?.toLowerCase() ?? ''; // Use 'Status'
      final type = incident['Type']?.toLowerCase() ?? '';     // Use 'Type'
      final description = incident['Description']?.toLowerCase() ?? ''; // Use 'Description'
      final location = incident['LocationAddress']?.toLowerCase() ?? ''; // Use 'LocationAddress'

      final matchesStatus =
          (_selectedStatus == IncidentStatusFilter.Pending && status == 'pending') ||
              (_selectedStatus == IncidentStatusFilter.Resolved && status == 'resolved') ||
              (_selectedStatus == IncidentStatusFilter.Rejected && status == 'rejected');

      final matchesCategory = selectedCategory == 'All' || type == selectedCategory.toLowerCase();

      final matchesSearch =
          description.contains(searchQuery.toLowerCase()) ||
              location.contains(searchQuery.toLowerCase()) ||
              type.contains(searchQuery.toLowerCase());


      return matchesStatus && matchesCategory && matchesSearch;
    }
    ).toList();

  }


  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
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
      case 'pending':
        return Icons.access_time;
      case 'resolved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'inprogress':
        return Icons.build;
      default:
        return Icons.help_outline;
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTitle(),
          //  const SizedBox(height: 8),
          //  _buildSearchBar(),
            const SizedBox(height: 16),
            _buildStatusFilter(),
            const SizedBox(height: 16),
            _buildCategoryChips(),
            const SizedBox(height: 16),
            Expanded(child: _buildIncidentList()),
          ],
        ),
      ),
    );
  }
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: const Color(0xFF1B9169),
        statusBarIconBrightness: Brightness.light,
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF1B9169)),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Text(
          'admin.manage_incidents'.tr(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B9169),
          ),
        ),
      ),
    );
  }
  Widget _buildStatusFilter() {
    return SegmentedButton<IncidentStatusFilter>(
      showSelectedIcon: false,
      style: ButtonStyle(
        padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
        backgroundColor: MaterialStateProperty.resolveWith<Color?>(
              (states) => states.contains(MaterialState.selected)
              ? const Color(0xFFE0F2F1) // Light green when selected
              : Colors.transparent,
        ),
        side: MaterialStateProperty.resolveWith<BorderSide?>(
              (states) => states.contains(MaterialState.selected)
              ? const BorderSide(color: Color(0xFF1B9169)) // Green border when selected
              : const BorderSide(color: Colors.grey),
        ),
        shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        foregroundColor: MaterialStateProperty.resolveWith<Color?>(
              (states) => states.contains(MaterialState.selected)
              ? const Color(0xFF1B9169) // Green text when selected
              : Colors.grey, // Grey text when not selected
        ),
        overlayColor: MaterialStateProperty.all(const Color(0xFF1B9169).withOpacity(0.1)), // Green overlay effect
      ),
      segments: [
        ButtonSegment(
          value: IncidentStatusFilter.Pending,
          label: _buildStatusSegmentLabel(
            Icons.access_time,
            'incident_report.pending'.tr(),
            _selectedStatus == IncidentStatusFilter.Pending,
            color: Colors.orange, // Orange color for pending
          ),
        ),
        ButtonSegment(
          value: IncidentStatusFilter.Resolved,
          label: _buildStatusSegmentLabel(
            Icons.check_circle,
            'incident_report.resolved'.tr(),
            _selectedStatus == IncidentStatusFilter.Resolved,
            color: Colors.green, // Green color for resolved
          ),
        ),
        ButtonSegment(
          value: IncidentStatusFilter.Rejected,
          label: _buildStatusSegmentLabel(
            Icons.cancel,
            'incident_report.rejected'.tr(),
            _selectedStatus == IncidentStatusFilter.Rejected,
            color: Colors.red, // Red color for rejected
          ),
        ),
      ],
      selected: {_selectedStatus},
      onSelectionChanged: (newSelection) {
        setState(() {
          _selectedStatus = newSelection.first;
        });
      },
    );
  }
  Widget _buildStatusSegmentLabel(IconData icon, String label, bool isSelected, {required Color color}) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min, // This helps minimize the row's width
        children: [
          Icon(
            icon,
            color: isSelected ? color : Colors.grey,
            size: 18, // Make icons slightly smaller
          ),
          const SizedBox(width: 4), // Reduce spacing
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey,
                fontSize: 13, // Smaller font size
              ),
              overflow: TextOverflow.ellipsis, // Add ellipsis if text overflows
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((category) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: FilterChip(
              label: Text(
                // Translate the category name using tr() method
                'incident_report.$category'.tr(),
                style: TextStyle(
                  color: selectedCategory == category
                      ? Colors.white // White text when selected
                      : const Color(0xFF1B9169), // Green text when not selected
                ),
              ),
              selected: selectedCategory == category,
              onSelected: (selected) {
                setState(() {
                  selectedCategory = selected ? category : 'All';
                });
              },
              selectedColor: const Color(0xFF1B9169).withOpacity(0.3), // Light green for selected
              backgroundColor: Colors.grey.withOpacity(0.1), // Light gray for unselected
              checkmarkColor: const Color(0xFF1B9169), // Green checkmark
              shadowColor: Colors.grey.withOpacity(0.2), // Soft shadow for depth
              elevation: 4, // Slight elevation to give it a floating effect
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildIncidentList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('Incident Reports').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Something went wrong: ${snapshot.error}', style: TextStyle(color: Colors.red)),
                ElevatedButton(
                  onPressed: () {
                    // Retry fetching data (you can add more retry logic if needed)
                    setState(() {});
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF1B9169),
              strokeWidth: 2,
            ),
          );
        }

        final incidents = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'Type': data['Type'] ?? 'Unknown',
            'Description': data['Description'] ?? '',
            'Status': data['Status'] ?? 'Pending',
            'timestamp': data['ReportTime'],
            'ImageURL': data['ImageURL'],
            'Location': data['Location'],
            'Address': data['Address'] ?? '',
          };
        }).toList();

        final filteredIncidents = _filterIncidents(incidents);

        if (filteredIncidents.isEmpty) {
          return const Center(
            child: Text(
              'No incidents found matching the criteria.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredIncidents.length,
          itemBuilder: (context, index) {
            return _buildIncidentCardForAdmin(filteredIncidents[index], context);
          },
        );
      },
    );
  }
  Widget _buildIncidentCardForAdmin(Map<String, dynamic> incident, BuildContext context) {
    final category = incident['Type'] ?? 'Unknown';
    final status = incident['Status'] ?? 'Pending';
    final timestamp = incident['timestamp'];
    final location = incident['Address'] ?? 'Localisation inconnue';

    String formattedDate = 'Date inconnue';
    if (timestamp is Timestamp) {
      formattedDate = DateFormat('dd/MM/yyyy').format(timestamp.toDate());
    }

    final hasImage = incident['ImageURL'] != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => IncidentDetailsScreen(
                incidentId: incident['id'],
              ),
            ),
          );
        },
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
                      "incident_report.$category".tr(),
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
                          color: _getStatusColor(status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getStatusIcon(status),
                              size: 16,
                              color: _getStatusColor(status),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "incident_report.${status.toLowerCase()}".tr(),
                              style: TextStyle(
                                fontSize: 12,
                                color: _getStatusColor(status),
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
                    formattedDate,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  if (location != null)
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 100,
                          child: Text(
                            location,
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
  Widget _buildIncidentSegmentLabel(IconData icon, String text, bool isSelected) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: isSelected ? const Color(0xFF1B9169) : Colors.grey),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isSelected ? const Color(0xFF1B9169) : Colors.grey,
            ),
          ),
        ),
      ],
    );
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