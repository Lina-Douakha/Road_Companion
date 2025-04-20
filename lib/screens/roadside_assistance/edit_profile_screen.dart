import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:road_companion/screens/profile/profile_photo_selection.dart';

class EditProfileScreen extends StatefulWidget {
  final String localisation;
  final String phoneNumber;
  final String workingHours;
  final String facebookPage;

  const EditProfileScreen({
    Key? key,
    required this.localisation,
    required this.phoneNumber,
    required this.workingHours,
    required this.facebookPage,
  }) : super(key: key);

  @override
  _EnhancedEditProfileScreenState createState() => _EnhancedEditProfileScreenState();
}

class _EnhancedEditProfileScreenState extends State<EditProfileScreen> {
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
  String? _selectedWilayaNumber;
  String _displayedWilaya = "";

  final List<String> _daysOfWeek = [
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
  ];


final List<String> _wilayas = [
  "1", "2", "3", "4", "5", "6", "7", "8", "9", "10",
  "11", "12", "13", "14", "15", "16", "17", "18", "19", "20",
  "21", "22", "23", "24", "25", "26", "27", "28", "29", "30",
  "31", "32", "33", "34", "35", "36", "37", "38", "39", "40",
  "41", "42", "43", "44", "45", "46", "47", "48", "49", "50",
  "51", "52", "53", "54", "55", "56", "57", "58"
];

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
  _localisationController = TextEditingController(text: widget.localisation);
  _phoneNumberController = TextEditingController(text: widget.phoneNumber);
  _facebookPageController = TextEditingController(text: widget.facebookPage);
  _emailController = TextEditingController();
}

// Updated _fetchCurrentUser
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

          // Handle location
          final location = _userData?['Location'] ?? "";
          _selectedWilayaNumber = location;
          if (location.isNotEmpty) {
            _displayedWilaya = "$location - ${"wilayas.$location".tr()}";
            _localisationController.text = _displayedWilaya;
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
      print("⚠️ Erreur lors de l'analyse des horaires : $e");
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
  // Fixed dimensions for all chips
  const fixedWidth = 120.0;
  const fixedHeight = 45.0;

  return SizedBox(
    width: fixedWidth,
    height: fixedHeight,
    child: ChoiceChip(
      label: Container(
        width: fixedWidth - 24, // Account for padding
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

  // Handle location update
  if (_selectedWilayaNumber != null && _selectedWilayaNumber != _userData?['Location']) {
    updatedData['Location'] = _selectedWilayaNumber;
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
          backgroundColor: Colors.green,
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

              _buildTextField("edit_profile_mecanic.Nom".tr(), _nameController, onChanged: (_) => setState(() => _isEdited = true)),
              const SizedBox(height: 15),
              _buildPhoneNumberField("edit_profile_mecanic.phone_number".tr(), _phoneNumberController),
              const SizedBox(height: 15),
              _buildTextField("edit_profile_mecanic.Email".tr(), _emailController, isReadOnly: true),
              const SizedBox(height: 15),
              _buildLocationField("edit_profile_mecanic.Wilaya".tr(), _localisationController),
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
              _buildTextField("edit_profile_mecanic.Link".tr(), _facebookPageController, onChanged: (_) => setState(() => _isEdited = true)),
              const SizedBox(height: 32),

              // Improved Save Button
              Container(
                margin: const EdgeInsets.only(bottom: 40), // Space at bottom
                child: ElevatedButton(
                  onPressed: _isEdited ? _saveChanges : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isEdited ? const Color(0xFF00D47E) : Colors.grey[400],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: Size.fromHeight(isSmallScreen ? 50 : 56),
                    elevation: 2,
                    shadowColor: Colors.black.withOpacity(0.2),
                  ),
                  child: Text(
                    "edit_profile_mecanic.save_button".tr(),
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
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
                size: editIconSize ,
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

// Updated _buildLocationField
Widget _buildLocationField(String label, TextEditingController controller) {
  return Autocomplete<String>(
    optionsBuilder: (TextEditingValue textEditingValue) {
      if (textEditingValue.text.isEmpty) {
        return _wilayas;
      }
      return _wilayas.where((wilayaNumber) {
        final wilayaName = "wilayas.$wilayaNumber".tr();
        return wilayaNumber.contains(textEditingValue.text) ||
               wilayaName.toLowerCase().contains(textEditingValue.text.toLowerCase());
      });
    },
    onSelected: (String selectedNumber) {
      setState(() {
        _selectedWilayaNumber = selectedNumber;
        _displayedWilaya = "$selectedNumber - ${"wilayas.$selectedNumber".tr()}";
        controller.text = _displayedWilaya;
        _isEdited = true;
      });
    },
    fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
      // Initialize with current displayed value
      if (textEditingController.text.isEmpty && _displayedWilaya.isNotEmpty) {
        textEditingController.text = _displayedWilaya;
      }

      return TextFormField(
        controller: textEditingController,
        focusNode: focusNode,
        onChanged: (value) {
          _displayedWilaya = value;
          setState(() => _isEdited = true);
        },
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
          suffixIcon: const Icon(Icons.location_on, color: Color(0xFF1B9169)),
        ),
      );
    },
    optionsViewBuilder: (context, onSelected, options) {
      return Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4.0,
          child: Container(
            width: MediaQuery.of(context).size.width - 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (context, index) {
                final wilayaNumber = options.elementAt(index);
                final wilayaName = "wilayas.$wilayaNumber".tr();
                return ListTile(
                  title: Text("$wilayaNumber - $wilayaName"),
                  onTap: () {
                    onSelected(wilayaNumber);
                  },
                );
              },
            ),
          ),
        ),
      );
    },
  );
}



Widget _buildWorkingDaysSelector(String label) {
  // Calculate the maximum width needed based on the longest day name
  final longestDay = _daysOfWeek.reduce((a, b) =>
      "days.$a".tr().length > "days.$b".tr().length ? a : b);

  final textStyle = TextStyle(fontSize: 14);
  final textSpan = TextSpan(
    text: "days.$longestDay".tr(),
    style: textStyle,
  );

  final textPainter = TextPainter(
    text: textSpan,
    textDirection: ui.TextDirection.ltr,  // Use the imported ui prefix
    maxLines: 1,
  )..layout(minWidth: 0, maxWidth: double.infinity);

  final maxWidth = textPainter.width + 32; // Add padding

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
}