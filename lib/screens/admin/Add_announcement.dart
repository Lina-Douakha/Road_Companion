import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddAnnouncementScreen extends StatefulWidget {
  final Map<String, dynamic>? announcementData;
  final String? announcementId;

  const AddAnnouncementScreen({
    Key? key,
    this.announcementData,
    this.announcementId,
  }) : super(key: key);

  @override
  _AddAnnouncementScreenState createState() => _AddAnnouncementScreenState();
}

class _AddAnnouncementScreenState extends State<AddAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  List<String> _audienceOptions = ['All', 'user', 'mechanic', 'towing_service', 'parts_supplier'];
  List<String> _selectedAudience = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // If editing an existing announcement, populate the form
    if (widget.announcementData != null) {
      _titleController.text = widget.announcementData!['title'] ?? '';
      _messageController.text = widget.announcementData!['message'] ?? '';

      // Handle audience population
      if (widget.announcementData!['audience'] == 'All') {
        _selectedAudience = ['All'];
      } else if (widget.announcementData!['audience'] is List) {
        _selectedAudience = List<String>.from(widget.announcementData!['audience']);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _saveAnnouncement() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedAudience.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one audience')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      final String adminId = currentUser?.uid ?? 'Unknown';
      final String adminName = currentUser?.displayName ?? 'Admin';

      // Prepare announcement data
      final Map<String, dynamic> announcementData = {
        'title': _titleController.text.trim(),
        'message': _messageController.text.trim(),
        'audience': _selectedAudience.contains('All') ? 'All' : _selectedAudience,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': adminName,
        'adminId': adminId,
      };

      // Save to Firestore (create new or update existing)
      if (widget.announcementId != null) {
        // Update existing announcement
        await FirebaseFirestore.instance
            .collection('announcements')
            .doc(widget.announcementId)
            .update(announcementData);
      } else {
        // Create new announcement
        await FirebaseFirestore.instance
            .collection('announcements')
            .add(announcementData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement saved successfully!')),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving announcement: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _toggleAudience(String audience) {
    setState(() {
      if (audience == 'All') {
        // If "All" is selected, clear other selections
        if (_selectedAudience.contains('All')) {
          _selectedAudience.remove('All');
        } else {
          _selectedAudience = ['All'];
        }
      } else {
        // If a specific role is selected, remove "All"
        if (_selectedAudience.contains('All')) {
          _selectedAudience.remove('All');
        }

        // Toggle the selected role
        if (_selectedAudience.contains(audience)) {
          _selectedAudience.remove(audience);
        } else {
          _selectedAudience.add(audience);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.announcementId != null ? 'Edit Announcement' : 'Add New Announcement',
          style: TextStyle(
            color: Color(0xFF1B9169),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Color(0xFF1B9169)),
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D47E)),
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Field
              Text(
                'Announcement Title',
                style: TextStyle(
                  color: Color(0xFF1B9169),
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Enter title here',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Color(0xFF1B9169).withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Color(0xFF1B9169).withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Color(0xFF00D47E), width: 1.5),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.red, width: 1),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  fillColor: Color(0xFF1B9169).withOpacity(0.05),
                  filled: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Message Field
              Text(
                'Announcement Message',
                style: TextStyle(
                  color: Color(0xFF1B9169),
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Enter your message here',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Color(0xFF1B9169).withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Color(0xFF1B9169).withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Color(0xFF00D47E), width: 1.5),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.red, width: 1),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  fillColor: Color(0xFF1B9169).withOpacity(0.05),
                  filled: true,
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a message';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Audience Selection
              Text(
                'Target Audience',
                style: TextStyle(
                  color: Color(0xFF1B9169),
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _audienceOptions.map((audience) {
                  final isSelected = _selectedAudience.contains(audience);
                  return GestureDetector(
                    onTap: () => _toggleAudience(audience),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? Color(0xFFD1FADF) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Color(0xFF00D47E) : Color(0xFF1B9169).withOpacity(0.3),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        audience,
                        style: TextStyle(
                          color: isSelected ? Color(0xFF00D47E) : Color(0xFF1B9169),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveAnnouncement,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Color(0xFF00D47E),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    widget.announcementId != null
                        ? 'Update Announcement'
                        : 'Post Announcement',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}