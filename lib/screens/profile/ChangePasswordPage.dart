import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePasswordPage extends StatefulWidget {
  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isObscured = true;
  bool _isLoading = false;

  Future<void> _changePassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("change_password.no_user".tr())),
        );
        setState(() => _isLoading = false);
        return;
      }

      try {
        // Step 1: Reauthenticate the user with their current password
        final AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: _currentPasswordController.text,
        );

        await user.reauthenticateWithCredential(credential);

        // Step 2: Update the password
        await user.updatePassword(_newPasswordController.text);

        // Success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("change_password.success_message".tr()),
            backgroundColor: Colors.green,
          ),
        );

        // ✅ **Navigate back to Profile Page**
        Navigator.pop(context); // Return to the previous page (Profile Page)

      } on FirebaseAuthException catch (e) {
        // Handle errors
        String errorMessage;
        switch (e.code) {
          case "wrong-password":
            errorMessage = "change_password.wrong_current_password".tr();
            break;
          case "weak-password":
            errorMessage = "change_password.min_length".tr();
            break;
          default:
            errorMessage = "change_password.error".tr();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF1B9169), size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  "change_password.title".tr(),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00D47E),
                  ),
                ),
              ),
              const SizedBox(height: 50),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildPasswordField("change_password.current_password".tr(), _currentPasswordController),
                    const SizedBox(height: 16),
                    _buildPasswordField("change_password.new_password".tr(), _newPasswordController),
                    const SizedBox(height: 16),
                    _buildPasswordField("change_password.confirm_password".tr(), _confirmPasswordController, confirm: true),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _changePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00D47E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(48),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                "change_password.update_button".tr(),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller, {bool confirm = false}) {
    return TextFormField(
      controller: controller,
      obscureText: _isObscured,
      validator: (value) {
        if (value == null || value.isEmpty) return "change_password.required_field".tr();
        if (!confirm && value.length < 6) return "change_password.min_length".tr();
        if (confirm && value != _newPasswordController.text) return "change_password.password_mismatch".tr();
        return null;
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
          borderSide: const BorderSide(color: Colors.green, width: 2),
        ),
        suffixIcon: IconButton(
          icon: Icon(_isObscured ? Icons.visibility_off : Icons.visibility),
          onPressed: () {
            setState(() => _isObscured = !_isObscured);
          },
        ),
      ),
    );
  }
}
