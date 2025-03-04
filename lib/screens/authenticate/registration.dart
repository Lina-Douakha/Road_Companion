import 'package:flutter/material.dart';
import 'package:road_companion/services/auth_service.dart';
// import 'package:road_companion/screens/authenticate/email_verification_screen.dart';

class RegistrationScreen extends StatefulWidget {
  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  bool offerService = true;
  String serviceType = 'Mécanicien';
  bool acceptedTerms = false;
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();


  bool _validateFields() {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty ||
        confirmPasswordController.text.trim().isEmpty ||
        nameController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Tous les champs sont obligatoires"), backgroundColor: Colors.red),
      );
      return false;
    }

    // Check if passwords match
    if (passwordController.text.trim() != confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Les mots de passe ne correspondent pas"), backgroundColor: Colors.red),
      );
      return false;
    }

    return true;
  }




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

            _buildTextField(label: "Nom d'utilisateur", hint: "Username", controller: nameController),
            _buildTextField(label: "Adresse Email", hint: "Email Address", icon: Icons.email_outlined, controller: emailController),
            _buildPhoneField(), // Phone field should also use a controller
            _buildTextField(label: "Mot de passe", hint: "Password", isPassword: true, controller: passwordController),
            _buildTextField(label: "Confirmez le mot de passe", hint: "Confirm Password", isPassword: true, controller: confirmPasswordController),

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
                onPressed: acceptedTerms ? () async {
                  print("DEBUG: Email = '${emailController.text}'");
                  print("DEBUG: Password = '${passwordController.text}'");
                  print("DEBUG: Confirm Password = '${confirmPasswordController.text}'");
                  print("DEBUG: Name = '${nameController.text}'");
                  print("DEBUG: Phone = '${phoneController.text}'");

                  if (_validateFields()) {  // Ensure fields are filled
                    String? error = await _authService.registerUser(
                      emailController.text.trim(),
                      passwordController.text.trim(),
                      nameController.text.trim(),
                      phoneController.text.trim(),
                      offerService ? serviceType : "User", // Role is based on selection
                      context,
                    );

                    if (error != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error), backgroundColor: Colors.red),
                      );
                    }
                  }
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
  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    IconData? icon,
    bool isPassword = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          TextField(
            controller: controller,
            obscureText: isPassword,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: icon != null ? Icon(icon) : null,
              suffixIcon: isPassword ? const Icon(Icons.visibility_off) : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.white,
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
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: "+213 Numéro de téléphone",
              filled: true,
              fillColor: Colors.white,
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