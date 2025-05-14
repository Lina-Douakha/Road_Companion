import 'package:flutter/material.dart';

class ClickableCard extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const ClickableCard({
    super.key,
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.green[100],
        ),
        child: Row(
          children: [
            Icon(icon, size: screenWidth * 0.08, color: Color(0xff049b5f)),
            SizedBox(width: 16),
            Text(
              text,
              style: TextStyle(
                fontSize: screenWidth * 0.045,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
