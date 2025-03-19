import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';


class EditProfilePage extends StatefulWidget {
  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  String _selectedGender = "edit_profile.female".tr();

  File? _imageFile;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await showModalBottomSheet<XFile?>(
      context: context,
      builder: (context) => _buildImagePickerOptions(picker),
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Widget _buildImagePickerOptions(ImagePicker picker) {
    return Wrap(
      children: [
        ListTile(
          leading: Icon(Icons.photo_library),
          title: Text("edit_profile.choose_gallery".tr()),

          onTap: () async {
            Navigator.pop(context, await picker.pickImage(source: ImageSource.gallery));
          },
        ),
        ListTile(
          leading: Icon(Icons.camera_alt),
          title: Text("edit_profile.take_photo".tr()),

          onTap: () async {
            Navigator.pop(context, await picker.pickImage(source: ImageSource.camera));
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
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
                SizedBox(height: 30),
                _buildTextField("edit_profile.name".tr(), _nomController),
                SizedBox(height: 20),
                _buildTextField("edit_profile.phone_number".tr(), _telephoneController, keyboardType: TextInputType.phone),
                SizedBox(height: 20),
                _buildTextField("edit_profile.email".tr(), _emailController, keyboardType: TextInputType.emailAddress),
                SizedBox(height: 20),
                _buildDropdownField("edit_profile.gender".tr(), ["edit_profile.male".tr(), "edit_profile.female".tr()]),

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
          backgroundImage: _imageFile != null
              ? FileImage(_imageFile!) as ImageProvider
              : AssetImage('assets/images/photo_de_profile.png'),
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

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(

          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Color(0xFF1B9169), width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "edit_profile.required_field".tr();

        }
        return null;
      },
    );
  }

  Widget _buildDropdownField(String label, List<String> options) {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Color(0xFF1B9169), width: 2),
        ),
      ),
      items: options.map((String gender) {
        return DropdownMenuItem(value: gender, child: Text(gender));
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedGender = newValue!;
        });
      },
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
      ),
      onPressed: () {
        if (_formKey.currentState!.validate()) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("edit_profile.success_message".tr()),
              backgroundColor: Colors.green,
            ),

          );
        }
      },
      child: Text("edit_profile.save".tr(), style: TextStyle(color: Colors.white, fontSize: 16)),

    );
  }
}