import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPage extends StatefulWidget {
  final LatLng serviceProviderLocation;
  final LatLng? clientLocation; // Optional
  final String? clientAddress; // Optional

  const MapPage({
    Key? key,
    required this.serviceProviderLocation,
    this.clientLocation,
    this.clientAddress,
  }) : super(key: key);

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  String mapStyle = "";
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};

  @override
  void initState() {
    super.initState();
    _loadMapStyle();
    _initializeMarkers();
  }

  Future<void> _loadMapStyle() async {
    final String style = await DefaultAssetBundle.of(context).loadString('assets/map_style.json');
    setState(() {
      mapStyle = style;
    });
  }

  void _initializeMarkers() {
    // Always add the service provider marker.
    markers.add(
      Marker(
        markerId: const MarkerId('provider'),
        position: widget.serviceProviderLocation,
        infoWindow: const InfoWindow(title: 'Service Provider'),
      ),
    );

    // If a client location is provided, add it and a polyline between them.
    if (widget.clientLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('client'),
          position: widget.clientLocation!,
          infoWindow: InfoWindow(title: widget.clientAddress ?? 'Client'),
        ),
      );

      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: [widget.serviceProviderLocation, widget.clientLocation!],
          color: Colors.blue,
          width: 5,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine which location to center on: client if available, otherwise provider.
    LatLng initialCenter = widget.clientLocation ?? widget.serviceProviderLocation;

    // Instead of returning a Scaffold, return just the GoogleMap widget.
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: initialCenter,
        zoom: 13,
      ),
      onMapCreated: (GoogleMapController controller) {
        _controller.complete(controller);
        controller.setMapStyle(mapStyle);
      },
      markers: markers,
      myLocationButtonEnabled: true,
      myLocationEnabled: true,
    );
  }
}