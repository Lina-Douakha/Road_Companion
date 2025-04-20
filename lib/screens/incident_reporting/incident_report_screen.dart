import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:road_companion/screens/incident_reporting/incident_history_screen.dart';
import 'location_picker_screen.dart';
import 'package:geocoding/geocoding.dart';
import 'package:lottie/lottie.dart';


class IncidentReportScreen extends StatefulWidget {
  final int selectedIndex;
  final LatLng? initialLocation;


  const IncidentReportScreen({
    super.key,
    this.selectedIndex = 0,
    this.initialLocation,
  });

  @override
  State<IncidentReportScreen> createState() => _IncidentReportScreenState();
}

class _IncidentReportScreenState extends State<IncidentReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedType;
  File? _selectedImage;
  bool _isButtonPressed = false;
  // Location related variables
  LatLng? _selectedLocation;
  bool _isLocationPermissionGranted = false;
  bool _isFetchingLocation = false;
  String _locationAddress = "Location not specified";
  bool _isFetchingAddress = false;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
    _checkLocationPermission();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _updateAddress(double lat, double lng) async {
    setState(() => _isFetchingAddress = true);
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _locationAddress = [
            place.street,
            place.subLocality,
            place.locality,
            place.postalCode,
            place.country
          ].where((part) => part?.isNotEmpty ?? false).join(', ');
        });
      }
    } catch (e) {
      setState(() {
        _locationAddress = "Location: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}";
      });
    } finally {
      setState(() => _isFetchingAddress = false);
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied to clipboard'))
    );
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

  Future<void> _getCurrentLocation() async {
    if (!_isLocationPermissionGranted) {
      await _checkLocationPermission();
      if (!_isLocationPermissionGranted) return;
    }

    setState(() {
      _isFetchingLocation = true;
    });

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
      });

      await _updateAddress(position.latitude, position.longitude);

    } catch (e) {
      setState(() {
        _isFetchingLocation = false;
      });
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
    barrierDismissible: true,
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
                Lottie.asset(
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

                // Use Current Location Button
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop('current_location');
                  },
                  icon: const Icon(Icons.my_location, color: Color(0xFF0766AD)),
                  label: Text(
                    'incident_report.use_current_location'.tr(),
                    style: const TextStyle(color: Color(0xFF0766AD)),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFCAF4FF), // blue
                    minimumSize: const Size.fromHeight(45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Choose on Map Button
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop('map_selection');
                  },
                  icon: const Icon(Icons.map, color: Color(0xFF1b9169)),
                  label: Text(
                    'incident_report.choose_on_map'.tr(),
                    style: const TextStyle(color: Color(0xFF1b9169)),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD1FADF), // Refreshing green
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

  // Handle the button response here:
  if (result == 'current_location') {
    await _getCurrentLocation();
  } else if (result == 'map_selection') {
    await _selectLocationOnMap();
  }
}




Widget _buildLocationOption({
  required IconData icon,
  required String title,
  Color? color,
  VoidCallback? onTap,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap ?? () {
        Navigator.pop(context);
        if (icon == Icons.my_location) {
          _getCurrentLocation();
        } else {
          _selectLocationOnMap();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 14.0,
          horizontal: 12.0,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (color ?? Colors.blue).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 22,
                color: color ?? Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void _showLocationServiceDisabledDialog() {
  showDialog(
    context: context,
    barrierDismissible: false, // Prevent dismissing by tapping outside
    builder: (BuildContext context) {
      // Add a listener for app state changes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkLocationServiceAndDismiss(context);
      });

      return AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'incident_report.location_service_disabled'.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'incident_report.enable_location_service'.tr(),
          style: const TextStyle(fontSize: 16),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'incident_report.cancel'.tr(),
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
          TextButton(
            onPressed: () async {
              await Geolocator.openLocationSettings();
              // Check service status after returning from settings
              _checkLocationServiceAndDismiss(context);
            },
            child: Text(
              'incident_report.settings'.tr(),
              style: const TextStyle(color: Color(0xFF1B9169)),
            ),
          ),
        ],
      );
    },
  );
}

