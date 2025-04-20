import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapPage extends StatefulWidget {
  final List<Map<String, dynamic>> incidents;
  const MapPage({super.key, required this.incidents});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late GoogleMapController _mapController;
  LatLng? _currentLocation;
  final Set<Marker> _markers = {};
  final Map<String, BitmapDescriptor> _cachedIcons = {};
  bool _loadingLocation = true;

  @override
  void initState() {
    super.initState();
    _preloadMarkerIcons().then((_) => _initMapBehavior());
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
      case 'Accident':
        assetPath = 'assets/GPS/accident_icon.png';
        break;
      case 'Panne':
        assetPath = 'assets/GPS/breakdown_icon.png';
        break;
      case 'Routes Barrées':
        assetPath = 'assets/GPS/circulation.png';
        break;
      case 'Travaux':
        assetPath = 'assets/GPS/roadwork.png';
        break;
      case 'Événements Spéciaux':
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

  Future<void> _initMapBehavior() async {
    if (widget.incidents.length == 1) {
      // Single incident — center on it
      final single = widget.incidents.first;
      final geoPoint = single['coordinates'] as GeoPoint?;
      if (geoPoint != null) {
        final position = LatLng(geoPoint.latitude, geoPoint.longitude);
        final icon = await _getCustomIcon(single['type']);
        setState(() {
          _markers.add(
            Marker(
              markerId: MarkerId(single['id'] ?? 'incident'),
              position: position,
              icon: icon,
              infoWindow: InfoWindow(
                title: single['type'],
                snippet: single['description'],
              ),
            ),
          );
        });

        await Future.delayed(const Duration(milliseconds: 300));
        _mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: position, zoom: 16.0),
          ),
        );
      }
      setState(() => _loadingLocation = false);
    } else {
      // Multiple incidents — get user location
      await _getCurrentLocation();
      _addIncidentMarkers(widget.incidents);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showMessage("Enable location services");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _currentLocation = LatLng(position.latitude, position.longitude);

      setState(() {
        _markers.add(
          Marker(
            markerId: const MarkerId("current-location"),
            position: _currentLocation!,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
      });

      _mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentLocation!, zoom: 14.0),
        ),
      );
    } catch (e) {
      _showMessage("Location error: ${e.toString()}");
    } finally {
      setState(() => _loadingLocation = false);
    }
  }

  void _addIncidentMarkers(List<Map<String, dynamic>> incidents) async {
    for (var incident in incidents) {
      if (incident['coordinates'] != null) {
        final geoPoint = incident['coordinates'] as GeoPoint;
        final icon = await _getCustomIcon(incident['type']);
        if (mounted) {
          setState(() {
            _markers.add(
              Marker(
                markerId: MarkerId(incident['id'] ?? 'incident-${incident.hashCode}'),
                position: LatLng(geoPoint.latitude, geoPoint.longitude),
                icon: icon,
                infoWindow: InfoWindow(
                  title: incident['type'],
                  snippet: incident['description'],
                ),
              ),
            );
          });
        }
      }
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF1B9169),
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentLocation ?? const LatLng(28.0339, 1.6596),
                zoom: 5.5,
              ),
              onMapCreated: (controller) => _mapController = controller,
              markers: _markers,
              myLocationEnabled: widget.incidents.length > 1,
              myLocationButtonEnabled: false,
              padding: EdgeInsets.zero,
            ),

            // Back Button
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FADF).withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Color(0xFF1B9169),
                    size: 24,
                  ),
                ),
              ),
            ),

            // Location Button
            if (widget.incidents.length > 1)
              Positioned(
                bottom: 100,
                right: 8,
                child: FloatingActionButton(
                  mini: true,
                  backgroundColor: const Color(0xFFD1FADF),
                  elevation: 2,
                  onPressed: _getCurrentLocation,
                  child: const Icon(
                    Icons.my_location,
                    color: Color(0xFF1B9169),
                    size: 24,
                  ),
                ),
              ),

            if (_loadingLocation)
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B9169)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}