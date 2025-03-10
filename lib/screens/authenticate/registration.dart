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
  bool _isPasswordVisible = false;
bool _isConfirmPasswordVisible = false;

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();

 
    String? identityCardFile; 
  String? commercialRegisterFile; 



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
            const Center(child: Text('Bienvenue à Road Companion', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
            const SizedBox(height: 10),
            const Center(child: Text("S'inscrire", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green))),
            const SizedBox(height: 20),

            _buildTextField(label: "Nom d'utilisateur",  controller: nameController),
            _buildTextField(label: "Adresse Email", icon: Icons.email_outlined, controller: emailController),
            _buildPhoneField(),
            _buildTextField(label: "Mot de passe", isPassword: true, controller: passwordController),
            _buildTextField(label: "Confirmez le mot de passe",  isPassword: true, controller: confirmPasswordController),

            const SizedBox(height: 10),
            const Text("Offrez-vous un service ?", style: TextStyle(fontWeight: FontWeight.bold)),
           
            Column(children: [_buildRadio("Oui", true), _buildRadio("Non", false)]),
            
            if (offerService) ...[
              const SizedBox(height: 10),
              const Text("Quel type de service offrez-vous ?", style: TextStyle(fontWeight: FontWeight.bold)),
              _buildServiceTypeRadio("Mécanicien"),
              _buildServiceTypeRadio("Service de remorquage"),
              _buildServiceTypeRadio("Pièces de rechange"),
              const SizedBox(height: 10),
              const Text("Veuillez ajouter les documents (obligatoires):", style: TextStyle(fontWeight: FontWeight.bold)),
              _buildFileUploadField("Carte d’identité (PDF)", identityCardFile, (file) {
                setState(() => identityCardFile = file);
              }),
              _buildFileUploadField("Registre de commerce (PDF)", commercialRegisterFile, (file) {
                setState(() => commercialRegisterFile = file);
              }),
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

                  if (_validateFields()) {  
                    String? error = await _authService.registerUser(
                      emailController.text.trim(),
                      passwordController.text.trim(),
                      nameController.text.trim(),
                      phoneController.text.trim(),
                      offerService ? serviceType : "User", 
                      context,
                    );

                    if (error != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error), backgroundColor: Colors.red),
                      );
                    }
                  }
                } : null,

                  child: const Text("Continue", style: TextStyle(fontSize: 18, color: Colors.white)),

              ),
            ),
          ],
        ),
      ),
    );
  }
  
Widget _buildTextField({
  required String label,
  required TextEditingController controller,
  IconData? icon,
  bool isPassword = false,
  bool isConfirmPassword = false, 
bool passwordVisible = false,
bool confirmPasswordVisible = false,

}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: TextField(
      controller: controller,
       obscureText: isPassword
          ? (isConfirmPassword ? !_isConfirmPasswordVisible : !_isPasswordVisible)
          : false,

      cursorColor: const Color(0xFF4CAF50),
      decoration: InputDecoration(
        labelText: label,
         labelStyle: const TextStyle(color: Color.fromRGBO(0, 0, 0, 1)),  // Couleur du label au repos
        floatingLabelStyle: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),  
        floatingLabelBehavior: FloatingLabelBehavior.always, 
        prefixIcon: icon != null ? Icon(icon) : null,
        suffixIcon: isPassword 
                    ? IconButton(
                icon: Icon(
                  (isConfirmPassword ? _isConfirmPasswordVisible : _isPasswordVisible)
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: Color.fromARGB(255, 88, 90, 93),
                ),
onPressed: () {
    setState(() {
        if (isConfirmPassword) {
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


Widget _buildPhoneField() => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: phoneController,
        keyboardType: TextInputType.phone,
        cursorColor: const Color(0xFF4CAF50), // Curseur vert
        decoration: InputDecoration(
          labelText: "Numéro de téléphone",
          labelStyle: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)), // Label au repos
          floatingLabelStyle: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)), // Label flottant (focus)
          floatingLabelBehavior: FloatingLabelBehavior.always,
          prefixText: "+213 ",
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color.fromARGB(255, 0, 0, 0)), // Bordure normale (gris clair)
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color.fromARGB(255, 0, 0, 0)), // Bordure normale (gris clair)
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.green, width: 2), // Bordure verte quand focus
          ),
        ),
      ),
    );


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
    Widget _buildFileUploadField(String label, String? fileName, Function(String) onFileSelected) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: GestureDetector(
          onTap: () async {/*
            FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
            if (result != null) {
              onFileSelected(result.files.single.name);
            }
          */},
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(padding: const EdgeInsets.all(12), child: Text(label)),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: fileName != null
                      ? Text(fileName, style: TextStyle(color: Colors.green))
                      : const Icon(Icons.add, color: Colors.green),
                ),
              ],
            ),
          ),
        ),
      );

 
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
                  style: TextStyle(color: Color(0xFFDBD6D6)),
                ),
                const Icon(Icons.add, color: Color(0xFFDBD6D6)), 
              ],
            ),
          ),
        ],
      ),
    );
  }
}