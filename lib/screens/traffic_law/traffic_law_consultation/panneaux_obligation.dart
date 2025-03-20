import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:road_companion/widgets/navigation_bar_widget.dart';

class PanneauxObligationScreen extends StatefulWidget {
  const PanneauxObligationScreen({super.key});

  @override
  _PanneauxObligationScreenState createState() => _PanneauxObligationScreenState();
}

class _PanneauxObligationScreenState extends State<PanneauxObligationScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> panneaux = [];
  List<Map<String, dynamic>> filteredPanneaux = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPanneaux(); // Fetch from Firestore
  }

  //Fetch "panels" with LawType "Danger"
  Future<void> _fetchPanneaux() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection("Traffic-Laws")
          .where("Category", isEqualTo: "panels")
          .where("LawType", isEqualTo: "obligation")
          .get();

      List<Map<String, dynamic>> fetchedPanneaux = querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      setState(() {
        panneaux = fetchedPanneaux;
        filteredPanneaux = fetchedPanneaux;
        isLoading = false;
      });
    } catch (e) {
      print("Erreur lors du chargement: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  // Search function
  void _filterPanneaux(String query) {
    setState(() {
      filteredPanneaux = panneaux
          .where(
            (panneau) => (panneau["Title"] ?? "")
            .toLowerCase()
            .contains(query.toLowerCase()),
      )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF1B9169),
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 70),
              Center(
                child: Text(
                  "Panneaux d'obligation",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B9169),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              //Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterPanneaux,
                  decoration: InputDecoration(
                    hintText: "Rechercher...",
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF1B9169)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Panels List
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredPanneaux.isEmpty
                    ? const Center(child: Text("Aucun panneau trouvé."))
                    : Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: filteredPanneaux.length,
                    itemBuilder: (context, index) {
                      var panneau = filteredPanneaux[index];
                      String imageName = panneau["ImageUrl"] ?? "";

                      return Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        child: ListTile(
                          leading: imageName.isNotEmpty
                              ? Image.asset(
                            "assets/images/Panels/$imageName",
                            width: 50,
                            height: 50,
                            fit: BoxFit.contain,
                          )
                              : const Icon(Icons.image_not_supported),
                          title: Text(
                            panneau["Title"] ?? "Sans titre",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        resizeToAvoidBottomInset: false,
        bottomNavigationBar: NavigationBarWidget(
          selectedIndex: 0,
          onItemTapped: (index) {
            print("Onglet sélectionné : $index");
          },
        ),
      ),
    );
  }
}