import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminStatScreen extends StatefulWidget {
  @override
  _AdminStatScreenState createState() => _AdminStatScreenState();
}

class _AdminStatScreenState extends State<AdminStatScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic> stats = {};
  bool loading = true;
  late TabController _tabController;
  int _selectedIndex = 0;
  int totalTests = 0;

  final List<Color> gradientColors = [
    const Color(0xff23b6e6),
    const Color(0xff02d39a),
  ];

  @override
  void initState() {
    super.initState();
    fetchStatistics();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  Future<void> fetchStatistics() async {
    final snapshot = await FirebaseFirestore.instance.collection('UserResponses').get();
    final allDocs = snapshot.docs;

    final examTestSnapshot = await FirebaseFirestore.instance.collection('Exam Test').get();
    final totalTests = examTestSnapshot.docs.length;

    final Map<String, List<Map<String, dynamic>>> groupedByTest = {};

    for (var doc in allDocs) {
      final data = doc.data();
      final testID = data['TestID'];
      final score = data['Score'] is num ? double.parse((data['Score'] as num).toStringAsFixed(2)) : data['Score'];
      final timestamp = data['Timestamp'];

      if (testID != null && score != null) {
        groupedByTest.putIfAbsent(testID, () => []);
        groupedByTest[testID]!.add({
          'score': score,
          'timestamp': timestamp,
        });
      }
    }

    final Map<String, dynamic> calculatedStats = {};

    groupedByTest.forEach((testID, responses) {
      final scores = responses.map((e) => e['score'] as num).toList();
      final timestamps = responses.map((e) => e['timestamp'] as Timestamp).toList();

      final average = scores.isNotEmpty
          ? double.parse((scores.reduce((a, b) => a + b) / scores.length).toStringAsFixed(2))
          : 0.0;

      final latestTime = timestamps.isNotEmpty
          ? timestamps.reduce((a, b) => a.compareTo(b) > 0 ? a : b)
          : Timestamp.now();

      final highestScore = scores.isNotEmpty
          ? double.parse(scores.reduce((a, b) => a > b ? a : b).toStringAsFixed(2))
          : 0.0;

      final lowestScore = scores.isNotEmpty
          ? double.parse(scores.reduce((a, b) => a < b ? a : b).toStringAsFixed(2))
          : 0.0;

      final sortedData = List.generate(responses.length, (i) => {
        'score': scores[i],
        'timestamp': timestamps[i],
      })..sort((a, b) => (a['timestamp'] as Timestamp).compareTo(b['timestamp'] as Timestamp));

      final trendData = sortedData.map((e) => {
        'score': double.parse((e['score'] as num).toStringAsFixed(2)),
        'date': (e['timestamp'] as Timestamp).toDate(),
      }).toList();

      calculatedStats[testID] = {
        'count': scores.length,
        'average': average.toStringAsFixed(2),
        'averageRaw': average,
        'latest': DateFormat('yyyy-MM-dd – kk:mm').format(latestTime.toDate()),
        'highestScore': highestScore,
        'lowestScore': lowestScore,
        'trendData': trendData,
      };
    });

    setState(() {
      stats = calculatedStats;
      loading = false;
      this.totalTests = totalTests;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Admin Dashboard", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor:Color(0xFF1B9169),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white,
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.analytics, color: Colors.white,), text: "Stats Overview"),
            Tab(icon: Icon(Icons.stacked_line_chart, color: Colors.white), text: "Detailed Analysis"),
          ],
          indicatorColor: Colors.white,
          indicatorWeight: 3,
        ),
      ),
      body: loading
          ? _buildLoadingView()
          : stats.isEmpty
          ? _buildEmptyDataView()
          : TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardView(),
          _buildDetailedAnalysisView(),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D47E)),
            ),
            SizedBox(height: 20),
            Text(
              "Loading dashboard data...",
              style: TextStyle(
                color: Color(0xFF1B9169),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyDataView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            "No Data Available",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            "No test responses have been submitted yet",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardView() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(),
          SizedBox(height: 20),
          Text(
            "Test Performance Overview",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B9169),
            ),
          ),
          SizedBox(height: 10),
          Expanded(
            child: _buildTestList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    // Calculate total tests and average response count
    int totalActiveTests = stats.length;
    int totalResponses = 0;

    stats.forEach((test, data) {
      totalResponses += data['count'] as int;
    });

    double avgResponses = totalActiveTests > 0 ? totalResponses / totalActiveTests : 0;
    return Container(
      height: 150,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 12), // add little side padding
        children: [
          _buildSummaryCard(
            "Total Tests",
            totalTests.toString(),
            Colors.indigo,
            Icons.quiz,
          ),
          SizedBox(width: 12),
          _buildSummaryCard(
            "Active Tests",
            totalActiveTests.toString(),
            Color(0xFF1B9169), // nice turquoise
            Icons.check_circle,
          ),// space between cards
          SizedBox(width: 12),
          _buildSummaryCard(
            "Total Responses",
            totalResponses.toString(),
            Color(0xFF3498DB), // softer purple
            Icons.people,
          ),
          SizedBox(width: 12),
          _buildSummaryCard(
            "Avg. Responses",
            avgResponses.toStringAsFixed(1),
            Colors.amber, // warm orange
            Icons.analytics,
          ),
        ],
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

  Widget _buildTestList() {
    return ListView.builder(
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final testID = stats.keys.elementAt(index);
        final data = stats[testID];

        // Calculate percentage for progress indicator
        final avgScore = data['averageRaw'] as double;
        final progressValue = avgScore / 30;

        return Container(
          margin: EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedIndex = index;
                _tabController.animateTo(1);  // Switch to detailed tab
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Color(0xFF00D47E).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.assignment,
                          color: Color(0xFF00D47E),
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Test ID: $testID",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color:Color(0xFF1B9169),
                              ),
                            ),
                            Text(
                              "Last Submission: ${data['latest']}",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Color(0xFF00D47E).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "${data['count']} Responses",
                          style: TextStyle(
                            color: Color(0xFF00D47E),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Average Score",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 6),
                            LinearProgressIndicator(
                              value: progressValue.clamp(0.0, 1.0),
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getScoreColor(avgScore),
                              ),
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 16),
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getScoreColor(avgScore).withOpacity(0.1),
                        ),
                        child: Center(
                          child: Text(
                            _formatNumber(data['average']),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _getScoreColor(avgScore),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildStatChip("Highest", _formatNumber(data['highestScore']), Color(0xFF00D47E)),
                        SizedBox(width: 16),
                        _buildStatChip("Lowest", _formatNumber(data['lowestScore']), Colors.red),
                        SizedBox(width: 16),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedIndex = index;
                              _tabController.animateTo(1);
                            });
                          },
                          icon: Icon(Icons.bar_chart, size: 18),
                          label: Text("View Details"),
                          style: TextButton.styleFrom(
                            foregroundColor: Color(0xFF1B9169),
                          ),
                        ),
                      ],
                    ),
                  ),

                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailedAnalysisView() {
    if (stats.isEmpty) return _buildEmptyDataView();

    final testID = stats.keys.elementAt(_selectedIndex);
    final data = stats[testID];
    final trendData = (data['trendData'] as List);


    String dateRange = "No data available";
    if (trendData.isNotEmpty) {
      final firstDate = (trendData.first['date'] as DateTime);
      final lastDate = (trendData.last['date'] as DateTime);
      dateRange = "${DateFormat('MMM dd, yyyy').format(firstDate)} - ${DateFormat('MMM dd, yyyy').format(lastDate)}";
    }


    List<FlSpot> spots = [];
    if (trendData.isNotEmpty) {
      for (int i = 0; i < trendData.length; i++) {
        spots.add(FlSpot(i.toDouble(), (trendData[i]['score'] as num).toDouble()));
      }
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button and title
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: Color(0xFF1B9169)),
                onPressed: () {
                  _tabController.animateTo(0);
                },
              ),
              Text(
                "Test ID: $testID",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B9169),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),

          // Key metrics
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF00D47E), Color(0xFF1B9169)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricItem("Total\nResponses", data['count'].toString(), Colors.white),
                Container(height: 40, width: 1, color: Colors.white.withOpacity(0.3)),
                _buildMetricItem("Average\nScore", _formatNumber(data['average']), Colors.white),
                Container(height: 40, width: 1, color: Colors.white.withOpacity(0.3)),
                _buildMetricItem("Latest\nSubmission", data['latest'].toString().split('–')[0], Colors.white),
              ],
            ),
          ),
          SizedBox(height: 20),


          Container(
            height: 350,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Score Trend Over Time",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B9169),
                      ),
                    ),
                    SizedBox(height: 6),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(0xFFE8F6F0),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Color(0xFF1B9169).withOpacity(0.2)),
                      ),
                      child: Text(
                        dateRange,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1B9169),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Expanded(
                  child: trendData.isEmpty
                      ? Center(child: Text("Not enough data for trends"))
                      : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: 5,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey[300],
                            strokeWidth: 1,
                          );
                        },
                        getDrawingVerticalLine: (value) {
                          return FlLine(
                            color: Colors.grey[300],
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

                              bool isFirstOrLast = value == 0 || value == trendData.length - 1;
                              bool isDivisibleBy5 = value % 5 == 0;

                              if (!isFirstOrLast && !isDivisibleBy5) {
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  child: Text(''),
                                );
                              }

                              if (value >= 0 && value < trendData.length) {
                                final date = (trendData[value.toInt()]['date'] as DateTime);
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  child: Text(
                                    DateFormat('MM/dd').format(date),
                                    style: TextStyle(
                                      color: isFirstOrLast
                                          ? Color(0xFF1B9169)
                                          : Colors.grey[600],
                                      fontSize: 10,
                                      fontWeight: isFirstOrLast ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                );
                              }
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                child: Text(''),
                              );
                            },
                          ),
                        ),

                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 5,
                            getTitlesWidget: (value, meta) {
                              if (value % 5 == 0 && value <= 30) {
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  child: Text(
                                    value.toInt().toString(),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 10,
                                    ),
                                  ),
                                );
                              }
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                child: Text(''),
                              );
                            },
                            reservedSize: 30,
                          ),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),

                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.grey[300]!, width: 1),
                      ),
                      minX: 0,
                      maxX: spots.isEmpty ? 5 : (spots.length - 1).toDouble(),
                      minY: 0,
                      maxY: 30,
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots.isEmpty ? [FlSpot(0, 0), FlSpot(1, 0)] : spots,
                          isCurved: true,
                          gradient: LinearGradient(
                            colors: gradientColors,
                          ),
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,  // Enable dots for clarity
                            getDotPainter: (spot, percent, barData, index) {

                              bool isFirstOrLast = index == 0 || index == spots.length - 1;
                              return FlDotCirclePainter(
                                radius: isFirstOrLast ? 5 : 3.5,
                                color: isFirstOrLast ? Colors.white : barData.gradient!.colors.first,
                                strokeWidth: isFirstOrLast ? 2.5 : 0,
                                strokeColor: isFirstOrLast ? barData.gradient!.colors.first : Colors.transparent,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: gradientColors
                                  .map((color) => color.withOpacity(0.3))
                                  .toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Rest of the UI remains the same
          SizedBox(height: 20),

          // Score Distribution
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Score Distribution",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B9169),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildScoreDistributionItem("Lowest", _formatNumber(data['lowestScore']), Colors.red),
                    _buildScoreDistributionItem("Average", _formatNumber(data['average']), Colors.amber),
                    _buildScoreDistributionItem("Highest", _formatNumber(data['highestScore']), Color(0xFF00D47E)),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
        ],
      ),
    );
  }
  String _formatNumber(dynamic value, [int decimals = 2]) {
    if (value == null) return '0.00';

    if (value is String) {
      try {
        return double.parse(value).toStringAsFixed(decimals);
      } catch (e) {
        return value;
      }
    } else if (value is num) {
      return value.toStringAsFixed(decimals);
    }
    return value.toString();
  }
  Widget _buildMetricItem(String label, String value, Color textColor) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: textColor.withOpacity(0.8),
            fontSize: 12,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
          SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreDistributionItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.1),   // Instead of color[50]
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,                 // Instead of color[700]
              ),
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 24) return Color(0xFF00D47E);
    if (score >= 15) return Colors.amber;
    return Colors.red;
  }
}