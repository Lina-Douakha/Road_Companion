import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:road_companion/widgets/navigation_bar_widget.dart';

class Law extends StatefulWidget {
  @override
  _LawState createState() => _LawState();
}

class _LawState extends State<Law> {
  final List<Map<String, String>> questions = [
    {
      "passage":
      "مقتطف من القانون 01-14 المؤرخ في 19 أوت 2001 المتعلق بتنظيم حركة المرور وسلامتها وأمنها",
      "titre": "القسم الأول: المخالفات والعقوبات",
      "contenue":
      "المادة 66: تصنيف المخالفات\n"
          "يتم تصنيف المخالفات الخاصة بحركة المرور إلى أربعة درجات:\n\n"
          "1. مخالفات من الدرجة الأولى:\n"
          " - غرامة مالية تتراوح بين 2000 و 2500 دج.\n"
          " - عدم احترام قواعد الإشارة والفرملة الخاصة بالدراجات.\n"
          " - عدم تقديم أو غياب وثائق السيارة أو رخصة السياقة المهنية.\n"
          " - استخدام جهاز أو أداة غير مطابقة للقانون.\n"
          " - عدم احترام قواعد عبور الممرات المحمية للمشاة.\n",
    },
  ];

  int currentIndex = 0;

  void nextQuestion() {
    setState(() {
      currentIndex = (currentIndex + 1) % questions.length;
    });
  }

  void previousQuestion() {
    setState(() {
      currentIndex = (currentIndex - 1 + questions.length) % questions.length;
    });
  }

  int _selectedIndex = 0;
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final questionData = questions[currentIndex];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF1B9169),
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 70),

              const Text(
                'القانون المروري',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B9169),
                ),
              ),
              SizedBox(height: 30),

              // Conteneur principal avec Expanded
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Passage
                      _buildTextField(
                        questionData["passage"] ?? "Passage غير متوفر",
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        backgroundColor: Colors.white,
                      ),

                      SizedBox(height: 20),

                      // Titre avec style différent
                      _buildTextField(
                        questionData["titre"] ?? "Titre غير متوفر",
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        backgroundColor: Color(0xFFD1FADF), // Fond coloré
                      ),

                      SizedBox(height: 20),

                      // Contenu principal
                      _buildTextField(
                        questionData["contenue"] ?? "Contenu غير متوفر",
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                        backgroundColor: Colors.white,
                      ),

                      SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              // Boutons pour naviguer entre les questions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: previousQuestion,
                    icon: Icon(Icons.arrow_circle_left_outlined, size: 30),
                    color: Color(0xFF1B9169),
                    tooltip: "السؤال السابق",
                  ),
                  IconButton(
                    onPressed: nextQuestion,
                    icon: Icon(Icons.arrow_circle_right_outlined, size: 30),
                    color: Color(0xFF1B9169),
                    tooltip: "السؤال التالي",
                  ),
                ],
              ),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBarWidget(
          selectedIndex: _selectedIndex,
          onItemTapped: _onItemTapped,
        ),
      ),
    );
  }

  // Fonction pour générer les zones de texte
  Widget _buildTextField(
      String text, {
        double fontSize = 16,
        FontWeight fontWeight = FontWeight.normal,
        Color backgroundColor = Colors.white,
      }) {
    return SizedBox(
      width: 350,
      child: TextField(
        controller: TextEditingController(text: text),
        readOnly: true,
        maxLines: null,
        textAlign: TextAlign.right, // Texte aligné à droite pour l'arabe
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF1B9169)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF1B9169)),
          ),
          filled: true,
          fillColor: backgroundColor, // Fond coloré
        ),
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: Colors.black,
        ),
      ),
    );
  }
}