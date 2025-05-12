import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import 'dart:math';

class StatisticsUsers extends StatefulWidget {
  @override
  _StatisticsUsersState createState() => _StatisticsUsersState();
}

class _StatisticsUsersState extends State<StatisticsUsers> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<Map<String, dynamic>> _userStats;
  bool _isLoading = false;
  String _errorMessage = '';

  // Define the user type colors
  final Map<String, Color> _userTypeColors = {
    'user': const Color(0xFF00D47E), // Green for regular users
    'mechanic':  Colors.amber, // Blue for mechanics
    'towing_service': Colors.blue, // Orange for towing services
    'parts_supplier': const Color(0xFFE84D5E),
  };

  // Define status colors
  final Map<String, Color> _statusColors = {
    'Active': const Color(0xFF00D47E), // Green
    'Blocked': Colors.amber, // Orange
    'Deleted':  Colors.red, // Red
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _userStats = _fetchUserStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _userStats = _fetchUserStats();
    });

    try {
      await _userStats;
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  Future<Map<String, dynamic>> _fetchUserStats() async {
    try {
      // Get basic user counts
      final userCounts = await fetchUserCounts();

      // Get user type counts
      final userTypeCounts = await fetchUserTypeCounts();

      // Combine all data
      return {
        'activeUsers': userCounts['activeUsers'] ?? 0,
        'blockedUsers': userCounts['blockedUsers'] ?? 0,
        'deletedUsers': userCounts['deletedUsers'] ?? 0,
        'totalUsers': (userCounts['activeUsers'] ?? 0) +
            (userCounts['blockedUsers'] ?? 0) +
            (userCounts['deletedUsers'] ?? 0),
        'userTypeCounts': userTypeCounts,
      };
    } catch (e) {
      print('Error fetching user stats: $e');
      throw Exception('Failed to load user statistics');
    }
  }
  Future<Map<String, int>> fetchUserCounts() async {
    try {
      final firestore = FirebaseFirestore.instance;

      final activeSnapshot = await firestore
          .collection('users')
          .where('isBlocked', isEqualTo: false)
          .get();

      final blockedSnapshot = await firestore
          .collection('users')
          .where('isBlocked', isEqualTo: true)
          .get();

      final deletedSnapshot = await firestore
          .collection('deleted_users')
          .get();

      return {
        'activeUsers': activeSnapshot.size,
        'blockedUsers': blockedSnapshot.size,
        'deletedUsers': deletedSnapshot.size,
      };
    } catch (e) {
      print('Error fetching user counts: $e');
      return {
        'activeUsers': 0,
        'blockedUsers': 0,
        'deletedUsers': 0,
      };
    }
  }

  // Method to get user counts by user type
  Future<Map<String, int>> fetchUserTypeCounts() async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Initialize counts for each user type
      final Map<String, int> typeCounts = {
        'user': 0,
        'mechanic': 0,
        'towing_service': 0,
        'parts_supplier': 0,
      };

      // Count active and blocked users by type
      final usersSnapshot = await firestore.collection('users').get();
      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        if (data.containsKey('Role')) {
          final type = _normalizeUserType(data['Role']);
          typeCounts[type] = (typeCounts[type] ?? 0) + 1;
        }
      }

      // Count deleted users by type
      final deletedSnapshot = await firestore.collection('deleted_users').get();
      for (var doc in deletedSnapshot.docs) {
        final data = doc.data();
        if (data.containsKey('Role')) {
          final type = _normalizeUserType(data['Role']);
          typeCounts[type] = (typeCounts[type] ?? 0) + 1;
        }
      }

      return typeCounts;
    } catch (e) {
      print('Error fetching user type counts: $e');
      return {
        'user': 0,
        'mechanic': 0,
        'towing_service': 0,
        'parts_supplier': 0,
      };
    }
  }
  Future<Map<String, Map<String, int>>> fetchUserTypeStatusCounts() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Initialize empty map
    Map<String, Map<String, int>> typeStatusCounts = {};

    try {
      // Pre-initialize all user types with zero counts
      final allTypes = [
        'user',
        'mechanic',
        'towing_service',
        'parts_supplier',
      ];
      for (var type in allTypes) {
        typeStatusCounts[type] = {
          'Active': 0,
          'Blocked': 0,
          'Deleted': 0,
        };
      }

      // Get all users from the users collection
      final usersSnapshot = await firestore.collection('users').get();

      // Process each user document
      for (var doc in usersSnapshot.docs) {
        final data = doc.data();

        // Check for Role field instead of type
        if (!data.containsKey('Role')) {
          continue;
        }

        final userType = _normalizeUserType(data['Role']);

        // Directly check isBlocked field instead of using determineUserStatus
        final isBlocked = data['isBlocked'] == true;
        final status = isBlocked ? 'Blocked' : 'Active';

        // Make sure the user type is in our predefined list
        if (typeStatusCounts.containsKey(userType)) {
          // Increment the appropriate counter
          typeStatusCounts[userType]![status] =
              (typeStatusCounts[userType]![status] ?? 0) + 1;
        }
      }

      // Check deleted_users collection for deleted users
      final deletedUsersSnapshot = await firestore.collection('deleted_users').get();
      for (var doc in deletedUsersSnapshot.docs) {
        final data = doc.data();

        // Check for Role field in deleted_users collection
        if (!data.containsKey('Role')) {
          continue;
        }

        final userType = _normalizeUserType(data['Role']);

        // Make sure the user type is in our predefined list
        if (typeStatusCounts.containsKey(userType)) {
          // All users in deleted_users collection have Deleted status
          typeStatusCounts[userType]!['Deleted'] =
              (typeStatusCounts[userType]!['Deleted'] ?? 0) + 1;
        }
      }

      print('User Type-Status Counts: $typeStatusCounts');
      return typeStatusCounts;
    } catch (e) {
      print('Error fetching user type status counts: $e');
      return typeStatusCounts;
    }
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

  // Modified version of this function to correctly handle normalization for storage
  // and proper translation for display
  String _normalizeUserType(dynamic type) {
    if (type == null) return 'user';  // Default to user if null

    // Convert to lowercase for case-insensitive comparison
    String typeStr = type.toString().toLowerCase();

    // Return the standardized internal type names for database use
    switch (typeStr) {
      case 'user':
      case 'registration.user':
        return 'user';
      case 'mechanic':
      case 'registration.mechanic':
        return 'mechanic';
      case 'towing_service':
      case 'registration.towing_service':
        return 'towing_service';
      case 'parts_supplier':
      case 'registration.parts_supplier':
        return 'parts_supplier';
      default:
      // Return 'user' as default for unrecognized types
        print('Unrecognized user type: $type, defaulting to "user"');
        return 'user';
    }
  }

  // New function to get translated display name for user types
  String _getTranslatedUserType(String userType) {
    switch (userType) {
      case 'user':
        return 'registration.user'.tr();
      case 'mechanic':
        return 'registration.mechanic'.tr();
      case 'towing_service':
        return 'registration.towing_service'.tr();
      case 'parts_supplier':
        return 'registration.parts_supplier'.tr();
      default:
        return userType;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('admin.Admin_Dashboard'.tr(), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor:Color(0xFF1B9169),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white,
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.analytics, color: Colors.white,), text: 'admin.stats_overview'.tr()),
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
      future: _userStats,
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
              Text(
                'admin.overview'.tr(),
                style: const TextStyle(fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B9169)),
              ),
              const SizedBox(height: 16),

              // Summary Cards
              SizedBox(
                height: 180,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildSummaryCard(
                        'admin.total_users'.tr(), stats['totalUsers'].toString(),
                        const Color(0xFF1B9169), Icons.people),
                    _buildSummaryCard(
                        'admin.active_users'.tr(), stats['activeUsers'].toString(),
                        const Color(0xFF00D47E), Icons.check_circle_outline),
                    _buildSummaryCard(
                        'admin.blocked_users'.tr(), stats['blockedUsers'].toString(),
                        Colors.amber, Icons.block),
                    _buildSummaryCard(
                        'admin.deleted_users'.tr(), stats['deletedUsers'].toString(),
                        Colors.red, Icons.delete_forever),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Divider(height: 32, thickness: 1, color: Colors.grey[300]),

              // Users Distribution Section
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'admin.distribution'.tr(),
                  style: const TextStyle(fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B9169)),
                ),
              ),
              const SizedBox(height: 16),

              FutureBuilder<Map<String, int>>(
                future: fetchUserTypeCounts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return  Center(
                      child: Text('admin.Loading_distribution'.tr(),
                          style: TextStyle(color: Colors.grey)),
                    );
                  } else if (snapshot.hasError) {
                    return Center(child: Text('admin.error_loading_data'.tr()));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('admin.no_data_available'.tr()));
                  } else {
                    final userTypeStats = snapshot.data!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 300,
                          child: _buildUserTypePieChart(userTypeStats),
                        ),
                        const SizedBox(height: 32),
                        Divider(thickness: 1, color: Colors.grey[300]),

                        // Status by User Type Section
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Text(
                            'admin.Status_by_Type'.tr(),
                            style: const TextStyle(fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B9169)),
                          ),
                        ),
                        const SizedBox(height: 16),

                        FutureBuilder<Map<String, Map<String, int>>>(
                          future: fetchUserTypeStatusCounts(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(
                                child: Text('admin.Loading_status_by_type', style: TextStyle(color: Colors.grey)),
                              );
                            } else if (snapshot.hasError) {
                              return Center(child: Text('admin.error_loading_data'.tr()));
                            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return Center(child: Text('admin.no_data_available'.tr()));
                            } else {
                              final userStatusData = snapshot.data!;
                              print(userStatusData);  // Add this line to print the data and debug
                              return _buildUserStatusByTypeBarChart(userStatusData);
                            }
                          },
                        )

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
              'admin.users_types'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B9169),
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, int>>(
              future: fetchUserTypeCounts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(
                      color: Color(0xFF1B9169)));
                } else if (snapshot.hasError) {
                  return Center(child: Text('admin.error_loading_data'.tr()));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('admin.no_data_available'.tr()));
                } else {
                  final userTypeStats = snapshot.data!;
                  return _buildUserTypeList(userTypeStats);
                }
              },
            ),

            const SizedBox(height: 24),
            // Divider(height: 32, thickness: 1, color: Colors.grey[300]),

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

  Widget _buildUserTypeList(Map<String, int> typeStats) {
    final sortedEntries = typeStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedEntries.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final entry = sortedEntries[index];
        final userType = entry.key;
        final count = entry.value;
        final softColor = _userTypeColors[userType] ?? Colors.grey;

        // Get translated name for display
        final displayName = _getTranslatedUserType(userType);

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

              // Avatar/Icon
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: softColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    _getIconForUserType(userType),
                    color: softColor,
                    size: 24,
                  ),
                ),
              ),

              // Title - Use translated display name
              title: Text(
                displayName,
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

                // Status section
                FutureBuilder<Map<String, Map<String, int>>>(
                  future: fetchUserTypeStatusCounts(),
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
                          'admin.no_status_data'.tr(),
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      );
                    }

                    final statusCounts = snapshot.data![userType] ?? {};
                    if (statusCounts.isEmpty) {
                      return Center(
                        child: Text(
                          'admin.no_status_data'.tr(),
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
                        _buildStatusBar(statusCounts),
                        const SizedBox(height: 20),

                        // Status legend
                        _buildStatusLegend(statusCounts, totalForType),
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

  Widget _buildStatusBar(Map<String, int> statusCounts) {
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
            child: Container(color: _statusColors[statusName] ?? Colors.grey),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusLegend(Map<String, int> statusCounts, int totalForType) {
    final sortedEntries = statusCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Wrap(
      spacing: 20,
      runSpacing: 16,
      children: sortedEntries.map((entry) {
        final statusName = entry.key;
        final count = entry.value;
        final color = _statusColors[statusName] ?? Colors.grey;
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
                'admin.$statusName'.tr(),
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

  Widget _buildUserTypePieChart(Map<String, int> userTypeStats) {
    final total = userTypeStats.values.fold(0, (sum, count) => sum + count);

    final filteredStats = Map<String, int>.from(userTypeStats)
      ..removeWhere((key, value) => value == 0);

    if (filteredStats.isEmpty) {
      return Center(child: Text('no_data_available'.tr()));
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            sections: _buildPieChartSections(filteredStats),
            centerSpaceRadius: 70,
            sectionsSpace: 2,
            startDegreeOffset: -90,
            pieTouchData: PieTouchData(
              touchCallback: (event, response) {
                // Future: optional interaction
              },
            ),
            borderData: FlBorderData(show: false),
          ),
          swapAnimationDuration: const Duration(milliseconds: 700),
          swapAnimationCurve: Curves.easeOutQuart,
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$total',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'admin.Users'.tr(),
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildPieChartSections(Map<String, int> stats) {
    final total = stats.values.fold(0, (sum, count) => sum + count);

    final sortedEntries = stats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries.map((entry) {
      final percentage = total > 0 ? (entry.value / total) * 100 : 0.0;
      final showTitle = percentage >= 5; // Show label if >=5%

      // Get translated display name for tooltip
      final displayName = _getTranslatedUserType(entry.key);

      return PieChartSectionData(
        color: _userTypeColors[entry.key] ?? Colors.grey.shade400,
        value: entry.value.toDouble(),
        title: showTitle ? '${percentage.toStringAsFixed(1)}%' : '',
        radius: 55 + (percentage > 20 ? 6 : 0),
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        badgeWidget: showTitle ? _getPieChartBadge(displayName) : null,
        badgePositionPercentageOffset: 1.15,
      );
    }).toList();
  }

  Widget? _getPieChartBadge(String userType) {
    return null; // Optional: Return a small icon or indicator for the pie chart section
  }
  Widget _buildUserStatusByTypeBarChart(
      Map<String, Map<String, int>> userStatusData, {
        bool isLoading = false,
      }) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('admin.Loading_user_statistics'.tr()),
          ],
        ),
      );
    }

    final filteredTypes = userStatusData.keys.where((type) {
      final counts = userStatusData[type]!;
      return counts.values.fold(0, (sum, count) => sum + count) > 0;
    }).toList();

    if (filteredTypes.isEmpty) {
      return Center(child: Text('admin.no_data_available'.tr()));
    }

    double maxY = 0;
    userStatusData.forEach((type, statusMap) {
      final sum = statusMap.values.fold(0, (sum, count) => sum + count);
      if (sum > maxY) maxY = sum.toDouble();
    });

    if (maxY == 0) {
      return Center(child: Text('admin.no_data_available'.tr()));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            height: 320,
            width: max(filteredTypes.length * 80.0, MediaQuery.of(context).size.width - 32),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceEvenly,
                maxY: maxY * 1.2,
                groupsSpace: 50,

                barTouchData: BarTouchData(
                  enabled: true,
                  handleBuiltInTouches: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: Colors.grey.shade800,
                    tooltipRoundedRadius: 8,
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final type = filteredTypes[group.x.toInt()];
                      final statusMap = userStatusData[type]!;
                      final active = statusMap['Active'] ?? 0;
                      final blocked = statusMap['Blocked'] ?? 0;
                      final deleted = statusMap['Deleted'] ?? 0;
                      final total = active + blocked + deleted;

                      return BarTooltipItem(
                        '${_formatTypeLabel(type)}\nTotal: $total\nActive: $active\nBlocked: $blocked\nDeleted: $deleted',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 80, // or 100 if you want it *even lower*
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < filteredTypes.length) {
                          final type = filteredTypes[value.toInt()];
                          return Padding(
                            padding: const EdgeInsets.only(top: 16.0), // <-- also make this bigger!
                            child: RotatedBox(
                              quarterTurns: 3,
                              child: Text(
                                _formatTypeLabel(type),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                overflow: TextOverflow.visible,
                                softWrap: false,
                                textAlign: TextAlign.center,
                              ),
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
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const Text('0');
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        );
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
                    dashArray: [4, 4],
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
                barGroups: List.generate(filteredTypes.length, (index) {
                  final type = filteredTypes[index];
                  final statusMap = userStatusData[type]!;

                  final active = (statusMap['Active'] ?? 0).toDouble();
                  final blocked = (statusMap['Blocked'] ?? 0).toDouble();
                  final deleted = (statusMap['Deleted'] ?? 0).toDouble();

                  return BarChartGroupData(
                    x: index,
                    barsSpace: 0,
                    barRods: [
                      BarChartRodData(
                        toY: active + blocked + deleted,
                        width: 28,
                        rodStackItems: [
                          BarChartRodStackItem(0, active, const Color(0xFF00D47E)),
                          BarChartRodStackItem(active, active + blocked, Colors.amber),
                          BarChartRodStackItem(active + blocked, active + blocked + deleted,Colors.red),
                        ],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 24,
          runSpacing: 12,
          children: [
            _buildLegendItem(color: const Color(0xFF00D47E), label: 'admin.Active'.tr()),
            _buildLegendItem(color: Colors.amber, label: 'admin.Blocked'.tr()),
            _buildLegendItem(color: Colors.red, label: 'admin.Deleted'.tr()),
          ],
        ),
        const SizedBox(height: 16),

      ],
    );
  }


  Widget _buildLegendItem({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  IconData _getIconForUserType(String Role) {
    switch (Role.toLowerCase()) {
      case 'user':
        return Icons.person;
      case 'mechanic':
        return Icons.build;
      case 'parts_supplier':
        return Icons.local_shipping;
      case 'towing_service':
        return Icons.directions_car; // Or another suitable icon
      default:
        return Icons.person;
    }
  }

  String _formatTypeLabel(String Role) {
    switch (Role.toLowerCase()) {
      case 'user':
        return 'registration.user'.tr();
      case 'mechanic':
        return 'registration.mechanic'.tr();
      case 'parts_supplier':
        return 'registration.parts_supplier'.tr();
      case 'towing_service':
        return 'registration.towing_service'.tr();
      default:
        return 'registration.user'.tr();
    }
  }



}




