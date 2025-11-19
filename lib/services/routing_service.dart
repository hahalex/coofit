// lib/services/routing_service.dart
import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

/// Uses public OSRM demo server to get route between two points (lon,lat)
/// Returns polyline coordinates and distance (meters).
class RoutingService {
  // OSRM public demo server
  static const String _base = 'https://router.project-osrm.org';

  /// from, to are LatLng
  static Future<Map<String, dynamic>?> getRoute(LatLng from, LatLng to) async {
    try {
      final url =
          '$_base/route/v1/driving/${from.longitude},${from.latitude};${to.longitude},${to.latitude}?overview=full&geometries=geojson';
      final resp = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return null;
      final js = json.decode(resp.body);
      if (js == null || js['routes'] == null || (js['routes'] as List).isEmpty)
        return null;
      final route = js['routes'][0];
      final distance = (route['distance'] as num).toDouble(); // meters
      final geom = route['geometry'];
      // geometry.coordinates is list of [lon,lat]
      final coords = (geom['coordinates'] as List)
          .map<LatLng>(
            (e) => LatLng((e[1] as num).toDouble(), (e[0] as num).toDouble()),
          )
          .toList();
      return {'distance': distance, 'coords': coords};
    } catch (e) {
      return null;
    }
  }
}