Future<void> _checkLocationServiceAndDismiss(BuildContext dialogContext) async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (serviceEnabled && dialogContext.mounted) {
    Navigator.of(dialogContext).pop(); // Close the dialog
    _checkLocationPermission(); // Re-check permissions
  }
}

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'incident_report.location_permission_denied'.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'incident_report.enable_location_permission'.tr(),
          style: const TextStyle(fontSize: 16),
        ),
        actions: <Widget>[
          TextButton(
            child: Text(
              'incident_report.cancel'.tr(),
              style: TextStyle(color: Colors.grey[700]),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text(
              'incident_report.settings'.tr(),
              style: const TextStyle(color: Color(0xFF1B9169)),
            ),
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
      backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'incident_report.location_permission_permanently_denied'.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'incident_report.enable_location_permission_settings'.tr(),
          style: const TextStyle(fontSize: 16),
        ),
        actions: <Widget>[
          TextButton(
            child: Text(
              'incident_report.cancel'.tr(),
              style: TextStyle(color: Colors.grey[700]),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text(
              'incident_report.settings'.tr(),
              style: const TextStyle(color: Color(0xFF1B9169)),
            ),
            onPressed: () => Geolocator.openAppSettings(),
          ),
        ],
      ),
    );
  }

Widget _buildLocationField() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        "incident_report.location".tr(),
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: _showLocationSelectionDialog,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16), // Reduced vertical padding
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.location_on,
                color: _selectedLocation != null
                    ? const Color(0xFF1B9169)
                    : Colors.grey.shade400,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _isFetchingLocation || _isFetchingAddress
                    ? Text(
                        'incident_report.fetching_location'.tr(),
                        style: TextStyle(color: Colors.grey.shade600),
                      )
                    : Text(
                        _selectedLocation != null
                            ? _locationAddress
                            : "incident_report.select_location".tr(),
                        style: TextStyle(
                          color: _selectedLocation != null
                              ? Colors.black
                              : Colors.grey.shade600,
                        ),
                      ),
              ),
              if (_selectedLocation != null)
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () => _copyToClipboard(
                    '$_locationAddress\n(${_selectedLocation!.latitude}, ${_selectedLocation!.longitude})'
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
      if (_selectedLocation != null)
        Padding(
          padding: const EdgeInsets.only(top: 4), // Reduced top padding
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: _showLocationSelectionDialog,
              child: Text(
                'incident_report.change_location'.tr(),
                style: const TextStyle(
                  fontSize: 13, // Slightly smaller font
                  color: Color(0xFF1B9169),
                ),
              ),
            ),
          ),
        ),
    ],
  );
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
    final incidentTypes = [
      {
        'label': 'incident_report.accident',
        'iconPath': 'assets/GPS/accident_icon.png',
      },
      {
        'label': 'incident_report.breakdown',
        'iconPath': 'assets/GPS/breakdown_icon.png',
      },
      {
        'label': 'incident_report.Road_Blockages',
        'iconPath': 'assets/GPS/circulation.png',
      },
      {
        'label': 'incident_report.Roadwork',
        'iconPath': 'assets/GPS/roadwork.png',
      },
      {
        'label': 'incident_report.Special_Events',
        'iconPath': 'assets/GPS/event.png',
      },
      {
        'label': 'incident_report.other',
        'iconPath': 'assets/GPS/other.png',
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFf8fafc),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              height: 5,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 12),
            ...incidentTypes.map((type) {
              return ListTile(
                leading: Image.asset(
                  type['iconPath']!,
                  width: 30,
                  height: 30,
                ),
                title: Text(type['label']!.tr()),
                onTap: () {
                  setState(() {
                    _selectedType = type['label']!.tr();
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
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
      Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
      const SizedBox(height: 8),
      if (isDropdown)
        TextButton(
          onPressed: onTap,
          style: ButtonStyle(
            // Normal state
            backgroundColor: MaterialStateProperty.all(Colors.white),
            // Pressed/highlight state
            overlayColor: MaterialStateProperty.resolveWith<Color?>(
              (states) => states.contains(MaterialState.pressed)
                ? const Color(0xFF1B9169).withOpacity(0.1)
                : null,
            ),
            // Text color
            foregroundColor: MaterialStateProperty.resolveWith<Color>(
              (states) => _selectedType == null
                ? Colors.grey.shade600
                : const Color(0xFF1B9169),
            ),
            // Shape and border
            shape: MaterialStateProperty.all(
              RoundedRectangleBorder(
                side: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            // Padding
            padding: MaterialStateProperty.all(
              const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 12,
              ),
            ),
            // Elevation
            elevation: MaterialStateProperty.all(0),
            // Tap target size
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedType ?? hint,
                style: TextStyle(
                  fontSize: 16,
                  color: _selectedType == null
                      ? Colors.grey.shade600
                      : const Color(0xFF1B9169),
                ),
              ),
              Icon(
                Icons.arrow_drop_down,
                color: _selectedType == null
                    ? Colors.grey.shade500
                    : const Color(0xFF1B9169),
                size: 24,
              ),
            ],
          ),
        )
      else
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
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
              borderSide: const BorderSide(
                color: Color(0xFF1B9169),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.all(16),
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
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedImage == null
                  ? "incident_report.import_a_pic".tr()
                  : "incident_report.pic_selected".tr(),
              style: TextStyle(
                color: _selectedImage == null
                    ? Colors.grey.shade600
                    : Colors.black,
              ),
            ),
            Icon(
              _selectedImage == null ? Icons.cloud_upload : Icons.check_circle,
              color: _selectedImage == null
                  ? Colors.grey.shade400
                  : const Color(0xFF1B9169),
            ),
          ],
        ),
      ),
    );
  }

