import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:road_companion/screens/GPS_navigation/Search_page.dart';
import 'package:road_companion/screens/incident_reporting/incident_report_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:road_companion/screens/GPS_navigation/Destination_map.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapPage extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final String? label;

  const MapPage({super.key, this.latitude, this.longitude, this.label});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Completer<GoogleMapController> _controller = Completer();
  final LatLng _center = const LatLng(36.7538, 3.0588);
  final Set<Polyline> _polyline = {};
  final Set<Marker> _markers = {};
  final Map<String, BitmapDescriptor> _cachedIcons = {};
  bool _isPermissionGranted = false;
  bool _followUser = true;
  LatLng? _currentLocation;
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<QuerySnapshot>? _incidentsSubscription;

  @override
  void initState() {
    super.initState();
    _checkPermissionRequest();
    _preloadMarkerIcons();
    _subscribeToIncidents();

    if (widget.latitude != null && widget.longitude != null) {
      _centerOnProvidedLocation();
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _incidentsSubscription?.cancel();
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
    // Clear existing incident markers
    _markers.removeWhere((marker) => marker.markerId.value.startsWith('incident-'));

    // Add new markers for active incidents
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

  void _onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
    _addCustomMarkers();
  }

  Future<void> _checkPermissionRequest() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      setState(() => _isPermissionGranted = true);
      _getUserLocation();
    } else {
      print("Permission refusée");
    }
  }

  Future<void> _getUserLocation() async {
    if (!_isPermissionGranted) return;

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
    });

    _startTracking();
  }

  void _startTracking() {
    _positionStream = Geolocator.getPositionStream().listen((position) {
      _currentLocation = LatLng(position.latitude, position.longitude);

      if (_followUser) {
        _controller.future.then((controller) {
          controller.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: _currentLocation!,
                zoom: 14,
                bearing: position.heading,
              ),
            ),
          );
        });
      }
    });
  }

  Future<void> _centerOnProvidedLocation() async {
    final controller = await _controller.future;
    final LatLng position = LatLng(widget.latitude!, widget.longitude!);

    setState(() {
      _markers.add(
        Marker(
          markerId: const MarkerId("provided_location"),
          position: position,
          infoWindow: InfoWindow(title: widget.label ?? "Lieu"),
        ),
      );
    });

    _followUser = false;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: position, zoom: 14),
      ),
    );
  }

  Future<void> _addCustomMarkers() async {
    final icon = await _customIcon();

    setState(() {
      _markers.addAll([
        Marker(
          markerId: const MarkerId("Meca1"),
          position: const LatLng(36.7143, 3.1795),
          infoWindow: const InfoWindow(title: "Mécanicien - Sihem"),
        ),
        Marker(
          markerId: const MarkerId("Meca2"),
          position: const LatLng(36.7040, 3.1721),
          infoWindow: const InfoWindow(title: "Mécanicien - Soundous"),
        ),
      ]);
    });
  }

  Future<BitmapDescriptor> _customIcon() async {
    return await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      "assets/GPS/marker_meca.png",
    );
  }

  Widget _buildQuickAccessButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _buildQuickButton(
            "Mécanicien",
            Icons.handyman,
            const LatLng(36.752887, 3.042048),
          ),
          const SizedBox(width: 1),
          _buildQuickButton(
            "Pièce détachée",
            Icons.shopping_cart,
            const LatLng(36.752887, 3.042048),
          ),
          const SizedBox(width: 1),
          _buildQuickButton(
            "Remorquage",
            Icons.local_shipping,
            const LatLng(36.752887, 3.042048),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickButton(String label, IconData icon, LatLng target) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: ElevatedButton.icon(
        onPressed: () async {
          final controller = await _controller.future;
          _followUser = false;
          controller.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: target, zoom: 14),
            ),
          );
        },
        icon: Icon(icon, color: Colors.black, size: 18),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 12,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          elevation: 3,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          minimumSize: const Size(0, 36),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }

  Future<void> _goToCurrentLocation() async {
    if (_currentLocation == null) return;

    final controller = await _controller.future;
    setState(() {
      _followUser = true;
    });
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _currentLocation!, zoom: 15),
      ),
    );
  }

  void _goToDirectionPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DestinationPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            myLocationEnabled: _isPermissionGranted,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            zoomGesturesEnabled: true,
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(target: _center, zoom: 12),
            polylines: _polyline,
            markers: _markers,
            onTap: (_) {
              setState(() => _followUser = false);
            },
            onCameraMoveStarted: () {
              setState(() => _followUser = false);
            },
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: screenHeight * 0.04,
                color: const Color(0xFF1B9169),
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: screenWidth * 0.9,
                  child: GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LocationAutoComplete(),
                        ),
                      );

                      if (result != null && result is LatLng) {
                        final controller = await _controller.future;
                        _followUser = false;

                        controller.animateCamera(
                          CameraUpdate.newCameraPosition(
                            CameraPosition(target: result, zoom: 15),
                          ),
                        );

                        setState(() {
                          _markers.add(
                            Marker(
                              markerId: const MarkerId("search_result"),
                              position: result,
                              infoWindow: const InfoWindow(
                                title: "Lieu recherché",
                              ),
                            ),
                          );
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.search, color: Colors.grey),
                          SizedBox(width: 8),
                          Text(
                            "Rechercher un lieu",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _buildQuickAccessButtons(),
            ],
          ),
          Positioned(
            bottom: 8,
            right: 198,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF00d47e),
                elevation: 6,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                shadowColor: Colors.black26,
              ),
              icon: const Icon(Icons.report_problem, color: Colors.white, size: 20),
              label: Text(
                "report incident".tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const IncidentReportScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 50),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 45,
              height: 45,
              child: FloatingActionButton(
                onPressed: _goToCurrentLocation,
                backgroundColor: Colors.white,
                child: const Icon(Icons.my_location, color: Colors.black, size: 23),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 45,
              height: 45,
              child: FloatingActionButton(
                onPressed: _goToDirectionPage,
                backgroundColor: Colors.white,
                child: const Icon(Icons.directions, color: Colors.black, size: 23),
              ),
            ),
          ],
        ),
      ),
    );
  }
}