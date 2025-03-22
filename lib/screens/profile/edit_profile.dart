import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_photo_selection.dart'; // Import the profile photo selection screen

class EditProfilePage extends StatefulWidget {
  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isEdited = false;
  String? _currentUserId;
  Map<String, dynamic>? _userData;
  String? _selectedProfilePhoto; // Stores the selected profile photo

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          _userData = userDoc.data() as Map<String, dynamic>;
          _nomController.text = _userData?['Name'] ?? "";
          _telephoneController.text = _userData?['Phone'] ?? "";
          _emailController.text = _userData?['Email'] ?? "";
          _selectedProfilePhoto = _userData?['ProfilePhoto']; // Get the profile photo
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final selectedPhoto = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfilePhotoSelectionPage()),
    );

    if (selectedPhoto != null) {
      setState(() {
        _selectedProfilePhoto = selectedPhoto;
        _isEdited = true;
      });
    }
  }

  Future<void> _deleteProfilePhoto() async {
    if (_currentUserId == null) return;

    setState(() {
      _selectedProfilePhoto = null; // Remove the profile photo
      _isEdited = true;
    });

    await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUserId)
        .update({'ProfilePhoto': null});
  }

  void _onFieldChanged() {
    setState(() {
      _isEdited = true;
    });
  }

  Future<void> _saveChanges() async {
    if (_currentUserId == null) return;

    Map<String, dynamic> updatedData = {};

    if (_nomController.text.isNotEmpty && _nomController.text != _userData?['Name']) {
      updatedData['Name'] = _nomController.text;
    }
    if (_telephoneController.text.isNotEmpty && _telephoneController.text != _userData?['Phone']) {
      updatedData['Phone'] = _telephoneController.text;
    }
    if (_selectedProfilePhoto != _userData?['ProfilePhoto']) {
      updatedData['ProfilePhoto'] = _selectedProfilePhoto;
    }

    if (updatedData.isNotEmpty) {
      await FirebaseFirestore.instance.collection('users').doc(_currentUserId).update(updatedData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("edit_profile.success_message".tr()),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true); // Return true to indicate changes were made
    } else {
      Navigator.pop(context, false); // Return false if no changes were made
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _userData == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 50),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back, color: Color(0xFF1B9169)),
                            onPressed: () => Navigator.pop(context),
                          ),
                          SizedBox(width: 10),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                "edit_profile.title".tr(),
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B9169)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 30),
                      _buildProfilePicture(),
                      SizedBox(height: 10),
                      if (_selectedProfilePhoto != null)
                        TextButton(
                          onPressed: _deleteProfilePhoto,
                          child: Text(
                            "edit_profile.delete_photo".tr(),
                            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        ),
                      SizedBox(height: 30),
                      _buildTextField("edit_profile.name".tr(), _nomController),
                      SizedBox(height: 20),
                      _buildTextField("edit_profile.phone_number".tr(), _telephoneController, keyboardType: TextInputType.phone),
                      SizedBox(height: 20),
                      _buildTextField("edit_profile.email".tr(), _emailController, keyboardType: TextInputType.emailAddress, isReadOnly: true),
                      SizedBox(height: 30),
                      _buildSaveButton(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildProfilePicture() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: _selectedProfilePhoto != null
              ? AssetImage(_selectedProfilePhoto!) as ImageProvider
              : null,
          backgroundColor: _userData?['ProfilePhoto'] == null ? Colors.grey[400] : Colors.transparent,
          child: _userData?['ProfilePhoto'] == null
              ? (_userData?['Name'] != null && _userData!['Name'].isNotEmpty
                  ? Text(
                      _userData!['Name'][0].toUpperCase(),
                      style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold, color: Colors.white),
                    )
                  : Icon(Icons.person, size: 50, color: Colors.white))
              : null,
        ),
        Positioned(
          right: 4,
          bottom: 4,
          child: GestureDetector(
            onTap: _pickImage,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.black,
              child: Icon(Icons.edit, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    bool isReadOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: isReadOnly,
      onChanged: isReadOnly ? null : (value) => _onFieldChanged(),
      style: TextStyle(color: isReadOnly ? Colors.grey[600] : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.black),
        suffixIcon: isReadOnly ? null : Icon(Icons.edit, color: Color(0xFF1B9169)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.black, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Color(0xFF1B9169), width: 2),
        ),
        filled: isReadOnly,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: _isEdited ? Colors.green : Colors.grey,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
      ),
      onPressed: _isEdited ? _saveChanges : null,
      child: Text("edit_profile.save".tr(), style: TextStyle(color: Colors.white, fontSize: 16)),
    );
  }
}








