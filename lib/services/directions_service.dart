// directions_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

const String googleMapsApiKey = "AIzaSyCcq9cNPuV2llNxo_rMg59nw-6I2t5aYOk"; // Replace with your API Key

Future<List<LatLng>> fetchRoute(LatLng start, LatLng end) async {
  final url =
      'https://maps.googleapis.com/maps/api/directions/json?origin=${start.latitude},${start.longitude}&destination=${end.latitude},${end.longitude}&key=$googleMapsApiKey';

  try {
    final response = await http.get(Uri.parse(url));

    print("Response status: ${response.statusCode}");  // Print status code to ensure successful response
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print("Response body: ${response.body}");  // Print the full response to check its contents

      final routes = data['routes'];

      // Check if routes exist and if so, decode the polyline
      if (routes.isNotEmpty) {
        final polyline = routes[0]['overview_polyline']['points'];
        print("Polyline points: $polyline");  // Print polyline points for debugging
        return _decodePolyline(polyline);
      } else {
        print("No routes found in response");
      }
    } else {
      print("Failed to fetch route: ${response.statusCode}");
    }
  } catch (e) {
    print("Error fetching route: $e");
  }

  // Return an empty list if there is no route or if the request fails
  return [];
}

List<LatLng> _decodePolyline(String encoded) {
  List<LatLng> polyline = [];
  int index = 0;
  int len = encoded.length;
  int lat = 0;
  int lng = 0;

  while (index < len) {
    int shift = 0;
    int result = 0;
    while (true) {
      int byte = encoded.codeUnitAt(index) - 63;
      index++;
      result |= (byte & 0x1f) << shift;
      shift += 5;
      if (byte < 0x20) break;
    }
    int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    lat += dlat;

    shift = 0;
    result = 0;
    while (true) {
      int byte = encoded.codeUnitAt(index) - 63;
      index++;
      result |= (byte & 0x1f) << shift;
      shift += 5;
      if (byte < 0x20) break;
    }
    int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    lng += dlng;

    polyline.add(LatLng(lat / 1E5, lng / 1E5));
  }

  return polyline;
}