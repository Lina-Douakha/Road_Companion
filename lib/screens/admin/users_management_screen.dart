import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'UserDetailsScreen.dart';
import 'user_registration_Screen.dart';
import 'admin_registartion_screen.dart';


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
        return Colors.grey;
      case 'mechanic':
        return Colors.orange;
      case 'parts_supplier':
        return Colors.green;
      case 'towing_service':
        return Colors.purple;
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User moved to deleted_users and removed.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete user: $e')),
      );
    }
  }

  Future<void> _toggleBlockUser(String userId, bool currentBlockedStatus, int index) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isBlocked': !currentBlockedStatus,
      });
      setState(() {
        final userIndex = _users.indexWhere((user) => user['UserID'] == userId);
        if (userIndex != -1) {
          _users[userIndex]['isBlocked'] = !currentBlockedStatus;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'user ${!currentBlockedStatus ? 'blocked' : 'active'} successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to toggle block status: <span class="math-inline">e')),
      );
    }
  }

  String _getNoUsersMessage() {
    switch (_selectedFilter) {
      case UserFilter.active:
        return "No unblocked users found.";
      case UserFilter.blocked:
        return "No blocked users found.";
      case UserFilter.deleted:
        return "No deleted users found.";
      default:
        return "No users found.";
    }
  }
  Widget _buildUserCard(Map<String, dynamic> user, int index, {bool isDeleted = false}) {
    final bool isBlocked = user['isBlocked'] ?? false;
    final blockIcon = isBlocked ? Icons.lock : Icons.lock_open_outlined;
    final blockColor = isBlocked ? Colors.redAccent : Colors.green;
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
  void _showBlockDialog(Map<String, dynamic> user, int index, bool isBlocked) {
    final String actionText = isBlocked ? "Unblock" : "Block";
    final Color actionColor = const Color(0xFF1B9169); // soft modern green

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '$actionText user',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        content: Text(
          'Are you sure you want to ${actionText.toLowerCase()} "${user['Name']}"?',
          style: const TextStyle(fontSize: 15),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
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
              backgroundColor: actionColor.withOpacity(0.1),
              foregroundColor: actionColor,
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
  void _showDeleteDialog(Map<String, dynamic> user, int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete User',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        content: const Text(
          'Are you sure you want to permanently delete this user?',
          style: TextStyle(fontSize: 15),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              deleteUser(user['UserID'], index);
            },
            child: const Text(
              'Delete',
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
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
                      children: const [
                        Icon(Icons.admin_panel_settings, color: Color(0xFF1B9169)),
                        SizedBox(width: 10),
                        Text('Add Admin'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'user',
                    child: Row(
                      children: const [
                        Icon(Icons.person_add_alt, color: Color(0xFF1B9169)),
                        SizedBox(width: 10),
                        Text('Add User'),
                      ],
                    ),
                  ),
                ],
                child:Container(
                  height: 30,
                  width: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B9169).withOpacity(0.1),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
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


      body: RefreshIndicator(
        color: const Color(0xFF1B9169),
        backgroundColor: Colors.white,
        strokeWidth: 2.0,
        onRefresh: _fetchUsersBasedOnFilter,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B9169)))
            : Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 16),
                child: Center(
                  child: Text(
                    'admin.manage_users'.tr(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF157E15),
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
                    hintText: "recherche".tr(),
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
              Container(
                height: 44,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: SegmentedButton<UserFilter>(
                  showSelectedIcon: false,
                  style: ButtonStyle(
                    padding: MaterialStateProperty.all(
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    backgroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
                      return states.contains(MaterialState.selected)
                          ? const Color(0xFFE0F2F1)
                          : Colors.transparent;
                    }),
                    side: MaterialStateProperty.resolveWith<BorderSide?>((states) {
                      return states.contains(MaterialState.selected)
                          ? const BorderSide(color: Color(0xFF1B9169))
                          : const BorderSide(color: Colors.grey);
                    }),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    foregroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
                      return states.contains(MaterialState.selected)
                          ? const Color(0xFF1B9169)
                          : Colors.grey;
                    }),
                    overlayColor: MaterialStateProperty.all(
                      const Color(0xFF1B9169).withOpacity(0.1),
                    ),
                  ),
                  segments: <ButtonSegment<UserFilter>>[
                    ButtonSegment<UserFilter>(
                      value: UserFilter.active,
                      label: _buildSegmentLabel(Icons.check_circle, 'Active', _selectedFilter == UserFilter.active),
                    ),
                    ButtonSegment<UserFilter>(
                      value: UserFilter.blocked,
                      label: Flexible(
                        child: _buildSegmentLabel(Icons.block, 'Blocked', _selectedFilter == UserFilter.blocked),
                      ),
                    ),
                    ButtonSegment<UserFilter>(
                      value: UserFilter.deleted,
                      label: _buildSegmentLabel(Icons.delete, 'Deleted', _selectedFilter == UserFilter.deleted),
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
              ),

              const SizedBox(height: 0),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: _roles.map((role) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: FilterChip(
                      label: Text('registration.$role'.tr()),
                      selected: selectedRole == role,
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            selectedRole = role;
                          } else if (selectedRole == role) {
                            selectedRole = 'All';
                          }
                        });
                      },
                      selectedColor: const Color(0xFF1B9169).withOpacity(0.2),
                      backgroundColor: Colors.grey.withOpacity(0.1),
                      checkmarkColor: const Color(0xFF1B9169),
                      labelStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: selectedRole == role ? FontWeight.bold : FontWeight.normal,
                        color: selectedRole == role ? const Color(0xFF1B9169) : Colors.black87,
                      ),
                      shape: const StadiumBorder(),
                      elevation: selectedRole == role ? 2 : 0,
                      shadowColor: Colors.grey.withOpacity(0.3),
                    ),
                  )).toList(),
                ),
              ),

              Expanded(
                child: displayedUsers.isEmpty
                    ? Center(child: Text(_getNoUsersMessage()))
                    : ListView.builder(
                  itemCount: displayedUsers.length,
                  itemBuilder: (context, index) {
                    final user = displayedUsers[index];
                    return _buildUserCard(user, index, isDeleted: _selectedFilter == UserFilter.deleted);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildSegmentLabel(IconData icon, String text, bool isSelected) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: isSelected ? const Color(0xFF1B9169) : Colors.grey),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isSelected ? const Color(0xFF1B9169) : Colors.grey,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }


}