import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:road_companion/screens/admin/IncidentDetailsScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';

enum IncidentStatusFilter { Pending, Resolved, Rejected }
enum IncidentPriority { High, Medium, Low }

class IncidentManagementScreen extends StatefulWidget {
  const IncidentManagementScreen({Key? key}) : super(key: key);

  @override
  State<IncidentManagementScreen> createState() => _IncidentManagementScreenState();
}

class _IncidentManagementScreenState extends State<IncidentManagementScreen> {
  IncidentStatusFilter _selectedStatus = IncidentStatusFilter.Pending;
  String selectedCategory = 'All';
  IncidentPriority? selectedPriority; // Added priority filter
  String searchQuery = '';
  int _pendingCount = 0;
  int _rejectedCount = 0;
  DateTime? dateRangeStart;
  DateTime? dateRangeEnd;

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
      final status = incident['Status']?.toLowerCase() ?? '';
      final type = incident['Type']?.toLowerCase() ?? '';
      final priority = getPriorityFromString(incident['Priority'] ?? 'Medium');

      // Get the incident timestamp
      final timestamp = incident['timestamp'] as Timestamp?;
      final incidentDate = timestamp?.toDate();

      // Status filtering
      final matchesStatus =
          (_selectedStatus == IncidentStatusFilter.Pending && status == 'pending') ||
              (_selectedStatus == IncidentStatusFilter.Resolved && status == 'resolved') ||
              (_selectedStatus == IncidentStatusFilter.Rejected && status == 'rejected');

      // Category filtering
      final matchesCategory = selectedCategory == 'All' || type == selectedCategory.toLowerCase();

      // Priority filtering
      final matchesPriority = selectedPriority == null || priority == selectedPriority;

      // Date range filtering
      bool matchesDateRange = true;
      if (incidentDate != null) {
        // Check if incident date is within the selected date range
        if (dateRangeStart != null) {
          // Set start date to beginning of day for comparison
          final startOfDay = DateTime(
              dateRangeStart!.year,
              dateRangeStart!.month,
              dateRangeStart!.day
          );
          if (incidentDate.isBefore(startOfDay)) {
            matchesDateRange = false;
          }
        }

        if (dateRangeEnd != null && matchesDateRange) {
          // Set end date to end of day for comparison
          final endOfDay = DateTime(
              dateRangeEnd!.year,
              dateRangeEnd!.month,
              dateRangeEnd!.day,
              23, 59, 59, 999
          );
          if (incidentDate.isAfter(endOfDay)) {
            matchesDateRange = false;
          }
        }
      }

