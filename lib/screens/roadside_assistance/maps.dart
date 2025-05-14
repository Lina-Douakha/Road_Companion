import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:easy_localization/easy_localization.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:road_companion/screens/GPS_navigation/Search_page.dart';
import 'package:http/http.dart' as http;


class ServiceProviderMapPage extends StatefulWidget {
  // Service provider's location will be obtained from device
  // Client location is optional and will be provided when there's a request
  final LatLng? clientLocation;
  final String? clientAddress;

  const ServiceProviderMapPage({
    Key? key,
    this.clientLocation,
    this.clientAddress,
  }) : super(key: key);

  @override
  _ServiceProviderMapPageState createState() => _ServiceProviderMapPageState();
}

class _ServiceProviderMapPageState extends State<ServiceProviderMapPage> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  String mapStyle = "";
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};

  // For search functionality
  final TextEditingController _searchController = TextEditingController();
  LatLng? _searchResultLocation;
  bool _isSearching = false;
  bool _showSearchResults = false;
  List<Map<String, dynamic>> _searchResults = [];

  // For service provider location
  LatLng? _serviceProviderLocation;
  bool _isPermissionGranted = false;
  bool _followProvider = true;
  StreamSubscription<Position>? _positionStream;

  // For custom markers
  final Map<String, BitmapDescriptor> _markerIcons = {};

  // For routing
  bool _isLoadingRoute = false;

  @override
  void initState() {
    super.initState();
    _loadMapStyle();
    _loadMarkerIcons();
    _checkLocationPermission();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _loadMapStyle() async {
    try {
      final String style = await DefaultAssetBundle.of(context).loadString('assets/map_style.json');
      setState(() {
        mapStyle = style;
      });
    } catch (e) {
      // If style file doesn't exist, use default style
      print('Map style file not found: $e');
    }
  }

  Future<void> _loadMarkerIcons() async {
    try {
      _markerIcons['provider'] = await _getBitmapDescriptorFromAssetBytes(
          'assets/GPS/marker_service.png',
          100
      );
      _markerIcons['client'] = await _getBitmapDescriptorFromAssetBytes(
          'assets/GPS/marker_client.png',
          100
      );
      _markerIcons['search'] = await _getBitmapDescriptorFromAssetBytes(
          'assets/GPS/marker_search.png',
          100
      );
    } catch (e) {
      print('Error loading marker icons: $e');
      // Use default markers if custom ones can't be loaded
    }
  }

  Future<BitmapDescriptor> _getBitmapDescriptorFromAssetBytes(String path, int width) async {
    try {
      final ByteData data = await rootBundle.load(path);
      ui.Codec codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: width,
      );
      ui.FrameInfo fi = await codec.getNextFrame();
      final Uint8List bytes = (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
          .buffer
          .asUint8List();
      return BitmapDescriptor.fromBytes(bytes);
    } catch (e) {
      print('Error creating custom marker: $e');
      // Return default marker if custom one fails
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    }
  }

  Future<void> _checkLocationPermission() async {
    final status = await Permission.location.request();
    setState(() {
      _isPermissionGranted = status.isGranted;
    });

    if (status.isGranted) {
      _startLocationTracking();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permission is required for this app to function properly"))
      );
    }
  }

  void _startLocationTracking() {
    // First get current position once
    Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high).then((position) {
      setState(() {
        _serviceProviderLocation = LatLng(position.latitude, position.longitude);
      });
      _updateMarkers();

      // Center map on service provider location
      _controller.future.then((controller) {
        controller.animateCamera(
          CameraUpdate.newLatLngZoom(_serviceProviderLocation!, 15),
        );
      });

      // If client location exists, fetch the route
      if (widget.clientLocation != null) {
        _getRoute(_serviceProviderLocation!, widget.clientLocation!);
      }
    });

    // Then start continuous tracking
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update when moved 10 meters
      ),
    ).listen((Position position) {
      setState(() {
        _serviceProviderLocation = LatLng(position.latitude, position.longitude);
      });
      _updateMarkers();

      // If following is enabled, center map on new position
      if (_followProvider) {
        _controller.future.then((controller) {
          controller.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: _serviceProviderLocation!,
                zoom: 15,
                bearing: position.heading,
              ),
            ),
          );
        });
      }
    });
  }

  Future<void> _centerOnServiceProvider() async {
    if (_serviceProviderLocation != null) {
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(_serviceProviderLocation!, 15),
      );
      setState(() {
        _followProvider = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Getting your location...")),
      );
    }
  }

  LatLngBounds _getBounds() {
    List<LatLng> points = [];

    // Add all markers to calculate bounds
    for (Marker marker in markers) {
      points.add(marker.position);
    }

    // Add all polyline points for more accurate bounds
    for (Polyline polyline in polylines) {
      points.addAll(polyline.points);
    }

    // Ensure we have at least two points
    if (points.length < 2) {
      // If we only have one point, create a small area around it
      if (points.length == 1) {
        return LatLngBounds(
          southwest: LatLng(
            points[0].latitude - 0.01,
            points[0].longitude - 0.01,
          ),
          northeast: LatLng(
            points[0].latitude + 0.01,
            points[0].longitude + 0.01,
          ),
        );
      }

      // Fallback to default location if no points
      return LatLngBounds(
        southwest: const LatLng(36.7438, 3.0488),
        northeast: const LatLng(36.7638, 3.0688),
      );
    }

    // Calculate actual bounds
    double minLat = points[0].latitude;
    double maxLat = points[0].latitude;
    double minLng = points[0].longitude;
    double maxLng = points[0].longitude;

    for (LatLng point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    // Add a little padding
    minLat -= 0.005;
    minLng -= 0.005;
    maxLat += 0.005;
    maxLng += 0.005;

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  void _fitAllMarkers() async {
    if (markers.isNotEmpty) {
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(
        CameraUpdate.newLatLngBounds(_getBounds(), 50),
      );
      setState(() {
        _followProvider = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No markers to fit")),
      );
    }
  }

  void _handleSearchResult(LatLng result) {
    setState(() {
      _searchResultLocation = result;
      _followProvider = false;
    });

    // Animate camera to show the search result
    _controller.future.then((controller) {
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(_searchResultLocation!, 14),
      );
    });

    // Calculate route to the search result
    if (_serviceProviderLocation != null) {
      _getRoute(_serviceProviderLocation!, _searchResultLocation!);
    }

    _updateMarkers();
  }

  Future<void> _getRoute(LatLng origin, LatLng destination) async {
    setState(() {
      _isLoadingRoute = true;
    });

    try {
      // Get API key from environment variables
      final apiKey = "AIzaSyCcq9cNPuV2llNxo_rMg59nw-6I2t5aYOk";

      final response = await http.get(
        Uri.parse(
            'https://maps.googleapis.com/maps/api/directions/json?'
                'origin=${origin.latitude},${origin.longitude}'
                '&destination=${destination.latitude},${destination.longitude}'
                '&mode=driving'
                '&key=$apiKey'
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          // Decode polyline points
          final points = _decodePolyline(data['routes'][0]['overview_polyline']['points']);

          setState(() {
            String polylineId = destination == widget.clientLocation
                ? 'route'
                : 'search_route';

            Color polylineColor = destination == widget.clientLocation
                ? Colors.blue
                : Colors.green;

            // Remove any existing polyline with the same ID
            polylines.removeWhere((p) => p.polylineId.value == polylineId);

            // Add the new polyline with the decoded points
            polylines.add(
              Polyline(
                polylineId: PolylineId(polylineId),
                points: points,
                color: polylineColor,
                width: 5,
              ),
            );
          });
        } else {
          print('Directions API error: ${data['status']}');
          // Fall back to straight line if route not found
          _createStraightLinePolyline(origin, destination);
        }
      } else {
        print('Failed to get directions: ${response.statusCode}');
        // Fall back to straight line if API request fails
        _createStraightLinePolyline(origin, destination);
      }
    } catch (e) {
      print('Error getting route: $e');
      // Fall back to straight line if there's an exception
      _createStraightLinePolyline(origin, destination);
    } finally {
      setState(() {
        _isLoadingRoute = false;
      });
    }
  }

  void _createStraightLinePolyline(LatLng origin, LatLng destination) {
    String polylineId = destination == widget.clientLocation
        ? 'route'
        : 'search_route';

    Color polylineColor = destination == widget.clientLocation
        ? Colors.blue
        : Colors.green;

    List<PatternItem> pattern = destination == widget.clientLocation
        ? [PatternItem.dash(20), PatternItem.gap(10)]
        : [PatternItem.dot, PatternItem.gap(10)];

    // Remove any existing polyline with the same ID
    polylines.removeWhere((p) => p.polylineId.value == polylineId);

    // Add straight line polyline
    polylines.add(
      Polyline(
        polylineId: PolylineId(polylineId),
        points: [origin, destination],
        color: polylineColor,
        width: 5,
        patterns: pattern,
      ),
    );
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _serviceProviderLocation ?? const LatLng(36.7538, 3.0588),
              zoom: 14,
            ),
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
              if (mapStyle.isNotEmpty) {
                controller.setMapStyle(mapStyle);
              }

              // If we have both provider and client, fit bounds to show both
              if (_serviceProviderLocation != null && widget.clientLocation != null) {
                Future.delayed(const Duration(milliseconds: 500), _fitAllMarkers);
              }
            },
            markers: markers,
            polylines: polylines,
            myLocationEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: true,
            compassEnabled: true,
            onTap: (_) => setState(() {
              _followProvider = false;
            }),
            onCameraMove: (_) {
              setState(() {
                _followProvider = false;
              });
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
                        _handleSearchResult(result);
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
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: Colors.grey),
                          SizedBox(width: 8),
                          Text(
                            "GPS.Search".tr(),
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Loading indicator
          if (_isLoadingRoute)
            const Center(
              child: Card(
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: CircularProgressIndicator(),
                ),
              ),
            ),

          Positioned(
            bottom: 47,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'locate',
                  onPressed: _centerOnServiceProvider,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.my_location,
                    color: _followProvider ? Theme.of(context).primaryColor : Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                if (markers.length >= 2)
                  FloatingActionButton(
                    heroTag: 'fit',
                    onPressed: _fitAllMarkers,
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.zoom_out_map, color: Colors.black),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _updateMarkers() {
    setState(() {
      markers.clear();

      if (_serviceProviderLocation != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('provider'),
            position: _serviceProviderLocation!,
            icon: _markerIcons['provider'] ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            infoWindow: const InfoWindow(
              title: 'My Location',
              snippet: 'You are here',
            ),
          ),
        );
      }

      if (widget.clientLocation != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('client'),
            position: widget.clientLocation!,
            icon: _markerIcons['client'] ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(
              title: widget.clientAddress ?? 'Client',
            ),
          ),
        );
      }

      if (_searchResultLocation != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('search_result'),
            position: _searchResultLocation!,
            icon: _markerIcons['search'] ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
            infoWindow: const InfoWindow(
              title: 'Lieu recherché',
            ),
          ),
        );
      }
    });
  }
}