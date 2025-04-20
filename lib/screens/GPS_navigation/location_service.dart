import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  final StreamController<LatLng> _locationStreamController = StreamController<LatLng>.broadcast();
  StreamSubscription<Position>? _positionStream;
  bool _isPermissionGranted = false;

  LatLng? currentLocation;

  Stream<LatLng> get locationStream => _locationStreamController.stream;

  Future<bool> checkAndRequestPermission() async {
    final status = await Permission.location.request();
    _isPermissionGranted = status.isGranted;
    return _isPermissionGranted;
  }

  Future<void> getCurrentLocation() async {
    if (!_isPermissionGranted) return;

    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    currentLocation = LatLng(position.latitude, position.longitude);
    _locationStreamController.add(currentLocation!);
  }

  void startTracking() {
    if (!_isPermissionGranted) return;

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    ).listen((Position position) {
      currentLocation = LatLng(position.latitude, position.longitude);
      _locationStreamController.add(currentLocation!);
    });
  }

  void stopTracking() {
    _positionStream?.cancel();
    _locationStreamController.close();
  }
}