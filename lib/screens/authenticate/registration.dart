import 'package:flutter/material.dart';
import 'package:road_companion/services/auth_service.dart';
import 'package:flutter/services.dart';
import 'login.dart';
import 'package:file_picker/file_picker.dart';
import 'package:easy_localization/easy_localization.dart';

class RegistrationScreen extends StatefulWidget {
  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
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
        statusBarColor: Color(0xFF1B9169),
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 50),
                Center(
                  child: Text(
                    'registration.welcome'.tr(),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    'registration.title'.tr(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
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
                ],
                const SizedBox(height: 10),

                // Terms and conditions
                Row(
                  children: [
                    Checkbox(
                      value: acceptedTerms,
                      onChanged: (val) {
                        setState(() {
                          acceptedTerms = val ?? false;
                        });
                      },
                      activeColor: Colors.green,
                    ),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(color: Colors.black),
                          children: [
                            TextSpan(text: 'registration.accept_terms'.tr()),
                            TextSpan(
                              text: 'registration.terms_conditions'.tr(),
                              style: const TextStyle(
                                color: Colors.green,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Register button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: acceptedTerms ? Colors.green : const Color(0xFFCBD5E1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: acceptedTerms
                        ? () async {
                            if (_validateFields()) {
                              String? error = await _authService.registerUser(
                                emailController.text.trim(),
                                passwordController.text.trim(),
                                nameController.text.trim(),
                                phoneController.text.trim(),
                                offerService ? serviceType : userRole,
                                context,
                              );

                              if (error != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(error),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        : null,
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
            borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
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
            borderSide: const BorderSide(color: Colors.green, width: 2),
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
          activeColor: Colors.green,
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
          activeColor: Colors.green,
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
                    color: fileName != null ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const Icon(Icons.upload_file, color: Colors.green),
            ],
          ),
        ),
      ),
    );
  }
}