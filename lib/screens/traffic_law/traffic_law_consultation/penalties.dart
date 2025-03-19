import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert'; // Pour parser le JSON
import 'package:road_companion/widgets/navigation_bar_widget.dart';

class Law extends StatefulWidget {
  @override
  _LawState createState() => _LawState();
}

class _LawState extends State<Law> {
  Map<String, dynamic>? jsonData;
  int currentIndex = 0;
  int _selectedIndex = 0;
  String currentSection = "المخالفات";

  @override
  void initState() {
    super.initState();
    _loadJsonData();
  }

  Future<void> _loadJsonData() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/data/penalties.json',
      );
      setState(() {
        jsonData = jsonDecode(jsonString);
      });
    } catch (e) {
      print("Erreur lors du chargement ou du parsing du JSON : $e");
    }
  }

  void nextQuestion() {
    setState(() {
      currentIndex = (currentIndex + 1) % _getSectionLength();
    });
  }

  void previousQuestion() {
    setState(() {
      currentIndex =
          (currentIndex - 1 + _getSectionLength()) % _getSectionLength();
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _changeSection(String section) {
    setState(() {
      currentSection = section;
      currentIndex = 0;
    });
  }

  int _getSectionLength() {
    if (jsonData != null && jsonData!.containsKey(currentSection)) {
      final sectionData = jsonData![currentSection];
      if (sectionData is List) {
        return sectionData.length;
      } else if (sectionData is Map) {
        return sectionData.length;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    if (jsonData == null || !jsonData!.containsKey(currentSection)) {
      return Scaffold(body: Center(child: Text("Chargement en cours...")));
    }

    final sectionData = jsonData![currentSection];
    final currentData = _getCurrentData(sectionData);

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
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Color(0xFFD1FADF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFF1B9169)),
                ),
                child: DropdownButton<String>(
                  value: currentSection,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      _changeSection(newValue);
                    }
                  },
                  items:
                  jsonData!.keys.map((String key) {
                    return DropdownMenuItem<String>(
                      value: key,
                      child: Text(
                        key,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B9169),
                        ),
                      ),
                    );
                  }).toList(),
                  underline: SizedBox(),
                  icon: Icon(Icons.arrow_drop_down, color: Color(0xFF1B9169)),
                  isExpanded: true,
                ),
              ),
              SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildTextField(
                        "مقتطف من القانون 01-14 المؤرخ في 19 أوت 2001 المتعلق بتنظيم حركة المرور وسلامتها وأمنها",
                        fontSize: 16,
                        fontWeight: FontWeight.w500,

                      ),
                      SizedBox(height: 20),
                      _buildTextField(_formatData(currentData), fontSize: 16),
                      SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: previousQuestion,
                    icon: Icon(Icons.arrow_circle_left_outlined, size: 30),
                    color: Color(0xFF1B9169),
                  ),
                  IconButton(
                    onPressed: nextQuestion,
                    icon: Icon(Icons.arrow_circle_right_outlined, size: 30),
                    color: Color(0xFF1B9169),
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

  dynamic _getCurrentData(dynamic sectionData) {
    if (sectionData is List) {
      return sectionData[currentIndex];
    } else if (sectionData is Map) {
      final keys = sectionData.keys.toList()..sort();
      return sectionData[keys[currentIndex]];
    }
    return null;
  }

  String _formatData(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data.entries.map((e) => "${e.key}: ${e.value}").join("\n");
    }
    return data?.toString() ?? "غير متوفر";
  }

  Widget _buildTextField(
      String text, {
        double fontSize = 16,
        FontWeight fontWeight = FontWeight.normal,
      }) {
    return SizedBox(
      width: 350,
      child: TextField(
        controller: TextEditingController(text: text),
        readOnly: true,
        maxLines: null,
        textAlign: TextAlign.right,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: Colors.black,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}