Future<void> _submitForm() async {
  if (_selectedLocation == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("incident_report.location_required".tr()),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  try {
    setState(() => _isButtonPressed = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not logged in");

    String? imageUrl;
    if (_selectedImage != null) {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('incident_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await storageRef.putFile(_selectedImage!);
      imageUrl = await storageRef.getDownloadURL();
    }

    await FirebaseFirestore.instance.collection('Incident Reports').add({
      'Type': _selectedType,
      'Description': _descriptionController.text,
      'ImageURL': imageUrl,
      'ReportTime': Timestamp.fromDate(DateTime.now()),
      'Status': 'Pending',
      'UserID': user.uid,
      'Location': GeoPoint(
        _selectedLocation!.latitude,
        _selectedLocation!.longitude,
      ),
      'Address': _locationAddress ?? _getFormattedCoordinates(_selectedLocation!),
    });

    // Reset form
    _selectedType = null;
    _descriptionController.clear();
    _selectedImage = null;
    _selectedLocation = null;
    _locationAddress = '';

    _showSuccessBottomSheet();
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Failed to submit report: ${e.toString()}"),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    setState(() => _isButtonPressed = false);
  }
}

// format coordinates to a normal text
String _getFormattedCoordinates(LatLng location) {
  return 'Lat: ${location.latitude.toStringAsFixed(4)}, Lng: ${location.longitude.toStringAsFixed(4)}';
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
        surfaceTintColor: Colors.white,
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
                  builder: (context) => const IncidentHistoryScreen(),
                ),
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
                _buildLocationField(),
                const SizedBox(height: 16),
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
                Text(
                  "incident_report.photo".tr(),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                _buildPhotoUploadField(),
                if (_selectedImage != null)
                  Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(top: 16),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _selectedImage!,
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedImage = null;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTapDown: (_) => setState(() => _isButtonPressed = true),
                  onTapUp: (_) {
                    _submitForm();
                  },
                  onTapCancel: () => setState(() => _isButtonPressed = false),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _isButtonPressed
                          ? const Color(0xFF61E9C4)
                          : const Color(0xFF00D47E),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00D47E).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
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