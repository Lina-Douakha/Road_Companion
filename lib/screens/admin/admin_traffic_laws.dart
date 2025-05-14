import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:easy_localization/easy_localization.dart';

class TrafficLawsManager extends StatefulWidget {
  @override
  _TrafficLawsManagerState createState() => _TrafficLawsManagerState();
}

class _TrafficLawsManagerState extends State<TrafficLawsManager> with SingleTickerProviderStateMixin {
  String selectedLanguage = "fr";
  String selectedCategory = "panels";
  List<Map<String, dynamic>> items = [];
  bool isLoading = true;
  late TabController _tabController;
  Map<String, Set<String>> modifiedQuestions = {};
  Set<String> pendingModifications = {};
  Map<String, Map<String, Map<String, dynamic>>> pendingPanelChanges = {};
  Map<String, Map<String, Map<String, dynamic>>> pendingChanges = {};

  Map<String, Map<String, Map<String, dynamic>>> pendingQuestionChanges = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {

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
    modifiedQuestions.clear();
    pendingModifications.clear();
    super.dispose();
  }


  Future<Map<String, dynamic>> fetchPanelData(String id, String languageCode) async {
    String collection = languageCode == 'ar'
        ? 'Traffic-laws-ar'
        : languageCode == 'fr'
        ? 'Traffic-Laws'
        : 'Traffic-laws-en';
    final doc = await FirebaseFirestore.instance.collection(collection).doc(id).get();
    return doc.data() ?? {};
  }


  Future<void> fetchItems() async {
    setState(() {
      isLoading = true;
    });

    try {
      String collectionName = selectedLanguage == "fr"
          ? "Traffic-Laws"
          : selectedLanguage == "ar"
          ? "Traffic-laws-ar"
          : "Traffic-laws-en";


      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection(collectionName)
          .where('Category', isEqualTo: selectedCategory)
          .get();

      List<Map<String, dynamic>> loadedItems = [];
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
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

  Future<void> editPanelDialog(BuildContext context, Map<String, dynamic> itemData) async {
    final String id = itemData['id'];
    final String languageCode = selectedLanguage;

    Map<String, Map<String, String>> languageMappings = {
      'ar': {'code': 'ar', 'name': tr("admin.arabicLanguage")},
      'fr': {'code': 'fr', 'name': tr("admin.frenchLanguage")},
      'en': {'code': 'en', 'name': tr("admin.englishLanguage")},
    };

    List<Map<String, String>> otherLanguages = [];
    if (languageCode == 'ar') {
      otherLanguages.add({'code': 'fr', 'name': tr("admin.frenchLanguage")});
      otherLanguages.add({'code': 'en', 'name':  tr("admin.englishLanguage")});
    } else if (languageCode == 'fr') {
      otherLanguages.add({'code': 'ar', 'name': tr("admin.arabicLanguage")});
      otherLanguages.add({'code': 'en', 'name':  tr("admin.englishLanguage")});
    } else if (languageCode == 'en') {
      otherLanguages.add({'code': 'ar', 'name': tr("admin.arabicLanguage")});
      otherLanguages.add({'code': 'fr', 'name': tr("admin.frenchLanguage")});
    }

    final bool hasPendingChanges = pendingPanelChanges.containsKey(id) &&
        pendingPanelChanges[id]!.containsKey(languageCode);

    Map<String, dynamic> data;
    if (hasPendingChanges) {
      data = pendingPanelChanges[id]![languageCode]!;
    } else {
      data = await fetchPanelData(id, languageCode);
    }

    if (data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr("admin.panelNotFound"))),
      );
      return;
    }

    final TextEditingController titleController = TextEditingController(text: data['Title'] ?? '');
    final TextEditingController imageUrlController = TextEditingController(text: data['ImageUrl'] ?? '');

    bool hasAllOtherLanguageChanges = true;
    for (var otherLang in otherLanguages) {
      bool hasThisLanguageChanges = pendingPanelChanges.containsKey(id) &&
          pendingPanelChanges[id]!.containsKey(otherLang['code']);
      if (!hasThisLanguageChanges) {
        hasAllOtherLanguageChanges = false;
        break;
      }
    }

