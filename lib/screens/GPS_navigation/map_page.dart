import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;
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
import 'service_profile.dart';

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
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _serviceProviders = [];
  bool _showProvidersSheet = false;
  bool _isPermissionGranted = false;
  bool _followUser = true;
  LatLng? _currentLocation;
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<QuerySnapshot>? _incidentsSubscription;
  String? _selectedServiceType;

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
      _getServiceProviderIcon('mechanic'),
      _getServiceProviderIcon('parts_supplier'),
      _getServiceProviderIcon('towing_service'),
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

  Future<BitmapDescriptor> _getServiceProviderIcon(String role) async {
    if (_cachedIcons.containsKey(role)) return _cachedIcons[role]!;

    String assetPath;
    switch (role) {
      case 'mechanic':
        assetPath = 'assets/GPS/marker_meca.png';
        break;
      case 'parts_supplier':
        assetPath = 'assets/GPS/marker_parts.png';
        break;
      case 'towing_service':
        assetPath = 'assets/GPS/marker_towing.png';
        break;
      default:
        assetPath = 'assets/GPS/marker_meca.png';
    }

    try {
      final Uint8List icon = await getBytesFromAsset(assetPath, 100);
      final descriptor = BitmapDescriptor.fromBytes(icon);
      _cachedIcons[role] = descriptor;
      return descriptor;
    } catch (e) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
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

  void _onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
  }

  Future<void> _checkPermissionRequest() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      setState(() => _isPermissionGranted = true);
      _getUserLocation();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location permission is required")),
      );
    }
  }

  Future<void> _getUserLocation() async {
    if (!_isPermissionGranted) return;

    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
      _startTracking();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error getting location: $e")),
      );
    }
  }

  void _startTracking() {
    _positionStream = Geolocator.getPositionStream().listen((position) {
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });

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

  void _toggleProvidersSheet(bool show, {List<Map<String, dynamic>>? providers}) {
    setState(() {
      _showProvidersSheet = show;
      if (providers != null) {
        _serviceProviders = providers;
      }
    });
  }

  Future<double> _getAverageRating(String providerId) async {
    try {
      final reviewDoc = await FirebaseFirestore.instance
          .collection('Reviews')
          .doc(providerId)
          .get();

      if (!reviewDoc.exists) return 0.0;

      final reviewData = reviewDoc.data() as Map<String, dynamic>;
      final reviewsMap = reviewData['reviews'] as Map<String, dynamic>? ?? {};

      double totalRating = 0.0;
      int reviewCount = 0;

      for (final entry in reviewsMap.entries) {
        if (entry.key.startsWith('review')) {
          final review = entry.value as Map<String, dynamic>;
          totalRating += (review['rating'] as num?)?.toDouble() ?? 0.0;
          reviewCount++;
        }
      }

      return reviewCount > 0 ? totalRating / reviewCount : 0.0;
    } catch (e) {
      debugPrint('Error calculating average rating: $e');
      return 0.0;
    }
  }

  Future<void> _findNearbyServiceProviders(String serviceType) async {
    if (_currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Waiting for location...")),
      );
      return;
    }

    setState(() {
      _markers.removeWhere((marker) => marker.markerId.value.startsWith('service-'));
      _selectedServiceType = serviceType;
    });

    String role;
    switch (serviceType) {
      case "Mécanicien":
        role = "mechanic";
        break;
      case "Pièce détachée":
        role = "parts_supplier";
        break;
      case "Remorquage":
        role = "towing_service";
        break;
      default:
        return;
    }

    try {
      const radiusInKm = 10;
      const earthRadius = 6371.0;

      final lat = _currentLocation!.latitude;
      final lng = _currentLocation!.longitude;
      final latDelta = radiusInKm / earthRadius * (180 / math.pi);
      final lngDelta = radiusInKm / (earthRadius * math.cos(math.pi * lat / 180)) * (180 / math.pi);

      final lowerLat = lat - latDelta;
      final upperLat = lat + latDelta;
      final lowerLng = lng - lngDelta;
      final upperLng = lng + lngDelta;

      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('Role', isEqualTo: role)
          .where('Location', isGreaterThan: GeoPoint(lowerLat, lowerLng))
          .where('Location', isLessThan: GeoPoint(upperLat, upperLng))
          .get();

      final icon = await _getServiceProviderIcon(role);
      final providers = <Map<String, dynamic>>[];

      // Get average ratings for all providers
      await Future.wait(querySnapshot.docs.map((doc) async {
        final data = doc.data() as Map<String, dynamic>;
        if (data['Location'] != null) {
          final geoPoint = data['Location'] as GeoPoint;
          final position = LatLng(geoPoint.latitude, geoPoint.longitude);
          final name = data['Name'] as String? ?? 'Unknown';
          final address = data['Address'] as String? ?? '';
          final phone = data['Phone'] as String? ?? '';
          final profilePhoto = data['ProfilePhoto'] as String? ?? '';
          final averageRating = await _getAverageRating(doc.id);

          providers.add({
            'id': doc.id,
            'name': name,
            'position': position,
            'address': address,
            'phone': phone,
            'email': data['Email'] as String? ?? '',
            'Link': data['Link'] as String? ?? '',
            'ProfilePhoto': profilePhoto,
            'Role': role,
            'Location': geoPoint,
            'VerifiedAt': data['VerifiedAt'],
            'Working_hours': data['Working_hours'] as String? ?? '',
            'rating': averageRating,
          });

          _markers.add(
            Marker(
              markerId: MarkerId('service-${doc.id}'),
              position: position,
              icon: icon,
              infoWindow: InfoWindow(
                title: '$serviceType - $name',
                snippet: 'Tap for more information',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MechanicProfilePage(providerId: doc.id),
                    ),
                  );
                },
              ),
            ),
          );
        }
      }));

      if (querySnapshot.docs.isNotEmpty) {
        final bounds = _calculateBounds(
          _currentLocation!,
          querySnapshot.docs.map((doc) {
            final geoPoint = (doc.data() as Map<String, dynamic>)['Location'] as GeoPoint;
            return LatLng(geoPoint.latitude, geoPoint.longitude);
          }).toList(),
        );

        final controller = await _controller.future;
        controller.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 200),
        );

        _toggleProvidersSheet(true, providers: providers);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No $serviceType found nearby")),
        );
        _toggleProvidersSheet(false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error finding service providers: $e")),
      );
      _toggleProvidersSheet(false);
    }
  }

  LatLngBounds _calculateBounds(LatLng center, List<LatLng> locations) {
    double? minLat, maxLat, minLng, maxLng;

    locations.add(center);

    for (var location in locations) {
      minLat = minLat == null ? location.latitude : math.min(minLat, location.latitude);
      maxLat = maxLat == null ? location.latitude : math.max(maxLat, location.latitude);
      minLng = minLng == null ? location.longitude : math.min(minLng, location.longitude);
      maxLng = maxLng == null ? location.longitude : math.max(maxLng, location.longitude);
    }

    return LatLngBounds(
      northeast: LatLng(maxLat!, maxLng!),
      southwest: LatLng(minLat!, minLng!),
    );
  }

  Widget _buildQuickAccessButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _buildQuickButton("Mécanicien", Icons.handyman),
          const SizedBox(width: 8),
          _buildQuickButton("Pièce détachée", Icons.shopping_cart),
          const SizedBox(width: 8),
          _buildQuickButton("Remorquage", Icons.local_shipping),
          if (_selectedServiceType != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedServiceType = null;
                    _markers.removeWhere((marker) => marker.markerId.value.startsWith('service-'));
                    _toggleProvidersSheet(false);
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  elevation: 3,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  minimumSize: const Size(0, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "Clear",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickButton(String label, IconData icon) {
    return ElevatedButton.icon(
      onPressed: () => _findNearbyServiceProviders(label),
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
            onTap: (_) => setState(() => _followUser = false),
            onCameraMoveStarted: () => setState(() => _followUser = false),
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
          if (_showProvidersSheet)
            DraggableScrollableSheet(
              initialChildSize: 0.5,
              minChildSize: 0.3,
              maxChildSize: 0.85,
              builder: (context, controller) => Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4),
                    Center(
                      child: Container(
                        width: 35,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedServiceType ?? "Service Providers",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close),
                            onPressed: () => _toggleProvidersSheet(false),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: controller,
                        itemCount: _serviceProviders.length,
                        padding: const EdgeInsets.only(top: 8),
                        itemBuilder: (context, index) {
                          final provider = _serviceProviders[index];
                          final profilePhoto = provider['ProfilePhoto'] as String?;
                          final name = provider['name'] as String? ?? '';
                          final rating = provider['rating'] as double? ?? 0.0;

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: Material(
                              borderRadius: BorderRadius.circular(12),
                              elevation: 1,
                              child: ListTile(
                                tileColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                leading: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.grey[400],
                                  backgroundImage: profilePhoto != null && profilePhoto.isNotEmpty
                                      ? (profilePhoto.startsWith('http')
                                          ? NetworkImage(profilePhoto)
                                          : AssetImage(profilePhoto)) as ImageProvider
                                      : null,
                                  child: profilePhoto == null || profilePhoto.isEmpty
                                      ? Text(
                                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                                          style: TextStyle(color: Colors.white),
                                        )
                                      : null,
                                ),
                                title: Text(provider['name']),
                                subtitle: Text(provider['address']),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.star, color: Colors.amber, size: 20),
                                    SizedBox(width: 4),
                                    Text(rating.toStringAsFixed(1)),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward_ios, size: 16),
                                  ],
                                ),
                                onTap: () {
                                  _controller.future.then((controller) {
                                    controller.animateCamera(
                                      CameraUpdate.newLatLngZoom(
                                        provider['position'],
                                        16,
                                      ),
                                    );
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => MechanicProfilePage(providerId: provider['id']),
                                      ),
                                    );
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
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