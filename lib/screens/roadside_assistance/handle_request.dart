import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:road_companion/screens/roadside_assistance/maps.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:road_companion/screens/chat.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

enum TravelMode {
  driving,
  motorcycle,
  walking
}

class HandleRequestPage extends StatefulWidget {
  @override
  _HandleRequestPageState createState() => _HandleRequestPageState();
}

Future<List<Map<String, dynamic>>> getRequestsForProvider(String providerID) async {
  try {
    print('Fetching requests for provider: $providerID');
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('Service_requests')
        .where('providerID', isEqualTo: providerID)
        .where('status', whereIn: ['pending', 'accepted'])
        .orderBy('timestamp')
        .get();

    print('Fetched ${snapshot.docs.length} requests');

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['requestId'] = doc.id; // Include the document ID
      print('Request Data: $data');
      return data;
    }).toList();
  } catch (e) {
    print('Error fetching requests: $e');
    return [];
  }
}

class _HandleRequestPageState extends State<HandleRequestPage> {
  final DraggableScrollableController _controller = DraggableScrollableController();
  String providerID = "";
  bool _accepted = false;
  Map<String, dynamic>? requestData;
  List<Map<String, dynamic>> allRequests = [];

  final ValueNotifier<int> selectedIndexNotifier = ValueNotifier<int>(0);
  final String apiKey = 'AIzaSyCcq9cNPuV2llNxo_rMg59nw-6I2t5aYOk';

  double? distanceInKm;
  Map<TravelMode, String> travelTimes = {
    TravelMode.driving: '--',
    TravelMode.motorcycle: '--',
    TravelMode.walking: '--',
  };


  LatLng? userLocation;
  LatLng? destinationLocation;

