import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:road_companion/screens/GPS_navigation/track.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import 'package:easy_localization/easy_localization.dart';

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
  bool _isPermissionGranted = false;
  bool _followUser = true;
  bool _showTripButton = false;
  LatLng? _currentLocation;
  LatLng? _destinationLocation;
  String? _destinationLabel;
  String? _distance;
  String? _duration;
  StreamSubscription<Position>? _positionStream;
  final String _googleApiKey = 'AIzaSyCcq9cNPuV2llNxo_rMg59nw-6I2t5aYOk';

  @override
  void initState() {
    super.initState();
    _checkPermissionRequest();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
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
    _startTracking();
    _moveCameraToCurrentLocation();
  }

  void _startTracking() {
    _positionStream = Geolocator.getPositionStream().listen((position) {
      _currentLocation = LatLng(position.latitude, position.longitude);
      if (_followUser) {
        _moveCameraToCurrentLocation();
      }
    });
  }

  Future<void> _moveCameraToCurrentLocation() async {
    if (_currentLocation != null) {
      final controller = await _controller.future;
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _currentLocation!,
            zoom: 14,
            bearing: 0,
          ),
        ),
      );
    }
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

  void _clearTrip() {
    setState(() {
      _destinationLocation = null;
      _destinationLabel = null;
      _distance = null;
      _duration = null;
      _polylines.clear();
      _markers.removeWhere((marker) => marker.markerId.value == "destination");
      _showTripButton = false;
    });
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
      });
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
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "GOT IT",
                    style: TextStyle(
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
              onTap: _selectDestination,
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
          ],
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
          if (_showTripButton)
            Positioned(
              bottom: 120,
              right: 16,
              child: SizedBox(
                width: 45, // Smaller width
                height: 45, // Smaller height
                child: FloatingActionButton(
                  backgroundColor: Colors.white,
                  onPressed: _showTripDetails,
                  child: const Icon(Icons.info_outline, color: Colors.black, size: 23),
                ),
              ),
            ),
          Positioned(
            bottom: 65,
            right: 16,
            child: SizedBox(
              width: 45, // Smaller width
              height: 45, // Smaller height
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