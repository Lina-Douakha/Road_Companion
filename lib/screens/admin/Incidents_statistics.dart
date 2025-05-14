import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';


class StatisticsIncidents extends StatefulWidget {
  @override
  _StatisticsIncidentsState createState() => _StatisticsIncidentsState();
}

class _StatisticsIncidentsState extends State<StatisticsIncidents> with SingleTickerProviderStateMixin {
  late Future<Map<String, dynamic>> _incidentStats;
  late TabController _tabController;

  bool _isLoading = false;
  String _errorMessage = '';

  // Define incident types as they are stored in Firebase
  final List<String> _incidentTypes = [
    'accident',
    'breakdown',
    'Road_Blockages',
    'Roadwork',
    'Special_Events',
    'other'
  ];

  // Mapping of Firebase storage format to display format for translations
  final Map<String, String> _incidentTypeTranslationKeys = {
    'accident': 'incident_report.accident',
    'breakdown': 'incident_report.breakdown',
    'Road_Blockages': 'incident_report.Road_Blockages',
    'Roadwork': 'incident_report.Roadwork',
    'Special_Events': 'incident_report.Special_Events',
    'other': 'incident_report.other',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _incidentStats = _getIncidentStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _getIncidentStats() async {
    final incidentCollection = FirebaseFirestore.instance.collection('Incident Reports');
    final incidents = await incidentCollection.get();

    int totalIncidents = 0;
    int resolvedCount = 0;
    int rejectedCount = 0;
    int pendingCount = 0;

    for (var doc in incidents.docs) {
      totalIncidents++;

      final status = doc['Status'];
      if (status == 'Resolved') {
        resolvedCount++;
      } else if (status == 'Rejected') {
        rejectedCount++;
      } else if (status == 'Pending') {
        pendingCount++;
      }
    }

    return {
      'totalIncidents': totalIncidents,
      'resolvedCount': resolvedCount,
      'rejectedCount': rejectedCount,
      'pendingCount': pendingCount,
    };
  }

  Future<Map<String, int>> _getIncidentTypeStats() async {
    final incidentCollection = FirebaseFirestore.instance.collection('Incident Reports');
    final incidents = await incidentCollection.get();

    // Initialize counters using the exact Firebase keys
    Map<String, int> typeCounts = {};
    for (var type in _incidentTypes) {
      typeCounts[type] = 0;
    }

    for (var doc in incidents.docs) {
      final type = doc['Type'];
      // Only increment if it's a recognized type
      if (typeCounts.containsKey(type)) {
        typeCounts[type] = (typeCounts[type] ?? 0) + 1;
      }
    }

    return typeCounts;
  }

  Future<Map<String, Map<String, int>>> fetchIncidentTypeStatusCounts() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Initialize map with Firebase keys
    Map<String, Map<String, int>> typeStatusCounts = {};
    for (var type in _incidentTypes) {
      typeStatusCounts[type] = {
        'Pending': 0,
        'Resolved': 0,
        'Rejected': 0,
      };
    }

    try {
      // Fetch all incidents without date filtering
      final querySnapshot = await firestore.collection('Incident Reports').get();

      for (var doc in querySnapshot.docs) {
        final data = doc.data();

        // Ensure we have Status and Type fields
        if (!data.containsKey('Status') || !data.containsKey('Type')) {
          continue; // Skip documents missing required fields
        }

        final type = data['Type'] ?? 'other';
        final status = data['Status'] ?? 'Pending';

        // Only process if it's a recognized type
        if (typeStatusCounts.containsKey(type)) {
          // Increment the correct counter
          if (status == 'Pending' || status == 'Resolved' || status == 'Rejected') {
            typeStatusCounts[type]![status] = (typeStatusCounts[type]![status] ?? 0) + 1;
          }
        }
      }

      // For debugging
      print('Type-Status Counts: $typeStatusCounts');

    } catch (e) {
      print('Error fetching incidents: $e');
    }

    return typeStatusCounts;
  }

