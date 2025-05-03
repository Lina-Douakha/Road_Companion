import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import 'dart:math';

class StatisticsIncidents extends StatefulWidget {
  @override
  _StatisticsIncidentsState createState() => _StatisticsIncidentsState();
}

class _StatisticsIncidentsState extends State<StatisticsIncidents> with SingleTickerProviderStateMixin {
  late Future<Map<String, dynamic>> _incidentStats;
  late TabController _tabController;

  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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

    // Récupérer tous les incidents sans filtrage par date
    final incidents = await incidentCollection.get();

    // Initialize counters
    int accidentCount = 0;
    int breakdownCount = 0;
    int roadBlockagesCount = 0;
    int roadworkCount = 0;
    int eventsCount = 0;
    int otherCount = 0;

    for (var doc in incidents.docs) {
      final type = doc['Type'];

      switch (type) {
        case 'accident':
          accidentCount++;
          break;
        case 'breakdown':
          breakdownCount++;
          break;
        case 'Road_Blockages':
          roadBlockagesCount++;
          break;
        case 'Roadwork':
          roadworkCount++;
          break;
        case 'Special_Events':
          eventsCount++;
          break;
        case 'other':
          otherCount++;
          break;
      }
    }

    return {
      'Accident': accidentCount,
      'Breakdown': breakdownCount,
      'Road Blockages': roadBlockagesCount,
      'Roadwork': roadworkCount,
      'Special Events': eventsCount,
      'Other': otherCount,
    };
  }
  Future<Map<String, Map<String, int>>> fetchIncidentTypeStatusCounts() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Initialize empty map
    Map<String, Map<String, int>> typeStatusCounts = {};

    try {
      // Fetch all incidents without date filtering
      final querySnapshot = await firestore.collection('Incident Reports').get();

      // Pre-initialize all incident types with zero counts
      final allTypes = ['Accident', 'Breakdown', 'Road Blockages', 'Roadwork', 'Special Events', 'Other'];
      for (var type in allTypes) {
        typeStatusCounts[type] = {
          'Pending': 0,
          'Resolved': 0,
          'Rejected': 0,
        };
      }

      for (var doc in querySnapshot.docs) {
        final data = doc.data();

        // Ensure we have Status and Type fields
        if (!data.containsKey('Status') || !data.containsKey('Type')) {
          continue; // Skip documents missing required fields
        }

        final type = data['Type'] ?? 'Other';
        final status = data['Status'] ?? 'Pending';

        // Normalize type values
        String incidentType;
        if (type == 'accident') incidentType = 'Accident';
        else if (type == 'breakdown') incidentType = 'Breakdown';
        else if (type == 'Road_Blockages') incidentType = 'Road Blockages';
        else if (type == 'Roadwork') incidentType = 'Roadwork';
        else if (type == 'Special_Events') incidentType = 'Special Events';
        else incidentType = 'Other';

        // Increment the correct counter
        if (status == 'Pending') {
          typeStatusCounts[incidentType]!['Pending'] = (typeStatusCounts[incidentType]!['Pending'] ?? 0) + 1;
        } else if (status == 'Resolved') {
          typeStatusCounts[incidentType]!['Resolved'] = (typeStatusCounts[incidentType]!['Resolved'] ?? 0) + 1;
        } else if (status == 'Rejected') {
          typeStatusCounts[incidentType]!['Rejected'] = (typeStatusCounts[incidentType]!['Rejected'] ?? 0) + 1;
        }
      }

      // Pour débugger, affichez les données récupérées
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

  Future<void> _exportStatistics(String format) async {
    // In a real app, you would implement export functionality here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('export_started'.tr() + ': $format')),
    );

    // Simulate export process
    await Future.delayed(Duration(seconds: 2));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('export_completed'.tr())),
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
        title: Text(
          'Les statistiques'.tr(),
          style: TextStyle(
            color: Color(0xFF1B9169),
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Color(0xFF1B9169)),
            onPressed: _refreshData,
          ),

        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Color(0xFF1B9169),
          indicatorColor: Color(0xFF1B9169),
          tabs: [
            Tab(icon: Icon(Icons.dashboard), text: 'overview'.tr()),
            Tab(icon: Icon(Icons.category), text: 'details'.tr()),
          ],
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
  } Widget _buildOverviewTab() {
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
                  child: Text('retry'.tr()),
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
              Text(
                'overview'.tr(),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold,color: Color(0xFF1B9169)),
              ),
              const SizedBox(height: 16),

              // Summary Cards
              SizedBox(
                height: 180,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildSummaryCard('total_incidents'.tr(), stats['totalIncidents'].toString(), const Color(0xFF1B9169), Icons.list_alt),
                    _buildSummaryCard('resolved'.tr(), stats['resolvedCount'].toString(), const Color(0xFF4CAF50), Icons.check_circle_outline),
                    _buildSummaryCard('pending'.tr(), stats['pendingCount'].toString(), const Color(0xFFFFA726), Icons.pending_actions_outlined),
                    _buildSummaryCard('rejected'.tr(), stats['rejectedCount'].toString(), const Color(0xFFE53935), Icons.cancel_outlined),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Divider(height: 32, thickness: 1, color: Colors.grey[300]),
// Incident Distribution Section
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'distribution'.tr(),
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
                    return const Center(
                      child: Text('Loading distribution...', style: TextStyle(color: Colors.grey)),
                    );
                  } else if (snapshot.hasError) {
                    return Center(child: Text('error_loading_data'.tr()));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('no_data_available'.tr()));
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
                            'Statut par Type'.tr(),
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
                              return const Center(
                                child: Text('Loading status by type...', style: TextStyle(color: Colors.grey)),
                              );
                            } else if (snapshot.hasError) {
                              return Center(child: Text('error_loading_data'.tr()));
                            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return Center(child: Text('no_data_available'.tr()));
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
              'Les types des incidents'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold,color: Color(0xFF1B9169),),
            ),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, int>>(
              future: _getIncidentTypeStats(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF1B9169)));
                } else if (snapshot.hasError) {
                  return Center(child: Text('error_loading_data'.tr()));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('no_data_available'.tr()));
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
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

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
          'No Data',
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
                if (event is FlTapUpEvent && pieTouchResponse?.touchedSection != null) {
                  final touchedIndex = pieTouchResponse!.touchedSection!.touchedSectionIndex;
                  // TODO: Handle tap (example: show details or animate)
                }
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
              'Incidents',
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
    final List<String> types = typeStatusCounts.keys.where((type) {
      final counts = typeStatusCounts[type]!;
      return (counts['Pending'] ?? 0) > 0 || (counts['Resolved'] ?? 0) > 0 || (counts['Rejected'] ?? 0) > 0;
    }).toList();

    if (types.isEmpty) {
      return Center(child: Text('no_data_available'.tr(), style: const TextStyle(fontSize: 14, color: Colors.grey)));
    }

    double maxY = typeStatusCounts.values
        .map((statusMap) => statusMap.values.fold(0, (sum, count) => sum + count))
        .fold(0, (prev, curr) => curr > prev ? curr : prev)
        .toDouble();

    if (maxY == 0) {
      return Center(child: Text('no_data_available'.tr(), style: const TextStyle(fontSize: 14, color: Colors.grey)));
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
                          '$type\nTotal: $total',
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
                                _formatTypeName(types[value.toInt()]),
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
                    final counts = typeStatusCounts[types[index]]!;
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
                            BarChartRodStackItem(0, pending, const Color(0xFFFFC107)), // Softer Pending
                            BarChartRodStackItem(pending, pending + resolved, const Color(0xFF66BB6A)), // Softer Resolved
                            BarChartRodStackItem(pending + resolved, pending + resolved + rejected, const Color(0xFFEF5350)), // Softer Rejected
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
              _buildLegendItem(color: const Color(0xFFFFC107), label: 'Pending'),
              _buildLegendItem(color: const Color(0xFF66BB6A), label: 'Resolved'),
              _buildLegendItem(color: const Color(0xFFEF5350), label: 'Rejected'),
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

  Widget _buildTrendLineChart(List<Map<String, dynamic>> trendData) {
    // Process data for the line chart
    List<FlSpot> pendingSpots = [];
    List<FlSpot> resolvedSpots = [];
    List<FlSpot> rejectedSpots = [];

    for (int i = 0; i < trendData.length; i++) {
      final item = trendData[i];
      pendingSpots.add(FlSpot(i.toDouble(), item['Pending'].toDouble()));
      resolvedSpots.add(FlSpot(i.toDouble(), item['Resolved'].toDouble()));
      rejectedSpots.add(FlSpot(i.toDouble(), item['Rejected'].toDouble()));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 1,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(), // just show the number (index)
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
              reservedSize: 30,
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade300, width: 1),
            left: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
        ),
        minX: 0,
        maxX: (trendData.length - 1).toDouble(),
        minY: 0,
        maxY: trendData.fold(0, (prev, item) =>
            max(prev, max(
                item['Pending'] as int,
                max(item['Resolved'] as int, item['Rejected'] as int)
            ))
        ).toDouble() * 1.2,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.grey.shade800,
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: pendingSpots,
            isCurved: true,
            color: const Color(0xFFFFA726), // Orange
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
          LineChartBarData(
            spots: resolvedSpots,
            isCurved: true,
            color: const Color(0xFF4CAF50), // Green
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
          LineChartBarData(
            spots: rejectedSpots,
            isCurved: true,
            color: const Color(0xFFE53935), // Red
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }
  Widget _buildDailyBarChart(List<Map<String, dynamic>> trendData) {
    return BarChart(
      swapAnimationDuration: const Duration(milliseconds: 700),
      swapAnimationCurve: Curves.easeOutBack,

      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: trendData.fold(0, (prev, item) =>
            max(prev, (item['Pending'] as int) + (item['Resolved'] as int) + (item['Rejected'] as int))
        ).toDouble() * 1.2,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.grey.shade800,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < trendData.length && index % 3 == 0) {
                  // Show only every 3rd date to avoid overcrowding
                  final date = DateTime.parse(trendData[index]['date']);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('MM/dd').format(date),
                      style: TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(fontSize: 10),
                );
              },
              reservedSize: 30,
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          horizontalInterval: 1,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade300, width: 1),
            left: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
        ),
        barGroups: List.generate(
          trendData.length,
              (index) {
            final item = trendData[index];
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: (item['Pending'] + item['Resolved'] + item['Rejected']).toDouble(),
                  color: const Color(0xFF1B9169),
                  width: 10,
                  borderRadius: BorderRadius.circular(2),
                  rodStackItems: [
                    BarChartRodStackItem(
                        0,
                        item['Pending'].toDouble(),
                        const Color(0xFFFFA726)
                    ),
                    BarChartRodStackItem(
                        item['Pending'].toDouble(),
                        item['Pending'].toDouble() + item['Resolved'].toDouble(),
                        const Color(0xFF4CAF50)
                    ),
                    BarChartRodStackItem(
                        item['Pending'].toDouble() + item['Resolved'].toDouble(),
                        item['Pending'].toDouble() + item['Resolved'].toDouble() + item['Rejected'].toDouble(),
                        const Color(0xFFE53935)
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
  String _formatTypeName(String type) {
    return type.replaceAll('_', ' '); // Special_Events -> Special Events
  }


  final Map<String, Color> _incidentTypeColors = {
    'Accident': Colors.redAccent,
    'Breakdown': Colors.orangeAccent,
    'Road Blockages': Colors.blueAccent,
    'Roadwork': Colors.greenAccent,
    'Special Events': Colors.teal,
    'Other': Colors.purpleAccent,
  };
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
                incidentType.tr(),
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
                  '$count incidents',
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
                          'Status Distribution'.tr(),
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
                statusName.tr(),
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

// Colors mapping for incident statuses
  final Map<String, Color> _incidentStatusColors = {
    'Pending': Color(0xFFFFA726),
    'Resolved': Color(0xFF4CAF50),
    'Rejected': Color(0xFFE53935),
  };

  // Function to get the incident icon path
  String _getIncidentTypeIconPath(String category) {
    final incidentTypes = {
      'Accident': 'assets/GPS/accident_icon.png',
      'Breakdown': 'assets/GPS/breakdown_icon.png',
      'Road Blockages': 'assets/GPS/circulation.png',
      'Roadwork': 'assets/GPS/roadwork.png',
      'Special Events': 'assets/GPS/event.png',
      'Other': 'assets/GPS/other.png',
    };

    return incidentTypes[category] ?? 'assets/GPS/other.png';
  }

  final Map<String, Color> _incidentTypeSoftColors = {
    'Accident': Colors.redAccent.withOpacity(0.6),  // Softer red
    'Breakdown': Colors.orangeAccent.withOpacity(0.6),  // Softer orange
    'Road Blockages': Colors.blueAccent.withOpacity(0.6),  // Softer blue
    'Roadwork': Colors.greenAccent.withOpacity(0.6),  // Softer green
    'Special Events': Colors.tealAccent.withOpacity(0.6),  // Softer teal
    'Other': Colors.purpleAccent.withOpacity(0.6),  // Softer purple
  };
}
// Function to get the incident icon path
String _getIncidentTypeIconPath2(String category) {
  switch (category.toLowerCase()) {
    case 'accident':
      return 'assets/GPS/accident_icon.png';
    case 'breakdown':
      return 'assets/GPS/breakdown_icon.png';
    case 'road_blockages':
      return 'assets/GPS/circulation.png';
    case 'roadwork':
      return 'assets/GPS/roadwork.png';
    case 'special_events':
      return 'assets/GPS/event.png';
    case 'other':
    default:
      return 'assets/GPS/other.png';
  }
}

// Softer background colors for the incidents
final Map<String, Color> _incidentTypeSoftColors2 = {
  'accident': Colors.redAccent.withOpacity(0.6),
  'breakdown': Colors.orangeAccent.withOpacity(0.6),
  'road_blockages': Colors.blueAccent.withOpacity(0.6),
  'roadwork': Colors.greenAccent.withOpacity(0.6),
  'special_events': Colors.tealAccent.withOpacity(0.6),
  'other': Colors.purpleAccent.withOpacity(0.6),
};
