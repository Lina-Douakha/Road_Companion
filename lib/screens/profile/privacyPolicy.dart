import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';



class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});
  void _showDeleteConfirmation(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "privacy.delete_confirmation_title".tr()
                ,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                "privacy.delete_confirmation_message".tr(),
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Ajoute ici la logique de suppression
                  Navigator.pop(context); // Ferme le pop-up
                  // Redirige vers la page de suppression si nécessaire
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF00D47E), // Couleur du bouton
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: Size(double.infinity, 48), // Largeur max
                ),
                child: Text("privacy.delete_account".tr(), style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Ferme le pop-up
                },
                child: Text(
                  "privacy.contact_us".tr(),
                  style: TextStyle(color: Color(0xFF00D47E), fontSize: 16),
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCustomHeader(context), // En-tête
          const SizedBox(height: 20), // Espace avant les options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                _buildOptionTile(
                  icon: Icons.article,
                  text: "privacy.terms_and_conditions".tr(),
                  onTap: () {

                  },
                ),
                const SizedBox(height: 10),
                _buildOptionTile(
                  icon: Icons.person_remove,
                  text: "privacy.delete_account".tr(),
                  onTap: () {
                    _showDeleteConfirmation(context);
                  },
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }

  /// En-tête personnalisé sans AppBar
  Widget _buildCustomHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 70.0, left: 16.0, right: 16.0, bottom: 20.0), // Aligné avec les autres pages
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color:  Color(0xFF1B9169), size: 24),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Text(
            "privacy.title".tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B9169),
            ),
          ),
        ],
      ),
    );
  }

  /// Widget pour les options de la politique de confidentialité
  Widget _buildOptionTile({required IconData icon, required String text, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100], // Couleur de fond légère
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Color(0xFF00D47E), size: 28), // Icône verte
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey), // Flèche de navigation
          ],
        ),
      ),
    );
  }
}
