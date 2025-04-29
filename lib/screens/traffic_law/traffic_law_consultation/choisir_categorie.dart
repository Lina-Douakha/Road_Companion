import 'package:flutter/material.dart';
import 'package:road_companion/screens/traffic_law/traffic_law_consultation/priorité_passage.dart';
import 'package:road_companion/screens/traffic_law/traffic_law_consultation/panneaux_principal.dart';
import 'package:road_companion/screens/traffic_law/traffic_law_consultation/questionExamen.dart';
import 'package:road_companion/screens/traffic_law/traffic_law_consultation/penalties.dart';
import 'package:easy_localization/easy_localization.dart';

class ChoisirCategorie extends StatelessWidget {
  const ChoisirCategorie({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 60),
              Text(
                tr("Categories.Choose"),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B9169),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Divider(
                  color: const Color(0xFF1B9169).withOpacity(0.2),
                  thickness: 1,
                ),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 0.85,
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        categorieItem(
                          context,
                          'assets/images/priorités.png',
                          tr("Categories.Prio"),
                              () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PriorityQuestionScreen(),
                            ),
                          ),
                          const Color(0xFFE5F6EF),
                        ),
                        categorieItem(
                          context,
                          'assets/images/panneaux.png',
                          tr("Categories.Panels"),
                              () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChoisirPanneauxGlobal(),
                            ),
                          ),
                          const Color(0xFFF2F8FF),
                        ),
                        categorieItem(
                          context,
                          'assets/images/exam.png',
                          tr("Categories.Questions_title"),
                              () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QuestionExamen(),
                            ),
                          ),
                          const Color(0xFFFFF8E5),
                        ),
                        categorieItem(
                          context,
                          'assets/images/penalties.png',
                          tr("Categories.Pénalités"),
                              () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => Law()),
                          ),
                          const Color(0xFFFEEDEF),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget categorieItem(
      BuildContext context,
      String imagePath,
      String title,
      VoidCallback onPressed,
      Color iconBgColor,
      ) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 3,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(24),
          splashColor: iconBgColor.withOpacity(0.3),
          highlightColor: iconBgColor.withOpacity(0.15),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset(
                        imagePath,
                        width: 65,
                        height: 65,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF424752),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}