    final String imageAssetPath = 'assets/images/Panels/${data['ImageUrl'] ?? ''}';

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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tr("admin.editPanel"),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B9169),
                        ),
                      ),
                      // Language indicator
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
                  const SizedBox(height: 8),

                  if (pendingPanelChanges.containsKey(id))
                    Container(
                      padding: EdgeInsets.all(10),
                      margin: EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: hasAllOtherLanguageChanges
                            ? Color(0xFF00D47E).withOpacity(0.2)
                            : Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: hasAllOtherLanguageChanges
                                ? Color(0xFF00D47E).withOpacity(0.5)
                                : Colors.amber.withOpacity(0.5)
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                              hasAllOtherLanguageChanges
                                  ? Icons.check_circle_outline
                                  : Icons.warning_amber_rounded,
                              color: hasAllOtherLanguageChanges
                                  ? Color(0xFF00D47E)
                                  : Colors.amber[700],
                              size: 18
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              hasAllOtherLanguageChanges
                                  ? tr("admin.allVersionsModified")
                                  : tr("admin.editAllPanels"),
                              style: TextStyle(
                                fontSize: 12,
                                color: hasAllOtherLanguageChanges
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
                              controller: titleController,
                              style: TextStyle(fontSize: 15),
                              textAlign: languageCode == 'ar' ? TextAlign.right : TextAlign.left,
                              decoration: InputDecoration(
                                labelText: tr("admin.panelTitle"),
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
                              controller: imageUrlController,
                              style: TextStyle(fontSize: 15),
                              decoration: InputDecoration(
                                labelText:tr("admin.imageUrl"),
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

                          if (data['ImageUrl'] != null && data['ImageUrl'].toString().isNotEmpty)
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
                                      tr("admin.imagePreview"),
                                      style: TextStyle(
                                        color: Color(0xFF1B9169),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),

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
                                              tr("admin.imageNotFound", namedArgs: {
                                                "imageAssetPath": imageAssetPath,
                                              }),
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
                          tr("admin.cancel"),
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
                          // Prepare updated data
                          final updatedData = {
                            'Title': titleController.text.trim(),
                            'ImageUrl': imageUrlController.text.trim(),
                            // Make sure to preserve the Category field
                            'Category': data['Category']
                          };

                          bool hasChanges = false;
                          if (data['Title'] != updatedData['Title'] ||
                              data['ImageUrl'] != updatedData['ImageUrl']) {
                            hasChanges = true;
                          }

                          if (hasChanges) {
                            if (!pendingPanelChanges.containsKey(id)) {
                              pendingPanelChanges[id] = {};
                            }
                            pendingPanelChanges[id]![languageCode] = updatedData;

                            // Check if all required languages have changes
                            bool readyToSave = pendingPanelChanges[id]!.containsKey('ar') &&
                                pendingPanelChanges[id]!.containsKey('fr') &&
                                pendingPanelChanges[id]!.containsKey('en');

                            if (readyToSave) {
                              try {
                                final batch = FirebaseFirestore.instance.batch();

                                // Update French version
                                final frDocRef = FirebaseFirestore.instance
                                    .collection('Traffic-Laws')
                                    .doc(id);
                                batch.update(frDocRef, pendingPanelChanges[id]!['fr']!);

                                // Update Arabic version
                                final arDocRef = FirebaseFirestore.instance
                                    .collection('Traffic-laws-ar')
                                    .doc(id);
                                batch.update(arDocRef, pendingPanelChanges[id]!['ar']!);

                                // Update English version
                                final enDocRef = FirebaseFirestore.instance
                                    .collection('Traffic-laws-en')
                                    .doc(id);
                                batch.update(enDocRef, pendingPanelChanges[id]!['en']!);

                                await batch.commit();

                                pendingPanelChanges.remove(id);

                                Navigator.pop(context);
                                showSuccessDialog(context, tr("admin.allVersionsUpdated"));
                                fetchItems();
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(tr("admin.errorUpdating", namedArgs: {
                                      "error": e.toString(),
                                    })),
                                    backgroundColor: Colors.red,
                                  ),
                                );

                                return;
                              }
                            } else {
                              this.setState(() {});
                              Navigator.pop(context);

                              // Create a list of missing languages
                              List<String> missingLanguages = [];
                              if (!pendingPanelChanges[id]!.containsKey('ar')) missingLanguages.add('admin.arabicLanguage'.tr());
                              if (!pendingPanelChanges[id]!.containsKey('fr')) missingLanguages.add('admin.frenchLanguage'.tr());
                              if (!pendingPanelChanges[id]!.containsKey('en')) missingLanguages.add('admin.englishLanguage'.tr());

                              String missingLanguagesText = missingLanguages.join(' | ');

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      tr("admin.changesSaved", namedArgs: {
                                        "missingLanguages": missingLanguagesText,
                                        "versionsLabel": missingLanguages.length > 1 ?
                                        tr("admin.versions") :
                                        tr("admin.version")
                                      }),
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
                          hasAllOtherLanguageChanges ?  tr("admin.saveAllVersions") : tr("admin.saveChanges"),
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
    final String id = itemData['id'];
    final String languageCode = selectedLanguage;

    Map<String, Map<String, String>> languageMappings = {
      'ar': {'code': 'ar', 'name': tr("admin.arabicLanguage")},
      'fr': {'code': 'fr', 'name': tr("admin.frenchLanguage")},
      'en': {'code': 'en', 'name': tr("admin.englishLanguage")},
    };

    List<Map<String, String>> otherLanguages = [];
    if (languageCode == 'ar') {
      otherLanguages.add({'code': 'fr', 'name':  tr("admin.frenchLanguage")});
      otherLanguages.add({'code': 'en', 'name':  tr("admin.englishLanguage")});
    } else if (languageCode == 'fr') {
      otherLanguages.add({'code': 'ar', 'name': tr("admin.arabicLanguage")});
      otherLanguages.add({'code': 'en', 'name':  tr("admin.englishLanguage")});
    } else if (languageCode == 'en') {
      otherLanguages.add({'code': 'ar', 'name': tr("admin.arabicLanguage")});
      otherLanguages.add({'code': 'fr', 'name':  tr("admin.frenchLanguage")});
    }

    final bool hasPendingChanges = pendingChanges.containsKey(id) &&
        pendingChanges[id]!.containsKey(languageCode);

    Map<String, dynamic> data;
    if (hasPendingChanges) {
      data = pendingChanges[id]![languageCode]!;
    } else {
      data = itemData;
    }

    final TextEditingController descriptionController = TextEditingController(text: data['Description'] ?? '');
    final TextEditingController questionController = TextEditingController(text: data['Question'] ?? '');
    final TextEditingController imageUrlController = TextEditingController(text: data['imageURL'] ?? '');

    bool hasAllOtherLanguageChanges = true;
    for (var otherLang in otherLanguages) {
      bool hasThisLanguageChanges = pendingChanges.containsKey(id) &&
          pendingChanges[id]!.containsKey(otherLang['code']);
      if (!hasThisLanguageChanges) {
        hasAllOtherLanguageChanges = false;
        break;
      }
    }

    final String imageAssetPath = 'assets/images/priorities/${data['imageURL'] ?? ''}';

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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                  tr("admin.editPriority"),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B9169),
                        ),
                      ),
                      // Language indicator
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
                  const SizedBox(height: 8),

                  if (pendingChanges.containsKey(id))
                    Container(
                      padding: EdgeInsets.all(10),
                      margin: EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: hasAllOtherLanguageChanges
                            ? Color(0xFF00D47E).withOpacity(0.2)
                            : Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: hasAllOtherLanguageChanges
                                ? Color(0xFF00D47E).withOpacity(0.5)
                                : Colors.amber.withOpacity(0.5)
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                              hasAllOtherLanguageChanges
                                  ? Icons.check_circle_outline
                                  : Icons.warning_amber_rounded,
                              color: hasAllOtherLanguageChanges
                                  ? Color(0xFF00D47E)
                                  : Colors.amber[700],
                              size: 18
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              hasAllOtherLanguageChanges
                                  ?tr("admin.allVersionsModified")
                                  : tr("admin.editAllPriorities"),
                              style: TextStyle(
                                fontSize: 12,
                                color: hasAllOtherLanguageChanges
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
                              controller: descriptionController,
                              style: TextStyle(fontSize: 15),
                              maxLines: 3,
                              minLines: 1,
                              textAlign: languageCode == 'ar' ? TextAlign.right : TextAlign.left,
                              decoration: InputDecoration(
                                labelText: tr("admin.description"),
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
                              maxLines: 2,
                              minLines: 1,
                              textAlign: languageCode == 'ar' ? TextAlign.right : TextAlign.left,
                              decoration: InputDecoration(
                                labelText: tr("admin.question"),
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
                              controller: imageUrlController,
                              style: TextStyle(fontSize: 15),
                              decoration: InputDecoration(
                                labelText:tr("admin.imageUrl"),
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

                          if (data['imageURL'] != null && data['imageURL'].toString().isNotEmpty)
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
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Text(
                                      tr("admin.imagePreview"),
                                      style: TextStyle(
                                        color: Color(0xFF1B9169),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),

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
                                              tr("admin.imageNotFound", namedArgs: {
                                                "imageAssetPath": imageAssetPath,
                                              }),
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
                          tr("admin.cancel"),
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
                          final updatedData = {
                            'Description': descriptionController.text.trim(),
                            'Question': questionController.text.trim(),
                            'imageURL': imageUrlController.text.trim(),
                            'Category': data['Category']
                          };

                          bool hasChanges = false;
                          if (data['Description'] != updatedData['Description'] ||
                              data['Question'] != updatedData['Question'] ||
                              data['imageURL'] != updatedData['imageURL']) {
                            hasChanges = true;
                          }

                          if (hasChanges) {
                            if (!pendingChanges.containsKey(id)) {
                              pendingChanges[id] = {};
                            }
                            pendingChanges[id]![languageCode] = updatedData;

                            bool readyToSave = pendingChanges[id]!.containsKey('ar') &&
                                pendingChanges[id]!.containsKey('fr') &&
                                pendingChanges[id]!.containsKey('en');

                            if (readyToSave) {
                              try {
                                final batch = FirebaseFirestore.instance.batch();

                                final frDocRef = FirebaseFirestore.instance
                                    .collection('Traffic-Laws')
                                    .doc(id);
                                batch.update(frDocRef, pendingChanges[id]!['fr']!);


                                final arDocRef = FirebaseFirestore.instance
                                    .collection('Traffic-laws-ar')
                                    .doc(id);
                                batch.update(arDocRef, pendingChanges[id]!['ar']!);

                                final enDocRef = FirebaseFirestore.instance
                                    .collection('Traffic-laws-en')
                                    .doc(id);
                                batch.update(enDocRef, pendingChanges[id]!['en']!);

                                await batch.commit();

                                pendingChanges.remove(id);

                                Navigator.pop(context);
                                showSuccessDialog(context,
                                    tr("admin.allVersionsUpdated"));
                                fetchItems();
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(tr("admin.errorUpdating", namedArgs: {
                                      "error": e.toString(),
                                    })),
                                    backgroundColor: Colors.red,
                                  ),
                                );

                                return;
                              }
                            } else {
                              this.setState(() {});
                              Navigator.pop(context);

                              List<String> missingLanguages = [];
                              if (!pendingChanges[id]!.containsKey('ar')) missingLanguages.add('admin.arabicLanguage'.tr());
                              if (!pendingChanges[id]!.containsKey('fr')) missingLanguages.add('admin.frenchLanguage'.tr());
                              if (!pendingChanges[id]!.containsKey('en')) missingLanguages.add('admin.englishLanguage'.tr());

                              String missingLanguagesText = missingLanguages.join(' | ');

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    tr("admin.changesSaved", namedArgs: {
                                      "missingLanguages": missingLanguagesText,
                                      "versionsLabel": missingLanguages.length > 1 ?
                                      tr("admin.versions") :
                                      tr("admin.version")
                                    }),
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
                          hasAllOtherLanguageChanges ? tr("admin.saveAllVersions") : tr("admin.saveChanges"),
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
  Future<void> editQuestionDialog(BuildContext context, Map<String, dynamic> itemData) async {
    final String id = itemData['id'];
    final String languageCode = selectedLanguage;

    Map<String, Map<String, String>> languageMappings = {
      'ar': {'code': 'ar', 'name':  tr("admin.arabicLanguage")},
      'fr': {'code': 'fr', 'name':  tr("admin.frenchLanguage")},
      'en': {'code': 'en', 'name':  tr("admin.englishLanguage")},
    };


    List<Map<String, String>> otherLanguages = [];
    if (languageCode == 'ar') {
      otherLanguages.add({'code': 'fr', 'name': tr("admin.frenchLanguage")});
      otherLanguages.add({'code': 'en', 'name':  tr("admin.EnglishLanguage")});
    } else if (languageCode == 'fr') {
      otherLanguages.add({'code': 'ar', 'name': tr("admin.arabicLanguage")});
      otherLanguages.add({'code': 'en', 'name':  tr("admin.englishLanguage")});
    } else if (languageCode == 'en') {
      otherLanguages.add({'code': 'ar', 'name':  tr("admin.arabicLanguage")});
      otherLanguages.add({'code': 'fr', 'name':  tr("admin.frenchLanguage")});
    }

    Map<String, dynamic> data;
    final bool hasPendingChanges = pendingQuestionChanges.containsKey(id) &&
        pendingQuestionChanges[id]!.containsKey(languageCode);

    if (hasPendingChanges) {
      data = pendingQuestionChanges[id]![languageCode]!;
    } else {
      data = itemData;
    }

    final TextEditingController questionTextController = TextEditingController(text: data['QuestionText'] ?? '');
    final TextEditingController answerController = TextEditingController(text: data['Answer'] ?? '');

    bool hasAllOtherLanguageChanges = true;
    for (var otherLang in otherLanguages) {
      bool hasThisLanguageChanges = pendingQuestionChanges.containsKey(id) &&
          pendingQuestionChanges[id]!.containsKey(otherLang['code']);
      if (!hasThisLanguageChanges) {
        hasAllOtherLanguageChanges = false;
        break;
      }
    }

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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                  tr("admin.editQuestion"),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B9169),
                        ),
                      ),
                      // Language indicator
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
                  const SizedBox(height: 8),

                  if (pendingQuestionChanges.containsKey(id))
                    Container(
                      padding: EdgeInsets.all(10),
                      margin: EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: hasAllOtherLanguageChanges
                            ? Color(0xFF00D47E).withOpacity(0.2)
                            : Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: hasAllOtherLanguageChanges
                                ? Color(0xFF00D47E).withOpacity(0.5)
                                : Colors.amber.withOpacity(0.5)
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                              hasAllOtherLanguageChanges
                                  ? Icons.check_circle_outline
                                  : Icons.warning_amber_rounded,
                              color: hasAllOtherLanguageChanges
                                  ? Color(0xFF00D47E)
                                  : Colors.amber[700],
                              size: 18
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              hasAllOtherLanguageChanges
                                  ?tr("admin.allVersionsModified")
                                  : tr("admin.editAllLanguages"),
                              style: TextStyle(
                                fontSize: 12,
                                color: hasAllOtherLanguageChanges
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
                            child:TextField(
                              cursorColor: Color(0xFF00D47E),
                              controller: questionTextController,
                              style: TextStyle(fontSize: 15),
                              maxLines: 3,
                              minLines: 1,
                              textAlign: languageCode == 'ar' ? TextAlign.right : TextAlign.left,
                              decoration: InputDecoration(
                                labelText: tr("admin.questionText"),
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
                              controller: answerController,
                              style: TextStyle(fontSize: 15),
                              maxLines: 3,
                              minLines: 1,
                              textAlign: languageCode == 'ar' ? TextAlign.right : TextAlign.left,
                              decoration: InputDecoration(
                                labelText:tr("admin.answer"),
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
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

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
                        tr("admin.cancel"),
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
                          final updatedData = {
                            'QuestionText': questionTextController.text.trim(),
                            'Answer': answerController.text.trim(),
                            'Category': data['Category'] ?? itemData['Category']
                          };

                          bool hasChanges = false;
                          if (data['QuestionText'] != updatedData['QuestionText'] ||
                              data['Answer'] != updatedData['Answer']) {
                            hasChanges = true;
                          }

                          if (hasChanges) {
                            if (!pendingQuestionChanges.containsKey(id)) {
                              pendingQuestionChanges[id] = {};
                            }
                            pendingQuestionChanges[id]![languageCode] = updatedData;
                            bool readyToSave = pendingQuestionChanges[id]!.containsKey('ar') &&
                                pendingQuestionChanges[id]!.containsKey('fr') &&
                                pendingQuestionChanges[id]!.containsKey('en');

                            if (readyToSave) {
                              try {
                                final batch = FirebaseFirestore.instance.batch();

                                final frDocRef = FirebaseFirestore.instance
                                    .collection('Traffic-Laws')
                                    .doc(id);
                                batch.update(frDocRef, pendingQuestionChanges[id]!['fr']!);


                                final arDocRef = FirebaseFirestore.instance
                                    .collection('Traffic-laws-ar')
                                    .doc(id);
                                batch.update(arDocRef, pendingQuestionChanges[id]!['ar']!);

                                final enDocRef = FirebaseFirestore.instance
                                    .collection('Traffic-laws-en')
                                    .doc(id);
                                batch.update(enDocRef, pendingQuestionChanges[id]!['en']!);

                                await batch.commit();

                                pendingQuestionChanges.remove(id);

                                Navigator.pop(context);
                                showSuccessDialog(context,tr("admin.allVersionsUpdated"));
                                fetchItems();
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(tr("admin.errorUpdating", namedArgs: {
                                      "error": e.toString(),
                                    })),
                                    backgroundColor: Colors.red,
                                  ),
                                );

                                return;
                              }
                            } else {
                              this.setState(() {});
                              Navigator.pop(context);

                              List<String> missingLanguages = [];
                              if (!pendingQuestionChanges[id]!.containsKey('ar')) missingLanguages.add('admin.arabicLanguage'.tr());
                              if (!pendingQuestionChanges[id]!.containsKey('fr')) missingLanguages.add('admin.frenchLanguage'.tr());
                              if (!pendingQuestionChanges[id]!.containsKey('en')) missingLanguages.add('admin.englishLanguage'.tr());

                              String missingLanguagesText = missingLanguages.join(' | ');

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    tr("admin.changesSaved", namedArgs: {
                                      "missingLanguages": missingLanguagesText,
                                      "versionsLabel": missingLanguages.length > 1 ?
                                      tr("admin.versions") :
                                      tr("admin.version")
                                    }),
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
                          hasAllOtherLanguageChanges ? tr("admin.saveAllVersions") : tr("admin.saveChanges"),
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
                    tr("admin.manageTrafficLaws"),
                  style: TextStyle(
                    color: Color(0xFF1B9169),
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth * 0.04,
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 200,
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
                                fetchItems();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: selectedLanguage == "fr" ? Color(0xFF00D47E) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "FR",
                                style: TextStyle(
                                  color: selectedLanguage == "fr" ? Colors.white : Color(0xFF1B9169),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedLanguage = "en";
                                fetchItems();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: selectedLanguage == "en" ? Color(0xFF00D47E) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "EN",
                                style: TextStyle(
                                  color: selectedLanguage == "en" ? Colors.white : Color(0xFF1B9169),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedLanguage = "ar";
                                fetchItems();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: selectedLanguage == "ar" ? Color(0xFF00D47E) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "AR",
                                style: TextStyle(
                                  color: selectedLanguage == "ar" ? Colors.white : Color(0xFF1B9169),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
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
                  dividerColor: Colors.transparent,
                  labelPadding: EdgeInsets.symmetric(horizontal: 4),
                  labelColor: Colors.white,
                  unselectedLabelColor: Color(0xFF1B9169),
                  labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  unselectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  tabs: [
                    Tab(text: tr("admin.tabPanels")),
                    Tab(text: tr("admin.tabPriorities")),
                    Tab(text: tr("admin.tabQuestions"))
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
                        tr("admin.noItemsFound"),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
                :

                ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final itemId = item['id'];


                    final bool hasPendingChanges = selectedCategory == 'panels'
                        ? pendingPanelChanges.containsKey(itemId)
                        : selectedCategory == 'question'
                        ? pendingQuestionChanges.containsKey(itemId)
                        : pendingChanges.containsKey(itemId);

                    final String pendingLanguages = hasPendingChanges
                        ? (selectedCategory == 'panels'
                        ? pendingPanelChanges[itemId]!.keys.toList().map((lang) => lang.toString().toUpperCase()).join(' / ')
                        : selectedCategory == 'question'
                        ? pendingQuestionChanges[itemId]!.keys.toList().map((lang) => lang.toString().toUpperCase()).join(' / ')
                        : pendingChanges[itemId]!.keys.toList().map((lang) => lang.toString().toUpperCase()).join(' / '))
                        : '';

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

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
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
                                hasPendingChanges ? Icons.warning_amber_rounded :
                                selectedCategory == 'panels' ? Icons.traffic :
                                selectedCategory == 'priorities' ? Icons.priority_high_rounded :
                                Icons.question_answer_outlined,  // Using help_outline to match SliverList exactly
                                color: hasPendingChanges ? Colors.amber[700] : Colors.grey[900],
                                size: 20
                            ),
                            const SizedBox(width: 10),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    itemTitle,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[900],
                                    ),
                                  ),

                                  if (hasPendingChanges)
                                    Text(
                                      tr("admin.modifiedIn", namedArgs: {
                                        "languages": pendingLanguages,
                                      }),
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
                                if (selectedCategory == 'panels') {
                                  editPanelDialog(context, item);
                                } else if (selectedCategory == 'priorities') {
                                  editPriorityDialog(context, item);
                                } else  if (selectedCategory == 'question') { // questions
                                  // Use the same parameters as in SliverList
                                  editQuestionDialog(context, item);
                                }
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
                                        tr("admin.confirmDeletion"),
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    content: Text(
                                        tr("admin.confirmDeleteItem"),
                                      style: TextStyle(color: Colors.grey[800]),
                                    ),
                                    actions: [
                                      TextButton(
                                        child:  Text(
                                          tr("admin.cancel"),
                                          style: TextStyle(color: Color(0xFF00D47E)),
                                        ),
                                        onPressed: () => Navigator.of(context).pop(),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          Navigator.of(context).pop();

                                          if (selectedCategory == 'questions') {
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
                                                         Text(
                                                          tr("admin.questionDeleted"),
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
                                          } else {

                                            await deleteItem(itemId);
                                            DeletionSuccessDialog();
                                          }
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
                                        child: Text(tr("admin.confirm")),
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
                )
              ),
            ],
          ),
        ),

        floatingActionButton: FloatingActionButton(
          onPressed: () {

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
                  tr("admin.addNewPanel"),
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
                          Theme(
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
                                labelText: tr("admin.panelTitle"),
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
                          ),

                        const SizedBox(height: 16),

                         Theme(
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
                                labelText: tr("admin.imageUrl"),
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
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

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
                        tr("admin.cancel"),
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
                            SnackBar(
                              content: Text(
                                tr("admin.pleaseEnterTitle"),
                                style: TextStyle(
                                  color: Colors.orange[700], // Dark red text
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              backgroundColor: Colors.orange[50], // Light red background
                              behavior: SnackBarBehavior.floating,
                              elevation: 2,
                            ),
                          );

                          return;
                        }

                        try {
                          String collectionName = selectedLanguage == "fr"
                              ? "Traffic-Laws"
                              : "Traffic-laws-ar";

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

                          String newId = 'panel${nextNumber.toString().padLeft(
                              3, '0')}';

                          await FirebaseFirestore.instance.collection(
                              collectionName).doc(newId).set({
                            'Title': titleController.text.trim(),
                            'ImageURL': imageUrlController.text.trim(),
                            'Category': 'panels',
                          });

                          Navigator.pop(context);
                          showSuccessDialog(
                              context, tr("admin.panelAddedSuccess"));
                          fetchItems(); // Refresh list after adding
                        } catch (e) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                tr("admin.errorAddingPanel"),
                                style: TextStyle(
                                  color: Colors.red[700], // Dark red text
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              backgroundColor: Colors.red[50], // Light red background
                              behavior: SnackBarBehavior.floating,
                              elevation: 2,
                            ),
                          );


                        }
                      },

                      child: Text(tr("admin.addPanel")
                        ,
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
                  tr("admin.addNewPriority"),
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

                       Theme(
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
                                labelText: tr("admin.description"),
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

                        ),

                        const SizedBox(height: 16),

                        // Question field

                           Theme(
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
                                labelText: tr("admin.addquestion"),
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

                        ),

                        const SizedBox(height: 16),

                        // Image URL field
                       Theme(
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
                                labelText: tr("admin.imageUrl"),
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

                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

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
                        tr("admin.cancel"),
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
                              content: Text(
                                tr("admin.pleaseEnterDescription"),
                                style: TextStyle(
                                  color: Colors.orange[700], // Dark red text
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              backgroundColor: Colors.orange[50], // Light red background
                              behavior: SnackBarBehavior.floating,
                              elevation: 2,
                            ),
                          );

                          return;
                        }

                        try {
                          String collectionName = selectedLanguage == "fr"
                              ? "Traffic-Laws"
                              : "Traffic-laws-ar";

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

                          String newId = 'prio${nextNumber.toString().padLeft(
                              3, '0')}';

                          await FirebaseFirestore.instance.collection(
                              collectionName).doc(newId).set({
                            'Description': descriptionController.text.trim(),
                            'Question': questionController.text.trim(),
                            'ImageURL': imageUrlController.text.trim(),
                            'Category': 'priorities',
                          });

                          Navigator.pop(context);
                          showSuccessDialog(
                              context, tr("admin.priorityAddedSuccess"));
                          fetchItems(); // Refresh list after adding
                        } catch (e) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                tr("admin.errorAddingPriority"),
                                style: TextStyle(
                                  color: Colors.red[700], // Dark red text
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              backgroundColor: Colors.red[50], // Light red background
                              behavior: SnackBarBehavior.floating,
                              elevation: 2,
                            ),
                          );

                        }
                      },
                      child: Text(
                        tr("admin.addPriority"),
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
                  tr("admin.addNewQuestion"),
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
                       TextField(
                            cursorColor: Color(0xFF00D47E),
                            controller: questionTextController,
                            style: TextStyle(fontSize: 15),
                            maxLines: 3,
                            minLines: 1,
                            textAlign: selectedLanguage == 'ar' ? TextAlign.right : TextAlign.left,
                            decoration: InputDecoration(
                              labelText: tr("admin.questionText"),
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

                        const SizedBox(height: 16),

                        Theme(
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
                                labelText: tr("admin.answer"),
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
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

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
                       tr("admin.cancel"),
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
                            SnackBar(
                              content: Text(
                                tr("admin.fillAllFields"),
                                style: TextStyle(
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              backgroundColor: Colors.orange[50],
                              behavior: SnackBarBehavior.floating,
                              elevation: 2,
                            ),
                          );
                          return;
                        }

                        try {

                          String collectionName = selectedLanguage == "fr"
                              ? "Traffic-Laws"
                              : "Traffic-laws-ar";


                          DocumentReference docRef = await FirebaseFirestore.instance
                              .collection(collectionName)
                              .add({
                            'QuestionText': questionTextController.text.trim(),
                            'Answer': answerController.text.trim(),
                            'Category': 'question', // Assuming you need a type field
                          });

                          Navigator.pop(context);
                          showSuccessDialog(context, tr("admin.questionAddedSuccess"),);
                          fetchItems(); // Refresh list after adding
                        } catch (e) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(tr("admin.errorAddingQuestion", namedArgs: {
                              "error": e.toString(),
                            }))),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                tr("admin.errorAddingQuestion"),
                                style: TextStyle(
                                  color: Colors.red[700], // Dark red text
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              backgroundColor: Colors.red[50], // Light red background
                              behavior: SnackBarBehavior.floating,
                              elevation: 2,
                            ),
                          );

                        }
                      },
                      child: Text(
                        tr("admin.addQuestion"),
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
  Future<void> deleteItem(String id) async {
    try {
      String collectionName1 = "Traffic-Laws";

      await FirebaseFirestore.instance.collection(collectionName1)
          .doc(id)
          .delete();
      String collectionName2 = "Traffic-laws-ar";
      await FirebaseFirestore.instance.collection(collectionName2)
          .doc(id)
          .delete();
      fetchItems();
    } catch (e) {
      print("Error deleting item: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr("admin.errorDeletingItem", namedArgs: {
          "error": e.toString(),
        }))),
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
                Text(
                  tr("admin.itemDeleted"),
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
}