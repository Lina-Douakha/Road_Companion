import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Completer<GoogleMapController> _controller =
  Completer<GoogleMapController>();

  String mapStyle = "";
  Set<Marker> markers = {};
  StreamSubscription<Position>? _positionStream;
  bool _isPermissionGranted = false;
  LatLng? _currentLocation;

  // Algeria's coordinates for default center
  static const LatLng _algeriaCoordinates = LatLng(28.0339, 1.6596);
  bool _initialCameraPositionSet = false;

  @override
  void initState() {
    super.initState();
    _loadMapStyle();
    _checkPermissionAndGetLocation();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        myLocationButtonEnabled: true,
        myLocationEnabled: _isPermissionGranted,
        initialCameraPosition: const CameraPosition(
          target: _algeriaCoordinates, // Algeria's coordinates
          zoom: 5.5, // Adjusted zoom to show more of Algeria
        ),
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);

          // Apply map style when map is created
          controller.setMapStyle(mapStyle);

          // Add markers after map is created
          _addMarkers();
        },
        markers: markers,
      ),
    );
  }

  Future _loadMapStyle() async {
    final String style = await DefaultAssetBundle.of(
      context,
    ).loadString('assets/map_style.json');
    setState(() {
      mapStyle = style;
    });
  }

  Future<BitmapDescriptor> _customIcon(String assets) async {
    return await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      assets,
    );
  }

  void _addMarkers() async {
    final markerIcon1 = await _customIcon("assets/marker.png");
    final markerIcon2 = await _customIcon("assets/car.png");

    setState(() {
      markers.addAll({
        Marker(
          markerId: const MarkerId("ESI"),
          position: const LatLng(36.7051, 2.1734), // ESI coordinates
          infoWindow: const InfoWindow(
            title: "ESI",
            snippet: "École nationale Supérieure d'Informatique",
          ),
          icon: markerIcon1,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "ESI - École nationale Supérieure d'Informatique",
                ),
              ),
            );
          },
        ),
        Marker(
          markerId: const MarkerId("Alger"),
          position: const LatLng(36.7200, 3.1666), // Algiers coordinates
          infoWindow: const InfoWindow(
            title: "Alger",
            snippet: "Capitale de l'Algérie",
          ),
          icon: markerIcon2,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Alger - Capitale de l'Algérie")),
            );
          },
        ),
      });

      // Add current location marker if available
      if (_currentLocation != null) {
        markers.add(
          Marker(
            markerId: const MarkerId("currentLocation"),
            position: _currentLocation!,
            infoWindow: const InfoWindow(title: "Ma position"),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
          ),
        );
      }
    });
  }

  Future<void> _checkPermissionAndGetLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled, show a dialog to enable them
      return;
    }

    // Check for location permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, show a message
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are permanently denied, show a message
      return;
    }

    // Permissions are granted
    setState(() {
      _isPermissionGranted = true;
    });

    _getUserLocation();
  }

  void _getUserLocation() async {
    if (!_isPermissionGranted) {
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      // Add the current location marker
      _addMarkers();
    });

    // Only animate to user location if they explicitly request it
    // This ensures the map initially shows Algeria
    if (_initialCameraPositionSet) {
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentLocation!, zoom: 14),
        ),
      );
    } else {
      _initialCameraPositionSet = true;
    }

    _startTracking();
  }

  void _startTracking() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update location when user moved 10 meters
      ),
    ).listen((Position position) {
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        // Update markers with new position
        _addMarkers();
      });
    });
  }

  // Add a method to manually center on user location
  Future<void> _centerOnUserLocation() async {
    if (_currentLocation != null) {
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentLocation!, zoom: 14),
        ),
      );
    }
  }
}