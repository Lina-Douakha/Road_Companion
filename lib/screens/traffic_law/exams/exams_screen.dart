import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ExamsScreen extends StatefulWidget {
  const ExamsScreen({super.key});

  @override
  _ExamsScreenState createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen> {
  int? selectedAnswer;

  void selectAnswer(int index) {
    setState(() {
      selectedAnswer = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF1B9169),
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            Container(
              height: screenHeight * 0.04,
              color: const Color(0xFF1B9169),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.05,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: screenHeight * 0.04), // More space above "TEST: 1"
                    Text(
                      'TEST: 1',
                      style: TextStyle(
                        fontSize: screenWidth * 0.08,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1B9169),
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.04), // More space below "TEST: 1"
                    Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.03,
                          vertical: screenHeight * 0.008,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1FADF),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Text(
                          'Question 1/10',
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1B9169),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.04), // More space above image
                    Center(
                      child: Image.asset(
                        'assets/images/prio1.jpg',
                        width: screenWidth * 0.75, // Keep the image width balanced
                        fit: BoxFit.fitWidth,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03), // More space below image
                    const Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Qui a la priorité de passage ?',
                        style: TextStyle(
                          fontSize: 18.0,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    buildAnswerOption(0, 'A. La voiture rouge', screenWidth),
                    SizedBox(height: screenHeight * 0.02),
                    buildAnswerOption(1, 'B. La voiture bleue', screenWidth),
                    SizedBox(height: screenHeight * 0.02),
                    buildAnswerOption(2, 'C. Les voitures bleue et jaune', screenWidth),
                    SizedBox(height: screenHeight * 0.05),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        CircleAvatar(
                          radius: screenWidth * 0.08,
                          backgroundColor: const Color(0xFFD1FADF),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, color: Color(0xFF1B9169)),
                            onPressed: () {},
                          ),
                        ),
                        CircleAvatar(
                          radius: screenWidth * 0.08,
                          backgroundColor: const Color(0xFFD1FADF),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_forward, color: Color(0xFF1B9169)),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildAnswerOption(int index, String text, double screenWidth) {
    return Align(
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: () => selectAnswer(index),
        child: Container(
          width: screenWidth * 0.85,
          padding: EdgeInsets.all(screenWidth * 0.04),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: selectedAnswer == index
                  ? const Color(0xFF00D47E)
                  : Colors.grey[300]!,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text(text, textAlign: TextAlign.center)),
              Container(
                width: screenWidth * 0.05,
                height: screenWidth * 0.05,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selectedAnswer == index ? const Color(0xFF00D47E) : Colors.grey,
                    width: 1.0,
                  ),
                ),
                child: selectedAnswer == index
                    ? Center(
                  child: Container(
                    width: screenWidth * 0.025,
                    height: screenWidth * 0.025,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF00D47E),
                    ),
                  ),
                )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
