import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

class TrafficLawsManager extends StatefulWidget {
  @override
  _TrafficLawsManagerState createState() => _TrafficLawsManagerState();
}

class _TrafficLawsManagerState extends State<TrafficLawsManager> with SingleTickerProviderStateMixin {
  String selectedLanguage = "fr"; // Default language
  String selectedCategory = "panels"; // Default category: panels, priorities, questions
  List<Map<String, dynamic>> items = [];
  bool isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      // Update selected category when tab changes
      if (_tabController.indexIsChanging) {
        setState(() {
          switch (_tabController.index) {
            case 0:
              selectedCategory = "panels";
              break;
            case 1:
              selectedCategory = "priorities";
              break;
            case 2:
              selectedCategory = "question";
              break;
          }
        });
        fetchItems();
      }
    });
    fetchItems();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchItems() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Determine collection based on selected language
      String collectionName = selectedLanguage == "fr"
          ? "Traffic-Laws"
          : "Traffic-laws-ar";

      // Query documents based on category
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection(collectionName)
          .where('Category', isEqualTo: selectedCategory)
          .get();

      List<Map<String, dynamic>> loadedItems = [];
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Add document ID to the data
        loadedItems.add(data);
      }

      setState(() {
        items = loadedItems;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching items: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> deleteItem(String id) async {
    try {
      String collectionName = selectedLanguage == "fr"
          ? "Traffic-Laws"
          : "Traffic-laws-ar";
      await FirebaseFirestore.instance.collection(collectionName)
          .doc(id)
          .delete();
      fetchItems(); // Refresh list after deletion
    } catch (e) {
      print("Error deleting item: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting item: $e')),
      );
    }
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

  Future<void> editPanelDialog(BuildContext context, Map<String, dynamic> itemData) async {
    final TextEditingController titleController = TextEditingController(text: itemData['Title'] ?? '');
    final TextEditingController imageUrlController = TextEditingController(text: itemData['ImageUrl'] ?? '');
    final String id = itemData['id'];

    // Construct full asset path for panel image
    final String imageAssetPath = 'assets/images/Panels/${itemData['ImageUrl'] ?? ''}';

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white,
            insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edit Panel',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B9169),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title field
                          Directionality(
                            textDirection: selectedLanguage == 'ar' ? TextDirection.rtl : TextDirection.ltr,
                            child:Theme(
                              data: Theme.of(context).copyWith(
                                textSelectionTheme: TextSelectionThemeData(
                                  cursorColor: Color(0xFF00D47E),

                                  selectionHandleColor: Color(0xFF00D47E),
                                ),
                              ),
                              child: TextField(
                                cursorColor: Color(0xFF00D47E),
                                controller: titleController,
                                style: TextStyle(fontSize: 15),
                                textAlign: selectedLanguage == 'ar' ? TextAlign.right : TextAlign.left,
                                decoration: InputDecoration(
                                  labelText: 'Panel Title',
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
                            )
                          ),

                          const SizedBox(height: 16),

                          // Image URL field
                          Directionality(
                            textDirection: selectedLanguage == 'ar' ? TextDirection.rtl : TextDirection.ltr,
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                textSelectionTheme: TextSelectionThemeData(
                                  cursorColor: Color(0xFF00D47E),

                                  selectionHandleColor: Color(0xFF00D47E),
                                ),
                              ),
                              child: TextField(
                                cursorColor: Color(0xFF00D47E),
                                controller: imageUrlController,
                                style: TextStyle(fontSize: 15),
                                textAlign: selectedLanguage == 'ar' ? TextAlign.right : TextAlign.left,
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
                                  prefixIcon: selectedLanguage != 'ar' ? Icon(Icons.image_outlined, color: Color(0xFF1B9169), size: 20) : null,
                                  suffixIcon: selectedLanguage == 'ar' ? Icon(Icons.image_outlined, color: Color(0xFF1B9169), size: 20) : null,
                                ),
                              ),
                            )
                          ),

                          // Display the panel image
                          if (itemData['ImageUrl'] != null && itemData['ImageUrl'].toString().isNotEmpty)
                            Container(
                              margin: EdgeInsets.only(top: 16),
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: Colors.grey.shade100,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Label for the image preview
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Text(
                                      'Image Preview:',
                                      style: TextStyle(
                                        color: Color(0xFF1B9169),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  // Image display with error handling
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.asset(
                                      imageAssetPath,
                                      height: 150,
                                      width: double.infinity,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        height: 150,
                                        width: double.infinity,
                                        color: Colors.grey.shade200,
                                        alignment: Alignment.center,
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                            SizedBox(height: 8),
                                            Text(
                                              'Image not found: $imageAssetPath',
                                              style: TextStyle(color: Colors.grey.shade700),
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
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
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
                          try {
                            String collectionName = selectedLanguage == "fr" ? "Traffic-Laws" : "Traffic-laws-ar";
                            await FirebaseFirestore.instance.collection(collectionName).doc(id).update({
                              'Title': titleController.text.trim(),
                              'ImageUrl': imageUrlController.text.trim(),
                            });

                            Navigator.pop(context);
                            showSuccessDialog(context, 'Panel updated successfully!');
                            fetchItems(); // Refresh list after update
                          } catch (e) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error updating panel: $e')),
                            );
                          }
                        },
                        child: Text(
                          'Save Changes',
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

  Future<void> editPriorityDialog(BuildContext context, Map<String, dynamic> itemData) async {
    final TextEditingController descriptionController = TextEditingController(text: itemData['Description'] ?? '');
    final TextEditingController questionController = TextEditingController(text: itemData['Question'] ?? '');
    final TextEditingController imageUrlController = TextEditingController(text: itemData['imageURL'] ?? '');
    final String id = itemData['id'];

    // Construct full asset path for priority image
    final String imageAssetPath = 'assets/images/priorities/${itemData['imageURL'] ?? ''}';

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white,
            insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edit Priority',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B9169),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Description field
                          Directionality(
                            textDirection: selectedLanguage == 'ar' ? TextDirection.rtl : TextDirection.ltr,
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                textSelectionTheme: TextSelectionThemeData(
                                  cursorColor: Color(0xFF00D47E),

                                  selectionHandleColor: Color(0xFF00D47E),
                                ),
                              ),
                              child:TextField(
                                cursorColor: Color(0xFF00D47E),
                                controller: descriptionController,
                                style: TextStyle(fontSize: 15),
                                maxLines: 3,
                                minLines: 1,
                                textAlign: selectedLanguage == 'ar' ? TextAlign.right : TextAlign.left,
                                decoration: InputDecoration(
                                  labelText: 'Description',
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
                            )
                          ),

                          const SizedBox(height: 16),

                          // Question field
                          Directionality(
                            textDirection: selectedLanguage == 'ar' ? TextDirection.rtl : TextDirection.ltr,
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                textSelectionTheme: TextSelectionThemeData(
                                  cursorColor: Color(0xFF00D47E),

                                  selectionHandleColor: Color(0xFF00D47E),
                                ),
                              ),
                              child:TextField(
                                cursorColor: Color(0xFF00D47E),
                                controller: questionController,
                                style: TextStyle(fontSize: 15),
                                maxLines: 2,
                                minLines: 1,
                                textAlign: selectedLanguage == 'ar' ? TextAlign.right : TextAlign.left,
                                decoration: InputDecoration(
                                  labelText: 'Question',
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
                            )
                          ),

                          const SizedBox(height: 16),

                          // Image URL field
                          Directionality(
                            textDirection: selectedLanguage == 'ar' ? TextDirection.rtl : TextDirection.ltr,
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                textSelectionTheme: TextSelectionThemeData(
                                  cursorColor: Color(0xFF00D47E),

                                  selectionHandleColor: Color(0xFF00D47E),
                                ),
                              ),
                              child: TextField(
                                cursorColor: Color(0xFF00D47E),
                                controller: imageUrlController,
                                style: TextStyle(fontSize: 15),
                                textAlign: selectedLanguage == 'ar' ? TextAlign.right : TextAlign.left,
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
                                  prefixIcon: selectedLanguage != 'ar' ? Icon(Icons.image_outlined, color: Color(0xFF1B9169), size: 20) : null,
                                  suffixIcon: selectedLanguage == 'ar' ? Icon(Icons.image_outlined, color: Color(0xFF1B9169), size: 20) : null,
                                ),
                              ),
                            )
                          ),

                          // Display the priority image
                          if (itemData['imageURL'] != null && itemData['imageURL'].toString().isNotEmpty)
                            Container(
                              margin: EdgeInsets.only(top: 16),
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: Colors.grey.shade100,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Label for the image preview
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Text(
                                      'Image Preview:',
                                      style: TextStyle(
                                        color: Color(0xFF1B9169),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  // Image display with error handling
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.asset(
                                      imageAssetPath,
                                      height: 150,
                                      width: double.infinity,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        height: 150,
                                        width: double.infinity,
                                        color: Colors.grey.shade200,
                                        alignment: Alignment.center,
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                            SizedBox(height: 8),
                                            Text(
                                              'Image not found: $imageAssetPath',
                                              style: TextStyle(color: Colors.grey.shade700),
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
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
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
                          try {
                            String collectionName = selectedLanguage == "fr" ? "Traffic-Laws" : "Traffic-laws-ar";
                            await FirebaseFirestore.instance.collection(collectionName).doc(id).update({
                              'Description': descriptionController.text.trim(),
                              'Question': questionController.text.trim(),
                              'imageURL': imageUrlController.text.trim(),
                            });

                            Navigator.pop(context);
                            showSuccessDialog(context, 'Priority updated successfully!');
                            fetchItems(); // Refresh list after update
                          } catch (e) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error updating priority: $e')),
                            );
                          }
                        },
                        child: Text(
                          'Save Changes',
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

  Future<void> editQuestionDialog(BuildContext context,
      Map<String, dynamic> itemData) async {
    final TextEditingController questionTextController = TextEditingController(
        text: itemData['QuestionText'] ?? '');
    final TextEditingController answerController = TextEditingController(
        text: itemData['Answer'] ?? '');
    final String id = itemData['id'];

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) =>
              Dialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                backgroundColor: Colors.white,
                insetPadding: EdgeInsets.symmetric(
                    horizontal: 20, vertical: 24),
                child: Container(
                  width: MediaQuery
                      .of(context)
                      .size
                      .width * 0.85,
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit Question',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B9169),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Question text field
                              Directionality(
                                textDirection: selectedLanguage == 'ar'
                                    ? TextDirection.rtl
                                    : TextDirection.ltr,
                                child: Theme(
                                  data: Theme.of(context).copyWith(
                                    textSelectionTheme: TextSelectionThemeData(
                                      cursorColor: Color(0xFF00D47E),
                                      selectionHandleColor: Color(0xFF00D47E),
                                    ),
                                  ),
                                  child:TextField(
                                    cursorColor: Color(0xFF00D47E),
                                    controller: questionTextController,
                                    style: TextStyle(fontSize: 15),
                                    maxLines: 3,
                                    minLines: 1,
                                    textAlign: selectedLanguage == 'ar'
                                        ? TextAlign.right
                                        : TextAlign.left,
                                    decoration: InputDecoration(
                                      labelText: 'Question Text',
                                      alignLabelWithHint: true,
                                      labelStyle: TextStyle(
                                          fontSize: 14, color: Color(0xFF1B9169)),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(
                                            color: Color(0xFF1B9169).withOpacity(
                                                0.3)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(
                                            color: Color(0xFF00D47E), width: 1.5),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      fillColor: Color(0xFF1B9169).withOpacity(
                                          0.05),
                                      filled: true,
                                    ),
                                  ),
                                )
                              ),

                              const SizedBox(height: 16),

                              // Answer field
                              Directionality(
                                textDirection: selectedLanguage == 'ar'
                                    ? TextDirection.rtl
                                    : TextDirection.ltr,
                                child: Theme(
                                  data: Theme.of(context).copyWith(
                                    textSelectionTheme: TextSelectionThemeData(
                                      cursorColor: Color(0xFF00D47E),
                                      selectionHandleColor: Color(0xFF00D47E),
                                    ),
                                  ),
                                  child: TextField(
                                    controller: answerController,
                                    style: TextStyle(fontSize: 15),
                                    maxLines: 3,
                                    minLines: 1,
                                    textAlign: selectedLanguage == 'ar'
                                        ? TextAlign.right
                                        : TextAlign.left,
                                    decoration: InputDecoration(
                                      labelText: 'Answer',
                                      alignLabelWithHint: true,
                                      labelStyle: TextStyle(
                                          fontSize: 14, color: Color(0xFF1B9169)),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(
                                            color: Color(0xFF1B9169).withOpacity(
                                                0.3)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(
                                            color: Color(0xFF00D47E), width: 1.5),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      fillColor: Color(0xFF1B9169).withOpacity(
                                          0.05),
                                      filled: true,
                                    ),
                                  ),
                                )
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              foregroundColor: Color(0xFF1B9169),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
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

                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF00D47E),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 10),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () async {
                              try {
                                String collectionName = selectedLanguage == "fr"
                                    ? "Traffic-Laws"
                                    : "Traffic-laws-ar";
                                await FirebaseFirestore.instance.collection(
                                    collectionName).doc(id).update({
                                  'QuestionText': questionTextController.text
                                      .trim(),
                                  'Answer': answerController.text.trim(),
                                });

                                Navigator.pop(context);
                                showSuccessDialog(
                                    context, 'Question updated successfully!');
                                fetchItems(); // Refresh list after update
                              } catch (e) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(
                                      'Error updating question: $e')),
                                );
                              }
                            },
                            child: Text(
                              'Save Changes',
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

  void DeletionSuccessDialog() {
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
                  'Item deleted!',
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

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

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
              // App Bar
              Container(
                height: screenHeight * 0.12,
                alignment: Alignment.center,
                child: Text(
                  'Manage Traffic Laws',
                  style: TextStyle(
                    color: Color(0xFF1B9169),
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth * 0.04,
                  ),
                ),
              ),

              // Language Toggle
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
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
                          // FR button
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedLanguage = "fr";
                              });
                              fetchItems();
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

                          // AR button
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedLanguage = "ar";
                              });
                              fetchItems();
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

              // Tab Bar
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFF1B9169).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: EdgeInsets.symmetric(horizontal: 16),
                padding: EdgeInsets.all(4),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Color(0xFF00D47E),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent, // Removes the divider line
                  labelPadding: EdgeInsets.symmetric(horizontal: 4),
                  labelColor: Colors.white,
                  unselectedLabelColor: Color(0xFF1B9169),
                  labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  unselectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  tabs: [
                    Tab(text: 'Panels'),
                    Tab(text: 'Priorities'),
                    Tab(text: 'Questions'),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: isLoading
                    ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D47E)),
                  ),
                )
                    : items.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.sentiment_dissatisfied,
                        size: 60,
                        color: Colors.grey.shade400,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No items found',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), // Added bottom padding to prevent FAB overlap
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final itemId = item['id'];

                    // Determine item title based on category
                    String itemTitle = '';
                    if (selectedCategory == 'panels') {
                      itemTitle = item['Title'] ?? 'Panel ${index + 1}';
                    } else if (selectedCategory == 'priorities') {
                      itemTitle = item['Description'] ?? 'Priority ${index + 1}';
                    } else { // questions
                      itemTitle = item['QuestionText'] ?? 'Question ${index + 1}';
                      if (itemTitle.length > 50) {
                        itemTitle = itemTitle.substring(0, 50) + '...';
                      }
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.0),
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
                          // Item icon based on category
                          Icon(
                              selectedCategory == 'panels' ? Icons.traffic :
                              selectedCategory == 'priorities' ? Icons.priority_high_rounded :
                              Icons.question_answer,
                              color: Colors.grey[900],
                              size: 20
                          ),
                          const SizedBox(width: 10),

                          // Item title
                          Expanded(
                            child: Text(
                              itemTitle,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[900],
                              ),
                            ),
                          ),

                          // Edit button
                          buildIconCircle(
                            icon: Icons.edit_outlined,
                            color: const Color(0xFF1B9169),
                            onTap: () {
                              if (selectedCategory == 'panels') {
                                editPanelDialog(context, item);
                              } else if (selectedCategory == 'priorities') {
                                editPriorityDialog(context, item);
                              } else { // questions
                                editQuestionDialog(context, item);
                              }
                            },
                          ),

                          const SizedBox(width: 8),

                          // Delete button
                          buildIconCircle(
                            icon: Icons.delete_outlined,
                            color: Colors.orange,
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) =>
                                    AlertDialog(
                                      title: Center(
                                        child: Text(
                                          'Confirm Deletion',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      content: Text(
                                        'Are you sure you want to delete this ${selectedCategory
                                            .substring(0,
                                            selectedCategory.length - 1)}?',
                                        style: TextStyle(
                                            color: Colors.grey[800]),
                                      ),
                                      actions: [
                                        TextButton(
                                          child: const Text(
                                            'Cancel',
                                            style: TextStyle(
                                                color: Color(0xFF00D47E)),
                                          ),
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            await deleteItem(itemId);
                                            Navigator.of(context)
                                                .pop(); // Close the confirmation dialog

                                           DeletionSuccessDialog();
                                          },
                                          style: TextButton.styleFrom(
                                            backgroundColor: const Color(
                                                0xFF00D47E),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets
                                                .symmetric(
                                                horizontal: 24, vertical: 12),
                                            textStyle: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius
                                                  .circular(20),
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
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        // FAB to add new item
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Show dialog to add new item based on category
            if (selectedCategory == 'panels') {
              _showAddPanelDialog(context);
            } else if (selectedCategory == 'priorities') {
              _showAddPriorityDialog(context);
            } else { // questions
              _showAddQuestionDialog(context);
            }
          },
          backgroundColor: Color(0xFFD1FADF),
          child: Icon(Icons.add, color: Color(0xFF00D47E)),
        ),
      ),
    );
  }

  void _showAddPanelDialog(BuildContext context) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController imageUrlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            width: MediaQuery
                .of(context)
                .size
                .width * 0.85,
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add New Panel',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B9169),
                  ),
                ),
                const SizedBox(height: 20),

                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title field
                        Directionality(
                          textDirection: selectedLanguage == 'ar'
                              ? TextDirection.rtl
                              : TextDirection.ltr,
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              textSelectionTheme: TextSelectionThemeData(
                                cursorColor: Color(0xFF00D47E),

                                selectionHandleColor: Color(0xFF00D47E),
                              ),
                            ),
                            child:TextField(
                              cursorColor: Color(0xFF00D47E),
                              controller: titleController,
                              style: TextStyle(fontSize: 15),
                              textAlign: selectedLanguage == 'ar' ? TextAlign
                                  .right : TextAlign.left,
                              decoration: InputDecoration(
                                labelText: 'Panel Title',
                                alignLabelWithHint: true,
                                labelStyle: TextStyle(
                                    fontSize: 14, color: Color(0xFF1B9169)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                      color: Color(0xFF1B9169).withOpacity(0.3)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                      color: Color(0xFF00D47E), width: 1.5),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                fillColor: Color(0xFF1B9169).withOpacity(0.05),
                                filled: true,
                              ),
                            ),
                          )
                        ),

                        const SizedBox(height: 16),

                        // Image URL field
                        Directionality(
                          textDirection: selectedLanguage == 'ar'
                              ? TextDirection.rtl
                              : TextDirection.ltr,
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              textSelectionTheme: TextSelectionThemeData(
                                cursorColor: Color(0xFF00D47E),

                                selectionHandleColor: Color(0xFF00D47E),
                              ),
                            ),
                            child:TextField(
                              cursorColor: Color(0xFF00D47E),
                              controller: imageUrlController,
                              style: TextStyle(fontSize: 15),
                              textAlign: selectedLanguage == 'ar' ? TextAlign
                                  .right : TextAlign.left,
                              decoration: InputDecoration(
                                labelText: 'Image URL (Asset Path)',
                                alignLabelWithHint: true,
                                labelStyle: TextStyle(
                                    fontSize: 14, color: Color(0xFF1B9169)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                      color: Color(0xFF1B9169).withOpacity(0.3)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                      color: Color(0xFF00D47E), width: 1.5),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                fillColor: Color(0xFF1B9169).withOpacity(0.05),
                                filled: true,
                                prefixIcon: selectedLanguage != 'ar' ? Icon(
                                    Icons.image_outlined,
                                    color: Color(0xFF1B9169), size: 20) : null,
                                suffixIcon: selectedLanguage == 'ar' ? Icon(
                                    Icons.image_outlined,
                                    color: Color(0xFF1B9169), size: 20) : null,
                              ),
                            ),
                          )
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Color(0xFF1B9169),
                        padding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
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

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF00D47E),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                            horizontal: 24, vertical: 10),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        if (titleController.text
                            .trim()
                            .isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Please enter a title')),
                          );
                          return;
                        }

                        try {
                          String collectionName = selectedLanguage == "fr"
                              ? "Traffic-Laws"
                              : "Traffic-laws-ar";

                          // Find the latest panel ID to create a new one with the next number
                          QuerySnapshot panelDocs = await FirebaseFirestore
                              .instance
                              .collection(collectionName)
                              .where('Category', isEqualTo: 'panels')
                              .get();

                          int nextNumber = 0;
                          for (var doc in panelDocs.docs) {
                            String docId = doc.id;
                            if (docId.startsWith('panel')) {
                              int idNumber = int.tryParse(docId.substring(5)) ??
                                  0;
                              if (idNumber >= nextNumber) {
                                nextNumber = idNumber + 1;
                              }
                            }
                          }

                          // Format new ID with leading zeros
                          String newId = 'panel${nextNumber.toString().padLeft(
                              3, '0')}';

                          // Add new panel document
                          await FirebaseFirestore.instance.collection(
                              collectionName).doc(newId).set({
                            'Title': titleController.text.trim(),
                            'ImageURL': imageUrlController.text.trim(),
                            'Category': 'panels',
                          });

                          Navigator.pop(context);
                          showSuccessDialog(
                              context, 'Panel added successfully!');
                          fetchItems(); // Refresh list after adding
                        } catch (e) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error adding panel: $e')),
                          );
                        }
                      },
                      child: Text(
                        'Add Panel',
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
        );
      },
    );
  }

  void _showAddPriorityDialog(BuildContext context) {
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController questionController = TextEditingController();
    final TextEditingController imageUrlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            width: MediaQuery
                .of(context)
                .size
                .width * 0.85,
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add New Priority',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B9169),
                  ),
                ),
                const SizedBox(height: 20),

                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Description field
                        Directionality(
                          textDirection: selectedLanguage == 'ar'
                              ? TextDirection.rtl
                              : TextDirection.ltr,
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              textSelectionTheme: TextSelectionThemeData(
                                cursorColor: Color(0xFF00D47E),

                                selectionHandleColor: Color(0xFF00D47E),
                              ),
                            ),
                            child: TextField(
                              cursorColor: Color(0xFF00D47E),
                              controller: descriptionController,
                              style: TextStyle(fontSize: 15),
                              maxLines: 3,
                              minLines: 1,
                              textAlign: selectedLanguage == 'ar' ? TextAlign
                                  .right : TextAlign.left,
                              decoration: InputDecoration(
                                labelText: 'Description',
                                alignLabelWithHint: true,
                                labelStyle: TextStyle(
                                    fontSize: 14, color: Color(0xFF1B9169)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                      color: Color(0xFF1B9169).withOpacity(0.3)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                      color: Color(0xFF00D47E), width: 1.5),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                fillColor: Color(0xFF1B9169).withOpacity(0.05),
                                filled: true,
                              ),
                            ),
                          )
                        ),

                        const SizedBox(height: 16),

                        // Question field
                        Directionality(
                          textDirection: selectedLanguage == 'ar'
                              ? TextDirection.rtl
                              : TextDirection.ltr,
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              textSelectionTheme: TextSelectionThemeData(
                                cursorColor: Color(0xFF00D47E),

                                selectionHandleColor: Color(0xFF00D47E),
                              ),
                            ),
                            child: TextField(
                              cursorColor: Color(0xFF00D47E),
                              controller: questionController,
                              style: TextStyle(fontSize: 15),
                              maxLines: 2,
                              minLines: 1,
                              textAlign: selectedLanguage == 'ar' ? TextAlign
                                  .right : TextAlign.left,
                              decoration: InputDecoration(
                                labelText: 'Question',
                                alignLabelWithHint: true,
                                labelStyle: TextStyle(
                                    fontSize: 14, color: Color(0xFF1B9169)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                      color: Color(0xFF1B9169).withOpacity(0.3)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                      color: Color(0xFF00D47E), width: 1.5),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                fillColor: Color(0xFF1B9169).withOpacity(0.05),
                                filled: true,
                              ),
                            ),
                          )
                        ),

                        const SizedBox(height: 16),

                        // Image URL field
                        Directionality(
                          textDirection: selectedLanguage == 'ar'
                              ? TextDirection.rtl
                              : TextDirection.ltr,
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              textSelectionTheme: TextSelectionThemeData(
                                cursorColor: Color(0xFF00D47E),

                                selectionHandleColor: Color(0xFF00D47E),
                              ),
                            ),
                            child: TextField(
                              cursorColor: Color(0xFF00D47E),
                              controller: imageUrlController,
                              style: TextStyle(fontSize: 15),
                              textAlign: selectedLanguage == 'ar' ? TextAlign
                                  .right : TextAlign.left,
                              decoration: InputDecoration(
                                labelText: 'Image URL',
                                alignLabelWithHint: true,
                                labelStyle: TextStyle(
                                    fontSize: 14, color: Color(0xFF1B9169)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                      color: Color(0xFF1B9169).withOpacity(0.3)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                      color: Color(0xFF00D47E), width: 1.5),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                fillColor: Color(0xFF1B9169).withOpacity(0.05),
                                filled: true,
                                prefixIcon: selectedLanguage != 'ar' ? Icon(
                                    Icons.image_outlined,
                                    color: Color(0xFF1B9169), size: 20) : null,
                                suffixIcon: selectedLanguage == 'ar' ? Icon(
                                    Icons.image_outlined,
                                    color: Color(0xFF1B9169), size: 20) : null,
                              ),
                            ),
                          )
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Color(0xFF1B9169),
                        padding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
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

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF00D47E),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                            horizontal: 24, vertical: 10),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        if (descriptionController.text
                            .trim()
                            .isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Please enter a description')),
                          );
                          return;
                        }

                        try {
                          String collectionName = selectedLanguage == "fr"
                              ? "Traffic-Laws"
                              : "Traffic-laws-ar";

                          // Find the latest priority ID
                          QuerySnapshot priorityDocs = await FirebaseFirestore
                              .instance
                              .collection(collectionName)
                              .where('Category', isEqualTo: 'priorities')
                              .get();

                          int nextNumber = 0;
                          for (var doc in priorityDocs.docs) {
                            String docId = doc.id;
                            if (docId.startsWith('prio')) {
                              int idNumber = int.tryParse(docId.substring(4)) ??
                                  0;
                              if (idNumber >= nextNumber) {
                                nextNumber = idNumber + 1;
                              }
                            }
                          }

                          // Format new ID with leading zeros
                          String newId = 'prio${nextNumber.toString().padLeft(
                              3, '0')}';

                          // Add new priority document
                          await FirebaseFirestore.instance.collection(
                              collectionName).doc(newId).set({
                            'Description': descriptionController.text.trim(),
                            'Question': questionController.text.trim(),
                            'ImageURL': imageUrlController.text.trim(),
                            'Category': 'priorities',
                          });

                          Navigator.pop(context);
                          showSuccessDialog(
                              context, 'Priority added successfully!');
                          fetchItems(); // Refresh list after adding
                        } catch (e) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Error adding priority: $e')),
                          );
                        }
                      },
                      child: Text(
                        'Add Priority',
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
        );
      },
    );
  }
  void _showAddQuestionDialog(BuildContext context) {
    final TextEditingController questionTextController = TextEditingController();
    final TextEditingController answerController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add New Question',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B9169),
                  ),
                ),
                const SizedBox(height: 20),

                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Question text field
                        Directionality(
                          textDirection: selectedLanguage == 'ar' ? TextDirection.rtl : TextDirection.ltr,
                          child: TextField(
                            cursorColor: Color(0xFF00D47E),
                            controller: questionTextController,
                            style: TextStyle(fontSize: 15),
                            maxLines: 3,
                            minLines: 1,
                            textAlign: selectedLanguage == 'ar' ? TextAlign.right : TextAlign.left,
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

                        const SizedBox(height: 16),

                        // Answer field
                        Directionality(
                          textDirection: selectedLanguage == 'ar' ? TextDirection.rtl : TextDirection.ltr,
                          child:Theme(
                            data: Theme.of(context).copyWith(
                              textSelectionTheme: TextSelectionThemeData(
                                cursorColor: Color(0xFF00D47E),

                                selectionHandleColor: Color(0xFF00D47E),
                              ),
                            ),
                            child:  TextField(
                              cursorColor: Color(0xFF00D47E),
                              controller: answerController,
                              style: TextStyle(fontSize: 15),
                              maxLines: 3,
                              minLines: 1,
                              textAlign: selectedLanguage == 'ar' ? TextAlign.right : TextAlign.left,
                              decoration: InputDecoration(
                                labelText: 'Answer',
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
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
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
                        // Validate inputs
                        if (questionTextController.text.trim().isEmpty ||
                            answerController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Please fill in all fields')),
                          );
                          return;
                        }

                        try {
                          // Determine collection based on selected language
                          String collectionName = selectedLanguage == "fr"
                              ? "Traffic-Laws"
                              : "Traffic-laws-ar";

                          // Create new document with auto-generated ID
                          DocumentReference docRef = await FirebaseFirestore.instance
                              .collection(collectionName)
                              .add({
                            'QuestionText': questionTextController.text.trim(),
                            'Answer': answerController.text.trim(),
                            'Category': 'question', // Assuming you need a type field
                          });

                          Navigator.pop(context);
                          showSuccessDialog(context, 'Question added successfully!');
                          fetchItems(); // Refresh list after adding
                        } catch (e) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error adding question: $e')),
                          );
                        }
                      },
                      child: Text(
                        'Add question',
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
        );
      },
    );
  }
}