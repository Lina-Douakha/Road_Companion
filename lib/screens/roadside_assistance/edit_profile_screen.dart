import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:lottie/lottie.dart' as lottie;
import 'dart:ui' as ui;
import 'package:road_companion/screens/profile/profile_photo_selection.dart';
import 'package:road_companion/screens/incident_reporting/location_picker_screen.dart';

class EditProfileScreen extends StatefulWidget {
  final String phoneNumber;
  final String workingHours;
  final String facebookPage;

  const EditProfileScreen({
    Key? key,
    required this.phoneNumber,
    required this.workingHours,
    required this.facebookPage,
  }) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _localisationController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _facebookPageController;
  late TextEditingController _emailController;

  List<String> _selectedDays = [];
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isEdited = false;
  String? _currentUserId;
  String? _selectedProfilePhoto;
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _serviceProviderData;

  // Location related variables
  LatLng? _selectedLocation;
  bool _isLocationPermissionGranted = false;
  bool _isFetchingLocation = false;
  bool _isFetchingAddress = false;

  final List<String> _daysOfWeek = ["1", "2", "3", "4", "5", "6", "7"];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _parseWorkingHours(widget.workingHours);
    _fetchCurrentUser();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _localisationController.dispose();
    _phoneNumberController.dispose();
    _facebookPageController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _localisationController = TextEditingController(text: widget.facebookPage);
    _phoneNumberController = TextEditingController(text: widget.phoneNumber);
    _facebookPageController = TextEditingController(text: widget.facebookPage);
    _emailController = TextEditingController();
  }

  void _fetchCurrentUser() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          _currentUserId = user.uid;
          _emailController.text = user.email ?? "";
        });

        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            _userData = userDoc.data() as Map<String, dynamic>;
            _nameController.text = _userData?['Name'] ?? "";
            _selectedProfilePhoto = _userData?['ProfilePhoto'];
            _phoneNumberController.text = _userData?['Phone'] ?? "";
            _localisationController.text = _userData?['Address'] ?? "";

            // Initialize location from Firestore
            if (_userData?['Location'] != null) {
              GeoPoint location = _userData?['Location'];
              _selectedLocation = LatLng(location.latitude, location.longitude);
            }

            _facebookPageController.text = _userData?['Link'] ?? "";
            _parseWorkingHours(_userData?['Working_hours'] ?? "");
          });
        }
      }
    } catch (e) {
      print("Error fetching user data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de la récupération des données utilisateur".tr()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateAddress(double lat, double lng) async {
    setState(() => _isFetchingAddress = true);
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = [
          place.street,
          place.subLocality,
          place.locality,
          place.postalCode,
          place.country
        ].where((part) => part?.isNotEmpty ?? false).join(', ');

        setState(() {
          _localisationController.text = address;
          _selectedLocation = LatLng(lat, lng);
          _isEdited = true;
        });
      }
    } catch (e) {
      setState(() {
        _localisationController.text = "Location: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}";
        _selectedLocation = LatLng(lat, lng);
        _isEdited = true;
      });
    } finally {
      setState(() => _isFetchingAddress = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    if (!_isLocationPermissionGranted) {
      await _checkLocationPermission();
      if (!_isLocationPermissionGranted) return;
    }

    setState(() => _isFetchingLocation = true);

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
      });

      await _updateAddress(position.latitude, position.longitude);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to get location: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isFetchingLocation = false);
    }
  }

  Future<void> _selectLocationOnMap() async {
    final selectedLocation = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(
          initialLocation: _selectedLocation,
        ),
      ),
    );

    if (selectedLocation != null) {
      setState(() {
        _selectedLocation = selectedLocation;
      });
      await _updateAddress(selectedLocation.latitude, selectedLocation.longitude);
    }
  }

  Future<void> _showLocationSelectionDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFFf8fafc),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 300,
              maxWidth: 350,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  lottie.Lottie.asset(
                    'assets/animation/location.json',
                    height: 100,
                    repeat: true,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'incident_report.select_location_method'.tr(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[900],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop('current_location'),
                    icon: const Icon(Icons.my_location, color: Color(0xFF0766AD)),
                    label: Text(
                      'incident_report.use_current_location'.tr(),
                      style: const TextStyle(color: Color(0xFF0766AD)),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFCAF4FF),
                      minimumSize: const Size.fromHeight(45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop('map_selection'),
                    icon: const Icon(Icons.map, color: Color(0xFF1b9169)),
                    label: Text(
                      'incident_report.choose_on_map'.tr(),
                      style: const TextStyle(color: Color(0xFF1b9169)),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD1FADF),
                      minimumSize: const Size.fromHeight(45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (result == 'current_location') {
      await _getCurrentLocation();
    } else if (result == 'map_selection') {
      await _selectLocationOnMap();
    }
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showLocationServiceDisabledDialog();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showPermissionDeniedDialog();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showPermissionPermanentlyDeniedDialog();
      return;
    }

    setState(() {
      _isLocationPermissionGranted = true;
    });
  }

  void _showLocationServiceDisabledDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('incident_report.location_service_disabled'.tr()),
        content: Text('incident_report.enable_location_service'.tr()),
        actions: [
          TextButton(
            child: Text('incident_report.cancel'.tr()),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text('incident_report.settings'.tr()),
            onPressed: () => Geolocator.openLocationSettings(),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('incident_report.location_permission_denied'.tr()),
        content: Text('incident_report.enable_location_permission'.tr()),
        actions: [
          TextButton(
            child: Text('incident_report.cancel'.tr()),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text('incident_report.settings'.tr()),
            onPressed: () => Geolocator.openAppSettings(),
          ),
        ],
      ),
    );
  }

  void _showPermissionPermanentlyDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('incident_report.location_permission_permanently_denied'.tr()),
        content: Text('incident_report.enable_location_permission_settings'.tr()),
        actions: [
          TextButton(
            child: Text('incident_report.cancel'.tr()),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text('incident_report.settings'.tr()),
            onPressed: () => Geolocator.openAppSettings(),
          ),
        ],
      ),
    );
  }

  void _parseWorkingHours(String workingHours) {
    try {
      if (workingHours.isNotEmpty && workingHours.contains("|")) {
        List<String> parts = workingHours.split("|");
        if (parts.length >= 3) {
          setState(() {
            _selectedDays = parts[0].split("  ").map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
            _startTime = _parseTime(parts[1]);
            _endTime = _parseTime(parts[2]);
          });
        }
      }
    } catch (e) {
      print("Error parsing working hours: $e");
    }
  }

  TimeOfDay? _parseTime(String timeString) {
    try {
      List<String> parts = timeString.split(":");
      if (parts.length == 2) {
        int hour = int.tryParse(parts[0]) ?? 0;
        int minute = int.tryParse(parts[1]) ?? 0;
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {
      print("Error parsing time: $e");
    }
    return null;
  }

  Future<void> _pickImage() async {
    try {
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
    } catch (e) {
      print("Error picking image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de la sélection de la photo".tr()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteProfilePhoto() async {
    if (_currentUserId == null) return;

    try {
      setState(() {
        _selectedProfilePhoto = null;
        _isEdited = true;
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .update({'ProfilePhoto': null});
    } catch (e) {
      print("Error deleting profile photo: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de la suppression de la photo".tr()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectTime(bool isStart) async {
    try {
      final ThemeData customTimePickerTheme = ThemeData(
        colorScheme: ColorScheme.light(
          primary: const Color(0xFF00D47E),
          onPrimary: Colors.white,
          surface: Colors.white,
          onSurface: Colors.black87,
        ),
      );

      TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: isStart ? (_startTime ?? TimeOfDay.now()) : (_endTime ?? TimeOfDay.now()),
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: customTimePickerTheme,
            child: child!,
          );
        },
      );

      if (picked != null) {
        setState(() {
          if (isStart) {
            _startTime = picked;
            if (_endTime != null &&
                (_startTime!.hour > _endTime!.hour ||
                    (_startTime!.hour == _endTime!.hour && _startTime!.minute >= _endTime!.minute))) {
              _endTime = null;
            }
          } else {
            if (_startTime == null ||
                picked.hour > _startTime!.hour ||
                (picked.hour == _startTime!.hour && picked.minute > _startTime!.minute)) {
              _endTime = picked;
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("L'heure de fin doit être après l'heure de début.".tr()),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
          }
          _isEdited = true;
        });
      }
    } catch (e) {
      print("Error selecting time: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de la sélection de l'heure".tr()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildDayChip(String day) {
    bool isSelected = _selectedDays.contains(day);
    const fixedWidth = 120.0;
    const fixedHeight = 45.0;

    return SizedBox(
      width: fixedWidth,
      height: fixedHeight,
      child: ChoiceChip(
        label: Container(
          width: fixedWidth - 24,
          alignment: Alignment.center,
          child: Text(
            "days.$day".tr(),
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              color: isSelected ? Colors.black : Colors.black87,
            ),
          ),
        ),
        selected: isSelected,
        selectedColor: const Color(0xFFD1FADF),
        backgroundColor: Colors.grey[200],
        padding: EdgeInsets.zero,
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected ? const Color(0xFF00D47E) : Colors.grey[400]!,
            width: 1.5,
          ),
        ),
        showCheckmark: false,
        onSelected: (selected) {
          setState(() {
            if (selected) {
              _selectedDays.add(day);
            } else {
              _selectedDays.remove(day);
            }
            _isEdited = true;
          });
        },
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (_currentUserId == null) return;

    Map<String, dynamic> updatedData = {};

    // Handle address update
    if (_localisationController.text != _userData?['Address']) {
      updatedData['Address'] = _localisationController.text;
    }

    // Only update location if we have new coordinates
    if (_selectedLocation != null) {
      updatedData['Location'] = GeoPoint(
        _selectedLocation!.latitude,
        _selectedLocation!.longitude,
      );
    }

    // Rest of your existing save logic...
    if (_nameController.text.isNotEmpty && _nameController.text != _userData?['Name']) {
      updatedData['Name'] = _nameController.text;
    }
    if (_phoneNumberController.text.isNotEmpty && _phoneNumberController.text != _userData?['Phone']) {
      updatedData['Phone'] = _phoneNumberController.text;
    }
    if (_selectedProfilePhoto != _userData?['ProfilePhoto']) {
      updatedData['ProfilePhoto'] = _selectedProfilePhoto;
    }
    if (_facebookPageController.text != _userData?['Link']) {
      updatedData['Link'] = _facebookPageController.text;
    }

    // Working hours
    String workingHours = _selectedDays.join("  ") + "|" +
        (_startTime != null ? "${_startTime!.hour}:${_startTime!.minute.toString().padLeft(2, '0')}" : "") + "|" +
        (_endTime != null ? "${_endTime!.hour}:${_endTime!.minute.toString().padLeft(2, '0')}" : "");

    if (workingHours != _userData?['Working_hours']) {
      updatedData['Working_hours'] = workingHours;
    }

    try {
      if (updatedData.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUserId)
            .update(updatedData);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("edit_profile.success_message".tr()),
            backgroundColor: Color(0xFF00d47e),
          ),
        );

        Navigator.pop(context, true);
      }
    } catch (e) {
      print("Error saving changes: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de la mise à jour du profil".tr()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildLocationField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showLocationSelectionDialog,
          child: AbsorbPointer(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Color(0xFF1B9169)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final isEmpty = controller.text.isEmpty;
                        return Text(
                          isEmpty ? "Select location".tr() : controller.text,
                          style: TextStyle(
                            fontSize: 16,
                            color: isEmpty ? Colors.grey.shade600 : Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfilePicture(double screenWidth) {
    final avatarRadius = screenWidth * 0.2;
    final editIconSize = screenWidth * 0.06;

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: avatarRadius,
          backgroundImage: _selectedProfilePhoto != null
              ? AssetImage(_selectedProfilePhoto!) as ImageProvider
              : null,
          backgroundColor: _selectedProfilePhoto == null ? Colors.grey[400] : null,
          child: _selectedProfilePhoto == null
              ? (_nameController.text.isNotEmpty
                  ? Text(
                      _nameController.text[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: avatarRadius * 0.8,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      Icons.person,
                      size: avatarRadius * 0.8,
                      color: Colors.white,
                    ))
              : null,
        ),
        Positioned(
          right: 2,
          bottom: 4,
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(
                Icons.edit,
                color: Colors.white,
                size: editIconSize,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {
    bool isReadOnly = false,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: isReadOnly,
      onChanged: isReadOnly ? null : onChanged,
      style: TextStyle(
        color: isReadOnly ? Colors.grey[600] : Colors.black,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
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
        focusedBorder: isReadOnly
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.black26),
              )
            : OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF00D47E), width: 2),
              ),
        suffixIcon: isReadOnly ? null : const Icon(Icons.edit, color: Color(0xFF1B9169)),
        filled: isReadOnly,
        fillColor: isReadOnly ? Colors.white : null,
      ),
    );
  }

  Widget _buildPhoneNumberField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      onChanged: (value) => setState(() => _isEdited = true),
      decoration: InputDecoration(
        labelText: label,
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
          borderSide: const BorderSide(color: Color(0xFF00D47E), width: 2),
        ),
        suffixIcon: const Icon(Icons.edit, color: Color(0xFF1B9169)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Veuillez entrer un numéro de téléphone.";
        }
        if (value.length != 10) {
          return "Le numéro doit contenir 10 chiffres.";
        }
        if (!value.startsWith("05") && !value.startsWith("06") && !value.startsWith("07")) {
          return "Le numéro doit commencer par 05, 06 ou 07.";
        }
        return null;
      },
    );
  }

  Widget _buildWorkingDaysSelector(String label) {
    final longestDay = _daysOfWeek.reduce((a, b) =>
        "days.$a".tr().length > "days.$b".tr().length ? a : b);

    final textStyle = TextStyle(fontSize: 14);
    final textSpan = TextSpan(
      text: "days.$longestDay".tr(),
      style: textStyle,
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: ui.TextDirection.ltr,
      maxLines: 1,
    )..layout(minWidth: 0, maxWidth: double.infinity);

    final maxWidth = textPainter.width + 32;

    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
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
          borderSide: const BorderSide(color: Color(0xFF00D47E), width: 2),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: _daysOfWeek.map((day) => _buildDayChip(day)).toList(),
      ),
    );
  }

  Widget _buildWorkingHoursSelector(String label) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
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
          borderSide: const BorderSide(color: Color(0xFF00D47E), width: 2),
        ),
      ),
      child: Column(
        children: [
          _buildTimeRow("edit_profile_mecanic.Debut".tr(), true),
          const SizedBox(height: 8),
          _buildTimeRow("edit_profile_mecanic.Fin".tr(), false),
        ],
      ),
    );
  }

  Widget _buildTimeRow(String label, bool isStart) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        TextButton(
          onPressed: () => _selectTime(isStart),
          child: Text(
            isStart
                ? (_startTime?.format(context) ?? "edit_profile_mecanic.Choisir".tr())
                : (_endTime?.format(context) ?? "edit_profile_mecanic.Choisir".tr()),
            style: const TextStyle(
              color: Color(0xFF00D47E),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 350;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: const Color(0xFF1B9169),
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
            statusBarColor: const Color(0xFF1B9169),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1B9169)),
            iconSize: 28,
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: kToolbarHeight + 16),
                const SizedBox(height: 30),

                Center(
                  child: _buildProfilePicture(screenWidth * 0.7),
                ),

                if (_selectedProfilePhoto != null)
                  Center(
                    child: TextButton(
                      onPressed: _deleteProfilePhoto,
                      child: Text(
                        "edit_profile.delete_photo".tr(),
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),

                _buildTextField("edit_profile_mecanic.Nom".tr(), _nameController,
                    onChanged: (_) => setState(() => _isEdited = true)),
                const SizedBox(height: 15),
                _buildPhoneNumberField("edit_profile_mecanic.phone_number".tr(), _phoneNumberController),
                const SizedBox(height: 15),
                _buildTextField("edit_profile_mecanic.Email".tr(), _emailController, isReadOnly: true),
                const SizedBox(height: 15),
                _buildLocationField("edit_profile_mecanic.address".tr(), _localisationController),
                const SizedBox(height: 24),

                // Professional Information
                Text(
                  "edit_profile_mecanic.professionnelles".tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B9169),
                  ),
                ),
                const SizedBox(height: 24),
                _buildWorkingDaysSelector("edit_profile_mecanic.days".tr()),
                const SizedBox(height: 15),
                _buildWorkingHoursSelector("edit_profile_mecanic.working_hours".tr()),
                const SizedBox(height: 15),
                _buildTextField("edit_profile_mecanic.Link".tr(), _facebookPageController,
                    onChanged: (_) => setState(() => _isEdited = true)),
                const SizedBox(height: 32),

               // Save Button
               Container(
                 width: double.infinity,
                 margin: const EdgeInsets.only(bottom: 40),
                 child: Material(
                   borderRadius: BorderRadius.circular(17),
                   elevation: 2,
                   shadowColor: Colors.black.withOpacity(0.2),
                   child: InkWell(
                     borderRadius: BorderRadius.circular(17),
                     onTap: _isEdited ? _saveChanges : null,
                     child: Container(
                       padding: const EdgeInsets.symmetric(vertical: 16),
                       decoration: BoxDecoration(
                         color: _isEdited ? const Color(0xFF00D47E) : Colors.grey[300],
                         borderRadius: BorderRadius.circular(17),
                         boxShadow: [
                           BoxShadow(
                             color: Colors.black.withOpacity(0.1),
                             blurRadius: 4,
                             offset: const Offset(0, 2),
                           ),
                         ],
                       ),
                       child: Center(
                         child: Text(
                           "edit_profile_mecanic.save_button".tr(),
                           style: TextStyle(
                             fontSize: isSmallScreen ? 16 : 18,
                             fontWeight: FontWeight.w600,
                             letterSpacing: 0.5,
                             color: Colors.white,
                           ),
                         ),
                       ),
                     ),
                   ),
                 ),
               )
              ],
            ),
          ),
        ),
      ),
    );
  }
}