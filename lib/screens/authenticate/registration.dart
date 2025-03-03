import 'package:flutter/material.dart';

class RegistrationScreen extends StatefulWidget {
  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  bool offerService = true;
  String serviceType = 'Mécanicien';
  bool acceptedTerms = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 50),
            const Center(
              child: Text(
                'Bienvenue à Road Companion',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            const Center(
              child: Text(
                "S'inscrire",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField(label: "Nom d'utilisateur", hint: "Username"),
            _buildTextField(label: "Adresse Email", hint: "Email Address", icon: Icons.email_outlined),
            _buildPhoneField(),
            _buildTextField(label: "Mot de passe", hint: "Password", isPassword: true),
            _buildTextField(label: "Confirmez le mot de passe", hint: "Confirm Password", isPassword: true),
            const SizedBox(height: 10),
            const Text("Offrez-vous un service ?", style: TextStyle(fontWeight: FontWeight.bold)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRadio("Oui", true),
                _buildRadio("Non", false),
              ],
            ),
            if (offerService) ...[
              const SizedBox(height: 10),
              const Text("Quel type de service offrez-vous ?", style: TextStyle(fontWeight: FontWeight.bold)),
              _buildServiceTypeRadio("Mécanicien"),
              _buildServiceTypeRadio("Service de remorquage"),
              _buildServiceTypeRadio("Pièces de rechange"),
              const SizedBox(height: 10),
              const Text("Veuillez ajouter les documents (obligatoires):", style: TextStyle(fontWeight: FontWeight.bold)),
              _buildStaticDocumentField("Carte d’identité (PDF)"),
              _buildStaticDocumentField("Registre de commerce (PDF)"),
            ],
            const SizedBox(height: 10),
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
                    text: const TextSpan(
                      style: TextStyle(color: Colors.black),
                      children: [
                        TextSpan(text: "En créant un compte, vous acceptez "),
                        TextSpan(
                          text: "nos conditions générales",
                          style: TextStyle(color: Colors.green, decoration: TextDecoration.underline),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: acceptedTerms ? Colors.green : const Color(0xFFCBD5E1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: acceptedTerms ? () {
                  // Logique d'inscription ici
                } : null,
                child: const Text(
                  "Continue",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({required String label, required String hint, IconData? icon, bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          TextField(
            obscureText: isPassword,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: icon != null ? Icon(icon) : null,
              suffixIcon: isPassword ? const Icon(Icons.visibility_off) : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: const Color.fromARGB(255, 255, 255, 255),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Numéro de téléphone", style: TextStyle(fontWeight: FontWeight.bold)),
          TextField(
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: "+213  Numéro de téléphone",
              filled: true,
              fillColor: const Color.fromARGB(255, 255, 255, 255),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
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

  Widget _buildServiceTypeRadio(String type) {
    return Row(
      children: [
        Radio<String>(
          value: type,
          groupValue: serviceType,
          activeColor: Colors.green,
          onChanged: (val) => setState(() => serviceType = val!),
        ),
        Text(type),
      ],
    );
  }

  Widget _buildStaticDocumentField(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            height: 50,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFFCBD5E1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Aucun fichier sélectionné",
                  style: TextStyle(color: Colors.grey),
                ),
                const Icon(Icons.add, color: Colors.grey), // Icône "+" demandée
              ],
            ),
          ),
        ],
      ),
    );
  }
}