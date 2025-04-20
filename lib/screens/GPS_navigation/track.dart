import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocationAutoComplete extends StatefulWidget {
  const LocationAutoComplete({super.key});

  @override
  LocationAutoCompleteState createState() => LocationAutoCompleteState();
}

class LocationAutoCompleteState extends State<LocationAutoComplete> {
  final TextEditingController _searchController = TextEditingController();
  final String token = const Uuid().v4();
  List<dynamic> listOfLocation = [];
  List<Map<String, dynamic>> searchHistory = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onChanged);
    _loadSearchHistory();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF1B9169),
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  void _onChanged() {
    if (_searchController.text.isNotEmpty) {
      placeSuggestion(_searchController.text);
    } else {
      setState(() {
        listOfLocation = [];
      });
    }
  }

  Future<void> placeSuggestion(String input) async {
    const String apiKey = "AIzaSyCcq9cNPuV2llNxo_rMg59nw-6I2t5aYOk";
    try {
      setState(() => isLoading = true);
      String baseUrl = "https://maps.googleapis.com/maps/api/place/autocomplete/json";
      String request = '$baseUrl?input=$input&key=$apiKey&sessiontoken=$token';

      final response = await http.get(Uri.parse(request));
      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          listOfLocation = data['predictions'];
        });
      } else {
        throw Exception("Failed to load suggestions");
      }
    } catch (e) {
      print("Erreur : $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _selectPlace(String placeId, [String? description]) async {
    const String apiKey = "AIzaSyCcq9cNPuV2llNxo_rMg59nw-6I2t5aYOk";
    try {
      final detailsUrl =
          "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$apiKey";
      final response = await http.get(Uri.parse(detailsUrl));
      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        final location = data['result']['geometry']['location'];
        final lat = location['lat'];
        final lng = location['lng'];

        await _addToSearchHistory(description ?? '', lat, lng);

        // Return both the location and the description
        Navigator.pop(context, {
          'location': LatLng(lat, lng),
          'name': description ?? 'Destination'
        });
      } else {
        throw Exception("Failed to load place details");
      }
    } catch (e) {
      print("Erreur : $e");
    }
  }

  Future<void> _addToSearchHistory(String name, double lat, double lng) async {
    final prefs = await SharedPreferences.getInstance();
    final newEntry = {"name": name, "lat": lat, "lng": lng};

    setState(() {
      searchHistory.removeWhere((item) => item['name'] == name);
      searchHistory.insert(0, newEntry);
      if (searchHistory.length > 5) searchHistory.removeLast();
    });

    final encoded = json.encode(searchHistory);
    prefs.setString('searchHistory', encoded);
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getString('searchHistory');
    if (history != null) {
      setState(() {
        searchHistory = List<Map<String, dynamic>>.from(json.decode(history));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 20),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      cursorColor: const Color(0xFF1B9169),
                      decoration: InputDecoration(
                        hintText: "rechercheGPS.hint_search".tr(),
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: const Color(0xFFF1F3F4),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 20.0),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            borderSide: const BorderSide(color: Color(0xFF1B9169), width: 1.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            borderSide: const BorderSide(color: Colors.grey, width: 0.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (isLoading)
              const SizedBox(
                height: 4, // the height to control the size of the progress bar
                child: LinearProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B9169)), // Set the color to green
                  backgroundColor: Color(0xFFE0E0E0), // background color: light gray
                ),
              ),

            const SizedBox(height: 10),

            // History
            if (_searchController.text.isEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.history, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      "rechercheGPS.historique_title".tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: searchHistory.length,
                itemBuilder: (context, index) {
                  final place = searchHistory[index];
                  return ListTile(
                    leading: const Icon(Icons.place_outlined),
                    title: Text(place['name']),
                    onTap: () {
                      Navigator.pop(
                          context,
                          {
                            'location': LatLng(place['lat'], place['lng']),
                            'name': place['name']
                          },
                      );
                    },
                  );
                },
              ),
            ],

            // 📍 Suggestions
            if (_searchController.text.isNotEmpty) ...[
              Expanded(
                child: ListView.builder(
                  itemCount: listOfLocation.length,
                  itemBuilder: (context, index) {
                    final suggestion = listOfLocation[index];
                    return ListTile(
                      leading: const Icon(Icons.location_on_outlined),
                      title: Text(suggestion["description"] ?? ''),
                      onTap: () {
                        final placeId = suggestion["place_id"];
                        final desc = suggestion["description"];
                        _selectPlace(placeId, desc);
                      },
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
