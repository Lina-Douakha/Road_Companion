import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';


class AdminExamManager extends StatefulWidget {
  @override
  _AdminExamManagerState createState() => _AdminExamManagerState();
}

class _AdminExamManagerState extends State<AdminExamManager> {
  String selectedTest = 'Test1';
  List<String> questionIds = [];
  Map<String, Set<String>> modifiedQuestions = {};
  Set<String> pendingModifications = {};
  Map<String, Map<String, Map<String, dynamic>>> pendingChanges = {};
  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    fetchTestQuestions();
  }
  @override
  void dispose() {
    modifiedQuestions.clear();
    pendingModifications.clear();
    super.dispose();
  }
  Future<void> fetchTestQuestions() async {
    setState(() {
      isLoading = true;
    });

    try {
      final doc = await FirebaseFirestore.instance.collection('Exam Test').doc(selectedTest).get();
      if (doc.exists) {
        final newQuestionIds = List<String>.from(doc['ExamQuestions']);

        setState(() {
          questionIds = newQuestionIds;
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching test questions: $e");
      setState(() {
        isLoading = false;
      });
    }
  }
  void deleteQuestion(String id) async {
    questionIds.remove(id);
    await FirebaseFirestore.instance.collection('Exam Test')
        .doc(selectedTest)
        .update({
      'ExamQuestions': questionIds,
    });
    setState(() {});
  }

  Future<Map<String, dynamic>> fetchQuestionData(String id, String languageCode) async {
    String collection;

    if (languageCode == 'ar') {
      collection = id.startsWith('Theo') ? 'theoquestions-ar' : 'Questions-arb';
    } else {
      // Default to French
      collection = id.startsWith('Theo') ? 'Theoquestions' : 'Questions';
    }

    final doc = await FirebaseFirestore.instance.collection(collection).doc(id).get();
    return doc.data() ?? {};
  }
  Future<void> editQuestionDialog(BuildContext context, String questionId, String languageCode) async {
    final isTheo = questionId.startsWith('TheoQuestion');
    final otherLanguage = languageCode == 'ar' ? 'fr' : 'ar';
    final Language = languageCode == 'ar' ? 'French' : 'Arabic';

    final bool hasPendingChanges = pendingChanges.containsKey(questionId) &&
        pendingChanges[questionId]!.containsKey(languageCode);

    Map<String, dynamic> data;
    if (hasPendingChanges) {
      data = pendingChanges[questionId]![languageCode]!;
    } else {

      data = await fetchQuestionData(questionId, languageCode);
    }

    if (data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Question not found')),
      );
      return;
    }
    final String category = data['Category'] ?? '';
    final String imageAssetPath = 'assets/images/$category/${data['ImageURL'] ?? ''}';
    final questionController = TextEditingController(text: data['QuestionText']);
    final imageController = TextEditingController(text: data['ImageURL'] ?? '');
    final options = List<String>.from(data['Options'] ?? []);
    final optionControllers = options.map((e) => TextEditingController(text: e)).toList();

    List<int> correctIndices = [];
    String correctAnswer = "";

    if (isTheo) {
      correctIndices = List<int>.from(data['CorrectAnswer'] ?? []);
    } else {
      correctAnswer = data['CorrectAnswer'] ?? '';
    }

    bool hasOtherLanguageChanges = pendingChanges.containsKey(questionId) &&
        pendingChanges[questionId]!.containsKey(otherLanguage);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white,
            insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85, // Wider dialog
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dialog title with matching style
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Edit ${isTheo ? "Theoretical" : "Test"} Question',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B9169),
                        ),
                      ),

                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(0xFF1B9169).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          languageCode.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B9169),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  if (pendingChanges.containsKey(questionId))
                    Container(
                      padding: EdgeInsets.all(10),
                      margin: EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: hasOtherLanguageChanges
                            ? Color(0xFF00D47E).withOpacity(0.2)
                            : Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: hasOtherLanguageChanges
                                ? Color(0xFF00D47E).withOpacity(0.5)
                                : Colors.amber.withOpacity(0.5)
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                              hasOtherLanguageChanges
                                  ? Icons.check_circle_outline
                                  : Icons.warning_amber_rounded,
                              color: hasOtherLanguageChanges
                                  ? Color(0xFF00D47E)
                                  : Colors.amber[700],
                              size: 18
                          ),
                          SizedBox(width: 8),

                          Expanded(
                            child: Text(
                              hasOtherLanguageChanges
                                  ? "The ${Language} version has been modified. Save this version to update both simultaneously."
                                  : "You must edit this question in ${Language} as well before changes take effect.",
                              style: TextStyle(
                                fontSize: 12,
                                color: hasOtherLanguageChanges
                                    ? Color(0xFF00D47E)
                                    : Colors.amber[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),

                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Theme(
                            data: Theme.of(context).copyWith(
                              textSelectionTheme: TextSelectionThemeData(
                                cursorColor: Color(0xFF00D47E),
                                selectionColor: Color(0xFF00D47E).withOpacity(0.3),
                                selectionHandleColor: Color(0xFF00D47E),
                              ),
                            ),
                              child: TextField(
                                cursorColor: Color(0xFF00D47E),
                                controller: questionController,
                                style: TextStyle(fontSize: 15),
                                maxLines: 3,
                                minLines: 1,
                                textAlign: languageCode == 'ar' ? TextAlign.right : TextAlign.left,
                                decoration: InputDecoration(
                                  labelText: 'Question Text',
                                  alignLabelWithHint: true,
                                  labelStyle: TextStyle(fontSize: 14, color: Color(0xFF1B9169)),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: Color(0xFF1B9169).withOpacity(0.3)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: Color(0xFF00D47E), width: 1.5),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  fillColor: Color(0xFF1B9169).withOpacity(0.05),
                                  filled: true,
                                ),
                              ),
                            ),

                          if (!isTheo)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  textSelectionTheme: TextSelectionThemeData(
                                    cursorColor: Color(0xFF00D47E),
                                    selectionColor: Color(0xFF00D47E).withOpacity(0.3),
                                    selectionHandleColor: Color(0xFF00D47E),
                                  ),
                                ),

                                  child: TextField(
                                    cursorColor: Color(0xFF00D47E),
                                    controller: imageController,
                                    style: TextStyle(fontSize: 15),
                                    decoration: InputDecoration(
                                      labelText: 'Image URL',
                                      alignLabelWithHint: true,
                                      labelStyle: TextStyle(fontSize: 14, color: Color(0xFF1B9169)),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(color: Color(0xFF1B9169).withOpacity(0.3)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(color: Color(0xFF00D47E), width: 1.5),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      fillColor: Color(0xFF1B9169).withOpacity(0.05),
                                      filled: true,
                                      prefixIcon: languageCode != 'ar' ? Icon(Icons.image_outlined, color: Color(0xFF1B9169), size: 20) : null,
                                      suffixIcon: languageCode == 'ar' ? Icon(Icons.image_outlined, color: Color(0xFF1B9169), size: 20) : null,
                                    ),
                                  ),
                                ),
                              ),

                          if (data['ImageURL'] != null && data['ImageURL'].toString().isNotEmpty)
                            Container(
                              margin: EdgeInsets.only(top: 12), // reduced margin
                              padding: EdgeInsets.all(6), // reduced padding
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.grey.shade100,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 6.0),
                                    child: Text(
                                      'Image Preview:',
                                      style: TextStyle(
                                        color: Color(0xFF1B9169),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.asset(
                                      imageAssetPath,
                                      height: 110,
                                      width: double.infinity,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        height: 110,
                                        width: double.infinity,
                                        color: Colors.grey.shade200,
                                        alignment: Alignment.center,
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.broken_image, size: 36, color: Colors.grey),
                                            SizedBox(height: 6),
                                            Text(
                                              'Image not found: $imageAssetPath',
                                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 24),

                          Container(
                            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            decoration: BoxDecoration(
                              color: Color(0xFF1B9169).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.list_alt, size: 18, color: Color(0xFF1B9169)),
                                SizedBox(width: 8),
                                Text(
                                  "Answer Options",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1B9169),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          ...optionControllers.asMap().entries.map((entry) {
                            final i = entry.key;
                            final controller = entry.value;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.05),
                                    spreadRadius: 1,
                                    blurRadius: 3,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                                border: Border.all(
                                  color: Color(0xFF1B9169).withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Directionality(
                                textDirection: languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
                                child: Row(
                                  children: [

                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8),
                                      child: isTheo
                                          ? Theme(
                                        data: Theme.of(context).copyWith(
                                          unselectedWidgetColor: Color(0xFF1B9169).withOpacity(0.4),
                                        ),
                                        child: Checkbox(
                                          activeColor: Color(0xFF00D47E),
                                          checkColor: Colors.white,
                                          value: correctIndices.contains(i),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          onChanged: (val) {
                                            setState(() {
                                              val! ? correctIndices.add(i) : correctIndices.remove(i);
                                            });
                                          },
                                        ),
                                      )
                                          : Theme(
                                        data: Theme.of(context).copyWith(
                                          unselectedWidgetColor: Color(0xFF1B9169).withOpacity(0.4),
                                        ),
                                        child: Radio<String>(
                                          value: controller.text,
                                          groupValue: correctAnswer,
                                          activeColor: Color(0xFF00D47E),
                                          onChanged: (val) {
                                            setState(() {
                                              correctAnswer = val!;
                                            });
                                          },
                                        ),
                                      ),
                                    ),

                                    Expanded(
                                      child: Theme(
                                        data: Theme.of(context).copyWith(
                                          textSelectionTheme: TextSelectionThemeData(
                                            cursorColor: Color(0xFF00D47E),
                                            selectionColor: Color(0xFF00D47E).withOpacity(0.3),
                                            selectionHandleColor: Color(0xFF00D47E),
                                          ),
                                        ),
                                        child: TextField(
                                          cursorColor: Color(0xFF00D47E),
                                          controller: controller,
                                          style: TextStyle(fontSize: 15),
                                          textAlign: languageCode == 'ar' ? TextAlign.right : TextAlign.left,
                                          decoration: InputDecoration(
                                            hintText: 'Option ${i + 1}',
                                            hintStyle: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade500,
                                            ),
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                                            enabledBorder: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Cancel button
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: Color(0xFF1B9169),
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Save button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF00D47E),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),


                        onPressed: () async {
                          final updatedOptions = optionControllers.map((e) => e.text.trim()).toList();

                          final Map<String, dynamic> updatedData = {
                            'QuestionText': questionController.text.trim(),
                            'Options': updatedOptions,
                          };

                          if (isTheo) {
                            updatedData['CorrectAnswer'] = correctIndices;
                          } else {
                            updatedData['CorrectAnswer'] = correctAnswer;
                            updatedData['ImageURL'] = imageController.text.trim();
                          }

                          bool hasChanges = false;

                          if (data['QuestionText'] != updatedData['QuestionText']) {
                            hasChanges = true;
                          }

                          if (!isTheo && (data['ImageURL'] ?? '') != updatedData['ImageURL']) {
                            hasChanges = true;
                          }

                          List<String> originalOptions = List<String>.from(data['Options'] ?? []);
                          if (originalOptions.length != updatedData['Options'].length) {
                            hasChanges = true;
                          } else {
                            for (int i = 0; i < originalOptions.length; i++) {
                              if (originalOptions[i] != updatedData['Options'][i]) {
                                hasChanges = true;
                                break;
                              }
                            }
                          }

                          if (isTheo) {
                            List<int> originalCorrect = List<int>.from(data['CorrectAnswer'] ?? []);
                            if (originalCorrect.length != correctIndices.length) {
                              hasChanges = true;
                            } else {

                              originalCorrect.sort();
                              List<int> sortedCorrectIndices = List<int>.from(correctIndices)..sort();

                              for (int i = 0; i < originalCorrect.length; i++) {
                                if (originalCorrect[i] != sortedCorrectIndices[i]) {
                                  hasChanges = true;
                                  break;
                                }
                              }
                            }
                          } else {
                            if ((data['CorrectAnswer'] ?? '') != correctAnswer) {
                              hasChanges = true;
                            }
                          }

                          if (hasChanges) {

                            if (!pendingChanges.containsKey(questionId)) {
                              pendingChanges[questionId] = {};
                            }
                            pendingChanges[questionId]![languageCode] = updatedData;


                            bool readyToSave = pendingChanges[questionId]!.containsKey('ar') &&
                                pendingChanges[questionId]!.containsKey('fr');

                            if (readyToSave) {

                              try {

                                final batch = FirebaseFirestore.instance.batch();

                                final frCollection = isTheo ? 'Theoquestions' : 'Questions';
                                final frDocRef = FirebaseFirestore.instance
                                    .collection(frCollection)
                                    .doc(questionId);
                                batch.update(frDocRef, pendingChanges[questionId]!['fr']!);


                                final arCollection = isTheo ? 'Theoquestions-ar' : 'Questions-arb';
                                final arDocRef = FirebaseFirestore.instance
                                    .collection(arCollection)
                                    .doc(questionId);
                                batch.update(arDocRef, pendingChanges[questionId]!['ar']!);

                                await batch.commit();

                                pendingChanges.remove(questionId);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error updating question: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );

                                return;
                              }
                              Navigator.pop(context);
                              showSuccessDialog(context,  "Both versions updated successfully!");
                              fetchTestQuestions();
                            } else {

                              this.setState(() {}); // Update parent widget state
                              Navigator.pop(context);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Changes saved. Please edit the ${Language} version to complete the update.',
                                  style: TextStyle(color: Colors.amber[700], fontWeight: FontWeight.bold),
                                  ),
                                  backgroundColor: Colors.amber[50],

                                  duration: Duration(seconds: 3),
                                ),
                              );
                            }
                          } else {

                            Navigator.pop(context);
                          }
                        },
                        child: Text(
                          hasOtherLanguageChanges ? 'Save Both Versions' : 'Save Changes',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  void showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        Future.delayed(Duration(seconds: 1), () {
          Navigator.of(context).pop();
        });

        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 60,
                  width: 60,
                  child: Icon(
                    Icons.check_circle_outline,
                    size: 50,
                    color: Color(0xFF00D47E),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  Widget buildIconCircle({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.1),
        ),

            child: Icon(
              icon,
              size: 16,
              color: color,
            ),

        ),
    );
  }
  String selectedLanguage = "fr";

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    final testItems = List.generate(20, (i) => 'Test${i + 1}');
    if (!testItems.contains(selectedTest)) {
      selectedTest = testItems.first;
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF1B9169),
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Fixed Title
              Container(
                height: screenHeight * 0.12,
                alignment: Alignment.bottomCenter,
                padding: EdgeInsets.only(bottom: screenHeight * 0.03),
                child: Text(
                  'Manage Questions',
                  style: TextStyle(
                    color: Color(0xFF1B9169),
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth * 0.04,
                  ),
                ),
              ),


              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [

                    Container(
                      width: 140,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: Color(0xFF1B9169).withOpacity(0.1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedTest,
                          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF00D47E)),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF1B9169),
                            fontWeight: FontWeight.bold,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          dropdownColor: Colors.white,
                          isExpanded: true,
                          menuMaxHeight: 300,
                          items: testItems.map((test) {
                            return DropdownMenuItem(
                              value: test,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(test),
                                  if (test == selectedTest)
                                    const Icon(Icons.check_circle, color: Color(0xFF00D47E), size: 16),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                selectedTest = value;
                              });
                              fetchTestQuestions();
                            }
                          },
                        ),
                      ),
                    ),

                    Container(
                      width: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: Color(0xFF1B9169).withOpacity(0.1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedLanguage = "fr";
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: selectedLanguage == "fr" ? Color(0xFF00D47E) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "FR",
                                style: TextStyle(
                                  color: selectedLanguage == "fr" ? Colors.white : Color(0xFF1B9169),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedLanguage = "ar";
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: selectedLanguage == "ar" ? Color(0xFF00D47E) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "AR",
                                style: TextStyle(
                                  color: selectedLanguage == "ar" ? Colors.white : Color(0xFF1B9169),
                                  fontWeight: FontWeight.bold,
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

              Expanded(
                child: CustomScrollView(
                  slivers: [

                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          final questionNum = index + 1;
                          final id = questionIds[index];
                          final hasPendingChanges = pendingChanges.containsKey(id);
                          final pendingLanguages = hasPendingChanges
                              ? pendingChanges[id]!.keys.map((lang) => lang.toUpperCase()).join(' / ')
                              : '';

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 6.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16.0),
                                border: hasPendingChanges
                                    ? Border.all(color: Colors.amber, width: 1.5)
                                    : null,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                      hasPendingChanges ? Icons.warning_amber_rounded : Icons.help_outline,
                                      color: hasPendingChanges ? Colors.amber[700] : Colors.grey[900],
                                      size: 20
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Question $questionNum',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[900],
                                          ),
                                        ),
                                        if (hasPendingChanges)
                                          Text(
                                            'Modified in: $pendingLanguages - needs other language',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.amber[700],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  buildIconCircle(
                                    icon: Icons.edit_outlined,
                                    color: const Color(0xFF1B9169),
                                    onTap: () {
                                      editQuestionDialog(context, id, selectedLanguage);
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  buildIconCircle(
                                    icon: Icons.delete_outlined,
                                    color: Colors.orange,
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Center(
                                            child: Text(
                                              'Question removal',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          content: Text(
                                            'Are you sure you want to delete this question?',
                                            style: TextStyle(color: Colors.grey[800]),
                                          ),
                                          actions: [
                                            TextButton(
                                              child: const Text(
                                                'Cancel',
                                                style: TextStyle(color: Color(0xFF00D47E)),
                                              ),
                                              onPressed: () => Navigator.of(context).pop(),
                                            ),
                                            TextButton(
                                              onPressed: () async {
                                                Navigator.of(context).pop();
                                                showDialog(
                                                  context: context,
                                                  barrierDismissible: false,
                                                  builder: (context) {
                                                    Future.delayed(Duration(seconds: 2), () {
                                                      Navigator.of(context).pop();
                                                    });
                                                    return Dialog(
                                                      backgroundColor: Colors.white,
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                      child: Padding(
                                                        padding: const EdgeInsets.all(20),
                                                        child: Column(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            SizedBox(
                                                              height: 60,
                                                              width: 60,
                                                              child: Lottie.asset('assets/animation/deleted.json'),
                                                            ),
                                                            const SizedBox(height: 12),
                                                            const Text(
                                                              'Question deleted!',
                                                              style: TextStyle(
                                                                color: Colors.black87,
                                                                fontWeight: FontWeight.w600,
                                                                fontSize: 16,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                              style: TextButton.styleFrom(
                                                backgroundColor: const Color(0xFF00D47E),
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                              ),
                                              child: const Text('Confirm'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: questionIds.length,
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
}