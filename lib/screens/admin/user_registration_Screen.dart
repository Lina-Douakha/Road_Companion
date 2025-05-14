import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:road_companion/services/auth_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:road_companion/screens/incident_reporting/location_picker_screen.dart';
import 'package:geocoding/geocoding.dart';
import 'package:lottie/lottie.dart';
import 'package:road_companion/screens/admin/Admin_Email_verification.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';



class UserRegistrationScreen extends StatefulWidget {
  final LatLng? initialLocation;

  const UserRegistrationScreen({
    super.key,
    this.initialLocation,
  });

  @override
  State<UserRegistrationScreen> createState() => _UserRegistrationScreenState();
}

class _UserRegistrationScreenState extends State<UserRegistrationScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Role constants
  static const String userRole = 'user';
  static const String mechanicRole = 'mechanic';
  static const String partsSupplierRole = 'parts_supplier';
  static const String towingServiceRole = 'towing_service';

  bool offerService = false;
  String serviceType = mechanicRole;
  bool acceptedTerms = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();

  String? identityCardFile;
  String? commercialRegisterFile;
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

  // format coordinates to a normal text
  String _getFormattedCoordinates(LatLng location) {
    return 'Lat: ${location.latitude.toStringAsFixed(4)}, Lng: ${location.longitude.toStringAsFixed(4)}';
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
          "admin.location".tr(),
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

  String _getTranslatedRoleName(String roleKey) {
    switch (roleKey) {
      case userRole:
        return 'registration.user'.tr();
      case mechanicRole:
        return 'registration.mechanic'.tr();
      case partsSupplierRole:
        return 'registration.spare_parts'.tr();
      case towingServiceRole:
        return 'registration.towing'.tr();
      default:
        return 'Unknown Role';
    }
  }

  bool _validateFields() {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty ||
        confirmPasswordController.text.trim().isEmpty ||
        nameController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('registration.all_fields_required'.tr()),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    if (passwordController.text.trim() != confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('registration.password_mismatch'.tr()),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    if (offerService && (identityCardFile == null || commercialRegisterFile == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('registration.provider_docs_required'.tr()),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF00d47e),
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF00d47e)),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'admin.Add_User'.tr(),
            style: TextStyle(
              color: Color(0xFF00d47e),
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          automaticallyImplyLeading: false,
          scrolledUnderElevation: 0,
        ),

        body: SingleChildScrollView(

          padding: const EdgeInsets.all(16),

          child: ConstrainedBox(

            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),
                Center(
                  child: Text(
                    'admin.add_user_instruction'.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Form fields
                _buildTextField(label: 'registration.username'.tr(), controller: nameController),
                _buildTextField(
                  label: 'registration.email'.tr(),
                  icon: Icons.email_outlined,
                  controller: emailController,
                ),
                _buildPhoneField(),
                _buildTextField(
                  label: 'registration.password'.tr(),
                  isPassword: true,
                  controller: passwordController,
                ),
                _buildTextField(
                  label: 'registration.confirm_password'.tr(),
                  isPassword: true,
                  controller: confirmPasswordController,
                ),

                const SizedBox(height: 10),
                Text(
                  'registration.offer_service'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Column(
                  children: [
                    _buildRadio("registration.non".tr(), false),
                    _buildRadio("registration.oui".tr(), true),
                  ],
                ),

                // Service provider specific fields
                if (offerService) ...[
                  const SizedBox(height: 10),
                  Text(
                    'registration.service_type'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  _buildServiceTypeRadio(mechanicRole),
                  _buildServiceTypeRadio(towingServiceRole),
                  _buildServiceTypeRadio(partsSupplierRole),
                  const SizedBox(height: 10),
                  Text(
                    'file_upload.upload_file'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  _buildFileUploadField(
                    'registration.id_card'.tr(),
                    identityCardFile,
                        (file) {
                      setState(() => identityCardFile = file);
                    },
                  ),
                  _buildFileUploadField(
                    'registration.commercial_register'.tr(),
                    commercialRegisterFile,
                        (file) {
                      setState(() => commercialRegisterFile = file);
                    },
                  ),

                  const SizedBox(height: 30),
                  _buildLocationField(),

                ],
                const SizedBox(height: 20),



                // Register button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF00d47e),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () async {
                      if (_validateFields()) {
                        try {
                          final authService = AuthService();
                          String? error = await registerUserAdmin(
                            email: emailController.text.trim(),
                            password: passwordController.text.trim(),
                            name: nameController.text.trim(),
                            phone: phoneController.text.trim(),
                            role: offerService ? serviceType : AuthService.userRole,
                            context: context,
                            location: offerService ? _selectedLocation : null,
                            address: offerService ? _locationAddress : null,
                          );

                          if (error != null && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(error),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } /** else {
                            if (context.mounted) {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => AlertDialog(
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Lottie.network(
                                        'https://assets9.lottiefiles.com/packages/lf20_jbrw3hcz.json',
                                        height: 120,
                                        repeat: false,
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Success!',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'The user has been registered successfully.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: 16, color: Colors.black54),
                                      ),
                                      const SizedBox(height: 24),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context); // Close dialog
                                          Navigator.pop(context); // Go back
                                        },
                                        style: TextButton.styleFrom(
                                          backgroundColor: Color(0xFF00d47e),
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: const Text(
                                          'OK',
                                          style: TextStyle(color: Colors.white, fontSize: 16),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                          }**/

                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("registration.error_occurred".tr()),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                          print("Registration error: $e");
                        }
                      }
                    },
                    child: Text(
                      'registration.continue'.tr(),
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    IconData? icon,
    bool isPassword = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        obscureText: isPassword
            ? (label.contains('confirm') ? !_isConfirmPasswordVisible : !_isPasswordVisible)
            : false,
        cursorColor: const Color.fromARGB(255, 0, 0, 0),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color.fromRGBO(0, 0, 0, 1)),
          floatingLabelStyle: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          prefixIcon: icon != null ? Icon(icon) : null,
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
              (label.contains('confirm') ? _isConfirmPasswordVisible : _isPasswordVisible)
                  ? Icons.visibility
                  : Icons.visibility_off,
              color: const Color.fromARGB(255, 88, 90, 93),
            ),
            onPressed: () {
              setState(() {
                if (label.contains('confirm')) {
                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                } else {
                  _isPasswordVisible = !_isPasswordVisible;
                }
              });
            },
          )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF00d47e), width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: phoneController,
        cursorColor: Colors.black,
        keyboardType: TextInputType.phone,
        decoration: InputDecoration(
          labelText: "registration.num".tr(),
          labelStyle: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
          floatingLabelStyle: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          prefixText: "+213 ",
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF00d47e), width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildRadio(String label, bool value) {
    return Row(
      children: [
        Radio<bool>(
          value: value,
          groupValue: offerService,
          activeColor: Color(0xFF00d47e),
          onChanged: (val) => setState(() => offerService = val!),
        ),
        Text(label),
      ],
    );
  }

  Widget _buildServiceTypeRadio(String roleKey) {
    return Row(
      children: [
        Radio<String>(
          value: roleKey,
          groupValue: serviceType,
          activeColor: Color(0xFF00d47e),
          onChanged: (val) => setState(() => serviceType = val!),
        ),
        Text(_getTranslatedRoleName(roleKey)),
      ],
    );
  }

  Widget _buildFileUploadField(String label, String? fileName, Function(String) onFileSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GestureDetector(
        onTap: () async {
          FilePickerResult? result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['pdf'],
          );
          if (result != null && result.files.isNotEmpty) {
            onFileSelected(result.files.single.name);
          }
        },
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  fileName ?? label,
                  style: TextStyle(
                    color: fileName != null ? Color(0xFF00d47e) : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const Icon(Icons.upload_file, color: Color(0xFF00d47e)),
            ],
          ),
        ),
      ),
    );
  }


  Future<String?> registerUserAdmin({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
    required BuildContext context,
    LatLng? location,
    String? address,
  }) async {
    try {
      // 1. Check if the email exists in the deleted_users collection
      final deletedUserQuery = await _firestore
          .collection('deleted_users')
          .where('Email', isEqualTo: email)
          .get();

      if (deletedUserQuery.docs.isNotEmpty) {
        // User was deleted
        return "auth.account_deleted".tr();
      }
// 2. Check if the email exists in the users collection
      final userQuery = await _firestore
          .collection('users')
          .where('Email', isEqualTo: email)
          .get();
      //block
      if (userQuery.docs.isNotEmpty) {
        final userData = userQuery.docs.first.data();
        if (userData['isBlocked'] == true) {
          return "auth.account_blocked".tr();
        }
        // Already registered
        return "auth.email_already_in_use".tr();
      }

      final pendingQuery = await _firestore.collection('unverified_users').where('Email', isEqualTo: email).get();
      if (pendingQuery.docs.isNotEmpty) {
        for (var doc in pendingQuery.docs) {
          await _firestore.collection('unverified_users').doc(doc.id).delete();
        }
        User? existingUser = _auth.currentUser;
        if (existingUser != null && !existingUser.emailVerified) {
          await existingUser.delete();
        }
      }

      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        Map<String, dynamic> userData = {
          'UserID': user.uid,
          'Email': email,
          'Name': name,
          'Phone': phone,
          'Role': role,
          'Location': null,
          'Address': null,
          'CreatedAt': FieldValue.serverTimestamp(),
          'EmailVerified': false,


        };

        if (role != userRole && location != null) {
          userData.addAll({
            'Location': GeoPoint(location.latitude, location.longitude),
            'Address': address ?? '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
          });
        }

        await _firestore.collection('unverified_users').doc(user.uid).set(userData);
        await user.sendEmailVerification();

        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => EmailVerificationScreen(
                name: name,
                phone: phone,
                role: role,
              ),
            ),
          );
        }
        return null;
      }
    } on FirebaseAuthException catch (e) {
      return _getErrorMessageRegister(e.code);
    }
    return "auth.unknown_error".tr();
  }

  String _getErrorMessageRegister(String errorCode) {
    switch (errorCode) {
      case "invalid-email":
        return "auth.invalid_email".tr();
      case "weak-password":
        return "auth.weak_password".tr();
      default:
        return "auth.unexpected_error".tr();
    }
  }

}