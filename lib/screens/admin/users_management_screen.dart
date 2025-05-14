import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:road_companion/screens/admin/UserDetailsScreen.dart';
import 'package:road_companion/screens/admin/user_registration_Screen.dart';
import 'package:road_companion/screens/admin/admin_registartion_screen.dart';


enum UserFilter { active, blocked, deleted }

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({Key? key}) : super(key: key);

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}
class _UsersManagementScreenState extends State<UsersManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String selectedRole = 'All';
  bool _isLoading = true; // Initially set to true
  List<Map<String, dynamic>> _users = []; // To store fetched users
  List<Map<String, dynamic>> _deletedUsers = [];
  // final FirebaseDatabase _database = FirebaseDatabase.instance; // For Realtime Database
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<String> _roles = ['All', 'mechanic', 'towing_service', 'parts_supplier', 'user'];
  UserFilter _selectedFilter = UserFilter.active;


  Color _getRoleColor(String Role) {
    switch (Role.toLowerCase()) {
      case 'user':
        return const Color(0xFF00D47E);
      case 'mechanic':
        return Colors.amber;
      case 'parts_supplier':
        return const Color(0xFFE84D5E);
      case 'towing_service':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
  IconData _getRoleIcon(String Role) {
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


  @override
  void initState() {
    super.initState();
    _fetchUsersBasedOnFilter();
  }

  Future<void> _fetchDeletedUsers() async {
    setState(() {
      _isLoading = true;
    });
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot =
      await _firestore.collection('deleted_users').get();
      _deletedUsers = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print("Error fetching deleted users: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  Future<void> _fetchActiveUsers({UserFilter filter = UserFilter.active}) async {
    setState(() {
      _isLoading = true;
    });
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot;
      if (filter == UserFilter.blocked) {
        snapshot = await _firestore
            .collection('users')
            .where('isBlocked', isEqualTo: true)
            .get();
      } else { // This covers the UserFilter.unblocked case (and any other unexpected filter)
        snapshot = await _firestore
            .collection('users')
            .where('isBlocked', isEqualTo: false)
            .get();
      }
      _users = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print("Error fetching active users: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  Future<void> _fetchUsersBasedOnFilter() async {
    if (_selectedFilter == UserFilter.deleted) {
      await _fetchDeletedUsers();
    } else {
      await _fetchActiveUsers(filter: _selectedFilter);
    }
  }

  Future<void> deleteUser(String userId, int index) async {
    try {
      // 1. Get the user document
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userSnapshot.exists) {
        throw Exception('User not found.');
      }

      // 2. Copy data to deleted_users
      await FirebaseFirestore.instance
          .collection('deleted_users')
          .doc(userId)
          .set(userSnapshot.data() as Map<String, dynamic>);

      // 3. Delete from original users collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .delete();

      // 4. Update UI
      setState(() {
        _users.removeAt(index);
      });

      _showUserActionSuccessDialog('delete');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete user: $e')),
      );
    }
  }
  Future<void> _toggleBlockUser(String userId, bool currentBlockedStatus, int index) async {
    try {
      // Update Firestore
      await _firestore.collection('users').doc(userId).update({
        'isBlocked': !currentBlockedStatus,
      });

      // Update local state
      setState(() {
        final userIndex = _users.indexWhere((user) => user['UserID'] == userId);
        if (userIndex != -1) {
          _users[userIndex]['isBlocked'] = !currentBlockedStatus;
        }
      });

      _showUserActionSuccessDialog(!currentBlockedStatus ? 'block' : 'unblock');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to toggle block status: $e')),
      );
    }
  }
// Enhanced dialog with more detailed explanation
  void _showBlockDialog(Map<String, dynamic> user, int index, bool isBlocked) {
    final String actionText = isBlocked ? 'admin.Unblock'.tr() : 'admin.Block'.tr();

    final String message = isBlocked
        ? 'admin.unblock_message'.tr()
        : 'admin.block_message'.tr() ;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '$actionText',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 15),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:  Text(
              'admin.cancel'.tr(),
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _toggleBlockUser(user['UserID'], isBlocked, index);
            },
            child: Text(
              actionText,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isBlocked
                  ? const Color(0xFF1B9169).withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              foregroundColor: isBlocked ? const Color(0xFF00D47E)  : Colors.amber,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
  String _getNoUsersMessage() {
    switch (_selectedFilter) {
      case UserFilter.active:
        return 'admin.No_unblocked'.tr();
      case UserFilter.blocked:
        return 'admin.No_blocked'.tr();
      case UserFilter.deleted:
        return 'admin.No_deleted'.tr();
      default:
        return "admin.No_users".tr();
    }
  }
  Widget _buildUserCard(Map<String, dynamic> user, int index, {bool isDeleted = false}) {
    final bool isBlocked = user['isBlocked'] ?? false;
    final blockIcon = isBlocked ? Icons.lock : Icons.lock_open_outlined;
    final blockColor = isBlocked ? Colors.redAccent : Color(0xFF00d47e);
    final blockTooltip = isBlocked ? 'Unblock User' : 'Block User';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF9FBFD),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserDetailsScreen(user: user),
                ),
              );
            },
            child: Padding(

              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: isDeleted ? Colors.grey[300] : Colors.grey[400],
                    backgroundImage: user['ProfilePhoto'] != null
                        ? AssetImage(user['ProfilePhoto'] as String)
                        : null,
                    child: user['ProfilePhoto'] == null
                        ? Text(
                      (user['Name']?.isNotEmpty ?? false)
                          ? user['Name'][0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                        : null,
                  ),

                  const SizedBox(width: 16),

                  // Name + Email on the left side
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user['Name'] ?? 'No Name',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDeleted ? Colors.grey : Colors.black87,
                            fontStyle: isDeleted ? FontStyle.italic : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user['Email'] ?? 'No Email',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Right side: Actions and Role
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (!isDeleted)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              iconSize: 20,
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                              icon: Icon(
                                blockIcon,
                                color: blockColor.withOpacity(0.7),
                              ),
                              tooltip: blockTooltip,
                              onPressed: () => _showBlockDialog(user, index, isBlocked),
                            ),

                            IconButton(
                              iconSize: 20,
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                              icon: Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent.withOpacity(0.7),
                              ),
                              tooltip: 'Delete User',
                              onPressed: () => _showDeleteDialog(user, index),
                            ),

                          ],
                        )
                      else
                        Icon(Icons.delete_forever, color: Colors.grey[400]),

                      const SizedBox(height: 8),

                      // Role badge
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getRoleColor(user['Role']).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getRoleIcon(user['Role']),
                              size: 14,
                              color: _getRoleColor(user['Role']),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'registration.${user['Role'] ?? "user"}'.tr(),
                              style: TextStyle(
                                fontSize: 12,
                                color: _getRoleColor(user['Role']),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  void _showDeleteDialog(Map<String, dynamic> user, int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'admin.Delete'.tr(),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        content: Text(
          'admin.delete_message'.tr(),
          style: TextStyle(fontSize: 15),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:Text(
              'admin.cancel'.tr(),
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              deleteUser(user['UserID'], index);
            },
            child: Text(
              'admin.Delete'.tr(),
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withOpacity(0.1),
              foregroundColor: Colors.redAccent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> displayedUsers = [];

    if (_selectedFilter == UserFilter.deleted) {
      displayedUsers = _deletedUsers.where((user) {
        final isSearchMatch =
            (user['Name']?.toLowerCase().contains(_searchController.text.toLowerCase()) ?? false) ||
                (user['Email']?.toLowerCase().contains(_searchController.text.toLowerCase()) ?? false) ||
                (user['UserID']?.toString().toLowerCase().contains(_searchController.text.toLowerCase()) ?? false);

        final isRoleMatch = selectedRole == 'All' || user['Role'] == selectedRole;
        return isSearchMatch && isRoleMatch;
      }).toList();
    } else {
      displayedUsers = _users.where((user) {
        final isRoleMatch = selectedRole == 'All' || user['Role'] == selectedRole;
        final isSearchMatch =
            (user['Name']?.toLowerCase().contains(_searchController.text.toLowerCase()) ?? false) ||
                (user['Email']?.toLowerCase().contains(_searchController.text.toLowerCase()) ?? false) ||
                (user['UserID']?.toString().toLowerCase().contains(_searchController.text.toLowerCase()) ?? false);

        final bool isBlocked = user['isBlocked'] ?? false;
        bool isBlockStatusMatch = true;
        switch (_selectedFilter) {
          case UserFilter.active:
            isBlockStatusMatch = !isBlocked;
            break;
          case UserFilter.blocked:
            isBlockStatusMatch = isBlocked;
            break;
          case UserFilter.deleted:
            isBlockStatusMatch = false;
            break;
        }
        return isRoleMatch && isSearchMatch && isBlockStatusMatch;
      }).toList();
    }
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.grey[100],
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: const Color(0xFF1B9169),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1B9169)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 16),
            child: PopupMenuButton<String>(
              tooltip: 'Add New',
              onSelected: (value) {
                if (value == 'admin') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminRegistrationScreen()),
                  );
                } else if (value == 'user') {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => UserRegistrationScreen(),
                  ));
                }
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: Colors.white,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'admin',
                  child: Row(
                    children:  [
                      Icon(Icons.admin_panel_settings, color: Color(0xFF1B9169)),
                      SizedBox(width: 10),
                      Text('admin.Add_Admin'.tr()),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'user',
                  child: Row(
                    children: [
                      Icon(Icons.person_add_alt, color: Color(0xFF1B9169)),
                      SizedBox(width: 10),
                      Text('admin.Add_User'.tr()),
                    ],
                  ),
                ),
              ],
              child: Container(
                height: 30,
                width: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B9169).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: null,
                  child: const Center(
                    child: Icon(
                      Icons.add,
                      color: Color(0xFF1B9169),
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            // Fixed header content
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 16),
              child: Center(
                child: Text(
                  'admin.manage_users'.tr(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color:Color(0xFF1B9169),
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'admin.recherche'.tr(),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF1B9169)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildUserFilter(),
            const SizedBox(height: 0),
            _buildRoleChips(),

            // Refresh indicator only wraps the user list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B9169)))
                  : RefreshIndicator(
                color: const Color(0xFF1B9169),
                backgroundColor: Colors.white,
                strokeWidth: 2.0,
                onRefresh: _fetchUsersBasedOnFilter,
                child: displayedUsers.isEmpty
                    ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.3,
                      child: Center(child: Text(_getNoUsersMessage())),
                    ),
                  ],
                )
                    : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: displayedUsers.length,
                  itemBuilder: (context, index) {
                    final user = displayedUsers[index];
                    return _buildUserCard(user, index, isDeleted: _selectedFilter == UserFilter.deleted);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildUserFilter() {
    return SizedBox(
      width: double.infinity, // Make the SizedBox take the full width
      child: SegmentedButton<UserFilter>(
        showSelectedIcon: false,
        style: ButtonStyle(
          padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
          backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                (states) => states.contains(MaterialState.selected)
                ? const Color(0xFFE0F2F1) // Light green when selected (from _buildStatusFilter)
                : Colors.transparent,
          ),
          side: MaterialStateProperty.resolveWith<BorderSide?>(
                (states) => states.contains(MaterialState.selected)
                ? const BorderSide(color: Color(0xFF00D47E)) // Green border when selected (from _buildStatusFilter)
                : const BorderSide(color: Colors.grey),
          ),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          foregroundColor: MaterialStateProperty.resolveWith<Color?>(
                (states) => states.contains(MaterialState.selected)
                ? const Color(0xFF00D47E) // Green text when selected (from _buildStatusFilter)
                : Colors.grey,
          ),
          overlayColor: MaterialStateProperty.all(
            const Color(0xFF00D47E).withOpacity(0.1), // Green overlay effect (from _buildStatusFilter)
          ),
        ),
        segments: [
          ButtonSegment(
            value: UserFilter.active,
            label: Expanded(
              child: Center(
                child: _buildStatusSegmentLabel(
                  Icons.check_circle,
                  'admin.Active'.tr(),
                  _selectedFilter == UserFilter.active,
                  color: Color(0xFF00D47E), // Green
                ),
              ),
            ),
          ),
          ButtonSegment(
            value: UserFilter.blocked,
            label: Expanded( // Make the label take available width
              child: Center( // Center the label text
                child: _buildStatusSegmentLabel(
                  Icons.block,
                  'admin.Blocked'.tr(),
                  _selectedFilter == UserFilter.blocked,
                  color: Colors.amber, // Orange
                ),
              ),
            ),
          ),
          ButtonSegment(
            value: UserFilter.deleted,
            label: Expanded( // Make the label take available width
              child: Center( // Center the label text
                child: _buildStatusSegmentLabel(
                  Icons.delete,
                  'admin.Deleted'.tr(),
                  _selectedFilter == UserFilter.deleted,
                  color: Colors.red, // Red
                ),
              ),
            ),
          ),
        ],
        selected: {_selectedFilter},
        onSelectionChanged: (Set<UserFilter> newSelection) {
          setState(() {
            _selectedFilter = newSelection.first;
            _fetchUsersBasedOnFilter();
          });
        },
      ),
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
  Widget _buildRoleChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _roles.map((role) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: FilterChip(
              label: Text(
                // Translate the role name using tr() method with 'incident_report' prefix
                'registration.$role'.tr(),
                style: TextStyle(
                  color: selectedRole == role
                      ? Colors.white // White text when selected
                      : const Color(0xFF00D47E), // Green text when not selected
                ),
              ),
              selected: selectedRole == role,
              onSelected: (bool selected) {
                setState(() {
                  selectedRole = selected ? role : 'All';
                });
              },
              selectedColor: const Color(0xFF00D47E), // Green background when selected
              backgroundColor: Colors.white, // White background when unselected
              checkmarkColor: Colors.white, // White checkmark
              shadowColor: Colors.grey.withOpacity(0.2), // Softer shadow
              elevation: 2, // Reduced shadow depth
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25), // Rounded corners
                side: const BorderSide(
                  color: Colors.transparent, // No border for both states
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
// Show success dialog with custom message based on user actions
  void _showUserActionSuccessDialog(String actionType) {
    String message;
    Color iconColor;
    IconData iconData;

    switch (actionType.toLowerCase()) {
      case 'block':
        message = 'admin.user_successfully_blocked'.tr();
        iconColor = Colors.orange;
        iconData = Icons.block;
        break;
      case 'unblock':
        message = 'admin.user_successfully_unblocked'.tr();
        iconColor = const Color(0xFF00D47E); // Green
        iconData = Icons.check_circle;
        break;
      case 'delete':
        message = 'admin.user_successfully_deleted'.tr();
        iconColor = Colors.red;
        iconData = Icons.delete_forever;
        break;
      default:
        message = 'admin.action_completed_successfully'.tr();
        iconColor = Colors.blue;
        iconData = Icons.check_circle;
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
                    iconData,
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
                  child: Text('admin.OK'.tr()),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


}