  void _refreshData() {
    setState(() {
      _incidentStats = _getIncidentStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('admin.Admin_Dashboard'.tr(), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF1B9169),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white,
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.analytics, color: Colors.white), text: 'admin.stats_overview'.tr()),
            Tab(icon: Icon(Icons.stacked_line_chart, color: Colors.white), text: 'admin.detailed_analysis'.tr()),
          ],
          indicatorColor: Colors.white,
          indicatorWeight: 3,
        ),
      ),
      body: Column(
        children: [
          // Loading indicator
          if (_isLoading)
            LinearProgressIndicator(
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B9169)),
            ),

          // Error message if any
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _errorMessage,
                style: TextStyle(color: Colors.red),
              ),
            ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildDetailsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _incidentStats,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF1B9169)),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('error_loading_data'.tr() + ': ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _refreshData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1B9169),
                  ),
                  child: Text('admin.retry'.tr()),
                ),
              ],
            ),
          );
        }

        final stats = snapshot.data!;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Cards
              SizedBox(
                height: 180,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildSummaryCard('admin.total_incidents'.tr(), stats['totalIncidents'].toString(), const Color(0xFF1B9169), Icons.list_alt),
                    _buildSummaryCard('incident_report.Resolved'.tr(), stats['resolvedCount'].toString(), const Color(0xFF00D47E), Icons.check_circle_outline),
                    _buildSummaryCard('incident_report.Pending'.tr(), stats['pendingCount'].toString(), Colors.amber, Icons.pending_actions_outlined),
                    _buildSummaryCard('incident_report.Rejected'.tr(), stats['rejectedCount'].toString(), Colors.red, Icons.cancel_outlined),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Divider(height: 32, thickness: 1, color: Colors.grey[300]),

              // Incident Distribution Section
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'admin.distribution'.tr(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B9169),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              FutureBuilder<Map<String, int>>(
                future: _getIncidentTypeStats(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Text('admin.Loading_distribution'.tr(), style: TextStyle(color: Colors.grey)),
                    );
                  } else if (snapshot.hasError) {
                    return Center(child: Text('admin.error_loading_data'.tr()));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('admin.no_data_available'.tr()));
                  } else {
                    final typeStats = snapshot.data!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 300,
                          child: _buildIncidentTypePieChart(typeStats),
                        ),
                        const SizedBox(height: 32), // MORE space between Distribution and next section
                        Divider(thickness: 1, color: Colors.grey[300]),

                        // Status by Type Section
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Text(
                            'admin.Status_by_Type'.tr(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B9169),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        FutureBuilder<Map<String, Map<String, int>>>(
                          future: fetchIncidentTypeStatusCounts(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Center(
                                child: Text('admin.Loading_status_by_type'.tr(), style: TextStyle(color: Colors.grey)),
                              );
                            } else if (snapshot.hasError) {
                              return Center(child: Text('admin.error_loading_data'.tr()));
                            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return Center(child: Text('admin.no_data_available'.tr()));
                            } else {
                              final statusData = snapshot.data!;
                              return _buildStatusByTypeBarChart(statusData);
                            }
                          },
                        ),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'admin.incidents_types'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B9169)),
            ),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, int>>(
              future: _getIncidentTypeStats(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF1B9169)));
                } else if (snapshot.hasError) {
                  return Center(child: Text('admin.error_loading_data'.tr()));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('admin.no_data_available'.tr()));
                } else {
                  final typeStats = snapshot.data!;
                  return _buildIncidentTypeList(typeStats);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color, IconData icon) {
    return Container(
      width: 160,
      margin: EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 30,
            ),
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // Map incident types to their corresponding colors
  final Map<String, Color> _incidentTypeColors = {
    'accident': Colors.red,
    'breakdown': Colors.amber,
    'Road_Blockages': Colors.blue,
    'Roadwork': const Color(0xFF00D47E),
    'Special_Events': Colors.teal,
    'other': Colors.grey,
  };

  // Map incident types to their soft colors (for UI elements that need lighter colors)
  final Map<String, Color> _incidentTypeSoftColors = {
    'accident': Colors.red.withOpacity(0.6),
    'breakdown': Colors.amber.withOpacity(0.6),
    'Road_Blockages': Colors.blue.withOpacity(0.6),
    'Roadwork': Color(0xFF00D47E).withOpacity(0.6),
    'Special_Events': Colors.teal.withOpacity(0.4),
    'other': Colors.grey.withOpacity(0.6),
  };

  // Map incident status to their corresponding colors
  final Map<String, Color> _incidentStatusColors = {
    'Pending': Colors.amber,
    'Resolved': Color(0xFF00D47E),
    'Rejected': Colors.red,
  };

  PieChartSectionData _buildPieChartSection({
    required Color color,
    required double value,
    required String title,
    required double radius,
  }) {
    return PieChartSectionData(
      color: color.withOpacity(0.85), // Softer tone
      value: value,
      title: value > 5 ? title : '', // Hide title if too small for clarity
      radius: radius,
      titleStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: 0.3,
      ),
      badgeWidget: null, // Optionally you can add a badge widget for fancier charts
      badgePositionPercentageOffset: .98,
    );
  }

  List<PieChartSectionData> _buildIncidentTypeSections(Map<String, int> typeStats) {
    final total = typeStats.values.fold(0, (sum, count) => sum + count);

    return typeStats.entries.map((entry) {
      final percentage = total > 0 ? (entry.value / total) * 100 : 0.0;
      final showTitle = percentage >= 5; // Only show title if >=5%

      return _buildPieChartSection(
        color: _incidentTypeColors[entry.key] ?? Colors.grey,
        value: percentage,
        title: showTitle ? '${percentage.toStringAsFixed(1)}%' : '',
        radius: 50 + (percentage > 10 ? 8 : 0),
      );
    }).toList();
  }

  Widget _buildIncidentTypePieChart(Map<String, int> typeStats) {
    final total = typeStats.values.fold(0, (sum, count) => sum + count);

    if (total == 0) {
      return Center(
        child: Text(
          'admin.no_data_available'.tr(),
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            sections: _buildIncidentTypeSections(typeStats),
            centerSpaceRadius: 70,
            sectionsSpace: 3,
            startDegreeOffset: -90,
            pieTouchData: PieTouchData(
              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                // Touchable chart functionality can be implemented here
              },
            ),
            borderData: FlBorderData(show: false),
          ),
          swapAnimationDuration: const Duration(milliseconds: 500),
          swapAnimationCurve: Curves.easeOutCubic,
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$total',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D3142), // Dark, modern text color
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'admin.incidents'.tr(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusByTypeBarChart(Map<String, Map<String, int>> typeStatusCounts) {
    // Only include types that have at least one incident
    final List<String> types = typeStatusCounts.keys.where((type) {
      final counts = typeStatusCounts[type]!;
      return (counts['Pending'] ?? 0) > 0 || (counts['Resolved'] ?? 0) > 0 || (counts['Rejected'] ?? 0) > 0;
    }).toList();

    if (types.isEmpty) {
      return Center(child: Text('admin.no_data_available'.tr(), style: const TextStyle(fontSize: 14, color: Colors.grey)));
    }

    double maxY = typeStatusCounts.values
        .map((statusMap) => statusMap.values.fold(0, (sum, count) => sum + count))
        .fold(0, (prev, curr) => curr > prev ? curr : prev)
        .toDouble();

    if (maxY == 0) {
      return Center(child: Text('admin.no_data_available'.tr(), style: const TextStyle(fontSize: 14, color: Colors.grey)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 280,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: types.length * 80.0,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceBetween,
                  maxY: maxY * 1.2,
                  barTouchData: BarTouchData(
                    enabled: true,
                    handleBuiltInTouches: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: Colors.black87,
                      tooltipRoundedRadius: 12,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final type = types[group.x.toInt()];
                        final counts = typeStatusCounts[type]!;
                        final total = (counts['Pending'] ?? 0) + (counts['Resolved'] ?? 0) + (counts['Rejected'] ?? 0);

                        return BarTooltipItem(
                          '${_translateIncidentType(type)}\nTotal: $total',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < types.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                _translateIncidentType(types[value.toInt()]),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.black87),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: (maxY / 5).ceilToDouble(),
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const Text('0', style: TextStyle(fontSize: 10));
                          return Text('${value.toInt()}', style: const TextStyle(fontSize: 10, color: Colors.black54));
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    horizontalInterval: (maxY / 5).ceilToDouble(),
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.shade300,
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    ),
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                      left: BorderSide(color: Colors.grey.shade300, width: 1),
                    ),
                  ),
                  barGroups: List.generate(types.length, (index) {
                    final type = types[index];
                    final counts = typeStatusCounts[type]!;
                    final pending = (counts['Pending'] ?? 0).toDouble();
                    final resolved = (counts['Resolved'] ?? 0).toDouble();
                    final rejected = (counts['Rejected'] ?? 0).toDouble();

                    return BarChartGroupData(
                      x: index,
                      barsSpace: 2,
                      barRods: [
                        BarChartRodData(
                          toY: pending + resolved + rejected,
                          width: 28,
                          rodStackItems: [
                            BarChartRodStackItem(0, pending, Colors.amber), // Pending
                            BarChartRodStackItem(pending, pending + resolved, const Color(0xFF00D47E)), // Resolved
                            BarChartRodStackItem(pending + resolved, pending + resolved + rejected, Colors.red), // Rejected
                          ],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ],
                    );
                  }),
                  groupsSpace: 28,
                ),
                swapAnimationDuration: const Duration(milliseconds: 700),
                swapAnimationCurve: Curves.easeOutExpo,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Wrap(
            spacing: 24,
            runSpacing: 8,
            children: [
              _buildLegendItem(color: Colors.amber, label: 'incident_report.Pending'.tr()),
              _buildLegendItem(color: const Color(0xFF00D47E), label: 'incident_report.Resolved'.tr()),
              _buildLegendItem(color: Colors.red, label: 'incident_report.Rejected'.tr()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  // Translate incident type to display format using translation keys
  String _translateIncidentType(String type) {
    final translationKey = _incidentTypeTranslationKeys[type];
    if (translationKey != null) {
      return translationKey.tr();
    }
    return type.tr(); // Fallback with direct translation
  }

  // Get icon path for a specific incident type
  String _getIncidentTypeIconPath(String type) {
    final iconPaths = {
      'accident': 'assets/GPS/accident_icon.png',
      'breakdown': 'assets/GPS/breakdown_icon.png',
      'Road_Blockages': 'assets/GPS/circulation.png',
      'Roadwork': 'assets/GPS/roadwork.png',
      'Special_Events': 'assets/GPS/event.png',
      'other': 'assets/GPS/other.png',
    };

    return iconPaths[type] ?? 'assets/GPS/other.png';
  }
  Widget _buildIncidentTypeList(Map<String, int> typeStats) {
    final sortedEntries = typeStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedEntries.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final entry = sortedEntries[index];
        final incidentType = entry.key;
        final count = entry.value;
        final softColor = _incidentTypeSoftColors[incidentType] ?? Colors.grey;
        final iconPath = _getIncidentTypeIconPath(incidentType);

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.15),
                blurRadius: 15,
                offset: const Offset(0, 6),
                spreadRadius: 1,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
              colorScheme: ColorScheme.fromSwatch().copyWith(
                secondary: softColor,
              ),
            ),
            child: ExpansionTile(
              backgroundColor: Colors.white,
              collapsedBackgroundColor: Colors.white,
              tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,

              // Icon leading
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: softColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: iconPath.isNotEmpty
                      ? Image.asset(
                    iconPath,
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                  )
                      : const Icon(Icons.category, color: Colors.white, size: 24),
                ),
              ),

              // Title
              title: Text(
                _translateIncidentType(incidentType),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Color(0xFF2D3142),
                ),
              ),

              // Subtitle with count
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF9A9A9A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              children: [
                // Divider
                Container(
                  height: 1,
                  color: Colors.grey.shade200,
                ),
                const SizedBox(height: 16),

                // Status Section
                FutureBuilder<Map<String, Map<String, int>>>(
                  future: fetchIncidentTypeStatusCounts(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF1B9169),
                          ),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.hasError) {
                      return Center(
                        child: Text(
                          'no_status_data'.tr(),
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      );
                    }

                    final statusCounts = snapshot.data![incidentType] ?? {};
                    if (statusCounts.isEmpty) {
                      return Center(
                        child: Text(
                          'no_status_data'.tr(),
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      );
                    }

                    final totalForType = statusCounts.values.fold(0, (sum, count) => sum + count);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status distribution heading
                        Text(
                          'admin.Status_Distribution'.tr(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Color(0xFF2D3142),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Status bar
                        _buildIncidentStatusBar(statusCounts),
                        const SizedBox(height: 20),

                        // Status legend
                        _buildIncidentStatusLegend(statusCounts, totalForType),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIncidentStatusBar(Map<String, int> statusCounts) {
    final total = statusCounts.values.fold(0, (sum, count) => sum + count);
    if (total == 0) return const SizedBox.shrink();

    final statusEntries = statusCounts.entries.toList();

    return Container(
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: statusEntries.map((entry) {
          final statusName = entry.key;
          final count = entry.value;
          final width = total > 0 ? count / total : 0.0;

          if (width <= 0) return const SizedBox.shrink();

          return Expanded(
            flex: (width * 100).toInt() + 1,
            child: Container(color: _incidentStatusColors[statusName] ?? Colors.grey),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildIncidentStatusLegend(Map<String, int> statusCounts, int totalForType) {
    final sortedEntries = statusCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Wrap(
      spacing: 20,
      runSpacing: 16,
      children: sortedEntries.map((entry) {
        final statusName = entry.key;
        final count = entry.value;
        final color = _incidentStatusColors[statusName] ?? Colors.grey;
        final percentage = totalForType > 0
            ? (count / totalForType * 100.0)
            : 0.0;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'incident_report.$statusName'.tr(),
                style: TextStyle(
                  color: color.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$count (${percentage.toStringAsFixed(1)}%)',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: color,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

}
