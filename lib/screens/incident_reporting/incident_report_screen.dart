import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:road_companion/widgets/navigation_bar_widget.dart';

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
  int _selectedIndex = 4;
  File? _selectedImage;
  bool _isButtonPressed = false;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
  }


  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/map');
        break;
      case 1:
        Navigator.pushNamed(context, '/emergency');
        break;
      case 3:
        Navigator.pushNamed(context, '/profile');
        break;
    }
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Prendre une photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choisir depuis la galerie'),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Wrap(
          children: [
            ListTile(
              title: const Text('Accident'),
              onTap: () {
                setState(() {
                  _selectedType = 'Accident';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Panne'),
              onTap: () {
                setState(() {
                  _selectedType = 'Panne';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Autre'),
              onTap: () {
                setState(() {
                  _selectedType = 'Autre';
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
        if (isDropdown) // Si c'est un champ sélectionnable
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
                Text(_selectedType ?? hint, style: TextStyle(color: _selectedType == null ? Colors.grey : Colors.black)),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          )
        else // Sinon, c'est un champ de texte normal
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: hint,
            ),
            validator: isDropdown
              ? null // Pas de validation pour les dropdowns ici
              : (value) => null,
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
            Text(_selectedImage == null ? "Télécharger une photo" : "Photo sélectionnée"),
            const Icon(Icons.cloud_upload, color: Colors.grey),
          ],
        ),
      ),
    );
  }
void _submitForm() {
  if (_selectedType == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Veuillez sélectionner un type d'incident",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  if (_formKey.currentState!.validate()) {
    _showSuccessBottomSheet();
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
        value: const SystemUiOverlayStyle(
          statusBarColor: Color(0xFF1B9169),
          statusBarIconBrightness: Brightness.light,
        ),
    child: Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.only(top: 90, left: 16, right: 16, bottom: 16),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'Signaler un incident',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1B9169)),
                  ),
                ),
                const SizedBox(height: 30),
                _buildTextField(
                  label: 'Type d’incident',
                  hint: _selectedType ?? 'Sélectionner un type',
                  onTap: _showIncidentTypeMenu,
                  isDropdown: true,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'Description',
                  hint: 'Décrivez l’incident',
                  maxLines: 3,
                  controller: _descriptionController,
                ),
                const SizedBox(height: 16),
                const Text('Photo'),
                const SizedBox(height: 8),
                _buildPhotoUploadField(),
if (_selectedImage != null)
  Container(
    alignment: Alignment.center,
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
  setState(() => _isButtonPressed = false);
  _submitForm(); // Appelle la nouvelle fonction
},
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _isButtonPressed ? const Color(0xFF61E9C4) : const Color(0xFF00D47E),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        'Envoyer',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      //bottomNavigationBar: NavigationBarWidget(selectedIndex: _selectedIndex, onItemTapped: _onItemTapped),
    ),
    );
  }
}
