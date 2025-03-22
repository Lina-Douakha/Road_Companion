import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class ProfilePhotoSelectionPage extends StatelessWidget {
  final List<String> profilePhotos = [
    'assets/images/profile/profile1.png',
    'assets/images/profile/profile2.png',
    'assets/images/profile/profile3.png',
    'assets/images/profile/profile4.png',
    'assets/images/profile/profile5.png',
    'assets/images/profile/profile6.png',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 50), // Ensure space from the top status bar

          // Custom Header (Back Button + Title)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF1B9169), size: 24),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 10),
                Text(
                  "edit_profile.choose_photo".tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B9169),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20), // Space before the grid

          // Profile Photos Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: profilePhotos.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    // Return the selected photo path to EditProfilePage
                    Navigator.pop(context, profilePhotos[index]);
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      profilePhotos[index],
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


