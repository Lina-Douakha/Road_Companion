import 'package:flutter/material.dart';

class EditProfilePage extends StatefulWidget {
  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs pour les champs de saisie
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  String _selectedGender = "Femme";

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
                // Espace en haut pour déplacer la flèche et le titre vers le bas
                SizedBox(height: 50),
                // Flèche de retour et titre
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: const Color(0xFF1B9169)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    SizedBox(width: 10),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          "Modifier les informations du profil",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,  color: Color(0xFF1B9169),),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30), // Espace supplémentaire
                // Photo de profil
                _buildProfilePicture(),
                SizedBox(height: 30), // Espace supplémentaire
                // Champs de saisie
                _buildTextField("Nom", _nomController, isRequired: false),
                SizedBox(height: 20), // Espace entre les champs
                _buildTextField("Numéro de téléphone", _telephoneController, keyboardType: TextInputType.phone, isRequired: false),
                SizedBox(height: 20), // Espace entre les champs
                _buildTextField("Email", _emailController, keyboardType: TextInputType.emailAddress, isRequired: false),
                SizedBox(height: 20), // Espace entre les champs
                // Section Sexe
                _buildDropdownField("Sexe", ["Homme", "Femme"]),
                SizedBox(height: 30), // Espace supplémentaire
                // Bouton Enregistrer
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
          backgroundImage: AssetImage('assets/images/photo_de_profile.png'), // Remplacez par le chemin de votre image
          child: _selectedGender == "Femme"
              ? null
              : Icon(Icons.person, size: 50, color: Colors.white), // Image par défaut si aucune photo n'est définie
        ),
        Positioned(
          right: 4,
          bottom: 4,
          child: CircleAvatar(
            radius: 16,
            backgroundColor: Colors.black,
            child: Icon(Icons.edit, color: Colors.white, size: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text, bool isRequired = true, bool hasBorder = true}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: hasBorder ? OutlineInputBorder(borderRadius: BorderRadius.circular(10)) : InputBorder.none,
      ),
      validator: isRequired
          ? (value) {
              if (value == null || value.isEmpty) {
                return 'Ce champ est obligatoire';
              }
              return null;
            }
          : null,
    );
  }

  Widget _buildDropdownField(String label, List<String> options) {
    return Container(
      width: double.infinity, // Largeur égale à celle des autres champs
      child: DropdownButtonFormField<String>(
        value: _selectedGender,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        items: options.map((String gender) {
          return DropdownMenuItem(value: gender, child: Text(gender));
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _selectedGender = newValue!;
          });
        },
      ),
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
        content: Text('Informations enregistrées avec succès !'),
        backgroundColor: Colors.green,
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erreur : Veuillez creessayer plus tard !.'),
        backgroundColor: Colors.red, 
      ),
    );
  }
},

      child: Text("Enregistrer", style: TextStyle(color: Colors.white, fontSize: 16)),
    );
  }
}