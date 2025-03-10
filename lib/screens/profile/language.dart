import 'package:flutter/material.dart';

class LanguageSelectionPage extends StatefulWidget {
  @override
  _LanguageSelectionPageState createState() => _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends State<LanguageSelectionPage> {
  String _selectedLanguage = "Français"; // Langue sélectionnée par défaut

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Corrige le fond noir
      appBar: AppBar(
        title: Text("Choisir la langue"),
        backgroundColor: Colors.green[700],
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            _showLanguageSelection(context);
          },
          child: Text("Changer de langue"),
        ),
      ),
    );
  }

  void _showLanguageSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white, // Fond blanc pour éviter le noir
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Sélectionnez une langue",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              _buildLanguageOption(context, "Français"),
              _buildLanguageOption(context, "Anglais (English)"),
              _buildLanguageOption(context, "Arabe (العربية)"),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(BuildContext context, String language) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLanguage = language; // Met à jour l'état
        });
        Navigator.pop(context); // Ferme la modal après sélection
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: _selectedLanguage == language ? Colors.green[100] : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(language, style: TextStyle(fontSize: 16)),
            if (_selectedLanguage == language)
              Icon(Icons.check, color: Colors.green),
          ],
        ),
      ),
    );
  }
}
