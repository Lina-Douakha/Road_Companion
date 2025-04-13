import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:road_companion/screens/incident_reporting/incident_history_screen.dart';

class IncidentReportScreen extends StatefulWidget {
  final int selectedIndex;

  const IncidentReportScreen({super.key, this.selectedIndex = 0});

  @override
  State<IncidentReportScreen> createState() => _IncidentReportScreenState();
}

class _IncidentReportScreenState extends State<IncidentReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedType;
  File? _selectedImage;
  bool _isButtonPressed = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Color(0xFFf8fafc),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Wrap(
          children: [
            ListTile(
              tileColor: Color(0xFFf8fafc),
              leading: const Icon(Icons.camera_alt),
              title: Text('incident_report.take_a_pic'.tr()),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              tileColor: Color(0xFFf8fafc),
              leading: const Icon(Icons.photo_library),
              title: Text("incident_report.from_gallery".tr()),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        );
      },
    );
  }

  void _showIncidentTypeMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Color(0xFFf8fafc),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Wrap(
          children: [
            ListTile(
              tileColor: Color(0xFFf8fafc),
              title: Text("incident_report.accident".tr()),
              onTap: () {
                setState(() {
                  _selectedType = "incident_report.accident".tr();
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              tileColor: Color(0xFFf8fafc),
              title: Text("incident_report.breakdown".tr()),
              onTap: () {
                setState(() {
                  _selectedType = "incident_report.breakdown".tr();
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              tileColor: Color(0xFFf8fafc),
              title: Text("incident_report.other".tr()),
              onTap: () {
                setState(() {
                  _selectedType = "incident_report.other".tr();
                });
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    int maxLines = 1,
    TextEditingController? controller,
    VoidCallback? onTap,
    bool isDropdown = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        if (isDropdown)
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              backgroundColor: Colors.white,
              alignment: Alignment.centerLeft,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_selectedType ?? hint,
                     style: TextStyle(color: _selectedType == null ? Colors.grey : Colors.black)),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          )
        else
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              floatingLabelBehavior: FloatingLabelBehavior.always,
              labelStyle: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.black26),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.black26),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.green, width: 2),
              ),
            ),
            validator: isDropdown
                ? null
                : (value) {
                    if (_selectedType == "incident_report.other".tr() &&
                        (value == null || value.isEmpty)) {
                      return "incident_report.description_required".tr();
                    }
                    return null;
                  },
          ),
      ],
    );
  }

  Widget _buildPhotoUploadField() {
    return GestureDetector(
      onTap: _showImagePickerOptions,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_selectedImage == null
                ? "incident_report.import_a_pic".tr()
                : "incident_report.pic_selected".tr()),
            const Icon(Icons.cloud_upload, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "incident_report.select_a_type".tr(),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedType == "incident_report.other".tr() &&
        _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "incident_report.description_required".tr(),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      setState(() => _isButtonPressed = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      // Upload image to Firebase Storage if exists
      String? imageUrl;
      if (_selectedImage != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('incident_images/${DateTime.now().millisecondsSinceEpoch}.jpg');

        await storageRef.putFile(_selectedImage!);
        imageUrl = await storageRef.getDownloadURL();
      }

      // Add to Firestore
      await FirebaseFirestore.instance.collection('Incident Reports').add({
        'Type': _selectedType,
        'Description': _descriptionController.text,
        'ImageURL': imageUrl,
        'ReportTime': Timestamp.fromDate(DateTime.now()),
        'Status': 'Pending',
        'UserID': user.uid,
      });

      // Clear form
      _selectedType = null;
      _descriptionController.clear();
      _selectedImage = null;
      setState(() {});

      _showSuccessBottomSheet();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to submit report: ${e.toString()}",
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isButtonPressed = false);
    }
  }

  void _showSuccessBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isDismissible: false,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Container(
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF1B9169), width: 2),
                ),
                child: const Center(
                  child: Icon(
                    Icons.check,
                    size: 28,
                    color: Color(0xFF1B9169),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Merci ! Votre rapport a été envoyé avec succès.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/map');
                },
                child: const Text(
                  'OK',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B9169),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: const Color(0xFF1B9169),
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
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
          actions: [
            IconButton(
              icon: const Icon(Icons.history, color: Colors.grey),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const IncidentHistoryScreen()),
                );
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 16),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'incident_report.title'.tr(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B9169),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildTextField(
                    label: "incident_report.incident_type".tr(),
                    hint: "incident_report.select_type".tr(),
                    onTap: _showIncidentTypeMenu,
                    isDropdown: true,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: "incident_report.descreption".tr(),
                    hint: "incident_report.select_describe_incident".tr(),
                    maxLines: 3,
                    controller: _descriptionController,
                  ),
                  const SizedBox(height: 16),
                  Text("incident_report.photo".tr()),
                  const SizedBox(height: 8),
                  _buildPhotoUploadField(),
                  if (_selectedImage != null)
                    Container(
                      alignment: Alignment.center,
                      margin: const EdgeInsets.only(top: 16),
                      child: Image.file(
                        _selectedImage!,
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTapDown: (_) => setState(() => _isButtonPressed = true),
                    onTapUp: (_) {
                      _submitForm();
                    },
                    onTapCancel: () => setState(() => _isButtonPressed = false),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _isButtonPressed
                            ? const Color(0xFF61E9C4)
                            : const Color(0xFF00D47E),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          "incident_report.submit".tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}