  void fetchCurrentUser() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        providerID = user.uid;
      });
    } else {
      print("No user logged in.");
    }
  }

  Future<void> fetchRequests() async {
    if (providerID.isEmpty) {
      print("Provider ID is empty, can't fetch requests");
      return;
    }

    try {
      final requests = await getRequestsForProvider(providerID);
      setState(() {
        allRequests = requests;
        if (requests.isNotEmpty) {
          requestData = requests[0]; // Use the first request
          _accepted = requestData!['status'] == 'accepted';
          // Initialize locations and routes after getting request
          _initializeLocationsAndRoutes();
        }
      });
    } catch (e) {
      print("Error fetching requests: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchCurrentUser();

    Future.delayed(Duration(milliseconds: 500), () {
      fetchRequests();
    });
  }

  Future<void> _initializeLocationsAndRoutes() async {

    try {
      print('Initializing locations and routes');
      Position position = await _determinePosition();
      print('Current position: ${position.latitude}, ${position.longitude}');

      setState(() {
        userLocation = LatLng(position.latitude, position.longitude);
      });


      if (requestData != null && requestData!['address'] != null) {
        print('Getting location from address: ${requestData!['address']}');
        try {
          List<Location> locations = await locationFromAddress(requestData!['address']);
          if (locations.isNotEmpty) {
            print('Address resolved to: ${locations.first.latitude}, ${locations.first.longitude}');

            setState(() {
              destinationLocation = LatLng(locations.first.latitude, locations.first.longitude);
            });

            await _calculateRoutes();
          } else {
            print('No locations found for the address');
          }
        } catch (geocodeError) {
          print('Error geocoding address: $geocodeError');

          if (requestData!.containsKey('lat') && requestData!.containsKey('lng')) {
            double lat = double.tryParse(requestData!['lat'].toString()) ?? 0.0;
            double lng = double.tryParse(requestData!['lng'].toString()) ?? 0.0;
            if (lat != 0.0 && lng != 0.0) {
              print('Using fallback coordinates: $lat, $lng');
              setState(() {
                destinationLocation = LatLng(lat, lng);
              });
              await _calculateRoutes();
            }
          }
        }
      }
    } catch (e) {
      print('Error initializing locations: $e');
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _calculateRoutes() async {
    if (userLocation == null || destinationLocation == null) {
      print('Cannot calculate routes: locations are not available');
      return;
    }

    try {
      print('Calculating routes between ${userLocation!.latitude},${userLocation!.longitude} and ${destinationLocation!.latitude},${destinationLocation!.longitude}');

      await _calculateRoute(TravelMode.driving, 'driving');

      await _calculateRoute(TravelMode.motorcycle, 'driving', multiplier: 1.2);

      await _calculateRoute(TravelMode.walking, 'walking');

      setState(() {});
    } catch (e) {
      print('Error calculating routes: $e');
    }
  }

  Future<void> _calculateRoute(TravelMode mode, String googleMode, {double multiplier = 1.0}) async {
    final origin = '${userLocation!.latitude},${userLocation!.longitude}';
    final destination = '${destinationLocation!.latitude},${destinationLocation!.longitude}';

    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?'
            'origin=$origin&'
            'destination=$destination&'
            'mode=$googleMode&'
            'key=$apiKey'
    );

    print('Requesting directions for $mode: $url');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Direction API response status: ${data['status']}');

        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final routes = data['routes'][0];
          final legs = routes['legs'][0];

          if (mode == TravelMode.driving) {
            setState(() {
              distanceInKm = legs['distance']['value'] / 1000.0;
              print('Distance set to: $distanceInKm km');
            });
          }

          int durationInMinutes = (legs['duration']['value'] / 60 * multiplier).round();
          setState(() {
            travelTimes[mode] = '${durationInMinutes}m';
            print('Travel time for $mode set to: ${durationInMinutes}m');
          });
        } else {
          print('Direction API error or no routes: ${data['status']}');
        }
      } else {
        print('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in _calculateRoute for $mode: $e');
    }
  }

  void _launchNavigation() async {
    if (destinationLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Destination location is not available')),
      );
      return;
    }

    String googleMapsMode;
    switch (selectedIndexNotifier.value) {
      case 0: googleMapsMode = 'driving'; break; // driving
      case 1: googleMapsMode = 'driving'; break; // motorcycle (use driving)
      case 2: googleMapsMode = 'walking'; break; // walking
      default: googleMapsMode = 'driving';
    }


    final url = 'https://www.google.com/maps/dir/?api=1'
        '&destination=${destinationLocation!.latitude},${destinationLocation!.longitude}'
        '&travelmode=$googleMapsMode';

    print('Launching navigation URL: $url');

    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      print('Navigation launch error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch navigation: $e')),
      );
    }
  }

  Widget _buildAcceptedContent() {
    if (requestData == null) return Center(child: Text("No request data"));

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(requestData!['clientID'])
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(child: Text("Client data not found"));
        }

        final clientData = snapshot.data!;
        final profilePhoto = clientData['ProfilePhoto'];
        final clientName = requestData!['clientName'];
        final clientPhone = requestData!['clientPhone'];
        final address = requestData!['address'];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: AssetImage(profilePhoto),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          clientName,
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          clientPhone,
                          style: TextStyle(color: Colors.grey[700], fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: Center(
                          child: Text(
                            'handle_request.request_description'.tr(),
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        content: requestData!['description'] == null ||
                            requestData!['description']
                                .toString()
                                .trim()
                                .isEmpty
                            ? SizedBox(
                          width: MediaQuery.of(context).size.width * 0.7,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Lottie.asset(
                                'assets/animation/emptybox.json',
                                width: 140,
                                height: 140,
                                repeat: true,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'handle_request.no_client_request_description'
                                    .tr(),
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                            : SingleChildScrollView(
                          child: Text(
                            requestData!['description'],
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ),
                        actions: [
                          Center(
                            child: TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                'handle_request.close'.tr(),
                                style: TextStyle(
                                  color: Color(0xFF00D47E),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: Icon(Icons.info_outline,
                      color: Color(0xFF00D47E), size: 18),
                  label: Text(
                    'handle_request.show_description'.tr(),
                    style: TextStyle(
                      color: Color(0xFF00D47E),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Location Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _circleIcon(Icons.radio_button_checked),
                      const SizedBox(width: 8),
                      Text(
                        'handle_request.your_location'.tr(),
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Container(
                    height: 1,
                    width: double.infinity,
                    color: Colors.grey[400],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      _circleIcon(Icons.location_on),
                      const SizedBox(width: 8),

                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Text(
                            address,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            ValueListenableBuilder<int>(
              valueListenable: selectedIndexNotifier,
              builder: (context, selectedIndex, _) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTransportOption(
                      icon: Icons.directions_car,
                      time: travelTimes[TravelMode.driving] ?? "--",
                      isSelected: selectedIndex == 0,
                      onTap: () {
                        selectedIndexNotifier.value = 0;
                      },
                    ),
                    _buildTransportOption(
                      icon: Icons.motorcycle,
                      time: travelTimes[TravelMode.motorcycle] ?? "--",
                      isSelected: selectedIndex == 1,
                      onTap: () {
                        selectedIndexNotifier.value = 1;
                      },
                    ),
                    _buildTransportOption(
                      icon: Icons.directions_walk,
                      time: travelTimes[TravelMode.walking] ?? "--",
                      isSelected: selectedIndex == 2,
                      onTap: () {
                        selectedIndexNotifier.value = 2;
                      },
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          distanceInKm != null ? distanceInKm!.toStringAsFixed(1) : "--",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                        Text(
                          "km",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.teal,
                          ),
                        ),
                      ],
                    )
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            // Go Now Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _launchNavigation,
                icon: Icon(Icons.navigation),
                label: Text('handle_request.go_now'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF00D47E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  textStyle:
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTransportOption({
    required IconData icon,
    required String time,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 250),
        width: 60,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal[900] : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? null : Border.all(color: Colors.teal),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
                icon, size: 20, color: isSelected ? Colors.white : Colors.teal),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.teal,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Stream<List<Map<String, dynamic>>> requestStream(String providerID) {
    return FirebaseFirestore.instance
        .collection('Service_requests')
        .where('providerID', isEqualTo: providerID)
        .where('status', whereIn: ['pending', 'accepted'])
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['requestId'] = doc.id; // Ensure doc.id is included
        return data;
      }).toList();
    });
  }

  Future<void> updateRequestStatus(String requestId, String status) async {
    try {
      print('Updating status for request: $requestId to $status');
      await FirebaseFirestore.instance
          .collection('Service_requests')
          .doc(requestId)
          .update({'status': status});
      print('Request status updated');
    } catch (e) {
      print('Error updating request status: $e');
    }
  }


  Future<void> saveRequestToHistory({
    required String providerID,
    required String clientID,
    required String username,
    required GeoPoint location,
    required bool status,
    required Timestamp timestamp, // client's original request time
  }) async {
    final firestore = FirebaseFirestore.instance;
    final historyRef = firestore.collection('Request_history').doc(providerID);

    try {
      print('Saving request to history for provider: $providerID');

      final snapshot = await historyRef.get();
      print('Fetched history snapshot: ${snapshot.data()}');

      // Count how many fields already exist to name the next request
      int nextIndex = 1;
      if (snapshot.exists && snapshot.data() != null) {
        nextIndex = snapshot.data()!.length + 1;
        print('Snapshot exists. Next index: $nextIndex');
      } else {
        print('No existing data found. Starting with index 1');
      }

      final newRequestKey = 'request$nextIndex';
      print('New request key: $newRequestKey');

      final newRequestData = {
        'date': timestamp,
        'location': location,
        'status': status,
        'userID': clientID,
        'username': username,
      };


      await historyRef.set(
          {newRequestKey: newRequestData}, SetOptions(merge: true));
      print('Request saved to history successfully');
    } catch (e) {
      print("❌ Failed to save request to history: $e");
    }
  }


  void _showCallDialog(String clientPhone) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(
            child: Text(
              'handle_request.client_accepted'.tr(),

              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          content: Text.rich(
            TextSpan(
              text: 'handle_request.call_prompt'.tr(),
              style: TextStyle(color: Colors.grey[800]),
              children: [
                TextSpan(
                  text: clientPhone,
                  style: TextStyle(
                    color: Color(0xFF00D47E),
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFF00D47E),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('handle_request.cancel'.tr(),
                  style: TextStyle(color: Color(0xFF00D47E))),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.phone, color: Colors.white),
              label: Text('handle_request.call'.tr(),
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF00D47E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _callClient(clientPhone);
              },
            )
          ],
        );
      },
    );
  }

  void _callClient(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch phone app')),
      );
    }
  }

  void _showRequestListSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final pendingRequests = allRequests.where((
            request) => request['status'] == 'pending').toList();
        final screenHeight = MediaQuery
            .of(context)
            .size
            .height;
        final screenWidth = MediaQuery
            .of(context)
            .size
            .width;

        return ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          child: Container(
            color: Color(0xFFF9F9F9),
            height: 350,
            child: pendingRequests.isEmpty
                ? Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Lottie.asset(
                      'assets/animation/emptybox.json',
                      width: 180,
                      height: 180,
                      repeat: true,
                    ),
                    SizedBox(height: MediaQuery
                        .of(context)
                        .size
                        .height * 0.02),
                    Text(
                      'results.no_results'.tr(),
                      style: TextStyle(
                        fontSize: MediaQuery
                            .of(context)
                            .size
                            .width * 0.045,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: MediaQuery
                        .of(context)
                        .size
                        .height * 0.008),
                    Text(
                      'handle_request.no_other'.tr(),
                      style: TextStyle(
                        fontSize: MediaQuery
                            .of(context)
                            .size
                            .width * 0.035,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey.shade500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )

                : ListView.builder(
              itemCount: pendingRequests.length,
              itemBuilder: (context, index) {
                final request = pendingRequests[index];

                String formattedDate = "";
                if (request['timestamp'] is Timestamp) {
                  DateTime date = request['timestamp'].toDate();
                  formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(date);
                }

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      requestData = request;
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.05),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    margin: EdgeInsets.fromLTRB(
                        10.0, index == 0 ? 16.0 : 4.0, 10.0, 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 34.0,
                          height: 34.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: ClipOval(
                            child: Icon(
                              Icons.person,
                              size: 24.0,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        SizedBox(width: 10.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                request['clientName'],
                                style: TextStyle(
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 2.0),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    color: Colors.grey.shade500,
                                    size: 15.0,
                                  ),
                                  SizedBox(width: 3),
                                  Expanded(
                                    child: Text(
                                      request['address'],
                                      style: TextStyle(
                                        fontSize: 13.0,
                                        color: Colors.grey.shade600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 2.0),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    color: Colors.grey.shade500,
                                    size: 15.0,
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    formattedDate,
                                    style: TextStyle(
                                      fontSize: 13.0,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 10.0),
                        Column(
                          children: [
                            TextButton(
                              onPressed: () async {
                                setState(() => _accepted = true);
                                await updateRequestStatus(
                                    requestData!['requestId'], 'accepted');
                                await saveRequestToHistory(
                                  providerID: providerID,
                                  clientID: requestData!['clientID'],
                                  username: requestData!['clientName'],
                                  location: requestData!['location'],
                                  status: true,
                                  timestamp: requestData!['timestamp'],
                                );
                                setState(() =>
                                requestData!['status'] = 'accepted');
                                Navigator.pop(context);
                                _showCallDialog(requestData!["clientPhone"]);
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: Color(0xFF00D47E).withOpacity(
                                    0.1),
                                foregroundColor: Color(0xFF00D47E),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                textStyle: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w500),
                                minimumSize: Size(60, 28),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text('handle_request.accept'.tr()),
                            ),
                            SizedBox(height: 2),
                            TextButton(
                              onPressed: () async {
                                setState(() => _accepted = false);
                                await updateRequestStatus(
                                    requestData!['requestId'], 'rejected');
                                await saveRequestToHistory(
                                  providerID: providerID,
                                  clientID: requestData!['clientID'],
                                  username: requestData!['clientName'],
                                  location: requestData!['location'],
                                  status: false,
                                  timestamp: requestData!['timestamp'],
                                );
                                setState(() {
                                  allRequests.removeWhere((r) =>
                                  r['requestId'] == requestData!['requestId']);
                                  requestData = allRequests.isNotEmpty
                                      ? allRequests.first
                                      : null;
                                });
                                Navigator.pop(context);
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.red.withOpacity(0.1),
                                foregroundColor: Colors.red,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                textStyle: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w500),
                                minimumSize: Size(60, 28),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text('handle_request.reject'.tr()),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _refreshData() async {
    fetchRequests();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    final screenHeight = MediaQuery
        .of(context)
        .size
        .height;
    final LatLng providerLocation = LatLng(36.7538, 3.0588);

    LatLng? clientLocation;
    String? clientAddress;
    if (allRequests.isNotEmpty && requestData != null &&
        requestData!["location"] != null) {
      clientLocation = LatLng(requestData!["location"].latitude,
          requestData!["location"].longitude);
      clientAddress = requestData!["clientName"];
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF1B9169),
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: Stack(
          children: [
            ServiceProviderMapPage(
              key: ValueKey(requestData?["requestId"]),
              clientLocation: clientLocation,
              clientAddress: clientAddress,
            ),

            if (allRequests.isNotEmpty)
              DraggableScrollableSheet(
                controller: _controller,
                initialChildSize: 0.48,
                minChildSize: 0.12,
                maxChildSize: 0.6,
                builder: (context, scrollController) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          offset: Offset(0, -2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Center(
                              child: Container(
                                height: 5,
                                width: 40,
                                margin: EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [

                                Material(
                                  color: Color(0xFFD6F5E7),
                                  shape: CircleBorder(),
                                  child: InkWell(
                                    customBorder: CircleBorder(),
                                    onTap: _showRequestListSheet,
                                    child: Padding(
                                      padding: EdgeInsets.all(10),
                                      child: _circleIcon(
                                          Icons.view_list_outlined),
                                    ),
                                  ),
                                ),
                                // Refresh Icon
                                Material(
                                  color: Color(0xFFD6F5E7),
                                  shape: CircleBorder(),
                                  child: InkWell(
                                    customBorder: CircleBorder(),
                                    onTap: () {
                                      onRefresh:
                                      _refreshData();
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.all(10),
                                      child: _circleIcon(Icons.refresh),
                                    ),
                                  ),
                                ),
                                // Call Icon
                                Material(
                                  color: Color(0xFFD6F5E7),
                                  shape: CircleBorder(),
                                  child: InkWell(
                                    customBorder: CircleBorder(),
                                    onTap: () {
                                      if (requestData!['status'] ==
                                          'accepted') {
                                        _showCallDialog(
                                            requestData!["clientPhone"]);
                                      }
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.all(10),
                                      child: _circleIcon(Icons.phone_outlined),
                                    ),
                                  ),
                                ),
                                Material(
                                  color: Color(0xFFD6F5E7),
                                  shape: CircleBorder(),
                                  child: InkWell(
                                    customBorder: CircleBorder(),
                                    onTap: () {
                                      if (requestData!['status'] ==
                                          'accepted') {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ChatScreen(
                                                    receiverId: requestData!['clientID']),
                                          ),
                                        );
                                      }
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.all(10),
                                      child: _circleIcon(Icons.chat),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 16),


                            requestData!['status'] == 'pending'
                                ? _buildPendingContent()
                                : _buildAcceptedContent(),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            if (allRequests.isNotEmpty && requestData!['status'] == 'accepted')
              Positioned(
                top: 115,
                left: 16,
                child: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) =>
                          AlertDialog(
                            title: Center(
                              child: Text(
                                'handle_request.service_completion'.tr(),
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            content: Text(
                              'handle_request.service_completion_confirmation'
                                  .tr(),
                              style: TextStyle(color: Colors.grey[800]),
                            ),
                            actions: [
                              TextButton(
                                child: Text(
                                  'handle_request.cancel'.tr(),
                                  style: TextStyle(color: Color(0xFF00D47E)),
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.of(context).pop();

                                  setState(() async {
                                    await updateRequestStatus(
                                        requestData!['requestId'], 'completed');
                                  });

                                  setState(() {
                                    allRequests.removeWhere((r) =>
                                    r['requestId'] ==
                                        requestData!['requestId']);
                                    requestData = allRequests.isNotEmpty
                                        ? allRequests.first
                                        : null;
                                  });
                                },
                                style: TextButton.styleFrom(
                                  backgroundColor: Color(0xFF00D47E),
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                  textStyle: TextStyle(fontSize: 14,
                                      fontWeight: FontWeight.w600),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: Text('handle_request.confirm'.tr()),
                              ),
                            ],
                          ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:  Color(0xFF00D47E),

                    foregroundColor: Colors.white,

                    elevation: 0,
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    textStyle: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),

                    ),
                  ),
                  child: Text('handle_request.finish_service'.tr(),),
                ),
              ),

            if (allRequests.isEmpty)
              Positioned(
                top: 115,
                left: 16,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.12), // light orange tint
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline, size: 18, color: Colors.orange),
                      SizedBox(width: 8),
                      Text(
                        'handle_request.no_requests_yet'.tr(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
  Widget _buildPendingContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Center(
                  child: Text(
                    'handle_request.request_description'.tr(),
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                content: requestData!['description'] == null ||
                    requestData!['description']
                        .toString()
                        .trim()
                        .isEmpty
                    ? SizedBox(
                  width: MediaQuery.of(context).size.width * 0.7,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Lottie.asset(
                        'assets/animation/emptybox.json',
                        width: 140,
                        height: 140,
                        repeat: true,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'handle_request.no_client_request_description'
                            .tr(),
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
                    : SingleChildScrollView(
                  child: Text(
                    requestData!['description'],
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
                actions: [
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'handle_request.close'.tr(),
                        style: TextStyle(
                          color: Color(0xFF00D47E),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },

          icon: Icon(Icons.info_outline,
              color: Color(0xFF00D47E), size: 18),
          label: Text(
            'handle_request.show_description'.tr(),
            style: TextStyle(
              color: Color(0xFF00D47E),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(height: 16),
        _styledInfoCard(
          Icons.person_outline,
          'handle_request.client_name'.tr(),
          "${requestData!["clientName"]}",
        ),
        const SizedBox(height: 10),
        _styledInfoCard(
          Icons.phone_outlined,
          'handle_request.phone'.tr(),
          "**********",
        ),
        const SizedBox(height: 10),
        _styledInfoCard(
          Icons.location_on_outlined,
          'handle_request.address'.tr(),
          "${requestData!["address"]}",
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Reject Button - smaller with enhanced style
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  // Haptic feedback for better UX
                  HapticFeedback.mediumImpact();

                  setState(() => _accepted = false);
                  await updateRequestStatus(
                      requestData!['requestId'],
                      'rejected'
                  );
                  await saveRequestToHistory(
                    providerID: providerID,
                    clientID: requestData!['clientID'],
                    username: requestData!['clientName'],
                    location: requestData!['location'],
                    status: false,
                    timestamp: requestData!['timestamp'],
                  );
                  setState(() {
                    allRequests.removeWhere((r) =>
                    r['requestId'] == requestData!['requestId']);
                    requestData =
                    allRequests.isNotEmpty ? allRequests.first : null;
                  });
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.teal,
                  backgroundColor: Colors.white,
                  side: BorderSide(color: Colors.teal, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  minimumSize: Size(100, 40),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)
                  ),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.close, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'handle_request.reject'.tr(),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: ElevatedButton(
                onPressed: () async {

                  HapticFeedback.mediumImpact();

                  setState(() => _accepted = true);
                  await updateRequestStatus(
                      requestData!['requestId'],
                      'accepted'
                  );
                  await saveRequestToHistory(
                    providerID: providerID,
                    clientID: requestData!['clientID'],
                    username: requestData!['clientName'],
                    location: requestData!['location'],
                    status: true,
                    timestamp: requestData!['timestamp'],
                  );
                  setState(() => requestData!['status'] = 'accepted');
                  _showCallDialog(requestData!["clientPhone"]);
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Color(0xFF00D47E),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  minimumSize: Size(100, 40),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)
                  ),
                  elevation: 2,
                  shadowColor: Color(0xFF00D47E).withOpacity(0.4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'handle_request.accept'.tr(),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),


        if (allRequests.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swipe, size: 16, color: Colors.grey[500]),
                  SizedBox(width: 6),
                  Text(
                    '${allRequests.length - 1} more requests',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _styledInfoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            offset: Offset(0, 2),
            blurRadius: 5,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.teal,
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Icon(icon, size: 18, color: Colors.white),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (value.length > 25)
            Icon(
              Icons.keyboard_arrow_right,
              size: 16,
              color: Colors.grey[400],
            )
        ],
      ),
    );
  }
}
  Widget _circleIcon(IconData icon) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: Color(0xFF00D47E),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(icon, size: 14, color: Colors.white),
      ),
    );
  }