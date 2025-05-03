import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:road_companion/screens/GPS_navigation/track.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:lottie/lottie.dart' as lottie;

// Identity Colors
const Color kAppBGreen = Color(0xFF00d47e);
const Color kAppGreen = Color(0xFF1b9169);
const Color kAppWhite = Colors.white;
const Color kAppBlue = Color(0xFF4285F4);
const Color kAppGrey = Color(0xFF9E9E9E);

class DestinationPage extends StatefulWidget {
  const DestinationPage({super.key});

  @override
  State<DestinationPage> createState() => _DestinationPageState();
}

class _DestinationPageState extends State<DestinationPage> {
  final Completer<GoogleMapController> _controller = Completer();
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};
  final Map<String, BitmapDescriptor> _cachedIcons = {};
  final List<LatLng> _realTimePath = []; // Added for tracking
  bool _isPermissionGranted = false;
  bool _followUser = true;
  bool _showTripButton = false;
  bool _showIncidentAlert = false;
  bool _tracking = false; // Added for tracking functionality
  LatLng? _currentLocation;
  LatLng? _destinationLocation;
  String? _destinationLabel;
  String? _distance;
  String? _duration;
  Map<String, dynamic>? _nearestIncident;
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<QuerySnapshot>? _incidentsSubscription;
  Timer? _incidentCheckTimer;
  double _alertDistanceThreshold = 500; // meters
  final AudioPlayer _audioPlayer = AudioPlayer();
  final String _googleApiKey = 'AIzaSyCcq9cNPuV2llNxo_rMg59nw-6I2t5aYOk';

  @override
  void initState() {
    super.initState();
    _checkPermissionRequest();
    _preloadMarkerIcons();
    _subscribeToIncidents();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _incidentsSubscription?.cancel();
    _incidentCheckTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _preloadMarkerIcons() async {
    await Future.wait([
      _getCustomIcon('Accident'),
      _getCustomIcon('Panne'),
      _getCustomIcon('Routes Barrées'),
      _getCustomIcon('Travaux'),
      _getCustomIcon('Événements Spéciaux'),
    ]);
  }

  Future<BitmapDescriptor> _getCustomIcon(String type) async {
    if (_cachedIcons.containsKey(type)) return _cachedIcons[type]!;

    String assetPath;
    switch (type) {
      case 'accident':
        assetPath = 'assets/GPS/accident_icon.png';
        break;
      case 'breakdown':
        assetPath = 'assets/GPS/breakdown_icon.png';
        break;
      case 'Road_Blockages':
        assetPath = 'assets/GPS/circulation.png';
        break;
      case 'Roadwork':
        assetPath = 'assets/GPS/roadwork.png';
        break;
      case 'Special_Events':
        assetPath = 'assets/GPS/event.png';
        break;
      default:
        assetPath = 'assets/GPS/other.png';
    }

    try {
      final Uint8List icon = await getBytesFromAsset(assetPath, 100);
      final descriptor = BitmapDescriptor.fromBytes(icon);
      _cachedIcons[type] = descriptor;
      return descriptor;
    } catch (e) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  void _subscribeToIncidents() {
    _incidentsSubscription = FirebaseFirestore.instance
        .collection('Incident Reports')
        .where('Status', whereIn: ['Pending', 'In Progress'])
        .snapshots()
        .listen((snapshot) {
      _updateIncidentMarkers(snapshot.docs);
    });
  }

  void _updateIncidentMarkers(List<QueryDocumentSnapshot> docs) {
    _markers.removeWhere((marker) => marker.markerId.value.startsWith('incident-'));

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['Location'] != null) {
        final geoPoint = data['Location'] as GeoPoint;
        final position = LatLng(geoPoint.latitude, geoPoint.longitude);
        final type = data['Type'] as String? ?? 'Unknown';
        final status = data['Status'] as String? ?? 'Pending';

        _getCustomIcon(type).then((icon) {
          if (mounted) {
            setState(() {
              _markers.add(
                Marker(
                  markerId: MarkerId('incident-${doc.id}'),
                  position: position,
                  icon: icon,
                  infoWindow: InfoWindow(
                    title: type,
                    snippet: '${data['Description']}\nStatus: $status',
                  ),
                ),
              );
            });
          }
        });
      }
    }
  }

  void _startIncidentMonitoring() {
    _incidentCheckTimer?.cancel();
    _incidentCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_currentLocation == null || _polylines.isEmpty) return;
      _checkForIncidentsNearRoute();
    });
  }

  Future<void> _checkForIncidentsNearRoute() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('Incident Reports')
        .where('Status', whereIn: ['Pending', 'In Progress'])
        .get();

    double nearestDistance = double.infinity;
    Map<String, dynamic>? nearestIncident;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data['Location'] != null) {
        final incidentLocation = data['Location'] as GeoPoint;
        final incidentLatLng = LatLng(
          incidentLocation.latitude,
          incidentLocation.longitude,
        );

        final distanceToRoute = await _distanceToPolyline(incidentLatLng);
        final distanceToUser = Geolocator.distanceBetween(
          _currentLocation!.latitude,
          _currentLocation!.longitude,
          incidentLocation.latitude,
          incidentLocation.longitude,
        );

        if (distanceToRoute < _alertDistanceThreshold &&
            distanceToUser < _alertDistanceThreshold * 2) {
          if (distanceToUser < nearestDistance) {
            nearestDistance = distanceToUser;
            nearestIncident = data;
            nearestIncident!['distance'] = distanceToUser.round();
            nearestIncident!['id'] = doc.id;
          }
        }
      }
    }

    if (nearestIncident != null &&
        (_nearestIncident == null || nearestIncident['id'] != _nearestIncident!['id'])) {
      setState(() {
        _nearestIncident = nearestIncident;
        _showIncidentAlert = true;
      });

      // Play alert sound and vibration
      Vibration.vibrate(duration: 500);
      _audioPlayer.play(AssetSource('sounds/alert.mp3'));

      Future.delayed(const Duration(seconds: 20), () {
        if (mounted) {
          setState(() => _showIncidentAlert = false);
        }
      });
    }
  }

  Future<double> _distanceToPolyline(LatLng point) async {
    double minDistance = double.infinity;

    for (var polyline in _polylines) {
      for (var polyPoint in polyline.points) {
        final distance = Geolocator.distanceBetween(
          point.latitude,
          point.longitude,
          polyPoint.latitude,
          polyPoint.longitude,
        );
        if (distance < minDistance) {
          minDistance = distance;
        }
      }
    }

    return minDistance;
  }

  Future<void> _checkPermissionRequest() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      setState(() => _isPermissionGranted = true);
      _getUserLocation();
    }
  }

  Future<void> _getUserLocation() async {
    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      _markers.add(
        Marker(
          markerId: const MarkerId("origin"),
          position: _currentLocation!,
          infoWindow: const InfoWindow(title: "Votre position"),
        ),
      );
    });
    _startLocationUpdates(); // Changed from _startTracking to separate real-time position updates
    _moveCameraToCurrentLocation();
  }

  // Updated to separate location updates from tracking
  void _startLocationUpdates() {
    _positionStream = Geolocator.getPositionStream().listen((position) {
      final newPosition = LatLng(position.latitude, position.longitude);

      setState(() {
        _currentLocation = newPosition;

        // Update origin marker to match current position
        _markers.removeWhere((marker) => marker.markerId.value == "origin");
        _markers.add(
          Marker(
            markerId: const MarkerId("origin"),
            position: newPosition,
            infoWindow: const InfoWindow(title: "Votre position"),
          ),
        );

        // If actively tracking, add to path and update route
        if (_tracking && _destinationLocation != null) {
          _realTimePath.add(newPosition);

          // Update polyline for active navigation
          _updateRoute(newPosition, _destinationLocation!);
        }
      });

      if (_followUser) {
        _moveCameraToCurrentLocation();
      }
    });
  }

  // New method for tracking functionality
  void _startTracking() {
    setState(() {
      _tracking = true;
      _realTimePath.clear();
      _realTimePath.add(_currentLocation!);
      _followUser = true;
      _startIncidentMonitoring();
    });

    // Zoom in for better navigation view
    _moveCameraToCurrentLocation(zoom: 18.0);
  }

  // New method to stop tracking
  void _stopTracking() {
    setState(() {
      _tracking = false;
      _moveCameraToCurrentLocation(zoom: 14.0);
    });
  }

  Future<void> _moveCameraToCurrentLocation({double zoom = 14.0}) async {
    if (_currentLocation != null) {
      final controller = await _controller.future;
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _currentLocation!,
            zoom: zoom,
            bearing: 0,
          ),
        ),
      );
    }
  }

  Future<void> _updateRoute(LatLng current, LatLng destination) async {
    await _getPolyline(current, destination);
    await _fetchDistanceAndDuration(current, destination);
  }

  Future<void> _selectDestination() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LocationAutoComplete()),
    );

    if (result != null && result is Map) {
      setState(() {
        _destinationLocation = result['location'];
        _destinationLabel = result['name'];
        _showTripButton = true;
        _markers.add(
          Marker(
            markerId: const MarkerId("destination"),
            position: _destinationLocation!,
            infoWindow: InfoWindow(title: result['name']),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );
      });

      if (_currentLocation != null && _destinationLocation != null) {
        await _getPolyline(_currentLocation!, _destinationLocation!);
        await _fetchDistanceAndDuration(
          _currentLocation!,
          _destinationLocation!,
        );
        _showTripDetails();
      }
    }
  }

  Future<void> _getPolyline(LatLng start, LatLng end) async {
    final polylinePoints = PolylinePoints();
    final request = PolylineRequest(
      origin: PointLatLng(start.latitude, start.longitude),
      destination: PointLatLng(end.latitude, end.longitude),
      mode: TravelMode.driving,
    );
    final result = await polylinePoints.getRouteBetweenCoordinates(
      request: request,
      googleApiKey: _googleApiKey,
    );
    if (result.points.isNotEmpty) {
      setState(() {
        _polylines.clear();
        _polylines.add(
          Polyline(
            polylineId: const PolylineId("route"),
            points: result.points
                .map((p) => LatLng(p.latitude, p.longitude))
                .toList(),
            color: kAppBlue,
            width: 5,
          ),
        );

        // Add real-time path polyline if tracking
        if (_tracking && _realTimePath.isNotEmpty) {
          _polylines.add(
            Polyline(
              polylineId: const PolylineId("realTimePath"),
              points: _realTimePath,
              color: kAppBGreen,
              width: 6,
            ),
          );
        }
      });
      _startIncidentMonitoring();
    }
  }

  Future<void> _fetchDistanceAndDuration(
    LatLng origin,
    LatLng destination,
  ) async {
    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&mode=driving&key=$_googleApiKey';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['routes'].isNotEmpty) {
        final leg = data['routes'][0]['legs'][0];
        setState(() {
          _distance = leg['distance']['text'];
          _duration = leg['duration']['text'];
        });
      }
    }
  }

  void _clearTrip() {
    _incidentCheckTimer?.cancel();
    setState(() {
      _destinationLocation = null;
      _destinationLabel = null;
      _distance = null;
      _duration = null;
      _polylines.clear();
      _markers.removeWhere((marker) => marker.markerId.value == "destination");
      _showTripButton = false;
      _showIncidentAlert = false;
      _tracking = false;
      _realTimePath.clear();
    });
  }

  Widget _buildIncidentAlertCard() {
    final incident = _nearestIncident!;
    final distance = incident['distance']?.toStringAsFixed(0) ?? 'N/A';
    final type = incident['Type'] ?? 'Incident';
    final description = incident['Description'] ?? 'No description provided';

    return Center(
      child: AnimatedScale(
        scale: 1.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        child: Material(
          elevation: 12,
          borderRadius: BorderRadius.circular(20),
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.15),
                  blurRadius: 25,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                lottie.Lottie.asset(
                  'assets/animation/alert.json',
                  height: 90,
                  repeat: true,
                ),
                const SizedBox(height: 8),
                Text(
                  "Incident Ahead",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.red[800],
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  "$type - $distance meters away",
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() => _showIncidentAlert = false);
                        _showIncidentDetails(incident);
                      },
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text("View Details"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _showIncidentAlert = false),
                      child: const Text("Dismiss"),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showIncidentDetails(Map<String, dynamic> incident) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              incident['Type'] ?? 'Incident',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              incident['Description'] ?? 'No description available',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            if (incident['Address'] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(incident['Address'])),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAppBGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "OK",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTripDetails() {
    if (_distance == null || _duration == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.52,
        decoration: const BoxDecoration(
          color: kAppWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                    color: kAppGrey.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                "Trip Details",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 20),
              _buildDetailRow(Icons.place, "Destination", _destinationLabel ?? "Destination"),
              const SizedBox(height: 15),
              _buildDetailRow(Icons.directions_car, "Distance", _distance!),
              const SizedBox(height: 15),
              _buildDetailRow(Icons.access_time, "Duration", _duration!),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAppBGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _tracking ? null : () {
                    Navigator.pop(context);
                    _startTracking();
                  },
                  child: Text(
                    _tracking ? "NAVIGATION IN PROGRESS" : "START TRIP",
                    style: const TextStyle(
                      color: kAppWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, color: kAppBGreen, size: 28),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: kAppGrey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationFields() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: kAppGrey.withOpacity(0.3),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _followUser = true;
                });
                _moveCameraToCurrentLocation();
              },
              child: TextField(
                enabled: false,
                style: const TextStyle(color: kAppGreen),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.my_location, color: kAppGreen),
                  hintText: "rechercheGPS.your_location".tr(),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  border: OutlineInputBorder(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const Divider(
              color: Color(0xFFE0E0E0),
              height: 1,
              thickness: 1,
              indent: 12,
              endIndent: 12,
            ),
            GestureDetector(
              onTap: _tracking ? null : _selectDestination,
              child: TextField(
                enabled: false,
                style: const TextStyle(color: kAppGreen),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.location_on, color: kAppGreen),
                  hintText: _destinationLabel ??
                      "rechercheGPS.choose_destination".tr(),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  border: OutlineInputBorder(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(16),
                    ),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            if (_distance != null && _duration != null && _tracking)
            const Divider(
                                    color: Color(0xFFE0E0E0),
                                    height: 1,
                                    thickness: 1,
                                    indent: 12,
                                    endIndent: 12,
                                ),
            if (_distance != null && _duration != null && _tracking)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    const Icon(Icons.directions_car, color: kAppGreen),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Text(
                        'Distance: $_distance    Duration: $_duration',
                        style: const TextStyle(
                          color: kAppGrey,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStopTrackingButton() {
    return Positioned(
      bottom: 175, // Positioned above the current location button
      right: 16,
      child: SizedBox(
        width: 45,
        height: 45,
        child: FloatingActionButton(
          backgroundColor: Colors.red, // Red color for stop action
          onPressed: _stopTracking,
          child: const Icon(Icons.stop, color: Colors.white, size: 23),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isPermissionGranted || _currentLocation == null) {
      return const Scaffold(
        backgroundColor: kAppWhite,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(kAppGreen),
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) => _controller.complete(controller),
            initialCameraPosition: CameraPosition(
              target: _currentLocation!,
              zoom: 14,
              bearing: 0,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            polylines: _polylines,
            markers: _markers,
            onCameraMoveStarted: () {
              setState(() {
                _followUser = false;
              });
            },
          ),
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: _buildLocationFields(),
          ),
          if (_showIncidentAlert && _nearestIncident != null)
            Positioned(
              bottom: 180,
              left: 16,
              right: 16,
              child: _buildIncidentAlertCard(),
            ),
          if (_showTripButton)
            Positioned(
              bottom: 120,
              right: 16,
              child: SizedBox(
                width: 45,
                height: 45,
                child: FloatingActionButton(
                  backgroundColor: Colors.white,
                  onPressed: _showTripDetails,
                  child: const Icon(Icons.info_outline, color: Colors.black, size: 23),
                ),
              ),
            ),
          if (_tracking) _buildStopTrackingButton(),
                Positioned(
                  bottom: 65,
                  right: 16,
                  child: SizedBox(
                    width: 45,
                    height: 45,
                    child: FloatingActionButton(
                      backgroundColor: Colors.white,
                      onPressed: () {
                        setState(() {
                          _followUser = true;
                        });
                        _moveCameraToCurrentLocation();
                      },
                      child: const Icon(Icons.my_location, color: Colors.black, size: 23),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}