      return matchesStatus && matchesCategory && matchesPriority && matchesDateRange;
    }).toList();
  }
  // Helper function to convert string to enum
  IncidentPriority getPriorityFromString(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
        return IncidentPriority.High;
      case 'medium':
        return IncidentPriority.Medium;
      case 'low':
        return IncidentPriority.Low;
      default:
        return IncidentPriority.Medium; // Default priority
    }
  }

  // Helper function to get priority color
  Color getPriorityColor(IncidentPriority priority) {
    switch (priority) {
      case IncidentPriority.High:
        return Colors.red;
      case IncidentPriority.Medium:
        return Colors.amber;
      case IncidentPriority.Low:
        return Colors.blue;
    }
  }

  // Helper function to get priority icon
  IconData getPriorityIcon(IncidentPriority priority) {
    switch (priority) {
      case IncidentPriority.High:
        return Icons.warning_amber_rounded;
      case IncidentPriority.Medium:
        return Icons.flag_rounded;
      case IncidentPriority.Low:
        return Icons.info_outline;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.amber;
      case 'resolved':
        return Color(0xFF00D47E);
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
      backgroundColor: Colors.grey[100],
      appBar: _buildAppBar(context),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTitle(),
            const SizedBox(height: 16),
            _buildStatusFilter(),
            const SizedBox(height: 2),
            _buildCategoryChips(),
            const SizedBox(height: 2),
            buildPriorityFilter(), // Added priority filter
            const SizedBox(height: 10),
            // Add the date filter indicator when dates are selected
            _buildDateFilterIndicator(),

            Expanded(child: _buildIncidentList()),
          ],
        ),
      ),
    );
  }
  // Add this widget to your build method after the category chips
  Widget _buildDateFilterIndicator() {
    if (dateRangeStart == null && dateRangeEnd == null) {
      return const SizedBox.shrink();
    }

    final dateFormat = DateFormat('dd MMM yyyy');
    String filterText;

    if (dateRangeStart != null && dateRangeEnd != null) {
      filterText = '${dateFormat.format(dateRangeStart!)} - ${dateFormat.format(dateRangeEnd!)}';
    } else if (dateRangeStart != null) {
      filterText = 'From ${dateFormat.format(dateRangeStart!)}';
    } else {
      filterText = 'Until ${dateFormat.format(dateRangeEnd!)}';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: Color(0xFF1B9169).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Color(0xFF1B9169).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.date_range, color: Color(0xFF1B9169), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Date Filter: $filterText',
                style: TextStyle(
                  color: Color(0xFF1B9169),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  dateRangeStart = null;
                  dateRangeEnd = null;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Color(0xFF1B9169).withOpacity(0.3)),
                ),
                child: Icon(
                  Icons.close,
                  color: Color(0xFF1B9169),
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.grey[100],
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
      actions: [
        // Date filter button
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          child: Tooltip(
            message: 'incident_report.filter_by_date'.tr(),
            child: Material(
              color: Colors.transparent, // ✅ Always transparent, no change
              borderRadius: BorderRadius.circular(50),
              child: InkWell(
                onTap: _showSearchDialog,
                borderRadius: BorderRadius.circular(50),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(
                    Icons.calendar_month,
                    size: 24,
                    color: Color(0xFF1B9169), // ✅ Always same color
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showSearchDialog() {
    DateTime? selectedStartDate = dateRangeStart;
    DateTime? selectedEndDate = dateRangeEnd;
    final dateFormat = DateFormat('dd MMM yyyy');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.calendar_month, color: const Color(0xFF1B9169)),
                const SizedBox(width: 10),
                Text(
                  'incident_report.filter_by_date'.tr(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'incident_report.select_date_range'.tr(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildDatePickerTile(
                    label: 'incident_report.start_date'.tr(),
                    date: selectedStartDate,
                    onPick: (picked) => setState(() => selectedStartDate = picked),
                    dateFormat: dateFormat,
                  ),
                  const SizedBox(height: 16),
                  _buildDatePickerTile(
                    label: 'incident_report.end_date'.tr(),
                    date: selectedEndDate,
                    onPick: (picked) => setState(() => selectedEndDate = picked),
                    dateFormat: dateFormat,
                  ),
                  const SizedBox(height: 16),
                  if (selectedStartDate != null &&
                      selectedEndDate != null &&
                      selectedEndDate!.isBefore(selectedStartDate!))
                    _buildErrorBox('incident_report.date_range_error'.tr()),
                  if (selectedStartDate != null &&
                      selectedEndDate != null &&
                      !selectedEndDate!.isBefore(selectedStartDate!))
                    _buildDateSummaryBox(selectedStartDate!, selectedEndDate!, dateFormat),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    selectedStartDate = null;
                    selectedEndDate = null;
                  });
                },
                child: Text(
                  'incident_report.clear_dates'.tr(),
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  bool isValid = true;
                  if (selectedStartDate != null && selectedEndDate != null) {
                    isValid = !selectedEndDate!.isBefore(selectedStartDate!);
                  }

                  if (isValid) {
                    Navigator.pop(
                      context,
                      {
                        'startDate': selectedStartDate,
                        'endDate': selectedEndDate,
                      },
                    );
                  }
                },
                icon: Icon(Icons.filter_alt),
                label: Text('incident_report.apply_filter'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B9169),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ).then((result) {
      // Handle the search result if needed
      if (result != null) {
        // Update the parent state with date parameters only
        setState(() {
          dateRangeStart = result['startDate'];
          dateRangeEnd = result['endDate'];
          // Keep searchQuery empty to focus only on date filtering
          searchQuery = '';
        });
      }
    });
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
  Widget _buildDatePickerTile({
    required String label,
    required DateTime? date,
    required Function(DateTime) onPick,
    required DateFormat dateFormat,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2101),
              builder: (context, child) => Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: Color(0xFF1B9169),
                    onPrimary: Colors.white,
                  ),
                ),
                child: child!,
              ),
            );
            if (picked != null) onPick(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date != null ? dateFormat.format(date) : 'incident_report.select_date'.tr(),
                  style: TextStyle(
                    fontSize: 16,
                    color: date != null ? Colors.black : Colors.grey.shade600,
                  ),
                ),
                const Icon(Icons.calendar_today, color: Color(0xFF1B9169)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBox(String message) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  Widget _buildDateSummaryBox(DateTime start, DateTime end, DateFormat format) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1B9169).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1B9169).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.date_range, color: Color(0xFF1B9169)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${format.format(start)} - ${format.format(end)}',
              style: const TextStyle(
                color: Color(0xFF1B9169),
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }


// Add priority filter widget
  Widget buildPriorityFilter() {
    // List of all priority options for cleaner implementation
    final List<Map<String, dynamic>> priorityOptions = [
      {'priority': null, 'label': 'All'},
      {'priority': IncidentPriority.High, 'label': 'High'},
      {'priority': IncidentPriority.Medium, 'label': 'Medium'},
      {'priority': IncidentPriority.Low, 'label': 'Low'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: priorityOptions.length,
          separatorBuilder: (context, index) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final option = priorityOptions[index];
            return buildPriorityChip(
              option['priority'],
              option['label'],
            );
          },
        ),
      ),
    );
  }

  Widget buildPriorityChip(IncidentPriority? priority, String label) {
    final bool isSelected = selectedPriority == priority;
    final Color priorityColor = priority == null ? Colors.grey.shade700 : getPriorityColor(priority);
    final Color selectedBackgroundColor = priority == null ? Colors.grey.shade200 : priorityColor.withOpacity(0.15);

    return FilterChip(
      label: Text(
        label.tr(), // Ensure label is translated
        style: TextStyle(
          color: priorityColor, // Text color always matches priority
          fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          fontSize: 14,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          selectedPriority = selected ? priority : null;
        });
      },
      selectedColor: selectedBackgroundColor,
      backgroundColor: Colors.white,
      showCheckmark: false, // Remove the checkmark
      elevation: 0,
      shadowColor: Colors.transparent,
      pressElevation: 0,
      avatar: priority == null
          ? null
          : Icon(
        getPriorityIcon(priority),
        color: priorityColor,
        size: 16,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? selectedBackgroundColor : Colors.grey.shade300, // Use light color for selected border
          width: 1,
        ),
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0), // Adjust padding if needed
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
              ? const BorderSide(color: Color(0xFF00D47E)) // Green border when selected
              : const BorderSide(color: Colors.grey),
        ),
        shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        foregroundColor: MaterialStateProperty.resolveWith<Color?>(
              (states) => states.contains(MaterialState.selected)
              ? const Color(0xFF00D47E) // Green text when selected
              : Colors.grey, // Grey text when not selected
        ),
        overlayColor: MaterialStateProperty.all(const Color(0xFF00D47E).withOpacity(0.1)), // Green overlay effect
      ),
      segments: [
        ButtonSegment(
          value: IncidentStatusFilter.Pending,
          label: _buildStatusSegmentLabel(
            Icons.access_time,
            'incident_report.pending'.tr(),
            _selectedStatus == IncidentStatusFilter.Pending,
            color: Colors.amber, // Orange color for pending
          ),
        ),
        ButtonSegment(
          value: IncidentStatusFilter.Resolved,
          label: _buildStatusSegmentLabel(
            Icons.check_circle,
            'incident_report.resolved'.tr(),
            _selectedStatus == IncidentStatusFilter.Resolved,
            color: Color(0xFF00D47E), // Green color for resolved
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? color : Colors.grey,
            size: 18,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
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
                'incident_report.$category'.tr(),
                style: TextStyle(
                  color: selectedCategory == category
                      ? Colors.white
                      : const Color(0xFF00D47E),
                ),
              ),
              selected: selectedCategory == category,
              onSelected: (selected) {
                setState(() {
                  selectedCategory = selected ? category : 'All';
                });
              },
              selectedColor: const Color(0xFF00D47E),
              backgroundColor: Colors.white,
              checkmarkColor: Colors.white,
              shadowColor: Colors.grey.withOpacity(0.2),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
                side: BorderSide(
                  color: Colors.transparent,
                ),
              ),
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
              color: Color(0xFF00D47E),
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
            'Priority': data['Priority'] ?? 'Medium', // Get priority from Firestore
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
    final priority = getPriorityFromString(incident['Priority'] ?? 'Medium');

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
        // Add a subtle left border with priority color
        boxShadow: [
          BoxShadow(
            color: getPriorityColor(priority).withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
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
                  // Left side: Priority indicator with popup menu
                  InkWell(
                    onTap: () {
                      showPriorityChangeDialog(context, incident['id'], priority);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: getPriorityColor(priority).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: getPriorityColor(priority).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            getPriorityIcon(priority),
                            size: 16,
                            color: getPriorityColor(priority),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            priority.toString().split('.').last,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: getPriorityColor(priority),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.arrow_drop_down,
                            size: 16,
                            color: getPriorityColor(priority),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Right side: Status indicator
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
              const SizedBox(height: 12),
              Row(
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
                  if (hasImage)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(Icons.image, size: 20, color: Colors.grey),
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

              // Add quick action buttons
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (status.toLowerCase() == 'pending')
                    _buildQuickActionButton(
                      Icons.check,
                      'Resolve',
                      const Color(0xFF00D47E),
                          () => _updateIncidentStatus(incident['id'], 'Resolved'),
                    ),
                  if (status.toLowerCase() == 'pending')
                    const SizedBox(width: 8),
                  if (status.toLowerCase() == 'pending')
                    _buildQuickActionButton(
                      Icons.close,
                      'Reject',
                      Colors.red,
                          () => _updateIncidentStatus(incident['id'], 'Rejected'),
                    ),
                  if (status.toLowerCase() != 'pending')
                    _buildQuickActionButton(
                      Icons.refresh,
                      'Reset',
                      Colors.blue,
                          () => _updateIncidentStatus(incident['id'], 'Pending'),
                    ),
                ],
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
        actionVerb = 'approve';
        confirmButtonText = 'Approve';
        confirmColor = const Color(0xFF00D47E);
        confirmIcon = Icons.check_circle;
        break;
      case 'rejected':
        actionVerb = 'reject';
        confirmButtonText = 'Reject';
        confirmColor = Colors.red;
        confirmIcon = Icons.cancel;
        break;
      case 'pending':
        actionVerb = 'reset';
        confirmButtonText = 'Reset';
        confirmColor = Colors.blue;
        confirmIcon = Icons.refresh;
        break;
      default:
        actionVerb = 'update';
        confirmButtonText = 'Update';
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
                  'Confirm Action',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Are you sure you want to $actionVerb this incident?',
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
                        child: Text('Cancel'),
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


  void showPriorityChangeDialog(BuildContext context, String incidentId, IncidentPriority currentPriority) {
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
                Text(
                  'incident_report.change_priority'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                ...IncidentPriority.values.map((priority) =>
                    _buildPriorityOption(
                      context,
                      incidentId,
                      priority,
                      isSelected: priority == currentPriority,
                    ),
                ).toList(),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                      ),
                      child: Text('cancel'.tr()),
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

  Widget _buildPriorityOption(
      BuildContext context,
      String incidentId,
      IncidentPriority priority,
      {bool isSelected = false}
      ) {
    final String label = priority.toString().split('.').last;
    final Color color = getPriorityColor(priority);
    final IconData icon = getPriorityIcon(priority);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.pop(context);
            _updateIncidentPriority(incidentId, label);
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? color : Colors.transparent,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const Spacer(),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: color,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Method to update incident priority
  Future<void> _updateIncidentPriority(String incidentId, String newPriority) async {
    try {
      await _firestore.collection('Incident Reports').doc(incidentId).update({
        'Priority': newPriority,
        'UpdatedAt': FieldValue.serverTimestamp(),
      });

      SuccessDialog(context, 'Priority updated successfully');
    } catch (e) {
      print('Error updating priority: $e');
      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Failed to update incident priority: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
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
        message = 'Incident successfully marked as resolved';
        iconColor = const Color(0xFF00D47E);
        break;
      case 'rejected':
        message = 'Incident has been rejected';
        iconColor = Colors.red;
        break;
      case 'pending':
        message = 'Incident status reset to pending';
        iconColor = Colors.blue;
        break;
      default:
        message = 'Status updated successfully';
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
// Quick action button for incident cards
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
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